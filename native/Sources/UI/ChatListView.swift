import SwiftUI

enum ChatFolder: String, CaseIterable {
    case all, privateChats, groups, channels
    var title: String {
        switch self {
        case .all: return "Все"
        case .privateChats: return "Частный"
        case .groups: return "Группы"
        case .channels: return "Каналы"
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
    @State private var deleting: ChatItem?
    @State private var swipeOpen: String?
    @ObservedObject private var marks = UnreadMarks.shared
    @State private var storyStart: String?
    @State private var addStory = false
    @State private var showNet = false
    @State private var showEmoji = false
    @State private var storiesOpen = false
    @State private var pulled = false
    @State private var archiveMode: String?
    @Namespace private var foldNS
    @FocusState private var searchFocused: Bool
    /// iPad: список слева, чат справа (без собственной навигации)
    var sidebar = false

    private var filtered: [ChatItem] {
        switch folder {
        case .all: return model.chats
        case .privateChats: return model.chats.filter { $0.isPrivate }
        case .groups: return model.chats.filter { $0.type == "group" }
        case .channels: return model.chats.filter { $0.isChannel }
        }
    }

    /// число непрочитанных чатов в папке и есть ли среди них не заглушённые (тогда значок синий, иначе серый)
    private func count(_ f: ChatFolder) -> (Int, Bool) {
        let u = model.chats.filter { $0.unread > 0 }
        let l: [ChatItem]
        switch f {
        case .all: return (0, false)
        case .privateChats: l = u.filter { $0.isPrivate }
        case .groups: l = u.filter { $0.type == "group" }
        case .channels: l = u.filter { $0.isChannel }
        }
        return (l.count, l.contains { !$0.muted })
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
                header
                    .padding(.horizontal, 14).padding(.top, 6)
                SearchField(placeholder: "Поиск", text: $query, focused: $searchFocused)
                    .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 10)

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    if storiesOpen {
                        StoriesBar(open: { storyStart = $0 }, add: { addStory = true }, menu: { archiveMode = $0 })
                            .padding(.bottom, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    folders
                    chatList
                } else {
                    searchList
                }
            }
            .animation(.easeInOut(duration: 0.25), value: model.netStatus)
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: storiesOpen)
            .background(Theme.bg.ignoresSafeArea())
            .onChange(of: query) { q in runSearch(q) }
            .sheet(isPresented: $showNew) { NewChatView().environmentObject(model) }
            .fullScreenCover(item: Binding(get: { storyStart.map { IdentifiedString(value: $0) } }, set: { storyStart = $0?.value })) { s in
                StoryViewer(startUser: s.value).environmentObject(model)
            }
            .fullScreenCover(isPresented: $addStory) { AddStoryView().environmentObject(model) }
            .sheet(item: Binding(get: { archiveMode.map { IdentifiedString(value: $0) } }, set: { archiveMode = $0?.value })) { m in
                StoryArchiveView(postsOnly: m.value == "posts").environmentObject(model)
            }
    }

    /// Шапка как в Telegram: «Изм.», истории + «Чаты», кнопки справа и синяя «Новый чат»
    private var header: some View {
        HStack(spacing: 10) {
            Menu {
                Button { model.markAllRead() } label: { Label("Прочитать все", systemImage: "checkmark.message") }
                Button { showNew = true } label: { Label("Новый чат, группа или канал", systemImage: "square.and.pencil") }
            } label: {
                Text("Изм.").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1).fixedSize()
                    .padding(.horizontal, 16).frame(height: 44)
                    .lumoGlass(Capsule(), interactive: true)
                    .fixedSize()
            }
            .layoutPriority(4)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if !storiesOpen { storyStack.transition(.scale(scale: 0.5).combined(with: .opacity)) }
                Text("Чаты").font(.system(size: 19, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                    .fixedSize().layoutPriority(3)
                if model.me?.premium == true {
                    // эмодзи-статус рядом с «Чаты»; нажатие — выбрать другой
                    Button { showEmoji = true } label: {
                        if let e = model.me?.emojiStatus, !e.isEmpty { StatusEmojiView(s: e, size: 22) }
                        else { Image(systemName: "star.fill").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.a1) }
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .fixedSize()
                }
            }
            .layoutPriority(2)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Button { showNet = true } label: {
                    Image(systemName: Net.mode == .direct ? "checkmark.shield" : "bolt.shield")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(Theme.text).frame(width: 40, height: 44)
                }
                Button { addStory = true } label: {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 19, weight: .semibold)).foregroundColor(Theme.text).frame(width: 40, height: 44)
                }
            }
            .padding(.horizontal, 4)
            .lumoGlass(Capsule(), interactive: true)
            Button { showNew = true } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 19, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Theme.a1))
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .sheet(isPresented: $showEmoji) { EmojiStatusSheet().environmentObject(model) }
        .alert("Соединение", isPresented: $showNet) {
            Button("Проверить заново") { Task { await Net.pick(force: true); await model.loadChats() } }
            Button("Закрыть", role: .cancel) {}
        } message: {
            Text(Net.mode == .direct ? "Прямое подключение к серверу Lumo." : (Net.mode == .proxy ? "Подключение через зеркало Lumo — прямой путь сейчас недоступен." : "Подключение через защищённый узел — прямой путь сейчас режется."))
        }
    }

    /// стопка аватаров с историями рядом с заголовком
    @ViewBuilder private var storyStack: some View {
        let groups = model.stories.sorted { a, b in
            if (a.userId == model.myId) != (b.userId == model.myId) { return a.userId == model.myId }
            return a.unseen && !b.unseen
        }
        if !groups.isEmpty {
            Button { storyStart = groups.first(where: { $0.userId != model.myId && $0.unseen })?.userId ?? groups[0].userId } label: {
                HStack(spacing: -12) {
                    if groups.count > 2 {
                        Text("\(groups.count)").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(LinearGradient(colors: [Color(hex: 0x6fb8ff), Theme.a1], startPoint: .top, endPoint: .bottom)))
                            .padding(2).overlay(Circle().strokeBorder(Color(hex: 0x34c759), lineWidth: 2))
                            .zIndex(3)
                    }
                    ForEach(Array(groups.prefix(2).enumerated()), id: \.offset) { i, g in
                        AvatarView(name: g.name, url: g.avatarURL, color: g.color, size: 30)
                            .padding(2)
                            .overlay(StoryRing(unseen: g.unseen, mine: g.userId == model.myId).scaleEffect(1.0))
                            .background(Circle().fill(Theme.bg))
                            .zIndex(Double(2 - i))
                    }
                }
            }
            .buttonStyle(BouncyButtonStyle())
        }
    }

    private var folders: some View {
        HStack(spacing: 2) {
            ForEach(ChatFolder.allCases, id: \.self) { f in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { folder = f }
                } label: {
                    HStack(spacing: 6) {
                        Text(f.title).font(.system(size: 15, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        let (n, loud) = count(f)
                        if n > 0 {
                            Text(n > 999 ? "999+" : "\(n)").font(.system(size: 11.5, weight: .bold)).foregroundColor(.white)
                                .padding(.horizontal, 6).frame(minWidth: 20, minHeight: 20)
                                .background(Capsule().fill(loud ? Theme.a1 : Color(hex: 0xa3a6b8)))
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 38)
                    .foregroundColor(Theme.text)
                    .background {
                        if folder == f { Capsule().fill(Theme.text.opacity(0.08)).matchedGeometryEffect(id: "fold", in: foldNS) }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .lumoGlass(Capsule())
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private var chatList: some View {
        ScrollView {
            GeometryReader { g in Color.clear.preference(key: ProfileScrollKey.self, value: g.frame(in: .named("clist")).minY) }.frame(height: 0)
            LazyVStack(spacing: 0) {
                if folder == .all { RemindersBar() }
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
                        SwipeChatRow(id: c.id, openId: $swipeOpen, leading: leadingSwipes(c), trailing: trailingSwipes(c)) {
                            chatLink(c).buttonStyle(RowButtonStyle())
                        }
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
                                    Button { Task { await model.clearChat(c.id) } } label: {
                                        Label("Очистить историю", systemImage: "eraser")
                                    }
                                }
                                Button(role: .destructive) { deleting = c } label: {
                                    Label(c.deleteTitle, systemImage: c.deleteIcon)
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
        .coordinateSpace(name: "clist")
        .onPull { y in
            // как в Telegram: потянуть вниз — раскрыть ленту историй, прокрутить вверх — свернуть
            if y < 10 { pulled = false }
            if y > 70, !storiesOpen, !pulled {
                pulled = true
                Task { await model.loadChats(); await model.loadStories() }
                UIImpactFeedbackGenerator(style: .light).impactOccurred(); storiesOpen = true
            } else if y < -24, storiesOpen { storiesOpen = false }
        }
        .chatDeletion($deleting)
    }

    /// свайп вправо: «Не прочитан» (крайняя, синяя) и «Закрепить» (зелёная)
    private func leadingSwipes(_ c: ChatItem) -> [SwipeAction] {
        let unread = c.unread > 0 || marks.has(c.id)
        return [
            SwipeAction(icon: unread ? "checkmark.message.fill" : "message.badge.filled.fill", title: unread ? "Прочитан" : "Не прочитан", color: Color(hex: 0x0A84FF)) {
                if c.unread > 0 { Task { await model.loadMessages(c.id); model.markRead(c.id) } }
                marks.set(c.id, !unread)
            },
            SwipeAction(icon: c.pinned ? "pin.slash.fill" : "pin.fill", title: c.pinned ? "Открепить" : "Закрепить", color: Color(hex: 0x34C759)) {
                Task { await model.setPinned(c.id, !c.pinned) }
            },
        ]
    }

    /// свайп влево: «Убрать звук» (оранжевая) и «Удалить» (крайняя, красная)
    private func trailingSwipes(_ c: ChatItem) -> [SwipeAction] {
        [
            SwipeAction(icon: c.muted ? "speaker.wave.2.fill" : "speaker.slash.fill", title: c.muted ? "Вкл. звук" : "Убрать звук", color: Color(hex: 0xFF9F0A)) {
                Task { await model.setMuted(c.id, !c.muted) }
            },
            SwipeAction(icon: "trash.fill", title: "Удалить", color: Color(hex: 0xFF3B30)) { deleting = c },
        ]
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
    @ObservedObject private var marks = UnreadMarks.shared
    let chat: ChatItem

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: chat.displayName, url: chat.displayAvatar, color: chat.displayColor, size: 54,
                       online: chat.isPrivate && chat.peerId != model.myId && model.isOnline(chat.peerId),
                       icon: chat.isPrivate && chat.peerId == model.myId ? "bookmark.fill" : nil,
                       storyUid: chat.isPrivate && chat.peerId != model.myId ? chat.peerId : nil)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if chat.isChannel { Image(systemName: "megaphone.fill").font(.caption).foregroundColor(Theme.muted) }
                    else if chat.type == "group" { Image(systemName: "person.2.fill").font(.caption).foregroundColor(Theme.muted) }
                    Text(chat.isPrivate && chat.peerId == model.myId ? "Избранное" : chat.displayName)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                    if chat.isPrivate && chat.peerId != model.myId { NameBadges(bot: chat.peerBot, premium: chat.peerPremium, emoji: chat.peerId.flatMap { model.profiles[$0]?.emojiStatus }, verified: chat.peerVerified || (chat.peerId.flatMap { model.profiles[$0]?.verified } ?? false)); StreakBadge(chatId: chat.id) }
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
                    } else if marks.has(chat.id) {
                        Circle().fill(chat.muted ? Color(hex: 0xa3a6c2) : Theme.a1).frame(width: 22, height: 22)
                    } else if chat.pinned {
                        Image(systemName: "pin.fill").font(.caption).foregroundColor(Theme.muted)
                    }
                }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            // тонкая полоска между чатами, от текста до края (как в Telegram)
            Rectangle().fill(Color(UIColor.separator).opacity(0.55)).frame(height: 0.5).padding(.leading, 76)
        }
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
                    Text(chat.preview(myId: model.myId)).font(.system(size: 14)).foregroundColor(Theme.muted).padding(.top, 30)
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
