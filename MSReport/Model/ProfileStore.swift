import Foundation
import Observation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var shopName: String = ""
    var city: String = ""
    var points: Int = 1
    /// Цель по выручке в месяц, ₽. 0 — не задана.
    var monthlyGoal: Double = 0
    var createdAt: Date = Date()

    var initials: String {
        let source = name.isEmpty ? shopName : name
        let letters = source
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
        return letters.isEmpty ? "MS" : letters
    }

    var displayName: String { name.isEmpty ? "Гость" : name }
}

/// Личный кабинет: хранится на телефоне.
@Observable
final class ProfileStore {
    var profile: UserProfile {
        didSet { save() }
    }

    var onboarded: Bool {
        didSet { UserDefaults.standard.set(onboarded, forKey: "onboarded") }
    }

    var haptics: Bool {
        didSet { UserDefaults.standard.set(haptics, forKey: "haptics") }
    }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "profile"),
           let p = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = p
        } else {
            profile = UserProfile()
        }
        onboarded = defaults.bool(forKey: "onboarded")
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
    }

    func reset() {
        profile = UserProfile()
        onboarded = false
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "profile")
        }
    }
}
