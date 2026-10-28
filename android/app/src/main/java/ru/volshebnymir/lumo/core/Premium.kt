package ru.volshebnymir.lumo.core

import org.json.JSONArray
import org.json.JSONObject
import java.util.Date

const val PREMIUM_SOON = "Функция Lumo Premium. Оформление пока временно недоступно"

val AppModel.isPremium: Boolean get() = me?.premium == true

/** Выполняет действие, только если у пользователя есть Premium; иначе сообщает, что функция пока недоступна */
fun AppModel.premium(action: () -> Unit) { if (isPremium) action() else say(PREMIUM_SOON) }

suspend fun AppModel.scheduleMessage(chatId: String, text: String, at: Date, replyTo: Int?): Boolean {
    prep(chatId)
    val wire = E2E.encrypt(chatId, text) ?: text
    val p = jsonOf("p_chat" to chatId, "p_kind" to "text", "p_body" to wire, "p_meta" to JSONObject(), "p_at" to Dates.string(at))
    replyTo?.let { p.put("p_reply", it) }
    return try { Api.rpc("lm_schedule", p); true } catch (e: Exception) { say(e.message ?: "Не удалось запланировать"); false }
}

data class Scheduled(val id: Int, val at: Date, val text: String)

suspend fun AppModel.scheduledList(chatId: String): List<Scheduled> {
    val rows = (runCatching { Api.rpc("lm_scheduled_list", jsonOf("p_chat" to chatId)) }.getOrNull() as? JSONArray).objects()
    prep(chatId)
    return rows.map { r ->
        var t = r.str("body") ?: ""
        if (E2E.isEnc(t)) t = E2E.decrypt(chatId, t) ?: "🔒"
        Scheduled(r.int("id") ?: 0, r.date("send_at") ?: Date(), t)
    }
}

suspend fun AppModel.cancelScheduled(id: Int) { runCatching { Api.rpc("lm_scheduled_cancel", jsonOf("p_id" to id)) } }

suspend fun AppModel.chatTtl(chatId: String): Int =
    runCatching { Api.select("lm_chats", mapOf("select" to "ttl_seconds", "id" to "eq.$chatId")).firstOrNull()?.int("ttl_seconds") }.getOrNull() ?: 0

suspend fun AppModel.setChatTtl(chatId: String, seconds: Int): Boolean =
    try { Api.rpc("lm_set_chat_ttl", jsonOf("p_chat" to chatId, "p_seconds" to seconds)); true } catch (e: Exception) { say(e.message ?: "Не удалось изменить"); false }

suspend fun AppModel.channelStats(chatId: String): JSONObject? =
    try { Api.rpc("lm_channel_stats", jsonOf("p_chat" to chatId)) as? JSONObject } catch (e: Exception) { say(e.message ?: "Не удалось загрузить"); null }

suspend fun AppModel.setEmojiStatus(e: String) {
    try { Api.rpc("lm_set_emoji_status", jsonOf("p_emoji" to e)); loadMe(); say(if (e.isEmpty()) "Статус убран" else "Статус установлен") }
    catch (x: Exception) { say(x.message ?: "Не удалось изменить") }
}

/** Защищённые чаты: запрет пересылки, копирования и скриншотов */
object Prot {
    val map = androidx.compose.runtime.mutableStateMapOf<String, Boolean>()
    fun on(chatId: String?) = chatId != null && map[chatId] == true
    suspend fun load(chatId: String) {
        val v = runCatching { Api.select("lm_chats", mapOf("select" to "protected", "id" to "eq.$chatId")).firstOrNull()?.optBoolean("protected") }.getOrNull()
        if (v != null) map[chatId] = v
    }
    suspend fun set(chatId: String, on: Boolean): Boolean =
        try { Api.rpc("lm_set_protected", jsonOf("p_chat" to chatId, "p_on" to on)); map[chatId] = on; true } catch (e: Exception) { AppModel.say(e.message ?: "Не удалось изменить"); false }
}
