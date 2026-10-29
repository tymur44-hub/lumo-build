import Foundation
import Contacts
import SwiftUI

struct MatchedContact: Identifiable {
    let id: String          // user id
    let phone: String
    let name: String
    let username: String
    let avatarURL: URL?
    let color: Int
    let bookName: String
}
struct InviteContact: Identifiable { let id: String; let name: String; let phone: String }

/// Номер телефона, двухэтапная защита и сверка контактов
@MainActor
final class PhoneStore: ObservableObject {
    static let shared = PhoneStore()
    @Published var phone: String?
    @Published var status = "ok"          // ok | remind | skipped | required
    @Published var tfa = false
    @Published var hint = ""
    @Published var loaded = false
    @Published var matched: [MatchedContact] = []
    @Published var invites: [InviteContact] = []
    @Published var contactsState = "unknown"   // unknown | denied | ok
    @Published var syncing = false
    @Published var reminderShown = false
    @Published var skipUntil: Date?
    var skipText: String {
        guard let d = skipUntil else { return "окончания отсрочки" }
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "d MMMM"
        return f.string(from: d)
    }

    func reset() {
        phone = nil; status = "ok"; tfa = false; hint = ""; loaded = false; matched = []; invites = []; reminderShown = false
    }

    /// Запрос к функции lumo-phone. Ошибки сервера приходят полем error
    func call(_ path: String, _ body: JSON, auth: Bool = false) async throws -> JSON {
        let r = try await API.shared.raw("POST", "/functions/v1/lumo-phone/" + path, body: body, auth: auth) as? JSON ?? [:]
        return r
    }

    static func message(_ code: String, _ j: JSON = [:]) -> String {
        switch code {
        case "bad_phone": return "Введите российский номер мобильного телефона"
        case "bad_code": return "Неверный код"
        case "expired": return "Код устарел — запросите новый"
        case "locked": return "Слишком много попыток — запросите новый код"
        case "too_many": return "Слишком много кодов. Попробуйте через час"
        case "wait": return "Новый код можно запросить через минуту"
        case "busy": return "Сервис занят, попробуйте позже"
        case "sms_off", "sms_fail": return "Отправка кодов пока недоступна"
        case "phone_taken": return "Этот номер уже привязан к другому аккаунту"
        case "banned": return "Аккаунт заблокирован"
        case "bad_tfa": return "Неверный пароль"
        default: return "Не удалось выполнить действие"
        }
    }

    func load() async {
        guard let r = try? await API.shared.rpc("lm_my_phone") else { return }
        let o = (r as? JSON) ?? ((r as? [JSON])?.first) ?? [:]
        phone = o.str("phone")
        status = o.str("status") ?? "ok"
        tfa = (o["tfa"] as? Bool) ?? false
        hint = o.str("hint") ?? ""
        skipUntil = o.date("skip_until")
        loaded = true
    }

    func skip() async {
        _ = try? await API.shared.rpc("lm_phone_skip")
        await load()
    }

    static func pretty(_ p: String?) -> String {
        guard let p, p.count == 11 else { return p ?? "" }
        let d = Array(p)
        return "+7 (\(String(d[1...3]))) \(String(d[4...6]))-\(String(d[7...8]))-\(String(d[9...10]))"
    }

    // MARK: - контакты

    static func normalize(_ raw: String) -> String? {
        var d = raw.filter { $0.isNumber }
        if d.count == 11, d.hasPrefix("8") { d = "7" + d.dropFirst() }
        if d.count == 10, d.hasPrefix("9") { d = "7" + d }
        return d.count == 11 && d.hasPrefix("79") ? d : nil
    }

    func requestContacts() async -> Bool {
        let store = CNContactStore()
        let st = CNContactStore.authorizationStatus(for: .contacts)
        if st == .authorized { contactsState = "ok"; return true }
        if st == .notDetermined {
            let ok = (try? await store.requestAccess(for: .contacts)) ?? false
            contactsState = ok ? "ok" : "denied"
            return ok
        }
        contactsState = "denied"
        return false
    }

    /// Тихая сверка, если доступ к контактам уже разрешён
    func syncIfAllowed() async {
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized { await syncContacts() }
        else if CNContactStore.authorizationStatus(for: .contacts) == .denied { contactsState = "denied" }
    }

    /// Прочитать записную книжку и узнать, кто из знакомых уже в Lumo
    func syncContacts() async {
        guard !syncing else { return }
        guard await requestContacts() else { return }
        syncing = true
        defer { syncing = false }
        let book: [(String, String)] = await Task.detached(priority: .utility) { () -> [(String, String)] in
            let store = CNContactStore()
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            var out: [(String, String)] = []
            let req = CNContactFetchRequest(keysToFetch: keys)
            try? store.enumerateContacts(with: req) { c, _ in
                let n = (c.givenName + " " + c.familyName).trimmingCharacters(in: .whitespaces)
                for p in c.phoneNumbers {
                    if let d = PhoneStore.normalize(p.value.stringValue) { out.append((n.isEmpty ? "+" + d : n, d)) }
                }
            }
            return out
        }.value
        var names: [String: String] = [:]
        for (n, p) in book where names[p] == nil { names[p] = n }
        let phones = Array(names.keys)
        var found: [MatchedContact] = []
        var i = 0
        while i < phones.count {
            let chunk = Array(phones[i..<min(i + 400, phones.count)]); i += 400
            if let rows = try? await API.shared.rpc("lm_match_contacts", ["p_phones": chunk]) as? [JSON] {
                for r in rows {
                    guard let uid = r.str("user_id"), let ph = r.str("phone") else { continue }
                    found.append(MatchedContact(id: uid, phone: ph, name: r.str("name") ?? "", username: r.str("username") ?? "",
                                                avatarURL: r.str("avatar_url").flatMap { URL(string: $0) }, color: r.int("color") ?? 0,
                                                bookName: names[ph] ?? ""))
                }
            }
        }
        let foundPhones = Set(found.map { $0.phone })
        matched = found.sorted { $0.bookName.localizedCompare($1.bookName) == .orderedAscending }
        invites = phones.filter { !foundPhones.contains($0) }.map { InviteContact(id: $0, name: names[$0] ?? "", phone: $0) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
