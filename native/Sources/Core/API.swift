import Foundation
import Security

struct APIError: LocalizedError {
    let message: String
    let status: Int
    var errorDescription: String? { message }
}

struct AuthSession: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Double
    var userId: String
}

/// Хранение входа в связке ключей iOS
enum Keychain {
    private static let service = "ru.volshebnymir.lumo.session"

    static func save(_ data: Data) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load() -> Data? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess else { return nil }
        return out as? Data
    }

    static func clear() {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
        SecItemDelete(q as CFDictionary)
    }
}

/// Сервер Lumo (Supabase): вход, база, хранилище файлов, функции
@MainActor
final class API {
    static let shared = API()

    var base: String { Net.base }
    private(set) var session: AuthSession?
    private var refreshTask: Task<Void, Error>?
    var onSessionChange: ((AuthSession?) -> Void)?

    private init() {
        if let d = Keychain.load(), let s = try? JSONDecoder().decode(AuthSession.self, from: d) { session = s }
    }

    var userId: String? { session?.userId }

    private func setSession(_ s: AuthSession?) {
        session = s
        if let s = s, let d = try? JSONEncoder().encode(s) { Keychain.save(d) } else { Keychain.clear() }
        onSessionChange?(s)
    }

    // MARK: - вход

    private func applyAuth(_ j: JSON) throws {
        guard let at = j.str("access_token"), let rt = j.str("refresh_token") else {
            throw APIError(message: "Не удалось войти", status: 0)
        }
        let exp = j.double("expires_at") ?? (Date().timeIntervalSince1970 + (j.double("expires_in") ?? 3600))
        let uid = j.dict("user").str("id") ?? session?.userId ?? ""
        setSession(AuthSession(accessToken: at, refreshToken: rt, expiresAt: exp, userId: uid))
    }

    func signIn(username: String, password: String) async throws {
        let j = try await raw("POST", "/auth/v1/token", query: [URLQueryItem(name: "grant_type", value: "password")],
                              body: ["email": username + Config.emailDomain, "password": password], auth: false) as? JSON ?? [:]
        try applyAuth(j)
    }

    func register(username: String, password: String, name: String) async throws {
        _ = try await raw("POST", "/rest/v1/rpc/lm_register",
                          body: ["p_username": username, "p_password": password, "p_name": name], auth: false)
        try await signIn(username: username, password: password)
    }

    /// Вход по одноразовой ссылке, которую выдал бот Telegram
    func verifyMagic(_ tokenHash: String) async throws {
        let j = try await raw("POST", "/auth/v1/verify", body: ["type": "magiclink", "token_hash": tokenHash], auth: false) as? JSON ?? [:]
        try applyAuth(j)
    }

    /// Запрос к функции без входа (настройки, проверка входа через Telegram)
    func publicFunction(_ path: String, body: JSON? = nil) async throws -> Any? {
        try await raw(body == nil ? "GET" : "POST", "/functions/v1/lumo" + path, body: body, auth: false)
    }

    func signOut() async {
        if session != nil {
            _ = try? await raw("POST", "/auth/v1/logout", query: [URLQueryItem(name: "scope", value: "local")], body: [:])
        }
        setSession(nil)
    }

    func forgetSession() { setSession(nil) }

    /// Действующий ключ доступа (обновляется заранее, за минуту до окончания)
    func validToken() async throws -> String {
        guard let s = session else { throw APIError(message: "Войдите заново", status: 401) }
        if s.expiresAt - 60 > Date().timeIntervalSince1970 { return s.accessToken }
        if let t = refreshTask { try await t.value } else {
            let t = Task { try await self.doRefresh() }
            refreshTask = t
            defer { refreshTask = nil }
            try await t.value
        }
        guard let ns = session else { throw APIError(message: "Войдите заново", status: 401) }
        return ns.accessToken
    }

    private func doRefresh() async throws {
        guard let s = session else { return }
        do {
            let j = try await raw("POST", "/auth/v1/token", query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
                                  body: ["refresh_token": s.refreshToken], auth: false) as? JSON ?? [:]
            try applyAuth(j)
        } catch let e as APIError where e.status == 400 || e.status == 401 || e.status == 403 {
            setSession(nil)
            throw e
        }
    }

    // MARK: - запросы

    @discardableResult
    func raw(_ method: String, _ path: String, query: [URLQueryItem] = [], body: Any? = nil,
             headers: [String: String] = [:], auth: Bool = true, data: Data? = nil) async throws -> Any? {
        let t0 = Date()
        let fid = Net.flyStart(path)
        defer { Net.flyEnd(fid) }
        do {
            let r = try await rawImpl(method, path, query: query, body: body, headers: headers, auth: auth, data: data)
            Net.lastOk = "\(method) \(path.prefix(34)) \(Int(Date().timeIntervalSince(t0) * 1000)) мс"
            return r
        } catch {
            let e = error as NSError
            Net.lastErr = "\(method) \(path.prefix(34)): \(e.domain.suffix(10)) \(e.code) \((error as? APIError)?.message ?? e.localizedDescription.prefix(60).description)"
            throw error
        }
    }

    private func rawImpl(_ method: String, _ path: String, query: [URLQueryItem] = [], body: Any? = nil,
             headers: [String: String] = [:], auth: Bool = true, data: Data? = nil) async throws -> Any? {
        var comps = URLComponents(string: base + path)!
        if !query.isEmpty { comps.queryItems = query }
        var req = URLRequest(url: comps.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: data == nil ? 12 : 180)
        req.httpMethod = method
        req.setValue(Config.anonKey, forHTTPHeaderField: "apikey")
        if auth { req.setValue("Bearer " + (try await validToken()), forHTTPHeaderField: "Authorization") }
        if let d = data {
            req.httpBody = d
        } else if let b = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: b)
        }
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        var respData: Data
        var resp: URLResponse
        do { (respData, resp) = try await Net.session.data(for: req) }
        catch let e as URLError where e.code != .cancelled {
            // нет связи — проверяем рабочий путь (напрямую / зеркало / локальная точка) и пробуем ещё раз
            let was = Net.base
            let wasMode = Net.mode
            await Net.pick(force: true)
            if Net.base == was && Net.mode == wasMode && Net.mode != .tunnel {
                guard await Net.escalate() else { throw e }
            }
            if var c2 = URLComponents(string: Net.base + path) {
                if !query.isEmpty { c2.queryItems = query }
                req.url = c2.url
            }
            (respData, resp) = try await Net.session.data(for: req)
        }
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let obj = respData.isEmpty ? nil : try? JSONSerialization.jsonObject(with: respData, options: [.fragmentsAllowed])
        if !(200..<300).contains(code) {
            let j = obj as? JSON ?? [:]
            var msg = j.str("message") ?? j.str("msg") ?? j.str("error_description") ?? j.str("error") ?? "Ошибка сервера (\(code))"
            if msg.contains("Invalid login") { msg = "Неверный юзернейм или пароль" }
            throw APIError(message: msg, status: code)
        }
        return obj
    }

    func rpc(_ name: String, _ params: JSON = [:]) async throws -> Any? {
        try await raw("POST", "/rest/v1/rpc/" + name, body: params)
    }

    func select(_ table: String, _ query: [String: String]) async throws -> [JSON] {
        let items = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return (try await raw("GET", "/rest/v1/" + table, query: items)) as? [JSON] ?? []
    }

    func insert(_ table: String, _ row: JSON) async throws -> JSON? {
        let r = try await raw("POST", "/rest/v1/" + table, body: row, headers: ["Prefer": "return=representation"])
        return (r as? [JSON])?.first
    }

    func update(_ table: String, match: [String: String], _ values: JSON) async throws {
        let items = match.map { URLQueryItem(name: $0.key, value: "eq." + $0.value) }
        try await raw("PATCH", "/rest/v1/" + table, query: items, body: values, headers: ["Prefer": "return=minimal"])
    }

    /// Загрузка файла в хранилище; возвращает публичную ссылку
    func upload(_ data: Data, ext: String, contentType: String) async throws -> String {
        guard let uid = userId else { throw APIError(message: "Войдите заново", status: 401) }
        let path = "\(uid)/\(randomId()).\(ext)"
        try await raw("POST", "/storage/v1/object/\(Config.bucket)/\(path)",
                      headers: ["Content-Type": contentType, "x-upsert": "false", "Cache-Control": "3600"], data: data)
        return Config.supabaseURL + "/storage/v1/object/public/\(Config.bucket)/\(path)"
    }

    func botFunction(_ path: String, body: JSON) async throws -> Any? {
        try await raw("POST", "/functions/v1/lumo-bots" + path, body: body)
    }

    func function(_ path: String, body: JSON? = nil) async throws -> Any? {
        try await raw(body == nil ? "GET" : "POST", "/functions/v1/lumo" + path, body: body)
    }
}
