import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

/// Строка ленты, посчитанная заранее (чтобы список не обращался к индексам, которые уже изменились)
struct FeedItem: Identifiable {
    let id: Int
    let message: Message
    let first: Bool
    let last: Bool
    let showDay: Bool
}

struct ChatView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var e2e = E2E.shared
    @EnvironmentObject var calls: CallManager
    @EnvironmentObject var look: Appearance
    @ObservedObject private var note = NoteRec.shared
    let chatId: String

    @State private var text = ""
    @State private var reply: Message?
    @State private var editing: Message?
    @State private var loadingOlder = false
    @State private var imageURL: IdentifiedURL?
    @State private var videoURL: IdentifiedURL?
    @State private var showInfo = false
    @State private var forwarding: ForwardBatch?
    @State private var selecting = false
    @State private var selected: Set<Int> = []
    @State private var reporting: ReportTarget?
    @State private var transcript: String?
    @ObservedObject private var prot = ProtStore.shared
    private var isProt: Bool { prot.map[chatId] == true }
    @State private var showSearch = false
    @State private var confirmClear = false
    @State private var confirmLeave = false
    @State private var highlight: Int?
    @State private var menuMsg: Message?
    @State private var deleteList: [Message] = []
    @State private var confirmDelete = false
    @State private var atBottom = true
    @State private var sendMenu = false
    @State private var showBubSheet = false
    @State private var showSchedule2 = false
    @State private var showScheduled2 = false
    @State private var scheduleText2 = ""
    @State private var fxPlay: String?
    @State private var fxSeen = 0
    @State private var newBelow = 0

    private var chat: ChatItem? { model.chat(chatId) }
    private var isBotChat: Bool { chat?.isPrivate == true && (chat?.peerBot == true || (chat?.peerId.flatMap { model.profiles[$0]?.isBot } ?? false)) }

    private func sendFromMenu(silent: Bool = false, fx: String? = nil) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var meta: JSON = [:]
        if silent { meta["silent"] = true }
        if let f = fx { meta["fx"] = f }
        text = ""
        let r = reply?.id
        reply = nil
        Task { await model.send(chatId: chatId, kind: "text", body: t, meta: meta, replyTo: r) }
    }

    private func checkFx() {
        guard let m = model.messages[chatId]?.last, m.id > 0, m.id != fxSeen, let f = m.meta["fx"] as? String, fxList.contains(f),
              Date().timeIntervalSince(m.createdAt) < 15 else { return }
        fxSeen = m.id
        fxPlay = f
    }

    /// Лента: новые сообщения первыми (список перевёрнут — открывается сразу на последнем сообщении)
    private var feed: [FeedItem] {
        let list = (model.messages[chatId] ?? []).filter { !$0.deleted }
        var out: [FeedItem] = []
        out.reserveCapacity(list.count)
        for i in stride(from: list.count - 1, through: 0, by: -1) {
            let m = list[i]
            let prev: Message? = i > 0 ? list[i - 1] : nil
            let next: Message? = i < list.count - 1 ? list[i + 1] : nil
            let newDay = prev == nil || !Calendar.current.isDate(prev!.createdAt, inSameDayAs: m.createdAt)
            let first = newDay || prev?.senderId != m.senderId || prev?.kind == "system" || m.createdAt.timeIntervalSince(prev!.createdAt) > 300
            var last = true
            if let n = next {
                let nextNewDay = !Calendar.current.isDate(n.createdAt, inSameDayAs: m.createdAt)
                last = nextNewDay || n.senderId != m.senderId || n.kind == "system" || n.createdAt.timeIntervalSince(m.createdAt) > 300
            }
            out.append(FeedItem(id: m.id, message: m, first: first, last: last, showDay: newDay))
        }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            if let pid = chat?.pinnedMessageId { pinnedBar(pid) }
            messagesList
        }
        .background(ChatWallpaper(index: look.wall).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if selecting { selectionBar } else {
                ComposerView(chatId: chatId, text: $text, reply: $reply, editing: $editing, blockedText: blockedText, onSendMenu: { sendMenu = true })
            }
        }
        .overlay {
            if note.active { VideoNoteOverlay() }
            else if let mm = menuMsg { menuOverlay(mm) }
        }
        .overlay {
            if sendMenu {
                SendMenuOverlay(text: text.trimmingCharacters(in: .whitespacesAndNewlines), onClose: { sendMenu = false },
                    onFx: { e in sendMenu = false; model.premium { sendFromMenu(fx: e) } },
                    onAction: { k in
                        sendMenu = false
                        if k == 0 { model.premium { sendFromMenu(silent: true) } }
                        else if k == 1 { model.premium { scheduleText2 = text.trimmingCharacters(in: .whitespacesAndNewlines); showSchedule2 = true } }
                        else { showScheduled2 = true }
                    },
                    onSend: { sendMenu = false; sendFromMenu() })
                    .environmentObject(model)
            }
        }
        .overlay { if let e = fxPlay { FxOverlayView(emoji: e) { fxPlay = nil } } }
        .sheet(isPresented: $showSchedule2) {
            ScheduleSheet(chatId: chatId, text: scheduleText2, replyTo: reply?.id) { text = ""; reply = nil }.environmentObject(model)
        }
        .sheet(isPresented: $showScheduled2) { ScheduledListSheet(chatId: chatId).environmentObject(model) }
        .sheet(isPresented: $showBubSheet) { BubbleColorSheet(chatId: chatId) }
        .onChange(of: model.messages[chatId]?.last?.id) { _ in checkFx() }
        .animation(.easeOut(duration: 0.18), value: note.active)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if selecting {
                    Text(selected.isEmpty ? "Выберите сообщения" : "Выбрано: \(selected.count)")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                } else {
                    Button { showInfo = true } label: { header }.buttonStyle(.plain)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if selecting { Button("Отмена") { endSelecting() } }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !selecting, !isBotChat, let c = chat, c.isPrivate, c.peerId != model.myId, model.peerBlockText(c.peerId) == nil {
                    Button { calls.startCall(chat: c, video: false) } label: { Image(systemName: "phone.fill") }
                    Button { calls.startCall(chat: c, video: true) } label: { Image(systemName: "video.fill") }
                }
                if !selecting { menu }
            }
        }
        .navigationBarBackButtonHidden(selecting)
        .lumoNavBar()
        .onAppear {
            model.openChatId = chatId
            Notifier.clear(chat: chatId)
            if model.demo == "profile" || model.demo == "qr" || model.demo == "contact" { showInfo = true }
            if model.demo == "select" { selecting = true; selected = [3, 5] }
            if model.demo == "menu" { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { menuMsg = (model.messages[chatId] ?? []).first { $0.id == 4 } } }
        }
        .onDisappear {
            if model.openChatId == chatId { model.openChatId = nil }
            AudioPlayer.shared.stop()
        }
        .task {
            if model.demo != nil { return }
            await model.loadMessages(chatId)
            model.markRead(chatId)
            if let p = chat?.peerId { await model.refreshProfile(p) }
        }
        .onChange(of: model.messages[chatId]?.last?.id) { _ in model.markRead(chatId) }
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "lumo", url.host == "user" {
                Task { await model.openByUsername(url.lastPathComponent) }
                return .handled
            }
            if url.scheme == "lumo", url.host == "cmd" {
                let cmd = "/" + url.lastPathComponent
                Task { _ = await model.send(chatId: chatId, kind: "text", body: cmd) }
                return .handled
            }
            return .systemAction
        })
        .fullScreenCover(item: $imageURL) { ImageScreen(url: $0.url) }
        .fullScreenCover(item: $videoURL) { VideoScreen(url: $0.url) }
        .navigationDestination(isPresented: $showInfo) {
            ChatInfoView(chatId: chatId, onSearch: {
                Task { try? await Task.sleep(nanoseconds: 450_000_000); showSearch = true }
            })
        }
        .sheet(item: $forwarding) { b in ForwardView(messages: b.messages).environmentObject(model) }
        .sheet(item: $reporting) { t in ReportView(target: t).environmentObject(model) }
        .task(id: chatId) { await prot.load(chatId) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            if isProt { model.say("В этом чате запрещены скриншоты") }
        }
        .overlay {
            if isProt && prot.captured {
                ZStack {
                    Theme.bg.ignoresSafeArea()
                    VStack(spacing: 10) {
                        Image(systemName: "shield.lefthalf.filled").font(.system(size: 40)).foregroundColor(Theme.a1)
                        Text("Содержимое защищённого чата скрыто, пока идёт запись экрана").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.text).multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                }
            }
        }
        .alert("Расшифровка", isPresented: Binding(get: { transcript != nil }, set: { if !$0 { transcript = nil } })) {
            Button("Копировать") { UIPasteboard.general.string = transcript; model.say("Скопировано") }
            Button("Закрыть", role: .cancel) {}
        } message: { Text(transcript ?? "") }
        .sheet(isPresented: $showSearch) {
            ChatSearchView(chatId: chatId) { id in highlight = id }.environmentObject(model)
        }
        .confirmationDialog(deleteList.count > 1 ? "Удалить \(deleteList.count) сообщ.?" : "Удалить сообщение?", isPresented: $confirmDelete, titleVisibility: .visible) {
            let l = deleteList
            if canDeleteForAll && chat?.isPrivate == true && chat?.peerId != model.myId {
                Button("Удалить у меня и у " + (chat?.displayName ?? "собеседника"), role: .destructive) { Task { await model.delete(l, everyone: true) } }
            } else if canDeleteForAll && chat?.peerId != model.myId {
                Button("Удалить у всех", role: .destructive) { Task { await model.delete(l, everyone: true) } }
            }
            Button(chat?.peerId == model.myId ? "Удалить" : "Удалить только у меня", role: .destructive) {
                Task { await model.delete(l, everyone: chat?.peerId == model.myId) }
            }
        }
        .confirmationDialog("Очистить историю этого чата? Сообщения пропадут только у вас.", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Очистить", role: .destructive) { Task { await model.clearChat(chatId) } }
        }
        .confirmationDialog("Покинуть «\(chat?.displayName ?? "")»?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Покинуть", role: .destructive) { Task { await model.leave(chatId) } }
        }
    }

    // MARK: - выбор нескольких сообщений

    private var selectedMessages: [Message] {
        (model.messages[chatId] ?? []).filter { selected.contains($0.id) }.sorted { $0.id < $1.id }
    }

    private func endSelecting() {
        withAnimation { selecting = false; selected = [] }
    }

    private func toggle(_ m: Message) {
        if selected.contains(m.id) { selected.remove(m.id) } else { selected.insert(m.id) }
    }

    private var canDeleteSelected: Bool {
        let list = selectedMessages
        return !list.isEmpty && (chat?.isAdmin == true || list.allSatisfy { $0.senderId == model.myId })
    }

    private var selectionBar: some View {
        let list = selectedMessages
        let texts = list.compactMap { $0.body }.filter { !$0.isEmpty }
        return HStack(spacing: 0) {
            selButton("trash", "Удалить", color: Theme.danger, enabled: !list.isEmpty) {
                let l = list
                endSelecting()
                askDelete(l)
            }
            selButton("doc.on.doc", "Копировать", enabled: !texts.isEmpty && !isProt) {
                UIPasteboard.general.string = texts.joined(separator: "\n\n")
                model.say(texts.count > 1 ? "Сообщения скопированы" : "Скопировано")
                endSelecting()
            }
            if list.count == 1, chat?.canPost ?? true {
                selButton("arrowshape.turn.up.left", "Ответить", enabled: true) {
                    reply = list.first
                    editing = nil
                    endSelecting()
                }
            }
            selButton("arrowshape.turn.up.right", "Переслать", enabled: !list.isEmpty && !isProt) {
                forwarding = ForwardBatch(messages: list)
                endSelecting()
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .lumoBarBackground()
    }

    private func selButton(_ icon: String, _ title: String, color: Color? = nil, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                Text(title).font(.system(size: 11.5, weight: .semibold))
            }
            .foregroundColor(enabled ? (color ?? Theme.a1) : Theme.muted.opacity(0.5))
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .disabled(!enabled)
    }

    // MARK: - меню сообщения (своё, вместо системного — системное переворачивало сообщение)

    private func closeMenu() { withAnimation(.easeOut(duration: 0.16)) { menuMsg = nil } }

    private func actions(_ m: Message) -> [MsgAction] {
        let mine = m.senderId == model.myId
        var a: [MsgAction] = []
        if chat?.canPost ?? true { a.append(MsgAction(title: "Ответить", icon: "arrowshape.turn.up.left") { reply = m; editing = nil }) }
        if let b = m.body, !b.isEmpty, !isProt {
            a.append(MsgAction(title: "Копировать", icon: "doc.on.doc") { UIPasteboard.general.string = b; model.say("Скопировано") })
        }
        if ["voice", "video_note"].contains(m.kind), let u = m.mediaURL {
            a.append(MsgAction(title: "Расшифровать", icon: "text.quote") {
                model.premium {
                    model.say("Расшифровываю…")
                    Task {
                        switch await Transcriber.run(urlString: u, ext: m.kind == "voice" ? "m4a" : "mp4") {
                        case .success(let t): transcript = t
                        case .failure(let e): model.say(e.localizedDescription)
                        }
                    }
                }
            })
        }
        if mine && ["text", "image", "video", "file"].contains(m.kind) {
            a.append(MsgAction(title: "Изменить", icon: "square.and.pencil") { editing = m; reply = nil; text = m.body ?? "" })
        }
        if chat?.isPrivate == true || chat?.isAdmin == true {
            let pinned = chat?.pinnedMessageId == m.id
            a.append(MsgAction(title: pinned ? "Открепить" : "Закрепить", icon: pinned ? "pin.slash" : "pin") {
                Task { await model.pin(pinned ? nil : m, in: m.chatId) }
            })
        }
        if !isProt { a.append(MsgAction(title: "Переслать", icon: "arrowshape.turn.up.right") { forwarding = ForwardBatch(messages: [m]) }) }
        if !mine {
            a.append(MsgAction(title: "Пожаловаться", icon: "exclamationmark.bubble") {
                reporting = ReportTarget(user: m.senderId, chat: chatId, message: m.id)
            })
        }
        a.append(MsgAction(title: "Удалить", icon: "trash", destructive: true) { askDelete([m]) })
        a.append(MsgAction(title: "Выбрать", icon: "checkmark.circle", separated: true) {
            withAnimation { selecting = true; selected = [m.id] }
        })
        return a
    }

    private func askDelete(_ list: [Message]) {
        deleteList = list.filter { $0.id > 0 }
        if !deleteList.isEmpty { confirmDelete = true }
    }

    /// Можно ли удалить у всех: свои сообщения или я админ группы/канала
    private var canDeleteForAll: Bool {
        chat?.isAdmin == true && chat?.isPrivate == false || deleteList.allSatisfy { $0.senderId == model.myId }
    }

    /// «сегодня в 23:32»
    private func whenText(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "HH:mm"
        if cal.isDateInToday(d) { return "сегодня в " + f.string(from: d) }
        if cal.isDateInYesterday(d) { return "вчера в " + f.string(from: d) }
        f.dateFormat = "d MMM в HH:mm"
        return f.string(from: d)
    }

    /// Шапка меню: галочки и время
    private func menuHeader(_ m: Message) -> some View {
        let mine = m.senderId == model.myId
        let read = (chat?.othersReadAt ?? .distantPast) >= m.createdAt
        return HStack(spacing: 14) {
            if mine && chat?.isChannel != true {
                ZStack(alignment: .leading) {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold))
                    if read { Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold)).offset(x: 6) }
                }
                .frame(width: 24, alignment: .leading)
            } else {
                Image(systemName: "clock").font(.system(size: 15)).frame(width: 24)
            }
            Text((m.editedAt != nil ? "изм. · " : "") + whenText(m.createdAt)).font(.system(size: 15))
            Spacer()
        }
        .foregroundColor(Theme.text.opacity(0.75))
        .padding(.horizontal, 18).frame(height: 46)
    }

    private func menuOverlay(_ m: Message) -> some View {
        let mine = m.senderId == model.myId
        let acts = actions(m)
        return ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                .overlay(Color.black.opacity(0.18).ignoresSafeArea())
                .onTapGesture { closeMenu() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: mine ? .trailing : .leading, spacing: 10) {
                    Spacer(minLength: 0)
                    // реакции
                    HStack(spacing: 2) {
                        ForEach(MessageRow.quick, id: \.self) { e in
                            Button {
                                closeMenu()
                                Task { await model.react(m, e) }
                            } label: {
                                Text(e).font(.system(size: 26)).frame(width: 38, height: 42)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                    .background(Capsule().fill(Theme.panel))
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
                    // само сообщение
                    MessageRow(m: m, chat: chat, first: true, last: true,
                               onReply: { _ in }, onEdit: { _ in }, onForward: { _ in },
                               onImage: { _ in }, onVideo: { _ in }, onReport: { _ in }, swipeEnabled: false)
                        .allowsHitTesting(false)
                        .frame(maxHeight: 360, alignment: .top)
                        .clipped()
                    // действия — как в Telegram: время сверху, значки слева, «Выбрать» отдельно снизу
                    VStack(spacing: 0) {
                        menuHeader(m)
                        Divider().overlay(Theme.line)
                        ForEach(Array(acts.enumerated()), id: \.offset) { i, a in
                            if a.separated { Divider().overlay(Theme.line).padding(.vertical, 4) }
                            Button {
                                closeMenu()
                                a.run()
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: a.icon).font(.system(size: 19)).frame(width: 26)
                                    Text(a.title).font(.system(size: 17))
                                    Spacer()
                                }
                                .foregroundColor(a.destructive ? Theme.danger : Theme.text)
                                .padding(.horizontal, 18).frame(height: 48)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                    .frame(width: 260)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(.regularMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [Theme.a2.opacity(0.10), Theme.a1.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.2), radius: 18, y: 6)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
                .frame(minHeight: UIScreen.main.bounds.height * 0.75, alignment: .center)
                // нажатие на пустое место (и на само сообщение) — закрыть меню
                .contentShape(Rectangle())
                .onTapGesture { closeMenu() }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - лента

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    Color.clear.frame(height: 6).id("bottom")
                        .onAppear { atBottom = true; newBelow = 0 }
                        .onDisappear { atBottom = false }
                    ForEach(feed) { f in
                        VStack(spacing: 2) {
                            if f.showDay { DayLabel(date: f.message.createdAt) }
                            MessageRow(m: f.message, chat: chat, first: f.first, last: f.last,
                                       onReply: { reply = $0; editing = nil },
                                       onEdit: { editing = $0; reply = nil; text = $0.body ?? "" },
                                       onForward: { forwarding = ForwardBatch(messages: [$0]) },
                                       onImage: { imageURL = IdentifiedURL(url: $0) },
                                       onVideo: { videoURL = IdentifiedURL(url: $0) },
                                       onReport: { m in reporting = ReportTarget(user: m.senderId, chat: chatId, message: m.id) },
                                       onMenu: { m in withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) { menuMsg = m } },
                                       selecting: selecting, isSelected: selected.contains(f.id), onToggle: { toggle($0) })
                                .background(RoundedRectangle(cornerRadius: 12).fill(highlight == f.id ? Theme.a1.opacity(0.25) : Color.clear))
                        }
                        .rotationEffect(.degrees(180))
                        .scaleEffect(x: -1, y: 1)
                        .id(f.id)
                    }
                    if model.hasMore[chatId] == true {
                        ProgressView()
                            .padding(12)
                            .onAppear { loadOlder() }
                    }
                }
                .padding(.horizontal, 8)
            }
            .rotationEffect(.degrees(180))
            .scaleEffect(x: -1, y: 1)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages[chatId]?.last?.id) { _ in
                if model.messages[chatId]?.last?.senderId == model.myId {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .top) }
                } else if !atBottom {
                    newBelow += 1
                }
            }
            // пролистали вверх — кнопка «вниз», к последним сообщениям
            .overlay(alignment: .bottomTrailing) {
                if !atBottom {
                    Button {
                        withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("bottom", anchor: .top) }
                        newBelow = 0
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.text)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Theme.panel))
                            .overlay(Circle().stroke(Theme.line))
                            .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                            .overlay(alignment: .top) {
                                if newBelow > 0 {
                                    Text(newBelow > 99 ? "99+" : String(newBelow))
                                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                        .padding(.horizontal, 6).frame(minWidth: 20, minHeight: 20)
                                        .background(Capsule().fill(Theme.accent))
                                        .offset(y: -10)
                                }
                            }
                    }
                    .padding(.trailing, 12).padding(.bottom, 10)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.18), value: atBottom)
            .onChange(of: highlight) { id in
                guard let id = id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
                Task { try? await Task.sleep(nanoseconds: 1_600_000_000); if highlight == id { highlight = nil } }
            }
        }
    }

    private func pinnedBar(_ pid: Int) -> some View {
        let pm = model.findMessage(pid, in: chatId)
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 3, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("Закреплённое сообщение").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.a2)
                Text(pm?.preview ?? "Сообщение").font(.system(size: 13.5)).foregroundColor(Theme.text).lineLimit(1)
            }
            Spacer()
            if chat?.isPrivate == true || chat?.isAdmin == true {
                Button { Task { await model.pin(nil, in: chatId) } } label: {
                    Image(systemName: "xmark").font(.footnote.weight(.bold)).foregroundColor(Theme.muted).frame(width: 30, height: 30)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(Theme.panel)
        .onTapGesture {
            if (model.messages[chatId] ?? []).contains(where: { $0.id == pid }) { highlight = pid }
            else { model.say(pm?.preview ?? "Сообщение") }
        }
    }

    private func loadOlder() {
        guard !loadingOlder else { return }
        loadingOlder = true
        Task {
            await model.loadMessages(chatId, older: true)
            loadingOlder = false
        }
    }

    // MARK: - шапка и меню

    private var header: some View {
        HStack(spacing: 9) {
            let saved = chat?.isPrivate == true && chat?.peerId == model.myId
            AvatarView(name: chat?.displayName ?? "", url: chat?.displayAvatar, color: chat?.displayColor ?? 0, size: 36,
                       online: chat?.isPrivate == true && !saved && model.isOnline(chat?.peerId),
                       icon: saved ? "bookmark.fill" : nil)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(saved ? "Избранное" : (chat?.displayName ?? "")).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                    if chat?.isPrivate == true { NameBadges(bot: chat?.peerBot == true || (chat?.peerId.flatMap { model.profiles[$0]?.isBot } ?? false), premium: chat?.peerPremium == true || (chat?.peerId.flatMap { model.profiles[$0]?.premium } ?? false), emoji: chat?.peerId.flatMap { model.profiles[$0]?.emojiStatus }, verified: chat?.peerVerified == true || (chat?.peerId.flatMap { model.profiles[$0]?.verified } ?? false)) }
                    if chat?.isPrivate == true && e2e.active(chatId) { Image(systemName: "lock.fill").font(.system(size: 11)).foregroundColor(Theme.a2) }
                }
                if let n = model.netStatus {
                    HStack(spacing: 5) {
                        ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                        Text(n).font(.system(size: 12.5)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                } else if let t = model.typingText(chatId) {
                    Text(t).font(.system(size: 12.5, weight: .semibold)).foregroundColor(Theme.a2).lineLimit(1)
                } else {
                    Text(status).font(.system(size: 12.5)).foregroundColor(model.isOnline(chat?.peerId) && chat?.isPrivate == true ? Theme.a2 : Theme.muted).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: 230, alignment: .leading)
    }

    private var status: String {
        guard let c = chat else { return "" }
        if c.isPrivate {
            if c.peerId == model.myId { return "заметки и сохранённое" }
            if let b = model.peerBlockText(c.peerId), model.profiles[c.peerId ?? ""]?.banned == true { return b.lowercased() }
            return c.peerBot ? "бот" : model.lastSeenText(c.peerId, fallback: c.peerLastSeen)
        }
        let n = c.membersCount
        return c.isChannel ? "\(n) " + plural(n, "подписчик", "подписчика", "подписчиков") : "\(n) " + plural(n, "участник", "участника", "участников")
    }

    private var menu: some View {
        Menu {
            Button { showSearch = true } label: { Label("Поиск по чату", systemImage: "magnifyingglass") }
            if let c = chat {
                Button { Task { await model.setMuted(c.id, !c.muted) } } label: {
                    Label(c.muted ? "Включить уведомления" : "Без звука", systemImage: c.muted ? "bell" : "bell.slash")
                }
                Button { Task { await model.setPinned(c.id, !c.pinned) } } label: {
                    Label(c.pinned ? "Открепить чат" : "Закрепить чат", systemImage: c.pinned ? "pin.slash" : "pin")
                }
                Button { model.premium { showBubSheet = true } } label: { Label("Цвет сообщений ★", systemImage: "paintpalette") }
                if !c.isChannel, c.isPrivate || c.isAdmin {
                    let on = prot.map[c.id] == true
                    Button {
                        if on { Task { await prot.set(c.id, false) } } else { model.premium { Task { await prot.set(c.id, true) } } }
                    } label: { Label(on ? "Разрешить пересылку и скриншоты" : "Запретить пересылку и скриншоты ★", systemImage: "shield.lefthalf.filled") }
                }
                Button { confirmClear = true } label: { Label("Очистить историю", systemImage: "eraser") }
                if c.isPrivate, let p = c.peerId, p != model.myId {
                    let blocked = model.blockedByMe.contains(p)
                    Button(role: blocked ? nil : .destructive) { Task { await model.setBlocked(p, !blocked) } } label: {
                        Label(blocked ? "Разблокировать" : "Заблокировать", systemImage: blocked ? "lock.open" : "hand.raised")
                    }
                    Button { reporting = ReportTarget(user: p, chat: c.id, message: nil) } label: {
                        Label("Пожаловаться", systemImage: "exclamationmark.bubble")
                    }
                }
                if !c.isPrivate {
                    Button { reporting = ReportTarget(user: nil, chat: c.id, message: nil) } label: {
                        Label("Пожаловаться", systemImage: "exclamationmark.bubble")
                    }
                    Button(role: .destructive) { confirmLeave = true } label: {
                        Label(c.isChannel ? "Отписаться" : "Покинуть группу", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        } label: { Image(systemName: "ellipsis.circle") }
    }

    private var blockedText: String? {
        guard let c = chat else { return nil }
        if c.isPrivate { return model.peerBlockText(c.peerId) }
        if !c.canPost { return "Писать в канал могут только администраторы" }
        return nil
    }
}

func plural(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
    let n10 = n % 10, n100 = n % 100
    if n100 >= 11 && n100 <= 14 { return many }
    if n10 == 1 { return one }
    if n10 >= 2 && n10 <= 4 { return few }
    return many
}

// MARK: - поле ввода

struct ComposerView: View {
    @EnvironmentObject var model: AppModel
    let chatId: String
    @Binding var text: String
    @Binding var reply: Message?
    @Binding var editing: Message?
    let blockedText: String?

    @StateObject private var rec = VoiceRecorder()
    @State private var picks: [PhotosPickerItem] = []
    @State private var showPhotos = false
    @State private var showFiles = false
    @State private var showCamera = false
    @State private var showStickers = false
    @State private var showSchedule = false
    @State private var showScheduled = false
    @State private var scheduleText = ""
    var onSendMenu: () -> Void = {}

    private var needStart: Bool {
        guard let c = model.chat(chatId), c.isPrivate else { return false }
        let bot = c.peerBot || (c.peerId.flatMap { model.profiles[$0]?.isBot } ?? false)
        return bot && !(model.messages[chatId] ?? []).contains { $0.senderId == model.myId }
    }
    @State private var videoMode = false
    @State private var dragX: CGFloat = 0
    @State private var holding = false
    @State private var voiceLocked = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let b = blockedText {
                Text(b).font(.subheadline.weight(.semibold)).foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity).padding(14)
                    .background(Theme.panel)
            } else if needStart {
                Button { Task { _ = await model.send(chatId: chatId, kind: "text", body: "/start") } } label: {
                    Text("НАЧАТЬ").font(.system(size: 16, weight: .heavy)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 48).background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(10)
            } else {
                if let r = reply ?? editing { context(r) }
                HStack(alignment: .bottom, spacing: 6) {
                    if rec.recording {
                        if voiceLocked {
                            Button { rec.cancel(); voiceLocked = false } label: {
                                Image(systemName: "trash").font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(Theme.danger).frame(width: 40, height: 44)
                            }
                        }
                        recordingBar
                    } else {
                        Menu {
                            Button { showPhotos = true } label: { Label("Фото или видео", systemImage: "photo.on.rectangle") }
                            Button { showCamera = true } label: { Label("Камера", systemImage: "camera") }
                            Button { showFiles = true } label: { Label("Файл", systemImage: "doc") }
                            Button { startNote(locked: true) } label: { Label("Видеосообщение", systemImage: "video.circle") }
                        } label: {
                            Image(systemName: "paperclip").font(.system(size: 21, weight: .semibold))
                                .foregroundColor(Theme.muted).frame(width: 40, height: 44)
                        }
                        HStack(alignment: .bottom, spacing: 4) {
                            TextField("Сообщение", text: $text, axis: .vertical)
                                .lineLimit(1...6)
                                .focused($focused)
                                .font(.system(size: 16))
                                .padding(.leading, 16).padding(.vertical, 11)
                                .onChange(of: text) { t in if !t.isEmpty { model.userTyping(chatId) } }
                            Button { showStickers.toggle(); if showStickers { focused = false } } label: {
                                Image(systemName: showStickers ? "keyboard" : "face.smiling")
                                    .font(.system(size: 20)).foregroundColor(Theme.muted)
                                    .frame(width: 40, height: 44)
                            }
                        }
                        .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 22))
                    }
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !rec.recording {
                        Image(systemName: editing != nil ? "checkmark" : "arrow.up")
                            .font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                            .frame(width: 44, height: 44).background(Circle().fill(Theme.accent))
                            .contentShape(Circle())
                            .onTapGesture { sendText() }
                            .onLongPressGesture(minimumDuration: 0.4) {
                                if editing == nil { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); onSendMenu() }
                            }
                    } else if rec.recording && voiceLocked {
                        Button { finishVoice() } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(Circle().fill(Theme.accent))
                        }
                    } else {
                        recordButton
                    }
                }
                .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 8)
                if showStickers && !rec.recording {
                    StickerPanel(onEmoji: { text += $0 }, onSticker: { s in
                        let r = reply?.id
                        reply = nil
                        Task { await model.send(chatId: chatId, kind: "sticker", body: s, replyTo: r) }
                    })
                    .frame(height: 260)
                }
            }
        }
        .lumoBarBackground()
        .onChange(of: focused) { f in if f { showStickers = false } }
        .sheet(isPresented: $showSchedule) {
            ScheduleSheet(chatId: chatId, text: scheduleText, replyTo: reply?.id) { text = ""; reply = nil }.environmentObject(model)
        }
        .sheet(isPresented: $showScheduled) { ScheduledListSheet(chatId: chatId).environmentObject(model) }
        // «записывает голосовое/видео…» у собеседника
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in reportActivity() }
        .onChange(of: rec.recording) { _ in reportActivity() }
        .photosPicker(isPresented: $showPhotos, selection: $picks, maxSelectionCount: 10, matching: .any(of: [.images, .videos]))
        .onChange(of: picks) { items in
            guard !items.isEmpty else { return }
            let chosen = items
            picks = []
            Task { await sendPicked(chosen) }
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.item], allowsMultipleSelection: false) { r in
            if case .success(let urls) = r, let u = urls.first { sendFile(u) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { img, video in
                if let i = img, let res = Media.jpeg(i) {
                    model.sendMedia(chatId: chatId, kind: "image", data: res.0, ext: "jpg", contentType: "image/jpeg", meta: ["w": res.1, "h": res.2])
                } else if let v = video, let d = try? Data(contentsOf: v) {
                    model.sendMedia(chatId: chatId, kind: "video", data: d, ext: v.pathExtension.isEmpty ? "mov" : v.pathExtension.lowercased(),
                                    contentType: "video/quicktime", meta: ["name": v.lastPathComponent, "size": d.count])
                }
            }
            .ignoresSafeArea()
        }
    }

    private func context(_ m: Message) -> some View {
        HStack(spacing: 10) {
            Image(systemName: editing != nil ? "pencil" : "arrowshape.turn.up.left.fill").foregroundColor(Theme.a2)
            VStack(alignment: .leading, spacing: 1) {
                Text(editing != nil ? "Редактирование" : "Ответ: " + model.displayName(m.senderId))
                    .font(.caption.weight(.bold)).foregroundColor(Theme.a2)
                Text(m.preview).font(.caption).foregroundColor(Theme.muted).lineLimit(1)
            }
            Spacer()
            Button {
                if editing != nil { text = "" }
                reply = nil
                editing = nil
            } label: { Image(systemName: "xmark").foregroundColor(Theme.muted).frame(width: 30, height: 30) }
        }
        .padding(.horizontal, 14).padding(.top, 8)
    }

    @State private var actSent = ""
    private func reportActivity() {
        let act = rec.recording ? "voice" : (NoteRec.shared.active ? "video" : "")
        if !act.isEmpty { model.userTyping(chatId, act: act); actSent = act }
        else if !actSent.isEmpty { model.userTyping(chatId, act: "stop"); actSent = "" }
    }

    private var recordingBar: some View {
        HStack(spacing: 10) {
            Circle().fill(Theme.danger).frame(width: 10, height: 10)
                .opacity(Int(rec.elapsed * 2) % 2 == 0 ? 1 : 0.3)
            Text(Fmt.duration(rec.elapsed)).font(.body.monospacedDigit())
            Spacer()
            if voiceLocked {
                Text("Запись без удержания").font(.subheadline).foregroundColor(Theme.muted)
            } else {
                HStack(spacing: 6) {
                    Text(dragX < -60 ? "Отпустите для отмены" : "‹ Влево — отмена")
                    if dragX > -60 { Image(systemName: "lock").font(.caption) }
                }
                .font(.subheadline).foregroundColor(dragX < -60 ? Theme.danger : Theme.muted)
                .offset(x: max(-80, min(0, dragX)))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 22))
    }

    /// Нажатие — переключить голосовое/кружок; удержание — сразу запись (вверх — без удержания, влево — отмена)
    private var recordButton: some View {
        Image(systemName: videoMode ? "video.fill" : "mic.fill")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(width: rec.recording ? 54 : 44, height: rec.recording ? 54 : 44)
            .background(Circle().fill(rec.recording ? AnyShapeStyle(Theme.danger) : AnyShapeStyle(Theme.accent)))
            .scaleEffect(rec.recording ? 1 + CGFloat(rec.level) * 0.25 : 1)
            .animation(.easeOut(duration: 0.1), value: rec.level)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        dragX = v.translation.width
                        let note = NoteRec.shared
                        if note.active && !note.locked {
                            note.dragX = v.translation.width
                            if v.translation.height < -80 { note.lock() }
                        }
                        if rec.recording && !voiceLocked && v.translation.height < -80 {
                            voiceLocked = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        guard !holding else { return }
                        holding = true
                        Task {
                            try? await Task.sleep(nanoseconds: 180_000_000)
                            guard holding else { return }
                            if videoMode { startNote(locked: false); return }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            voiceLocked = false
                            let ok = await rec.start()
                            if !ok { model.say("Нет доступа к микрофону — разрешите его в Настройках iPhone") }
                            if !holding && !voiceLocked { rec.cancel() }
                        }
                    }
                    .onEnded { v in
                        holding = false
                        let cancel = v.translation.width < -60
                        dragX = 0
                        let note = NoteRec.shared
                        if note.active {
                            if note.locked { return }
                            if v.translation.width < -80 { note.cancel() } else { note.finish() }
                            return
                        }
                        if !rec.recording {
                            if abs(v.translation.width) < 10 && abs(v.translation.height) < 10 {
                                withAnimation { videoMode.toggle() }
                                model.say(videoMode ? "Удерживайте, чтобы записать кружок" : "Удерживайте, чтобы записать голосовое")
                            }
                            return
                        }
                        if voiceLocked { return }
                        if cancel { rec.cancel(); return }
                        finishVoice()
                    }
            )
    }

    private func startNote(locked: Bool) {
        focused = false
        showStickers = false
        let r = reply?.id
        reply = nil
        Task { await NoteRec.shared.begin(chatId: chatId, replyTo: r, locked: locked) }
    }

    private func finishVoice() {
        voiceLocked = false
        guard let res = rec.stop() else { return }
        if res.1 < 0.7 { return }
        sendVoice(res.0, res.1, res.2)
    }

    private func sendText(silent: Bool = false) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        text = ""
        if let e = editing {
            editing = nil
            if t != e.body { Task { await model.edit(e, text: t) } }
            return
        }
        let r = reply?.id
        reply = nil
        Task { await model.send(chatId: chatId, kind: "text", body: t, meta: silent ? ["silent": true] : [:], replyTo: r) }
    }

    private func sendVoice(_ url: URL, _ dur: Double, _ wave: [Int]) {
        guard let data = try? Data(contentsOf: url) else { return }
        let r = reply?.id
        reply = nil
        model.sendMedia(chatId: chatId, kind: "voice", data: data, ext: "m4a", contentType: "audio/mp4",
                        meta: ["dur": max(1, Int(dur.rounded())), "wave": wave], replyTo: r, local: url)
    }

    private func sendFile(_ url: URL) {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        guard let d = try? Data(contentsOf: url) else { model.say("Не удалось открыть файл"); return }
        if d.count > 50 * 1024 * 1024 { model.say("Файл больше 50 МБ"); return }
        let ext = url.pathExtension.isEmpty ? "bin" : url.pathExtension.lowercased()
        let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
        model.sendMedia(chatId: chatId, kind: "file", data: d, ext: ext, contentType: mime,
                        meta: ["name": url.lastPathComponent, "size": d.count])
    }

    private func sendPicked(_ items: [PhotosPickerItem]) async {
        let caption = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var captionUsed = false
        for item in items {
            let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                model.say("Не удалось открыть файл")
                continue
            }
            if data.count > 50 * 1024 * 1024 { model.say("Файл больше 50 МБ"); continue }
            let body: String? = (!captionUsed && !caption.isEmpty) ? caption : nil
            if body != nil { captionUsed = true; text = "" }
            let r = reply?.id
            reply = nil
            if isVideo {
                let type = item.supportedContentTypes.first { $0.conforms(to: .movie) }
                let ext = type?.preferredFilenameExtension ?? "mov"
                let mime = type?.preferredMIMEType ?? "video/quicktime"
                model.sendMedia(chatId: chatId, kind: "video", data: data, ext: ext, contentType: mime,
                                meta: ["name": "video." + ext, "size": data.count], body: body, replyTo: r)
            } else if let img = UIImage(data: data), let res = Media.jpeg(img) {
                model.sendMedia(chatId: chatId, kind: "image", data: res.0, ext: "jpg", contentType: "image/jpeg",
                                meta: ["w": res.1, "h": res.2], body: body, replyTo: r)
            }
        }
    }
}

/// Эмодзи (вставляются в текст) и стикеры (большие эмодзи отдельным сообщением), как на сайте
struct StickerPanel: View {
    let onEmoji: (String) -> Void
    let onSticker: (String) -> Void
    @State private var tab = 0

    static let emoji = Array("😀😃😄😁😆😅😂🤣😊😇🙂😉😍🥰😘😋😛😜🤪🤗🤔🤨😐😏😒🙄😬😌😔😴😷🤒🤧🥵🥶😎🤓🧐😕😟😮😲😳🥺😢😭😱😖😣😞😓😩😫🥱😤😡😠🤬😈💀💩🤡👻👽🤖😺😹😻🙈🙉🙊💋💌💘💝💖💗💓💞💕❣️💔❤️🧡💛💚💙💜🤎🖤🤍💯💥💫💦💨🕳💬👋🤚🖐✋🖖👌🤌🤏✌️🤞🤟🤘🤙👈👉👆👇☝️👍👎✊👊🤛🤜👏🙌👐🤲🤝🙏💪🎉🎊🎁🔥⭐️🌟✨⚡️☀️🌙🌈❄️🍀🌹🌸🍕🍔🍟🍩🍰🎂☕️🍺🍷⚽️🏀🎮🎧🎵🚀✈️🚗🏠💡📱💻📷⏰✅❌❓❗️").map(String.init)
    static let stickers = ["😂", "😍", "🥰", "😎", "🤔", "😭", "😡", "🥳", "😴", "🤯", "👍", "👏", "🙏", "💪", "🔥", "❤️", "💔", "🎉", "💯", "👋", "🐶", "🐱", "🦊", "🐼", "🐸", "🦄", "🌈", "⭐️", "🍕", "☕️"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                tabButton("Эмодзи", 0)
                tabButton("Стикеры", 1)
            }
            .padding(6)
            ScrollView {
                if tab == 0 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 6) {
                        ForEach(Array(Self.emoji.enumerated()), id: \.offset) { _, e in
                            Button { onEmoji(e) } label: { Text(e).font(.system(size: 28)) }
                        }
                    }
                    .padding(8)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(Self.stickers, id: \.self) { e in
                            Button { onSticker(e) } label: { Text(e).font(.system(size: 50)) }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(Theme.panel)
    }

    private func tabButton(_ t: String, _ i: Int) -> some View {
        Button { tab = i } label: {
            Text(t).font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 16).padding(.vertical, 7)
                .foregroundColor(tab == i ? .white : Theme.muted)
                .background(Capsule().fill(tab == i ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel2)))
        }
        .buttonStyle(.plain)
    }
}

/// Системная камера: снять фото или видео
struct CameraPicker: UIViewControllerRepresentable {
    let done: (UIImage?, URL?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) { p.sourceType = .camera }
        p.mediaTypes = ["public.image", "public.movie"]
        p.videoMaximumDuration = 300
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let img = info[.originalImage] as? UIImage
            let url = info[.mediaURL] as? URL
            parent.done(img, url)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

/// Пункт меню сообщения
struct MsgAction {
    let title: String
    let icon: String
    var destructive = false
    var separated = false
    let run: () -> Void
}

/// Сообщения для пересылки (одно или несколько)
struct ForwardBatch: Identifiable {
    let id = UUID()
    let messages: [Message]
}
