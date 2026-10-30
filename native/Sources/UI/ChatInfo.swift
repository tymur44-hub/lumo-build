import SwiftUI
import PhotosUI

struct ReportTarget: Identifiable {
    let id = UUID()
    let user: String?
    let chat: String?
    let message: Int?
}

/// Карточка чата: профиль собеседника или группа/канал с участниками
struct ChatInfoView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var calls: CallManager
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    var onSearch: () -> Void = {}

    @State private var members: [Member] = []
    @State private var peerPhone: String?
    @State private var aliasEdit = false
    @State private var lumenTarget: LumenTarget?
    @State private var giftTarget: GiftTarget?
    @State private var alias = ""
    @State private var report: ReportTarget?
    @State private var addMembers = false
    @State private var showRequests = false
    @State private var inviteLink: String?
    @State private var editChat = false
    @State private var confirmLeave = false
    @State private var confirmClear = false
    @State private var deleting: ChatItem?
    @State private var avatarPick: PhotosPickerItem?
    @State private var avatarFull: IdentifiedURL?
    @State private var showQR = false
    @State private var showBub = false
    @State private var showWall = false
    @ObservedObject private var prot = ProtStore.shared
    @EnvironmentObject var look: Appearance

    private var chat: ChatItem? { model.chat(chatId) }
    private var peer: Profile? { chat?.peerId.flatMap { model.profiles[$0] } }
    private var saved: Bool { chat?.isPrivate == true && chat?.peerId == model.myId }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                actions
                if let c = chat {
                    if c.isPrivate { privateSections(c) } else { groupSections(c) }
                    PremiumChatRows(chat: c)
                    // медиа, файлы, голосовые и ссылки из этого чата
                    SharedMediaSection(chatId: c.id)
                }
                Color.clear.frame(height: 20)
            }
            .padding(.top, 4)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let c = chat, canEdit(c) {
                    Button("Изм.") {
                        if c.isPrivate { aliasEdit = true }
                        else { editChat = true }
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .task {
            if model.demo == "qr" { try? await Task.sleep(nanoseconds: 800_000_000); showQR = true }
            if model.demo == "contact" { try? await Task.sleep(nanoseconds: 1_200_000_000); aliasEdit = true }
            if model.demo != nil { return }
            if let c = chat, !c.isPrivate { members = await model.members(c.id) }
            if let p = chat?.peerId { await model.refreshProfile(p) }
        }
        .sheet(isPresented: $aliasEdit) {
            if let pid = chat?.peerId { ContactEditView(peerId: pid).environmentObject(model) }
        }
        .sheet(item: $report) { t in ReportView(target: t).environmentObject(model) }
        .sheet(isPresented: $showBub) { BubbleColorSheet(chatId: chatId) }
        .sheet(isPresented: $showWall) {
            ChatWallSheet(chatId: chatId, peerName: chat?.peerName, isPrivate: chat?.isPrivate == true).environmentObject(model).environmentObject(look)
        }
        .sheet(item: $lumenTarget) { t in SendLumensSheet(userId: t.id).environmentObject(model) }
        .sheet(item: $giftTarget) { t in GiftShopSheet(user: t.id).environmentObject(model) }
        .task(id: chat?.peerId) { await loadPeerPhone(chat?.peerId) }
        .sheet(isPresented: $showRequests) { JoinRequestsSheet(chatId: chatId).environmentObject(model) }
        .sheet(isPresented: $addMembers) {
            PeoplePicker(title: "Добавить участников", exclude: Set(members.map { $0.userId })) { ids in
                Task { await model.addMembers(chatId, ids); members = await model.members(chatId) }
            }
            .environmentObject(model)
        }
        .fullScreenCover(isPresented: $editChat) { EditChatView(chatId: chatId).environmentObject(model) }
        .fullScreenCover(item: $avatarFull) { ImageScreen(url: $0.url) }
        .sheet(isPresented: $showQR) {
            if let c = chat {
                UserQRSheet(name: c.displayName, username: c.peerUsername ?? "", avatar: c.displayAvatar, color: c.displayColor)
                    .environmentObject(model)
            }
        }
        .chatDeletion($deleting, onDone: { dismiss() })
        .confirmationDialog("Очистить историю? Сообщения пропадут только у вас.", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Очистить", role: .destructive) { Task { await model.clearChat(chatId) } }
        }
        .onChange(of: avatarPick) { item in
            guard let item = item else { return }
            avatarPick = nil
            Task {
                if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) { await model.setChatAvatar(chatId, img) }
            }
        }
    }

    private func canEdit(_ c: ChatItem) -> Bool {
        c.isPrivate ? (c.peerId != nil && !saved) : c.isAdmin
    }

    // MARK: шапка: большая аватарка (нажатие — на весь экран), имя, статус

    private var hero: some View {
        let c = chat
        let avatar = c?.displayAvatar.flatMap(URL.init(string:))
        return VStack(spacing: 8) {
            Button {
                if let u = avatar { avatarFull = IdentifiedURL(url: u) }
            } label: {
                AvatarView(name: c?.displayName ?? "", url: c?.displayAvatar, color: c?.displayColor ?? 0, size: 120,
                           icon: saved ? "bookmark.fill" : nil, storyUid: (c?.isPrivate == true && !saved) ? c?.peerId : nil)
            }
            .buttonStyle(BouncyButtonStyle())
            .padding(.bottom, 6)
            HStack(spacing: 6) {
                Text(saved ? "Избранное" : (c?.displayName ?? ""))
                    .font(.system(size: 28, weight: .bold)).foregroundColor(Theme.text)
                    .multilineTextAlignment(.center)
                if peer?.verified == true { Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.a2) }
            }
            if let c = c {
                if c.isPrivate, !saved {
                    let online = model.isOnline(c.peerId)
                    if let t = model.typingText(c.id) {
                        Text(t).font(.system(size: 16)).foregroundColor(Theme.a2)
                    } else {
                        Text(c.peerBot ? "бот" : model.lastSeenText(c.peerId, fallback: c.peerLastSeen))
                            .font(.system(size: 16)).foregroundColor(online ? Theme.a2 : Theme.muted)
                    }
                    if peer?.banned == true {
                        Text(model.peerBlockText(c.peerId) ?? "").font(.subheadline.weight(.bold)).foregroundColor(Theme.danger)
                            .multilineTextAlignment(.center).padding(.horizontal, 20)
                    }
                } else if !c.isPrivate {
                    Text((c.isChannel ? "канал · " : "группа · ") + "\(c.membersCount) " + (c.isChannel ? plural(c.membersCount, "подписчик", "подписчика", "подписчиков") : plural(c.membersCount, "участник", "участника", "участников")))
                        .font(.system(size: 16)).foregroundColor(Theme.muted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: кнопки: звонок, видео, звук, поиск, ещё

    private var actions: some View {
        HStack(spacing: 8) {
            if let c = chat {
                if c.isPrivate, !saved, !(c.peerBot || (c.peerId.flatMap { model.profiles[$0]?.isBot } ?? false)), model.peerBlockText(c.peerId) == nil {
                    actionButton("phone.fill", "звонок") { calls.startCall(chat: c, video: false) }
                    actionButton("video.fill", "видео") { calls.startCall(chat: c, video: true) }
                }
                if !saved {
                    actionButton(c.muted ? "bell.slash.fill" : "bell.fill", c.muted ? "без звука" : "звук") {
                        Task { await model.setMuted(c.id, !c.muted) }
                    }
                }
                actionButton("magnifyingglass", "поиск") { dismiss(); onSearch() }
                Menu { moreMenu(c) } label: { actionLabel("ellipsis", "ещё") }
            }
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder private func moreMenu(_ c: ChatItem) -> some View {
        if c.isPrivate, !saved, let pid = c.peerId, pid != model.myId, !(c.peerBot || (model.profiles[pid]?.isBot ?? false)) {
            Button { lumenTarget = LumenTarget(id: pid) } label: { Label("Отправить люмены", systemImage: "sparkle") }
            Button { giftTarget = GiftTarget(id: pid) } label: { Label("Подарить подарок", systemImage: "gift") }
        }
        if c.isPrivate, let p = c.peerId, p != model.myId {
            Button {
                Task { if model.isContact(p) { await model.removeContact(p) } else { await model.addContact(p) } }
            } label: {
                Label(model.isContact(p) ? "Удалить из контактов" : "Добавить в контакты",
                      systemImage: model.isContact(p) ? "person.badge.minus" : "person.badge.plus")
            }
        }
        if let u = c.isPrivate ? c.peerUsername : c.username, !u.isEmpty {
            Button {
                UIPasteboard.general.string = "@" + u
                model.say("Юзернейм скопирован")
            } label: { Label("Скопировать @" + u, systemImage: "doc.on.doc") }
        }
        Button { Task { await model.setPinned(c.id, !c.pinned) } } label: {
            Label(c.pinned ? "Открепить чат" : "Закрепить чат", systemImage: c.pinned ? "pin.slash" : "pin")
        }
        Button { model.premium { showBub = true } } label: { Label("Цвет сообщений ★", systemImage: "paintpalette") }
        if !c.isChannel {
            Button { model.premium { showWall = true } } label: { Label("Изменить обои ★", systemImage: "photo.artframe") }
        }
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
            Button(role: .destructive) { report = ReportTarget(user: p, chat: c.id, message: nil) } label: {
                Label("Пожаловаться", systemImage: "exclamationmark.bubble")
            }
        }
        if !c.isPrivate {
            Button { report = ReportTarget(user: nil, chat: c.id, message: nil) } label: { Label("Пожаловаться", systemImage: "exclamationmark.bubble") }
        }
        Button(role: .destructive) { deleting = c } label: { Label(c.deleteTitle, systemImage: c.deleteIcon) }
    }

    private func actionLabel(_ icon: String, _ title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 21, weight: .semibold)).frame(height: 24)
            Text(title).font(.system(size: 12.5, weight: .medium))
        }
        .foregroundColor(Theme.a1)
        .frame(maxWidth: .infinity, minHeight: 66)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
    }

    private func actionButton(_ icon: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { actionLabel(icon, title) }.buttonStyle(BouncyButtonStyle())
    }

    private func infoRow(_ title: String, _ value: String, accent: Bool = false, trailing: String? = nil, tap: (() -> Void)? = nil) -> some View {
        Button { tap?() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14)).foregroundColor(Theme.text)
                    Text(value).font(.system(size: 17)).foregroundColor(accent ? Theme.a1 : Theme.text)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if let t = trailing { Image(systemName: t).font(.system(size: 22)).foregroundColor(Theme.a1) }
            }
            .padding(.vertical, 10).padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(tap == nil)
    }

    @ViewBuilder private func privateSections(_ c: ChatItem) -> some View {
        if !saved {
            SettingsGroup {
                if let ph = peerPhone {
                    infoRow("мобильный", PhoneStore.pretty(ph), accent: true) {
                        UIPasteboard.general.string = "+" + ph
                        model.say("Номер скопирован")
                    }
                    Divider().overlay(Theme.line)
                }
                if let u = c.peerUsername, !u.isEmpty {
                    HStack(spacing: 0) {
                        infoRow("имя пользователя", "@" + u, accent: true) {
                            UIPasteboard.general.string = "@" + u
                            model.say("Юзернейм скопирован")
                        }
                        Button { showQR = true } label: {
                            Image(systemName: "qrcode").font(.system(size: 26, weight: .medium)).foregroundColor(Theme.a1)
                                .frame(width: 48, height: 48).contentShape(Rectangle())
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                if let a = model.aliases[c.peerId ?? ""], !a.isEmpty, let real = peer?.name, real != a {
                    Divider().overlay(Theme.line)
                    infoRow("имя в профиле", real)
                }
                if let bio = peer?.bio, !bio.isEmpty {
                    Divider().overlay(Theme.line)
                    infoRow("о себе", bio)
                }
                if let b = Birthday.text(peer?.birthday, age: true) {
                    Divider().overlay(Theme.line)
                    infoRow("день рождения", b)
                }
            }
            if let p = peer, p.premium, !p.isBot { ProfileLinksView(userId: p.id) }
            if let p = peer { ProfileChannelCard(p: p) }
        }
    }

    private func loadPeerPhone(_ id: String?) async {
        guard let id = id, id != model.myId else { return }
        peerPhone = (try? await API.shared.rpc("lm_phone_of", ["p_user": id])) as? String
    }

    @ViewBuilder private func groupSections(_ c: ChatItem) -> some View {
        if let d = c.description, !d.isEmpty {
            SettingsGroup {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Описание").font(.caption.weight(.bold)).foregroundColor(Theme.muted)
                    Text(d).foregroundColor(Theme.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8).padding(.horizontal, 4)
            }
        }
        if let u = c.username, !u.isEmpty {
            SettingsGroup {
                Button {
                    UIPasteboard.general.string = "@" + u
                    model.say("Ссылка скопирована")
                } label: { SettingsRow(icon: "link", color: Theme.a2, title: "@" + u, subtitle: "Нажмите, чтобы скопировать", chevron: false) }
            }
        }
        if c.isAdmin {
            SettingsGroup {
                Button { editChat = true } label: { SettingsRow(icon: "pencil", color: Theme.a1, title: "Изменить название и описание") }
                Divider().overlay(Theme.line)
                PhotosPicker(selection: $avatarPick, matching: .images) {
                    SettingsRow(icon: "photo", color: Color(hex: 0x22a6ff), title: "Сменить фото")
                }
                Divider().overlay(Theme.line)
                Button { addMembers = true } label: {
                    SettingsRow(icon: "person.badge.plus", color: Color(hex: 0x2bd67b), title: c.isChannel ? "Добавить подписчиков" : "Добавить участников")
                }
                Divider().overlay(Theme.line)
                Button {
                    Task {
                        if let code = await model.inviteCode(c.id) {
                            let l = "https://volshebny-mir.ru/page322172009.html#+" + code
                            UIPasteboard.general.string = l
                            model.say("Ссылка-приглашение скопирована")
                        }
                    }
                } label: { SettingsRow(icon: "link.badge.plus", color: Color(hex: 0x3a7bff), title: "Ссылка-приглашение", subtitle: "Нажмите, чтобы скопировать", chevron: false) }
                Divider().overlay(Theme.line)
                Button { showRequests = true } label: { SettingsRow(icon: "person.crop.circle.badge.questionmark", color: Color(hex: 0xff8a3d), title: "Заявки на вступление") }
            }
        }
        if !c.isChannel || c.isAdmin {
            SectionTitle(text: (c.isChannel ? "Подписчики" : "Участники") + " · \(members.count)")
            SettingsGroup {
                ForEach(members) { m in
                    HStack(spacing: 12) {
                        AvatarView(name: model.displayName(m.userId), url: model.profiles[m.userId]?.avatarURL,
                                   color: model.profiles[m.userId]?.color ?? 0, size: 42, online: model.isOnline(m.userId))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(m.userId == model.myId ? "Вы" : model.displayName(m.userId)).font(.system(size: 15.5, weight: .bold))
                            Text(model.lastSeenText(m.userId)).font(.caption).foregroundColor(model.isOnline(m.userId) ? Theme.a2 : Theme.muted)
                        }
                        Spacer()
                        if m.role == "owner" || m.role == "admin" {
                            Text(m.role == "owner" ? "владелец" : "админ").font(.caption.weight(.bold)).foregroundColor(Theme.a1)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .contextMenu {
                        if m.userId != model.myId {
                            Button { dismiss(); Task { await model.openDM(m.userId) } } label: { Label("Написать", systemImage: "bubble.left") }
                            if c.role == "owner" && m.role != "owner" {
                                Button { Task { await model.setRole(c.id, m.userId, m.role == "admin" ? "member" : "admin"); members = await model.members(c.id) } } label: {
                                    Label(m.role == "admin" ? "Снять админа" : "Сделать админом", systemImage: "star")
                                }
                            }
                            if c.isAdmin && m.role != "owner" {
                                Button(role: .destructive) { Task { await model.removeMember(c.id, m.userId); members = await model.members(c.id) } } label: {
                                    Label("Исключить", systemImage: "person.badge.minus")
                                }
                            }
                        }
                    }
                }
            }
        }
        SettingsGroup {
            Button { report = ReportTarget(user: nil, chat: c.id, message: nil) } label: {
                SettingsRow(icon: "exclamationmark.bubble.fill", color: Color(hex: 0xff8a3d), title: "Пожаловаться", chevron: false)
            }
            Divider().overlay(Theme.line)
            Button { confirmClear = true } label: {
                SettingsRow(icon: "eraser", color: Color(hex: 0x8e8ea8), title: "Очистить историю", chevron: false)
            }
            Divider().overlay(Theme.line)
            Button { deleting = c } label: {
                SettingsRow(icon: c.deleteIcon, color: Theme.danger,
                            title: c.deleteTitle, titleColor: Theme.danger, chevron: false)
            }
        }
    }
}

struct EditChatView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String

    private enum Page { case main, type, admins, members, reactions, discussion }
    @State private var page: Page = .main
    @State private var title = ""
    @State private var about = ""
    @State private var isPublic = false
    @State private var uname = ""
    @State private var members: [Member] = []
    @State private var avatarPick: PhotosPickerItem?
    @State private var busy = false
    @State private var error: String?
    @ObservedObject private var lumens = Lumens.shared
    @State private var rxOn = true
    @State private var rxSet = Set(allReactions)
    @State private var rxTouched = false

    private var chat: ChatItem? { model.chat(chatId) }
    private var isChannel: Bool { chat?.isChannel == true }
    private var kind: String { isChannel ? "канала" : "группы" }
    private var owner: Bool { chat?.role == "owner" }
    private var link: String { "https://volshebny-mir.ru/page322172009.html#@" + uname }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { back() } label: {
                    Image(systemName: page == .main ? "xmark" : "chevron.left").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                if page != .main {
                    Text(pageTitle).font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                }
                Spacer()
                Button { save() } label: {
                    Group {
                        if busy { ProgressView().tint(.white) } else { Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).foregroundColor(.white) }
                    }
                    .frame(width: 44, height: 44).background(Circle().fill(Theme.accent))
                }
            }
            .padding(.horizontal, 14).padding(.top, 8)
            ScrollView {
                VStack(spacing: 0) {
                    switch page {
                    case .main: main
                    case .type: typePage
                    case .reactions: reactionsPage
                    case .discussion: discussionPage
                    case .admins: list(admins: true)
                    case .members: list(admins: false)
                    }
                }
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            title = chat?.title ?? ""; about = chat?.description ?? ""
            uname = chat?.username ?? ""; isPublic = !(chat?.username ?? "").isEmpty
            Task { members = await model.members(chatId) }
            let r = lumens.cfg[chatId]?.reactions
            rxOn = r?.isEmpty != true; rxSet = Set(r ?? allReactions)
        }
        .onChange(of: avatarPick) { item in
            guard let item = item else { return }
            avatarPick = nil
            Task { if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) { await model.setChatAvatar(chatId, img) } }
        }
    }

    private var pageTitle: String {
        switch page { case .type: return "Тип " + kind; case .admins: return "Администраторы"; case .reactions: return "Реакции"; case .discussion: return "Обсуждение"; default: return isChannel ? "Подписчики" : "Участники" }
    }

    private func back() { if page != .main { page = .main; error = nil } else { dismiss() } }

    private func save() {
        guard !busy else { return }
        let u = uname.trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: "@", with: "")
        if title.trimmingCharacters(in: .whitespaces).isEmpty { error = "Введите название"; return }
        if isPublic, u.range(of: "^[a-z0-9_]{5,32}$", options: .regularExpression) == nil { page = .type; error = "Адрес: 5–32 символа, латиница, цифры и _"; return }
        busy = true; error = nil
        Task {
            if isChannel && rxTouched {
                let list: [String]? = !rxOn ? [] : (rxSet.isSuperset(of: allReactions) ? nil : allReactions.filter { rxSet.contains($0) })
                if let e = await lumens.setReactions(chatId, list) { model.say(e) }
            }
            let ok = await model.saveChatFull(chatId, title: title.trimmingCharacters(in: .whitespaces), description: about.trimmingCharacters(in: .whitespaces),
                                              isPublic: isPublic, username: isPublic ? u : nil)
            busy = false
            if ok { dismiss() } else { page = .type; error = "Этот адрес уже занят или недоступен" }
        }
    }

    @ViewBuilder private var main: some View {
        VStack(spacing: 10) {
            AvatarView(name: chat?.displayName ?? "", url: chat?.displayAvatar, color: chat?.displayColor ?? 0, size: 110)
            PhotosPicker(selection: $avatarPick, matching: .images) {
                Text("Изменить фотографию").font(.system(size: 18)).foregroundColor(Theme.a1)
            }
        }
        .padding(.vertical, 12)
        TGCard {
            TextField("Название", text: $title).font(.system(size: 17)).padding(.horizontal, 20).frame(height: 56)
            Divider().overlay(Theme.line).padding(.leading, 20)
            TextField("Описание", text: $about, axis: .vertical).lineLimit(2...8).font(.system(size: 17)).padding(.horizontal, 20).padding(.vertical, 16)
        }
        TGHint(text: "Любые подробности о \(isChannel ? "канале" : "группе"): чем он занимается, ссылки, правила.")
        if let e = error { Text(e).font(.subheadline).foregroundColor(Theme.danger).padding(.horizontal, 30).padding(.bottom, 8) }
        TGCard {
            Button { page = .type } label: { TGIconRow(icon: isChannel ? "megaphone.fill" : "person.3.fill", color: Color(hex: 0x2b8cff), title: "Тип " + kind, value: isPublic ? "Публичный" : "Частный") }
                .buttonStyle(RowButtonStyle())
            if isPublic && !uname.isEmpty {
                Divider().overlay(Theme.line).padding(.leading, 68)
                Button { page = .type } label: { TGIconRow(icon: "link", color: Color(hex: 0xffa33a), title: "Ссылка", value: "@" + uname) }.buttonStyle(RowButtonStyle())
            }
        }
        if isChannel {
            TGCard {
                Button { page = .discussion } label: {
                    TGIconRow(icon: "bubble.left.and.bubble.right.fill", color: Color(hex: 0x5b6cff), title: "Обсуждение",
                              value: lumens.linked(chatId).flatMap { model.chat($0)?.title } ?? (lumens.linked(chatId) != nil ? "Группа" : "Добавить"))
                }.buttonStyle(RowButtonStyle())
                Divider().overlay(Theme.line).padding(.leading, 68)
                Button { page = .reactions } label: {
                    TGIconRow(icon: "heart.fill", color: Color(hex: 0xff4d6a), title: "Реакции", value: !rxOn ? "Выключены" : (rxSet.isSuperset(of: allReactions) ? "Все" : "\(rxSet.count)"))
                }.buttonStyle(RowButtonStyle())
            }
            .padding(.top, 14)
        }
        TGCard {
            Button { page = .admins } label: { TGIconRow(icon: "checkmark.shield.fill", color: Color(hex: 0x2bd67b), title: "Администраторы", value: "\(members.filter { $0.role != "member" }.count)") }
                .buttonStyle(RowButtonStyle())
            Divider().overlay(Theme.line).padding(.leading, 68)
            Button { page = .members } label: { TGIconRow(icon: "person.2.fill", color: Color(hex: 0x2b8cff), title: isChannel ? "Подписчики" : "Участники", value: "\(members.count)") }
                .buttonStyle(RowButtonStyle())
        }
        .padding(.top, 14)
    }

    @ViewBuilder private var typePage: some View {
        TGCard {
            Button { isPublic = false } label: { typeRow("Частный", "Попасть можно только по приглашению", !isPublic) }.buttonStyle(RowButtonStyle())
            Divider().overlay(Theme.line).padding(.leading, 20)
            Button { isPublic = true } label: { typeRow("Публичный", "Можно найти через поиск по адресу", isPublic) }.buttonStyle(RowButtonStyle())
        }
        .padding(.top, 8)
        if isPublic {
            Text("АДРЕС").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 6)
            TGCard {
                TextField("username", text: Binding(get: { uname }, set: { v in
                    uname = String(v.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }.prefix(32)); error = nil
                })).textInputAutocapitalization(.never).autocorrectionDisabled().font(.system(size: 17)).padding(.horizontal, 20).frame(height: 56)
            }
            TGHint(text: "Можно использовать a–z, 0–9 и _. Минимум 5 символов. Ссылка: " + (uname.isEmpty ? "..." : link))
            if uname.count >= 5 {
                Button("Скопировать ссылку") { UIPasteboard.general.string = link; model.say("Ссылка скопирована") }
                    .font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32)
            }
        }
        if let e = error { Text(e).font(.subheadline).foregroundColor(Theme.danger).padding(.horizontal, 30).padding(.top, 10) }
    }

    private func typeRow(_ t: String, _ s: String, _ on: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(t).font(.system(size: 17)).foregroundColor(Theme.text)
                Text(s).font(.system(size: 13)).foregroundColor(Theme.muted)
            }
            Spacer()
            if on { Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.a1) }
        }
        .padding(.horizontal, 20).frame(minHeight: 60).contentShape(Rectangle())
    }

    @ViewBuilder private var reactionsPage: some View {
        TGCard {
            Toggle("Реакции на посты", isOn: Binding(get: { rxOn }, set: { rxOn = $0; rxTouched = true }))
                .font(.system(size: 17)).padding(.horizontal, 20).frame(minHeight: 56)
        }
        .padding(.top, 8)
        if rxOn {
            Text("РАЗРЕШЁННЫЕ РЕАКЦИИ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32).padding(.top, 16).padding(.bottom, 6)
            TGCard {
                ForEach(Array(allReactions.enumerated()), id: \.element) { i, e in
                    if i > 0 { Divider().overlay(Theme.line).padding(.leading, 20) }
                    Button {
                        if rxSet.contains(e) { rxSet.remove(e) } else { rxSet.insert(e) }
                        rxTouched = true
                    } label: {
                        HStack {
                            Text(e).font(.system(size: 26))
                            Spacer()
                            Image(systemName: rxSet.contains(e) ? "checkmark.circle.fill" : "circle").font(.system(size: 22))
                                .foregroundColor(rxSet.contains(e) ? Theme.a1 : Theme.muted)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 8).contentShape(Rectangle())
                    }.buttonStyle(BouncyButtonStyle())
                }
            }
            TGHint(text: "Подписчики смогут ставить только отмеченные реакции. Если не отмечено ничего, реакции будут выключены.")
        } else {
            TGHint(text: "Подписчики не смогут ставить реакции на посты.")
        }
    }

    @ViewBuilder private var discussionPage: some View {
        let lid = lumens.linked(chatId)
        if let lid {
            TGCard {
                TGIconRow(icon: "person.3.fill", color: Color(hex: 0x5b6cff), title: model.chat(lid)?.title ?? "Группа", value: "Привязана", chevron: false)
                Divider().overlay(Theme.line).padding(.leading, 68)
                Button { Task { if let e = await lumens.link(chatId, nil) { model.say(e) } else { model.say("Группа отвязана") } } } label: {
                    Text("Отвязать группу").font(.system(size: 17)).foregroundColor(Theme.danger).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20).frame(height: 56).contentShape(Rectangle())
                }.buttonStyle(RowButtonStyle())
            }
            .padding(.top, 8)
            TGHint(text: "Под каждым постом канала появится кнопка «Комментарии». Комментарии хранятся в этой группе.")
        } else {
            let used = Set(lumens.cfg.values.compactMap { $0.linked })
            let cand = model.chats.filter { $0.type == "group" && $0.role == "owner" && !used.contains($0.id) }
            TGCard {
                Button {
                    Task {
                        if let gid = await lumens.createDiscussion(title: "Обсуждение: " + (title.isEmpty ? (chat?.displayName ?? "") : title)) {
                            await model.loadChats()
                            if let e = await lumens.link(chatId, gid) { model.say(e) } else { model.say("Обсуждение подключено") }
                        }
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "plus").foregroundColor(Theme.a1)
                        Text("Создать новую группу").font(.system(size: 17)).foregroundColor(Theme.a1)
                        Spacer()
                    }.padding(.horizontal, 20).frame(height: 56).contentShape(Rectangle())
                }.buttonStyle(RowButtonStyle())
                ForEach(cand) { g in
                    Divider().overlay(Theme.line).padding(.leading, 20)
                    Button {
                        Task { if let e = await lumens.link(chatId, g.id) { model.say(e) } else { model.say("Обсуждение подключено") } }
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: g.displayName, url: g.displayAvatar, color: g.displayColor, size: 38)
                            Text(g.displayName).font(.system(size: 17)).foregroundColor(Theme.text)
                            Spacer()
                        }.padding(.horizontal, 20).padding(.vertical, 10).contentShape(Rectangle())
                    }.buttonStyle(BouncyButtonStyle())
                }
            }
            .padding(.top, 8)
            TGHint(text: "Чтобы включить комментарии, создайте группу и привяжите её к каналу, либо выберите свою группу. Привязать можно только группу, где вы владелец.")
        }
    }

    @ViewBuilder private func list(admins: Bool) -> some View {
        let rows = admins ? members.filter { $0.role != "member" } : members
        TGCard {
            ForEach(Array(rows.enumerated()), id: \.element.userId) { i, m in
                if i > 0 { Divider().overlay(Theme.line).padding(.leading, 70) }
                Menu {
                    if m.userId != model.myId {
                        if owner && m.role != "owner" {
                            Button(m.role == "admin" ? "Снять админа" : "Сделать админом") {
                                Task { await model.setRole(chatId, m.userId, m.role == "admin" ? "member" : "admin"); members = await model.members(chatId) }
                            }
                        }
                        if m.role != "owner" && (owner || m.role != "admin") {
                            Button("Исключить", role: .destructive) { Task { await model.removeMember(chatId, m.userId); members = await model.members(chatId) } }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(name: model.displayName(m.userId), url: model.profiles[m.userId]?.avatarURL, color: model.profiles[m.userId]?.color ?? 0, size: 42)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.displayName(m.userId)).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                            Text(model.lastSeenText(m.userId)).font(.system(size: 13)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        if m.role != "member" { Text(m.role == "owner" ? "владелец" : "админ").font(.system(size: 13)).foregroundColor(Theme.a1) }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
                }
            }
        }
        .padding(.top, 8)
        if admins { TGHint(text: owner ? "Нажмите на участника на вкладке «\(isChannel ? "Подписчики" : "Участники")», чтобы сделать его админом." : "Назначать администраторов может только владелец.") }
    }
}

/// Жалоба: причина и комментарий (её увидит только администрация Lumo)
struct ReportView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let target: ReportTarget
    @State private var reason: ReportReason = .spam
    @State private var comment = ""
    @State private var alsoBlock = false
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Причина", selection: $reason) {
                        ForEach(ReportReason.allCases) { r in Text(r.title).tag(r) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: { Text("Жалобу увидит только администрация Lumo. Укажите причину:") }
                Section("Комментарий (необязательно)") {
                    TextField("Что случилось?", text: $comment, axis: .vertical).lineLimit(2...5)
                }
                if let u = target.user, !model.blockedByMe.contains(u) {
                    Toggle("Также заблокировать пользователя", isOn: $alsoBlock)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(target.message != nil ? "Жалоба на сообщение" : "Пожаловаться")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Отправить") {
                        busy = true
                        Task {
                            let ok = await model.report(user: target.user, chat: target.chat, message: target.message, reason: reason, comment: comment)
                            if ok, alsoBlock, let u = target.user { await model.setBlocked(u, true) }
                            busy = false
                            if ok { dismiss() }
                        }
                    }
                    .disabled(busy)
                }
            }
        }
    }
}

/// Выбор чата для пересылки
struct ForwardView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let messages: [Message]
    @State private var q = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                SearchField(placeholder: "Кому переслать?", text: $q).padding(.horizontal, 14)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.chats.filter { $0.canPost && (q.isEmpty || $0.displayName.lowercased().contains(q.lowercased())) }) { c in
                            Button {
                                dismiss()
                                let list = messages
                                Task {
                                    for m in list { await model.forward(m, to: c.id, quiet: true) }
                                    model.say(list.count > 1 ? "Сообщения пересланы" : "Сообщение переслано")
                                }
                            } label: { ChatRow(chat: c) }
                            .buttonStyle(RowButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.top, 8)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Переслать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
    }
}

/// Поиск по сообщениям чата
struct ChatSearchView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    let jump: (Int) -> Void
    @State private var q = ""
    @State private var results: [Message] = []
    @State private var busy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                SearchField(placeholder: "Поиск по сообщениям", text: $q).padding(.horizontal, 14)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if busy { ProgressView().frame(maxWidth: .infinity).padding(20) }
                        else if !q.isEmpty && results.isEmpty { Text("Ничего не найдено").foregroundColor(Theme.muted).frame(maxWidth: .infinity).padding(20) }
                        ForEach(results) { m in
                            Button {
                                dismiss()
                                jump(m.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(model.displayName(m.senderId)).font(.subheadline.weight(.bold)).foregroundColor(Theme.a2)
                                        Spacer()
                                        Text(Fmt.time(m.createdAt)).font(.caption).foregroundColor(Theme.muted)
                                    }
                                    Text(m.body ?? "").foregroundColor(Theme.text).lineLimit(3)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                    }
                }
            }
            .padding(.top, 8)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Поиск по чату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
            .onChange(of: q) { t in
                let s = t.trimmingCharacters(in: .whitespaces)
                guard s.count >= 2 else { results = []; return }
                busy = true
                Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard s == q.trimmingCharacters(in: .whitespaces) else { return }
                    results = await model.searchMessages(chatId, s)
                    busy = false
                }
            }
        }
    }
}

/// Выбор людей (контакты + глобальный поиск)
struct PeoplePicker: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let title: String
    var exclude: Set<String> = []
    var buttonTitle = "Добавить"
    let done: ([String]) -> Void

    @State private var q = ""
    @State private var picked: [String] = []
    @State private var found: [SearchResult] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                SearchField(placeholder: "Имя или @юзернейм", text: $q).padding(.horizontal, 14)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        let list = (q.isEmpty ? model.contacts : found.filter { $0.kind == "user" }.map { $0.id })
                            .filter { !exclude.contains($0) && $0 != model.myId }
                        if list.isEmpty {
                            Text(q.isEmpty ? "Контактов пока нет — найдите людей через поиск" : "Никого не найдено")
                                .foregroundColor(Theme.muted).frame(maxWidth: .infinity).padding(24)
                        }
                        ForEach(list, id: \.self) { id in
                            Button {
                                if let i = picked.firstIndex(of: id) { picked.remove(at: i) } else { picked.append(id) }
                            } label: {
                                HStack(spacing: 12) {
                                    let r = found.first { $0.id == id }
                                    AvatarView(name: model.profiles[id]?.name ?? r?.name ?? "", url: model.profiles[id]?.avatarURL ?? r?.avatarURL,
                                               color: model.profiles[id]?.color ?? r?.color ?? 0, size: 44, online: model.isOnline(id))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(model.profiles[id] != nil ? model.displayName(id) : (r?.name ?? "")).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                        Text("@" + (model.profiles[id]?.username ?? r?.username ?? "")).font(.caption).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                    Image(systemName: picked.contains(id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3).foregroundColor(picked.contains(id) ? Theme.a1 : Theme.muted)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                    }
                }
            }
            .padding(.top, 8)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonTitle + (picked.isEmpty ? "" : " (\(picked.count))")) { done(picked); dismiss() }.disabled(picked.isEmpty)
                }
            }
            .onChange(of: q) { t in
                let s = t.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
                guard !s.isEmpty else { found = []; return }
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard s == q.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "") else { return }
                    found = await model.search(s)
                }
            }
        }
    }
}

/// Новый чат: группа, канал или сообщение человеку. Канал и группа создаются мастером из нескольких экранов (как в Telegram)
struct NewChatView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    enum Step { case menu, intro, details, type, members }

    @State private var step: Step = .menu
    @State private var mode = "group"
    @State private var title = ""
    @State private var about = ""
    @State private var isPublic = false
    @State private var username = ""
    @State private var invite = NewChatView.makeCode()
    @State private var requests = false
    @State private var noCopy = false
    @State private var members: [String] = []
    @State private var pickMembers = false
    @State private var busy = false
    @State private var avatarPick: PhotosPickerItem?
    @State private var avatar: UIImage?
    @FocusState private var titleFocus: Bool

    static func makeCode() -> String { String((0..<16).map { _ in "abcdef0123456789".randomElement()! }) }

    private var isChannel: Bool { mode == "channel" }
    private var noun: String { isChannel ? "канал" : "группу" }
    private var nounOf: String { isChannel ? "канала" : "группы" }
    private var cleanName: String { username.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespaces) }
    private var link: String { "https://volshebny-mir.ru/page322172009.html#+" + invite }
    private var linkShown: String { "volshebny-mir.ru/…#+" + invite }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch step {
            case .menu: menu.transition(.opacity)
            case .intro: intro.transition(.move(edge: .trailing))
            case .details: details.transition(.move(edge: .trailing))
            case .type: typeScreen.transition(.move(edge: .trailing))
            case .members: membersScreen.transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .sheet(isPresented: $pickMembers) {
            PeoplePicker(title: isChannel ? "Подписчики" : "Участники", buttonTitle: "Готово") { members = $0 }.environmentObject(model)
        }
        .onChange(of: avatarPick) { item in
            guard let item = item else { return }
            Task {
                if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) { avatar = img }
                avatarPick = nil
            }
        }
    }

    // MARK: шапка мастера

    private func header(_ title: String, next: String? = nil, nextEnabled: Bool = true, back: @escaping () -> Void, onNext: @escaping () -> Void = {}) -> some View {
        ZStack {
            Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
            HStack {
                Button(action: back) {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text)
                        .frame(width: 46, height: 46).lumoGlass(Circle(), interactive: true)
                }
                Spacer()
                if let n = next {
                    Button(action: onNext) {
                        Text(n).font(.system(size: 17, weight: .semibold))
                            .foregroundColor(nextEnabled ? Theme.a1 : Theme.muted)
                            .padding(.horizontal, 18).frame(height: 46).lumoGlass(Capsule(), interactive: true)
                    }
                    .disabled(!nextEnabled)
                }
            }
        }
        .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)
    }

    // MARK: 0. выбор

    private var menu: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Новый чат").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
            }
            .frame(maxWidth: .infinity).overlay(alignment: .leading) {
                Button("Закрыть") { dismiss() }.foregroundColor(Theme.a1)
            }
            .padding(.horizontal, 16).padding(.vertical, 16)
            ScrollView {
                VStack(spacing: 12) {
                    SettingsGroup {
                        Button { mode = "group"; step = .details } label: { SettingsRow(icon: "person.2.fill", color: Color(hex: 0x2bd67b), title: "Новая группа", subtitle: "Общение с несколькими людьми") }
                        Divider().overlay(Theme.line)
                        Button { mode = "channel"; step = .intro } label: { SettingsRow(icon: "megaphone.fill", color: Color(hex: 0xff8a3d), title: "Новый канал", subtitle: "Публикации для подписчиков") }
                        Divider().overlay(Theme.line)
                        Button { dismiss(); Task { await model.openBotFather() } } label: { SettingsRow(icon: "cpu", color: Color(hex: 0x7c5cff), title: "Создать бота", subtitle: "Конструктор ботов и мини-приложений") }
                        Divider().overlay(Theme.line)
                        Button { Task { await model.openSaved(); dismiss() } } label: { SettingsRow(icon: "bookmark.fill", color: Color(hex: 0x3a7bff), title: "Избранное", subtitle: "Заметки для себя") }
                    }
                    SectionTitle(text: "Контакты")
                    SettingsGroup {
                        if model.contacts.isEmpty {
                            Text("Контактов пока нет — найдите людей через поиск на вкладке «Чаты»")
                                .font(.subheadline).foregroundColor(Theme.muted).padding(12)
                        }
                        ForEach(model.contacts, id: \.self) { id in
                            Button { dismiss(); Task { await model.openDM(id) } } label: {
                                HStack(spacing: 12) {
                                    AvatarView(name: model.displayName(id), url: model.profiles[id]?.avatarURL, color: model.profiles[id]?.color ?? 0, size: 42, online: model.isOnline(id))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(model.displayName(id)).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                        Text(model.lastSeenText(id)).font(.caption).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: 1. «Что такое канал?»

    private var intro: some View {
        VStack(spacing: 0) {
            HStack {
                Button { step = .menu } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text)
                        .frame(width: 46, height: 46).lumoGlass(Circle(), interactive: true)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12)
            Spacer()
            ChannelIntroArt().frame(height: 250)
            Spacer()
            Text("Что такое канал?").font(.system(size: 28, weight: .bold)).foregroundColor(Theme.text)
            Text("Каналы — инструмент, который позволяет транслировать сообщения на большую аудиторию.")
                .font(.system(size: 19)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                .padding(.horizontal, 30).padding(.top, 14)
            Spacer()
            GradientButton(title: "Создать канал") { step = .details }
                .padding(.horizontal, 18).padding(.bottom, 26)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    // MARK: 2. название, фото, описание

    private var details: some View {
        VStack(spacing: 0) {
            header("Создать " + noun, next: "Далее", nextEnabled: !title.trimmingCharacters(in: .whitespaces).isEmpty,
                   back: { step = isChannel ? .intro : .menu }, onNext: { titleFocus = false; step = .type })
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $avatarPick, matching: .images) {
                            ZStack {
                                Circle().fill(Theme.a1.opacity(0.12))
                                if let a = avatar {
                                    Image(uiImage: a).resizable().scaledToFill().clipShape(Circle())
                                } else {
                                    Image(systemName: "camera.fill").font(.system(size: 26)).foregroundColor(Theme.a1)
                                }
                            }
                            .frame(width: 76, height: 76)
                        }
                        TextField(isChannel ? "Название канала" : "Название группы", text: $title)
                            .font(.system(size: 20)).focused($titleFocus)
                    }
                    .padding(18)
                    .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 28))

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Описание", text: $about, axis: .vertical).lineLimit(1...5)
                            .font(.system(size: 19))
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 26))
                        Text("Можете указать дополнительное описание " + nounOf + ".")
                            .font(.system(size: 15)).foregroundColor(Theme.muted).padding(.horizontal, 10)
                    }
                }
                .padding(.horizontal, 14).padding(.top, 12)
            }
        }
        .onAppear { titleFocus = true }
    }

    // MARK: 3. тип, ссылка, заявки, копирование

    private var typeScreen: some View {
        VStack(spacing: 0) {
            header("Тип " + nounOf, next: "Далее", nextEnabled: !isPublic || cleanName.count >= 5,
                   back: { step = .details }, onNext: { step = .members })
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    SectionTitle(text: "Ссылка")
                    card {
                        typeRow("Публичная", on: isPublic) { withAnimation { isPublic = true } }
                        Divider().overlay(Theme.line).padding(.leading, 56)
                        typeRow("Частная", on: !isPublic) { withAnimation { isPublic = false } }
                    }
                    footnote(isPublic ? "Публичные \(isChannel ? "каналы" : "группы") можно найти через поиск, вступить в них может любой пользователь."
                                      : "На частные \(isChannel ? "каналы" : "группы") можно вступить только по ссылке-приглашению.")

                    if isPublic {
                        HStack(spacing: 0) {
                            Text("@").font(.system(size: 19)).foregroundColor(Theme.text)
                            TextField("ссылка", text: $username)
                                .font(.system(size: 19))
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                        }
                        .padding(.horizontal, 18).frame(height: 56)
                        .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 28))
                        .padding(.horizontal, 14).padding(.top, 14)
                        footnote("Если у \(nounOf) будет постоянная публичная ссылка, другие пользователи смогут найти \(isChannel ? "его" : "её") и вступить.")
                        footnote("Можно использовать латиницу (a-z), цифры (0-9) и подчёркивание. Минимальная длина — 5 символов.")
                    } else {
                        SectionTitle(text: "Ссылка-приглашение").padding(.top, 14)
                        card {
                            VStack(spacing: 10) {
                                HStack {
                                    Text(linkShown).font(.system(size: 18)).foregroundColor(Theme.text).lineLimit(1).truncationMode(.middle)
                                        .frame(maxWidth: .infinity)
                                    Menu {
                                        Button { UIPasteboard.general.string = link; model.say("Ссылка скопирована") } label: { Label("Копировать", systemImage: "doc.on.doc") }
                                        Button { invite = NewChatView.makeCode() } label: { Label("Создать новую", systemImage: "arrow.triangle.2.circlepath") }
                                    } label: {
                                        Image(systemName: "ellipsis").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                            .frame(width: 34, height: 34).background(Circle().fill(Theme.muted.opacity(0.7)))
                                    }
                                }
                                .padding(.horizontal, 14).frame(height: 52)
                                .background(Theme.bg, in: Capsule())
                                ShareLink(item: link) {
                                    Text("Поделиться").font(.headline).foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 52).background(Theme.accent, in: Capsule())
                                }
                            }
                            .padding(10)
                        }
                        footnote("По этой ссылке можно вступить в \(isChannel ? "канал" : "группу"). Вы можете сбросить её в любой момент.")
                        card {
                            Toggle("Заявки на вступление", isOn: $requests).tint(Theme.a1)
                                .font(.system(size: 18)).padding(.horizontal, 18).padding(.vertical, 12)
                        }
                        .padding(.top, 14)
                        footnote("Новые участники смогут вступить в \(isChannel ? "канал" : "группу") только после одобрения заявки администратором.")
                    }

                    SectionTitle(text: "Сохранение и копирование материалов").padding(.top, 14)
                    card {
                        Toggle("Запретить копирование", isOn: $noCopy).tint(Theme.a1)
                            .font(.system(size: 18)).padding(.horizontal, 18).padding(.vertical, 12)
                    }
                    footnote(isChannel ? "Подписчики смогут копировать, сохранять или пересылать материалы из канала." : "Участники смогут копировать, сохранять или пересылать материалы из группы.")
                    Color.clear.frame(height: 30)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func card<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        VStack(spacing: 0) { c() }
            .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 26))
            .padding(.horizontal, 14)
    }

    private func footnote(_ t: String) -> some View {
        Text(t).font(.system(size: 14.5)).foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 28).padding(.top, 4)
    }

    private func typeRow(_ t: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.a1)
                    .opacity(on ? 1 : 0).frame(width: 28)
                Text(t).font(.system(size: 19)).foregroundColor(Theme.text)
                Spacer()
            }
            .padding(.horizontal, 18).frame(height: 58).contentShape(Rectangle())
        }
    }

    // MARK: 4. участники и создание

    private var membersScreen: some View {
        VStack(spacing: 0) {
            header(isChannel ? "Подписчики" : "Участники", back: { step = .type })
            VStack(spacing: 14) {
                Button { pickMembers = true } label: {
                    SettingsRow(icon: "person.badge.plus", color: Color(hex: 0x2bd67b),
                                title: members.isEmpty ? (isChannel ? "Добавить подписчиков" : "Добавить участников") : "Выбрано: \(members.count)")
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 26))
                footnote("Это необязательно — людей можно позвать позже по ссылке или из списка контактов.")
                Spacer()
                GradientButton(title: isChannel ? "Создать канал" : "Создать группу", loading: busy) { create() }
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 14).padding(.top, 12)
        }
    }

    private func create() {
        busy = true
        Task {
            let id = await model.createChat(type: mode, title: title.trimmingCharacters(in: .whitespaces), description: about, members: members,
                                            username: isPublic ? cleanName : nil, protected: noCopy, requests: isPublic ? false : requests,
                                            invite: invite, avatar: avatar)
            busy = false
            if id != nil { dismiss() }
        }
    }
}

/// Иллюстрация «Что такое канал?»: телефон, шапка канала и просмотры
struct ChannelIntroArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30).fill(Color(hex: 0xb9d8f6)).frame(width: 150, height: 230)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color(hex: 0x3b4a5c), lineWidth: 5))
                .overlay(alignment: .top) { Capsule().fill(Color(hex: 0x3b4a5c)).frame(width: 52, height: 9).padding(.top, 6) }
            Text("🦆").font(.system(size: 86)).offset(y: 34)
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9)).frame(width: 96, height: 34).offset(x: -4, y: -36)
            VStack(spacing: 2) {
                Text("Канал").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: 0x1d2733))
                Text("57k подписчиков").font(.system(size: 11)).foregroundColor(Color(hex: 0x5b6b7d))
            }
            .frame(width: 98, height: 98).background(Circle().fill(Color(hex: 0xcfe4f8)).overlay(Circle().stroke(Color.white, lineWidth: 3)))
            .offset(x: -82, y: -78)
            VStack(spacing: 2) {
                Text("просмотры").font(.system(size: 12)).foregroundColor(Color(hex: 0x5b6b7d))
                HStack(spacing: 4) { Image(systemName: "eye.fill"); Text("1K").font(.system(size: 16)) }.foregroundColor(Color(hex: 0x5b6b7d))
            }
            .frame(width: 96, height: 96).background(Circle().fill(Color(hex: 0xcfe4f8)).overlay(Circle().stroke(Color.white, lineWidth: 3)))
            .offset(x: 82, y: 6)
        }
    }
}

// MARK: - Медиа, файлы, голосовые и ссылки чата (под профилем, как в Telegram)

struct SharedMediaSection: View {
    @EnvironmentObject var model: AppModel
    let chatId: String

    enum Tab: String, CaseIterable { case media = "Медиа", files = "Файлы", voice = "Голосовые", links = "Ссылки" }

    @State private var tab: Tab = .media
    @State private var media: [Message] = []
    @State private var files: [Message] = []
    @State private var voices: [Message] = []
    @State private var links: [(id: Int, url: URL, date: Date)] = []
    @State private var loaded = false
    @State private var image: IdentifiedURL?
    @State private var video: IdentifiedURL?

    private var available: [Tab] {
        Tab.allCases.filter { t in
            switch t {
            case .media: return !media.isEmpty
            case .files: return !files.isEmpty
            case .voice: return !voices.isEmpty
            case .links: return !links.isEmpty
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            if !loaded {
                ProgressView().padding(20)
            } else if available.isEmpty {
                Text("Здесь появятся фото, видео, файлы, голосовые и ссылки из этого чата")
                    .font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(available, id: \.self) { t in
                            Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tab = t } } label: {
                                Text(t.rawValue).font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(tab == t ? Theme.text : Theme.muted)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(tab == t ? Theme.panel2 : Color.clear))
                            }
                            .buttonStyle(BouncyButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                }
                content
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.panel))
        .padding(.horizontal, 14)
        .task { await load() }
        .fullScreenCover(item: $image) { ImageScreen(url: $0.url) }
        .fullScreenCover(item: $video) { VideoScreen(url: $0.url) }
    }

    @ViewBuilder private var content: some View {
        switch available.contains(tab) ? tab : (available.first ?? .media) {
        case .media:
            let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(media, id: \.id) { m in
                    if let u = m.mediaURL.flatMap(URL.init(string:)) {
                        Button { if m.kind == "video" { video = IdentifiedURL(url: u) } else { image = IdentifiedURL(url: u) } } label: {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    if m.kind == "video" {
                                        ZStack(alignment: .bottomLeading) {
                                            VideoThumb(url: u)
                                            Image(systemName: "play.fill").font(.caption).foregroundColor(.white).padding(6)
                                        }
                                    } else {
                                        CachedImage(url: u) { $0.resizable().scaledToFill() } placeholder: { Theme.panel2 }
                                    }
                                }
                                .clipped()
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        case .files:
            VStack(spacing: 0) {
                ForEach(files, id: \.id) { m in
                    Button { if let u = m.mediaURL.flatMap(URL.init(string:)) { UIApplication.shared.open(u) } } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.fill").font(.system(size: 20)).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.fileName).font(.system(size: 15.5, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                                Text((m.fileSize.map { Fmt.size($0) + " · " } ?? "") + Fmt.day(m.createdAt))
                                    .font(.caption).foregroundColor(Theme.muted)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 7).contentShape(Rectangle())
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        case .voice:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(voices, id: \.id) { m in
                    HStack {
                        if m.kind == "video_note", let u = m.mediaURL.flatMap(URL.init(string:)) {
                            Button { MiniNotePlayer.shared.play(u) } label: {
                                HStack(spacing: 10) {
                                    VideoThumb(url: u).frame(width: 44, height: 44).clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Видеосообщение").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                                        Text(model.displayName(m.senderId) + " · " + Fmt.day(m.createdAt)).font(.caption).foregroundColor(Theme.muted)
                                    }
                                }
                            }
                            .buttonStyle(BouncyButtonStyle())
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                VoiceView(m: m, mine: false)
                                Text(model.displayName(m.senderId) + " · " + Fmt.day(m.createdAt)).font(.caption).foregroundColor(Theme.muted)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        case .links:
            VStack(spacing: 0) {
                ForEach(links, id: \.id) { l in
                    Button { UIApplication.shared.open(l.url) } label: {
                        HStack(spacing: 12) {
                            Text(String((l.url.host ?? "?").replacingOccurrences(of: "www.", with: "").prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l.url.host ?? l.url.absoluteString).font(.system(size: 15.5, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                                Text(l.url.absoluteString).font(.caption).foregroundColor(Theme.a1).lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 7).contentShape(Rectangle())
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
    }

    private func load() async {
        if model.demo != nil { loaded = true; return }
        func q(_ kinds: String) async -> [Message] {
            let rows = (try? await API.shared.select("lm_messages", [
                "select": "*", "chat_id": "eq." + chatId, "deleted": "eq.false",
                "kind": "in.(" + kinds + ")", "order": "id.desc", "limit": "90",
            ])) ?? []
            return rows.map { Message(json: $0) }.filter { $0.mediaURL != nil }
        }
        async let m = q("image,video")
        async let f = q("file")
        async let v = q("voice,video_note")
        // личные чаты зашифрованы: ссылки ищем на устройстве среди последних сообщений
        let isPriv = model.chat(chatId)?.isPrivate == true
        if isPriv { await model.prep(chatId) }
        var tq = ["select": "*", "chat_id": "eq." + chatId, "deleted": "eq.false", "kind": "eq.text", "order": "id.desc", "limit": isPriv ? "300" : "60"]
        if !isPriv { tq["body"] = "ilike.*http*" }
        let texts = (try? await API.shared.select("lm_messages", tq)) ?? []
        var ls: [(id: Int, url: URL, date: Date)] = []
        let det = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        for j in texts {
            let msg = isPriv ? model.dec(Message(json: j)) : Message(json: j)
            let b = msg.body ?? ""
            for r in det?.matches(in: b, range: NSRange(b.startIndex..., in: b)) ?? [] {
                if let u = r.url, u.scheme?.hasPrefix("http") == true { ls.append((id: msg.id * 100 + ls.count % 100, url: u, date: msg.createdAt)) }
            }
        }
        media = await m
        files = await f
        voices = await v
        links = ls
        loaded = true
        if let first = available.first, !available.contains(tab) { tab = first }
    }
}


/// Заявки на вступление (для администраторов): принять или отклонить
struct JoinRequestsSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    @State private var ids: [String] = []
    @State private var loaded = false
    @State private var joinOn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    SettingsGroup {
                        Toggle("Заявки на вступление", isOn: Binding(get: { joinOn }, set: { v in
                            joinOn = v
                            Task { _ = try? await API.shared.rpc("lm_set_join_requests", ["p_chat": chatId, "p_on": v]) }
                        })).tint(Theme.a1).padding(.vertical, 8)
                    }
                    Text("Если включено, новые участники вступают только после вашего одобрения.")
                        .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24).frame(maxWidth: .infinity, alignment: .leading)
                    if loaded && ids.isEmpty {
                        Text("Заявок пока нет").foregroundColor(Theme.muted).padding(30)
                    }
                    ForEach(ids, id: \.self) { id in
                        HStack(spacing: 12) {
                            AvatarView(name: model.displayName(id), url: model.profiles[id]?.avatarURL, color: model.profiles[id]?.color ?? 0, size: 44)
                            Text(model.displayName(id)).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                            Spacer()
                            Button { decide(id, false) } label: { Image(systemName: "xmark").foregroundColor(Theme.danger).frame(width: 38, height: 38).background(Circle().fill(Theme.panel2)) }
                            Button { decide(id, true) } label: { Image(systemName: "checkmark").foregroundColor(.white).frame(width: 38, height: 38).background(Circle().fill(Theme.accent)) }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 6)
                    }
                }
                .padding(.top, 10)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Заявки").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
            .task { await load() }
        }
    }

    private func load() async {
        let rows = (try? await API.shared.rpc("lm_requests_list", ["p_chat": chatId])) as? [JSON] ?? []
        ids = rows.compactMap { $0.str("user_id") }
        await model.loadProfiles(ids)
        if let c = (try? await API.shared.select("lm_chats", ["select": "join_requests", "id": "eq." + chatId]))?.first { joinOn = c.bool("join_requests") }
        loaded = true
    }

    private func decide(_ id: String, _ ok: Bool) {
        ids.removeAll { $0 == id }
        Task { _ = try? await API.shared.rpc("lm_request_decide", ["p_chat": chatId, "p_user": id, "p_ok": ok]) }
    }
}
