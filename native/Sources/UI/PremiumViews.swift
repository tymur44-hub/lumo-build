import SwiftUI

let premiumSoon = "Функция Lumo Premium. Оформление пока временно недоступно"

// MARK: - Модель: функции Premium

extension AppModel {
    var isPremium: Bool { me?.premium == true }

    /// Выполняет действие, только если у пользователя есть Premium; иначе сообщает, что функция пока недоступна
    func premium(_ action: () -> Void) {
        if isPremium { action() } else { say(premiumSoon) }
    }

    func scheduleMessage(chatId: String, text: String, at: Date, replyTo: Int?) async -> Bool {
        await prep(chatId)
        var wire = text
        if let e = E2E.shared.encrypt(chatId, text) { wire = e }
        var p: JSON = ["p_chat": chatId, "p_kind": "text", "p_body": wire, "p_meta": [String: Any](), "p_at": DateParser.string(at)]
        if let r = replyTo { p["p_reply"] = r }
        do { _ = try await API.shared.rpc("lm_schedule", p); return true }
        catch { say((error as? APIError)?.message ?? "Не удалось запланировать"); return false }
    }

    func scheduledList(chatId: String) async -> [(id: Int, at: Date, text: String)] {
        guard let rows = try? await API.shared.rpc("lm_scheduled_list", ["p_chat": chatId]) as? [JSON] else { return [] }
        await prep(chatId)
        return rows.map { r in
            var t = r.str("body") ?? ""
            if t.hasPrefix("e2e1:"), let d = E2E.shared.decrypt(chatId, t) { t = d } else if t.hasPrefix("e2e1:") { t = "🔒" }
            return (r.int("id") ?? 0, r.date("send_at") ?? Date(), t)
        }
    }

    func cancelScheduled(_ id: Int) async { _ = try? await API.shared.rpc("lm_scheduled_cancel", ["p_id": id]) }

    func chatTTL(_ chatId: String) async -> Int {
        let r = try? await API.shared.select("lm_chats", ["select": "ttl_seconds", "id": "eq." + chatId]).first
        return r?.int("ttl_seconds") ?? 0
    }

    func setChatTTL(_ chatId: String, _ seconds: Int) async -> Bool {
        do { _ = try await API.shared.rpc("lm_set_chat_ttl", ["p_chat": chatId, "p_seconds": seconds]); return true }
        catch { say((error as? APIError)?.message ?? "Не удалось изменить"); return false }
    }

    func channelStats(_ chatId: String) async -> JSON? {
        do { return try await API.shared.rpc("lm_channel_stats", ["p_chat": chatId]) as? JSON }
        catch { say((error as? APIError)?.message ?? "Не удалось загрузить"); return nil }
    }

    func setEmojiStatus(_ e: String) async {
        do { _ = try await API.shared.rpc("lm_set_emoji_status", ["p_emoji": e]); await loadMe(); say(e.isEmpty ? "Статус убран" : "Статус установлен") }
        catch { say((error as? APIError)?.message ?? "Не удалось изменить") }
    }
}

// MARK: - Отложенная отправка

struct ScheduleSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    let text: String
    let replyTo: Int?
    var onDone: () -> Void
    @State private var at = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Сообщение уйдёт само в выбранное время, даже если Lumo закрыт.")
                    .font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                DatePicker("", selection: $at, in: Date().addingTimeInterval(30)..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical).labelsHidden()
                Button {
                    Task { if await model.scheduleMessage(chatId: chatId, text: text, at: at, replyTo: replyTo) { onDone(); dismiss(); model.say("Запланировано") } }
                } label: {
                    Text("Запланировать").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 50).background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Отложить отправку").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
        .presentationDetents([.large])
    }
}

struct ScheduledListSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    @State private var items: [(id: Int, at: Date, text: String)] = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            List {
                if loaded && items.isEmpty { Text("Запланированных сообщений нет").foregroundColor(Theme.muted) }
                ForEach(items, id: \.id) { it in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(it.at.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 15, weight: .semibold))
                        Text(it.text).font(.system(size: 14)).foregroundColor(Theme.muted).lineLimit(2)
                    }
                    .swipeActions { Button(role: .destructive) { Task { await model.cancelScheduled(it.id); items.removeAll { $0.id == it.id } } } label: { Text("Отменить") } }
                }
            }
            .scrollContentBackground(.hidden).background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Запланированные").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .task { items = await model.scheduledList(chatId: chatId); loaded = true }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Исчезающие сообщения и статистика канала

struct PremiumChatRows: View {
    @EnvironmentObject var model: AppModel
    let chat: ChatItem
    @State private var ttl = 0
    @State private var showTTL = false
    @State private var stats: JSON?
    @State private var showStats = false

    private var ttlText: String {
        switch ttl { case 3600: return "1 час"; case 86400: return "1 день"; case 604800: return "1 неделя"; case 2592000: return "1 месяц"; default: return "Выключено" }
    }
    private var canTTL: Bool { !chat.isChannel && !(chat.isPrivate && (chat.peerId == model.myId || chat.peerBot)) }

    var body: some View {
        if canTTL || (chat.isChannel && chat.isAdmin) {
            SettingsGroup {
                if canTTL {
                    Button { showTTL = true } label: {
                        SettingsRow(icon: "timer", color: Color(hex: 0x2bd67b), title: "Исчезающие сообщения", subtitle: ttlText)
                    }
                }
                if canTTL && chat.isChannel && chat.isAdmin { Divider().overlay(Theme.line) }
                if chat.isChannel && chat.isAdmin {
                    Button {
                        model.premium { Task { stats = await model.channelStats(chat.id); showStats = stats != nil } }
                    } label: {
                        SettingsRow(icon: "chart.bar.fill", color: Color(hex: 0x3a7bff), title: "Статистика канала", subtitle: "Подписчики и посты")
                    }
                }
            }
            .task { if canTTL { ttl = await model.chatTTL(chat.id) } }
            .confirmationDialog("Исчезающие сообщения", isPresented: $showTTL, titleVisibility: .visible) {
                ForEach([(0, "Выключить"), (3600, "1 час"), (86400, "1 день"), (604800, "1 неделя"), (2592000, "1 месяц")], id: \.0) { v in
                    Button(v.1) {
                        if v.0 > 0 && !model.isPremium { model.say(premiumSoon); return }
                        Task { if await model.setChatTTL(chat.id, v.0) { ttl = v.0 } }
                    }
                }
            } message: { Text("Сообщения в этом чате будут удаляться у всех через выбранное время после отправки.") }
            .sheet(isPresented: $showStats) { ChannelStatsSheet(stats: stats ?? [:]) }
        }
    }
}

struct ChannelStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let stats: JSON

    private func n(_ k: String) -> Int { (stats[k] as? Int) ?? Int((stats[k] as? Double) ?? 0) }
    private var days: [(Int, Int)] {
        ((stats["days"] as? [[String: Any]]) ?? []).map { (($0["joined"] as? Int) ?? 0, ($0["posts"] as? Int) ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        tile("Подписчиков", n("subscribers")); tile("Новых за 7 дней", n("joined_7d")); tile("Новых за 30 дней", n("joined_30d"))
                        tile("Постов всего", n("posts")); tile("Постов за 7 дней", n("posts_7d"))
                    }
                    Text("Последние 14 дней: новые подписчики и посты").font(.footnote).foregroundColor(Theme.muted)
                    let mx = max(1, days.map { max($0.0, $0.1) }.max() ?? 1)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                            HStack(alignment: .bottom, spacing: 1) {
                                RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(height: max(2, CGFloat(d.0) / CGFloat(mx) * 80))
                                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x2bd67b)).frame(height: max(2, CGFloat(d.1) / CGFloat(mx) * 80))
                            }
                        }
                    }
                    .frame(height: 84)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Статистика канала").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func tile(_ t: String, _ v: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(v)").font(.system(size: 24, weight: .heavy))
            Text(t).font(.footnote).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
    }
}
