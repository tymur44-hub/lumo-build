package ru.volshebnymir.lumo.core

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.util.Date

/** Экраны приложения (свой простой стек навигации) */
sealed class Screen {
    data class Chat(val id: String) : Screen()
    data class Info(val chatId: String) : Screen()
    data class Person(val userId: String) : Screen()
    data object MyProfile : Screen()
    data object EditProfile : Screen()
    data object Appearance : Screen()
    data object About : Screen()
    data object NewChat : Screen()
    data object CallsHistory : Screen()
    data object Notifications : Screen()
    data object Privacy : Screen()
    data object Blocked : Screen()
    data class ChatSearch(val chatId: String) : Screen()
    data class PrivacyKey(val key: String) : Screen()
    data object EditUsername : Screen()
    data object EditColor : Screen()
    data object Premium : Screen()
    data object MsgPrivacy : Screen()
}

enum class Tab { Contacts, Chats, Settings }

/** Состояние приложения: вход, чаты, сообщения, живые обновления. Всё меняется на главном потоке. */
object AppModel {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    lateinit var ctx: Context

    var loggedIn by mutableStateOf(false)
    var me by mutableStateOf<Profile?>(null)
    val chats = mutableStateListOf<ChatItem>()
    var chatsLoaded by mutableStateOf(false)
    val messages = mutableStateMapOf<String, List<Message>>()
    val hasMore = mutableStateMapOf<String, Boolean>()
    val profiles = mutableStateMapOf<String, Profile>()
    val reactions = mutableStateMapOf<Int, List<Reaction>>()
    val typing = mutableStateMapOf<String, Map<String, String>>()
    val online = mutableStateMapOf<String, Boolean>()
    val contacts = mutableStateListOf<String>()
    val aliases = mutableStateMapOf<String, String>()
    var tab by mutableStateOf(Tab.Chats)
    val stack = mutableStateListOf<Screen>()
    var toast by mutableStateOf<String?>(null)
    var netStatus by mutableStateOf<String?>(null)
    var botName by mutableStateOf<String?>(null)
    var openChatId: String? = null
        set(v) { if (field != v) { field = v; syncTyping() } }
    var isActive = true
    var unreadTotal by mutableIntStateOf(0)

    private var started = false
    private val replyCache = mutableMapOf<Int, Message>()
    private val cleared = mutableMapOf<String, Date>()
    private val notified = mutableSetOf<Int>()
    private val typingChannels = mutableMapOf<String, Realtime.Channel>()
    private val typingClear = mutableMapOf<String, Job>()
    private var lastTypingSent = 0L
    private var reloadJob: Job? = null
    private var toastJob: Job? = null
    private var netJob: Job? = null
    private var onlineChannel: Realtime.Channel? = null
    private var presenceJob: Job? = null

    var demoId: String? = null
    val myId: String? get() = Api.userId ?: demoId

    fun init(c: Context) {
        if (::ctx.isInitialized) return
        ctx = c.applicationContext
        Notifier.setup(ctx)
        Calls.init(ctx)
        Api.init(ctx)
        E2E.init(ctx)
        loggedIn = Api.session != null
        Api.onSession = { s ->
            scope.launch {
                if (s != null) Realtime.updateToken(s.access) else if (loggedIn) resetAfterLogout()
            }
        }
    }

    var openUrl: ((String) -> Unit)? = null

    /** Открытое мини-приложение бота */
    var miniApp by mutableStateOf<MiniAppReq?>(null)
    /** Кнопка мини-приложения у бота: id бота → (текст, адрес) */
    val botMenus = mutableStateMapOf<String, Pair<String, String>?>()

    suspend fun loadBotMenu(botId: String) {
        if (botMenus.containsKey(botId)) return
        val j = runCatching { Api.rpc("lm_bot_info", jsonOf("p_id" to botId)) as? JSONObject }.getOrNull()
        val u = j?.str("web_app_url")
        botMenus[botId] = if (u != null) (j?.str("menu_text") ?: "Открыть") to u else null
    }

    /** «Создать бота»: открывает конструктор в BotFather */
    suspend fun openBotFather() {
        val r = search("botfather").firstOrNull { it.username == "botfather" }
        if (r == null) { say("Конструктор ботов пока недоступен"); return }
        miniApp = MiniAppReq(r.id, null)
    }

    /** Нажатие кнопки под сообщением бота */
    fun botPress(m: Message, b: BotBtn) {
        if (!b.webApp.isNullOrEmpty() && m.senderId != null) { miniApp = MiniAppReq(m.senderId, b.webApp); return }
        if (!b.url.isNullOrEmpty()) { openUrl?.invoke(b.url); return }
        val d = b.data ?: return
        scope.launch {
            try {
                val r = Api.botFunction("/cb", JSONObject().put("message_id", m.id).put("data", d)) as? JSONObject
                r?.str("toast")?.let { say(it) }
            } catch (e: Exception) { say("Не удалось выполнить действие") }
        }
    }

    fun say(text: String) {
        toast = text
        toastJob?.cancel()
        toastJob = scope.launch { delay(2600); toast = null }
    }

    fun push(s: Screen) { stack.add(s) }
    fun pop(): Boolean { if (stack.isEmpty()) return false; stack.removeAt(stack.size - 1); return true }

    fun chat(id: String) = chats.firstOrNull { it.id == id }
    /** В сети — если человек разрешил мне видеть время захода */
    fun isOnline(uid: String?) = uid != null && profiles[uid]?.isBot != true && online[uid] == true && (uid == myId || profiles[uid]?.showSeen != false)
    fun displayName(uid: String?): String {
        if (uid == null) return "Lumo"
        if (uid == myId) return me?.name ?: "Вы"
        aliases[uid]?.takeIf { it.isNotEmpty() }?.let { return it }
        return profiles[uid]?.name ?: "Пользователь"
    }

    fun lastSeenText(uid: String?, fallback: Date? = null): String {
        if (uid != null && profiles[uid]?.isBot == true) return "бот"
        if (isOnline(uid)) return "в сети"
        val p = uid?.let { profiles[it] }
        // самое свежее время из профиля и из списка чатов
        val d = listOfNotNull(p?.lastSeen, fallback).maxOrNull()
        return Fmt.lastSeen(d, p?.showSeen ?: true)
    }

    // ---------- запуск и вход ----------

    fun start() {
        if (!loggedIn || started || demoId != null) return
        started = true
        scope.launch {
            netStatus = "Соединение…"
            Realtime.onState = { ok -> netChanged(ok) }
            loadMe()
            myId?.let { E2E.setup(it) }
            netStatus = "Обновление…"
            loadContacts()
            loadChats()
            loadChatWalls()
            Realtime.connect()
            netStatus = null
            if (!Realtime.isOpen) netChanged(false)
            val db = Realtime.channel("lm-db", JSONArray()
                .put(jsonOf("event" to "INSERT", "schema" to "public", "table" to "lm_messages"))
                .put(jsonOf("event" to "UPDATE", "schema" to "public", "table" to "lm_messages"))
                .put(jsonOf("event" to "*", "schema" to "public", "table" to "lm_members"))
                .put(jsonOf("event" to "*", "schema" to "public", "table" to "lm_reactions"))
                .put(jsonOf("event" to "*", "schema" to "public", "table" to "lm_reactions_extra"))
                .put(jsonOf("event" to "*", "schema" to "public", "table" to "lm_chat_wall")))
            db.onChange = { onDB(it) }
            Realtime.onReconnect = {
                scope.launch {
                    netStatus = "Обновление…"
                    loadChats()
                    openChatId?.let { loadMessages(it) }
                    if (Realtime.isOpen) netStatus = null
                }
            }
            myId?.let { id ->
                val oc = Realtime.channel("lm-online", presenceKey = id)
                oc.onPresenceState = { st -> online.clear(); st.keys().forEach { online[it] = true } }
                oc.onPresenceDiff = { joins, leaves ->
                    joins.keys().forEach { online[it] = true }
                    leaves.keys().forEach { k ->
                        if (!joins.has(k)) {
                            online.remove(k)
                            // только что вышел из сети — запоминаем время
                            profiles[k]?.let { profiles[k] = it.copy(lastSeen = Date()) }
                            chats.indexOfFirst { it.peerId == k }.takeIf { it >= 0 }?.let { i -> chats[i] = chats[i].copy(peerLastSeen = Date()) }
                        }
                    }
                }
                Realtime.track(oc, jsonOf("at" to System.currentTimeMillis()))
                onlineChannel = oc
                CallsBridge.attach(id)
            }
            presence(true)
            presenceJob?.cancel()
            presenceJob = scope.launch { while (true) { delay(45_000); if (isActive) presence(true) } }
            botName = (runCatching { Api.function("/config", auth = false) }.getOrNull() as? JSONObject)?.str("bot")
            if (keepAlive) LumoService.start(ctx)
            loadExtras(); loadBlocks(); loadStories()
        }
    }

    suspend fun login(username: String, password: String) {
        Api.signIn(username.lowercase(), password)
        loggedIn = true
        start()
    }

    suspend fun register(username: String, password: String, name: String) {
        Api.register(username.lowercase(), password, name)
        loggedIn = true
        start()
    }

    /** Вход через Telegram: true — вошли, false — ещё ждём */
    suspend fun telegramCheck(key: String): Boolean {
        val j = Api.function("/tglogin", jsonOf("key" to key), auth = false) as? JSONObject ?: JSONObject()
        val th = j.str("th")
        if (th != null) {
            Api.verifyMagic(th)
            loggedIn = true
            start()
            if (j.bool("new")) say("Аккаунт создан: @" + (j.str("username") ?: "") + " — имя и юзернейм можно поменять в настройках")
            return true
        }
        if (j.str("error") == "expired") throw ApiError("Ссылка устарела — нажмите кнопку ещё раз", 0)
        return false
    }

    suspend fun telegramBot(): String? {
        if (botName == null) botName = (runCatching { Api.function("/config", auth = false) }.getOrNull() as? JSONObject)?.str("bot")
        return botName
    }

    fun logout() {
        scope.launch {
            presence(false)
            Api.signOut()
            resetAfterLogout()
        }
    }

    fun resetAfterLogout() {
        LumoService.stop(ctx)
        CallsBridge.detach()
        Realtime.disconnect()
        presenceJob?.cancel()
        typingChannels.clear()
        onlineChannel = null
        started = false
        loggedIn = false
        E2E.forget()
        me = null
        chats.clear(); messages.clear(); profiles.clear(); reactions.clear(); stack.clear(); contacts.clear(); aliases.clear()
        chatsLoaded = false
        netStatus = null
        stories.clear(); calls.clear(); blockedByMe.clear(); blockedMe.clear(); staffRole = null; tgLinked = false
    }

    private fun netChanged(ok: Boolean) {
        netJob?.cancel()
        if (ok) { if (netStatus == "Соединение…") netStatus = null; return }
        netJob = scope.launch { delay(900); if (loggedIn && !Realtime.isOpen) netStatus = "Соединение…" }
    }

    fun foreground(active: Boolean) {
        isActive = active
        if (!loggedIn || demoId != null) return
        if (active) {
            scope.launch { Net.pick() }
            Realtime.ensure()
            onlineChannel?.let { Realtime.track(it, jsonOf("at" to System.currentTimeMillis())) }
            presence(true)
            scope.launch {
                loadChats()
                openChatId?.let { loadMessages(it); markRead(it) }
            }
            Notifier.clearAll(ctx)
        } else {
            onlineChannel?.let { Realtime.untrack(it) }
            presence(false)
        }
    }

    private fun presence(on: Boolean) { scope.launch { runCatching { Api.rpc("lm_presence", jsonOf("p_active" to on)) } } }

    // ---------- профиль ----------

    /** Профили с учётом настроек конфиденциальности (сервер скрывает то, что видеть нельзя) */
    private suspend fun fetchProfiles(ids: Collection<String>): List<Profile> =
        (runCatching { Api.rpc("lm_profiles_get", jsonOf("p_ids" to JSONArray(ids.distinct()))) }.getOrNull() as? JSONArray).objects().map { Profile.from(it) }

    suspend fun loadMe() {
        val id = myId ?: return
        fetchProfiles(listOf(id)).firstOrNull()?.let { me = it; profiles[id] = it }
    }

    suspend fun loadProfiles(ids: Collection<String>) {
        val need = ids.filter { !profiles.containsKey(it) }.distinct()
        if (need.isEmpty()) return
        fetchProfiles(need).forEach { profiles[it.id] = it }
    }

    suspend fun refreshProfile(id: String) {
        fetchProfiles(listOf(id)).firstOrNull()?.let { profiles[id] = it }
    }

    suspend fun setUsername(username: String) {
        val u = username.trim().lowercase().removePrefix("@")
        if (u != me?.username) Api.rpc("lm_set_username", jsonOf("p_username" to u))
        loadMe()
    }

    suspend fun saveProfile(name: String, username: String, bio: String) {
        val id = myId ?: return
        setUsername(username)
        Api.update("lm_profiles", mapOf("id" to id), jsonOf("name" to name, "bio" to bio))
        loadMe()
    }

    /** Имя, фамилия, о себе, день рождения (yyyy-MM-dd или null) */
    suspend fun saveProfileFull(first: String, last: String, bio: String, birthday: String?) {
        val id = myId ?: return
        val full = listOf(first.trim(), last.trim()).filter { it.isNotEmpty() }.joinToString(" ")
        if (full.isEmpty()) throw ApiError("Укажите имя", 0)
        Api.update("lm_profiles", mapOf("id" to id), jsonOf("name" to full, "last_name" to last.trim(), "bio" to bio.trim(), "birthday" to birthday))
        loadMe()
    }

    suspend fun setColor(c: Int) { val id = myId ?: return; runCatching { Api.update("lm_profiles", mapOf("id" to id), jsonOf("color" to c)) }; loadMe() }

    suspend fun setChannel(chatId: String?) { val id = myId ?: return; runCatching { Api.update("lm_profiles", mapOf("id" to id), jsonOf("channel_id" to chatId)) }; loadMe() }

    suspend fun setPrivacyKey(key: String, value: String) {
        runCatching { Api.rpc("lm_set_privacy", jsonOf("p_key" to key, "p_value" to value)); loadMe() }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun setAvatar(bytes: ByteArray?) {
        val id = myId ?: return
        val url = bytes?.let { Api.upload(it, "jpg", "image/jpeg") }
        Api.update("lm_profiles", mapOf("id" to id), jsonOf("avatar_url" to url))
        loadMe()
    }

    suspend fun setPassword(pw: String) { Api.raw("PUT", "/auth/v1/user", body = jsonOf("password" to pw)) }

    // ---------- контакты ----------

    suspend fun loadContacts() {
        val rows = runCatching { Api.select("lm_contacts", mapOf("select" to "contact_id,alias,created_at", "order" to "created_at.desc")) }.getOrNull() ?: return
        contacts.clear(); contacts.addAll(rows.mapNotNull { it.str("contact_id") })
        aliases.clear(); rows.forEach { r -> val id = r.str("contact_id"); val a = r.str("alias"); if (id != null && !a.isNullOrEmpty()) aliases[id] = a }
        loadProfiles(contacts)
    }

    fun isContact(id: String) = contacts.contains(id)

    suspend fun addContact(id: String) {
        runCatching { Api.insertQuiet("lm_contacts", jsonOf("contact_id" to id)) }.onFailure { say(it.message ?: "Ошибка") }
        loadContacts(); say("Добавлено в контакты")
    }

    suspend fun removeContact(id: String) {
        runCatching { Api.delete("lm_contacts", mapOf("contact_id" to id)) }
        loadContacts(); say("Удалено из контактов")
    }

    suspend fun setAlias(id: String, alias: String) {
        runCatching { Api.rpc("lm_set_alias", jsonOf("p_user" to id, "p_alias" to alias)) }.onFailure { say(it.message ?: "Ошибка") }
        loadContacts(); loadChats()
    }

    // ---------- чаты ----------

    suspend fun loadChats() {
        if (!loggedIn) return
        try {
            val rows = (Api.rpc("lm_chats_v2") as? JSONArray).objects()
            val raw = rows.map { ChatItem.from(it) }
            E2E.prefetch(raw.filter { it.isPrivate }.mapNotNull { it.peerId })
            val list = raw.map { c ->
                val a = c.peerId?.let { aliases[it] }
                if (!a.isNullOrEmpty()) c.copy(peerName = a) else c
            }.map { c ->
                if (c.isPrivate && E2E.isEnc(c.lastBody)) { E2E.prepare(c.id, c.peerId); c.copy(lastBody = E2E.decrypt(c.id, c.lastBody)) } else c
            }.sortedWith(compareByDescending<ChatItem> { it.pinned }.thenByDescending { it.lastAt?.time ?: 0 })
            chats.clear(); chats.addAll(list)
            chatsLoaded = true
            unreadTotal = list.filter { !it.muted }.sumOf { it.unread }
            syncTyping()
            loadProfiles(list.mapNotNull { it.peerId })
        } catch (e: ApiError) {
            if (e.status == 401) Api.forget()
        } catch (_: Exception) {}
    }

    fun scheduleReload() {
        reloadJob?.cancel()
        reloadJob = scope.launch { delay(400); loadChats() }
    }

    fun open(chatId: String) {
        tab = Tab.Chats
        stack.clear()
        stack.add(Screen.Chat(chatId))
    }

    suspend fun openDM(userId: String) {
        try {
            val cid = Api.rpc("lm_open_dm", jsonOf("p_other" to userId)) as? String ?: return
            loadChats(); open(cid)
        } catch (e: Exception) { say(e.message ?: "Ошибка") }
    }

    suspend fun search(q: String): List<SearchResult> =
        (runCatching { Api.rpc("lm_search", jsonOf("q" to q)) }.getOrNull() as? JSONArray).objects().map { SearchResult.from(it) }

    suspend fun setMuted(chatId: String, on: Boolean) {
        runCatching { Api.update("lm_members", mapOf("chat_id" to chatId, "user_id" to (myId ?: "")), jsonOf("muted" to on)) }
        loadChats()
    }

    suspend fun join(chatId: String) {
        try { Api.rpc("lm_join", jsonOf("p_chat" to chatId)); loadChats(); open(chatId) } catch (e: Exception) { say(e.message ?: "Ошибка") }
    }

    // ---------- сообщения ----------

    /** Расшифровать сообщение личного чата (ключ чата уже подготовлен через prep) */
    private fun dec(m: Message): Message =
        if (!E2E.isEnc(m.body)) m else m.copy(body = E2E.decrypt(m.chatId, m.body), enc = true)

    suspend fun prep(chatId: String) {
        if (chat(chatId) == null) loadChats()
        val c = chat(chatId) ?: return
        if (c.isPrivate) E2E.prepare(chatId, c.peerId)
    }

    suspend fun loadMessages(chatId: String, older: Boolean = false) {
        val me = myId ?: return
        prep(chatId)
        if (!cleared.containsKey(chatId)) {
            val r = runCatching { Api.select("lm_members", mapOf("select" to "cleared_at", "chat_id" to "eq.$chatId", "user_id" to "eq.$me")).firstOrNull() }.getOrNull()
            cleared[chatId] = r?.date("cleared_at") ?: Date(0)
        }
        val q = mutableMapOf("select" to "*", "chat_id" to "eq.$chatId", "deleted" to "eq.false", "order" to "id.desc", "limit" to "50")
        cleared[chatId]?.takeIf { it.time > 0 }?.let { q["created_at"] = "gt." + Dates.string(it) }
        val current = messages[chatId] ?: emptyList()
        if (older) current.firstOrNull { it.id > 0 }?.let { q["id"] = "lt.${it.id}" }
        val rows = runCatching { Api.select("lm_messages", q) }.getOrNull() ?: return
        // удалённые только у меня
        runCatching { Api.select("lm_hidden", mapOf("select" to "message_id", "chat_id" to "eq.$chatId")) }.getOrNull()
            ?.forEach { r -> r.int("message_id")?.let { hidden.add(it) } }
        val arr = rows.map { dec(Message.from(it)) }.reversed().filter { it.id !in hidden }
        messages[chatId] = if (older) arr.filter { m -> current.none { it.id == m.id } } + current else arr + current.filter { it.pending }
        hasMore[chatId] = rows.size == 50
        loadProfiles(arr.mapNotNull { it.senderId })
        val ids = arr.map { it.id }
        if (ids.isNotEmpty()) {
            val rr = runCatching { Api.select("lm_reactions", mapOf("select" to "message_id,user_id,emoji", "message_id" to "in.(" + ids.joinToString(",") + ")")) }.getOrNull() ?: emptyList()
            ids.forEach { reactions[it] = emptyList() }
            val rx = runCatching { Api.select("lm_reactions_extra", mapOf("select" to "message_id,user_id,emoji", "message_id" to "in.(" + ids.joinToString(",") + ")")) }.getOrNull() ?: emptyList()
            (rr.map { Reaction.from(it) } + rx.map { Reaction.from(it, true) }).groupBy { it.messageId }.forEach { (k, v) -> reactions[k] = v }
        }
        val need = arr.mapNotNull { it.replyTo }.toMutableList()
        chat(chatId)?.pinnedMessageId?.let { need.add(it) }
        val missing = need.filter { findMessage(it, chatId) == null }.distinct()
        if (missing.isNotEmpty()) {
            runCatching { Api.select("lm_messages", mapOf("select" to "*", "id" to "in.(" + missing.joinToString(",") + ")")) }.getOrNull()
                ?.forEach { val m = dec(Message.from(it)); replyCache[m.id] = m }
        }
    }

    fun findMessage(id: Int, chatId: String): Message? = messages[chatId]?.firstOrNull { it.id == id } ?: replyCache[id]

    fun markRead(chatId: String) {
        val me = myId ?: return
        if (!isActive) return
        val last = messages[chatId]?.lastOrNull { it.id > 0 } ?: return
        val i = chats.indexOfFirst { it.id == chatId }
        if (i >= 0) {
            val c = chats[i]
            if (c.unread == 0 && c.lastReadAt != null && !c.lastReadAt.before(last.createdAt)) return
            chats[i] = c.copy(unread = 0, lastReadAt = Date(last.createdAt.time + 1))
        }
        unreadTotal = chats.filter { !it.muted }.sumOf { it.unread }
        Notifier.clearChat(ctx, chatId)
        scope.launch {
            runCatching { Api.update("lm_members", mapOf("chat_id" to chatId, "user_id" to me), jsonOf("last_read_at" to Dates.string(Date(last.createdAt.time + 1)))) }
        }
    }

    private fun sorted(list: List<Message>) = list.filter { it.id > 0 }.sortedBy { it.id } + list.filter { it.id <= 0 }

    suspend fun send(chatId: String, kind: String, body: String? = null, media: String? = null, meta: JSONObject = JSONObject(),
                     replyTo: Int? = null, forwardedFrom: String? = null, pendingId: Int? = null): Boolean {
        val me = myId ?: return false
        val pid = pendingId ?: Message.pending(chatId, me, kind, body, meta, replyTo).also { messages[chatId] = (messages[chatId] ?: emptyList()) + it }.id
        return try {
            suspend fun insertRow(): JSONObject? {
                var wire = body
                if (kind == "text" && body != null) { prep(chatId); E2E.encrypt(chatId, body)?.let { wire = it } }
                val row = jsonOf("chat_id" to chatId, "sender_id" to me, "kind" to kind, "meta" to meta)
                wire?.let { row.put("body", it) }; media?.let { row.put("media_url", it) }
                replyTo?.let { row.put("reply_to", it) }; forwardedFrom?.let { row.put("forwarded_from", it) }
                return Api.insert("lm_messages", row)
            }
            val saved = try { insertRow() } catch (e: ApiError) {
                // у собеседника только что появился ключ — обновляем и пробуем ещё раз
                if (e.message?.contains("зашифровано") == true) { E2E.dropCaches(); insertRow() } else throw e
            } ?: throw ApiError("Не отправлено", 0)
            val m = dec(Message.from(saved))
            val list = (messages[chatId] ?: emptyList()).filter { it.id != pid }.let { l -> if (l.any { it.id == m.id }) l else l + m }
            messages[chatId] = sorted(list)
            scheduleReload()
            true
        } catch (e: Exception) {
            messages[chatId] = (messages[chatId] ?: emptyList()).filter { it.id != pid }
            say("Не отправлено: " + (e.message ?: ""))
            false
        }
    }

    fun sendMedia(chatId: String, kind: String, data: ByteArray, ext: String, contentType: String, meta: JSONObject,
                  body: String? = null, replyTo: Int? = null, local: String? = null) {
        val me = myId ?: return
        val temp = Message.pending(chatId, me, kind, body, meta, replyTo, local)
        messages[chatId] = (messages[chatId] ?: emptyList()) + temp
        scope.launch {
            try {
                val url = Api.upload(data, ext, contentType)
                send(chatId, kind, body, url, meta, replyTo, pendingId = temp.id)
            } catch (e: Exception) {
                messages[chatId] = (messages[chatId] ?: emptyList()).filter { it.id != temp.id }
                say("Ошибка загрузки: " + (e.message ?: ""))
            }
        }
    }

    suspend fun forward(m: Message, to: String) {
        val from = m.forwardedFrom?.takeIf { it.isNotEmpty() } ?: chat(m.chatId)?.takeIf { it.isChannel }?.displayName ?: displayName(m.senderId)
        send(to, m.kind, m.body, m.mediaUrl, m.meta, forwardedFrom = from)
    }

    private val hidden = mutableSetOf<Int>()

    suspend fun delete(m: Message) = delete(listOf(m), true)

    /** Удалить сообщения: у всех (исчезают полностью) или только у себя */
    suspend fun delete(list: List<Message>, everyone: Boolean) {
        val ids = list.map { it.id }.filter { it > 0 }.toSet()
        val chatId = list.firstOrNull()?.chatId ?: return
        if (ids.isEmpty()) return
        messages[chatId] = (messages[chatId] ?: emptyList()).filter { it.id !in ids }
        try {
            for (id in ids) {
                if (everyone) Api.update("lm_messages", mapOf("id" to id.toString()), jsonOf("deleted" to true))
                else {
                    hidden.add(id)
                    Api.raw("POST", "/rest/v1/lm_hidden", body = jsonOf("message_id" to id, "chat_id" to chatId),
                        headers = mapOf("Prefer" to "resolution=ignore-duplicates,return=minimal"))
                }
            }
            if (everyone && chat(chatId)?.pinnedMessageId?.let { it in ids } == true) runCatching { Api.update("lm_chats", mapOf("id" to chatId), jsonOf("pinned_message_id" to null)) }
            scheduleReload()
        } catch (e: Exception) { say(e.message ?: "Ошибка"); loadMessages(chatId) }
    }

    suspend fun edit(m: Message, text: String) {
        prep(m.chatId)
        val wire = if (m.kind == "text") E2E.encrypt(m.chatId, text) ?: text else text
        runCatching { Api.update("lm_messages", mapOf("id" to m.id.toString()), jsonOf("body" to wire, "edited_at" to Dates.string(Date()))) }.onFailure { say(it.message ?: "") }
    }

    suspend fun pin(m: Message?, chatId: String) {
        runCatching { Api.update("lm_chats", mapOf("id" to chatId), jsonOf("pinned_message_id" to m?.id)) }
            .onSuccess { m?.let { replyCache[it.id] = it }; loadChats(); say(if (m == null) "Сообщение откреплено" else "Сообщение закреплено") }
            .onFailure { say(it.message ?: "") }
    }

    suspend fun react(m: Message, emoji: String) {
        val me = myId ?: return
        if (m.id <= 0) return
        val list = reactions[m.id] ?: emptyList()
        val mine = list.filter { it.userId == me }
        val others = list.filter { it.userId != me }
        val had = mine.firstOrNull { it.emoji == emoji }
        if (had != null) {
            reactions[m.id] = others + mine.filter { it.emoji != emoji }
            runCatching { Api.delete(if (had.extra) "lm_reactions_extra" else "lm_reactions", mapOf("message_id" to m.id.toString(), "user_id" to me, "emoji" to emoji)) }
            return
        }
        val row = jsonOf("message_id" to m.id, "user_id" to me, "chat_id" to m.chatId, "emoji" to emoji)
        val merge = mapOf("Prefer" to "resolution=merge-duplicates,return=minimal")
        try {
            if (!isPremium) {
                // бесплатно: одна реакция, новая заменяет прежнюю
                reactions[m.id] = others + Reaction(m.id, me, emoji)
                Api.raw("POST", "/rest/v1/lm_reactions", mapOf("on_conflict" to "message_id,user_id"), row, merge)
                return
            }
            if (mine.size >= 3) { say("Можно поставить не больше 3 реакций"); return }
            if (mine.none { !it.extra }) {
                reactions[m.id] = others + mine + Reaction(m.id, me, emoji)
                Api.raw("POST", "/rest/v1/lm_reactions", mapOf("on_conflict" to "message_id,user_id"), row, merge)
            } else {
                reactions[m.id] = others + mine + Reaction(m.id, me, emoji, true)
                Api.raw("POST", "/rest/v1/lm_reactions_extra", emptyMap(), row, mapOf("Prefer" to "return=minimal"))
            }
        } catch (e: Exception) {
            reactions[m.id] = list
            say(e.message ?: "Не удалось поставить реакцию")
        }
    }

    // ---------- обои чатов ----------

    val chatWalls = mutableStateMapOf<String, ChatWall>()

    suspend fun loadChatWalls() {
        val me = myId ?: return
        val rows = runCatching { Api.select("lm_chat_wall", mapOf("select" to "chat_id,preset,url,blur,dim,set_by", "user_id" to "eq.$me")) }.getOrNull() ?: return
        val map = rows.mapNotNull { r -> r.str("chat_id")?.let { it to ChatWall(r.int("preset"), r.str("url"), r.bool("blur"), r.int("dim") ?: 0, r.str("set_by")) } }.toMap()
        chatWalls.clear(); chatWalls.putAll(map)
    }

    suspend fun setWall(chat: String, preset: Int?, url: String?, blur: Boolean, dim: Int, both: Boolean): Boolean {
        val p = JSONObject().put("p_chat", chat).put("p_blur", blur).put("p_dim", dim).put("p_both", both)
            .put("p_preset", preset ?: JSONObject.NULL).put("p_url", url ?: JSONObject.NULL)
        return try { Api.rpc("lm_set_wall", p); loadChatWalls(); true } catch (e: Exception) { say(e.message ?: "Не удалось установить обои"); false }
    }

    suspend fun clearWall(chat: String) {
        val me = myId ?: return
        chatWalls.remove(chat)
        runCatching { Api.delete("lm_chat_wall", mapOf("chat_id" to chat, "user_id" to me)) }
    }

    // ---------- «печатает…» во всех недавних чатах ----------

    private fun syncTyping() {
        if (!loggedIn || myId == null) return
        val want = chats.take(40).map { it.id }.toMutableSet()
        openChatId?.let { want.add(it) }
        typingChannels.keys.filter { it !in want }.forEach { Realtime.leave("lm-typing-$it"); typingChannels.remove(it) }
        want.filter { it !in typingChannels }.forEach { typingChannels[it] = makeTyping(it) }
    }

    private fun makeTyping(id: String): Realtime.Channel {
        val ch = Realtime.channel("lm-typing-$id")
        ch.onBroadcast = { ev, p ->
            val uid = p.str("uid")
            if (ev == "typing" && uid != null && uid != myId) {
                typingAct[id + uid] = p.str("act") ?: "typing"
                typingClear[id + uid]?.cancel()
                if (p.str("act") == "stop") typing[id] = (typing[id] ?: emptyMap()) - uid
                else {
                    typing[id] = (typing[id] ?: emptyMap()) + (uid to (p.str("name") ?: ""))
                    typingClear[id + uid] = scope.launch { delay(4000); typing[id] = (typing[id] ?: emptyMap()) - uid }
                }
            }
        }
        return ch
    }

    private val typingAct = mutableMapOf<String, String>()
    private var lastTypingAct = ""

    /** Сообщить собеседникам: печатаю («typing»), записываю голосовое («voice») или кружок («video»), закончил («stop») */
    fun userTyping(chatId: String, act: String = "typing") {
        val m = me ?: return
        val ch = typingChannels[chatId] ?: makeTyping(chatId).also { typingChannels[chatId] = it }
        if (act == lastTypingAct && act != "stop" && System.currentTimeMillis() - lastTypingSent < 2500) return
        lastTypingSent = System.currentTimeMillis()
        lastTypingAct = act
        Realtime.broadcast(ch, "typing", jsonOf("uid" to m.id, "name" to m.name, "act" to act))
    }

    fun typingText(chatId: String): String? {
        val t = typing[chatId]?.takeIf { it.isNotEmpty() } ?: return null
        fun verb(uid: String) = when (typingAct[chatId + uid]) { "voice" -> "записывает голосовое…"; "video" -> "записывает видеосообщение…"; else -> "печатает…" }
        if (chat(chatId)?.isPrivate == true) return verb(t.keys.first())
        if (t.size == 1) return displayName(t.keys.first()) + " " + verb(t.keys.first())
        return t.keys.take(2).joinToString(", ") { displayName(it) } + " печатают…"
    }

    // ---------- живые обновления ----------

    private fun onDB(d: JSONObject) {
        val table = d.optString("table"); val type = d.optString("type"); val rec = d.obj("record")
        when (table) {
            "lm_messages" -> {
                val m0 = Message.from(rec)
                if (m0.id <= 0 || m0.chatId.isEmpty()) return
                scope.launch {
                    if (E2E.isEnc(m0.body)) prep(m0.chatId)
                    val m = dec(m0)
                    if (type == "INSERT") incoming(m) else if (type == "UPDATE") {
                        messages[m.chatId]?.let { l -> messages[m.chatId] = if (m.deleted) l.filter { it.id != m.id } else l.map { if (it.id == m.id) m else it } }
                        if (replyCache.containsKey(m.id)) replyCache[m.id] = m
                        scheduleReload()
                    }
                }
            }
            "lm_members" -> scheduleReload()
            "lm_reactions", "lm_reactions_extra" -> {
                val isExtra = table == "lm_reactions_extra"
                if (type == "DELETE") {
                    val old = d.obj("old_record"); val mid = old.int("message_id"); val uid = old.str("user_id"); val e = old.str("emoji")
                    if (mid != null && uid != null && uid != myId) reactions[mid] = (reactions[mid] ?: emptyList()).filterNot { it.userId == uid && it.extra == isExtra && (e == null || it.emoji == e) }
                } else {
                    val r = Reaction.from(rec, isExtra)
                    if (r.messageId <= 0 || r.userId == myId) return
                    var l = reactions[r.messageId] ?: emptyList()
                    if (!isExtra) l = l.filterNot { it.userId == r.userId && !it.extra }
                    reactions[r.messageId] = l.filterNot { it.userId == r.userId && it.emoji == r.emoji } + r
                }
            }
            "lm_chat_wall" -> scope.launch { loadChatWalls() }
        }
    }

    private fun incoming(m: Message) {
        messages[m.chatId]?.let { list ->
            if (list.none { it.id == m.id }) {
                var l = list
                if (m.senderId == myId) { val i = l.indexOfFirst { it.pending && it.kind == m.kind && it.body == m.body }; if (i >= 0) l = l.filterIndexed { k, _ -> k != i } }
                messages[m.chatId] = sorted(l + m)
            }
        }
        m.senderId?.let { s -> typing[m.chatId]?.let { typing[m.chatId] = it - s } }
        scheduleReload()
        if (m.senderId == myId || m.kind == "system") return
        scope.launch { m.senderId?.let { loadProfiles(listOf(it)) } }
        val visible = isActive && openChatId == m.chatId
        val c = chat(m.chatId)
        if (isActive && m.kind != "call" && c?.muted != true) Notifier.beep()
        if (visible) { scope.launch { delay(300); markRead(m.chatId) }; return }
        if (m.kind == "call" && (m.metaStatus == null || m.metaStatus == "ended" || m.metaStatus == "rejected")) return
        if (!notified.add(m.id)) return
        scope.launch {
            if (chat(m.chatId) == null) loadChats()
            val ch = chat(m.chatId)
            if (ch?.muted == true || isActive) return@launch
            m.senderId?.let { loadProfiles(listOf(it)) }
            val sender = displayName(m.senderId)
            var body = m.preview
            if (m.kind == "call") body = if (m.isVideoCall) "Пропущенный видеозвонок" else "Пропущенный звонок"
            val title = when {
                ch == null || ch.isPrivate -> sender
                ch.isChannel -> ch.displayName
                else -> { body = "$sender: $body"; ch.displayName }
            }
            Notifier.message(ctx, m.id, title, body, m.chatId)
        }
    }


    // ---------- дополнительно: Telegram, роли, блокировки, звонки, истории, QR ----------

    var pendingJump: Int? = null
    var staffRole by mutableStateOf<String?>(null)
    var tgLinked by mutableStateOf(false)
    val blockedByMe = mutableStateListOf<String>()
    val blockedMe = mutableStateListOf<String>()
    val calls = mutableStateListOf<Message>()
    val stories = mutableStateListOf<StoryGroup>()

    var keepAlive: Boolean
        get() = ctx.getSharedPreferences("lumo_prefs", Context.MODE_PRIVATE).getBoolean("keep_alive", true)
        set(v) {
            ctx.getSharedPreferences("lumo_prefs", Context.MODE_PRIVATE).edit().putBoolean("keep_alive", v).apply()
            if (v) LumoService.start(ctx) else LumoService.stop(ctx)
        }

    val profileLink get() = Config.SITE + "#@" + (me?.username ?: "")

    suspend fun loadExtras() {
        if (botName == null) botName = (runCatching { Api.function("/config", auth = false) }.getOrNull() as? JSONObject)?.str("bot")
        tgLinked = runCatching { Api.select("lm_tg_links", mapOf("select" to "enabled")).firstOrNull()?.bool("enabled") ?: false }.getOrDefault(false)
        staffRole = runCatching { Api.rpc("lm_staff_role") as? String }.getOrNull()
    }

    suspend fun telegramLink(): String? {
        val bot = telegramBot() ?: return null
        val code = runCatching { Api.rpc("lm_tg_code") as? String }.getOrNull()
        return "https://t.me/$bot" + (code?.let { "?start=$it" } ?: "")
    }

    suspend fun telegramOff() {
        runCatching { Api.update("lm_tg_links", mapOf("user_id" to (myId ?: "")), jsonOf("enabled" to false)) }
        loadExtras()
    }

    suspend fun setPrivacy(showSeen: Boolean? = null, callsFrom: String? = null) {
        val id = myId ?: return
        val v = JSONObject()
        showSeen?.let { v.put("show_seen", it) }; callsFrom?.let { v.put("calls_from", it) }
        runCatching { Api.update("lm_profiles", mapOf("id" to id), v); loadMe() }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun deleteAccount() {
        val r = Api.function("/account", jsonOf("action" to "delete")) as? JSONObject
        r?.str("error")?.let { throw ApiError(it, 0) }
        Api.forget()
    }

    suspend fun openByUsername(username: String) {
        val u = username.lowercase()
        val r = runCatching { Api.select("lm_profiles", mapOf("select" to "id", "username" to "eq.$u")).firstOrNull() }.getOrNull()
            ?: run { say("Пользователь @$u не найден"); return }
        val p = fetchProfiles(listOf(r.str("id") ?: "")).firstOrNull() ?: return
        profiles[p.id] = p
        if (p.id == myId) { say("Это ваш профиль"); return }
        stack.add(Screen.Person(p.id))
    }

    suspend fun loadBlocks() {
        val j = runCatching { Api.rpc("lm_my_blocks") as? JSONObject }.getOrNull() ?: return
        fun arr(k: String) = j.optJSONArray(k)?.let { a -> (0 until a.length()).map { a.optString(it) } } ?: emptyList()
        blockedByMe.clear(); blockedByMe.addAll(arr("mine"))
        blockedMe.clear(); blockedMe.addAll(arr("me"))
    }

    suspend fun setBlocked(id: String, on: Boolean) {
        runCatching { Api.rpc("lm_block", jsonOf("p_user" to id, "p_on" to on)); loadBlocks() }
            .onSuccess { say(if (on) "Пользователь заблокирован" else "Пользователь разблокирован") }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun report(user: String?, chat: String?, message: Int?, reason: ReportReason, comment: String): Boolean = try {
        val em = if (chat != null && message != null) findMessage(message, chat)?.takeIf { it.enc } else null
        if (em != null) {
            // сообщение зашифровано: сервер его прочитать не может, поэтому прикладываем текст, который видит пожаловавшийся
            Api.rpc("lm_report_e2e", jsonOf("p_user" to user, "p_chat" to chat, "p_message" to message, "p_reason" to reason.name, "p_comment" to comment, "p_plain" to (em.body ?: "")))
        } else
        Api.rpc("lm_report", jsonOf("p_user" to user, "p_chat" to chat, "p_message" to message, "p_reason" to reason.name, "p_comment" to comment))
        say("Жалоба отправлена. Спасибо!"); true
    } catch (e: Exception) { say(e.message ?: "Ошибка"); false }

    /** Почему нельзя писать или звонить человеку */
    fun peerBlockText(uid: String?): String? {
        uid ?: return null
        if (profiles[uid]?.banned == true) return "Аккаунт заблокирован"
        if (uid in blockedByMe) return "Вы заблокировали этого пользователя"
        if (uid in blockedMe) return "Пользователь ограничил сообщения"
        return null
    }

    suspend fun setPinned(chatId: String, on: Boolean) {
        runCatching { Api.update("lm_members", mapOf("chat_id" to chatId, "user_id" to (myId ?: "")), jsonOf("pinned" to on)) }
        loadChats()
    }

    suspend fun addMembers(chatId: String, ids: List<String>) {
        runCatching { Api.rpc("lm_add_members", jsonOf("p_chat" to chatId, "p_members" to JSONArray(ids))); loadChats() }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun removeMember(chatId: String, uid: String) {
        runCatching { Api.delete("lm_members", mapOf("chat_id" to chatId, "user_id" to uid)); loadChats() }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun setRole(chatId: String, uid: String, role: String) {
        runCatching { Api.rpc("lm_set_role", jsonOf("p_chat" to chatId, "p_user" to uid, "p_role" to role)) }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun saveChat(chatId: String, title: String, description: String) {
        runCatching { Api.update("lm_chats", mapOf("id" to chatId), jsonOf("title" to title, "description" to description)); loadChats() }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun setChatAvatar(chatId: String, jpeg: ByteArray) {
        runCatching {
            val url = Api.upload(jpeg, "jpg", "image/jpeg")
            Api.update("lm_chats", mapOf("id" to chatId), jsonOf("avatar_url" to url)); loadChats()
        }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun loadCalls() {
        val rows = runCatching { Api.select("lm_messages", mapOf("select" to "*", "kind" to "eq.call", "order" to "id.desc", "limit" to "100")) }.getOrNull() ?: return
        calls.clear(); calls.addAll(rows.map { Message.from(it) })
    }

    suspend fun searchMessages(chatId: String, q: String): List<Message> {
        if (chat(chatId)?.isPrivate == true) {
            // личные чаты зашифрованы: ищем на устройстве среди последних сообщений
            prep(chatId)
            val all = runCatching { Api.select("lm_messages", mapOf("select" to "*", "chat_id" to "eq.$chatId", "deleted" to "eq.false", "order" to "id.desc", "limit" to "600")) }.getOrNull() ?: emptyList()
            val needle = q.lowercase()
            return all.map { dec(Message.from(it)) }.filter { it.kind != "system" && it.kind != "call" && (it.body ?: "").lowercase().contains(needle) }
                .take(60).onEach { replyCache[it.id] = it }
        }
        val rows = runCatching { Api.select("lm_messages", mapOf("select" to "*", "chat_id" to "eq.$chatId", "deleted" to "eq.false",
            "body" to "ilike.*$q*", "order" to "id.desc", "limit" to "60")) }.getOrNull() ?: emptyList()
        return rows.map { Message.from(it) }.onEach { replyCache[it.id] = it }
    }

    suspend fun loadStories() {
        val rows = (runCatching { Api.rpc("lm_stories_feed") }.getOrNull() as? JSONArray).objects().map { StoryItem.from(it) }
        val groups = rows.groupBy { it.userId }.map { (uid, l) ->
            val items = l.sortedBy { it.createdAt }
            val f = items.first()
            StoryGroup(uid, aliases[uid]?.takeIf { it.isNotEmpty() } ?: f.name, f.avatarUrl, f.color, items,
                uid != myId && items.any { !it.seen }, items.last().createdAt)
        }.sortedWith(compareByDescending<StoryGroup> { it.userId == myId }.thenByDescending { it.unseen }.thenByDescending { it.last })
        stories.clear(); stories.addAll(groups)
    }

    suspend fun addStory(kind: String, data: ByteArray, ext: String, contentType: String, caption: String, meta: JSONObject, hours: Int = 24): Boolean = try {
        val url = Api.upload(data, ext, contentType)
        Api.rpc("lm_story_add", jsonOf("p_kind" to kind, "p_url" to url, "p_caption" to caption, "p_meta" to meta, "p_hours" to hours))
        loadStories(); say("История опубликована"); true
    } catch (e: Exception) { say("Ошибка: " + (e.message ?: "")); false }

    fun viewStory(s: StoryItem) {
        if (s.userId == myId || s.seen) return
        scope.launch { runCatching { Api.rpc("lm_story_view", jsonOf("p_id" to s.id)) } }
        val gi = stories.indexOfFirst { g -> g.items.any { it.id == s.id } }
        if (gi >= 0) {
            val g = stories[gi]
            val items = g.items.map { if (it.id == s.id) it.copy(seen = true) else it }
            stories[gi] = g.copy(items = items, unseen = items.any { !it.seen })
        }
    }

    suspend fun reactStory(s: StoryItem) { runCatching { Api.rpc("lm_story_react", jsonOf("p_id" to s.id, "p_emoji" to "❤️")) }; say("Реакция отправлена") }

    suspend fun deleteStory(s: StoryItem) {
        runCatching { Api.rpc("lm_story_delete", jsonOf("p_id" to s.id)); loadStories() }.onSuccess { say("История удалена") }.onFailure { say(it.message ?: "Ошибка") }
    }

    suspend fun storyViewers(s: StoryItem): List<JSONObject> = (runCatching { Api.rpc("lm_story_viewers", jsonOf("p_id" to s.id)) }.getOrNull() as? JSONArray).objects()

    suspend fun replyStory(s: StoryItem, text: String) {
        try {
            val cid = Api.rpc("lm_open_dm", jsonOf("p_other" to s.userId)) as? String ?: return
            val me = myId ?: return
            val body = "Ответ на историю" + (if (s.caption.isEmpty()) "" else " «" + s.caption.take(60) + "»") + ":\n" + text
            Api.insert("lm_messages", jsonOf("chat_id" to cid, "sender_id" to me, "kind" to "text", "body" to body,
                "meta" to jsonOf("story" to jsonOf("id" to s.id, "kind" to s.kind, "url" to s.mediaUrl))))
            say("Ответ отправлен")
        } catch (e: Exception) { say(e.message ?: "Ошибка") }
    }

    /** Вход на компьютере по QR-коду */
    suspend fun approveQR(key: String) {
        val ch = Realtime.channel("lm-qr-$key")
        var result: String? = null
        ch.onBroadcast = { ev, p -> val t = p.str("t"); if (ev == "qr" && (t == "ok" || t == "fail")) result = t }
        Realtime.waitJoined(ch)
        Realtime.broadcast(ch, "qr", jsonOf("t" to "scan"))
        try {
            val j = Api.function("/qr", JSONObject()) as? JSONObject
            val th = j?.str("th") ?: throw ApiError("Не удалось подтвердить вход", 0)
            Realtime.broadcast(ch, "qr", jsonOf("t" to "login", "th" to th))
            repeat(30) { if (result == null) delay(500) }
            say(when (result) { "ok" -> "Готово! Вы вошли на компьютере"; "fail" -> "Не получилось — обновите QR-код на компьютере"; else -> "Компьютер не ответил — отсканируйте код заново" })
        } catch (e: Exception) { say(e.message ?: "Ошибка") }
        Realtime.leave("lm-qr-$key")
    }

    // ---------- чаты: группы, выход, очистка ----------

    suspend fun clearChat(chatId: String) {
        try {
            val t = Api.rpc("lm_clear_chat", jsonOf("p_chat" to chatId)) as? String
            cleared[chatId] = Dates.parse(t) ?: Date()
            messages[chatId] = emptyList(); hasMore[chatId] = false
            loadChats(); say("История очищена")
        } catch (e: Exception) { say(e.message ?: "Ошибка") }
    }

    suspend fun leave(chatId: String) {
        val id = myId ?: return
        try {
            Api.delete("lm_members", mapOf("chat_id" to chatId, "user_id" to id))
            stack.clear(); loadChats()
        } catch (e: Exception) { say(e.message ?: "Ошибка") }
    }

    suspend fun createChat(type: String, title: String, description: String, members: List<String>): String? = try {
        val cid = Api.rpc("lm_create_chat", jsonOf("p_type" to type, "p_title" to title, "p_members" to JSONArray(members), "p_description" to description)) as? String
        loadChats(); cid?.let { open(it) }; cid
    } catch (e: Exception) { say(e.message ?: "Ошибка"); null }

    suspend fun members(chatId: String): List<Pair<String, String>> {
        val rows = runCatching { Api.select("lm_members", mapOf("select" to "user_id,role", "chat_id" to "eq.$chatId")) }.getOrNull() ?: emptyList()
        val list = rows.map { (it.str("user_id") ?: "") to (it.str("role") ?: "member") }
        loadProfiles(list.map { it.first })
        val order = mapOf("owner" to 0, "admin" to 1)
        return list.sortedWith(compareBy<Pair<String, String>> { order[it.second] ?: 2 }.thenBy { displayName(it.first) })
    }

    suspend fun sharedMedia(chatId: String, kinds: List<String>): List<Message> =
        (runCatching { Api.select("lm_messages", mapOf("select" to "*", "chat_id" to "eq.$chatId", "deleted" to "eq.false",
            "kind" to "in.(" + kinds.joinToString(",") + ")", "order" to "id.desc", "limit" to "60")) }.getOrNull() ?: emptyList()).map { dec(Message.from(it)) }
}
