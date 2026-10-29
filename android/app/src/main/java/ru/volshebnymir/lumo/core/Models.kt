package ru.volshebnymir.lumo.core

import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object Dates {
    private val iso = ThreadLocal.withInitial {
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
    }
    private val isoNoFrac = ThreadLocal.withInitial {
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
    }

    fun parse(raw: String?): Date? {
        if (raw.isNullOrEmpty()) return null
        var s = raw.replace(" ", "T")
        s = Regex("""\.(\d{3})\d+""").replace(s) { "." + it.groupValues[1] }
        if (Regex("""[+-]\d\d$""").containsMatchIn(s)) s += ":00"
        if (!s.endsWith("Z") && !Regex("""[+-]\d\d:\d\d$""").containsMatchIn(s)) s += "Z"
        s = s.replace("Z", "+00:00")
        return runCatching { iso.get()!!.parse(s) }.getOrNull() ?: runCatching { isoNoFrac.get()!!.parse(s) }.getOrNull()
    }

    fun string(d: Date): String = iso.get()!!.format(d).replace("+00:00", "Z")
}

fun JSONObject.date(k: String): Date? = Dates.parse(str(k))

object Fmt {
    private fun cal(d: Date) = Calendar.getInstance().apply { time = d }
    private fun sameDay(a: Date, b: Date): Boolean { val x = cal(a); val y = cal(b); return x.get(Calendar.YEAR) == y.get(Calendar.YEAR) && x.get(Calendar.DAY_OF_YEAR) == y.get(Calendar.DAY_OF_YEAR) }
    private val ru = Locale("ru")

    fun clock(d: Date?): String = if (d == null) "" else SimpleDateFormat("HH:mm", ru).format(d)

    fun listTime(d: Date?): String {
        if (d == null) return ""
        val now = Date()
        if (sameDay(d, now)) return clock(d)
        val y = Date(now.time - 86_400_000)
        if (sameDay(d, y)) return "вчера"
        val days = (now.time - d.time) / 86_400_000
        if (days < 7) return SimpleDateFormat("EE", ru).format(d)
        return if (cal(d).get(Calendar.YEAR) == cal(now).get(Calendar.YEAR)) SimpleDateFormat("d MMM", ru).format(d)
        else SimpleDateFormat("dd.MM.yy", ru).format(d)
    }

    fun day(d: Date): String {
        val now = Date()
        if (sameDay(d, now)) return "Сегодня"
        if (sameDay(d, Date(now.time - 86_400_000))) return "Вчера"
        return SimpleDateFormat(if (cal(d).get(Calendar.YEAR) == cal(now).get(Calendar.YEAR)) "d MMMM" else "d MMMM yyyy", ru).format(d)
    }

    fun isSameDay(a: Date, b: Date) = sameDay(a, b)

    fun duration(s: Double): String { val t = maxOf(0, Math.round(s).toInt()); return "${t / 60}:" + String.format(Locale.US, "%02d", t % 60) }

    fun size(b: Long): String {
        var v = b.toDouble(); val u = listOf("Б", "КБ", "МБ", "ГБ"); var i = 0
        while (v >= 1024 && i < 3) { v /= 1024; i++ }
        return if (i == 0) "${v.toInt()} ${u[i]}" else String.format(Locale.US, "%.1f %s", v, u[i])
    }

    fun lastSeen(d: Date?, show: Boolean = true): String {
        if (!show || d == null) return "был(а) недавно"
        val m = (Date().time - d.time) / 60000.0
        if (m < 1.5) return "был(а) только что"
        if (m < 60) return "был(а) ${Math.round(m)} мин. назад"
        if (sameDay(d, Date())) return "был(а) сегодня в " + clock(d)
        return "был(а) " + day(d).lowercase() + " в " + clock(d)
    }

    fun initials(name: String): String {
        val p = name.split(" ").filter { it.isNotBlank() }
        if (p.isEmpty()) return "?"
        return if (p.size > 1) "${p[0].first()}${p[1].first()}".uppercase() else p[0].take(2).uppercase()
    }
}

data class Profile(
    val id: String, val username: String, val name: String, val bio: String, val avatarUrl: String?, val color: Int,
    val lastSeen: Date?, val showSeen: Boolean, val banned: Boolean, val callsFrom: String, val verified: Boolean,
    val lastName: String = "", val birthday: String? = null, val privacy: JSONObject = JSONObject(),
    val channelId: String? = null, val channelTitle: String? = null, val channelUsername: String? = null,
    val channelAvatar: String? = null, val channelColor: Int = 0, val channelMembers: Int = 0,
    val premium: Boolean = false, val isBot: Boolean = false, val emojiStatus: String? = null,
) {
    /** Имя без фамилии (в поле name хранится полное имя) */
    val firstName: String get() = if (lastName.isNotEmpty() && name.endsWith(" $lastName")) name.removeSuffix(" $lastName") else name

    /** Настройка конфиденциальности: all / contacts / none */
    fun priv(key: String): String = privacy.str(key) ?: when (key) {
        "seen" -> if (showSeen) "all" else "none"
        "calls" -> callsFrom
        "birthday" -> "all"
        "phone" -> "contacts"
        else -> "all"
    }

    companion object {
        fun from(j: JSONObject) = Profile(
            j.str("id") ?: "", j.str("username") ?: "", j.str("name") ?: "", j.str("bio") ?: "", j.str("avatar_url"),
            j.int("color") ?: 0, j.date("last_seen"), if (j.has("show_seen") && !j.isNull("show_seen")) j.bool("show_seen") else true,
            j.bool("banned"), j.str("calls_from") ?: "all", j.bool("verified"),
            j.str("last_name") ?: "", j.str("birthday"), j.optJSONObject("privacy") ?: JSONObject(),
            j.str("channel_id"), j.str("channel_title"), j.str("channel_username"), j.str("channel_avatar"), j.int("channel_color") ?: 0, j.int("channel_members") ?: 0,
            j.bool("premium"), j.bool("is_bot"), j.str("emoji_status"),
        )
    }
}

/** День рождения «1 июля 2011» (и сколько лет) */
object Birthday {
    private val months = listOf("января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря")
    fun parts(s: String?): Triple<Int, Int, Int>? {
        val p = s?.take(10)?.split("-")?.mapNotNull { it.toIntOrNull() } ?: return null
        return if (p.size == 3) Triple(p[0], p[1], p[2]) else null
    }
    fun text(s: String?, withAge: Boolean = false): String? {
        val (y, m, d) = parts(s) ?: return null
        var t = "$d ${months[(m - 1).coerceIn(0, 11)]} $y"
        if (withAge) {
            val c = Calendar.getInstance()
            var age = c.get(Calendar.YEAR) - y
            if (c.get(Calendar.MONTH) + 1 < m || (c.get(Calendar.MONTH) + 1 == m && c.get(Calendar.DAY_OF_MONTH) < d)) age--
            if (age in 1..120) t += " ($age " + (if (age % 100 in 11..14) "лет" else when (age % 10) { 1 -> "год"; 2, 3, 4 -> "года"; else -> "лет" }) + ")"
        }
        return t
    }
}

data class ChatItem(
    val id: String, val type: String, val title: String?, val avatarUrl: String?, val color: Int,
    val peerId: String?, val peerName: String?, val peerUsername: String?, val peerAvatar: String?, val peerColor: Int,
    val peerLastSeen: Date?, val role: String?, val muted: Boolean, val pinned: Boolean, val lastReadAt: Date?,
    val membersCount: Int, val lastId: Int?, val lastKind: String?, val lastBody: String?, val lastSender: String?,
    val lastSenderName: String?, val lastAt: Date?, val lastDeleted: Boolean, val unread: Int, val othersReadAt: Date?,
    val pinnedMessageId: Int?, val description: String?, val username: String?,
    val peerBot: Boolean = false, val peerPremium: Boolean = false, val peerVerified: Boolean = false,
) {
    val isPrivate get() = type == "private"
    val isChannel get() = type == "channel"
    val displayName: String get() = if (isPrivate) peerName ?: peerUsername ?: "Пользователь" else title ?: if (isChannel) "Канал" else "Группа"
    val displayAvatar: String? get() = if (isPrivate) peerAvatar else avatarUrl
    val displayColor: Int get() = if (isPrivate) peerColor else color
    val canPost get() = !isChannel || role == "owner" || role == "admin"
    val isAdmin get() = role == "owner" || role == "admin"

    fun preview(myId: String?): String {
        if (lastId == null) return if (isChannel) "Канал создан" else "Нет сообщений"
        if (lastDeleted) return "Сообщение удалено"
        val text = Message.previewText(lastKind ?: "text", lastBody)
        if (type == "group" && lastSenderName != null && lastKind != "system") return (if (lastSender == myId) "Вы" else lastSenderName) + ": " + text
        if (lastSender == myId && lastKind != "system" && lastKind != "call") return "Вы: $text"
        return text
    }

    companion object {
        fun from(j: JSONObject) = ChatItem(
            j.str("chat_id") ?: "", j.str("type") ?: "private", j.str("title"), j.str("avatar_url"), j.int("color") ?: 0,
            j.str("peer_id"), j.str("peer_name"), j.str("peer_username"), j.str("peer_avatar"), j.int("peer_color") ?: 0,
            j.date("peer_last_seen"), j.str("role"), j.bool("muted"), j.bool("pinned"), j.date("last_read_at"),
            j.int("members_count") ?: 0, j.int("last_id"), j.str("last_kind"), j.str("last_body"), j.str("last_sender"),
            j.str("last_sender_name"), j.date("last_at"), j.bool("last_deleted"), j.int("unread") ?: 0, j.date("others_read_at"),
            j.int("pinned_message_id"), j.str("description"), j.str("username"),
            j.bool("peer_bot"), j.bool("peer_premium"), j.bool("peer_verified"),
        )
    }
}

data class Message(
    val id: Int, val chatId: String, val senderId: String?, val kind: String, val body: String?, val mediaUrl: String?,
    val meta: JSONObject, val replyTo: Int?, val forwardedFrom: String?, val editedAt: Date?, val deleted: Boolean,
    val createdAt: Date, val pending: Boolean = false, val localPath: String? = null, val enc: Boolean = false,
) {
    val metaStatus get() = meta.str("status")
    val duration: Double get() = meta.dbl("dur") ?: meta.dbl("duration") ?: 0.0
    val wave: List<Int> get() = meta.optJSONArray("wave")?.let { a -> (0 until a.length()).map { a.optInt(it) } } ?: emptyList()
    val width get() = meta.dbl("w")
    val height get() = meta.dbl("h")
    val fileName get() = meta.str("name") ?: "Файл"
    val fileSize: Long? get() = meta.dbl("size")?.toLong()
    val isVideoCall get() = meta.bool("video")
    /** Кнопки под сообщением бота: строки по [текст, data|url] */
    val buttons: List<List<BotBtn>> get() = meta.optJSONArray("buttons")?.let { rows ->
        (0 until rows.length()).mapNotNull { i -> rows.optJSONArray(i)?.let { r -> (0 until r.length()).mapNotNull { k -> r.optJSONObject(k)?.let { b -> BotBtn(b.str("text") ?: "", b.str("data"), b.str("url"), b.str("web_app")) } } } }
    } ?: emptyList()
    val preview: String get() = if (deleted) "Сообщение удалено" else if (kind == "file") "Файл: $fileName" else previewText(kind, body)

    companion object {
        fun from(j: JSONObject) = Message(
            j.int("id") ?: 0, j.str("chat_id") ?: "", j.str("sender_id"), j.str("kind") ?: "text", j.str("body"), j.str("media_url"),
            j.optJSONObject("meta") ?: JSONObject(), j.int("reply_to"), j.str("forwarded_from"), j.date("edited_at"), j.bool("deleted"),
            j.date("created_at") ?: Date(),
        )

        fun pending(chat: String, sender: String, kind: String, body: String?, meta: JSONObject = JSONObject(), replyTo: Int? = null, local: String? = null) =
            Message(-(System.currentTimeMillis() % 1_000_000_000).toInt() - (0..999).random(), chat, sender, kind, body, null, meta, replyTo, null, null, false, Date(), true, local)

        fun previewText(kind: String, body: String?): String {
            val b = (body ?: "").replace("**", "").replace("__", "").replace("`", "").replace("~~", "")
            return when (kind) {
                "voice" -> "Голосовое сообщение"
                "video_note" -> "Видеосообщение"
                "image" -> b.ifEmpty { "Фото" }
                "video" -> b.ifEmpty { "Видео" }
                "file" -> "Файл"
                "sticker" -> "Стикер"
                "call" -> "Звонок"
                else -> b
            }
        }
    }
}

data class BotBtn(val text: String, val data: String?, val url: String?, val webApp: String? = null)

/** Запрос на открытие мини-приложения бота */
data class MiniAppReq(val botId: String, val url: String? = null)

/** extra — вторая и третья реакции (Premium), хранятся отдельно */
data class Reaction(val messageId: Int, val userId: String, val emoji: String, val extra: Boolean = false) {
    companion object { fun from(j: JSONObject, extra: Boolean = false) = Reaction(j.int("message_id") ?: 0, j.str("user_id") ?: "", j.str("emoji") ?: "", extra) }
}

/** Обои конкретного чата (для меня; могут быть установлены собеседником) */
data class ChatWall(val preset: Int?, val url: String?, val blur: Boolean, val dim: Int, val setBy: String?)

data class SearchResult(val id: String, val kind: String, val name: String, val username: String?, val avatarUrl: String?, val color: Int, val extra: String?) {
    companion object {
        fun from(j: JSONObject) = SearchResult(j.str("id") ?: "", j.str("kind") ?: "user", j.str("name") ?: "", j.str("username"), j.str("avatar_url"), j.int("color") ?: 0, j.str("extra"))
    }
}

data class StoryItem(
    val id: Int, val userId: String, val name: String, val username: String, val avatarUrl: String?, val color: Int,
    val kind: String, val mediaUrl: String, val caption: String, val createdAt: Date, val seen: Boolean, val views: Int,
) {
    companion object {
        fun from(j: JSONObject) = StoryItem(
            j.int("id") ?: 0, j.str("user_id") ?: "", j.str("name") ?: "", j.str("username") ?: "", j.str("avatar_url"), j.int("color") ?: 0,
            j.str("kind") ?: "image", j.str("media_url") ?: "", j.str("caption") ?: "", j.date("created_at") ?: Date(), j.bool("seen"), j.int("views") ?: 0,
        )
    }
}

data class StoryGroup(val userId: String, val name: String, val avatarUrl: String?, val color: Int, val items: List<StoryItem>, val unseen: Boolean, val last: Date)

enum class ReportReason(val title: String) {
    spam("Спам"), abuse("Оскорбления или травля"), fraud("Мошенничество"), violence("Угрозы или насилие"), adult("Неприемлемый контент"), other("Другое")
}
