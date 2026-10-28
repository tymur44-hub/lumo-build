import Foundation
import SwiftUI
import UIKit

enum Config {
    static let supabaseURL = "https://foniukmpiukuwpcdvdhp.supabase.co"
    /// Свой адрес сервера (прокси к Supabase) — чтобы Lumo работал в России без VPN
    static let proxyURL = "https://api.volshebny-mir.ru"
    static let anonKey = "sb_publishable_cE72E1dUPnfaVn8mPnc9sA_U2HO-mxN"
    static let emailDomain = "@lumo.app"
    static let bucket = "lm-media"
    /// Приложение пока в бета-версии (ещё исправляем ошибки)
    static var versionLabel: String {
        "Бета-версия " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
    }
    static var realtimeURL: URL {
        URL(string: Net.base.replacingOccurrences(of: "https://", with: "wss://")
            + "/realtime/v1/websocket?apikey=\(anonKey)&vsn=1.0.0")!
    }
}

typealias JSON = [String: Any]

extension Dictionary where Key == String, Value == Any {
    func str(_ k: String) -> String? {
        if let s = self[k] as? String { return s }
        if let n = self[k] as? NSNumber { return n.stringValue }
        return nil
    }
    func int(_ k: String) -> Int? {
        if let n = self[k] as? NSNumber { return n.intValue }
        if let s = self[k] as? String { return Int(s) }
        return nil
    }
    func double(_ k: String) -> Double? {
        if let n = self[k] as? NSNumber { return n.doubleValue }
        if let s = self[k] as? String { return Double(s) }
        return nil
    }
    func bool(_ k: String) -> Bool {
        if let b = self[k] as? Bool { return b }
        if let n = self[k] as? NSNumber { return n.boolValue }
        return false
    }
    func dict(_ k: String) -> JSON { self[k] as? JSON ?? [:] }
    func date(_ k: String) -> Date? { DateParser.parse(self[k] as? String) }
}

enum DateParser {
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ raw: String?) -> Date? {
        guard var s = raw, !s.isEmpty else { return nil }
        s = s.replacingOccurrences(of: " ", with: "T")
        // микросекунды → миллисекунды
        if let r = s.range(of: #"\.(\d{3})\d+"#, options: .regularExpression) {
            let frac = String(s[r].prefix(4))
            s.replaceSubrange(r, with: frac)
        }
        if s.range(of: #"[+-]\d\d$"#, options: .regularExpression) != nil { s += ":00" }
        let hasZone = s.hasSuffix("Z") || s.range(of: #"[+-]\d\d:\d\d$"#, options: .regularExpression) != nil
        if !hasZone { s += "Z" }
        return withFraction.date(from: s) ?? plain.date(from: s)
    }

    static func string(_ d: Date) -> String { withFraction.string(from: d) }
}

enum Fmt {
    static func time(_ d: Date?) -> String {
        guard let d = d else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        let cal = Calendar.current
        if cal.isDateInToday(d) { f.dateFormat = "HH:mm" }
        else if cal.isDateInYesterday(d) { return "вчера" }
        else if let w = cal.dateComponents([.day], from: d, to: Date()).day, w < 7 { f.dateFormat = "EE" }
        else if cal.component(.year, from: d) == cal.component(.year, from: Date()) { f.dateFormat = "d MMM" }
        else { f.dateFormat = "dd.MM.yy" }
        return f.string(from: d)
    }

    static func clock(_ d: Date?) -> String {
        guard let d = d else { return "" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    static func day(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Сегодня" }
        if cal.isDateInYesterday(d) { return "Вчера" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = cal.component(.year, from: d) == cal.component(.year, from: Date()) ? "d MMMM" : "d MMMM yyyy"
        return f.string(from: d)
    }

    static func duration(_ s: Double) -> String {
        let t = max(0, Int(s.rounded()))
        return "\(t / 60):" + String(format: "%02d", t % 60)
    }

    static func size(_ b: Int) -> String {
        var v = Double(b)
        let u = ["Б", "КБ", "МБ", "ГБ"]
        var i = 0
        while v >= 1024 && i < 3 { v /= 1024; i += 1 }
        return i == 0 ? "\(Int(v)) \(u[i])" : String(format: "%.1f %@", v, u[i])
    }

    static func lastSeen(_ d: Date?, show: Bool = true) -> String {
        guard show, let d = d else { return "был(а) недавно" }
        let m = Date().timeIntervalSince(d) / 60
        if m < 1.5 { return "был(а) только что" }
        if m < 60 { return "был(а) \(Int(m.rounded())) мин. назад" }
        if Calendar.current.isDateInToday(d) { return "был(а) сегодня в " + clock(d) }
        return "был(а) " + day(d).lowercased() + " в " + clock(d)
    }

    static func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        guard let first = parts.first else { return "?" }
        if parts.count > 1, let a = first.first, let b = parts[1].first { return String([a, b]).uppercased() }
        return String(first.prefix(2)).uppercased()
    }
}

/// Оформление (как на сайте): тема, цвет, размер текста, фон чата
final class Appearance: ObservableObject {
    static let shared = Appearance()
    static let accents: [(UInt32, UInt32)] = [(0x7c5cff, 0x22c1ff), (0xff5b8a, 0xff9a5b), (0x13b0a5, 0x2ee6a6),
                                              (0x3a7bff, 0x22c1ff), (0xc44dff, 0xff5b7a), (0xff8a3d, 0xffc94a),
                                              // эксклюзивные, только для Premium
                                              (0xff3d6e, 0xffb020), (0x00c6ff, 0x43e97b), (0xb066ff, 0x00e0c6),
                                              (0xffd34d, 0xff5b8a), (0x5b6cff, 0xff5bd0), (0x12b886, 0xb8e83d)]
    private let d = UserDefaults.standard

    @Published var theme: String { didSet { d.set(theme, forKey: "lm_theme"); version += 1 } }
    @Published var accent: Int { didSet { d.set(accent, forKey: "lm_accent"); version += 1 } }
    @Published var fontSize: Double { didSet { d.set(fontSize, forKey: "lm_fs") } }
    @Published var wall: Int { didSet { d.set(wall, forKey: "lm_wall") } }
    @Published var version = 0

    private init() {
        theme = d.string(forKey: "lm_theme") ?? "dark"
        accent = d.object(forKey: "lm_accent") as? Int ?? 0
        fontSize = d.object(forKey: "lm_fs") as? Double ?? 16
        wall = d.object(forKey: "lm_wall") as? Int ?? 0
    }

    var scheme: ColorScheme? { theme == "light" ? .light : theme == "dark" ? .dark : nil }
    var pair: (UInt32, UInt32) { Appearance.accents[min(max(0, accent), Appearance.accents.count - 1)] }
}

/// Цвета — как на сайте (светлая и тёмная тема)
enum Theme {
    private static func dyn(_ light: UInt32, _ dark: UInt32, _ la: CGFloat = 1, _ da: CGFloat = 1) -> Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: da) : UIColor(hex: light, alpha: la)
        })
    }
    static var bg: Color { dyn(0xeef0fb, 0x0c0d1a) }
    static var panel: Color { dyn(0xffffff, 0x13142a) }
    static var panel2: Color { dyn(0xf4f5fd, 0x1a1c36) }
    static var chatBg: Color { dyn(0xe7e9fb, 0x0e0f22) }
    static var bubble: Color { dyn(0xffffff, 0x1d1f3d) }
    static var text: Color { dyn(0x14163a, 0xeef0ff) }
    static var muted: Color { dyn(0x7276a0, 0x8d90b8) }
    static var line: Color { dyn(0x14163c, 0xffffff, 0.08, 0.07) }
    static var hover: Color { dyn(0x14163c, 0xffffff, 0.045, 0.05) }
    static var active: Color { a1.opacity(0.16) }
    static var a1: Color { Color(hex: Appearance.shared.pair.0) }
    static var a2: Color { Color(hex: Appearance.shared.pair.1) }
    static let ok = Color(hex: 0x3ee0a0)
    static var accent: LinearGradient { LinearGradient(colors: [a1, a2], startPoint: .topLeading, endPoint: .bottomTrailing) }
    static var out: LinearGradient {
        Appearance.shared.accent == 0
            ? LinearGradient(colors: [Color(hex: 0x6a4cf5), Color(hex: 0x3a7bff)], startPoint: .topLeading, endPoint: .bottomTrailing)
            : accent
    }
    static let danger = Color(hex: 0xff5b7a)
    static let nameColors: [Color] = [Color(hex: 0xff7a6b), Color(hex: 0xa48bff), Color(hex: 0x36b8ff), Color(hex: 0x25c99a),
                                      Color(hex: 0xf0a23a), Color(hex: 0xff5b9a), Color(hex: 0x6aa8ff), Color(hex: 0x52c46e)]
    static func nameColor(_ c: Int) -> Color { nameColors[((c % 8) + 8) % 8] }

    private static let pairs: [(Color, Color)] = [
        (Color(hex: 0xff8a5b), Color(hex: 0xff5b8a)), (Color(hex: 0x7c5cff), Color(hex: 0xb05cff)),
        (Color(hex: 0x22c1ff), Color(hex: 0x3a7bff)), (Color(hex: 0x2ee6a6), Color(hex: 0x13b0a5)),
        (Color(hex: 0xffc94a), Color(hex: 0xff8a3d)), (Color(hex: 0xff5b7a), Color(hex: 0xc44dff)),
        (Color(hex: 0x5bd0ff), Color(hex: 0x7c5cff)), (Color(hex: 0x9be15d), Color(hex: 0x00c6a7)),
    ]
    static func avatarGradient(_ color: Int) -> LinearGradient {
        let p = pairs[((color % 8) + 8) % 8]
        return LinearGradient(colors: [p.0, p.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}

func randomId(_ n: Int = 8) -> String {
    let chars = Array("abcdefghijklmnopqrstuvwxyz0123456789")
    return String((0..<n).map { _ in chars.randomElement()! })
}


/// Выбор адреса сервера: напрямую (supabase.co) или через свой прокси.
/// В России supabase.co работает плохо (замедление Cloudflare) — пробуем оба и берём тот, что отвечает.
enum Net {
    enum Mode { case direct, proxy, tunnel }

    private static let lock = NSLock()
    private static var _base = UserDefaults.standard.string(forKey: "lm_base") ?? Config.supabaseURL
    private static var _mode: Mode = {
        if UserDefaults.standard.string(forKey: "lm_mode") == "tunnel" {
            DispatchQueue.global().async { Fast.ensure() }
            return .tunnel
        }
        return .direct
    }()
    private static var lastPick = Date.distantPast
    static var diag = "проверка не запускалась"
    static var lastErr = "-"
    private static let flyLock = NSLock()
    private static var fly: [String: (String, Date)] = [:]
    static func flyStart(_ path: String) -> String { let id = UUID().uuidString; flyLock.lock(); fly[id] = (path, Date()); flyLock.unlock(); return id }
    static func flyEnd(_ id: String) { flyLock.lock(); fly[id] = nil; flyLock.unlock() }
    static var flyText: String {
        flyLock.lock(); defer { flyLock.unlock() }
        let now = Date()
        let items = fly.values.filter { now.timeIntervalSince($0.1) > 3 }.map { "\($0.0.prefix(28)) \(Int(now.timeIntervalSince($0.1))) c" }
        return items.isEmpty ? "-" : items.joined(separator: "; ")
    }
    /// обновляется из основного потока (Realtime)
    static var rtState = "-"
    static var diagFull: String {
        var t: String = diag
        t += "\nвисят: " + flyText
        t += "\nпоследний успех: " + lastOk
        t += "\nпоследняя ошибка: " + lastErr
        t += "\nrealtime: " + rtState
        return t
    }
    static var lastOk = "-"
    private static var why: [String: String] = [:]

    static var base: String {
        get { lock.lock(); defer { lock.unlock() }; return _base }
        set { lock.lock(); _base = newValue; lock.unlock(); UserDefaults.standard.set(newValue, forKey: "lm_base") }
    }
    static var mode: Mode { lock.lock(); defer { lock.unlock() }; return _mode }

    private static func set(_ m: Mode, _ b: String) {
        lock.lock(); _mode = m; lock.unlock()
        UserDefaults.standard.set(m == .tunnel ? "tunnel" : (m == .proxy ? "proxy" : "direct"), forKey: "lm_mode")
        if b != base { base = b }
    }

    /// Настройки сессии с маршрутом через локальную точку (когда прямой путь и зеркало режутся)
    static func proxyConfig() -> URLSessionConfiguration {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable as String: 1,
            kCFNetworkProxiesHTTPProxy as String: "127.0.0.1",
            kCFNetworkProxiesHTTPPort as String: Fast.HTTP,
            "HTTPSEnable": 1,
            "HTTPSProxy": "127.0.0.1",
            "HTTPSPort": Fast.HTTP,
        ]
        return cfg
    }
    private static let tunnelSession = URLSession(configuration: proxyConfig())

    /// Сессия для запросов: обычная или (в режиме туннеля) через локальную точку
    static var session: URLSession { mode == .tunnel ? tunnelSession : URLSession.shared }

    private static func ok(_ b: String, _ s: URLSession = URLSession.shared) async -> Bool {
        // большой ответ (48 КБ): провайдеры режут соединение после 16 КБ
        let key = s === URLSession.shared ? (b == Config.supabaseURL ? "прямой" : "зеркало") : "узел"
        guard let u = URL(string: b + "/functions/v1/lumo/ping?kb=48") else { return false }
        var r = URLRequest(url: u, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        r.setValue(Config.anonKey, forHTTPHeaderField: "apikey")
        r.setValue("Bearer " + Config.anonKey, forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await s.data(for: r)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let good = code == 200 && data.count > 40000
            why[key] = good ? "ок" : "код \(code), \(data.count) байт"
            return good
        } catch {
            let e = error as NSError
            why[key] = "\(e.domain.suffix(8)) \(e.code)"
            return false
        }
    }

    private static var tunUntil: Date {
        get { Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: "lm_tun_until")) }
        set { UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "lm_tun_until") }
    }

    /// Проверить пути и выбрать работающий (не чаще раза в 20 секунд). Локальный узел поднимается параллельно.
    /// Если недавно запросы зависали напрямую — держимся за узел (проверка «прямой: ок» обманчива: режутся только большие ответы).
    static func pick(force: Bool = false) async {
        if !force && Date().timeIntervalSince(lastPick) < 20 { return }
        lastPick = Date()
        async let d = ok(Config.supabaseURL)
        async let p = ok(Config.proxyURL)
        async let t: Bool = { Fast.ensure() ? await ok(Config.supabaseURL, tunnelSession) : false }()
        let rd = await d, rp = await p, rt = await t
        let sticky = Date() < tunUntil
        if rp { set(.proxy, Config.proxyURL) }
        else if sticky && rt { set(.tunnel, Config.supabaseURL) }
        else if rd { set(.direct, Config.supabaseURL) }
        else if rt { set(.tunnel, Config.supabaseURL) }
        diag = "прямой: \(why["прямой"] ?? "-")\nзеркало: \(why["зеркало"] ?? "-")\nузел: \(Fast.isRunning ? "запущен" : "нет") (\(Fast.lastMsg.prefix(330)))\nчерез узел: \(why["узел"] ?? "-")\nрежим: \(mode)"
    }

    /// Запрос завис при «рабочем» прямом пути — переходим на локальный узел на 30 минут
    static func escalate() async -> Bool {
        if mode == .tunnel { return false }
        guard Fast.ensure(), await ok(Config.supabaseURL, tunnelSession) else { return false }
        tunUntil = Date().addingTimeInterval(30 * 60)
        set(.tunnel, Config.supabaseURL)
        return true
    }

    /// Ссылка на файл через выбранный адрес
    static func px(_ s: String) -> String {
        let b = base
        guard b != Config.supabaseURL, s.hasPrefix(Config.supabaseURL) else { return s }
        return b + s.dropFirst(Config.supabaseURL.count)
    }
}

extension URL {
    /// Тот же адрес, но через выбранный сервер (прокси), если напрямую не работает
    var px: URL { URL(string: Net.px(absoluteString)) ?? self }
}
