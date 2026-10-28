import SwiftUI

enum ChatFolder: String, CaseIterable {
    case all, privateChats, groups, channels, unread
    var title: String {
        switch self {
        case .all: return "Все"
        case .privateChats: return "Чаты"
        case .groups: return "Группы"
        case .channels: return "Каналы"
        case .unread: return "Непрочитанные"
        }
    }
}

struct ChatListView: View {
    @EnvironmentObject var model: AppModel
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var searching = false
    @State private var folder: ChatFolder = .all
    @State private var showNew = false
    @State private var storyStart: String?
    @State private var addStory = false
    @FocusState private var searchFocused: Bool
    /// iPad: список слева, чат справа (без собственной навигации)
    var sidebar = false

    private var filtered: [ChatItem] {
        switch folder {
        case .all: return model.chats
        case .privateChats: return model.chats.filter { $0.isPrivate }
        case .groups: return model.chats.filter { $0.type == "group" }
        case .channels: return model.chats.filter { $0.isChannel }
        case .unread: return model.chats.filter { $0.unread > 0 }
        }
    }

    private func count(_ f: ChatFolder) -> Int {
        let u = model.chats.filter { $0.unread > 0 && !$0.muted }
        switch f {
        case .all: return 0
        case .privateChats: return u.filter { $0.isPrivate }.count
        case .groups: return u.filter { $0.type == "group" }.count
        case .channels: return u.filter { $0.isChannel }.count
        case .unread: return u.count
        }
    }

    var body: some View {
        if sidebar {
            listContent
        } else {
            NavigationStack(path: $model.path) {
                listContent
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: String.self) { id in ChatView(chatId: id) }
            }
        }
    }

    @ViewBuilder private func chatLink(_ c: ChatItem) -> some View {
        if sidebar {
            Button { model.path = [c.id] } label: { ChatRow(chat: c) }
                .background(model.path.last == c.id ? Theme.a1.opacity(0.22) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
        } else {
            NavigationLink(value: c.id) { ChatRow(chat: c) }
        }
    }

    private var listContent: some View {
            VStack(spacing: 0) {
                if let s = model.netStatus {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text(s).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                    }
                    .frame(maxWidth: .infinity).frame(height: 30)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                HStack(spacing: 10) {
                    SearchField(placeholder: "Поиск", text: $query, focused: $searchFocused)
                    Button { showNew = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .frame(width: 48, height: 48)
                            .lumoGlass(RoundedRectangle(cornerRadius: 18), interactive: true)
                    }
                }
                .padding(.horizontal, 14).padding(.top, 8).padding(.bottom, 8)

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    folders
                    chatList
                } else {
                    searchList
                }
            }
            .animation(.easeInOut(duration: 0.25), value: model.netStatus)
            .background(Theme.bg.ignoresSafeArea())
            .onChange(of: query) { q in runSearch(q) }
            .sheet(isPresented: $showNew) { NewChatView().environmentObject(model) }
            .fullScreenCover(item: Binding(get: { storyStart.map { IdentifiedString(value: $0) } }, set: { storyStart = $0?.value })) { s in
                StoryViewer(startUser: s.value).environmentObject(model)
            }
            .sheet(isPresented: $addStory) { AddStoryView().environmentObject(model) }
    }

    private var folders: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(ChatFolder.allCases, id: \.self) { f in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { folder = f }
                    } label: {
                        HStack(spacing: 6) {
                            Text(f.title).font(.system(size: 14, weight: .bold))
                            let n = count(f)
                            if n > 0 {
                                Text("\(n)").font(.system(size: 11, weight: .heavy)).foregroundColor(.white)
                                    .padding(.horizontal, 6).frame(minHeight: 18)
                                    .background(Capsule().fill(Theme.a1))
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .foregroundColor(Theme.text)
                        .background(RoundedRectangle(cornerRadius: 18).fill(folder == f ? Theme.panel : Color.clear))
                        .shadow(color: folder == f ? .black.opacity(0.12) : .clear, radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
        }
        .lumoGlass(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private var chatList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if folder == .all { StoriesBar(open: { storyStart = $0 }, add: { addStory = true }) }
                if !model.chatsLoaded {
                    ProgressView().padding(40)
                } else if filtered.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 44)).foregroundColor(Theme.muted)
                        Text(folder == .all ? "Пока нет чатов" : "Здесь пока пусто").font(.headline)
                        if folder == .all {
                            Text("Найдите человека по имени или @юзернейму в поиске сверху").foregroundColor(Theme.muted)
                                .multilineTextAlignment(.center).padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filtered) { c in
                        chatLink(c)
                            .buttonStyle(RowButtonStyle())
                            .contextMenu {
                                Button { Task { await model.setPinned(c.id, !c.pinned) } } label: {
                                    Label(c.pinned ? "Открепить" : "Закрепить", systemImage: c.pinned ? "pin.slash" : "pin")
                                }
                                Button { Task { await model.setMuted(c.id, !c.muted) } } label: {
                                    Label(c.muted ? "Включить уведомления" : "Выключить уведомления", systemImage: c.muted ? "bell" : "bell.slash")
                                }
                                if c.unread > 0 {
                                    Button { Task { await model.loadMessages(c.id); model.markRead(c.id) } } label: {
                                        Label("Прочитано", systemImage: "checkmark.message")
                                    }
                                }
                                if c.isPrivate {
                                    Button(role: .destructive) { Task { await model.clearChat(c.id) } } label: {
                                        Label("Очистить историю", systemImage: "trash")
                                    }
                                } else {
                                    Button(role: .destructive) { Task { await model.leave(c.id) } } label: {
                                        Label(c.isChannel ? "Отписаться" : "Покинуть группу", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                }
                            } preview: {
                                ChatPreviewCard(chat: c).environmentObject(model)
                            }
                    }
                }
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 8)
        }
        .refreshable {
            await model.loadChats()
            await model.loadStories()
        }
    }

    private var searchList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let q = query.lowercased().replacingOccurrences(of: "@", with: "")
                let local = model.chats.filter { $0.displayName.lowercased().contains(q) || ($0.peerUsername ?? "").contains(q) }
                if !local.isEmpty {
                    SectionTitle(text: "Чаты")
                    ForEach(local) { c in
                        chatLink(c).buttonStyle(RowButtonStyle())
                    }
                }
                let global = results.filter { r in !local.contains { $0.id == r.id || $0.peerId == r.id } }
                if !global.isEmpty {
                    SectionTitle(text: "Глобальный поиск")
                    ForEach(global) { r in
                        Button { openResult(r) } label: {
                            HStack(spacing: 12) {
                                AvatarView(name: r.name, url: r.avatarURL, color: r.color, size: 50, online: model.isOnline(r.id),
                                           icon: r.kind == "channel" ? "megaphone.fill" : r.kind == "group" ? "person.2.fill" : nil)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                    Text(r.kind == "user" ? "@" + (r.username ?? "") : (r.kind == "channel" ? "Канал" : "Группа") + " · " + (r.extra ?? "0") + " уч.")
                                        .font(.subheadline).foregroundColor(Theme.muted)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 10).padding(.vertical, 8)
                        }
                        .buttonStyle(RowButtonStyle())
                    }
                }
                if searching && results.isEmpty && local.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }.padding(30)
                } else if !searching && local.isEmpty && global.isEmpty {
                    Text("Ничего не найдено").foregroundColor(Theme.muted).frame(maxWidth: .infinity).padding(30)
                }
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 8)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func openResult(_ r: SearchResult) {
        query = ""
        searchFocused = false
        Task {
            if r.kind == "user" { await model.openDM(r.id) }
            else if model.chat(r.id) != nil { model.open(r.id) }
            else { await model.join(r.id) }
        }
    }

    private func runSearch(_ q: String) {
        let t = q.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !t.isEmpty else { results = []; searching = false; return }
        searching = true
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard t == query.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "") else { return }
            let r = await model.search(t)
            if t == query.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "") {
                results = r.filter { $0.id != model.myId }
                searching = false
            }
        }
    }
}

struct IdentifiedString: Identifiable {
    var id: String { value }
    let value: String
}

/// Подсветка строки при нажатии (как hover на сайте)
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(RoundedRectangle(cornerRadius: 16).fill(configuration.isPressed ? Theme.hover : Color.clear))
    }
}

struct ChatRow: View {
    @EnvironmentObject var model: AppModel
    let chat: ChatItem

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: chat.displayName, url: chat.displayAvatar, color: chat.displayColor, size: 54,
                       online: chat.isPrivate && chat.peerId != model.myId && model.isOnline(chat.peerId),
                       icon: chat.isPrivate && chat.peerId == model.myId ? "bookmark.fill" : nil)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if chat.isChannel { Image(systemName: "megaphone.fill").font(.caption).foregroundColor(Theme.muted) }
                    else if chat.type == "group" { Image(systemName: "person.2.fill").font(.caption).foregroundColor(Theme.muted) }
                    Text(chat.isPrivate && chat.peerId == model.myId ? "Избранное" : chat.displayName)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                    if chat.isPrivate && chat.peerId != model.myId { NameBadges(bot: chat.peerBot, premium: chat.peerPremium, emoji: chat.peerId.flatMap { model.profiles[$0]?.emojiStatus }, verified: chat.peerVerified || (chat.peerId.flatMap { model.profiles[$0]?.verified } ?? false)) }
                    if chat.muted { Image(systemName: "speaker.slash.fill").font(.caption2).foregroundColor(Theme.muted) }
                    Spacer(minLength: 4)
                    if chat.lastSender == model.myId, chat.lastId != nil, chat.lastKind != "system" {
                        let read = (chat.othersReadAt ?? .distantPast) >= (chat.lastAt ?? .distantFuture)
                        Image(systemName: read ? "checkmark.circle.fill" : "checkmark")
                            .font(.caption2).foregroundColor(Theme.a2)
                    }
                    Text(Fmt.time(chat.lastAt)).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                }
                HStack(alignment: .top) {
                    if let t = model.typingText(chat.id) {
                        Text(t).font(.system(size: 14.5, weight: .semibold)).foregroundColor(Theme.a2).lineLimit(1)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if chat.lastId != nil, !chat.lastDeleted, let ic = Message.previewIcon(kind: chat.lastKind ?? "") {
                                Image(systemName: ic).font(.system(size: 13, weight: .semibold))
                            }
                            Text(chat.preview(myId: model.myId)).font(.system(size: 14.5)).lineLimit(2)
                        }
                        .foregroundColor(Theme.muted)
                    }
                    Spacer(minLength: 4)
                    if chat.unread > 0 {
                        Text(chat.unread > 99 ? "99+" : "\(chat.unread)")
                            .font(.system(size: 12, weight: .heavy))
                            .padding(.horizontal, 7).frame(minWidth: 22, minHeight: 22)
                            .background(Capsule().fill(chat.muted ? Color(hex: 0xa3a6c2) : Theme.a1))
                            .foregroundColor(.white)
                    } else if chat.pinned {
                        Image(systemName: "pin.fill").font(.caption).foregroundColor(Theme.muted)
                    }
                }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}


/// Превью чата в меню по долгому нажатию: последние сообщения
struct ChatPreviewCard: View {
    @EnvironmentObject var model: AppModel
    let chat: ChatItem

    var body: some View {
        let msgs = Array((model.messages[chat.id] ?? []).filter { !$0.deleted && $0.kind != "system" }.suffix(7))
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                Text(chat.isPrivate && chat.peerId == model.myId ? "Избранное" : chat.displayName)
                    .font(.system(size: 16, weight: .bold)).lineLimit(1)
                Text(chat.isPrivate ? (chat.peerBot ? "бот" : model.lastSeenText(chat.peerId, fallback: chat.peerLastSeen)) : "\(chat.membersCount) уч.")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
            }
            .padding(.horizontal, 18).padding(.vertical, 6)
            .background(Theme.panel.opacity(0.9), in: Capsule())
            VStack(spacing: 5) {
                if msgs.isEmpty {
                    Text(chat.preview).font(.system(size: 14)).foregroundColor(Theme.muted).padding(.top, 30)
                }
                ForEach(msgs) { m in
                    let mine = m.senderId == model.myId
                    HStack {
                        if mine { Spacer(minLength: 40) }
                        Text((m.body ?? "").isEmpty ? Message.previewText(kind: m.kind, body: m.body) : String((m.body ?? "").prefix(160)))
                            .font(.system(size: 15)).foregroundColor(mine ? .white : Theme.text).lineLimit(4)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(mine ? AnyShapeStyle(Theme.out) : AnyShapeStyle(Theme.panel), in: RoundedRectangle(cornerRadius: 18))
                        if !mine { Spacer(minLength: 40) }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 320, height: 420, alignment: .top)
        .background(Theme.bg)
        .task { await model.loadMessages(chat.id) }
    }
}
