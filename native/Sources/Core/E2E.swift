import Foundation
import CryptoKit
import CommonCrypto
import Security

/// Сквозное шифрование личных чатов (тот же формат, что в Android и веб-версии).
/// Ключевая пара P-256 живёт на устройстве; открытая часть — на сервере (lm_keys), закрытая — в связке ключей iPhone
/// и в резервной копии под паролем (lm_key_backup). Ключ чата = HKDF-SHA256(ECDH, соль = id чата, info = "lumo-e2e-v1"),
/// сообщение = "e2e1:" + base64(nonce12 ‖ шифртекст ‖ тег), AES-256-GCM.
@MainActor
final class E2E: ObservableObject {
    static let shared = E2E()
    nonisolated static let prefix = "e2e1:"
    nonisolated static let locked = "🔒 Не удалось расшифровать"
    nonisolated static func isEnc(_ b: String?) -> Bool { b?.hasPrefix(prefix) == true }

    enum Status { case loading, ready, needRestore }

    @Published var status: Status = .loading
    @Published var backedUp = true
    @Published var promptBackup = false
    @Published var busy = false
    @Published var ver = 0

    private var me: String?
    private var priv: P256.KeyAgreement.PrivateKey?
    private var pub: Data?
    private var peerPubs: [String: Data] = [:]
    private var noKeyAt: [String: Date] = [:]
    private var chatKeys: [String: SymmetricKey] = [:]
    var changed: Set<String> = []

    private init() {}

    // MARK: - связка ключей

    private let service = "ru.volshebnymir.lumo.e2e"
    private func kcSave(_ account: String, _ data: Data) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
    private func kcLoad(_ account: String) -> Data? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
                                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess else { return nil }
        return out as? Data
    }
    private func kcClear(_ account: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(q as CFDictionary)
    }

    private func loadLocal(_ uid: String) -> (d: Data, pub: Data)? {
        guard let raw = kcLoad("key_" + uid), raw.count == 97 else { return nil }
        return (raw.prefix(32), raw.suffix(65))
    }

    private func install(_ uid: String, _ d: Data, _ pubKey: Data) throws {
        priv = try P256.KeyAgreement.PrivateKey(rawRepresentation: d)
        pub = pubKey
        me = uid
        chatKeys = [:]; peerPubs = [:]; noKeyAt = [:]
        ver += 1
    }

    // MARK: - запуск после входа

    func setup(_ uid: String) async {
        if me == uid, status == .ready, priv != nil { return }
        do {
            let srv = try await API.shared.select("lm_keys", ["select": "pub", "user_id": "eq." + uid]).first?.str("pub")
            let local = loadLocal(uid)
            if let l = local, srv == nil || srv == l.pub.base64EncodedString() {
                try install(uid, l.d, l.pub)
                if srv == nil { try await publish(uid, l.pub) }
                let b = try await API.shared.select("lm_key_backup", ["select": "user_id", "user_id": "eq." + uid])
                backedUp = !b.isEmpty
                promptBackup = !backedUp && !UserDefaults.standard.bool(forKey: "e2e_skip_" + uid)
                status = .ready
                return
            }
            if local != nil { kcClear("key_" + uid) } // на сервере другой ключ — это устройство отстало
            if srv != nil { me = uid; priv = nil; status = .needRestore; return }
            try await generateAndPublish(uid)
            promptBackup = true
        } catch {}
    }

    private func publish(_ uid: String, _ pubKey: Data) async throws {
        try await API.shared.raw("POST", "/rest/v1/lm_keys", query: [URLQueryItem(name: "on_conflict", value: "user_id")],
                                 body: ["user_id": uid, "pub": pubKey.base64EncodedString()],
                                 headers: ["Prefer": "resolution=merge-duplicates,return=minimal"])
    }

    private func generateAndPublish(_ uid: String) async throws {
        let k = P256.KeyAgreement.PrivateKey()
        let d = k.rawRepresentation
        let p = k.publicKey.x963Representation
        try await publish(uid, p)
        kcSave("key_" + uid, d + p)
        try install(uid, d, p)
        backedUp = false
        status = .ready
    }

    func forget() {
        me = nil; priv = nil; pub = nil; chatKeys = [:]; peerPubs = [:]; noKeyAt = [:]; changed = []
        status = .loading; promptBackup = false; backedUp = true
    }

    // MARK: - резервная копия под паролем

    nonisolated private static func pbkdf(_ pw: String, _ salt: Data, _ iters: Int) -> SymmetricKey {
        var out = [UInt8](repeating: 0, count: 32)
        let pwd = Array(pw.utf8)
        salt.withUnsafeBytes { (s: UnsafeRawBufferPointer) in
            pwd.withUnsafeBufferPointer { (p: UnsafeBufferPointer<UInt8>) in
                _ = p.baseAddress!.withMemoryRebound(to: Int8.self, capacity: max(pwd.count, 1)) { ip in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), ip, pwd.count,
                                         s.bindMemory(to: UInt8.self).baseAddress!, salt.count,
                                         CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), UInt32(iters), &out, 32)
                }
            }
        }
        return SymmetricKey(data: Data(out))
    }

    func createBackup(_ password: String) async -> Bool {
        guard let uid = me, let pr = priv, let pb = pub else { return false }
        busy = true
        defer { busy = false }
        do {
            var salt = Data(count: 16)
            _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
            let iters = 310_000
            let plain = pr.rawRepresentation + pb
            let saltF = salt
            let blob: Data = try await Task.detached {
                let key = E2E.pbkdf(password, saltF, iters)
                return try AES.GCM.seal(plain, using: key).combined!
            }.value
            try await API.shared.raw("POST", "/rest/v1/lm_key_backup", query: [URLQueryItem(name: "on_conflict", value: "user_id")],
                                     body: ["user_id": uid, "salt": salt.base64EncodedString(), "iters": iters, "blob": blob.base64EncodedString(),
                                            "updated_at": DateParser.string(Date())],
                                     headers: ["Prefer": "resolution=merge-duplicates,return=minimal"])
            backedUp = true; promptBackup = false
            return true
        } catch { return false }
    }

    func skipBackup() {
        if let u = me { UserDefaults.standard.set(true, forKey: "e2e_skip_" + u) }
        promptBackup = false
    }

    /// Восстановление на новом устройстве; false — неверный пароль или копии нет
    func restore(_ password: String) async -> Bool {
        guard let uid = API.shared.userId else { return false }
        busy = true
        defer { busy = false }
        do {
            guard let row = try await API.shared.select("lm_key_backup", ["select": "salt,iters,blob", "user_id": "eq." + uid]).first,
                  let salt = row.str("salt").flatMap({ Data(base64Encoded: $0) }),
                  let blob = row.str("blob").flatMap({ Data(base64Encoded: $0) }) else { return false }
            let iters = row.int("iters") ?? 310_000
            let plain: Data? = await Task.detached {
                let key = E2E.pbkdf(password, salt, iters)
                guard let box = try? AES.GCM.SealedBox(combined: blob) else { return nil }
                return try? AES.GCM.open(box, using: key)
            }.value
            guard let p = plain, p.count == 97 else { return false }
            let d = p.prefix(32), pb = p.suffix(65)
            let srv = try await API.shared.select("lm_keys", ["select": "pub", "user_id": "eq." + uid]).first?.str("pub")
            if let s = srv, s != Data(pb).base64EncodedString() { return false }
            kcSave("key_" + uid, Data(p))
            try install(uid, Data(d), Data(pb))
            backedUp = true; promptBackup = false; status = .ready
            return true
        } catch { return false }
    }

    /// Забыли пароль: создаются новые ключи, старые зашифрованные сообщения прочитать будет нельзя
    func reset() async -> Bool {
        guard let uid = API.shared.userId else { return false }
        busy = true
        defer { busy = false }
        do {
            _ = try? await API.shared.raw("DELETE", "/rest/v1/lm_key_backup", query: [URLQueryItem(name: "user_id", value: "eq." + uid)],
                                          headers: ["Prefer": "return=minimal"])
            try await generateAndPublish(uid)
            promptBackup = true
            return true
        } catch { return false }
    }

    // MARK: - ключи собеседников и чатов

    private func accept(_ uid: String, _ s: String) -> Bool {
        guard let raw = Data(base64Encoded: s), raw.count == 65 else { return false }
        noKeyAt[uid] = nil
        let k = "e2e_pin_" + uid
        if let pinned = UserDefaults.standard.string(forKey: k) { if pinned != s { changed.insert(uid) } }
        else { UserDefaults.standard.set(s, forKey: k) }
        peerPubs[uid] = raw
        return true
    }

    private func peerPub(_ uid: String) async -> Data? {
        if uid == me { return pub }
        if let p = peerPubs[uid] { return p }
        if let t = noKeyAt[uid], Date().timeIntervalSince(t) < 60 { return nil }
        let s = try? await API.shared.select("lm_keys", ["select": "pub", "user_id": "eq." + uid]).first?.str("pub")
        guard let str = s else { noKeyAt[uid] = Date(); return nil }
        return accept(uid, str) ? peerPubs[uid] : nil
    }

    func dropCaches() {
        noKeyAt = [:]
        peerPubs = peerPubs.filter { $0.key == me }
        chatKeys = [:]
    }

    /// Ключи нескольких собеседников одним запросом
    func prefetch(_ ids: [String]) async {
        let now = Date()
        let need = Array(Set(ids.filter { $0 != me && peerPubs[$0] == nil && (noKeyAt[$0].map { now.timeIntervalSince($0) > 60 } ?? true) }))
        guard !need.isEmpty,
              let rows = try? await API.shared.select("lm_keys", ["select": "user_id,pub", "user_id": "in.(" + need.joined(separator: ",") + ")"]) else { return }
        var got = Set<String>()
        for r in rows { if let u = r.str("user_id"), let s = r.str("pub"), accept(u, s) { got.insert(u) } }
        for u in need where !got.contains(u) { noKeyAt[u] = now }
    }

    /// Подготовить ключ чата (peer == nil — «Избранное»)
    func prepare(_ chatId: String, peer: String?) async {
        guard status == .ready, let pr = priv, chatKeys[chatId] == nil else { return }
        guard let pid = peer ?? me, let pk = await peerPub(pid) else { return }
        guard let pubKey = try? P256.KeyAgreement.PublicKey(x963Representation: pk),
              let ss = try? pr.sharedSecretFromKeyAgreement(with: pubKey) else { return }
        chatKeys[chatId] = ss.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(chatId.lowercased().utf8),
                                                      sharedInfo: Data("lumo-e2e-v1".utf8), outputByteCount: 32)
        ver += 1
    }

    func active(_ chatId: String) -> Bool { chatKeys[chatId] != nil }

    func encrypt(_ chatId: String, _ text: String) -> String? {
        guard let k = chatKeys[chatId], let box = try? AES.GCM.seal(Data(text.utf8), using: k), let c = box.combined else { return nil }
        return E2E.prefix + c.base64EncodedString()
    }

    func decrypt(_ chatId: String, _ body: String?) -> String? {
        guard let body = body, E2E.isEnc(body) else { return body }
        guard let k = chatKeys[chatId], let raw = Data(base64Encoded: String(body.dropFirst(E2E.prefix.count))),
              let box = try? AES.GCM.SealedBox(combined: raw), let p = try? AES.GCM.open(box, using: k),
              let s = String(data: p, encoding: .utf8) else { return E2E.locked }
        return s
    }

    /// Код безопасности: одинаковый у обоих собеседников
    func safety(_ peerId: String) -> String? {
        guard let a = pub, let b = (peerId == me ? pub : peerPubs[peerId]) else { return nil }
        let sa = a.base64EncodedString(), sb = b.base64EncodedString()
        let (x, y) = sa <= sb ? (sa, sb) : (sb, sa)
        let h = Array(SHA256.hash(data: Data("\(x)|\(y)".utf8)))
        return (0..<8).map { i -> String in
            let v = (UInt64(h[i * 4]) << 24) | (UInt64(h[i * 4 + 1]) << 16) | (UInt64(h[i * 4 + 2]) << 8) | UInt64(h[i * 4 + 3])
            return String(format: "%05d", Int(v % 100000))
        }.joined(separator: " ")
    }
}
