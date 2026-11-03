import Foundation

/// Локальный кэш списка чатов и переписки на диске устройства.
/// Хранит последний успешно загруженный ответ сервера как есть (сырой JSON),
/// чтобы при открытии без интернета чаты и сообщения показывались сразу,
/// а не пустым экраном.
enum LocalCache {
    private static var dir: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("lumo-cache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

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

    static func saveChats(_ rows: [JSON]) { save("chats", rows) }
    static func loadChats() -> [JSON]? { load("chats") }

    static func saveMessages(_ chatId: String, _ rows: [JSON]) {
        // храним не больше последних 80 сообщений на чат
        save("msgs_" + safe(chatId), Array(rows.prefix(80)))
    }
    static func loadMessages(_ chatId: String) -> [JSON]? { load("msgs_" + safe(chatId)) }
}
