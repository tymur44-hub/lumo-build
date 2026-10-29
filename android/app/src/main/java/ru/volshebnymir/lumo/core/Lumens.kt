package ru.volshebnymir.lumo.core

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.util.Date

data class ChatCfg(val reactions: List<String>?, val linked: String?)
data class LedgerRow(val id: Long, val delta: Long, val kind: String, val refUser: String?, val refMessage: Long?, val at: Date)

/** Люмены — внутренняя валюта Lumo, а также настройки каналов (реакции, обсуждение) и счётчики комментариев */
object Lumens {
    var balance by mutableStateOf(0L)
    var streak by mutableStateOf(0)
    var canClaim by mutableStateOf(false)
    val tips = mutableStateMapOf<Int, Long>()
    val comments = mutableStateMapOf<Int, Int>()
    val cfg = mutableStateMapOf<String, ChatCfg>()
    private val askedTips = HashSet<Int>()
    private val askedComments = HashSet<Int>()
    private val pendTips = LinkedHashSet<Int>()
    private val pendComments = LinkedHashSet<Int>()
    private var job: Job? = null

    fun reset() {
        balance = 0; streak = 0; canClaim = false
        tips.clear(); comments.clear(); cfg.clear()
        askedTips.clear(); askedComments.clear(); pendTips.clear(); pendComments.clear()
    }

    suspend fun load() {
        val j = runCatching { Api.rpc("lm_wallet_me") }.getOrNull() as? JSONObject ?: return
        balance = j.optLong("balance"); streak = j.optInt("streak"); canClaim = j.optBoolean("can_claim")
    }

    /** Ежедневный бонус: возвращает, сколько люменов получено */
    suspend fun claim(): Int {
        val j = Api.rpc("lm_wallet_daily") as? JSONObject
        load()
        return j?.optInt("amount") ?: 0
    }

    suspend fun tip(msgId: Int, amount: Int) {
        Api.rpc("lm_wallet_tip", jsonOf("p_message" to msgId, "p_amount" to amount))
        load()
        tips[msgId] = (tips[msgId] ?: 0L) + amount
    }

    suspend fun send(userId: String, amount: Int) {
        Api.rpc("lm_wallet_send", jsonOf("p_user" to userId, "p_amount" to amount))
        load()
    }

    suspend fun history(): List<LedgerRow> {
        val a = runCatching { Api.rpc("lm_wallet_history", jsonOf("p_limit" to 80)) as? JSONArray }.getOrNull().objects()
        return a.map { LedgerRow(it.optLong("id"), it.optLong("delta"), it.optString("kind"), it.str("ref_user"), if (it.isNull("ref_message")) null else it.optLong("ref_message"),
            it.date("created_at") ?: Date()) }
    }

    suspend fun loadCfg() {
        val rows = runCatching { Api.select("lm_chats", mapOf("select" to "id,reactions,linked_chat_id", "type" to "eq.channel")) }.getOrNull() ?: return
        for (o in rows) {
            val id = o.str("id") ?: continue
            val r = o.optJSONArray("reactions")?.let { a -> (0 until a.length()).map { a.optString(it) } }
            cfg[id] = ChatCfg(r, o.str("linked_chat_id"))
        }
    }

    fun allowed(chatId: String?): List<String>? = chatId?.let { cfg[it]?.reactions }
    fun linked(chatId: String?): String? = chatId?.let { cfg[it]?.linked }

    /** Подгружаем сумму люменов под сообщением и число комментариев пачкой */
    fun request(id: Int, withComments: Boolean) {
        if (id <= 0) return
        if (askedTips.add(id)) pendTips.add(id)
        if (withComments && askedComments.add(id)) pendComments.add(id)
        if (pendTips.isEmpty() && pendComments.isEmpty()) return
        job?.cancel()
        job = AppModel.scope.launch { delay(250); flush() }
    }

    fun refreshComments(id: Int) { askedComments.remove(id); request(id, true) }

    private suspend fun flush() {
        val t = pendTips.toList(); pendTips.clear()
        val c = pendComments.toList(); pendComments.clear()
        if (t.isNotEmpty()) {
            val a = runCatching { Api.rpc("lm_tip_totals", jsonOf("p_ids" to JSONArray(t))) as? JSONArray }.getOrNull().objects()
            for (o in a) tips[o.optInt("message_id")] = o.optLong("total")
        }
        if (c.isNotEmpty()) {
            val a = runCatching { Api.rpc("lm_comment_counts", jsonOf("p_posts" to JSONArray(c))) as? JSONArray }.getOrNull().objects()
            val got = a.associate { it.optInt("post") to it.optInt("n") }
            for (id in c) comments[id] = got[id] ?: 0
        }
    }
}
