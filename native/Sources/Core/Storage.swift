import Foundation
import Network
import UIKit

// MARK: - Данные и память: что лежит на устройстве, сколько трафика ушло, что качать автоматически

/// Вид данных — по нему раскладываются и кэш на устройстве, и статистика трафика
enum DataKind: String, CaseIterable, Codable {
    case video, photo, messages, sticker, voice, file, music, calls

    var title: String {
        switch self {
        case .video: return "Видео"
        case .photo: return "Фотографии"
        case .messages: return "Сообщения"
        case .sticker: return "Стикеры"
        case .voice: return "Голосовые"
        case .file: return "Файлы"
        case .music: return "Музыка"
        case .calls: return "Звонки"
        }
    }
    var icon: String {
        switch self {
        case .video: return "video.fill"
        case .photo: return "photo.fill"
        case .messages: return "bubble.left.fill"
        case .sticker: return "face.smiling.inverse"
        case .voice: return "mic.fill"
        case .file: return "doc.fill"
        case .music: return "play.circle.fill"
        case .calls: return "phone.fill"
        }
    }
    var color: UInt32 {
        switch self {
        case .video: return 0x3d82f6
        case .photo: return 0x6cc3f5
        case .messages: return 0x5a4fd8
        case .sticker: return 0xf0a23b
        case .voice: return 0xa855f7
        case .file: return 0x4cc764
        case .music: return 0xef5350
        case .calls: return 0xf4b43a
        }
    }
    /// по типу содержимого при отправке
    static func of(contentType: String) -> DataKind {
        if contentType.hasPrefix("image/") { return .photo }
        if contentType.hasPrefix("video/") { return .video }
        if contentType.hasPrefix("audio/") { return .voice }
        return .file
    }
}

// MARK: - Тип сети (мобильная / Wi-Fi)

final class NetType {
    static let shared = NetType()
    private let monitor = NWPathMonitor()
    private(set) var cellular = false
    private init() {
        monitor.pathUpdateHandler = { [weak self] p in self?.cellular = p.usesInterfaceType(.cellular) && !p.usesInterfaceType(.wifi) }
        monitor.start(queue: DispatchQueue(label: "lumo.nettype"))
    }
}

// MARK: - Статистика трафика

final class NetStats: ObservableObject {
    static let shared = NetStats()
    struct Counter: Codable { var sent: Int64 = 0; var recv: Int64 = 0; var total: Int64 { sent + recv } }
    /// [сеть: [вид: счётчик]]; сеть — "cell" или "wifi"
    @Published private(set) var data: [String: [String: Counter]] = [:]
    @Published private(set) var since: Date
    private let lock = NSLock()
    private var dirty = false
    private let key = "lm_netstats", sinceKey = "lm_netstats_since"

    private init() {
        let d = UserDefaults.standard
        if let raw = d.data(forKey: key), let v = try? JSONDecoder().decode([String: [String: Counter]].self, from: raw) { data = v }
        if let t = d.object(forKey: sinceKey) as? Date { since = t } else { since = Date(); d.set(since, forKey: sinceKey) }
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.flush() }
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.flush() }
    }

    /// учесть байты (вызывается из любых потоков)
    func add(_ kind: DataKind, sent: Int = 0, recv: Int = 0) {
        guard sent > 0 || recv > 0 else { return }
        let net = NetType.shared.cellular ? "cell" : "wifi"
        lock.lock()
        var bucket = pending[net] ?? [:]
        var c = bucket[kind.rawValue] ?? Counter()
        c.sent += Int64(sent); c.recv += Int64(recv)
        bucket[kind.rawValue] = c
        pending[net] = bucket
        dirty = true
        lock.unlock()
    }
    private var pending: [String: [String: Counter]] = [:]

    func flush() {
        lock.lock()
        let p = pending; pending = [:]; let was = dirty; dirty = false
        lock.unlock()
        guard was else { return }
        DispatchQueue.main.async {
            var d = self.data
            for (net, kinds) in p {
                var b = d[net] ?? [:]
                for (k, c) in kinds { var x = b[k] ?? Counter(); x.sent += c.sent; x.recv += c.recv; b[k] = x }
                d[net] = b
            }
            self.data = d
            if let raw = try? JSONEncoder().encode(d) { UserDefaults.standard.set(raw, forKey: self.key) }
        }
    }

    /// счётчик по виду для выбранной сети (nil — обе)
    func counter(_ kind: DataKind, net: String?) -> Counter {
        let nets = net.map { [$0] } ?? ["cell", "wifi"]
        var c = Counter()
        for n in nets { if let x = data[n]?[kind.rawValue] { c.sent += x.sent; c.recv += x.recv } }
        return c
    }
    func total(net: String?) -> Int64 { DataKind.allCases.reduce(0) { $0 + counter($1, net: net).total } }

    func reset() {
        flush()
        lock.lock(); pending = [:]; lock.unlock()
        data = [:]; since = Date()
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.set(since, forKey: sinceKey)
    }
}

// MARK: - Автозагрузка медиа

struct AutoDownload: Codable, Equatable {
    var enabled = true
    var photos = true
    var videos = true
    var files = true
    /// предел для видео (МБ)
    var mediaMB: Double
    /// предел для файлов (МБ)
    var filesMB: Double

    static let cellDefault = AutoDownload(mediaMB: 10, filesMB: 1)
    static let wifiDefault = AutoDownload(mediaMB: 15, filesMB: 3)

    var summary: String {
        guard enabled, photos || videos || files else { return "Выключена" }
        var parts: [String] = []
        if photos || videos { parts.append("Медиа (\(Self.mb(mediaMB)))") }
        if files { parts.append("файлы (\(Self.mb(filesMB)))") }
        return parts.joined(separator: ", ")
    }
    static func mb(_ v: Double) -> String { v >= 1 ? String(format: "%.0f МБ", v) : String(format: "%.1f МБ", v) }
}

final class AutoDownloadSettings: ObservableObject {
    static let shared = AutoDownloadSettings()
    @Published var cell: AutoDownload { didSet { save() } }
    @Published var wifi: AutoDownload { didSet { save() } }
    private init() {
        let d = UserDefaults.standard
        cell = d.data(forKey: "lm_ad_cell").flatMap { try? JSONDecoder().decode(AutoDownload.self, from: $0) } ?? .cellDefault
        wifi = d.data(forKey: "lm_ad_wifi").flatMap { try? JSONDecoder().decode(AutoDownload.self, from: $0) } ?? .wifiDefault
    }
    private func save() {
        let d = UserDefaults.standard
        if let a = try? JSONEncoder().encode(cell) { d.set(a, forKey: "lm_ad_cell") }
        if let b = try? JSONEncoder().encode(wifi) { d.set(b, forKey: "lm_ad_wifi") }
    }
    func reset() { cell = .cellDefault; wifi = .wifiDefault }
    var current: AutoDownload { NetType.shared.cellular ? cell : wifi }
    var isDefault: Bool { cell == .cellDefault && wifi == .wifiDefault }

    /// можно ли сейчас скачать сразу (без нажатия)
    func allow(_ kind: DataKind, bytes: Int?) -> Bool {
        let a = current
        guard a.enabled else { return false }
        switch kind {
        case .photo: return a.photos
        case .video: return a.videos && (bytes.map { Double($0) <= a.mediaMB * 1_048_576 } ?? false)
        case .file: return a.files && (bytes.map { Double($0) <= a.filesMB * 1_048_576 } ?? false)
        default: return true
        }
    }
}

// MARK: - Хранилище на устройстве

enum DeviceStorage {
    /// где лежат файлы каждого вида
    enum Bucket: String, CaseIterable {
        case video, photo, file, voice, sticker, chats, other
        var title: String {
            switch self {
            case .video: return "Видео"
            case .photo: return "Фотографии"
            case .file: return "Файлы"
            case .voice: return "Голосовые"
            case .sticker: return "Стикеры"
            case .chats: return "Сообщения"
            case .other: return "Другое"
            }
        }
        var color: UInt32 {
            switch self {
            case .video: return 0x3d82f6
            case .photo: return 0x6cc3f5
            case .file: return 0x4cc764
            case .voice: return 0xa855f7
            case .sticker: return 0xf0a23b
            case .chats: return 0x5a4fd8
            case .other: return 0xe9893a
            }
        }
    }

    static var caches: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0] }
    /// папка вида (для «Сообщений» и «Другого» — особые случаи)
    static func dir(_ b: Bucket) -> URL? {
        switch b {
        case .video: return caches.appendingPathComponent("vcache", isDirectory: true)
        case .photo: return caches.appendingPathComponent("lumo-img", isDirectory: true)
        case .file: return caches.appendingPathComponent("lumo-files", isDirectory: true)
        case .voice: return caches.appendingPathComponent("lumo-voice", isDirectory: true)
        case .sticker: return caches.appendingPathComponent("lumo-stk", isDirectory: true)
        case .chats: return LocalCache.dirURL
        case .other: return nil
        }
    }
    static func ensure(_ b: Bucket) -> URL {
        let d = dir(b)!
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private static func size(of url: URL) -> Int64 {
        guard let en = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey]) else { return 0 }
        var t: Int64 = 0
        for case let f as URL in en {
            guard let v = try? f.resourceValues(forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]), v.isRegularFile == true else { continue }
            t += Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0)
        }
        return t
    }
    private static var ourDirs: [URL] { Bucket.allCases.compactMap { dir($0) } }

    /// размер каждого вида (долгая операция — вызывать не из главного потока)
    static func usage() -> [Bucket: Int64] {
        var r: [Bucket: Int64] = [:]
        for b in Bucket.allCases where b != .other { r[b] = dir(b).map(size) ?? 0 }
        // «Другое»: всё прочее в кэше приложения и временные файлы
        var other: Int64 = size(of: FileManager.default.temporaryDirectory)
        let mine = Set(ourDirs.map { $0.standardizedFileURL.path })
        if let items = try? FileManager.default.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil) {
            for i in items where !mine.contains(i.standardizedFileURL.path) { other += size(of: i) }
        }
        r[.other] = other
        return r
    }

    /// очистить выбранное
    static func clear(_ buckets: Set<Bucket>) {
        let fm = FileManager.default
        for b in buckets {
            if b == .other {
                let mine = Set(ourDirs.map { $0.standardizedFileURL.path })
                if let items = try? fm.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil) {
                    for i in items where !mine.contains(i.standardizedFileURL.path) { try? fm.removeItem(at: i) }
                }
                if let t = try? fm.contentsOfDirectory(at: fm.temporaryDirectory, includingPropertiesForKeys: nil) { t.forEach { try? fm.removeItem(at: $0) } }
                URLCache.shared.removeAllCachedResponses()
            } else if let d = dir(b), let items = try? fm.contentsOfDirectory(at: d, includingPropertiesForKeys: nil) {
                for i in items { try? fm.removeItem(at: i) }
            }
        }
        if buckets.contains(.photo) || buckets.contains(.sticker) { ImageCache.shared.purgeMemory() }
    }

    static var freeSpace: Int64 {
        let v = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return v?.volumeAvailableCapacityForImportantUsage ?? 0
    }

    // MARK: срок хранения и предел размера

    /// хранить медиа: дней (0 — всегда)
    static var keepDays: Int {
        get { UserDefaults.standard.object(forKey: "lm_keep_days") as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: "lm_keep_days") }
    }
    /// предел кэша, ГБ (0 — без ограничений)
    static var maxGB: Int {
        get { UserDefaults.standard.object(forKey: "lm_max_gb") as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: "lm_max_gb") }
    }

    /// убрать устаревшее и лишнее (по давности использования)
    static func trim() {
        let fm = FileManager.default
        let buckets: [Bucket] = [.video, .photo, .file, .voice, .sticker]
        var all: [(URL, Int64, Date)] = []
        for b in buckets {
            guard let d = dir(b), let items = try? fm.contentsOfDirectory(at: d, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else { continue }
            for f in items {
                let v = try? f.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                all.append((f, Int64(v?.fileSize ?? 0), v?.contentModificationDate ?? .distantPast))
            }
        }
        if keepDays > 0 {
            let edge = Date().addingTimeInterval(-Double(keepDays) * 86400)
            all.removeAll { if $0.2 < edge { try? fm.removeItem(at: $0.0); return true }; return false }
        }
        if maxGB > 0 {
            let limit = Int64(maxGB) * 1_073_741_824
            var total = all.reduce(Int64(0)) { $0 + $1.1 }
            for it in all.sorted(by: { $0.2 < $1.2 }) where total > limit { try? fm.removeItem(at: it.0); total -= it.1 }
        }
    }

    static func fmt(_ b: Int64) -> String {
        let v = Double(b)
        if v < 1024 { return "\(b) Б" }
        if v < 1_048_576 { return String(format: "%.1f КБ", v / 1024) }
        if v < 1_073_741_824 { return String(format: "%.1f МБ", v / 1_048_576) }
        return String(format: "%.1f ГБ", v / 1_073_741_824)
    }
}

// MARK: - Файлы и голосовые: скачиваются один раз и дальше берутся с телефона

actor FileStore {
    static let shared = FileStore()
    private var inflight: [String: Task<URL?, Never>] = [:]

    private static func name(_ u: URL) -> String {
        var h: UInt64 = 1469598103934665603
        for b in u.absoluteString.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        let ext = u.pathExtension.isEmpty ? "bin" : u.pathExtension.lowercased()
        return String(h, radix: 36) + "." + ext
    }
    static func bucket(_ k: DataKind) -> DeviceStorage.Bucket {
        switch k {
        case .video: return .video
        case .photo: return .photo
        case .voice, .music: return .voice
        case .sticker: return .sticker
        default: return .file
        }
    }

    /// уже есть на телефоне?
    nonisolated func local(_ u: URL, _ k: DataKind) -> URL? {
        if u.isFileURL { return u }
        if k == .video, let v = MediaCache.shared.local(u) { return v }
        guard let d = DeviceStorage.dir(Self.bucket(k)) else { return nil }
        let f = d.appendingPathComponent(Self.name(u))
        guard FileManager.default.fileExists(atPath: f.path) else { return nil }
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: f.path)
        return f
    }

    /// локальная копия (скачивает при первом обращении); nil — не вышло
    func fetch(_ u: URL, _ k: DataKind) async -> URL? {
        if k == .video { let r = await MediaCache.shared.fetch(u); return r.isFileURL ? r : nil }
        if let l = local(u, k) { return l }
        let key = Self.name(u) + k.rawValue
        if let t = inflight[key] { return await t.value }
        let dst = DeviceStorage.ensure(Self.bucket(k)).appendingPathComponent(Self.name(u))
        let t = Task<URL?, Never> {
            do {
                let (tmp, resp) = try await Net.session.download(from: u.px)
                guard let r = resp as? HTTPURLResponse, (200..<300).contains(r.statusCode) else { return nil }
                let sz = (try? FileManager.default.attributesOfItem(atPath: tmp.path)[.size] as? Int) ?? 0
                NetStats.shared.add(k, recv: sz)
                try? FileManager.default.removeItem(at: dst)
                try FileManager.default.moveItem(at: tmp, to: dst)
                return dst
            } catch { return nil }
        }
        inflight[key] = t
        let r = await t.value
        inflight[key] = nil
        return r
    }
}
