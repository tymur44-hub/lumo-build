import Foundation
import Security

struct SavedAccount: Codable, Identifiable {
    var id: String
    var name: String
    var username: String
    var avatar: String?
    var session: AuthSession
}

/// Несколько аккаунтов в одном приложении: входы хранятся в связке ключей
@MainActor
final class Accounts: ObservableObject {
    static let shared = Accounts()
    @Published private(set) var list: [SavedAccount] = []
    private let service = "ru.volshebnymir.lumo.accounts"

    private init() {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        if SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data,
           let l = try? JSONDecoder().decode([SavedAccount].self, from: d) { list = l }
    }

    private func save() {
        guard let d = try? JSONEncoder().encode(list) else { return }
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = d
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    func saveTokens(_ s: AuthSession) {
        guard !s.userId.isEmpty else { return }
        if let i = list.firstIndex(where: { $0.id == s.userId }) { list[i].session = s }
        else { list.append(SavedAccount(id: s.userId, name: "", username: "", avatar: nil, session: s)) }
        save()
    }

    func info(_ id: String, name: String, username: String, avatar: String?) {
        guard let i = list.firstIndex(where: { $0.id == id }) else { return }
        list[i].name = name; list[i].username = username; list[i].avatar = avatar
        save()
    }

    func remove(_ id: String) { list.removeAll { $0.id == id }; save() }

    /// Premium — до 3 аккаунтов, без Premium — один
    func limit() -> Int { AppModel.shared.isPremium ? 3 : 1 }
}
