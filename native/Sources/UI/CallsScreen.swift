import SwiftUI

/// Раздел «Звонки»: как «Недавние» в «Телефоне» iPhone
struct CallEntry: Identifiable {
    var id: Int { message.id }
    let message: Message
    let chat: ChatItem
}

/// Подряд идущие звонки одному человеку сливаются в одну строку
struct CallGroup: Identifiable {
    var id: Int { items[0].id }
    let items: [CallEntry]
    var chat: ChatItem { items[0].chat }
}

struct CallsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var calls: CallManager
    @ObservedObject private var vice = ViceState.shared
    @State private var onlyMissed = false
    @State private var editing = false
    @State private var showNew = false
    @State private var live: [String: Int] = [:]

    private func entry(_ m: Message, _ c: ChatItem) -> CallEntry { CallEntry(message: m, chat: c) }

    private var groups: [CallGroup] {
        var out: [[CallEntry]] = []
        for m in model.calls {
            guard let c = model.chat(m.chatId), c.isPrivate else { continue }
            let e = entry(m, c)
            if onlyMissed && !CallRowView.isMissed(m, mine: model.myId) { continue }
            if var last = out.last, last[0].chat.id == c.id,
               Calendar.current.isDate(last[0].message.createdAt, inSameDayAs: m.createdAt) {
                last.append(e); out[out.count - 1] = last
            } else { out.append([e]) }
        }
        return out.map { CallGroup(items: $0) }
    }

    private var liveChats: [ChatItem] { model.chats.filter { $0.type == "group" && (live[$0.id] ?? 0) > 0 } }

    var body: some View {
        VStack(spacing: 0) {
            header
            if vice.on {
                Text("ЗВОНКИ").viceTitle(32).frame(maxWidth: .infinity).padding(.bottom, 6)
            }
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    Button { showNew = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "phone.badge.plus").font(.system(size: 24)).foregroundColor(Theme.a1).frame(width: 40)
                            Text("Новый звонок").font(.system(size: 20)).foregroundColor(Theme.a1)
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }
                    Divider().overlay(Theme.line).padding(.leading, 70)
                    if !liveChats.isEmpty && !onlyMissed {
                        sectionTitle("Видеочаты")
                        ForEach(liveChats) { c in liveRow(c) }
                    }
                    sectionTitle(onlyMissed ? "Пропущенные" : "Недавние звонки")
                    if groups.isEmpty {
                        Text(onlyMissed ? "Пропущенных звонков нет" : "Звонков пока нет.\nПозвонить можно из чата или из контактов")
                            .multilineTextAlignment(.center).foregroundColor(Theme.muted).padding(40)
                    }
                    ForEach(groups) { g in
                        CallRowView(group: g, editing: editing)
                        Divider().overlay(Theme.line).padding(.leading, 86)
                    }
                    Color.clear.frame(height: 110)
                }
            }
        }
        .background(alignment: .top) { if vice.on { ViceSky(height: 240).ignoresSafeArea(edges: .top) } }
        .background(Theme.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.22), value: onlyMissed)
        .animation(.easeInOut(duration: 0.22), value: editing)
        .sheet(isPresented: $showNew) { NewCallSheet().environmentObject(model).environmentObject(calls) }
        .task { await model.loadCalls() }
        .task { await pollLive() }
        .refreshable { await model.loadCalls() }
    }

    private var header: some View {
        HStack {
            Button { editing.toggle() } label: {
                Text(editing ? "Готово" : "Изм.").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text)
                    .padding(.horizontal, 18).frame(height: 44)
                    .background(Capsule().fill(Theme.panel))
            }
            Spacer()
            HStack(spacing: 0) {
                seg("Все", !onlyMissed) { onlyMissed = false }
                seg("Пропущ.", onlyMissed) { onlyMissed = true }
            }
            .padding(4).background(Capsule().fill(Theme.panel))
            Spacer()
            Button { showNew = true } label: {
                Image(systemName: "phone.badge.plus").font(.system(size: 19)).foregroundColor(Theme.text)
                    .frame(width: 44, height: 44).background(Circle().fill(Theme.panel))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func seg(_ t: String, _ on: Bool, _ f: @escaping () -> Void) -> some View {
        Button(action: f) {
            Text(t).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                .padding(.horizontal, 18).frame(height: 36)
                .background(Capsule().fill(on ? Theme.panel2 : .clear))
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        HStack { Text(t.uppercased()).font(.system(size: 14, weight: .medium)).foregroundColor(Theme.muted); Spacer() }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 6)
    }

    private func liveRow(_ c: ChatItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform").font(.system(size: 14, weight: .bold)).foregroundColor(Color(hex: 0x34c759)).frame(width: 22)
            AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(c.displayName).font(.system(size: 19, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                Text("Участников: \(live[c.id] ?? 0)").font(.system(size: 14)).foregroundColor(Theme.muted)
            }
            Spacer()
            Button { Task { await GroupCalls.shared.start(c.id, video: true, join: true) } } label: {
                Text("ВСТУПИТЬ").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 18).frame(height: 40).background(Capsule().fill(Theme.a1))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    /// какие группы сейчас в звонке (проверяем самые свежие группы)
    private func pollLive() async {
        while !Task.isCancelled {
            for c in model.chats.filter({ $0.type == "group" }).prefix(12) {
                let n = await model.groupCallCount(c.id)
                if Task.isCancelled { return }
                if live[c.id] != n { live[c.id] = n }
            }
            try? await Task.sleep(nanoseconds: 20_000_000_000)
        }
    }
}

struct CallRowView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var calls: CallManager
    let group: CallGroup
    let editing: Bool
    @State private var removed = false

    static func isMissed(_ m: Message, mine: String?) -> Bool {
        let st = m.metaStatus ?? ""
        return m.senderId != mine && st != "ended" && st != "rejected"
    }

    private func kind(_ m: Message) -> String {
        let out = m.senderId == model.myId
        let st = m.metaStatus ?? ""
        if out { return st == "ended" ? "Исходящий" : "Отменённый" }
        if st == "ended" { return "Входящий" }
        return st == "rejected" ? "Отклонённый" : "Пропущенный"
    }

    private var label: String {
        var seen: [String] = []
        for m in group.items { let k = kind(m.message); if !seen.contains(k) { seen.append(k) } }
        var t = seen.joined(separator: ", ")
        if group.items.count > 1 { t += " (\(group.items.count))" }
        if group.items.count == 1, let m = group.items.first?.message {
            if m.isVideoCall { t += " видео" }
            if (m.metaStatus ?? "") == "ended", m.duration > 0 { t += " · " + Fmt.duration(m.duration) }
        }
        return t
    }

    private var missed: Bool { CallRowView.isMissed(group.items[0].message, mine: model.myId) }
    private var outgoing: Bool { group.items[0].message.senderId == model.myId }

    var body: some View {
        let c = group.chat
        let m = group.items[0].message
        HStack(spacing: 12) {
            if editing {
                Button {
                    withAnimation { removed = true }
                    Task { await model.delete(group.items.map { $0.message }, everyone: false); await model.loadCalls() }
                } label: { Image(systemName: "minus.circle.fill").font(.system(size: 22)).foregroundColor(Theme.danger) }
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: outgoing ? "phone.arrow.up.right" : "phone.arrow.down.left")
                    .font(.system(size: 13)).foregroundColor(outgoing ? Theme.muted : .clear).frame(width: 22)
            }
            AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 56, online: model.isOnline(c.peerId))
            VStack(alignment: .leading, spacing: 2) {
                Text(c.displayName).font(.system(size: 19, weight: .semibold)).foregroundColor(missed ? Theme.danger : Theme.text).lineLimit(1)
                Text(label).font(.system(size: 15)).foregroundColor(Theme.muted).lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(Fmt.time(m.createdAt)).font(.system(size: 16)).foregroundColor(Theme.muted)
            Button { model.open(c.id) } label: {
                Image(systemName: "info.circle").font(.system(size: 24)).foregroundColor(Theme.a1)
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { if !editing { calls.startCall(chat: c, video: m.isVideoCall) } }
        .opacity(removed ? 0 : 1)
        .frame(height: removed ? 0 : nil).clipped()
    }
}

/// Выбор, кому позвонить
struct NewCallSheet: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var calls: CallManager
    @Environment(\.dismiss) private var dismiss
    @State private var q = ""

    private var list: [ChatItem] {
        let l = model.chats.filter { $0.isPrivate && $0.peerId != nil }
        let s = q.trimmingCharacters(in: .whitespaces).lowercased()
        return s.isEmpty ? l : l.filter { $0.displayName.lowercased().contains(s) }
    }

    var body: some View {
        NavigationStack {
            List(list) { c in
                HStack(spacing: 12) {
                    AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 44, online: model.isOnline(c.peerId))
                    Text(c.displayName).font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button { go(c, video: false) } label: { Image(systemName: "phone.fill").frame(width: 40, height: 40).background(Circle().fill(Theme.panel2)) }
                        .buttonStyle(BouncyButtonStyle())
                    Button { go(c, video: true) } label: { Image(systemName: "video.fill").frame(width: 40, height: 40).background(Circle().fill(Theme.panel2)) }
                        .buttonStyle(BouncyButtonStyle())
                }
                .listRowBackground(Theme.bg)
            }
            .listStyle(.plain)
            .searchable(text: $q, prompt: "Поиск")
            .background(Theme.bg)
            .navigationTitle("Новый звонок").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
    }

    private func go(_ c: ChatItem, video: Bool) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { calls.startCall(chat: c, video: video) }
    }
}
