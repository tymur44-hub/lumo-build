import SwiftUI
import Contacts
import UIKit
import AudioToolbox

enum AppTab: Hashable { case contacts, chats, settings }

/// Состояние приложения: вход, чаты, сообщения, живые обновления, уведомления
@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var loggedIn: Bool
    @Published var me: Profile?
    @Published var chats: [ChatItem] = []
    @Published var chatsLoaded = false
    @Published var messages: [String: [Message]] = [:]
    @Published var hasMore: [String: Bool] = [:]
    @Published var profiles: [String: Profile] = [:]
    @Published var path: [String] = []
    /// Строка сверху, как в Telegram: «Соединение…» / «Обновление…»; nil — всё в порядке
    @Published var netStatus: String?
    private var netTask: Task<Void, Never>?
    @Published var contactsPath: [String] = []
    @Published var settingsPath: [SettingsPage] = []
    @Published var tab: AppTab = .chats
    @Published var toast: String?
    /// Открытое мини-приложение бота
    @Published var miniApp: MiniAppReq?
    /// Кнопка мини-приложения у бота: id бота → [текст, адрес] (пустой массив — нет кнопки)
    @Published var botMenus: [String: [String]] = [:]

    func loadBotMenu(_ botId: String) async {
        if botMenus[botId] != nil { return }
        let j = (try? await API.shared.rpc("lm_bot_info", ["p_id": botId])) as? [String: Any]
        if let u = j?["web_app_url"] as? String, !u.isEmpty { botMenus[botId] = [(j?["menu_text"] as? String) ?? "Открыть", u] }
        else { botMenus[botId] = [] }
    }

    /// «Создать бота»: открывает конструктор в BotFather
    func openBotFather() async {
        let r = await search("botfather").first { $0.username == "botfather" }
        guard let r else { say("Конструктор ботов пока недоступен"); return }
        miniApp = MiniAppReq(botId: r.id, url: nil)
    }

    @Published var contacts: [String] = []
    @Published var aliases: [String: String] = [:]
    @Published var contactNotes: [String: String] = [:]
    @Published var contactPhotos: [String: String] = [:]
    @Published var blockedByMe: Set<String> = []
    @Published var blockedMe: Set<String> = []
    @Published var reactions: [Int: [Reaction]] = [:]
    /// Удалённые только у меня
    var hidden = Set<Int>()
    @Published var typing: [String: [String: String]] = [:]
    @Published var online: Set<String> = []
    @Published var stories: [StoryGroup] = []
    @Published var storyOpen: String?
    private var storyTask: Task<Void, Never>?
    @Published var calls: [Message] = []
    @Published var botName: String?
    @Published var tgLinked = false
    @Published var staffRole: String?

    var openChatId: String? {
        didSet { if oldValue != openChatId { syncTypingChannels() } }
    }
    private(set) var isActive = true
    private var started = false
    private var reloadTask: Task<Void, Never>?
    private var presenceTimer: Timer?
    private var storiesTimer: Timer?
    private var notified = Set<Int>()
    private var cleared: [String: Date] = [:]
    private var replyCache: [Int: Message] = [:]
    private var onlineChannel: Realtime.Channel?
    private var typingChannels: [String: Realtime.Channel] = [:]
    private var typingClear: [String: Task<Void, Never>] = [:]
    private var typingAct: [String: String] = [:]
    private var lastTypingAct = ""
    private var lastTypingSent = Date.distantPast

    private init() {
        loggedIn = API.shared.session != nil
        API.shared.onSessionChange = { [weak self] s in
            guard let self = self else { return }
            if let s = s { Realtime.shared.updateToken(s.accessToken) }
            else if self.loggedIn { self.resetAfterLogout() }
        }
    }

    var myId: String? { API.shared.userId ?? demoUser }
    private var demoUser: String?
    /// Режим показа экранов с примерными данными (только для скриншотов сборки)
    @Published var demo: String?

    func chat(_ id: String) -> ChatItem? { chats.first { $0.id == id } }

    /// Нажатие кнопки под сообщением бота
    func botPress(_ m: Message, _ b: BotButton) {
        if let w = b.webApp, !w.isEmpty, let sid = m.senderId { miniApp = MiniAppReq(botId: sid, url: w); return }
        if let u = b.url, let url = URL(string: u), url.scheme == "https" || url.scheme == "http" { UIApplication.shared.open(url); return }
        guard let d = b.data else { return }
        Task {
            do {
                let r = try await API.shared.botFunction("/cb", body: ["message_id": m.id, "data": d]) as? [String: Any]
                if let t = r?["toast"] as? String { say(t) }
            } catch { say("Не удалось выполнить действие") }
        }
    }

    func say(_ raw: String) {
        let text = Lang.tr(raw)
        toast = text
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if self?.toast == text { self?.toast = nil }
        }
    }

    /// Имя человека, как его видит пользователь (своё имя для контакта — если задано)
    func displayName(_ uid: String?) -> String {
        guard let uid = uid else { return "Пользователь" }
        if let a = aliases[uid], !a.isEmpty { return a }
        return profiles[uid]?.name ?? "Пользователь"
    }

    /// В сети — если человек разрешил мне видеть время захода
    func isOnline(_ uid: String?) -> Bool { uid.map { profiles[$0]?.isBot != true && online.contains($0) && ($0 == myId || profiles[$0]?.showSeen != false) } ?? false }

    func lastSeenText(_ uid: String?, fallback: Date? = nil) -> String {
        guard let uid = uid else { return "" }
        let p = profiles[uid]
        if p?.isBot == true { return "бот" }
        if p?.showSeen == false && uid != myId { return "был(а) недавно" }
        if online.contains(uid) { return "в сети" }
        // берём самое свежее время из профиля и из списка чатов
        let d = [p?.lastSeen, fallback].compactMap { $0 }.max()
        return Fmt.lastSeen(d, show: true)
    }

    // MARK: - запуск и вход

    func start() async {
        guard loggedIn, !started else { return }
        started = true
        netStatus = "Соединение…"
        Task { await Net.pick(force: true) }
        Realtime.shared.onState = { [weak self] ok in self?.netChanged(ok) }
        await loadMe()
        if let id = myId { await E2E.shared.setup(id) }
        netStatus = "Обновление…"
        await loadContacts()
        await loadChats()
        await loadChatWalls()
        Realtime.shared.connect()
        netStatus = nil
        if !Realtime.shared.isOpen { netChanged(false) }
        let ch = Realtime.shared.channel("lm-db", changes: [
            ["event": "INSERT", "schema": "public", "table": "lm_messages"],
            ["event": "UPDATE", "schema": "public", "table": "lm_messages"],
            ["event": "*", "schema": "public", "table": "lm_members"],
            ["event": "*", "schema": "public", "table": "lm_reactions"],
            ["event": "*", "schema": "public", "table": "lm_reactions_extra"],
            ["event": "*", "schema": "public", "table": "lm_chat_wall"],
        ])
        ch.onChange = { [weak self] d in self?.onDB(d) }
        let sch = Realtime.shared.channel("lm-stories")
        sch.onBroadcast = { [weak self] _, _ in
            guard let self = self else { return }
            self.storyTask?.cancel()
            self.storyTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                if !Task.isCancelled { await self.loadStories() }
            }
        }
        Realtime.shared.onReconnect = { [weak self] in
            guard let self = self else { return }
            Task {
                await self.refreshing {
                    await self.loadChats()
                    await self.loadStories()
                    if let c = self.openChatId { await self.loadMessages(c) }
                }
            }
        }
        if let id = myId {
            CallManager.shared.attach(myId: id)
            let oc = Realtime.shared.channel("lm-online", presenceKey: id)
            oc.onPresenceState = { [weak self] st in self?.online = Set(st.keys) }
            oc.onPresenceDiff = { [weak self] joins, leaves in
                guard let self = self else { return }
                var s = self.online
                for k in joins.keys { s.insert(k) }
                for k in leaves.keys where joins[k] == nil {
                    s.remove(k)
                    if var p = self.profiles[k] { p.lastSeen = Date(); self.profiles[k] = p }
                }
                self.online = s
            }
            Realtime.shared.track(oc, ["at": Int(Date().timeIntervalSince1970 * 1000)])
            onlineChannel = oc
        }
        Notifier.askPermission()
        presence(true)
        Task { await touchSession() }
        Task { await PhoneStore.shared.load(); await PhoneStore.shared.syncIfAllowed() }
        Task { await Lumens.shared.load(); await Lumens.shared.loadCfg() }
        presenceTimer?.invalidate()
        presenceTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            Task { @MainActor in if let self = self, self.isActive { self.presence(true); await self.touchSession() } }
        }
        storiesTimer?.invalidate()
        storiesTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in if let self = self, self.isActive { await self.loadStories() } }
        }
        Task {
            await loadBlocks()
            await loadStories()
            await loadExtras()
        }
    }

    func login(username: String, password: String) async throws {
        try await API.shared.signIn(username: username.lowercased(), password: password)
        loggedIn = true
        await start()
    }

    func register(username: String, password: String, name: String) async throws {
        try await API.shared.register(username: username.lowercased(), password: password, name: name)
        loggedIn = true
        await start()
    }

    /// Вход/регистрация через Telegram: ждём, пока в боте нажмут кнопку
    func telegramBot() async -> String? {
        if let b = botName { return b }
        if let j = (try? await API.shared.publicFunction("/config")) as? JSON { botName = j.str("bot") }
        return botName
    }

    /// Проверить ключ входа. true — вошли; nil — ещё ждём; бросает ошибку, если ключ устарел
    func telegramCheck(key: String) async throws -> Bool {
        let j = (try await API.shared.publicFunction("/tglogin", body: ["key": key])) as? JSON ?? [:]
        if let th = j.str("th"), !th.isEmpty {
            try await API.shared.verifyMagic(th)
            loggedIn = true
            await start()
            if j.bool("new") {
                let u = j.str("username") ?? ""
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    say("Аккаунт создан: @" + u + " — имя и юзернейм можно поменять в настройках")
                }
            }
            return true
        }
        if j.str("error") == "expired" { throw APIError(message: "Ссылка устарела — нажмите кнопку ещё раз", status: 0) }
        return false
    }

    @Published var msgViews: [Int: Int] = [:]

    /// Просмотры постов канала (по числу подписчиков, прочитавших пост)
    func loadViews(_ chatId: String) async {
        guard let c = chat(chatId), c.isChannel else { return }
        let ids = (messages[chatId] ?? []).suffix(80).filter { $0.id > 0 }.map { $0.id }
        guard !ids.isEmpty else { return }
        guard let r = try? await API.shared.rpc("lm_msg_views", ["p_chat": chatId, "p_ids": ids]) as? [[String: Any]] else { return }
        for j in r { if let i = j.int("id"), let n = j.int("n") { msgViews[i] = n } }
    }

    func logout() async {
        presence(false)
        if let u = API.shared.userId { Accounts.shared.remove(u) }
        await API.shared.signOut()
        resetAfterLogout()
        // есть другой сохранённый аккаунт — входим в него
        if let a = Accounts.shared.list.first { await switchAccount(a.id) }
    }

    /// Добавить аккаунт: текущий остаётся сохранённым, открывается экран входа
    @discardableResult
    func addAccount() -> Bool {
        if Accounts.shared.list.count >= Accounts.shared.limit() { return false }
        presence(false)
        resetAfterLogout()
        API.shared.forgetSession()
        return true
    }

    /// Переключиться на сохранённый аккаунт
    func switchAccount(_ id: String) async {
        guard let acc = Accounts.shared.list.first(where: { $0.id == id }) else { return }
        if loggedIn { presence(false); resetAfterLogout() }
        API.shared.restore(acc.session)
        loggedIn = true
        await start()
    }

    /// Соединение пропало/появилось. «Соединение…» показываем, только если связи нет дольше секунды
    func netChanged(_ ok: Bool) {
        netTask?.cancel()
        if ok { if netStatus == "Соединение…" { netStatus = nil }; return }
        netTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            if Task.isCancelled { return }
            if self.loggedIn && !Realtime.shared.isOpen { self.netStatus = "Соединение…" }
        }
    }

    /// Пока подгружаем свежие данные — «Обновление…»
    func refreshing(_ work: () async -> Void) async {
        if Realtime.shared.isOpen { netStatus = "Обновление…" }
        await work()
        if Realtime.shared.isOpen { netStatus = nil }
    }

    // MARK: - устройства (сеансы)

    static var deviceId: String {
        let d = UserDefaults.standard
        if let s = d.string(forKey: "lm_device_id") { return s }
        let s = UUID().uuidString
        d.set(s, forKey: "lm_device_id")
        return s
    }

    static var deviceName: String {
        let m = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        return m + " · iOS " + UIDevice.current.systemVersion
    }

    /// Отметить это устройство в списке сеансов; если сеанс завершили на другом устройстве — выйти
    func touchSession() async {
        guard loggedIn else { return }
        let d = UserDefaults.standard
        let fresh = !d.bool(forKey: "lm_sess_active")
        let p: JSON = ["p_device": Self.deviceId, "p_name": Self.deviceName, "p_platform": "ios",
                       "p_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "", "p_fresh": fresh]
        guard let r = try? await API.shared.rpc("lm_session_touch", p) as? JSON else { return }
        if r.bool("revoked") {
            d.set(false, forKey: "lm_sess_active")
            await logout()
            say("Сеанс завершён на другом устройстве")
        } else { d.set(true, forKey: "lm_sess_active") }
    }

    func loadSessions() async -> [DeviceSession] {
        let rows = (try? await API.shared.select("lm_sessions", ["select": "id,device_id,name,platform,app_version,created_at,last_active,revoked", "order": "last_active.desc"])) ?? []
        return rows.filter { !$0.bool("revoked") }.map { DeviceSession(json: $0) }
    }

    func endSession(_ id: String) async {
        _ = try? await API.shared.rpc("lm_session_kill", ["p_id": id])
    }

    func resetAfterLogout() {
        UserDefaults.standard.set(false, forKey: "lm_sess_active")
        PhoneStore.shared.reset()
        Lumens.shared.reset()
        if ProcessInfo.processInfo.environment["LUMO_SNAPSHOT"] != nil { NSLog("LUMODBG resetAfterLogout %@", Thread.callStackSymbols.prefix(14).joined(separator: " | ")) }
        netTask?.cancel()
        netStatus = nil
        Realtime.shared.disconnect()
        CallManager.shared.detach()
        presenceTimer?.invalidate()
        storiesTimer?.invalidate()
        onlineChannel = nil
        typingChannels = [:]
        started = false
        loggedIn = false
        E2E.shared.forget()
        me = nil
        chats = []
        chatsLoaded = false
        messages = [:]
        path = []
        contacts = []
        aliases = [:]
        contactNotes = [:]
        contactPhotos = [:]
        stories = []
        calls = []
        tab = .chats
        Notifier.setBadge(0)
    }

    func scenePhase(_ active: Bool) {
        if active { Task { await Net.pick() } }
        isActive = active
        if !loggedIn || demo != nil { return }
        if active {
            BackgroundKeeper.shared.stop()
            Realtime.shared.ensureConnected()
            if let oc = onlineChannel { Realtime.shared.track(oc, ["at": Int(Date().timeIntervalSince1970 * 1000)]) }
            presence(true)
            Task {
                await refreshing {
                    await loadChats()
                    if let c = openChatId { await loadMessages(c); markRead(c) }
                }
                await loadStories()
            }
        } else {
            if let oc = onlineChannel { Realtime.shared.untrack(oc) }
            presence(false)
            BackgroundKeeper.shared.start()
        }
    }

    private func presence(_ on: Bool) {
        Task { _ = try? await API.shared.rpc("lm_presence", ["p_active": on]) }
    }

    // MARK: - профиль

    /// Профили с учётом конфиденциальности (сервер скрывает то, что мне видеть нельзя)
    func fetchProfiles(_ ids: [String]) async -> [Profile] {
        let list = Array(Set(ids.filter { !$0.isEmpty }))
        guard !list.isEmpty else { return [] }
        let rows = (try? await API.shared.rpc("lm_profiles_get", ["p_ids": list])) as? [JSON] ?? []
        return rows.map { row in
            var prof = Profile(json: row)
            if let ph = contactPhotos[prof.id] { prof.avatarURL = ph }   // личное фото контакта видите только вы
            return prof
        }
    }

    func loadMe() async {
        guard let id = myId else { return }
        if let p = await fetchProfiles([id]).first {
            me = p
            profiles[id] = p
            Accounts.shared.info(id, name: p.name, username: p.username, avatar: p.avatarURL)
        }
    }

    func profile(_ id: String) async -> Profile? {
        if let p = profiles[id] { return p }
        if let p = await fetchProfiles([id]).first {
            profiles[id] = p
            return p
        }
        return nil
    }

    func refreshProfile(_ id: String) async {
        if let p = await fetchProfiles([id]).first { profiles[id] = p }
    }

    func setUsername(_ username: String) async throws {
        let un = username.lowercased().replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespaces)
        guard un != me?.username else { return }
        guard un.range(of: "^[a-z0-9_]{3,32}$", options: .regularExpression) != nil else {
            throw APIError(message: "Юзернейм: 3–32 символа, латиница, цифры и _", status: 0)
        }
        _ = try await API.shared.rpc("lm_set_username", ["p_username": un])
        await loadMe()
    }

    /// Имя, фамилия, «о себе», день рождения (yyyy-MM-dd или nil)
    func saveProfileFull(first: String, last: String, bio: String, birthday: String?) async throws {
        guard let id = myId else { return }
        let f = first.trimmingCharacters(in: .whitespaces), l = last.trimmingCharacters(in: .whitespaces)
        let full = [f, l].filter { !$0.isEmpty }.joined(separator: " ")
        guard !f.isEmpty else { throw APIError(message: "Укажите имя", status: 0) }
        try await API.shared.update("lm_profiles", match: ["id": id], ["name": full, "last_name": l, "bio": String(bio.trimmingCharacters(in: .whitespacesAndNewlines).prefix(70)),
                                                                       "birthday": birthday as Any? ?? NSNull()])
        await loadMe()
    }

    func setColor(_ c: Int) async {
        guard let id = myId else { return }
        try? await API.shared.update("lm_profiles", match: ["id": id], ["color": c])
        await loadMe()
    }

    func setChannel(_ chatId: String?) async {
        guard let id = myId else { return }
        try? await API.shared.update("lm_profiles", match: ["id": id], ["channel_id": chatId as Any? ?? NSNull()])
        await loadMe()
    }

    func setPrivacyKey(_ key: String, _ value: String) async {
        do { _ = try await API.shared.rpc("lm_set_privacy", ["p_key": key, "p_value": value]); await loadMe() }
        catch { say(error.localizedDescription) }
    }

    func loadProfiles(_ ids: [String]) async {
        let need = Array(Set(ids.filter { profiles[$0] == nil && !$0.isEmpty }))
        guard !need.isEmpty else { return }
        for p in await fetchProfiles(need) { profiles[p.id] = p }
    }


    func saveProfile(name: String, username: String, bio: String) async throws {
        guard let id = myId else { return }
        let un = username.lowercased().replacingOccurrences(of: "@", with: "")
        if un != me?.username {
            guard un.range(of: "^[a-z0-9_]{3,32}$", options: .regularExpression) != nil else {
                throw APIError(message: "Юзернейм: 3–32 символа, латиница, цифры и _", status: 0)
            }
            _ = try await API.shared.rpc("lm_set_username", ["p_username": un])
        }
        try await API.shared.update("lm_profiles", match: ["id": id], ["name": name, "bio": bio])
        await loadMe()
    }

    func setPassword(_ pw: String) async throws {
        try await API.shared.raw("PUT", "/auth/v1/user", body: ["password": pw])
    }

    func setPrivacy(showSeen: Bool? = nil, callsFrom: String? = nil) async {
        guard let id = myId else { return }
        var v: JSON = [:]
        if let s = showSeen { v["show_seen"] = s }
        if let c = callsFrom { v["calls_from"] = c }
        do { try await API.shared.update("lm_profiles", match: ["id": id], v); await loadMe() }
        catch { say(error.localizedDescription) }
    }

    func setAvatar(_ image: UIImage?) async throws {
        guard let id = myId else { return }
        var url: Any = NSNull()
        if let img = image, let data = Media.squareJPEG(img, side: 640) {
            url = try await API.shared.upload(data, ext: "jpg", contentType: "image/jpeg")
        }
        try await API.shared.update("lm_profiles", match: ["id": id], ["avatar_url": url])
        await loadMe()
    }

    func deleteAccount() async throws {
        let r = try await API.shared.function("/account", body: ["action": "delete"]) as? JSON
        if let e = r?.str("error") { throw APIError(message: e, status: 0) }
        API.shared.forgetSession()
        resetAfterLogout()
    }

    /// Профиль по @юзернейму (для QR-кодов и ссылок)
    func openByUsername(_ username: String) async {
        let u = username.lowercased()
        guard let r = try? await API.shared.select("lm_profiles", ["select": "id", "username": "eq." + u]).first,
              let p = await fetchProfiles([r.str("id") ?? ""]).first else {
            say("Пользователь @\(u) не найден")
            return
        }
        profiles[p.id] = p
        if p.id == myId { say("Это ваш профиль"); return }
        await openDM(p.id)
    }

    private func loadExtras() async {
        if let j = (try? await API.shared.function("/config")) as? JSON { botName = j.str("bot") }
        if let r = try? await API.shared.select("lm_tg_links", ["select": "enabled"]).first { tgLinked = r.bool("enabled") } else { tgLinked = false }
        staffRole = (try? await API.shared.rpc("lm_staff_role")) as? String
    }

    func telegramLink() async -> URL? {
        guard let bot = botName else { return nil }
        let code = (try? await API.shared.rpc("lm_tg_code")) as? String
        return URL(string: "https://t.me/\(bot)" + (code.map { "?start=" + $0 } ?? ""))
    }

    func telegramOff() async {
        try? await API.shared.update("lm_tg_links", match: ["user_id": myId ?? ""], ["enabled": false])
        await loadExtras()
    }

    var profileLink: String {
        "https://volshebny-mir.ru/page322172009.html#@" + (me?.username ?? "")
    }

    // MARK: - контакты и блокировки

    func loadContacts() async {
        let rows = (try? await API.shared.select("lm_contacts", ["select": "contact_id,alias,note,photo,created_at", "order": "created_at.desc"])) ?? []
        contacts = rows.compactMap { $0.str("contact_id") }
        var a: [String: String] = [:]
        for r in rows { if let id = r.str("contact_id"), let al = r.str("alias"), !al.isEmpty { a[id] = al } }
        aliases = a
        var notes: [String: String] = [:], photos: [String: String] = [:]
        for r in rows {
            guard let id = r.str("contact_id") else { continue }
            if let n = r.str("note"), !n.isEmpty { notes[id] = n }
            if let p = r.str("photo"), !p.isEmpty { photos[id] = p }
        }
        contactNotes = notes
        contactPhotos = photos
        if !contacts.isEmpty {
            for p in await fetchProfiles(contacts) { profiles[p.id] = p }
        }
    }

    func isContact(_ id: String) -> Bool { contacts.contains(id) }

    /// Сохранить человека в записную книжку телефона (если номер известен и его там ещё нет)
    func savePhonebook(_ id: String) async -> Bool {
        guard let raw = (try? await API.shared.rpc("lm_phone_of", ["p_user": id])) as? String else { return false }
        let digits = raw.filter { $0.isNumber }
        guard digits.count >= 10 else { return false }
        let store = CNContactStore()
        var ok = CNContactStore.authorizationStatus(for: .contacts) == .authorized
        if !ok { ok = (try? await store.requestAccess(for: .contacts)) ?? false }
        guard ok else { return false }
        let number = CNPhoneNumber(stringValue: "+" + digits)
        let pred = CNContact.predicateForContacts(matching: number)
        if let ex = try? store.unifiedContacts(matching: pred, keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor]), !ex.isEmpty { return true }
        let c = CNMutableContact()
        c.givenName = displayName(id)
        c.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: number)]
        let req = CNSaveRequest()
        req.add(c, toContainerWithIdentifier: nil)
        return (try? store.execute(req)) != nil
    }

    func addContact(_ id: String) async {
        guard id != myId, !isContact(id) else { return }
        do {
            _ = try await API.shared.insert("lm_contacts", ["contact_id": id])
            contacts.insert(id, at: 0)
            _ = await profile(id)
            let saved = await savePhonebook(id)
            say(saved ? "Добавлено в контакты и в телефон" : "Добавлено в контакты")
        } catch { say(error.localizedDescription) }
    }

    func removeContact(_ id: String) async {
        do {
            try await API.shared.raw("DELETE", "/rest/v1/lm_contacts", query: [URLQueryItem(name: "contact_id", value: "eq." + id)])
            contacts.removeAll { $0 == id }
            say("Удалено из контактов")
        } catch { say(error.localizedDescription) }
    }

    func setAlias(_ id: String, _ alias: String) async {
        do {
            _ = try await API.shared.rpc("lm_set_alias", ["p_user": id, "p_alias": alias])
            await loadContacts()
            await loadChats()
            say(alias.trimmingCharacters(in: .whitespaces).isEmpty ? "Имя сброшено" : "Имя сохранено — его видите только вы")
        } catch { say(error.localizedDescription) }
    }

    /// Заметка и личное фото контакта (видны только владельцу)
    func setContactExtra(_ id: String, note: String, photo: String?) async -> Bool {
        do {
            _ = try await API.shared.rpc("lm_set_contact_extra", ["p_user": id, "p_note": note, "p_photo": photo ?? ""])
            return true
        } catch { say(error.localizedDescription); return false }
    }

    func uploadContactPhoto(_ image: UIImage) async -> String? {
        guard let data = Media.squareJPEG(image, side: 640) else { return nil }
        do { return try await API.shared.upload(data, ext: "jpg", contentType: "image/jpeg") }
        catch { say(error.localizedDescription); return nil }
    }

    func loadBlocks() async {
        guard let j = (try? await API.shared.rpc("lm_my_blocks")) as? JSON else { return }
        blockedByMe = Set((j["mine"] as? [Any] ?? []).compactMap { $0 as? String })
        blockedMe = Set((j["me"] as? [Any] ?? []).compactMap { $0 as? String })
    }

    func setBlocked(_ id: String, _ on: Bool) async {
        do {
            _ = try await API.shared.rpc("lm_block", ["p_user": id, "p_on": on])
            await loadBlocks()
            say(on ? "Пользователь заблокирован" : "Пользователь разблокирован")
        } catch { say(error.localizedDescription) }
    }

    func report(user: String?, chat: String?, message: Int?, reason: ReportReason, comment: String) async -> Bool {
        do {
            if let cid = chat, let mid = message, let em = findMessage(mid, in: cid), em.enc {
                // сообщение зашифровано: сервер его прочитать не может, поэтому прикладываем текст, который видит пожаловавшийся
                _ = try await API.shared.rpc("lm_report_e2e", ["p_user": user.map { $0 as Any } ?? NSNull(), "p_chat": cid, "p_message": mid,
                                                                "p_reason": reason.rawValue, "p_comment": comment, "p_plain": em.body ?? ""])
                say("Жалоба отправлена. Спасибо!")
                return true
            }
            _ = try await API.shared.rpc("lm_report", ["p_user": user.map { $0 as Any } ?? NSNull(), "p_chat": chat.map { $0 as Any } ?? NSNull(),
                                                        "p_message": message.map { $0 as Any } ?? NSNull(),
                                                        "p_reason": reason.rawValue, "p_comment": comment])
            say("Жалоба отправлена. Спасибо!")
            return true
        } catch { say(error.localizedDescription); return false }
    }

    /// Почему нельзя писать или звонить человеку (блокировка или бан)
    func peerBlockText(_ uid: String?) -> String? {
        guard let uid = uid else { return nil }
        if let p = profiles[uid], p.banned { return "Аккаунт заблокирован" + ((p.banReason ?? "").isEmpty ? "" : ": " + (p.banReason ?? "")) }
        if blockedByMe.contains(uid) { return "Вы заблокировали этого пользователя" }
        if blockedMe.contains(uid) { return "Пользователь ограничил сообщения" }
        return nil
    }

    // MARK: - чаты

    func loadChats() async {
        guard loggedIn else { return }
        do {
            let rows = try await API.shared.rpc("lm_chats_v2") as? [JSON] ?? []
            var list = rows.map { ChatItem(json: $0) }
            await E2E.shared.prefetch(list.filter { $0.isPrivate }.compactMap { $0.peerId })
            for i in list.indices {
                if let p = list[i].peerId, let a = aliases[p], !a.isEmpty { list[i].peerName = a }
                if let p = list[i].peerId, let ph = contactPhotos[p] { list[i].peerAvatar = ph }
                if list[i].isPrivate, E2E.isEnc(list[i].lastBody) {
                    await E2E.shared.prepare(list[i].id, peer: list[i].peerId)
                    list[i].lastBody = E2E.shared.decrypt(list[i].id, list[i].lastBody)
                }
            }
            list.sort { a, b in
                if a.pinned != b.pinned { return a.pinned }
                return (a.lastAt ?? .distantPast) > (b.lastAt ?? .distantPast)
            }
            chats = list
            syncTypingChannels()
            Task { await self.loadProfiles(self.chats.compactMap { $0.peerId }) }
            chatsLoaded = true
            if list.contains(where: { $0.isChannel }) { Task { await Lumens.shared.loadCfg() } }
            Notifier.setBadge(list.filter { !$0.muted }.reduce(0) { $0 + $1.unread })
        } catch {
            if (error as? APIError)?.status == 401 { API.shared.forgetSession() }
        }
    }

    func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            await self?.loadChats()
        }
    }

    func open(_ chatId: String) {
        tab = .chats
        path = [chatId]
    }

    func openDM(_ userId: String) async {
        do {
            guard let cid = try await API.shared.rpc("lm_open_dm", ["p_other": userId]) as? String else { return }
            await loadChats()
            open(cid)
        } catch { say(error.localizedDescription) }
    }

    func openSaved() async {
        if let id = myId { await openDM(id) }
    }

    func join(_ chatId: String) async {
        do {
            _ = try await API.shared.rpc("lm_join", ["p_chat": chatId])
            await loadChats()
            open(chatId)
        } catch { say(error.localizedDescription) }
    }

    func search(_ q: String) async -> [SearchResult] {
        let rows = (try? await API.shared.rpc("lm_search", ["q": q])) as? [JSON] ?? []
        return rows.map { SearchResult(json: $0) }
    }

    func setMuted(_ chatId: String, _ on: Bool) async {
        guard let id = myId else { return }
        try? await API.shared.update("lm_members", match: ["chat_id": chatId, "user_id": id], ["muted": on])
        await loadChats()
    }

    func setPinned(_ chatId: String, _ on: Bool) async {
        guard let id = myId else { return }
        try? await API.shared.update("lm_members", match: ["chat_id": chatId, "user_id": id], ["pinned": on])
        await loadChats()
    }

    func clearChat(_ chatId: String) async {
        do {
            let t = try await API.shared.rpc("lm_clear_chat", ["p_chat": chatId]) as? String
            cleared[chatId] = DateParser.parse(t) ?? Date()
            messages[chatId] = []
            hasMore[chatId] = false
            await loadChats()
            say("История очищена — только у вас")
        } catch { say(error.localizedDescription) }
    }

    func leave(_ chatId: String) async {
        guard let id = myId else { return }
        do {
            try await API.shared.raw("DELETE", "/rest/v1/lm_members", query: [URLQueryItem(name: "chat_id", value: "eq." + chatId),
                                                                            URLQueryItem(name: "user_id", value: "eq." + id)])
            path = []
            await loadChats()
        } catch { say(error.localizedDescription) }
    }

    func createChat(type: String, title: String, description: String, members: [String], username: String?) async -> String? {
        do {
            var p: JSON = ["p_type": type, "p_title": title, "p_members": members, "p_description": description]
            if let u = username, !u.isEmpty { p["p_username"] = u.lowercased() }
            guard let cid = try await API.shared.rpc("lm_create_chat", p) as? String else { return nil }
            await loadChats()
            open(cid)
            return cid
        } catch { say(error.localizedDescription); return nil }
    }

    func members(_ chatId: String) async -> [Member] {
        let rows = (try? await API.shared.select("lm_members", ["select": "user_id,role", "chat_id": "eq." + chatId])) ?? []
        let list = rows.map { Member(userId: $0.str("user_id") ?? "", role: $0.str("role") ?? "member") }
        await loadProfiles(list.map { $0.userId })
        let order = ["owner": 0, "admin": 1]
        return list.sorted { (order[$0.role] ?? 2, displayName($0.userId)) < (order[$1.role] ?? 2, displayName($1.userId)) }
    }

    func addMembers(_ chatId: String, _ ids: [String]) async {
        do { _ = try await API.shared.rpc("lm_add_members", ["p_chat": chatId, "p_members": ids]); await loadChats() }
        catch { say(error.localizedDescription) }
    }

    func removeMember(_ chatId: String, _ uid: String) async {
        do {
            try await API.shared.raw("DELETE", "/rest/v1/lm_members", query: [URLQueryItem(name: "chat_id", value: "eq." + chatId),
                                                                            URLQueryItem(name: "user_id", value: "eq." + uid)])
            await loadChats()
        } catch { say(error.localizedDescription) }
    }

    func setRole(_ chatId: String, _ uid: String, _ role: String) async {
        do { _ = try await API.shared.rpc("lm_set_role", ["p_chat": chatId, "p_user": uid, "p_role": role]) }
        catch { say(error.localizedDescription) }
    }

    func saveChat(_ chatId: String, title: String, description: String) async {
        do { try await API.shared.update("lm_chats", match: ["id": chatId], ["title": title, "description": description]); await loadChats() }
        catch { say(error.localizedDescription) }
    }

    func saveChatFull(_ chatId: String, title: String, description: String, isPublic: Bool, username: String?) async -> Bool {
        do {
            var vals: JSON = ["title": title, "description": description, "is_public": isPublic]
            vals["username"] = username ?? NSNull()
            try await API.shared.update("lm_chats", match: ["id": chatId], vals)
            await loadChats(); return true
        } catch { return false }
    }

    func setChatAvatar(_ chatId: String, _ image: UIImage) async {
        guard let data = Media.squareJPEG(image, side: 640) else { return }
        do {
            let url = try await API.shared.upload(data, ext: "jpg", contentType: "image/jpeg")
            try await API.shared.update("lm_chats", match: ["id": chatId], ["avatar_url": url])
            await loadChats()
        } catch { say(error.localizedDescription) }
    }

    func chatDetails(_ chatId: String) async -> JSON? {
        try? await API.shared.select("lm_chats", ["select": "*", "id": "eq." + chatId]).first
    }

    // MARK: - звонки (история)

    func loadCalls() async {
        let rows = (try? await API.shared.select("lm_messages", ["select": "*", "kind": "eq.call", "order": "id.desc", "limit": "100"])) ?? []
        calls = rows.map { Message(json: $0) }
    }

    // MARK: - истории

    func loadStories() async {
        guard let rows = (try? await API.shared.rpc("lm_stories_feed")) as? [JSON] else { return }
        var by: [String: StoryGroup] = [:]
        for r in rows {
            let s = StoryItem(json: r)
            if by[s.userId] == nil {
                by[s.userId] = StoryGroup(userId: s.userId, name: s.name, avatarURL: s.avatarURL, color: s.color, items: [], unseen: false, last: s.createdAt)
            }
            by[s.userId]?.items.append(s)
        }
        var groups: [StoryGroup] = by.values.map { g in
            var g = g
            g.items.sort { $0.createdAt < $1.createdAt }
            g.unseen = g.userId != myId && g.items.contains { !$0.seen }
            g.last = g.items.last?.createdAt ?? g.last
            if let a = aliases[g.userId], !a.isEmpty { g.name = a }
            return g
        }
        groups.sort { a, b in
            if a.userId == myId { return true }
            if b.userId == myId { return false }
            if a.unseen != b.unseen { return a.unseen }
            return a.last > b.last
        }
        stories = groups
    }

    func addStory(kind: String, data: Data, ext: String, contentType: String, caption: String, meta: JSON, hours: Int = 24, aud: String = "all", allow: [String] = []) async -> Bool {
        do {
            let url = try await API.shared.upload(data, ext: ext, contentType: contentType)
            _ = try await API.shared.rpc("lm_story_add2", ["p_kind": kind, "p_url": url, "p_caption": caption, "p_meta": meta, "p_hours": hours, "p_aud": aud, "p_allow": allow])
            await loadStories()
            say("История опубликована")
            return true
        } catch { say("Ошибка: " + error.localizedDescription); return false }
    }

    func viewStory(_ s: StoryItem) {
        guard s.userId != myId, !s.seen else { return }
        Task { _ = try? await API.shared.rpc("lm_story_view", ["p_id": s.id]) }
        for gi in stories.indices {
            if let ii = stories[gi].items.firstIndex(where: { $0.id == s.id }) {
                stories[gi].items[ii].seen = true
                stories[gi].unseen = stories[gi].items.contains { !$0.seen }
            }
        }
    }

    func reactStory(_ s: StoryItem) async {
        _ = try? await API.shared.rpc("lm_story_react", ["p_id": s.id, "p_emoji": "❤️"])
        say("Реакция отправлена")
    }

    func deleteStory(_ s: StoryItem) async {
        do { _ = try await API.shared.rpc("lm_story_delete", ["p_id": s.id]); await loadStories(); say("История удалена") }
        catch { say(error.localizedDescription) }
    }

    func storyViewers(_ s: StoryItem) async -> [JSON] {
        (try? await API.shared.rpc("lm_story_viewers", ["p_id": s.id])) as? [JSON] ?? []
    }

    func replyStory(_ s: StoryItem, text: String) async {
        do {
            guard let cid = try await API.shared.rpc("lm_open_dm", ["p_other": s.userId]) as? String, let me = myId else { return }
            let body = "Ответ на историю" + (s.caption.isEmpty ? "" : " «" + String(s.caption.prefix(60)) + "»") + ":\n" + text
            _ = try await API.shared.insert("lm_messages", ["chat_id": cid, "sender_id": me, "kind": "text", "body": body,
                                                             "meta": ["story": ["id": s.id, "kind": s.kind, "url": s.mediaURL] as JSON]])
            say("Ответ отправлен")
        } catch { say(error.localizedDescription) }
    }

    // MARK: - вход на компьютере по QR-коду

    func approveQR(key: String) async {
        let ch = Realtime.shared.channel("lm-qr-" + key)
        var result: String?
        ch.onBroadcast = { ev, p in
            if ev == "qr", let t = p.str("t"), t == "ok" || t == "fail" { result = t }
        }
        await Realtime.shared.waitJoined(ch)
        Realtime.shared.broadcast(ch, event: "qr", payload: ["t": "scan"])
        do {
            let j = try await API.shared.function("/qr", body: [:]) as? JSON
            guard let th = j?.str("th") else { throw APIError(message: "Не удалось подтвердить вход", status: 0) }
            Realtime.shared.broadcast(ch, event: "qr", payload: ["t": "login", "th": th])
            for _ in 0..<30 where result == nil { try? await Task.sleep(nanoseconds: 500_000_000) }
            say(result == "ok" ? "Готово! Вы вошли на компьютере" : result == "fail" ? "Не получилось — обновите QR-код на компьютере" : "Компьютер не ответил — отсканируйте код заново")
        } catch {
            say(error.localizedDescription)
        }
        Realtime.shared.leave("lm-qr-" + key)
    }

    func cancelQR(key: String) async {
        let ch = Realtime.shared.channel("lm-qr-" + key)
        await Realtime.shared.waitJoined(ch)
        Realtime.shared.broadcast(ch, event: "qr", payload: ["t": "cancel"])
        Realtime.shared.leave("lm-qr-" + key)
    }

    // MARK: - сообщения

    /// Расшифровать сообщение личного чата (ключ чата уже подготовлен через prep)
    func dec(_ m: Message) -> Message {
        guard E2E.isEnc(m.body) else { return m }
        var x = m
        x.body = E2E.shared.decrypt(m.chatId, m.body)
        x.enc = true
        return x
    }

    func prep(_ chatId: String) async {
        if chat(chatId) == nil { await loadChats() }
        guard let c = chat(chatId), c.isPrivate else { return }
        await E2E.shared.prepare(chatId, peer: c.peerId)
    }

    func loadMessages(_ chatId: String, older: Bool = false) async {
        guard let me = myId else { return }
        await prep(chatId)
        if cleared[chatId] == nil {
            let r = try? await API.shared.select("lm_members", ["select": "cleared_at", "chat_id": "eq." + chatId, "user_id": "eq." + me]).first
            cleared[chatId] = r?.date("cleared_at") ?? .distantPast
        }
        var q = ["select": "*", "chat_id": "eq." + chatId, "deleted": "eq.false", "order": "id.desc", "limit": "50"]
        if let c = cleared[chatId], c != .distantPast { q["created_at"] = "gt." + DateParser.string(c) }
        let current = messages[chatId] ?? []
        if older, let first = current.first(where: { $0.id > 0 }) { q["id"] = "lt.\(first.id)" }
        guard let rows = try? await API.shared.select("lm_messages", q) else { return }
        // сообщения, которые я удалил только у себя
        if let hr = try? await API.shared.select("lm_hidden", ["select": "message_id", "chat_id": "eq." + chatId]) {
            for r in hr { if let id = r.int("message_id") { hidden.insert(id) } }
        }
        let arr = Array(rows.map { dec(Message(json: $0)) }.reversed()).filter { !hidden.contains($0.id) }
        if older {
            let have = Set(current.map { $0.id })
            messages[chatId] = arr.filter { !have.contains($0.id) } + current
        } else {
            let pending = current.filter { $0.pending }
            messages[chatId] = arr + pending
        }
        hasMore[chatId] = rows.count == 50
        await loadProfiles(arr.compactMap { $0.senderId })
        let ids = arr.map { $0.id }
        if !ids.isEmpty {
            let rr = (try? await API.shared.select("lm_reactions", ["select": "message_id,user_id,emoji", "message_id": "in.(" + ids.map(String.init).joined(separator: ",") + ")"])) ?? []
            var map = reactions
            for id in ids { map[id] = [] }
            for r in rr { let x = Reaction(json: r); map[x.messageId, default: []].append(x) }
            let rx = (try? await API.shared.select("lm_reactions_extra", ["select": "message_id,user_id,emoji", "message_id": "in.(" + ids.map(String.init).joined(separator: ",") + ")"])) ?? []
            for r in rx { var x = Reaction(json: r); x.extra = true; map[x.messageId, default: []].append(x) }
            reactions = map
        }
        var need = arr.compactMap { $0.replyTo }
        if let pm = chat(chatId)?.pinnedMessageId { need.append(pm) }
        let missing = need.filter { rid in findMessage(rid, in: chatId) == nil }
        if !missing.isEmpty {
            let rr = (try? await API.shared.select("lm_messages", ["select": "*", "id": "in.(" + missing.map(String.init).joined(separator: ",") + ")"])) ?? []
            for r in rr { let m = dec(Message(json: r)); replyCache[m.id] = m }
            await loadProfiles(rr.compactMap { $0.str("sender_id") })
        }
    }

    func findMessage(_ id: Int, in chatId: String) -> Message? {
        (messages[chatId] ?? []).first { $0.id == id } ?? replyCache[id]
    }

    func searchMessages(_ chatId: String, _ q: String) async -> [Message] {
        if chat(chatId)?.isPrivate == true {
            // личные чаты зашифрованы: ищем на устройстве среди последних сообщений
            await prep(chatId)
            let all = (try? await API.shared.select("lm_messages", ["select": "*", "chat_id": "eq." + chatId, "deleted": "eq.false", "order": "id.desc", "limit": "600"])) ?? []
            let needle = q.lowercased()
            let found = all.map { dec(Message(json: $0)) }
                .filter { $0.kind != "system" && $0.kind != "call" && ($0.body ?? "").lowercased().contains(needle) }
                .prefix(60)
            for m in found { replyCache[m.id] = m }
            return Array(found)
        }
        let rows = (try? await API.shared.select("lm_messages", ["select": "*", "chat_id": "eq." + chatId, "deleted": "eq.false",
                                                                 "body": "ilike.*" + q + "*", "order": "id.desc", "limit": "60"])) ?? []
        let list = rows.map { Message(json: $0) }
        for m in list { replyCache[m.id] = m }
        return list
    }

    func markRead(_ chatId: String) {
        guard let me = myId, isActive, let list = messages[chatId], let last = list.last(where: { $0.id > 0 }) else { return }
        if let c = chat(chatId), c.unread == 0, let lr = c.lastReadAt, lr >= last.createdAt { return }
        let ts = DateParser.string(last.createdAt.addingTimeInterval(0.001))
        if let i = chats.firstIndex(where: { $0.id == chatId }) {
            chats[i].unread = 0
            chats[i].lastReadAt = last.createdAt.addingTimeInterval(0.001)
        }
        Notifier.setBadge(chats.filter { !$0.muted }.reduce(0) { $0 + $1.unread })
        Notifier.clear(chat: chatId)
        Task { try? await API.shared.update("lm_members", match: ["chat_id": chatId, "user_id": me], ["last_read_at": ts]) }
    }

    @discardableResult
    func send(chatId: String, kind: String, body: String? = nil, media: String? = nil, meta: JSON = [:],
              replyTo: Int? = nil, forwardedFrom: String? = nil, pendingId: Int? = nil) async -> Bool {
        guard let me = myId else { return false }
        let pid: Int
        if let p = pendingId { pid = p } else {
            let temp = Message(pendingIn: chatId, sender: me, kind: kind, body: body, meta: meta, replyTo: replyTo)
            pid = temp.id
            messages[chatId, default: []].append(temp)
        }
        func insertRow() async throws -> JSON? {
            var wire = body
            if kind == "text", let b = body {
                await prep(chatId)
                if let e = E2E.shared.encrypt(chatId, b) { wire = e }
            }
            var row: JSON = ["chat_id": chatId, "sender_id": me, "kind": kind, "meta": meta]
            if let b = wire { row["body"] = b }
            if let u = media { row["media_url"] = u }
            if let r = replyTo { row["reply_to"] = r }
            if let f = forwardedFrom { row["forwarded_from"] = f }
            return try await API.shared.insert("lm_messages", row)
        }
        do {
            var savedRow: JSON?
            do { savedRow = try await insertRow() }
            catch let e as APIError where e.message.contains("зашифровано") {
                // у собеседника только что появился ключ — обновляем и пробуем ещё раз
                E2E.shared.dropCaches()
                savedRow = try await insertRow()
            }
            guard let saved = savedRow else { throw APIError(message: "Не отправлено", status: 0) }
            let m = dec(Message(json: saved))
            var list = messages[chatId] ?? []
            list.removeAll { $0.id == pid }
            if !list.contains(where: { $0.id == m.id }) { list.append(m) }
            messages[chatId] = sorted(list)
            scheduleReload()
            return true
        } catch {
            messages[chatId]?.removeAll { $0.id == pid }
            say("Не отправлено: " + error.localizedDescription)
            return false
        }
    }

    /// Отправка файла: сначала в списке появляется заглушка, потом файл загружается и сообщение уходит
    func sendMedia(chatId: String, kind: String, data: Data, ext: String, contentType: String, meta: JSON,
                   body: String? = nil, replyTo: Int? = nil, local: URL? = nil) {
        guard let me = myId else { return }
        let temp = Message(pendingIn: chatId, sender: me, kind: kind, body: body, meta: meta, replyTo: replyTo, local: local)
        messages[chatId, default: []].append(temp)
        Task {
            do {
                let url = try await API.shared.upload(data, ext: ext, contentType: contentType)
                await send(chatId: chatId, kind: kind, body: body, media: url, meta: meta, replyTo: replyTo, pendingId: temp.id)
            } catch {
                messages[chatId]?.removeAll { $0.id == temp.id }
                say("Ошибка загрузки: " + error.localizedDescription)
            }
        }
    }

    func forward(_ m: Message, to chatId: String, quiet: Bool = false) async {
        let from: String
        if let f = m.forwardedFrom, !f.isEmpty { from = f }
        else if let c = chat(m.chatId), c.isChannel { from = c.displayName }
        else { from = displayName(m.senderId) }
        let ok = await send(chatId: chatId, kind: m.kind, body: m.body, media: m.mediaURL, meta: m.meta, forwardedFrom: from)
        if ok && !quiet { say("Сообщение переслано") }
    }

    func delete(_ m: Message) async { await delete([m], everyone: true) }

    /// Удалить сообщения: у всех (исчезают у всех) или только у себя
    func delete(_ list: [Message], everyone: Bool) async {
        let ids = Set(list.map { $0.id }.filter { $0 > 0 })
        guard !ids.isEmpty, let chatId = list.first?.chatId else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            messages[chatId] = (messages[chatId] ?? []).filter { !ids.contains($0.id) }
        }
        do {
            for id in ids {
                if everyone {
                    try await API.shared.update("lm_messages", match: ["id": String(id)], ["deleted": true])
                } else {
                    hidden.insert(id)
                    try await API.shared.raw("POST", "/rest/v1/lm_hidden", body: ["message_id": id, "chat_id": chatId],
                                             headers: ["Prefer": "resolution=ignore-duplicates,return=minimal"])
                }
            }
            if chat(chatId)?.pinnedMessageId.map({ ids.contains($0) }) == true && everyone { try? await API.shared.update("lm_chats", match: ["id": chatId], ["pinned_message_id": NSNull()]) }
            scheduleReload()
        } catch { say(error.localizedDescription); await loadMessages(chatId) }
    }

    func edit(_ m: Message, text: String) async {
        await prep(m.chatId)
        let wire = m.kind == "text" ? (E2E.shared.encrypt(m.chatId, text) ?? text) : text
        do { try await API.shared.update("lm_messages", match: ["id": String(m.id)], ["body": wire, "edited_at": DateParser.string(Date())]) }
        catch { say(error.localizedDescription) }
    }

    func pin(_ m: Message?, in chatId: String) async {
        do {
            try await API.shared.update("lm_chats", match: ["id": chatId], ["pinned_message_id": m.map { $0.id as Any } ?? NSNull()])
            if let m = m { replyCache[m.id] = m }
            await loadChats()
            say(m == nil ? "Сообщение откреплено" : "Сообщение закреплено")
        } catch { say(error.localizedDescription) }
    }

    func react(_ m: Message, _ emoji: String) async {
        guard let me = myId, m.id > 0 else { return }
        let list = reactions[m.id] ?? []
        let mine = list.filter { $0.userId == me }
        let others = list.filter { $0.userId != me }
        func delRow(_ table: String, _ e: String?) async {
            var q = [URLQueryItem(name: "message_id", value: "eq.\(m.id)"), URLQueryItem(name: "user_id", value: "eq." + me)]
            if let e = e { q.append(URLQueryItem(name: "emoji", value: "eq." + e)) }
            try? await API.shared.raw("DELETE", "/rest/v1/" + table, query: q)
        }
        if let had = mine.first(where: { $0.emoji == emoji }) {
            reactions[m.id] = others + mine.filter { $0.emoji != emoji }
            await delRow(had.extra ? "lm_reactions_extra" : "lm_reactions", emoji)
            return
        }
        let row: JSON = ["message_id": m.id, "user_id": me, "chat_id": m.chatId, "emoji": emoji]
        do {
            if !isPremium {
                // бесплатно: одна реакция, новая заменяет прежнюю
                reactions[m.id] = others + [Reaction(messageId: m.id, userId: me, emoji: emoji)]
                try await API.shared.raw("POST", "/rest/v1/lm_reactions", query: [URLQueryItem(name: "on_conflict", value: "message_id,user_id")],
                                         body: row, headers: ["Prefer": "resolution=merge-duplicates,return=minimal"])
                return
            }
            if mine.count >= 3 { say("Можно поставить не больше 3 реакций"); return }
            if !mine.contains(where: { !$0.extra }) {
                reactions[m.id] = others + mine + [Reaction(messageId: m.id, userId: me, emoji: emoji)]
                try await API.shared.raw("POST", "/rest/v1/lm_reactions", query: [URLQueryItem(name: "on_conflict", value: "message_id,user_id")],
                                         body: row, headers: ["Prefer": "resolution=merge-duplicates,return=minimal"])
            } else {
                reactions[m.id] = others + mine + [Reaction(messageId: m.id, userId: me, emoji: emoji, extra: true)]
                try await API.shared.raw("POST", "/rest/v1/lm_reactions_extra", body: row, headers: ["Prefer": "return=minimal"])
            }
        } catch {
            reactions[m.id] = list
            say(error.localizedDescription)
        }
    }

    // MARK: обои чатов

    @Published var chatWalls: [String: ChatWall] = [:]

    func loadChatWalls() async {
        guard let me = myId else { return }
        let rows = (try? await API.shared.select("lm_chat_wall", ["select": "chat_id,preset,url,blur,dim,set_by", "user_id": "eq." + me])) ?? []
        var map: [String: ChatWall] = [:]
        for r in rows {
            guard let cid = r.str("chat_id") else { continue }
            map[cid] = ChatWall(preset: r.int("preset"), url: r.str("url"), blur: r.bool("blur"), dim: r.int("dim") ?? 0, setBy: r.str("set_by"))
        }
        chatWalls = map
    }

    func setWall(chat: String, preset: Int?, url: String?, blur: Bool, dim: Int, both: Bool) async -> Bool {
        var p: JSON = ["p_chat": chat, "p_blur": blur, "p_dim": dim, "p_both": both]
        p["p_preset"] = preset.map { $0 as Any } ?? NSNull()
        p["p_url"] = url.map { $0 as Any } ?? NSNull()
        do { _ = try await API.shared.rpc("lm_set_wall", p); await loadChatWalls(); return true }
        catch { say(error.localizedDescription); return false }
    }

    func clearWall(chat: String) async {
        guard let me = myId else { return }
        chatWalls[chat] = nil
        try? await API.shared.raw("DELETE", "/rest/v1/lm_chat_wall", query: [URLQueryItem(name: "chat_id", value: "eq." + chat), URLQueryItem(name: "user_id", value: "eq." + me)])
    }

    private func sorted(_ list: [Message]) -> [Message] {
        let real = list.filter { $0.id > 0 }.sorted { $0.id < $1.id }
        let pend = list.filter { $0.id <= 0 }
        return real + pend
    }

    // MARK: - «печатает…»

    /// «печатает…» слушаем во всех недавних чатах — чтобы видеть его и в списке чатов
    private func syncTypingChannels() {
        guard loggedIn, myId != nil else { return }
        var want = Set(chats.prefix(40).map { $0.id })
        if let o = openChatId { want.insert(o) }
        for (id, _) in typingChannels where !want.contains(id) {
            Realtime.shared.leave("lm-typing-" + id)
            typingChannels[id] = nil
        }
        for id in want where typingChannels[id] == nil { typingChannels[id] = makeTypingChannel(id) }
    }

    private func makeTypingChannel(_ id: String) -> Realtime.Channel {
        let ch = Realtime.shared.channel("lm-typing-" + id)
        ch.onBroadcast = { [weak self] ev, p in
            guard ev == "typing", let self = self, let uid = p.str("uid"), uid != self.myId else { return }
            self.typingAct[id + uid] = p.str("act") ?? "typing"
            if p.str("act") == "stop" { self.typing[id]?[uid] = nil; return }
            self.typing[id, default: [:]][uid] = p.str("name") ?? ""
            self.typingClear[id + uid]?.cancel()
            self.typingClear[id + uid] = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if Task.isCancelled { return }
                self?.typing[id]?[uid] = nil
            }
        }
        return ch
    }

    /// Сообщить собеседникам: печатаю («typing»), записываю голосовое («voice») или кружок («video»), закончил («stop»)
    func userTyping(_ chatId: String, act: String = "typing") {
        guard let me = self.me else { return }
        let ch = typingChannels[chatId] ?? makeTypingChannel(chatId)
        typingChannels[chatId] = ch
        guard act != lastTypingAct || act == "stop" || Date().timeIntervalSince(lastTypingSent) > 2.5 else { return }
        lastTypingSent = Date()
        lastTypingAct = act
        Realtime.shared.broadcast(ch, event: "typing", payload: ["uid": me.id, "name": me.name, "act": act])
    }

    func typingText(_ chatId: String) -> String? {
        guard let t = typing[chatId], !t.isEmpty else { return nil }
        func verb(_ uid: String) -> String {
            switch typingAct[chatId + uid] {
            case "voice": return "записывает голосовое…"
            case "video": return "записывает видеосообщение…"
            default: return "печатает…"
            }
        }
        if chat(chatId)?.isPrivate == true, let u = t.keys.first { return verb(u) }
        if t.count == 1, let u = t.keys.first { return displayName(u) + " " + verb(u) }
        let names = t.keys.map { displayName($0) }.prefix(2)
        return names.joined(separator: ", ") + " печатают…"
    }

    // MARK: - живые обновления

    private func onDB(_ d: JSON) {
        let table = d.str("table") ?? ""
        let type = d.str("type") ?? ""
        let rec = d.dict("record")
        switch table {
        case "lm_messages":
            let m0 = Message(json: rec)
            guard m0.id > 0, !m0.chatId.isEmpty else { return }
            Task { @MainActor in
                if E2E.isEnc(m0.body) { await self.prep(m0.chatId) }
                let m = self.dec(m0)
                if type == "INSERT" { self.incoming(m) }
                else if type == "UPDATE" {
                    if var list = self.messages[m.chatId], let i = list.firstIndex(where: { $0.id == m.id }) {
                        if m.deleted { list.remove(at: i) } else { list[i] = m }
                        withAnimation(.easeOut(duration: 0.25)) { self.messages[m.chatId] = list }
                    }
                    if self.replyCache[m.id] != nil { self.replyCache[m.id] = m }
                    if m.kind == "call" { Task { await self.loadCalls() } }
                    self.scheduleReload()
                }
            }
        case "lm_members":
            scheduleReload()
        case "lm_reactions", "lm_reactions_extra":
            let isExtra = table == "lm_reactions_extra"
            if type == "DELETE" {
                let old = d.dict("old_record")
                if let mid = old.int("message_id"), let uid = old.str("user_id"), uid != myId {
                    let e = old.str("emoji")
                    reactions[mid]?.removeAll { $0.userId == uid && $0.extra == isExtra && (e == nil || $0.emoji == e) }
                }
            } else {
                var r = Reaction(json: rec)
                r.extra = isExtra
                guard r.messageId > 0, r.userId != myId else { return }
                var list = reactions[r.messageId] ?? []
                if !isExtra { list.removeAll { $0.userId == r.userId && !$0.extra } }
                list.removeAll { $0.userId == r.userId && $0.emoji == r.emoji }
                list.append(r)
                reactions[r.messageId] = list
            }
        case "lm_chat_wall":
            Task { await loadChatWalls() }
        default:
            break
        }
    }

    private func incoming(_ m: Message) {
        if var list = messages[m.chatId], !list.contains(where: { $0.id == m.id }) {
            if m.senderId == myId, let i = list.firstIndex(where: { $0.pending && $0.kind == m.kind && $0.body == m.body }) {
                list.remove(at: i)
            }
            list.append(m)
            messages[m.chatId] = sorted(list)
        }
        if let s = m.senderId { typing[m.chatId]?[s] = nil }
        if m.kind == "call" { Task { await loadCalls() } }
        scheduleReload()
        guard m.senderId != myId, m.kind != "system" else { return }
        if let sid = m.senderId, profiles[sid] == nil { Task { _ = await profile(sid) } }
        let visible = isActive && openChatId == m.chatId
        if isActive && m.kind != "call" && chat(m.chatId)?.muted != true { playIncomingSound() }
        if visible {
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000)
                self?.markRead(m.chatId)
            }
            return
        }
        // звонок, который ещё идёт, показывает экран звонка — отдельное уведомление не нужно
        if m.kind == "call" && (m.metaStatus == nil || m.metaStatus == "ended" || m.metaStatus == "rejected") { return }
        guard !notified.contains(m.id) else { return }
        notified.insert(m.id)
        Task {
            if chat(m.chatId) == nil { await loadChats() }
            let c = chat(m.chatId)
            if c?.muted == true { return }
            if let sid = m.senderId { _ = await profile(sid) }
            let senderName = displayName(m.senderId)
            let title: String
            var body = m.preview
            if m.kind == "call" { body = m.isVideoCall ? "Пропущенный видеозвонок" : "Пропущенный звонок" }
            if c?.isPrivate ?? true { title = senderName }
            else if c?.isChannel == true { title = c?.displayName ?? "Канал" }
            else { title = c?.displayName ?? "Группа"; body = senderName + ": " + body }
            Notifier.show(id: "m\(m.id)", title: title, body: body, chatId: m.chatId)
        }
    }
}

extension AppModel {
    /// Короткий звук нового сообщения, когда Lumo открыт (с беззвучным режимом iPhone не звучит)
    func playIncomingSound() {
        let now = Date()
        guard now.timeIntervalSince(AppModel.lastSound) > 0.8, CallManager.shared.state == .idle else { return }
        AppModel.lastSound = now
        AudioServicesPlaySystemSound(1003)
    }
    static var lastSound = Date.distantPast
}

// MARK: - примерные данные для скриншотов (запуск с LUMO_SNAPSHOT)

extension AppModel {
    func loadDemo(_ mode: String) {
        let me = "00000000-0000-0000-0000-000000000001"
        let ann = "00000000-0000-0000-0000-000000000002"
        let max = "00000000-0000-0000-0000-000000000003"
        let kate = "00000000-0000-0000-0000-000000000004"
        demoUser = me
        started = true
        demo = mode
        let now = Date()
        func iso(_ s: Double) -> String { DateParser.string(now.addingTimeInterval(-s)) }
        self.me = Profile(json: ["id": me, "name": "Вы", "username": "me", "color": 1])
        profiles[me] = self.me
        profiles[ann] = Profile(json: ["id": ann, "name": "Анна Смирнова", "username": "anna_sm", "color": 0,
                                       "bio": "Люблю путешествия и кофе", "last_seen": iso(30)])
        profiles[max] = Profile(json: ["id": max, "name": "Максим", "username": "maxim", "color": 2, "last_seen": iso(600)])
        profiles[kate] = Profile(json: ["id": kate, "name": "Катя", "username": "katya", "color": 5, "last_seen": iso(3600)])
        online = [ann]
        chats = [
            ChatItem(json: ["chat_id": "c1", "type": "private", "peer_id": ann, "peer_name": "Анна Смирнова", "peer_username": "anna_sm",
                            "peer_color": 0, "last_id": 5, "last_kind": "text", "last_body": "До встречи!", "last_sender": ann,
                            "last_at": iso(60), "unread": 2, "role": "member"]),
            ChatItem(json: ["chat_id": "c2", "type": "private", "peer_id": max, "peer_name": "Максим", "peer_username": "maxim",
                            "peer_color": 2, "last_id": 9, "last_kind": "voice", "last_sender": max, "last_at": iso(900), "role": "member"]),
            ChatItem(json: ["chat_id": "c3", "type": "group", "title": "Друзья", "color": 3, "members_count": 5,
                            "last_id": 12, "last_kind": "text", "last_body": "Кто идёт в кино?", "last_sender": kate,
                            "last_sender_name": "Катя", "last_at": iso(3000), "unread": 4, "role": "member"]),
            ChatItem(json: ["chat_id": "c4", "type": "private", "peer_id": kate, "peer_name": "Катя", "peer_username": "katya",
                            "peer_color": 5, "last_id": 20, "last_kind": "video_note", "last_sender": me, "last_at": iso(7200), "role": "member"]),
        ]
        chatsLoaded = true
        typing["c2"] = [max: "Максим"]
        let texts: [(String, String, Double)] = [
            (ann, "Привет! Как дела?", 900), (me, "Привет! Всё отлично, а у тебя?", 840),
            (ann, "Тоже хорошо. Завтра встречаемся в 7?", 700), (me, "Да, договорились", 650),
            (ann, "Отлично, тогда до завтра", 120), (ann, "До встречи!", 60),
        ]
        messages["c1"] = texts.enumerated().map { i, t in
            Message(json: ["id": i + 1, "chat_id": "c1", "sender_id": t.0, "kind": "text", "body": t.1, "created_at": iso(t.2)])
        }
        hasMore["c1"] = false
        loggedIn = true
        if mode != "list" && mode != "incoming" && mode != "me" && mode != "edit" && mode != "privacy" { path = ["c1"] }
        if mode == "edit" { tab = .settings; settingsPath = [.profileEdit] }
        if mode == "privacy" { tab = .settings; settingsPath = [.privacy] }
        if mode == "me" { tab = .settings; settingsPath = [.profile]; profiles[me]?.bio = "Lumo — бета-версия"; self.me = profiles[me] }
        if mode == "incoming" { CallManager.shared.demoIncoming(name: "Анна Смирнова") }
    }
}
