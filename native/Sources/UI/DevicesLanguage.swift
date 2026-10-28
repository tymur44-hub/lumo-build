import SwiftUI

/// Раздел «Устройства»: все активные сеансы аккаунта
struct DevicesView: View {
    @EnvironmentObject var model: AppModel
    @State private var items: [DeviceSession] = []
    @State private var loaded = false
    @State private var confirmAll = false

    private func icon(_ p: String) -> String {
        switch p { case "ios": return "iphone"; case "android": return "smartphone"; case "windows": return "desktopcomputer"; default: return "globe" }
    }
    private func title(_ p: String) -> String {
        switch p { case "ios": return "iPhone / iPad"; case "android": return "Android"; case "windows": return "Windows"; default: return "Сайт" }
    }
    private func when(_ d: Date?) -> String {
        guard let d else { return "" }
        if Date().timeIntervalSince(d) < 120 { return "онлайн" }
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = Calendar.current.isDateInToday(d) ? "сегодня в HH:mm" : "d MMM в HH:mm"
        return f.string(from: d)
    }

    var body: some View {
        let me = AppModel.deviceId
        let current = items.first { $0.deviceId == me }
        let others = items.filter { $0.deviceId != me }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Это устройство")
                SettingsGroup {
                    if let c = current { row(c, current: true) }
                    else { SettingsRow(icon: "iphone", color: Color(hex: 0x2bd67b), title: AppModel.deviceName, subtitle: "онлайн") }
                }
                if !others.isEmpty {
                    Button(role: .destructive) { confirmAll = true } label: {
                        Text("Завершить все другие сеансы").font(.system(size: 16, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.danger)
                    }
                    .padding(.horizontal, 10)
                    SectionTitle(text: "Активные сеансы")
                    SettingsGroup {
                        ForEach(Array(others.enumerated()), id: \.element.id) { i, d in
                            if i > 0 { Divider().overlay(Theme.line) }
                            row(d, current: false)
                        }
                    }
                } else if loaded {
                    Text("Других активных сеансов нет.").font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 16)
                }
                Text("Здесь видны устройства, на которых вы вошли в Lumo через приложения для iPhone и Android. Если не узнаёте устройство — завершите сеанс. Вход через сайт и Windows пока в списке не отображается.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Устройства").navigationBarTitleDisplayMode(.inline)
        .task { await model.touchSession(); items = await model.loadSessions(); loaded = true }
        .refreshable { items = await model.loadSessions() }
        .confirmationDialog("Завершить все другие сеансы?", isPresented: $confirmAll, titleVisibility: .visible) {
            Button("Завершить", role: .destructive) {
                Task {
                    for d in others { await model.endSession(d.id) }
                    items = await model.loadSessions()
                }
            }
        }
    }

    private func row(_ d: DeviceSession, current: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(d.platform)).font(.system(size: 18)).foregroundColor(.white)
                .frame(width: 38, height: 38).background(RoundedRectangle(cornerRadius: 11).fill(current ? Color(hex: 0x2bd67b) : Theme.a1))
            VStack(alignment: .leading, spacing: 2) {
                Text(d.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                Text("Lumo " + d.version + " · " + title(d.platform) + " · " + when(d.lastActive)).font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            if !current {
                Button { Task { await model.endSession(d.id); items.removeAll { $0.id == d.id } } } label: {
                    Text("Завершить").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.danger)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
    }
}

/// Язык приложения
enum Lang {
    static let all: [(code: String, title: String, native: String)] = [("ru", "Русский", "Русский"), ("en", "English", "Английский"), ("tt", "Татарча", "Татарский")]
    static var current: String { UserDefaults.standard.string(forKey: "lm_lang") ?? "ru" }

    /// Перевод строки, не попадающей в SwiftUI-тексты (уведомления, подсказки)
    static func tr(_ s: String) -> String {
        let c = current
        guard c != "ru", let p = Bundle.main.path(forResource: c, ofType: "lproj"), let b = Bundle(path: p) else { return s }
        return b.localizedString(forKey: s, value: s, table: nil)
    }
}

struct LanguageView: View {
    @AppStorage("lm_lang") private var lang = "ru"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SettingsGroup {
                    ForEach(Array(Lang.all.enumerated()), id: \.element.code) { i, l in
                        if i > 0 { Divider().overlay(Theme.line) }
                        Button { withAnimation(.easeInOut(duration: 0.25)) { lang = l.code } } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: l.title).font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text)
                                    Text(verbatim: l.native).font(.caption).foregroundColor(Theme.muted)
                                }
                                Spacer()
                                if lang == l.code { Image(systemName: "checkmark").foregroundColor(Theme.a1).font(.system(size: 16, weight: .bold)) }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12).contentShape(Rectangle())
                        }
                    }
                }
                Text("Язык интерфейса меняется сразу. Названия чатов и сообщения не переводятся. Часть подписей пока доступна только на русском.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Язык").navigationBarTitleDisplayMode(.inline)
    }
}
