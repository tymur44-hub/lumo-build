import Foundation

/// Локальный кэш списка чатов, переписки и данных аккаунта на диске устройства.
/// Хранит последний успешно загруженный ответ сервера как есть (сырой JSON),
/// чтобы при открытии без интернета чаты и сообщения показывались сразу,
/// а не пустым экраном.
enum LocalCache {
    private static var dir: URL {
        // постоянная папка (iOS не чистит её сама, в отличие от «Caches»); очистить можно в «Данные и память»
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("lumo-cache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            // перенос старого кэша из «Caches»
            let old = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("lumo-cache")
            if let files = try? FileManager.default.contentsOfDirectory(at: old, includingPropertiesForKeys: nil) {
                for f in files { try? FileManager.default.moveItem(at: f, to: url.appendingPathComponent(f.lastPathComponent)) }
            }
        }
        return url
    }

    static var dirURL: URL { dir }
    private static func file(_ name: String) -> URL { dir.appendingPathComponent(name + ".json") }

    private static func safe(_ s: String) -> String {
        s.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
    }

    private static func save(_ name: String, _ rows: [JSON]) {
        guard let data = try? JSONSerialization.data(withJSONObject: rows) else { return }
        try? data.write(to: file(name), options: .atomic)
    }

    private static func load(_ name: String) -> [JSON]? {
        guard let data = try? Data(contentsOf: file(name)),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [JSON] else { return nil }
        return obj
    }

    /// чей это кэш: у каждого аккаунта на устройстве свой список чатов, контакты и т.д.
    static var uid = ""
    private static var u: String { uid.isEmpty ? "" : "u_" + safe(uid) + "_" }

    static func saveChats(_ rows: [JSON]) { save(u + "chats", rows) }
    /// Свой профиль: фото, имя, юзернейм, Premium видны и без интернета
    static func saveMe(_ uid: String, _ row: JSON) { save("me_" + safe(uid), [row]) }
    static func loadMe(_ uid: String) -> JSON? { load("me_" + safe(uid))?.first }
    static func loadChats() -> [JSON]? { load(u + "chats") }

    /// Любые другие данные аккаунта (контакты, обои чатов, истории, реакции, профили…):
    /// показываются сразу с устройства, потом обновляются с сервера
    static func saveRows(_ name: String, _ rows: [JSON]) { save(u + name, rows) }
    static func loadRows(_ name: String) -> [JSON]? { load(u + name) }

    static func saveMessages(_ chatId: String, _ rows: [JSON]) {
        // свежие строки с сервера + более старые, что уже были на устройстве; храним последние 300
        let newest = rows.compactMap { $0["id"] as? Int }
        var merged = rows
        if let lo = newest.min(), let old = load("msgs_" + safe(chatId)) {
            merged += old.filter { (($0["id"] as? Int) ?? Int.max) < lo }
        }
        merged.sort { (($0["id"] as? Int) ?? 0) > (($1["id"] as? Int) ?? 0) }
        save("msgs_" + safe(chatId), Array(merged.prefix(300)))
    }
    static func loadMessages(_ chatId: String) -> [JSON]? { load("msgs_" + safe(chatId)) }
}
