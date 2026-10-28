package ru.volshebnymir.lumo.core

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.CompletableDeferred
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONArray
import org.json.JSONObject

/** Живое соединение с сервером (Supabase Realtime, протокол Phoenix): сообщения, звонки, «печатает…», «в сети». Всё — на главном потоке. */
object Realtime {
    class Channel(val topic: String, val changes: JSONArray, val presenceKey: String) {
        var joinRef = ""
        var joined = false
        var trackPayload: JSONObject? = null
        val waiters = mutableListOf<CompletableDeferred<Unit>>()
        var onBroadcast: ((String, JSONObject) -> Unit)? = null
        var onChange: ((JSONObject) -> Unit)? = null
        var onPresenceState: ((JSONObject) -> Unit)? = null
        var onPresenceDiff: ((JSONObject, JSONObject) -> Unit)? = null
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var ws: WebSocket? = null
    private var ref = 0
    private val channels = mutableMapOf<String, Channel>()
    private var heartbeat: Job? = null
    private var reconnect: Job? = null
    private var backoff = 1.0
    var isOpen = false
        private set
    private var wanted = false
    var onReconnect: (() -> Unit)? = null
    var onState: ((Boolean) -> Unit)? = null

    private fun nextRef(): String { ref += 1; return ref.toString() }

    fun connect() {
        wanted = true
        if (ws != null) return
        val sock = Api.http.newWebSocket(Request.Builder().url(Config.realtimeUrl).build(), object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) { scope.launch { opened(webSocket) } }
            override fun onMessage(webSocket: WebSocket, text: String) {
                scope.launch { if (webSocket === ws) runCatching { handle(JSONObject(text)) } }
            }
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) { scope.launch { if (webSocket === ws) dropped() } }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) { scope.launch { if (webSocket === ws) dropped() } }
        })
        ws = sock
    }

    fun disconnect() {
        wanted = false
        reconnect?.cancel(); heartbeat?.cancel()
        ws?.close(1000, null); ws = null
        isOpen = false
        channels.values.forEach { it.joined = false; resumeAll(it) }
        channels.clear()
    }

    /** После возврата в приложение — проверить, живо ли соединение */
    fun ensure() { if (wanted && ws == null) connect() }

    private fun opened(s: WebSocket) {
        if (s !== ws) return
        isOpen = true
        backoff = 1.0
        heartbeat?.cancel()
        heartbeat = scope.launch {
            while (true) { delay(25_000); push("phoenix", "heartbeat", JSONObject()) }
        }
        channels.values.forEach { join(it) }
        onState?.invoke(true)
        onReconnect?.invoke()
    }

    private fun dropped() {
        heartbeat?.cancel()
        ws?.cancel(); ws = null
        isOpen = false
        channels.values.forEach { it.joined = false }
        if (!wanted) return
        onState?.invoke(false)
        reconnect?.cancel()
        val d = backoff
        backoff = minOf(backoff * 2, 20.0)
        reconnect = scope.launch { runCatching { Net.pick() }; delay((d * 1000).toLong()); connect() }
    }

    private fun push(topic: String, event: String, payload: JSONObject, joinRef: String? = null, r: String? = null) {
        val s = ws ?: return
        if (!isOpen) return
        val m = JSONObject().put("topic", topic).put("event", event).put("payload", payload).put("ref", r ?: nextRef())
        if (joinRef != null) m.put("join_ref", joinRef)
        s.send(m.toString())
    }

    fun channel(name: String, changes: JSONArray = JSONArray(), presenceKey: String = ""): Channel {
        val topic = "realtime:$name"
        channels[topic]?.let { return it }
        val c = Channel(topic, changes, presenceKey)
        channels[topic] = c
        if (isOpen) join(c) else connect()
        return c
    }

    fun leave(name: String) {
        val topic = "realtime:$name"
        val c = channels.remove(topic) ?: return
        resumeAll(c)
        if (c.joined) push(topic, "phx_leave", JSONObject(), c.joinRef)
    }

    private fun join(c: Channel) {
        scope.launch {
            val token = runCatching { Api.token() }.getOrNull()
            if (channels[c.topic] !== c || !isOpen) return@launch
            c.joinRef = nextRef()
            val cfg = JSONObject()
                .put("broadcast", JSONObject().put("self", false).put("ack", false))
                .put("presence", JSONObject().put("key", c.presenceKey))
                .put("postgres_changes", c.changes)
                .put("private", false)
            val p = JSONObject().put("config", cfg)
            if (token != null) p.put("access_token", token)
            push(c.topic, "phx_join", p, c.joinRef, c.joinRef)
        }
    }

    private fun resumeAll(c: Channel) {
        val w = c.waiters.toList(); c.waiters.clear()
        w.forEach { it.complete(Unit) }
    }

    suspend fun waitJoined(c: Channel, timeoutMs: Long = 6000) {
        if (c.joined) return
        val d = CompletableDeferred<Unit>()
        c.waiters.add(d)
        withTimeoutOrNull(timeoutMs) { d.await() }
        c.waiters.remove(d)
    }

    fun broadcast(c: Channel, event: String, payload: JSONObject) {
        push(c.topic, "broadcast", JSONObject().put("type", "broadcast").put("event", event).put("payload", payload), c.joinRef)
    }

    fun track(c: Channel, payload: JSONObject) {
        c.trackPayload = payload
        if (c.joined) push(c.topic, "presence", JSONObject().put("type", "presence").put("event", "track").put("payload", payload), c.joinRef)
    }

    fun untrack(c: Channel) {
        c.trackPayload = null
        if (c.joined) push(c.topic, "presence", JSONObject().put("type", "presence").put("event", "untrack"), c.joinRef)
    }

    fun updateToken(token: String) {
        channels.values.filter { it.joined }.forEach { push(it.topic, "access_token", JSONObject().put("access_token", token), it.joinRef) }
    }

    private fun handle(j: JSONObject) {
        val topic = j.optString("topic")
        val event = j.optString("event")
        val payload = j.optJSONObject("payload") ?: JSONObject()
        val c = channels[topic] ?: return
        when (event) {
            "phx_reply" -> {
                if (j.optString("ref") != c.joinRef) return
                if (payload.optString("status") == "ok") {
                    c.joined = true
                    resumeAll(c)
                    c.trackPayload?.let { track(c, it) }
                } else retryJoin(c, 3000)
            }
            "broadcast" -> c.onBroadcast?.invoke(payload.optString("event"), payload.optJSONObject("payload") ?: JSONObject())
            "postgres_changes" -> c.onChange?.invoke(payload.optJSONObject("data") ?: JSONObject())
            "presence_state" -> c.onPresenceState?.invoke(payload)
            "presence_diff" -> c.onPresenceDiff?.invoke(payload.optJSONObject("joins") ?: JSONObject(), payload.optJSONObject("leaves") ?: JSONObject())
            "phx_error", "phx_close" -> { c.joined = false; retryJoin(c, 2000) }
        }
    }

    private fun retryJoin(c: Channel, ms: Long) {
        scope.launch {
            delay(ms)
            if (channels[c.topic] === c && isOpen && !c.joined) join(c)
        }
    }
}
