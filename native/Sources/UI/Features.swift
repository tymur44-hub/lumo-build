import SwiftUI
import PhotosUI
import UserNotifications

// MARK: - Ответить позже

struct PendingReply: Equatable {
    let chat: String
    let msg: Int
}

struct ReplyReminder: Identifiable, Equatable {
    let id: Int
    let chatId: String
    let messageId: Int
    let at: Date
}

/// Напоминания «Ответить позже»: список на сервере (общий для устройств), уведомления — локальные на телефоне
@MainActor
final class Reminders: ObservableObject {
    static let shared = Reminders()
    @Published private(set) var list: [ReplyReminder] = []
    /// тексты сообщений для списка (уже расшифрованные)
    @Published private(set) var previews: [Int: Message] = [:]

    func load() async {
        guard let a = (try? await API.shared.rpc("lm_remind_list")) as? [JSON] else { return }
        list = a.compactMap { j in
            guard let id = j.int("id"), let c = j.str("chat_id"), let m = j.int("message_id"), let at = j.date("remind_at") else { return nil }
            return ReplyReminder(id: id, chatId: c, messageId: m, at: at)
        }
        await loadPreviews()
        reschedule()
    }

    private func loadPreviews() async {
        let need = list.map { $0.messageId }.filter { previews[$0] == nil }
        guard !need.isEmpty else { return }
        let rows = (try? await API.shared.select("lm_messages", ["select": "*", "id": "in.(" + need.map(String.init).joined(separator: ",") + ")"])) ?? []
        for r in rows {
            var m = Message(json: r)
            if E2E.isEnc(m.body) {
                await AppModel.shared.prep(m.chatId)
                m.body = E2E.shared.decrypt(m.chatId, m.body)
            }
            previews[m.id] = m
            if let s = m.senderId { await AppModel.shared.loadProfiles([s]) }
        }
    }

    func set(_ m: Message, at: Date) async {
        do {
            _ = try await API.shared.rpc("lm_remind_set", ["p_msg": m.id, "p_at": DateParser.string(at)])
            previews[m.id] = m
            await load()
            AppModel.shared.say("Напомню " + Reminders.whenText(at))
        } catch { AppModel.shared.say(error.localizedDescription) }
    }

    func remove(_ msgId: Int) async {
        _ = try? await API.shared.rpc("lm_remind_del", ["p_msg": msgId])
        list.removeAll { $0.messageId == msgId }
        reschedule()
    }

    /// ответили в чате — сервер уже снял напоминания, убираем и тут
    func repliedIn(_ chatId: String) {
        guard list.contains(where: { $0.chatId == chatId }) else { return }
        list.removeAll { $0.chatId == chatId }
        reschedule()
    }

    /// локальные уведомления: «Вы хотели ответить …»
    private func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let old = reqs.map { $0.identifier }.filter { $0.hasPrefix("remind-") }
            center.removePendingNotificationRequests(withIdentifiers: old)
            Task { @MainActor in
                for r in self.list where r.at > Date() {
                    let c = UNMutableNotificationContent()
                    let m = self.previews[r.messageId]
                    let who = AppModel.shared.displayName(m?.senderId)
                    c.title = "Ответить позже"
                    let text = m.map { Message.previewText(kind: $0.kind, body: $0.body) } ?? "Сообщение"
                    c.body = "Вы хотели ответить: \(who) — «\(text.prefix(90))»"
                    c.sound = .default
                    c.threadIdentifier = r.chatId
                    c.userInfo = ["chat": r.chatId, "msg": r.messageId]
                    let t = UNTimeIntervalNotificationTrigger(timeInterval: max(1, r.at.timeIntervalSinceNow), repeats: false)
                    center.add(UNNotificationRequest(identifier: "remind-\(r.messageId)", content: c, trigger: t))
                }
            }
        }
    }

    static func whenText(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "HH:mm"
        if cal.isDateInToday(d) { return "сегодня в " + f.string(from: d) }
        if cal.isDateInTomorrow(d) { return "завтра в " + f.string(from: d) }
        f.dateFormat = "d MMMM в HH:mm"
        return f.string(from: d)
    }
}

/// Выбор времени для «Ответить позже»
struct RemindPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let message: Message
    @State private var custom = Date().addingTimeInterval(3 * 3600)
    @State private var showCustom = false

    private var presets: [(String, String, Date)] {
        let cal = Calendar.current, now = Date()
        var out: [(String, String, Date)] = [("Через час", "clock", now.addingTimeInterval(3600))]
        if let ev = cal.date(bySettingHour: 20, minute: 0, second: 0, of: now), ev > now.addingTimeInterval(1800) {
            out.append(("Сегодня вечером", "moon.stars", ev))
        }
        if let t = cal.date(byAdding: .day, value: 1, to: now), let m = cal.date(bySettingHour: 9, minute: 0, second: 0, of: t) {
            out.append(("Завтра утром", "sunrise", m))
        }
        if let w = cal.nextDate(after: now, matching: DateComponents(hour: 10, weekday: 7), matchingPolicy: .nextTime) {
            out.append(("В выходные", "cup.and.saucer", w))
        }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Theme.line).frame(width: 40, height: 5).padding(.top, 8)
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(hex: 0xffb347), Color(hex: 0xff6a3d)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "bell.badge.fill").font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
                }.frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ответить позже").font(.system(size: 19, weight: .bold)).foregroundColor(Theme.text)
                    Text("Напомню и открою это сообщение").font(.system(size: 14)).foregroundColor(Theme.muted)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 10)
            Text("«" + String(Message.previewText(kind: message.kind, body: message.body).prefix(120)) + "»")
                .font(.system(size: 14)).foregroundColor(Theme.muted).lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12).background(Theme.panel2, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            VStack(spacing: 0) {
                ForEach(Array(presets.enumerated()), id: \.offset) { i, p in
                    if i > 0 { Divider().overlay(Theme.line).padding(.leading, 56) }
                    Button { pick(p.2) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: p.1).font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.a1).frame(width: 26)
                            Text(p.0).font(.system(size: 17)).foregroundColor(Theme.text)
                            Spacer()
                            Text(Reminders.whenText(p.2)).font(.system(size: 14)).foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 16).frame(height: 54).contentShape(Rectangle())
                    }.buttonStyle(RowButtonStyle())
                }
                Divider().overlay(Theme.line).padding(.leading, 56)
                Button { withAnimation(.easeOut(duration: 0.2)) { showCustom.toggle() } } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.a1).frame(width: 26)
                        Text("Выбрать время").font(.system(size: 17)).foregroundColor(Theme.text)
                        Spacer()
                        Image(systemName: showCustom ? "chevron.up" : "chevron.down").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 16).frame(height: 54).contentShape(Rectangle())
                }.buttonStyle(RowButtonStyle())
                if showCustom {
                    DatePicker("", selection: $custom, in: Date().addingTimeInterval(120)..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical).labelsHidden().environment(\.locale, Locale(identifier: "ru_RU"))
                        .padding(.horizontal, 10)
                    GradientButton(title: "Напомнить " + Reminders.whenText(custom)) { pick(custom) }
                        .padding(.horizontal, 16).padding(.bottom, 12)
                }
            }
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 16).padding(.top, 14)
            Spacer(minLength: 10)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents(showCustom ? [.large] : [.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func pick(_ d: Date) {
        let m = message
        dismiss()
        Task { await Reminders.shared.set(m, at: d) }
    }
}

/// Полоска «Ждут ответа · N» над списком чатов
struct RemindersBar: View {
    @ObservedObject var store = Reminders.shared
    @State private var open = false
    var body: some View {
        if !store.list.isEmpty {
            Button { open = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [Color(hex: 0xffb347), Color(hex: 0xff6a3d)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Image(systemName: "bell.badge.fill").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    }.frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ждут ответа · \(store.list.count)").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                        if let n = store.list.first {
                            Text("Ближайшее — " + Reminders.whenText(n.at)).font(.system(size: 13)).foregroundColor(Theme.muted)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 2).padding(.vertical, 6)
            }
            .buttonStyle(BouncyButtonStyle())
            .sheet(isPresented: $open) { RemindersSheet().environmentObject(AppModel.shared) }
        }
    }
}

struct RemindersSheet: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var store = Reminders.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if store.list.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.circle").font(.system(size: 44)).foregroundColor(Theme.a2)
                            Text("Вы на всё ответили").font(.headline).foregroundColor(Theme.text)
                        }.padding(.top, 60)
                    }
                    ForEach(store.list) { r in
                        let m = store.previews[r.messageId]
                        let c = model.chat(r.chatId)
                        Button {
                            dismiss()
                            model.pendingReply = PendingReply(chat: r.chatId, msg: r.messageId)
                            model.open(r.chatId)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                AvatarView(name: c?.displayName ?? "", url: c?.displayAvatar, color: c?.displayColor ?? 0, size: 46)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(c?.displayName ?? "Чат").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                                        Spacer()
                                        Text(Reminders.whenText(r.at)).font(.system(size: 12.5, weight: .semibold))
                                            .foregroundColor(r.at < Date() ? Color(hex: 0xff6a3d) : Theme.muted)
                                    }
                                    if let m = m, c?.isPrivate == false {
                                        Text(model.displayName(m.senderId)).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.a2)
                                    }
                                    Text(m.map { Message.previewText(kind: $0.kind, body: $0.body) } ?? "Сообщение")
                                        .font(.system(size: 14.5)).foregroundColor(Theme.muted).lineLimit(2).multilineTextAlignment(.leading)
                                }
                            }
                            .padding(12).background(Theme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .contextMenu {
                            Button(role: .destructive) { Task { await store.remove(r.messageId) } } label: { Label("Убрать напоминание", systemImage: "bell.slash") }
                        }
                    }
                }
                .padding(14)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Ждут ответа").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .task { await store.load() }
        }
    }
}

// MARK: - Не беспокоить + Срочно

struct PeerDND: Equatable {
    let until: Date
    let text: String?
    let urgentOK: Bool
}

@MainActor
final class DNDStore: ObservableObject {
    static let shared = DNDStore()
    @Published var until: Date?
    @Published var text: String?
    @Published var urgentFrom = "contacts"
    @Published private(set) var peers: [String: PeerDND] = [:]
    /// итог после окончания режима
    @Published var summary: String?
    private var endTask: Task<Void, Never>?

    var active: Bool { (until ?? .distantPast) > Date() }

    func load() async {
        guard let j = (try? await API.shared.rpc("lm_my_dnd")) as? JSON else { return }
        until = j.date("until"); text = j.str("text"); urgentFrom = j.str("urgent") ?? "contacts"
        remember()
        await checkEnded()
    }

    func set(until u: Date?, text t: String?, urgent: String) async -> Bool {
        var p: JSON = ["p_text": t ?? "", "p_urgent": urgent]
        if let u = u { p["p_until"] = DateParser.string(u) } else { p["p_until"] = NSNull() }
        do {
            _ = try await API.shared.rpc("lm_set_dnd", p)
            let wasActive = active
            until = u; text = t; urgentFrom = urgent
            if u != nil && !wasActive { UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "dnd_from") }
            if u == nil, wasActive { await showSummary() }
            remember()
            return true
        } catch { AppModel.shared.say(error.localizedDescription); return false }
    }

    /// запоминаем окно режима, чтобы после окончания показать итог; таймер на момент окончания
    private func remember() {
        if let u = until, u > Date() {
            UserDefaults.standard.set(u.timeIntervalSince1970, forKey: "dnd_until")
            if UserDefaults.standard.double(forKey: "dnd_from") == 0 { UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "dnd_from") }
            endTask?.cancel()
            endTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(max(1, u.timeIntervalSinceNow) * 1_000_000_000))
                if !Task.isCancelled { await self.checkEnded() }
            }
        }
    }

    /// режим закончился (пока приложение было закрыто или прямо сейчас) — итог «пока вас не было»
    func checkEnded() async {
        let u = UserDefaults.standard.double(forKey: "dnd_until")
        guard u > 0, Date().timeIntervalSince1970 >= u, !active else { return }
        await showSummary()
    }

    private func showSummary() async {
        let from = UserDefaults.standard.double(forKey: "dnd_from")
        let to = min(Date().timeIntervalSince1970, UserDefaults.standard.double(forKey: "dnd_until") > 0 ? UserDefaults.standard.double(forKey: "dnd_until") : Date().timeIntervalSince1970)
        UserDefaults.standard.removeObject(forKey: "dnd_until")
        UserDefaults.standard.removeObject(forKey: "dnd_from")
        guard from > 0, to > from else { return }
        let p: JSON = ["p_from": DateParser.string(Date(timeIntervalSince1970: from)), "p_to": DateParser.string(Date(timeIntervalSince1970: Date().timeIntervalSince1970))]
        guard let j = (try? await API.shared.rpc("lm_dnd_summary", p)) as? JSON else { return }
        let n = j.int("msgs") ?? 0, c = j.int("chats") ?? 0, u2 = j.int("urgent") ?? 0
        if n == 0 { summary = "Пока вы были в режиме «Не беспокоить», новых сообщений не было."; return }
        summary = "\(n) \(plural(n, "сообщение", "сообщения", "сообщений")) в \(c) \(plural(c, "чате", "чатах", "чатах")). "
            + (u2 == 0 ? "Срочных не было." : "Срочных: \(u2).")
    }

    func loadPeers(_ ids: [String]) async {
        let list = Array(Set(ids.filter { !$0.isEmpty && $0 != AppModel.shared.myId }))
        guard !list.isEmpty, let a = (try? await API.shared.rpc("lm_dnd_get", ["p_ids": list])) as? [JSON] else { return }
        var got: [String: PeerDND] = [:]
        for j in a {
            if let id = j.str("id"), let u = j.date("dnd_until"), u > Date() { got[id] = PeerDND(until: u, text: j.str("dnd_text"), urgentOK: j.bool("urgent_ok")) }
        }
        for id in list { peers[id] = got[id] }
    }

    func peer(_ id: String?) -> PeerDND? {
        guard let id = id, let p = peers[id], p.until > Date() else { return nil }
        return p
    }

    func report(_ m: Message) async {
        do { _ = try await API.shared.rpc("lm_urgent_report", ["p_msg": m.id]); AppModel.shared.say("Понятно. Неделю этот человек не сможет отправлять вам срочные") }
        catch { AppModel.shared.say(error.localizedDescription) }
    }

    static func untilText(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "HH:mm"
        if Calendar.current.isDateInToday(d) { return "до " + f.string(from: d) }
        if Calendar.current.isDateInTomorrow(d) { return "до завтра " + f.string(from: d) }
        f.dateFormat = "d MMMM HH:mm"
        return "до " + f.string(from: d)
    }

    /// значок статуса «Не беспокоить»
    static func icon(_ text: String?) -> String {
        let t = (text ?? "").lowercased()
        if t.contains("сплю") || t.contains("сон") { return "moon.zzz.fill" }
        if t.contains("встреч") { return "calendar" }
        if t.contains("рул") { return "car.fill" }
        if t.contains("занят") { return "headphones" }
        if t.contains("дорог") || t.contains("полёт") || t.contains("самол") { return "airplane" }
        if t == "свой" { return "pencil" }
        return "moon.fill"
    }

    /// «Сплю до 08:00 · без звука»
    static func peerLine(_ p: PeerDND) -> String {
        let t = (p.text?.isEmpty == false ? p.text! : "Не беспокоить")
        return t + " " + untilText(p.until) + " · без звука"
    }
}

/// Настройка «Не беспокоить»
struct DNDSettingsView: View {
    @ObservedObject var dnd = DNDStore.shared
    @State private var status = "Сплю"
    @State private var custom = ""
    @State private var dur = 1
    @State private var urgent = "contacts"
    @State private var busy = false

    private let statuses = ["Сплю", "На встрече", "За рулём", "Занят", "В дороге", "Свой"]
    private let durations: [(String, Int)] = [("1 час", 1), ("2 часа", 2), ("4 часа", 4), ("До утра", -1), ("До завтра", 24)]

    private func untilDate() -> Date {
        let now = Date()
        if dur == -1 {
            let cal = Calendar.current
            var d = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(8 * 3600)
            if d <= now { d = cal.date(byAdding: .day, value: 1, to: d) ?? d }
            return d
        }
        return now.addingTimeInterval(Double(dur) * 3600)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient(colors: dnd.active ? [Color(hex: 0x7c5cff), Color(hex: 0x3a2a8a)] : [Theme.panel2, Theme.panel2], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 96, height: 96)
                    Image(systemName: dnd.active ? "moon.zzz.fill" : "moon.fill").font(.system(size: 40, weight: .semibold))
                        .foregroundColor(dnd.active ? .white : Theme.muted)
                }
                .padding(.top, 10)
                if dnd.active, let u = dnd.until {
                    Text((dnd.text ?? "Не беспокоить") + " " + DNDStore.untilText(u)).font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text)
                    Text("Сообщения приходят без звука. Срочные — со звуком.").font(.system(size: 14)).foregroundColor(Theme.muted)
                    Button {
                        busy = true
                        Task { _ = await dnd.set(until: nil, text: dnd.text, urgent: dnd.urgentFrom); busy = false }
                    } label: {
                        Text("Выключить").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.danger)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Theme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(BouncyButtonStyle()).padding(.horizontal, 16).disabled(busy)
                } else {
                    Text("Не беспокоить").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text)
                    Text("Собеседники увидят ваш статус, а сообщения придут без звука. Если что-то правда важное — вам смогут написать срочно.")
                        .font(.system(size: 14)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 24)
                    section("СТАТУС") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(statuses, id: \.self) { s in chip(s, status == s, icon: DNDStore.icon(s)) { status = s } }
                        }
                        if status == "Свой" {
                            TextField("Например: На тренировке", text: $custom)
                                .padding(.horizontal, 14).frame(height: 46).background(Theme.panel2, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundColor(Theme.text).padding(.top, 4)
                        }
                    }
                    section("НА СКОЛЬКО") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Array(durations.enumerated()), id: \.offset) { _, d in chip(d.0, dur == d.1) { dur = d.1 } }
                        }
                        Text("Выключится " + DNDStore.untilText(untilDate()).replacingOccurrences(of: "до ", with: "в "))
                            .font(.system(size: 13)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button {
                        let t = status == "Свой" ? custom.trimmingCharacters(in: .whitespaces) : status
                        busy = true
                        Task { _ = await dnd.set(until: untilDate(), text: t.isEmpty ? "Не беспокоить" : t, urgent: urgent); busy = false }
                    } label: {
                        HStack(spacing: 8) { Image(systemName: "moon.zzz.fill"); Text("Включить") }
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(LinearGradient(colors: [Color(hex: 0x7c5cff), Color(hex: 0x4f7cff)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(BouncyButtonStyle()).padding(.horizontal, 16).disabled(busy)
                }
                section("КТО МОЖЕТ НАПИСАТЬ СРОЧНО") {
                    VStack(spacing: 0) {
                        ForEach(Array([("all", "Все"), ("contacts", "Только контакты"), ("none", "Никто")].enumerated()), id: \.offset) { _, o in
                            Button {
                                urgent = o.0
                                if dnd.active { Task { _ = await dnd.set(until: dnd.until, text: dnd.text, urgent: o.0) } }
                            } label: {
                                HStack {
                                    Text(o.1).font(.system(size: 16)).foregroundColor(Theme.text)
                                    Spacer()
                                    if urgent == o.0 { Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.a1) }
                                }.padding(.horizontal, 14).frame(height: 48).contentShape(Rectangle())
                            }.buttonStyle(RowButtonStyle())
                            if o.0 != "none" { Divider().overlay(Theme.line).padding(.leading, 14) }
                        }
                    }
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                    Text("Срочное сообщение приходит со звуком даже в этом режиме. Каждый может отправить вам не больше одного срочного в сутки. Если сообщение было не срочным — нажмите на него и выберите «Это было не срочно»: человек на неделю потеряет эту возможность.")
                        .font(.system(size: 12.5)).foregroundColor(Theme.muted)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Не беспокоить").navigationBarTitleDisplayMode(.inline)
        .task { await dnd.load(); urgent = dnd.urgentFrom }
    }

    private func section<C: View>(_ t: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).padding(.leading, 4)
            c()
        }
        .padding(.horizontal, 16)
    }

    private func chip(_ t: String, _ on: Bool, icon: String? = nil, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            HStack(spacing: 6) {
                if let i = icon { Image(systemName: i).font(.system(size: 14, weight: .semibold)) }
                Text(t).lineLimit(1).minimumScaleFactor(0.8)
            }
                .font(.system(size: 15, weight: .semibold)).foregroundColor(on ? .white : Theme.text)
                .frame(maxWidth: .infinity).frame(height: 42)
                .background(on ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x7c5cff), Color(hex: 0x4f7cff)], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Theme.panel),
                            in: RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(BouncyButtonStyle())
    }
}

/// Плашка «⚡ Срочно» над срочным сообщением
struct UrgentTag: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill").font(.system(size: 10, weight: .bold))
            Text("СРОЧНО").font(.system(size: 10.5, weight: .heavy))
        }
        .foregroundColor(.white).padding(.horizontal, 8).padding(.vertical, 3)
        .background(LinearGradient(colors: [Color(hex: 0xffb020), Color(hex: 0xff4d3d)], startPoint: .leading, endPoint: .trailing), in: Capsule())
    }
}

// MARK: - Капсула времени

@MainActor
final class CapsuleStore: ObservableObject {
    static let shared = CapsuleStore()
    /// содержимое открытых капсул: id сообщения → (вид, текст, картинка)
    @Published private(set) var opened: [Int: CapsuleContent] = [:]
    @Published private(set) var views: [Int: Int] = [:]

    struct CapsuleContent: Equatable {
        let kind: String
        let text: String?
        let image: String?
    }

    /// загрузить содержимое (сервер отдаёт его только после даты открытия; автору — сразу)
    func open(_ m: Message) async -> String? {
        do {
            guard let j = try await API.shared.rpc("lm_capsule_open", ["p_msg": m.id]) as? JSON else { return "Не удалось открыть" }
            let p = j.dict("payload")
            await AppModel.shared.prep(m.chatId)
            func dec(_ s: String?) -> String? {
                guard let s = s else { return nil }
                return E2E.isEnc(s) ? (E2E.shared.decrypt(m.chatId, s) ?? "Зашифровано") : s
            }
            opened[m.id] = CapsuleContent(kind: p.str("kind") ?? "text", text: dec(p.str("text")), image: dec(p.str("image")))
            views[m.id] = j.int("views") ?? 0
            return nil
        } catch { return error.localizedDescription }
    }

    func send(chatId: String, at: Date, text: String, image: UIImage?, replyTo: Int?) async -> Bool {
        do {
            await AppModel.shared.prep(chatId)
            var p: JSON = ["kind": image == nil ? "text" : "image"]
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { p["text"] = E2E.shared.encrypt(chatId, t) ?? t }
            if let img = image, let d = img.jpegData(compressionQuality: 0.82) {
                let url = try await API.shared.upload(d, ext: "jpg", contentType: "image/jpeg")
                p["image"] = E2E.shared.encrypt(chatId, url) ?? url
            }
            var params: JSON = ["p_chat": chatId, "p_open_at": DateParser.string(at), "p_payload": p]
            if let r = replyTo { params["p_reply"] = r }
            _ = try await API.shared.rpc("lm_capsule_send", params)
            await AppModel.shared.loadMessages(chatId)
            return true
        } catch { AppModel.shared.say(error.localizedDescription); return false }
    }

    static func countdown(_ to: Date, now: Date) -> String {
        let s = max(0, Int(to.timeIntervalSince(now)))
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60, sec = s % 60
        if d > 0 { return "\(d) д \(h) ч \(m) мин" }
        if h > 0 { return "\(h) ч \(m) мин \(sec) с" }
        return String(format: "%d:%02d", m, sec)
    }

    static func dateText(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "d MMMM yyyy, HH:mm"
        return f.string(from: d)
    }
}

/// Конверт с восковой печатью — нарисован вручную
struct CapsuleEnvelope: View {
    var opened: Bool
    var crack: CGFloat = 0
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let body = Path(roundedRect: CGRect(x: 0, y: h * 0.12, width: w, height: h * 0.88), cornerRadius: w * 0.07)
            ctx.fill(body, with: .linearGradient(Gradient(colors: [Color(hex: 0xf7e3c0), Color(hex: 0xe8c48c)]), startPoint: .zero, endPoint: CGPoint(x: w, y: h)))
            // нижние клапаны
            var low = Path()
            low.move(to: CGPoint(x: 0, y: h)); low.addLine(to: CGPoint(x: w * 0.5, y: h * 0.58)); low.addLine(to: CGPoint(x: w, y: h))
            ctx.stroke(low, with: .color(Color(hex: 0xc9a36a).opacity(0.8)), lineWidth: 1.4)
            // верхний клапан (откинут, если открыт)
            var flap = Path()
            if opened {
                flap.move(to: CGPoint(x: 0, y: h * 0.12)); flap.addLine(to: CGPoint(x: w * 0.5, y: -h * 0.2)); flap.addLine(to: CGPoint(x: w, y: h * 0.12)); flap.closeSubpath()
            } else {
                flap.move(to: CGPoint(x: 0, y: h * 0.14)); flap.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62)); flap.addLine(to: CGPoint(x: w, y: h * 0.14)); flap.closeSubpath()
            }
            ctx.fill(flap, with: .linearGradient(Gradient(colors: [Color(hex: 0xf0d3a2), Color(hex: 0xdcb170)]), startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: w / 2, y: h * 0.6)))
            ctx.stroke(flap, with: .color(Color(hex: 0xb8894a).opacity(0.7)), lineWidth: 1.2)
            if !opened {
                // восковая печать
                let c = CGPoint(x: w * 0.5, y: h * 0.6), r = w * 0.15
                var seal = Path()
                for i in 0..<16 {
                    let a = Double(i) / 16 * .pi * 2
                    let rr = r * (i % 2 == 0 ? 1.0 : 0.9)
                    let p = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
                    if i == 0 { seal.move(to: p) } else { seal.addLine(to: p) }
                }
                seal.closeSubpath()
                ctx.fill(seal, with: .radialGradient(Gradient(colors: [Color(hex: 0xff5a6e), Color(hex: 0xb3122e)]), center: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.3), startRadius: 1, endRadius: r * 1.3))
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.62, width: r * 1.24, height: r * 1.24)), with: .color(.white.opacity(0.35)), lineWidth: 1.2)
                // звёздочка на печати
                var st = Path()
                for i in 0..<10 {
                    let a = Double(i) / 10 * .pi * 2 - .pi / 2
                    let rr = r * (i % 2 == 0 ? 0.46 : 0.2)
                    let p = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
                    if i == 0 { st.move(to: p) } else { st.addLine(to: p) }
                }
                st.closeSubpath()
                ctx.fill(st, with: .color(Color(hex: 0xffd2d8).opacity(0.9)))
                if crack > 0 {
                    var cr = Path()
                    cr.move(to: CGPoint(x: c.x - r * 0.8 * crack, y: c.y - r * 0.2))
                    cr.addLine(to: CGPoint(x: c.x - r * 0.1, y: c.y + r * 0.15))
                    cr.addLine(to: CGPoint(x: c.x + r * 0.2, y: c.y - r * 0.25))
                    cr.addLine(to: CGPoint(x: c.x + r * 0.85 * crack, y: c.y + r * 0.1))
                    ctx.stroke(cr, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}

/// Сообщение-капсула в чате
struct CapsuleBubble: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var store = CapsuleStore.shared
    let m: Message
    let mine: Bool
    let isGroup: Bool
    @State private var shake: CGFloat = 0
    @State private var opening = false
    @State private var crack: CGFloat = 0
    @State private var sparkle = false
    @State private var showFull: URL?

    private var openAt: Date { m.meta.date("open_at") ?? m.createdAt }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { tl in
            let ready = tl.date >= openAt
            let content = store.opened[m.id]
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass").font(.system(size: 12, weight: .bold))
                    Text("КАПСУЛА ВРЕМЕНИ").font(.system(size: 11.5, weight: .heavy)).tracking(0.6)
                }
                .foregroundColor(Color(hex: 0xb07a2a))
                if let c = content, ready || mine {
                    VStack(alignment: .leading, spacing: 8) {
                        if let img = c.image, let u = URL(string: img) {
                            CachedImage(url: u) { $0.resizable().scaledToFill() } placeholder: { Color.black.opacity(0.08) }
                                .frame(maxWidth: 240, maxHeight: 260).clipShape(RoundedRectangle(cornerRadius: 14))
                                .onTapGesture { showFull = u }
                        }
                        if let t = c.text, !t.isEmpty {
                            Text(t).font(.system(size: 16)).foregroundColor(Color(hex: 0x3b2a14)).fixedSize(horizontal: false, vertical: true)
                        }
                        Text(ready ? "Открыта " + CapsuleStore.dateText(openAt) + ((store.views[m.id] ?? 0) > 0 && isGroup ? " · открыли: \(store.views[m.id] ?? 0)" : "")
                                   : "Откроется " + CapsuleStore.dateText(openAt) + " · видно только вам")
                            .font(.system(size: 12)).foregroundColor(Color(hex: 0x8a6a3e))
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    ZStack {
                        CapsuleEnvelope(opened: false, crack: crack).frame(width: 210, height: 140)
                        if sparkle {
                            ForEach(0..<12, id: \.self) { i in
                                Image(systemName: "sparkle").font(.system(size: CGFloat(10 + (i % 3) * 5)))
                                    .foregroundColor(i % 2 == 0 ? Color(hex: 0xffd24c) : Color(hex: 0xff8ae3))
                                    .offset(x: CGFloat(cos(Double(i) / 12 * .pi * 2)) * 120, y: CGFloat(sin(Double(i) / 12 * .pi * 2)) * 80)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .offset(x: shake)
                    .onTapGesture { tap(ready: ready) }
                    VStack(alignment: .leading, spacing: 2) {
                        if ready {
                            Text(opening ? "Открываем…" : "Нажмите, чтобы открыть").font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: 0x3b2a14))
                        } else {
                            Text("Откроется через").font(.system(size: 12.5)).foregroundColor(Color(hex: 0x8a6a3e))
                            Text(CapsuleStore.countdown(openAt, now: tl.date)).font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: 0x3b2a14)).monospacedDigit()
                            Text(CapsuleStore.dateText(openAt)).font(.system(size: 12)).foregroundColor(Color(hex: 0x8a6a3e))
                        }
                    }
                }
                HStack {
                    Spacer()
                    Text(Fmt.clock(m.createdAt)).font(.system(size: 11.5)).foregroundColor(Color(hex: 0x8a6a3e))
                }
            }
            .padding(12)
            .frame(width: 250, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0xfff6e6), Color(hex: 0xffe9c7)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(hex: 0xe8c48c), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            )
            .task(id: ready) { if mine && store.opened[m.id] == nil { _ = await store.open(m) } }
        }
        .fullScreenCover(item: Binding(get: { showFull.map { IdentifiedURL(url: $0) } }, set: { showFull = $0?.url })) { ImageScreen(url: $0.url) }
    }

    private func tap(ready: Bool) {
        if !ready {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            withAnimation(.default) { shake = 12 }
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 6).delay(0.05)) { shake = 0 }
            model.say("Ещё рано. Откроется " + CapsuleStore.dateText(openAt))
            return
        }
        guard !opening else { return }
        opening = true
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeIn(duration: 0.35)) { crack = 1 }
        Task {
            try? await Task.sleep(nanoseconds: 380_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { sparkle = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            let err = await store.open(m)
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { sparkle = false }
            opening = false
            if let e = err { model.say(e); crack = 0 }
        }
    }
}

/// Создание капсулы
struct CapsuleComposeSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    var replyTo: Int?
    @State private var text = ""
    @State private var at = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var preset = 1
    @State private var pickItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var busy = false
    @FocusState private var focus: Bool

    private var presets: [(String, Date)] {
        let cal = Calendar.current, now = Date()
        var out: [(String, Date)] = []
        if let t = cal.date(byAdding: .day, value: 1, to: now), let d = cal.date(bySettingHour: 9, minute: 0, second: 0, of: t) { out.append(("Завтра", d)) }
        if let d = cal.date(byAdding: .day, value: 7, to: now) { out.append(("Через неделю", d)) }
        if let d = cal.date(byAdding: .month, value: 1, to: now) { out.append(("Через месяц", d)) }
        let y = cal.component(.year, from: now)
        if let ny = cal.date(from: DateComponents(year: y + 1, month: 1, day: 1, hour: 0, minute: 0)) { out.append(("Новый год", ny)) }
        if let d = cal.date(byAdding: .year, value: 1, to: now) { out.append(("Через год", d)) }
        return out
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CapsuleEnvelope(opened: false).frame(width: 170, height: 114).padding(.top, 8)
                    Text("Капсула времени").font(.system(size: 24, weight: .black)).foregroundColor(Theme.text)
                    Text("Сообщение откроется только в выбранный момент. До этого собеседник увидит запечатанный конверт с обратным отсчётом.")
                        .font(.system(size: 14)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 24)
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty { Text("Что вы хотите сказать в будущем?").foregroundColor(Theme.muted).padding(.horizontal, 14).padding(.vertical, 12) }
                            TextEditor(text: $text).focused($focus).scrollContentBackground(.hidden)
                                .frame(minHeight: 110).padding(.horizontal, 9).padding(.vertical, 4).foregroundColor(Theme.text)
                        }
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                        if let img = image {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img).resizable().scaledToFill().frame(height: 160).frame(maxWidth: .infinity).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                Button { image = nil } label: {
                                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                        .frame(width: 26, height: 26).background(Color.black.opacity(0.55), in: Circle())
                                }.padding(8)
                            }
                        } else {
                            PhotosPicker(selection: $pickItem, matching: .images) {
                                HStack(spacing: 8) { Image(systemName: "photo.badge.plus"); Text("Добавить фото") }
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.a1)
                                    .frame(maxWidth: .infinity).frame(height: 44)
                                    .background(Theme.a1.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        Text("КОГДА ОТКРЫТЬ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).padding(.top, 6)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(presets.enumerated()), id: \.offset) { i, p in
                                    Button { preset = i; at = p.1 } label: {
                                        Text(p.0).font(.system(size: 15, weight: .semibold)).foregroundColor(preset == i ? .white : Theme.text)
                                            .padding(.horizontal, 14).frame(height: 38)
                                            .background(preset == i ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xffb347), Color(hex: 0xff6a3d)], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Theme.panel), in: Capsule())
                                    }.buttonStyle(BouncyButtonStyle())
                                }
                            }
                        }
                        DatePicker("Дата и время", selection: Binding(get: { at }, set: { at = $0; preset = -1 }),
                                   in: Date().addingTimeInterval(120)...Date().addingTimeInterval(5 * 365 * 86400), displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                            .padding(.horizontal, 14).frame(height: 50).background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(Theme.text)
                    }
                    .padding(.horizontal, 16)
                    Button {
                        guard !busy else { return }
                        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && image == nil { model.say("Напишите что-нибудь или добавьте фото"); return }
                        busy = true
                        Task {
                            if await CapsuleStore.shared.send(chatId: chatId, at: at, text: text, image: image, replyTo: replyTo) {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                            busy = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if busy { ProgressView().tint(.white) } else { Image(systemName: "seal.fill"); Text("Запечатать до " + CapsuleStore.dateText(at)).lineLimit(1).minimumScaleFactor(0.7) }
                        }
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(LinearGradient(colors: [Color(hex: 0xff8a3d), Color(hex: 0xe8336a)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(BouncyButtonStyle()).padding(.horizontal, 16).padding(.bottom, 20)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
            .onChange(of: pickItem) { item in
                guard let item = item else { return }
                pickItem = nil
                Task { if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) { image = img } }
            }
        }
    }
}

/// Шкатулка: все капсулы в моих чатах
struct CapsuleBoxView: View {
    @EnvironmentObject var model: AppModel
    @State private var items: [JSON]?
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let list = items {
                    if list.isEmpty {
                        VStack(spacing: 12) {
                            CapsuleEnvelope(opened: false).frame(width: 150, height: 100)
                            Text("Капсул пока нет").font(.headline).foregroundColor(Theme.text)
                            Text("Отправьте капсулу из меню вложений в любом чате — она откроется в выбранный день.")
                                .font(.system(size: 14)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
                        }.padding(.top, 50)
                    }
                    let sealed = list.filter { !$0.bool("opened") }, opened = list.filter { $0.bool("opened") }
                    if !sealed.isEmpty { header("ЗАПЕЧАТАНЫ · \(sealed.count)"); ForEach(Array(sealed.enumerated()), id: \.offset) { _, j in row(j) } }
                    if !opened.isEmpty { header("ОТКРЫТЫ · \(opened.count)"); ForEach(Array(opened.reversed().enumerated()), id: \.offset) { _, j in row(j) } }
                } else { ProgressView().padding(40) }
            }
            .padding(14)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Капсулы времени").navigationBarTitleDisplayMode(.inline)
        .task { items = ((try? await API.shared.rpc("lm_capsule_list")) as? [JSON]) ?? [] }
    }

    private func header(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6).padding(.leading, 4)
    }

    private func row(_ j: JSON) -> some View {
        let chatId = j.str("chat_id") ?? ""
        let c = model.chat(chatId)
        let at = j.date("open_at") ?? Date()
        let opened = j.bool("opened"), mine = j.bool("mine")
        return Button {
            if let id = j.int("message_id") { model.pendingJump = id; model.open(chatId) }
        } label: {
            HStack(spacing: 12) {
                CapsuleEnvelope(opened: opened).frame(width: 54, height: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mine ? "Вы → " + (c?.displayName ?? "чат") : "От " + model.displayName(j.str("sender_id")) + (c?.isPrivate == false ? " · " + (c?.displayName ?? "") : ""))
                        .font(.system(size: 15.5, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                    Text(opened ? "Открыта " + CapsuleStore.dateText(at) : "Откроется " + CapsuleStore.dateText(at))
                        .font(.system(size: 13)).foregroundColor(opened ? Theme.muted : Color(hex: 0xd08a2a))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
            }
            .padding(12).background(Theme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }.buttonStyle(BouncyButtonStyle())
    }
}

extension Notification.Name {
    /// перейти к сообщению в открытом чате (id сообщения — в object)
    static let lumoJump = Notification.Name("lumoJump")
}


/// Строка «Не беспокоить» в настройках: показывает, включён ли режим
struct DNDSettingsRow: View {
    @ObservedObject var dnd = DNDStore.shared
    var body: some View {
        SettingsRow(icon: "moon.zzz.fill", color: Color(hex: 0x7c5cff), title: "Не беспокоить",
                    subtitle: dnd.active ? ((dnd.text ?? "Включено") + " " + DNDStore.untilText(dnd.until ?? Date())) : "Тишина ночью, срочные — со звуком")
    }
}

/// Итог после режима «Не беспокоить»
struct DNDSummaryModifier: ViewModifier {
    @ObservedObject var dnd = DNDStore.shared
    func body(content: Content) -> some View {
        content.alert("Пока вас не было", isPresented: Binding(get: { dnd.summary != nil }, set: { if !$0 { dnd.summary = nil } })) {
            Button("Хорошо", role: .cancel) { dnd.summary = nil }
        } message: { Text(dnd.summary ?? "") }
    }
}

// MARK: - Серия (огонёк)

struct Streak: Equatable {
    let chatId: String; let count: Int; let best: Int; let level: Int; let done: Bool; let mine: Bool; let peer: Bool; let enabled: Bool
}

@MainActor
final class Streaks: ObservableObject {
    static let shared = Streaks()
    static let levels = [3, 10, 30, 100, 200]
    @Published var map: [String: Streak] = [:]
    /// праздник «огонёк загорелся» поверх всего приложения
    @Published var celebrate: Streak?
    private var last = Date.distantPast
    private let seenKey = "lm_streak_seen"

    func load(force: Bool = true) async {
        if !force && Date().timeIntervalSince(last) < 20 { return }
        last = Date()
        guard let a = (try? await API.shared.rpc("lm_streaks")) as? [JSON] else { return }
        var m: [String: Streak] = [:]
        for j in a {
            guard let c = j.str("chat_id") else { continue }
            m[c] = Streak(chatId: c, count: j.int("count") ?? 0, best: j.int("best") ?? 0, level: j.int("level") ?? 0,
                          done: j.bool("done"), mine: j.bool("mine"), peer: j.bool("peer"), enabled: j.bool("enabled"))
        }
        map = m
        checkCelebrate()
    }

    /// новый уровень огонька (3, 10, 30…) — один раз показываем красивую анимацию
    private func checkCelebrate() {
        guard celebrate == nil else { return }
        var seen = UserDefaults.standard.dictionary(forKey: seenKey) as? [String: Int] ?? [:]
        for s in map.values where s.enabled && s.level >= 3 {
            if (seen[s.chatId] ?? 0) < s.level {
                seen[s.chatId] = s.level
                UserDefaults.standard.set(seen, forKey: seenKey)
                celebrate = s
                return
            }
        }
    }

    /// огонёк виден, когда серийчик выведен и серия от 3 дней
    func of(_ chatId: String?) -> Streak? {
        guard let c = chatId, let s = map[c], s.enabled, s.count >= 3 else { return nil }
        return s
    }

    func enabled(_ chatId: String?) -> Bool { chatId.flatMap { map[$0]?.enabled } ?? false }

    /// «Вывести серийчика»
    func enable(_ chatId: String) async -> Bool {
        do {
            _ = try await API.shared.rpc("lm_streak_enable", ["p_chat": chatId])
            last = .distantPast
            await load()
            if let s = map[chatId], s.count < 3 { celebrate = s }   // приветствие серийчика
            return true
        } catch { AppModel.shared.say(error.localizedDescription); return false }
    }

    static func colors(_ level: Int, _ lit: Bool) -> [Color] {
        if !lit { return [Color(hex: 0xd9d9de), Color(hex: 0x9ea0a8)] }
        switch level {
        case 200...: return [Color(hex: 0xffe27a), Color(hex: 0xb45cff), Color(hex: 0x5b2bff)]
        case 100...: return [Color(hex: 0xb6f0ff), Color(hex: 0x3fa9ff), Color(hex: 0x2155ff)]
        case 30...: return [Color(hex: 0xffd1f0), Color(hex: 0xff4fa3), Color(hex: 0xe0145a)]
        case 10...: return [Color(hex: 0xffe07a), Color(hex: 0xff5a2a), Color(hex: 0xd9141e)]
        default: return [Color(hex: 0xffe680), Color(hex: 0xffa318), Color(hex: 0xff6a00)]
        }
    }

    static func days(_ n: Int) -> String {
        let m10 = n % 10, m100 = n % 100
        if m10 == 1 && m100 != 11 { return "день" }
        if (2...4).contains(m10) && (m100 < 10 || m100 >= 20) { return "дня" }
        return "дней"
    }
}

private func flamePath(_ w: CGFloat, _ h: CGFloat, extra: Bool) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: w * 0.5, y: h * 0.98))
    p.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.38), control1: CGPoint(x: w * 0.12, y: h * 0.98), control2: CGPoint(x: w * 0.02, y: h * 0.62))
    p.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.55), control1: CGPoint(x: w * 0.24, y: h * 0.52), control2: CGPoint(x: w * 0.32, y: h * 0.56))
    p.addCurve(to: CGPoint(x: w * 0.6, y: h * 0.02), control1: CGPoint(x: w * 0.3, y: h * 0.3), control2: CGPoint(x: w * 0.44, y: h * 0.1))
    p.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.4), control1: CGPoint(x: w * 0.58, y: h * 0.22), control2: CGPoint(x: w * 0.7, y: h * 0.3))
    if extra {
        p.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.2), control1: CGPoint(x: w * 0.8, y: h * 0.32), control2: CGPoint(x: w * 0.84, y: h * 0.26))
        p.addCurve(to: CGPoint(x: w * 0.96, y: h * 0.65), control1: CGPoint(x: w * 0.96, y: h * 0.4), control2: CGPoint(x: w * 0.98, y: h * 0.55))
    }
    p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.98), control1: CGPoint(x: w * 1.0, y: h * 0.84), control2: CGPoint(x: w * 0.82, y: h * 0.98))
    p.closeSubpath()
    return p
}

private func flameInner(_ w: CGFloat, _ h: CGFloat) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: w * 0.5, y: h * 0.96))
    p.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.64), control1: CGPoint(x: w * 0.3, y: h * 0.96), control2: CGPoint(x: w * 0.26, y: h * 0.76))
    p.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.68), control1: CGPoint(x: w * 0.42, y: h * 0.7), control2: CGPoint(x: w * 0.46, y: h * 0.7))
    p.addCurve(to: CGPoint(x: w * 0.6, y: h * 0.44), control1: CGPoint(x: w * 0.46, y: h * 0.56), control2: CGPoint(x: w * 0.52, y: h * 0.48))
    p.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.8), control1: CGPoint(x: w * 0.62, y: h * 0.56), control2: CGPoint(x: w * 0.74, y: h * 0.66))
    p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.96), control1: CGPoint(x: w * 0.7, y: h * 0.92), control2: CGPoint(x: w * 0.62, y: h * 0.96))
    p.closeSubpath()
    return p
}

/// Нарисованный огонёк
struct FlameView: View {
    let level: Int
    let lit: Bool
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cs = Streaks.colors(level, lit)
            ctx.fill(flamePath(w, h, extra: level >= 30 && lit), with: .linearGradient(Gradient(colors: [cs[1], cs.count > 2 ? cs[2] : cs[1]]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            ctx.fill(flameInner(w, h), with: .linearGradient(Gradient(colors: [cs[0].opacity(0.95), Color.white.opacity(lit ? 0.9 : 0.6)]),
                                                             startPoint: CGPoint(x: 0, y: h * 0.44), endPoint: CGPoint(x: 0, y: h)))
        }
    }
}

/// Серийчик — огонёк с глазками
struct SerialMascot: View {
    var size: CGFloat = 120
    var level: Int = 3
    var sleeping = false
    @State private var t = false
    @State private var blink = false
    var body: some View {
        ZStack {
            FlameView(level: level, lit: !sleeping).frame(width: size * 0.86, height: size)
                .scaleEffect(x: t ? 1.03 : 0.97, y: t ? 0.97 : 1.03, anchor: .bottom)
            // глазки и улыбка
            Canvas { ctx, sz in
                let w = sz.width, h = sz.height
                let ey = h * 0.66, ex = w * 0.13, er = w * 0.075
                for dx in [-ex, ex] {
                    let c = CGPoint(x: w * 0.53 + dx, y: ey)
                    if sleeping || blink {
                        var l = Path(); l.move(to: CGPoint(x: c.x - er, y: c.y)); l.addQuadCurve(to: CGPoint(x: c.x + er, y: c.y), control: CGPoint(x: c.x, y: c.y + er * 0.9))
                        ctx.stroke(l, with: .color(Color(hex: 0x5a2600)), style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
                    } else {
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - er, y: c.y - er * 1.2, width: er * 2, height: er * 2.4)), with: .color(Color(hex: 0x4a1d00)))
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - er * 0.25, y: c.y - er * 0.9, width: er * 0.8, height: er * 0.8)), with: .color(.white))
                    }
                }
                var m = Path()
                m.move(to: CGPoint(x: w * 0.45, y: h * 0.8)); m.addQuadCurve(to: CGPoint(x: w * 0.61, y: h * 0.8), control: CGPoint(x: w * 0.53, y: h * 0.87))
                ctx.stroke(m, with: .color(Color(hex: 0x5a2600)), style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
                for dx in [-w * 0.24, w * 0.24] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * 0.53 + dx - w * 0.05, y: h * 0.74, width: w * 0.1, height: w * 0.06)), with: .color(Color(hex: 0xff5a7a).opacity(0.55)))
                }
            }
            .frame(width: size * 0.86, height: size)
            .scaleEffect(x: t ? 1.03 : 0.97, y: t ? 0.97 : 1.03, anchor: .bottom)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { t = true }
            Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 3_200_000_000)
                    blink = true
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    blink = false
                }
            }
        }
    }
}

/// Огонёк рядом с именем: 3 и больше — горит; если серийчик не выведен — ничего
struct StreakBadge: View {
    let chatId: String?
    var size: CGFloat = 14
    @ObservedObject private var st = Streaks.shared
    var body: some View {
        if let s = st.of(chatId) {
            HStack(spacing: 1) {
                FlameView(level: s.level, lit: s.done).frame(width: size * 0.85, height: size)
                Text("\(s.count)").font(.system(size: size - 1, weight: .black))
                    .foregroundColor(s.done ? Color(hex: 0xff7a1a) : Theme.muted)
            }
        }
    }
}

/// Кнопка в шапке личного чата: горящий огонёк с числом, а если серийчика ещё нет — серый контур
struct StreakHeaderButton: View {
    let chatId: String
    let action: () -> Void
    @ObservedObject private var st = Streaks.shared
    var body: some View {
        Button(action: action) {
            if st.of(chatId) != nil { StreakBadge(chatId: chatId, size: 15) }
            else {
                FlameView(level: 3, lit: false).frame(width: 13, height: 15).opacity(0.8)
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Окно серии: что это, уровни, «Вывести серийчика»
struct StreakSheet: View {
    let chatId: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var st = Streaks.shared
    @ObservedObject private var model = AppModel.shared
    @State private var busy = false

    var body: some View {
        let s = st.map[chatId]
        let on = s?.enabled == true
        let count = on ? (s?.count ?? 0) : 0
        let lit = s?.done == true
        let c = model.chat(chatId)
        let peerName = c?.displayName ?? "собеседник"
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundColor(Theme.text)
                        .frame(width: 36, height: 36).background(Theme.panel2, in: Circle()) }
                }
                if on && count >= 3 {
                    ZStack {
                        AvatarView(name: model.me?.name ?? "", url: model.me?.avatarURL, color: model.me?.color ?? 0, size: 96)
                            .overlay(Circle().stroke(Theme.bg, lineWidth: 3)).offset(x: -40)
                        AvatarView(name: c?.displayName ?? "", url: c?.displayAvatar, color: c?.displayColor ?? 0, size: 96)
                            .overlay(Circle().stroke(Theme.bg, lineWidth: 3)).offset(x: 40)
                        SerialMascot(size: 54, level: s?.level ?? 3).offset(y: 46)
                    }
                    .frame(height: 130)
                    HStack(spacing: 4) {
                        Text("Ваша серия длится").font(.system(size: 22, weight: .black)).foregroundColor(Theme.text)
                        FlameView(level: s?.level ?? 3, lit: lit).frame(width: 20, height: 24)
                        Text("\(count) \(Streaks.days(count))").font(.system(size: 22, weight: .black)).foregroundColor(lit ? Color(hex: 0xff7a1a) : Theme.muted)
                    }
                    .minimumScaleFactor(0.7).lineLimit(1).padding(.top, 12)
                } else {
                    SerialMascot(size: 120, level: 3, sleeping: !on)
                    Text(on ? "Серийчик выведен" : "Серийчик ещё спит").font(.system(size: 24, weight: .black)).foregroundColor(Theme.text).padding(.top, 8)
                    Text(on ? "Пишите друг другу каждый день — на третий день загорится огонёк. Сейчас: \(count) \(Streaks.days(count)) подряд."
                            : "Выведите серийчика, и в этом чате начнётся серия: общайтесь каждый день, и через 3 дня рядом с именем загорится огонёк.")
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.top, 6).padding(.horizontal, 8)
                }
                VStack(alignment: .leading, spacing: 8) {
                    bullet("calendar", "День засчитывается, когда вы оба написали друг другу хотя бы по сообщению (по московскому времени).")
                    if on { bullet("clock", todo(s, peerName)) }
                    bullet("flame", "Не пропускайте дни: если день пропущен, серия погаснет в полночь.")
                    bullet("sparkles", "Чем дольше серия, тем ярче огонёк: 3, 10, 30, 100 и 200 дней.")
                }
                .padding(.top, 16)
                HStack(spacing: 0) {
                    ForEach(Array(Streaks.levels.enumerated()), id: \.offset) { i, lv in
                        if i > 0 { Capsule().fill(count >= lv ? Color(hex: 0xff9a3d) : Theme.line).frame(height: 3) }
                        VStack(spacing: 4) {
                            FlameView(level: lv, lit: count >= lv).frame(width: 28, height: 34)
                            Text("\(lv) д").font(.system(size: 13, weight: count >= lv ? .bold : .regular)).foregroundColor(count >= lv ? Theme.text : Theme.muted)
                        }
                    }
                }
                .padding(.top, 18)
                if on, let b = s?.best, b > count {
                    Text("Рекорд: \(b) \(Streaks.days(b))").font(.system(size: 13)).foregroundColor(Theme.muted).padding(.top, 10)
                }
                if on {
                    Button { dismiss() } label: {
                        Text("Понятно").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 54).background(Color(hex: 0xe8455a), in: Capsule())
                    }.buttonStyle(BouncyButtonStyle()).padding(.top, 20)
                } else {
                    Button {
                        busy = true
                        Task { if await st.enable(chatId) { dismiss() }; busy = false }
                    } label: {
                        HStack(spacing: 8) {
                            if busy { ProgressView().tint(.white) } else { Image(systemName: "flame.fill") }
                            Text("Вывести серийчика")
                        }
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(LinearGradient(colors: [Color(hex: 0xffa318), Color(hex: 0xff5a2a)], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    }.buttonStyle(BouncyButtonStyle()).disabled(busy).padding(.top, 20)
                }
            }
            .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 14)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await st.load(force: false) }
    }

    private func todo(_ s: Streak?, _ name: String) -> String {
        guard let s, s.count > 0 else { return "Напишите друг другу сегодня — серия начнётся." }
        if s.done { return "Сегодня вы оба уже написали — огонёк горит. Возвращайтесь завтра!" }
        if s.mine { return "Вы сегодня уже написали. Ждём ответа от \(name) — иначе серия погаснет в полночь." }
        if s.peer { return "\(name) уже написал(а) сегодня. Ответьте до полуночи, чтобы серия продолжилась!" }
        return "Напишите друг другу сегодня до полуночи, чтобы серия не погасла."
    }

    @ViewBuilder private func bullet(_ icon: String, _ t: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: 0xff7a1a)).frame(width: 22)
            Text(t).font(.system(size: 15)).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Раздел в настройках: как работают огоньки
struct StreakInfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SerialMascot(size: 130).padding(.top, 10)
                Text("Огоньки и серийчик").font(.system(size: 24, weight: .black)).foregroundColor(Theme.text)
                Text("Огонёк показывает, сколько дней подряд вы общаетесь с человеком.").font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 12) {
                    row("1.circle.fill", "Откройте личный чат и нажмите на серый огонёк рядом с именем, затем — «Вывести серийчика».")
                    row("2.circle.fill", "Пишите друг другу каждый день. День засчитывается, когда написали вы оба (по московскому времени).")
                    row("3.circle.fill", "На третий день загорится огонёк с числом — его видно в списке чатов и в шапке чата.")
                    row("moon.zzz.fill", "Если день пропущен, серия гаснет в полночь, и в чате появится сообщение об этом.")
                }
                .padding(16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 18)).padding(.horizontal, 16)
                Text("УРОВНИ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                VStack(spacing: 0) {
                    ForEach(Array(Streaks.levels.enumerated()), id: \.offset) { i, lv in
                        HStack(spacing: 12) {
                            FlameView(level: lv, lit: true).frame(width: 26, height: 31)
                            Text("\(lv) \(Streaks.days(lv)) подряд").font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                            Spacer()
                            Text(["Огонёк загорелся", "Огонёк ярче", "Розовое пламя", "Синее пламя", "Легендарное пламя"][i]).font(.system(size: 13)).foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 16).frame(height: 52)
                        if i < Streaks.levels.count - 1 { Divider().overlay(Theme.line).padding(.leading, 54) }
                    }
                }
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18)).padding(.horizontal, 16)
            }
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Огоньки").navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ icon: String, _ t: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(Color(hex: 0xff7a1a)).frame(width: 24)
            Text(t).font(.system(size: 15)).foregroundColor(Theme.text).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Красивое появление огонька: вспышка, искры, растущее пламя и число
struct StreakCelebration: View {
    let s: Streak
    let onClose: () -> Void
    @ObservedObject private var model = AppModel.shared
    @State private var phase: CGFloat = 0
    @State private var glow = false
    @State private var shown = false

    var body: some View {
        let lit = s.count >= 3
        ZStack {
            Color.black.opacity(shown ? 0.62 : 0).ignoresSafeArea()
                .onTapGesture { close() }
            // искры
            TimelineView(.animation) { tl in
                Canvas { ctx, size in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let c = CGPoint(x: size.width / 2, y: size.height * 0.42)
                    for i in 0..<36 {
                        let seed = Double(i) * 12.9898
                        let a = (seed.truncatingRemainder(dividingBy: 6.283))
                        let sp = 0.6 + (seed * 3.1).truncatingRemainder(dividingBy: 1.0)
                        let life = ((t * 0.45 * sp) + Double(i) / 36).truncatingRemainder(dividingBy: 1.0)
                        let r = 40 + life * 190
                        let p = CGPoint(x: c.x + CGFloat(cos(a) * r), y: c.y + CGFloat(sin(a) * r) - CGFloat(life * 60))
                        let sz = CGFloat(3 + (1 - life) * 5)
                        let col = i % 3 == 0 ? Color(hex: 0xffd24c) : (i % 3 == 1 ? Color(hex: 0xff8a3d) : Color.white)
                        ctx.opacity = (1 - life) * Double(phase)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - sz / 2, y: p.y - sz / 2, width: sz, height: sz)), with: .color(col))
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xffb347).opacity(0.75), .clear], center: .center, startRadius: 4, endRadius: 150))
                        .frame(width: 300, height: 300).scaleEffect(glow ? 1.12 : 0.88).opacity(Double(phase))
                    if lit {
                        FlameView(level: s.level, lit: true).frame(width: 130, height: 155)
                            .scaleEffect(phase).rotationEffect(.degrees(glow ? 3 : -3), anchor: .bottom)
                    } else {
                        SerialMascot(size: 150, level: 3).scaleEffect(phase)
                    }
                }
                .frame(height: 260)
                if lit {
                    Text("\(s.count)").font(.system(size: 64, weight: .black)).foregroundColor(.white)
                        .shadow(color: Color(hex: 0xff6a00).opacity(0.8), radius: 16)
                        .scaleEffect(phase).opacity(Double(phase))
                }
                Text(lit ? (s.level <= 3 ? "Огонёк загорелся!" : "Огонёк стал ярче!") : "Серийчик выведен!")
                    .font(.system(size: 26, weight: .black)).foregroundColor(.white).opacity(Double(phase))
                Text(lit ? "\(s.count) \(Streaks.days(s.count)) подряд с \(model.chat(s.chatId)?.displayName ?? "собеседником"). Не прерывайте серию!"
                         : "Пишите друг другу каждый день — через 3 дня загорится огонёк.")
                    .font(.system(size: 16)).foregroundColor(.white.opacity(0.85)).multilineTextAlignment(.center).padding(.horizontal, 36).opacity(Double(phase))
                Button { close() } label: {
                    Text("Ура!").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .frame(width: 200, height: 52)
                        .background(LinearGradient(colors: [Color(hex: 0xffa318), Color(hex: 0xff5a2a)], startPoint: .leading, endPoint: .trailing), in: Capsule())
                }
                .buttonStyle(BouncyButtonStyle()).opacity(Double(phase)).padding(.top, 10)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: 0.25)) { shown = true }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.55).delay(0.1)) { phase = 1 }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(0.4)) { glow = true }
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.22)) { phase = 0; shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { onClose() }
    }
}

struct StreakCelebrationModifier: ViewModifier {
    @ObservedObject private var st = Streaks.shared
    func body(content: Content) -> some View {
        content.overlay {
            if let s = st.celebrate {
                StreakCelebration(s: s) { st.celebrate = nil }
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
    }
}

/// Системное сообщение о серии
struct StreakSystemPill: View {
    let m: Message
    @State private var open = false
    var body: some View {
        let lost = m.meta.keys.contains("streak_lost")
        let n = m.meta.int("streak") ?? 3
        Button { open = true } label: {
            HStack(spacing: 6) {
                FlameView(level: Streaks.levels.last { $0 <= max(n, 3) } ?? 3, lit: !lost).frame(width: 14, height: 17)
                Text((m.body ?? "").replacingOccurrences(of: "🔥 ", with: "").replacingOccurrences(of: "💨 ", with: ""))
                    .font(.system(size: 13, weight: .semibold)).multilineTextAlignment(.center)
            }
            .foregroundColor(lost ? Color(hex: 0x55585f) : Color(hex: 0x8a3a0a))
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(LinearGradient(colors: lost ? [Color(hex: 0xdadce2), Color(hex: 0xc4c7cf)] : [Color(hex: 0xffe3b8), Color(hex: 0xffc2a0)],
                                       startPoint: .leading, endPoint: .trailing), in: Capsule())
        }
        .buttonStyle(BouncyButtonStyle())
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .sheet(isPresented: $open) { StreakSheet(chatId: m.chatId) }
    }
}

// MARK: - Оформление профиля (цвет шапки и узор)

enum ProfileStyle {
    /// цвета шапки профиля (верх → низ градиента)
    static let colors: [(UInt32, UInt32)] = [
        (0x6f8cff, 0x3d4fd8), (0xb06bff, 0x6a2fd8), (0xff6fae, 0xd8336f), (0xff8a4c, 0xe0442a),
        (0xffc24c, 0xe08a12), (0x4cd98a, 0x1f9e5c), (0x3cc6e0, 0x1a7fa8), (0x7a8296, 0x434a5e),
        (0xff5f6d, 0xc0263a), (0x9be15d, 0x4caf2e), (0x5ee7df, 0x2a9d8f), (0x2b2d42, 0x101120),
    ]
    /// узоры (Premium): значки, рассыпанные вокруг аватара
    static let patterns: [String] = ["star.fill", "heart.fill", "sparkles", "moon.stars.fill", "leaf.fill", "bolt.fill",
                                     "music.note", "pawprint.fill", "snowflake", "flame.fill", "gamecontroller.fill", "crown.fill",
                                     "cloud.fill", "camera.fill", "airplane", "sun.max.fill"]

    static func gradient(_ i: Int?) -> LinearGradient? {
        guard let i, colors.indices.contains(i) else { return nil }
        return LinearGradient(colors: [Color(hex: colors[i].0), Color(hex: colors[i].1)], startPoint: .top, endPoint: .bottom)
    }
}

/// Фон шапки профиля: цвет + узор кольцами вокруг аватара (как в Telegram).
/// Узор "@status" — рисуется эмодзи-статусом владельца профиля.
struct ProfileStyleBackground: View {
    let bg: Int?
    let pattern: String?
    var status: String? = nil
    var avatarCenterY: CGFloat = 92
    @State private var drift = false

    private struct Dot: Identifiable { let id: Int; let dx: CGFloat; let dy: CGFloat; let size: CGFloat; let alpha: Double }

    private static let dots: [Dot] = {
        var out: [Dot] = []
        let counts = [7, 11, 15], radii: [CGFloat] = [92, 140, 190], sizes: [CGFloat] = [22, 19, 16]
        var id = 0
        for ring in 0..<3 {
            for k in 0..<counts[ring] {
                let a = Double(k) / Double(counts[ring]) * Double.pi * 2 + Double(ring) * 0.35
                let dx = CGFloat(cos(a)) * radii[ring]
                let dy = CGFloat(sin(a)) * radii[ring] * 0.82
                out.append(Dot(id: id, dx: dx, dy: dy, size: sizes[ring], alpha: 0.42 - Double(ring) * 0.1))
                id += 1
            }
        }
        return out
    }()

    var body: some View {
        ZStack {
            if let g = ProfileStyle.gradient(bg) {
                g
                // мягкое свечение за аватаром
                GeometryReader { geo in
                    RadialGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0)], center: .center, startRadius: 10, endRadius: 210)
                        .frame(width: 420, height: 420)
                        .position(x: geo.size.width / 2, y: avatarCenterY)
                }
            }
            if let p = pattern, !p.isEmpty {
                GeometryReader { geo in
                    let cx: CGFloat = geo.size.width / 2
                    let useStatus: Bool = p == "@status" && (status ?? "").isEmpty == false
                    let tint: Color = bg == nil ? Theme.a1 : Color.white
                    let anchor = UnitPoint(x: 0.5, y: avatarCenterY / max(geo.size.height, 1))
                    ZStack {
                        ForEach(Self.dots) { d in
                            Group {
                                if useStatus { StatusEmojiView(s: status ?? "", size: d.size).saturation(0.15) }
                                else { Image(systemName: p == "@status" ? "star.fill" : p).font(.system(size: d.size * 0.8)).foregroundColor(tint) }
                            }
                            .opacity(useStatus ? d.alpha * 0.9 : (bg == nil ? d.alpha * 0.6 : d.alpha * 0.8))
                            .position(x: cx + d.dx, y: avatarCenterY + d.dy)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    // узор медленно «дышит» и покачивается вокруг аватара, как в Telegram
                    .rotationEffect(.degrees(drift ? 7 : -7), anchor: anchor)
                    .scaleEffect(drift ? 1.05 : 0.97, anchor: anchor)
                }
                .onAppear { withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { drift = true } }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Сдвиг прокрутки (для растягивания аватара в профиле)
struct ProfileScrollKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Шапка профиля как в Telegram: цвет и узор, большая аватарка, имя со статусом.
/// Потяните вниз — аватар раскрывается на всю ширину; прокрутите вверх — сворачивается.
struct ProfileTopHero<Top: View, Bottom: View>: View {
    let name: String
    let avatarURL: String?
    let color: Int
    let status: String?          // эмодзи-статус (если Premium)
    let premiumStar: Bool
    let verified: Bool
    let subtitle: String
    var subtitleAccent = false
    let bg: Int?
    let pattern: String?
    var storyUid: String? = nil
    @Binding var expanded: Bool
    var onAvatar: () -> Void = {}
    var onStatus: (() -> Void)? = nil
    @ViewBuilder var top: () -> Top
    @ViewBuilder var bottom: () -> Bottom

    private var styled: Bool { bg != nil }

    var body: some View {
        let hasPhoto = (avatarURL ?? "").isEmpty == false
        VStack(spacing: 0) {
            if expanded && hasPhoto {
                ZStack(alignment: .bottomLeading) {
                    if let u = avatarURL, let link = URL(string: u) {
                        CachedImage(url: link) { img in img.resizable().scaledToFill() } placeholder: { Theme.panel2 }
                            .frame(maxWidth: .infinity).frame(height: UIScreen.main.bounds.width)
                            .clipped()
                    }
                    LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        nameRow(white: true, size: 26)
                        Text(subtitle).font(.system(size: 15)).foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 18).padding(.bottom, 16)
                }
                .frame(height: UIScreen.main.bounds.width)
                .overlay(alignment: .top) { top().padding(.horizontal, 14).padding(.top, 8) }
                .contentShape(Rectangle())
                .onTapGesture { onAvatar() }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                bottom().padding(.top, 12)
            } else {
                VStack(spacing: 8) {
                    top().padding(.horizontal, 14)
                    Button(action: onAvatar) {
                        AvatarView(name: name, url: avatarURL, color: color, size: 112, storyUid: storyUid)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    nameRow(white: styled, size: 27).padding(.top, 6)
                    Text(subtitle).font(.system(size: 16))
                        .foregroundColor(styled ? .white.opacity(0.85) : (subtitleAccent ? Theme.a2 : Theme.muted))
                        .multilineTextAlignment(.center).lineLimit(2)
                    bottom()
                }
                .padding(.bottom, styled ? 22 : 6)
                .frame(maxWidth: .infinity)
                .background {
                    ProfileStyleBackground(bg: bg, pattern: pattern, status: status, avatarCenterY: 308)
                        .padding(.top, -200).padding(.horizontal, -40)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: expanded)
    }

    @ViewBuilder private func nameRow(white: Bool, size: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(name).font(.system(size: size, weight: .bold)).foregroundColor(white ? .white : Theme.text)
                .lineLimit(1).minimumScaleFactor(0.7)
            if verified { Image(systemName: "checkmark.seal.fill").font(.system(size: size * 0.7)).foregroundColor(white ? .white : Theme.a2) }
            if let e = status, !e.isEmpty {
                Button { onStatus?() } label: { StatusEmojiView(s: e, size: size * 0.85) }.buttonStyle(.plain).disabled(onStatus == nil)
            } else if premiumStar {
                Button { onStatus?() } label: {
                    Image(systemName: "star.fill").font(.system(size: size * 0.75)).foregroundColor(white ? .white : Color(hex: 0xffb020))
                }.buttonStyle(.plain).disabled(onStatus == nil)
            }
        }
    }
}

/// Круглая «стеклянная» кнопка в шапке профиля
struct HeroGlassButton: View {
    let icon: String?
    var text: String? = nil
    var light = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if let t = text { Text(t).font(.system(size: 17, weight: .semibold)).padding(.horizontal, 16) }
                else if let i = icon { Image(systemName: i).font(.system(size: 18, weight: .semibold)).frame(width: 44) }
            }
            .frame(height: 44)
            .foregroundColor(light ? .white : Theme.text)
            .background(Capsule().fill(light ? Color.white.opacity(0.22) : Theme.panel.opacity(0.9)))
            .overlay(Capsule().stroke(Color.white.opacity(light ? 0.3 : 0), lineWidth: 0.8))
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Настройка оформления профиля
struct ProfileStyleView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var bg: Int?
    @State private var pattern: String?
    @State private var loaded = false
    @State private var busy = false
    @State private var showPremium = false

    var body: some View {
        let me = model.me
        let premium = me?.premium == true
        ScrollView {
            VStack(spacing: 16) {
                // превью
                ZStack {
                    ProfileStyleBackground(bg: bg, pattern: pattern, status: me?.emojiStatus, avatarCenterY: 92)
                    VStack(spacing: 8) {
                        AvatarView(name: me?.name ?? "", url: me?.avatarURL, color: me?.color ?? 0, size: 96)
                            .overlay(Circle().stroke(Color.white.opacity(bg == nil ? 0 : 0.6), lineWidth: 3))
                        HStack(spacing: 6) {
                            Text(me?.name ?? "").font(.system(size: 22, weight: .bold)).foregroundColor(bg == nil ? Theme.text : .white)
                            if premium, let e = me?.emojiStatus, !e.isEmpty { StatusEmojiView(s: e, size: 20) }
                        }
                        Text("в сети").font(.system(size: 14)).foregroundColor(bg == nil ? Theme.a2 : .white.opacity(0.8))
                    }
                    .padding(.top, 44)
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .background(Theme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.25), value: bg)
                .animation(.easeInOut(duration: 0.25), value: pattern)

                section("ЦВЕТ ПРОФИЛЯ") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        Button { bg = nil } label: {
                            ZStack {
                                Circle().fill(Theme.panel2).frame(width: 40, height: 40)
                                Image(systemName: "nosign").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.muted)
                            }
                            .overlay(Circle().stroke(bg == nil ? Theme.text : .clear, lineWidth: 2.5).frame(width: 47, height: 47))
                        }.buttonStyle(BouncyButtonStyle())
                        ForEach(ProfileStyle.colors.indices, id: \.self) { i in
                            Button { bg = i } label: {
                                ZStack {
                                    Circle().fill(ProfileStyle.gradient(i)!).frame(width: 40, height: 40)
                                    if bg == i { Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundColor(.white) }
                                }
                                .overlay(Circle().stroke(bg == i ? Theme.text : .clear, lineWidth: 2.5).frame(width: 47, height: 47))
                            }.buttonStyle(BouncyButtonStyle())
                        }
                    }
                    .padding(.vertical, 14).padding(.horizontal, 8)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                }

                section(premium ? "УЗОР" : "УЗОР · LUMO PREMIUM") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        Button { pattern = nil } label: {
                            ZStack {
                                Circle().fill(Theme.panel2).frame(width: 40, height: 40)
                                Image(systemName: "nosign").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.muted)
                            }
                            .overlay(Circle().stroke(pattern == nil ? Theme.text : .clear, lineWidth: 2.5).frame(width: 47, height: 47))
                        }.buttonStyle(BouncyButtonStyle())
                        if let e = me?.emojiStatus, !e.isEmpty {
                            Button { if premium { pattern = "@status" } else { showPremium = true } } label: {
                                ZStack {
                                    Circle().fill(Theme.panel2).frame(width: 40, height: 40)
                                    StatusEmojiView(s: e, size: 18)
                                }
                                .overlay(Circle().stroke(pattern == "@status" ? Theme.text : .clear, lineWidth: 2.5).frame(width: 47, height: 47))
                            }.buttonStyle(BouncyButtonStyle())
                        }
                        ForEach(ProfileStyle.patterns, id: \.self) { p in
                            Button {
                                if premium { pattern = p } else { showPremium = true }
                            } label: {
                                ZStack {
                                    Circle().fill(Theme.panel2).frame(width: 40, height: 40)
                                    Image(systemName: p).font(.system(size: 16, weight: .semibold)).foregroundColor(premium ? Theme.a1 : Theme.muted)
                                    if !premium { Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                                        .padding(3).background(Circle().fill(Theme.a1)).offset(x: 14, y: 14) }
                                }
                                .overlay(Circle().stroke(pattern == p ? Theme.text : .clear, lineWidth: 2.5).frame(width: 47, height: 47))
                            }.buttonStyle(BouncyButtonStyle())
                        }
                    }
                    .padding(.vertical, 14).padding(.horizontal, 8)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                    if !premium {
                        Text("Узоры вокруг аватара доступны с Lumo Premium.").font(.system(size: 13)).foregroundColor(Theme.muted).padding(.leading, 4)
                    }
                }
                Button {
                    busy = true
                    Task { if await model.setProfileStyle(bg: bg, pattern: pattern) { model.say("Оформление сохранено"); dismiss() }; busy = false }
                } label: {
                    HStack(spacing: 8) { if busy { ProgressView().tint(.white) }; Text("Сохранить") }
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.a1, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(BouncyButtonStyle()).disabled(busy).padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Оформление профиля").navigationBarTitleDisplayMode(.inline)
        .onAppear { if !loaded { loaded = true; bg = model.me?.profileBg; pattern = model.me?.profilePattern } }
        .alert("Lumo Premium", isPresented: $showPremium) {
            Button("Понятно", role: .cancel) {}
        } message: { Text("Узоры профиля доступны с подпиской Lumo Premium. Оформить её можно в настройках.") }
    }

    private func section<C: View>(_ t: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).padding(.leading, 4)
            c()
        }
        .padding(.horizontal, 16)
    }
}

extension View {
    /// Насколько список оттянут вниз (положительное значение) или прокручен вверх (отрицательное).
    /// На iOS 18+ — точные данные прокрутки, на старых — через GeometryReader-маркер.
    @ViewBuilder func onPull(_ f: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self, of: { g in -(g.contentOffset.y + g.contentInsets.top) }, action: { _, y in f(y) })
        } else {
            self.onPreferenceChange(ProfileScrollKey.self) { y in f(y) }
        }
    }
}
