package ru.volshebnymir.lumo.core

import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

/** Очередь отправки: сообщения, которые не ушли из-за сети, ждут на телефоне (с часиками) и уходят сами, когда связь вернётся. */
object Outbox {
    data class Item(var pid: Int, val chatId: String, val kind: String, val body: String?, val media: String?, val meta: String, val replyTo: Int?, val forwardedFrom: String?)
    private val items = ArrayList<Item>()
    private var job: Job? = null
    private val prefs get() = AppModel.ctx.getSharedPreferences("lumo_outbox", android.content.Context.MODE_PRIVATE)
    private val key get() = "q_" + (AppModel.myId ?: "")

    fun isOffline(e: Throwable): Boolean = when (e) {
        is java.io.IOException -> true
        is ApiError -> e.status == 0 || e.status == 502 || e.status == 503 || e.status == 504
        else -> false
    }

    fun add(i: Item) { items.removeAll { it.pid == i.pid }; items += i; save(); arm() }
    fun remove(pid: Int) { if (items.removeAll { it.pid == pid }) save() }

    /** после входа: поднять неотправленное с прошлого раза и показать в чатах с часиками */
    fun restore() {
        val me = AppModel.myId ?: return
        val arr = runCatching { JSONArray(prefs.getString(key, "[]")) }.getOrNull() ?: return
        if (arr.length() == 0) return
        items.clear()
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            val meta = runCatching { JSONObject(o.optString("meta", "{}")) }.getOrDefault(JSONObject())
            val body = if (o.isNull("body")) null else o.optString("body")
            val replyTo = if (o.isNull("replyTo")) null else o.optInt("replyTo")
            val t = Message.pending(o.getString("chatId"), me, o.getString("kind"), body, meta, replyTo)
            AppModel.messages[t.chatId] = (AppModel.messages[t.chatId] ?: emptyList()) + t
            items += Item(t.id, t.chatId, t.kind, body, if (o.isNull("media")) null else o.optString("media"), meta.toString(), replyTo,
                if (o.isNull("forwardedFrom")) null else o.optString("forwardedFrom"))
        }
        save(); arm()
    }

    private fun save() {
        val arr = JSONArray()
        items.forEach { arr.put(JSONObject().put("chatId", it.chatId).put("kind", it.kind).put("body", it.body ?: JSONObject.NULL)
            .put("media", it.media ?: JSONObject.NULL).put("meta", it.meta).put("replyTo", it.replyTo ?: JSONObject.NULL)
            .put("forwardedFrom", it.forwardedFrom ?: JSONObject.NULL)) }
        prefs.edit().putString(key, arr.toString()).apply()
    }

    private fun arm() {
        if (job?.isActive == true || items.isEmpty()) return
        job = AppModel.scope.launch {
            while (items.isNotEmpty()) {
                delay(6000)
                for (it in items.toList()) {
                    val ok = AppModel.send(it.chatId, it.kind, it.body, it.media, runCatching { JSONObject(it.meta) }.getOrDefault(JSONObject()),
                        it.replyTo, it.forwardedFrom, pendingId = it.pid)
                    if (!ok && items.any { x -> x.pid == it.pid }) break
                }
            }
        }
    }
}
