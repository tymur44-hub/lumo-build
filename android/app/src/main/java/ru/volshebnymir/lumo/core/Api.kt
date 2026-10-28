package ru.volshebnymir.lumo.core

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.util.UUID
import java.util.concurrent.TimeUnit

object Config {
    const val SUPABASE = "https://foniukmpiukuwpcdvdhp.supabase.co"
    const val ANON = "sb_publishable_cE72E1dUPnfaVn8mPnc9sA_U2HO-mxN"
    const val EMAIL_DOMAIN = "@lumo.app"
    const val BUCKET = "lm-media"
    const val SITE = "https://volshebny-mir.ru/page322172009.html"
    /** Свой адрес сервера (прокси к Supabase) — чтобы Lumo работал в России без VPN */
    const val PROXY = "https://api.volshebny-mir.ru"
    val realtimeUrl get() = Net.base.replace("https://", "wss://") + "/realtime/v1/websocket?apikey=$ANON&vsn=1.0.0"
}

class ApiError(message: String, val status: Int) : Exception(message)

data class Session(val access: String, val refresh: String, val expiresAt: Long, val userId: String)

/**
 * Выбор адреса сервера: напрямую (supabase.co) или через свой прокси (api.volshebny-mir.ru).
 * В России supabase.co работает плохо (замедление Cloudflare), поэтому пробуем оба и берём тот, что отвечает.
 */
object Net {
    enum class Mode { DIRECT, PROXY, TUNNEL }

    @Volatile var base: String = Config.SUPABASE
        private set
    @Volatile var mode: Mode = Mode.DIRECT
        private set
    private val direct = Config.SUPABASE.toHttpUrl()
    private lateinit var prefs: android.content.SharedPreferences
    private val probe = OkHttpClient.Builder().connectTimeout(4, TimeUnit.SECONDS).readTimeout(6, TimeUnit.SECONDS).callTimeout(8, TimeUnit.SECONDS).build()
    // проверка через локальную точку (когда прямой путь и зеркало недоступны)
    private val tunProbe by lazy {
        OkHttpClient.Builder()
            .proxy(java.net.Proxy(java.net.Proxy.Type.SOCKS, java.net.InetSocketAddress.createUnresolved("127.0.0.1", Fast.PORT)))
            .connectTimeout(6, TimeUnit.SECONDS).readTimeout(8, TimeUnit.SECONDS).callTimeout(12, TimeUnit.SECONDS).build()
    }
    private var lastPick = 0L

    fun init(c: Context) {
        prefs = c.getSharedPreferences("lumo_net", Context.MODE_PRIVATE)
        base = prefs.getString("base", Config.SUPABASE) ?: Config.SUPABASE
        // в прошлый раз работал только локальный узел — поднимаем его сразу, не дожидаясь отказов
        if (prefs.getString("mode", "") == "TUNNEL") {
            mode = Mode.TUNNEL; base = Config.SUPABASE
            Thread { Fast.ensure() }.start()
        }
    }

    private fun ok(client: OkHttpClient, b: String): Boolean = runCatching {
        // большой ответ (48 КБ): провайдеры режут соединение после 16 КБ, мелкий запрос этого не покажет
        client.newCall(Request.Builder().url("$b/functions/v1/lumo/ping?kb=48").header("apikey", Config.ANON)
            .header("Authorization", "Bearer " + Config.ANON).build()).execute().use { it.isSuccessful && (it.body?.bytes()?.size ?: 0) > 40000 }
    }.getOrDefault(false)

    private fun set(m: Mode, b: String) {
        mode = m
        prefs.edit().putString("mode", m.name).apply()
        if (b != base) { base = b; prefs.edit().putString("base", b).apply() }
    }

    /** Когда режим — туннель, запросы клиента идут через локальную точку. */
    val proxySelector = object : java.net.ProxySelector() {
        private val socks = listOf(java.net.Proxy(java.net.Proxy.Type.SOCKS, java.net.InetSocketAddress.createUnresolved("127.0.0.1", Fast.PORT)))
        private val none = listOf(java.net.Proxy.NO_PROXY)
        override fun select(uri: java.net.URI?) = if (mode == Mode.TUNNEL) socks else none
        override fun connectFailed(uri: java.net.URI?, sa: java.net.SocketAddress?, e: java.io.IOException?) {}
    }

    private fun tunUntil() = prefs.getLong("tun_until", 0L)

    /** Проверить пути и выбрать работающий (не чаще раза в 20 секунд). Локальный узел поднимается параллельно.
     *  Если недавно запросы зависали напрямую — держимся за узел: проверка «прямой: ок» обманчива, режутся только большие ответы. */
    suspend fun pick(force: Boolean = false) = withContext(Dispatchers.IO) {
        if (!force && System.currentTimeMillis() - lastPick < 20_000) return@withContext
        lastPick = System.currentTimeMillis()
        kotlinx.coroutines.coroutineScope {
            val a = async { ok(probe, Config.SUPABASE) }
            val b = async { ok(probe, Config.PROXY) }
            val t = async { Fast.ensure() && ok(tunProbe, Config.SUPABASE) }
            val rd = a.await(); val rp = b.await(); val rt = t.await()
            val sticky = System.currentTimeMillis() < tunUntil()
            when {
                rp -> set(Mode.PROXY, Config.PROXY)
                sticky && rt -> set(Mode.TUNNEL, Config.SUPABASE)
                rd -> set(Mode.DIRECT, Config.SUPABASE)
                rt -> set(Mode.TUNNEL, Config.SUPABASE)
                else -> {}
            }
        }
    }

    /** Запрос завис при «рабочем» прямом пути — переходим на локальный узел на 30 минут */
    suspend fun escalate(): Boolean = withContext(Dispatchers.IO) {
        if (mode == Mode.TUNNEL) return@withContext false
        if (!(Fast.ensure() && ok(tunProbe, Config.SUPABASE))) return@withContext false
        prefs.edit().putLong("tun_until", System.currentTimeMillis() + 30 * 60_000L).apply()
        set(Mode.TUNNEL, Config.SUPABASE)
        true
    }

    /** Ссылка на файл через выбранный адрес */
    fun px(url: String?): String? {
        if (url == null || base == Config.SUPABASE) return url
        return if (url.startsWith(Config.SUPABASE)) base + url.removePrefix(Config.SUPABASE) else url
    }

    /** Подменяет адрес supabase.co на прокси во всех запросах (API, файлы, картинки, живое соединение) */
    val interceptor = okhttp3.Interceptor { chain ->
        val req = chain.request()
        val b = base
        if (b != Config.SUPABASE && req.url.host == direct.host) {
            val t = b.toHttpUrl()
            chain.proceed(req.newBuilder().url(req.url.newBuilder().scheme(t.scheme).host(t.host).port(t.port).build()).build())
        } else chain.proceed(req)
    }
}

/** Сервер Lumo (Supabase): вход, база (PostgREST), файлы, функции */
object Api {
    val http: OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(Net.interceptor)
        .proxySelector(Net.proxySelector)
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(25, TimeUnit.SECONDS)
        .writeTimeout(180, TimeUnit.SECONDS)
        .pingInterval(20, TimeUnit.SECONDS)
        .build()

    private lateinit var ctx: Context
    @Volatile var session: Session? = null
        private set
    var onSession: ((Session?) -> Unit)? = null
    private val refreshLock = Mutex()

    fun init(c: Context) {
        ctx = c.applicationContext
        Net.init(ctx)
        val p = ctx.getSharedPreferences("lumo_auth", Context.MODE_PRIVATE)
        val a = p.getString("a", null); val r = p.getString("r", null); val u = p.getString("u", null)
        if (a != null && r != null && u != null) session = Session(a, r, p.getLong("e", 0), u)
    }

    val userId: String? get() = session?.userId

    private fun setSession(s: Session?) {
        session = s
        val p = ctx.getSharedPreferences("lumo_auth", Context.MODE_PRIVATE).edit()
        if (s == null) p.clear() else p.putString("a", s.access).putString("r", s.refresh).putLong("e", s.expiresAt).putString("u", s.userId)
        p.apply()
        onSession?.invoke(s)
    }

    private fun applyAuth(j: JSONObject) {
        val at = j.optString("access_token"); val rt = j.optString("refresh_token")
        if (at.isEmpty() || rt.isEmpty()) throw ApiError("Не удалось войти", 0)
        val exp = if (j.has("expires_at")) j.optLong("expires_at") else System.currentTimeMillis() / 1000 + j.optLong("expires_in", 3600)
        val uid = j.optJSONObject("user")?.optString("id")?.takeIf { it.isNotEmpty() } ?: session?.userId ?: ""
        setSession(Session(at, rt, exp, uid))
    }

    suspend fun signIn(username: String, password: String) {
        val j = raw("POST", "/auth/v1/token", mapOf("grant_type" to "password"),
            JSONObject().put("email", username + Config.EMAIL_DOMAIN).put("password", password), auth = false) as? JSONObject ?: JSONObject()
        applyAuth(j)
    }

    suspend fun register(username: String, password: String, name: String) {
        raw("POST", "/rest/v1/rpc/lm_register", body = JSONObject().put("p_username", username).put("p_password", password).put("p_name", name), auth = false)
        signIn(username, password)
    }

    suspend fun verifyMagic(tokenHash: String) {
        val j = raw("POST", "/auth/v1/verify", body = JSONObject().put("type", "magiclink").put("token_hash", tokenHash), auth = false) as? JSONObject ?: JSONObject()
        applyAuth(j)
    }

    suspend fun signOut() {
        if (session != null) runCatching { raw("POST", "/auth/v1/logout", mapOf("scope" to "local"), JSONObject()) }
        setSession(null)
    }

    fun forget() = setSession(null)

    suspend fun token(): String {
        val s = session ?: throw ApiError("Войдите заново", 401)
        if (s.expiresAt - 60 > System.currentTimeMillis() / 1000) return s.access
        refreshLock.withLock {
            val cur = session ?: throw ApiError("Войдите заново", 401)
            if (cur.expiresAt - 60 > System.currentTimeMillis() / 1000) return cur.access
            try {
                val j = raw("POST", "/auth/v1/token", mapOf("grant_type" to "refresh_token"),
                    JSONObject().put("refresh_token", cur.refresh), auth = false) as? JSONObject ?: JSONObject()
                applyAuth(j)
            } catch (e: ApiError) {
                if (e.status in listOf(400, 401, 403)) setSession(null)
                throw e
            }
        }
        return session?.access ?: throw ApiError("Войдите заново", 401)
    }

    suspend fun raw(
        method: String, path: String, query: Map<String, String> = emptyMap(), body: Any? = null,
        headers: Map<String, String> = emptyMap(), auth: Boolean = true, bytes: ByteArray? = null, contentType: String? = null,
    ): Any? {
        val tk = if (auth) token() else null
        return withContext(Dispatchers.IO) {
            val ub = (Config.SUPABASE + path).toHttpUrl().newBuilder()
            query.forEach { (k, v) -> ub.addQueryParameter(k, v) }
            val rb = Request.Builder().url(ub.build()).header("apikey", Config.ANON)
            if (tk != null) rb.header("Authorization", "Bearer $tk")
            headers.forEach { (k, v) -> rb.header(k, v) }
            val reqBody = when {
                bytes != null -> bytes.toRequestBody((contentType ?: "application/octet-stream").toMediaType())
                body != null -> body.toString().toRequestBody("application/json".toMediaType())
                method == "GET" -> null
                else -> "".toRequestBody("application/json".toMediaType())
            }
            rb.method(method, reqBody)
            // нет связи — проверяем, какой адрес сервера сейчас работает (напрямую или через прокси), и пробуем ещё раз
            val resp0 = try { http.newCall(rb.build()).execute() } catch (e: java.io.IOException) {
                val was = Net.base; val wasMode = Net.mode
                Net.pick(force = true)
                if (Net.base == was && Net.mode == wasMode && Net.mode != Net.Mode.TUNNEL && !Net.escalate()) throw e
                http.newCall(rb.build()).execute()
            }
            resp0.use { resp ->
                val text = resp.body?.string() ?: ""
                val obj: Any? = if (text.isBlank()) null else runCatching { JSONTokener(text).nextValue() }.getOrNull()
                if (!resp.isSuccessful) {
                    val j = obj as? JSONObject
                    var msg = j?.optString("message")?.takeIf { it.isNotEmpty() } ?: j?.optString("msg")?.takeIf { it.isNotEmpty() }
                        ?: j?.optString("error_description")?.takeIf { it.isNotEmpty() } ?: j?.optString("error")?.takeIf { it.isNotEmpty() }
                        ?: "Ошибка сервера (${resp.code})"
                    if (msg.contains("Invalid login")) msg = "Неверный юзернейм или пароль"
                    throw ApiError(msg, resp.code)
                }
                obj
            }
        }
    }

    suspend fun rpc(name: String, params: JSONObject = JSONObject()): Any? = raw("POST", "/rest/v1/rpc/$name", body = params)

    suspend fun select(table: String, q: Map<String, String>): List<JSONObject> = (raw("GET", "/rest/v1/$table", q) as? JSONArray).objects()

    suspend fun insert(table: String, row: JSONObject): JSONObject? =
        (raw("POST", "/rest/v1/$table", body = row, headers = mapOf("Prefer" to "return=representation")) as? JSONArray)?.optJSONObject(0)

    suspend fun insertQuiet(table: String, row: JSONObject) {
        raw("POST", "/rest/v1/$table", body = row, headers = mapOf("Prefer" to "return=minimal"))
    }

    suspend fun update(table: String, match: Map<String, String>, values: JSONObject) {
        raw("PATCH", "/rest/v1/$table", match.mapValues { "eq." + it.value }, values, mapOf("Prefer" to "return=minimal"))
    }

    suspend fun delete(table: String, match: Map<String, String>) {
        raw("DELETE", "/rest/v1/$table", match.mapValues { "eq." + it.value }, headers = mapOf("Prefer" to "return=minimal"))
    }

    suspend fun upload(data: ByteArray, ext: String, contentType: String): String {
        val uid = userId ?: throw ApiError("Войдите заново", 401)
        val path = "$uid/${UUID.randomUUID().toString().take(8)}.$ext"
        raw("POST", "/storage/v1/object/${Config.BUCKET}/$path", headers = mapOf("x-upsert" to "false", "Cache-Control" to "3600"),
            bytes = data, contentType = contentType)
        return "${Config.SUPABASE}/storage/v1/object/public/${Config.BUCKET}/$path"
    }

    suspend fun botFunction(path: String, body: JSONObject): Any? = raw("POST", "/functions/v1/lumo-bots$path", body = body, auth = true)

    suspend fun function(path: String, body: JSONObject? = null, auth: Boolean = true): Any? =
        raw(if (body == null) "GET" else "POST", "/functions/v1/lumo$path", body = body, auth = auth)
}

fun JSONArray?.objects(): List<JSONObject> {
    if (this == null) return emptyList()
    return (0 until length()).mapNotNull { optJSONObject(it) }
}

fun JSONObject.str(k: String): String? = if (isNull(k) || !has(k)) null else optString(k).takeIf { it.isNotEmpty() }
fun JSONObject.int(k: String): Int? = if (isNull(k) || !has(k)) null else opt(k).let { (it as? Number)?.toInt() ?: it.toString().toIntOrNull() }
fun JSONObject.dbl(k: String): Double? = if (isNull(k) || !has(k)) null else opt(k).let { (it as? Number)?.toDouble() ?: it.toString().toDoubleOrNull() }
fun JSONObject.bool(k: String): Boolean = if (isNull(k) || !has(k)) false else opt(k).let { it == true || it == 1 || it == "true" }
fun JSONObject.obj(k: String): JSONObject = optJSONObject(k) ?: JSONObject()
fun jsonOf(vararg p: Pair<String, Any?>): JSONObject = JSONObject().apply { p.forEach { (k, v) -> put(k, v ?: JSONObject.NULL) } }
