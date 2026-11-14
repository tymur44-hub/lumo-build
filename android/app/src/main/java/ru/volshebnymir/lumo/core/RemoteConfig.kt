package ru.volshebnymir.lumo.core

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

data class RemoteWall(val n: Int, val url: String, val premium: Boolean, val section: String? = null) { val id get() = 1000 + n }
data class RemoteSticker(val id: String, val url: String)
data class RemotePack(val id: String, val name: String, val items: List<RemoteSticker>)
data class Announce(val id: String, val title: String, val text: String, val url: String?, val button: String?)

const val STICKER_IMG_PREFIX = "img:"

/** Настройки с сервера (lm_config: app / look / announce) — то, что меняется без выпуска новой версии.
 *  Последний полученный вариант хранится на устройстве. */
object RemoteConfig {
    private lateinit var ctx: Context
    var cfg by mutableStateOf(JSONObject())
        private set
    private var lastFetch = 0L
    private val prefs get() = ctx.getSharedPreferences("lumo_rcfg", Context.MODE_PRIVATE)

    fun init(c: Context) {
        if (::ctx.isInitialized) return
        ctx = c.applicationContext
        runCatching { cfg = JSONObject(prefs.getString("cfg", "{}") ?: "{}") }
    }

    suspend fun refresh(force: Boolean = false) {
        if (!::ctx.isInitialized) return
        if (!force && System.currentTimeMillis() - lastFetch < 60_000) return
        lastFetch = System.currentTimeMillis()
        val o = runCatching { Api.rpc("lm_get_config") as? JSONObject }.getOrNull() ?: return
        prefs.edit().putString("cfg", o.toString()).apply()
        withContext(Dispatchers.Main) { cfg = o }
        runCatching { syncGames() }
    }

    private val app get() = cfg.optJSONObject("app") ?: JSONObject()
    private val look get() = cfg.optJSONObject("look") ?: JSONObject()

    /** функция включена, пока сервер явно не выключил её */
    fun on(feature: String): Boolean = app.optJSONObject("features")?.let { if (it.has(feature)) it.optBoolean(feature, true) else true } ?: true
    val legacyLogin get() = app.optJSONObject("features")?.optBoolean("legacy_login", false) ?: false
    val secretNumbers: List<String> get() = app.optJSONObject("login")?.optJSONArray("secret_numbers")?.let { a -> (0 until a.length()).map { a.optString(it) } } ?: listOf("79999999999")

    // обязательное обновление
    private val minV get() = app.optJSONObject("min_version") ?: JSONObject()
    val build: Long get() = runCatching {
        val pi = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
        if (android.os.Build.VERSION.SDK_INT >= 28) pi.longVersionCode else @Suppress("DEPRECATION") pi.versionCode.toLong()
    }.getOrDefault(0L)
    val needsUpdate get() = ::ctx.isInitialized && minV.optLong("android", 0) > build
    val updateText get() = minV.optString("text").ifBlank { "Вышла новая версия Lumo. Обновите приложение, чтобы продолжить." }
    val updateUrl get() = minV.optString("url_android").ifBlank { null }

    // объявление
    val announce: Announce? get() {
        val a = cfg.optJSONObject("announce") ?: return null
        val text = a.optString("text").ifBlank { return null }
        a.optJSONArray("platforms")?.let { p -> if ((0 until p.length()).none { p.optString(it) == "android" }) return null }
        a.optString("until").ifBlank { null }?.let { u -> runCatching { java.time.Instant.parse(u) }.getOrNull()?.let { if (it.isBefore(java.time.Instant.now())) return null } }
        return Announce(a.opt("id")?.toString() ?: text, a.optString("title").ifBlank { "Объявление" }, text,
            a.optString("url").ifBlank { null }, a.optString("button").ifBlank { null })
    }

    // оформление
    private fun hex(s: String?): Long? {
        val h = s?.removePrefix("#") ?: return null
        return if (h.length == 6) h.toLongOrNull(16)?.let { 0xFF000000L or it } else null
    }
    private fun arr(o: JSONObject, k: String): List<JSONObject> = o.optJSONArray(k)?.let { a -> (0 until a.length()).mapNotNull { a.optJSONObject(it) } } ?: emptyList()

    /** [{a:"#rrggbb", b:"#rrggbb", premium:true}] */
    val accents: List<Triple<Long, Long, Boolean>> get() = arr(look, "accents").mapNotNull { j ->
        val a = hex(j.optString("a")) ?: return@mapNotNull null
        val b = hex(j.optString("b")) ?: return@mapNotNull null
        Triple(a, b, j.optBoolean("premium", false))
    }
    /** [{n:1, url, premium}] — номер обоев 1000+n */
    val walls: List<RemoteWall> get() = arr(look, "walls").mapNotNull { j ->
        if (!j.has("n")) return@mapNotNull null
        val u = j.optString("url").ifBlank { return@mapNotNull null }
        RemoteWall(j.optInt("n"), u, j.optBoolean("premium", false), j.optString("section").ifBlank { null })
    }
    fun wall(i: Int) = walls.firstOrNull { it.id == i }
    /** [{id, name, items:[{id, url}]}] */
    val packs: List<RemotePack> get() = arr(look, "stickers").mapNotNull { p ->
        val id = p.optString("id").ifBlank { return@mapNotNull null }
        val items = arr(p, "items").mapNotNull { i -> i.optString("url").ifBlank { null }?.let { RemoteSticker(i.optString("id").ifBlank { it }, it) } }
        if (items.isEmpty()) null else RemotePack(id, p.optString("name").ifBlank { id }, items)
    }

    // игры: страница скачивается один раз на новую версию
    private val gamesFile get() = File(ctx.filesDir, "games.html")
    fun gamesHtml(): String? {
        if (!::ctx.isInitialized || prefs.getInt("games_ver", 0) <= 0) return null
        return runCatching { gamesFile.readText() }.getOrNull()?.takeIf { it.contains("/*CFG*/") }
    }
    private suspend fun syncGames() {
        val ver = app.optInt("games_ver", 0)
        if (ver <= 0) { if (prefs.getInt("games_ver", 0) != 0) { prefs.edit().putInt("games_ver", 0).apply(); gamesFile.delete() }; return }
        if (prefs.getInt("games_ver", 0) == ver) return
        val o = Api.rpc("lm_games_html") as? JSONObject ?: return
        val html = o.optString("html")
        if (!html.contains("/*CFG*/") || o.optInt("ver") != ver) return
        withContext(Dispatchers.IO) { gamesFile.writeText(html) }
        prefs.edit().putInt("games_ver", ver).apply()
    }
}
