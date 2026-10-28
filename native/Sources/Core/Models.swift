import Foundation

struct Profile: Identifiable, Equatable {
    var id: String
    var username: String
    var name: String
    var bio: String
    var avatarURL: String?
    var color: Int
    var lastSeen: Date?
    var showSeen: Bool
    var banned: Bool
    var banReason: String?
    var callsFrom: String
    var verified: Bool
    var lastName: String
    var birthday: String?
    var privacy: [String: String]
    var channelId: String?
    var channelTitle: String?
    var channelUsername: String?
    var channelAvatar: String?
    var channelColor: Int
    var channelMembers: Int
    var premium = false
    var isBot = false
    var emojiStatus: String?

    /// Имя без фамилии (в name хранится полное имя)
    var firstName: String { !lastName.isEmpty && name.hasSuffix(" " + lastName) ? String(name.dropLast(lastName.count + 1)) : name }

    /// Настройка конфиденциальности: all / contacts / none
    func priv(_ key: String) -> String {
        if let v = privacy[key] { return v }
        switch key {
        case "seen": return showSeen ? "all" : "none"
        case "calls": return callsFrom
        case "birthday": return "contacts"
        default: return "all"
        }
    }

    init(json j: JSON) {
        id = j.str("id") ?? ""
        username = j.str("username") ?? ""
        name = j.str("name") ?? ""
        bio = j.str("bio") ?? ""
        avatarURL = j.str("avatar_url").flatMap { $0.isEmpty ? nil : $0 }
        color = j.int("color") ?? 0
        lastSeen = j.date("last_seen")
        showSeen = j["show_seen"] == nil ? true : j.bool("show_seen")
        banned = j.bool("banned")
        banReason = j.str("ban_reason")
        callsFrom = j.str("calls_from") ?? "all"
        verified = j.bool("verified")
        lastName = j.str("last_name") ?? ""
        birthday = j.str("birthday")
        privacy = (j["privacy"] as? [String: Any] ?? [:]).compactMapValues { $0 as? String }
        channelId = j.str("channel_id")
        channelTitle = j.str("channel_title")
        channelUsername = j.str("channel_username")
        channelAvatar = j.str("channel_avatar")
        channelColor = j.int("channel_color") ?? 0
        channelMembers = j.int("channel_members") ?? 0
        premium = j.bool("premium")
        isBot = j.bool("is_bot")
        emojiStatus = j.str("emoji_status")
    }
}

/// День рождения «1 июля 2011 (15 лет)»
enum Birthday {
    static let months = ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"]
    static func parts(_ s: String?) -> (Int, Int, Int)? {
        guard let p = s?.prefix(10).split(separator: "-").compactMap({ Int($0) }), p.count == 3 else { return nil }
        return (p[0], p[1], p[2])
    }
    static func text(_ s: String?, age: Bool = false) -> String? {
        guard let (y, m, d) = parts(s) else { return nil }
        var t = "\(d) \(months[max(0, min(11, m - 1))]) \(y)"
        if age {
            let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            var a = (c.year ?? y) - y
            if (c.month ?? 1) < m || ((c.month ?? 1) == m && (c.day ?? 1) < d) { a -= 1 }
            if a >= 1 && a <= 120 {
                let w = (11...14).contains(a % 100) ? "лет" : (a % 10 == 1 ? "год" : ((2...4).contains(a % 10) ? "года" : "лет"))
                t += " (\(a) \(w))"
            }
        }
        return t
    }
    static func date(_ s: String?) -> Date? {
        guard let (y, m, d) = parts(s) else { return nil }
        return Calendar.current.date(from: DateComponents(year: y, month: m, day: d))
    }
    static func string(_ d: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }
}

struct ChatItem: Identifiable, Equatable {
    var id: String
    var type: String
    var title: String?
    var avatarURL: String?
    var color: Int
    var peerId: String?
    var peerName: String?
    var peerUsername: String?
    var peerAvatar: String?
    var peerColor: Int
    var peerLastSeen: Date?
    var role: String?
    var muted: Bool
    var pinned: Bool
    var lastReadAt: Date?
    var membersCount: Int
    var lastId: Int?
    var lastKind: String?
    var lastBody: String?
    var lastSender: String?
    var lastSenderName: String?
    var lastAt: Date?
    var lastDeleted: Bool
    var unread: Int
    var othersReadAt: Date?
    var pinnedMessageId: Int?
    var description: String?
    var username: String?
    var isPublic: Bool
    var peerBot = false
    var peerPremium = false
    var peerVerified = false

    init(json j: JSON) {
        peerBot = j.bool("peer_bot")
        peerPremium = j.bool("peer_premium")
        peerVerified = j.bool("peer_verified")
        id = j.str("chat_id") ?? ""
        type = j.str("type") ?? "private"
        title = j.str("title")
        avatarURL = j.str("avatar_url").flatMap { $0.isEmpty ? nil : $0 }
        color = j.int("color") ?? 0
        peerId = j.str("peer_id")
        peerName = j.str("peer_name")
        peerUsername = j.str("peer_username")
        peerAvatar = j.str("peer_avatar").flatMap { $0.isEmpty ? nil : $0 }
        peerColor = j.int("peer_color") ?? 0
        peerLastSeen = j.date("peer_last_seen")
        role = j.str("role")
        muted = j.bool("muted")
        pinned = j.bool("pinned")
        lastReadAt = j.date("last_read_at")
        membersCount = j.int("members_count") ?? 0
        lastId = j.int("last_id")
        lastKind = j.str("last_kind")
        lastBody = j.str("last_body")
        lastSender = j.str("last_sender")
        lastSenderName = j.str("last_sender_name")
        lastAt = j.date("last_at")
        lastDeleted = j.bool("last_deleted")
        unread = j.int("unread") ?? 0
        othersReadAt = j.date("others_read_at")
        pinnedMessageId = j.int("pinned_message_id")
        description = j.str("description")
        username = j.str("username")
        isPublic = j.bool("is_public")
    }

    var isPrivate: Bool { type == "private" }
    var isChannel: Bool { type == "channel" }
    var displayName: String {
        if isPrivate { return peerName ?? peerUsername ?? "Пользователь" }
        return title ?? (isChannel ? "Канал" : "Группа")
    }
    var displayAvatar: String? { isPrivate ? peerAvatar : avatarURL }
    var displayColor: Int { isPrivate ? peerColor : color }
    var canPost: Bool { !isChannel || role == "owner" || role == "admin" }
    var isAdmin: Bool { role == "owner" || role == "admin" }

    func preview(myId: String?) -> String {
        if lastId == nil { return isChannel ? "Канал создан" : "Нет сообщений" }
        if lastDeleted { return "Сообщение удалено" }
        let text = Message.previewText(kind: lastKind ?? "text", body: lastBody)
        if type == "group", let s = lastSenderName, lastKind != "system" {
            return (lastSender == myId ? "Вы" : s) + ": " + text
        }
        if lastSender == myId && lastKind != "system" && lastKind != "call" { return "Вы: " + text }
        return text
    }
}

struct BotButton: Hashable {
    var text: String
    var data: String?
    var url: String?
}

struct Message: Identifiable, Equatable {
    var id: Int
    var chatId: String
    var senderId: String?
    var kind: String
    var body: String?
    var mediaURL: String?
    var meta: JSON
    var replyTo: Int?
    var forwardedFrom: String?
    var editedAt: Date?
    var deleted: Bool
    var createdAt: Date
    var pending = false
    var localMedia: URL?
    var enc = false

    /// Кнопки под сообщением бота
    var buttons: [[BotButton]] {
        guard let rows = meta["buttons"] as? [[[String: Any]]] else { return [] }
        return rows.map { $0.map { BotButton(text: $0["text"] as? String ?? "", data: $0["data"] as? String, url: $0["url"] as? String) } }
    }

    init(json j: JSON) {
        id = j.int("id") ?? 0
        chatId = j.str("chat_id") ?? ""
        senderId = j.str("sender_id")
        kind = j.str("kind") ?? "text"
        body = j.str("body")
        mediaURL = j.str("media_url")
        meta = j.dict("meta")
        replyTo = j.int("reply_to")
        forwardedFrom = j.str("forwarded_from")
        editedAt = j.date("edited_at")
        deleted = j.bool("deleted")
        createdAt = j.date("created_at") ?? Date()
    }

    init(pendingIn chat: String, sender: String, kind: String, body: String?, meta: JSON = [:], replyTo: Int? = nil, local: URL? = nil) {
        id = -Int(Date().timeIntervalSince1970 * 1000) - Int.random(in: 0..<1000)
        chatId = chat
        senderId = sender
        self.kind = kind
        self.body = body
        mediaURL = nil
        self.meta = meta
        self.replyTo = replyTo
        forwardedFrom = nil
        editedAt = nil
        deleted = false
        createdAt = Date()
        pending = true
        localMedia = local
    }

    static func == (a: Message, b: Message) -> Bool {
        a.id == b.id && a.editedAt == b.editedAt && a.deleted == b.deleted && a.body == b.body
            && a.pending == b.pending && a.mediaURL == b.mediaURL && a.metaStatus == b.metaStatus
    }

    var metaStatus: String? { meta.str("status") }
    var duration: Double { meta.double("dur") ?? meta.double("duration") ?? 0 }
    var wave: [Int] { (meta["wave"] as? [Any])?.compactMap { ($0 as? NSNumber)?.intValue } ?? [] }
    var width: Double? { meta.double("w") }
    var height: Double? { meta.double("h") }
    var fileName: String { meta.str("name") ?? "Файл" }
    var fileSize: Int? { meta.int("size") }
    var isVideoCall: Bool { meta.bool("video") }

    static func previewText(kind: String, body: String?) -> String {
        let b = (body ?? "").replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "").replacingOccurrences(of: "~~", with: "")
        switch kind {
        case "voice": return "Голосовое сообщение"
        case "video_note": return "Видеосообщение"
        case "image": return b.isEmpty ? "Фото" : b
        case "video": return b.isEmpty ? "Видео" : b
        case "file": return "Файл"
        case "sticker": return "Стикер"
        case "call": return "Звонок"
        default: return b
        }
    }

    /// Значок вместо эмодзи для превью (как иконки на сайте)
    static func previewIcon(kind: String) -> String? {
        switch kind {
        case "voice": return "mic.fill"
        case "video_note": return "video.circle.fill"
        case "image": return "photo"
        case "video": return "video.fill"
        case "file": return "doc.fill"
        case "sticker": return "face.smiling"
        case "call": return "phone.fill"
        default: return nil
        }
    }

    var preview: String {
        if deleted { return "Сообщение удалено" }
        if kind == "file" { return "Файл: " + fileName }
        return Message.previewText(kind: kind, body: body)
    }
}

struct SearchResult: Identifiable {
    var id: String
    var kind: String
    var name: String
    var username: String?
    var avatarURL: String?
    var color: Int
    var extra: String?

    init(json j: JSON) {
        id = j.str("id") ?? ""
        kind = j.str("kind") ?? "user"
        name = j.str("name") ?? ""
        username = j.str("username")
        avatarURL = j.str("avatar_url").flatMap { $0.isEmpty ? nil : $0 }
        color = j.int("color") ?? 0
        extra = j.str("extra")
    }
}

struct Reaction: Equatable {
    var messageId: Int
    var userId: String
    var emoji: String
    init(messageId: Int, userId: String, emoji: String) { self.messageId = messageId; self.userId = userId; self.emoji = emoji }
    init(json j: JSON) {
        messageId = j.int("message_id") ?? 0
        userId = j.str("user_id") ?? ""
        emoji = j.str("emoji") ?? ""
    }
}

struct StoryItem: Identifiable, Equatable {
    var id: Int
    var userId: String
    var name: String
    var username: String
    var avatarURL: String?
    var color: Int
    var kind: String
    var mediaURL: String
    var caption: String
    var createdAt: Date
    var seen: Bool
    var views: Int

    init(json j: JSON) {
        id = j.int("id") ?? 0
        userId = j.str("user_id") ?? ""
        name = j.str("name") ?? ""
        username = j.str("username") ?? ""
        avatarURL = j.str("avatar_url").flatMap { $0.isEmpty ? nil : $0 }
        color = j.int("color") ?? 0
        kind = j.str("kind") ?? "image"
        mediaURL = j.str("media_url") ?? ""
        caption = j.str("caption") ?? ""
        createdAt = j.date("created_at") ?? Date()
        seen = j.bool("seen")
        views = j.int("views") ?? 0
    }
}

struct StoryGroup: Identifiable, Equatable {
    var id: String { userId }
    var userId: String
    var name: String
    var avatarURL: String?
    var color: Int
    var items: [StoryItem]
    var unseen: Bool
    var last: Date
}

struct Member: Identifiable, Equatable {
    var id: String { userId }
    var userId: String
    var role: String
}

enum ReportReason: String, CaseIterable, Identifiable {
    case spam, abuse, fraud, violence, adult, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .spam: return "Спам"
        case .abuse: return "Оскорбления или травля"
        case .fraud: return "Мошенничество"
        case .violence: return "Угрозы или насилие"
        case .adult: return "Неприемлемый контент"
        case .other: return "Другое"
        }
    }
}
