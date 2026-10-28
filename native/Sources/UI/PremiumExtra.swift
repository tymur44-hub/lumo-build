import SwiftUI
import CryptoKit
import LocalAuthentication

/// Локальные настройки Premium: цвет сообщений в чатах и блокировка приложения
final class ExtraStore: ObservableObject {
    static let shared = ExtraStore()
    private let d = UserDefaults.standard
    static let bubs: [(UInt32, UInt32)?] = [
        nil, (0xff3d6e, 0xff8a5b), (0x00c6ff, 0x0072ff), (0x43e97b, 0x12b886), (0xf7971e, 0xffb020),
        (0xfa709a, 0xb66cff), (0x667eea, 0x764ba2), (0x475569, 0x1e293b),
    ]
    @Published var bub: [String: Int]
    @Published var hasLock: Bool
    @Published var locked: Bool
    @Published var faceId: Bool
    var lastStop: Date?

    private init() {
        bub = (UserDefaults.standard.dictionary(forKey: "lm_bub") as? [String: Int]) ?? [:]
        let h = UserDefaults.standard.string(forKey: "lm_lock")
        hasLock = !(h ?? "").isEmpty
        locked = !(h ?? "").isEmpty
        faceId = !(h ?? "").isEmpty && UserDefaults.standard.bool(forKey: "lm_faceid")
    }

    /// Есть ли на устройстве Face ID или Touch ID
    var bioAvailable: Bool { LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) }
    var bioName: String { let c = LAContext(); _ = c.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil); return c.biometryType == .touchID ? "Touch ID" : "Face ID" }

    func setFaceId(_ on: Bool) { faceId = on; d.set(on, forKey: "lm_faceid") }

    func unlockWithBio() {
        let c = LAContext()
        c.localizedCancelTitle = "Код доступа"
        c.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Разблокировать Lumo") { ok, _ in
            DispatchQueue.main.async { if ok { self.locked = false } }
        }
    }

    func setBub(_ chat: String, _ i: Int) {
        if i == 0 { bub.removeValue(forKey: chat) } else { bub[chat] = i }
        d.set(bub, forKey: "lm_bub")
    }

    @MainActor func bubFill(_ chat: String) -> AnyShapeStyle {
        guard AppModel.shared.isPremium, let i = bub[chat], i > 0, i < ExtraStore.bubs.count, let c = ExtraStore.bubs[i] else { return AnyShapeStyle(Theme.out) }
        return AnyShapeStyle(LinearGradient(colors: [Color(hex: c.0), Color(hex: c.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func hash(_ pin: String) -> String {
        SHA256.hash(data: Data(("lumo-lock:" + pin).utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func setPin(_ pin: String?) {
        if let p = pin { d.set(hash(p), forKey: "lm_lock"); hasLock = true }
        else { d.removeObject(forKey: "lm_lock"); d.removeObject(forKey: "lm_faceid"); hasLock = false; locked = false; faceId = false }
    }

    func check(_ pin: String) -> Bool { d.string(forKey: "lm_lock") == hash(pin) }

    func scene(active: Bool) {
        if !active { lastStop = Date(); return }
        if hasLock, let t = lastStop, Date().timeIntervalSince(t) > 60 { locked = true }
    }
}

// MARK: - Цвет сообщений в чате

struct BubbleColorSheet: View {
    @ObservedObject private var ex = ExtraStore.shared
    @Environment(\.dismiss) private var dismiss
    let chatId: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Только для этого чата, на этом устройстве.").font(.footnote).foregroundColor(Theme.muted)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(0..<ExtraStore.bubs.count, id: \.self) { i in
                        let c = ExtraStore.bubs[i]
                        Circle()
                            .fill(c.map { AnyShapeStyle(LinearGradient(colors: [Color(hex: $0.0), Color(hex: $0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)) } ?? AnyShapeStyle(Theme.panel2))
                            .frame(width: 52, height: 52)
                            .overlay(Circle().stroke(Theme.text, lineWidth: (ex.bub[chatId] ?? 0) == i ? 3 : 0).padding(-4))
                            .onTapGesture { ex.setBub(chatId, i); dismiss() }
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Цвет сообщений").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Блокировка приложения

struct PinPadView: View {
    let title: String
    var error: String?
    var onDone: (String) -> Void
    @State private var pin = ""

    var body: some View {
        VStack(spacing: 14) {
            Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text).multilineTextAlignment(.center)
            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { i in Circle().fill(i < pin.count ? Theme.a1 : Theme.muted.opacity(0.3)).frame(width: 14, height: 14) }
            }
            Text(error ?? " ").font(.system(size: 13)).foregroundColor(Theme.danger).frame(height: 18)
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]], id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(row, id: \.self) { k in
                        if k.isEmpty { Color.clear.frame(width: 70, height: 70) }
                        else {
                            Button {
                                if k == "⌫" { if !pin.isEmpty { pin.removeLast() } }
                                else if pin.count < 4 { pin += k; if pin.count == 4 { let p = pin; onDone(p) } }
                            } label: {
                                Text(k).font(.system(size: 26, weight: .medium)).foregroundColor(Theme.text)
                                    .frame(width: 70, height: 70).background(Circle().fill(Theme.panel2))
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: error) { e in if e != nil { pin = "" } }
        .id(title)
    }
}

/// Экран блокировки поверх приложения
struct LockOverlayView: View {
    @ObservedObject private var ex = ExtraStore.shared
    @State private var err: String?

    var body: some View {
        if ex.hasLock && ex.locked {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 18) {
                    PinPadView(title: "Введите код доступа", error: err) { pin in
                        if ex.check(pin) { err = nil; ex.locked = false } else { err = "Неверный код" }
                    }
                    if ex.faceId {
                        Button { ex.unlockWithBio() } label: {
                            Label("Войти по \(ex.bioName)", systemImage: "faceid").font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
            .onAppear { if ex.faceId { ex.unlockWithBio() } }
            .transition(.opacity)
        }
    }
}

struct LockSettingsSheet: View {
    @ObservedObject private var ex = ExtraStore.shared
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var step: String = ExtraStore.shared.hasLock ? "menu" : "new"
    @State private var first = ""
    @State private var err: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                switch step {
                case "menu":
                    Text("Блокировка включена").font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.text)
                    Text("Код спрашивается при входе и после сворачивания больше чем на минуту.").font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    if ex.bioAvailable {
                        Toggle(isOn: Binding(get: { ex.faceId }, set: { ex.setFaceId($0) })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.bioName).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                Text("Разблокировка без ввода кода").font(.footnote).foregroundColor(Theme.muted)
                            }
                        }
                    }
                    Button("Сменить код") { step = "old-change" }.font(.system(size: 17, weight: .bold))
                    Button("Выключить", role: .destructive) { step = "old-off" }.font(.system(size: 17, weight: .bold))
                case "old-change", "old-off":
                    PinPadView(title: "Введите текущий код", error: err) { pin in
                        if ex.check(pin) {
                            err = nil
                            if step == "old-off" { ex.setPin(nil); model.say("Блокировка выключена"); dismiss() } else { step = "new" }
                        } else { err = "Неверный код" }
                    }
                case "new":
                    PinPadView(title: "Придумайте код из 4 цифр", error: nil) { pin in first = pin; err = nil; step = "again" }
                default:
                    PinPadView(title: "Повторите код", error: err) { pin in
                        if pin == first { ex.setPin(pin); model.say("Блокировка включена"); dismiss() } else { err = "Коды не совпали"; step = "new" }
                    }
                }
                Spacer()
            }
            .padding(24)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Блокировка").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Расширенный профиль: ссылки

struct ProfileExtraSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var titles = ["", "", ""]
    @State private var urls = ["", "", ""]
    @State private var cover: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("До 3 ссылок в вашем профиле.").font(.footnote).foregroundColor(Theme.muted)
                    ForEach(0..<3, id: \.self) { i in
                        TextField("Название", text: $titles[i]).lumoField()
                        TextField("https://…", text: $urls[i]).lumoField().keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    GradientButton(title: "Сохранить", loading: false) { save() }.padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Расширенный профиль").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
            .task { await load() }
        }
    }

    private func load() async {
        guard let id = model.myId, let r = try? await API.shared.rpc("lm_profile_extra", ["p_id": id]) else { return }
        let o = (r as? [String: Any]) ?? ((r as? [[String: Any]])?.first)
        cover = o?["cover"] as? String
        for (i, l) in ((o?["links"] as? [[String: Any]]) ?? []).prefix(3).enumerated() {
            titles[i] = (l["title"] as? String) ?? ""; urls[i] = (l["url"] as? String) ?? ""
        }
    }

    private func save() {
        var links: [[String: Any]] = []
        for i in 0..<3 {
            let t = titles[i].trimmingCharacters(in: .whitespaces), u = urls[i].trimmingCharacters(in: .whitespaces)
            if !t.isEmpty, u.lowercased().hasPrefix("http://") || u.lowercased().hasPrefix("https://") { links.append(["title": t, "url": u]) }
        }
        Task {
            do {
                var p: JSON = ["p_links": links]
                p["p_cover"] = cover ?? NSNull()
                _ = try await API.shared.rpc("lm_set_profile_extra", p)
                model.say("Профиль обновлён"); dismiss()
            } catch { model.say((error as? APIError)?.message ?? "Не удалось сохранить") }
        }
    }
}

/// Ссылки в чужом профиле (у пользователей Premium)
struct ProfileLinksView: View {
    let userId: String
    @State private var links: [(String, String)] = []

    var body: some View {
        Group {
            if !links.isEmpty {
                SettingsGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ссылки").font(.caption.weight(.bold)).foregroundColor(Theme.muted)
                        ForEach(Array(links.enumerated()), id: \.offset) { _, l in
                            if let u = URL(string: l.1) { Link(l.0, destination: u).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.a2) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                }
            }
        }
        .task {
            guard let r = try? await API.shared.rpc("lm_profile_extra", ["p_id": userId]) else { return }
            let o = (r as? [String: Any]) ?? ((r as? [[String: Any]])?.first)
            links = ((o?["links"] as? [[String: Any]]) ?? []).compactMap { l in
                guard let t = l["title"] as? String, let u = l["url"] as? String, u.hasPrefix("http") else { return nil }
                return (t, u)
            }
        }
    }
}

/// Строка «Расширенный профиль» в редактировании профиля
struct ExtraProfileRow: View {
    @EnvironmentObject var model: AppModel
    @Binding var show: Bool

    var body: some View {
        Button { model.premium { show = true } } label: {
            TGIconRow(icon: "link", color: Color(hex: 0xffb020), title: "Расширенный профиль", value: "Ссылки · Premium")
        }
        .buttonStyle(RowButtonStyle())
    }
}

// MARK: - Защищённые чаты

/// Запрет пересылки, копирования и скриншотов: серверный флаг чата. iOS не позволяет блокировать скриншот, поэтому экран скрывается при записи
final class ProtStore: ObservableObject {
    static let shared = ProtStore()
    @Published var map: [String: Bool] = [:]
    @Published var captured = UIScreen.main.isCaptured
    private var obs: NSObjectProtocol?

    private init() {
        obs = NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.captured = UIScreen.main.isCaptured
        }
    }

    func on(_ id: String?) -> Bool { id.map { map[$0] == true } ?? false }

    func load(_ id: String) async {
        let r = try? await API.shared.select("lm_chats", ["select": "protected", "id": "eq." + id]).first
        if let v = r?["protected"] as? Bool { await MainActor.run { map[id] = v } }
    }

    func set(_ id: String, _ on: Bool) async {
        do {
            _ = try await API.shared.rpc("lm_set_protected", ["p_chat": id, "p_on": on])
            await MainActor.run { map[id] = on }
        } catch { await MainActor.run { AppModel.shared.say((error as? APIError)?.message ?? "Не удалось изменить") } }
    }
}
