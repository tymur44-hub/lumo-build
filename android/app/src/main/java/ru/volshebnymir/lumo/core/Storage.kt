package ru.volshebnymir.lumo.core

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.Interceptor
import okhttp3.Request
import org.json.JSONObject
import java.io.File

/** Вид данных: по нему считаются трафик и место на телефоне */
enum class DataKind(val title: String, val color: Long) {
    Video("Видео", 0xFF3D82F6), Photo("Фотографии", 0xFF6CC3F5), Messages("Сообщения", 0xFF5A4FD8), Sticker("Стикеры", 0xFFF0A23B),
    Voice("Голосовые", 0xFFA855F7), File("Файлы", 0xFF4CC764), Music("Музыка", 0xFFEF5350), Calls("Звонки", 0xFFF4B43A);

    companion object {
        fun ofType(ct: String?, url: String = ""): DataKind {
            val t = ct?.lowercase() ?: ""
            return when {
                t.startsWith("image/") -> if (url.contains("sticker")) Sticker else Photo
                t.startsWith("video/") -> Video
                t.startsWith("audio/") -> Voice
                t.contains("json") || t.startsWith("text/") || t.isEmpty() -> Messages
                else -> File
            }
        }
    }
}

/** Мобильная сеть или Wi-Fi */
object NetType {
    lateinit var ctx: Context
    val cellular: Boolean get() = runCatching {
        val cm = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val c = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        c.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) && !c.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }.getOrDefault(false)
}

/** Статистика трафика: [сеть][вид] = отправлено / получено */
object NetStats {
    private lateinit var ctx: Context
    private val prefs get() = ctx.getSharedPreferences("lumo_netstats", Context.MODE_PRIVATE)
    private val lock = Any()
    private val sent = HashMap<String, Long>()
    private val recv = HashMap<String, Long>()
    /** меняется при каждом сохранении — экраны перерисовываются */
    var rev by mutableLongStateOf(0L)
        private set
    var since by mutableLongStateOf(0L)
        private set
    private var dirty = false

    fun init(c: Context) {
        ctx = c.applicationContext; NetType.ctx = ctx
        val raw = runCatching { JSONObject(prefs.getString("data", "{}") ?: "{}") }.getOrDefault(JSONObject())
        raw.optJSONObject("s")?.let { o -> o.keys().forEach { sent[it] = o.optLong(it) } }
        raw.optJSONObject("r")?.let { o -> o.keys().forEach { recv[it] = o.optLong(it) } }
        since = prefs.getLong("since", 0L).takeIf { it > 0 } ?: System.currentTimeMillis().also { prefs.edit().putLong("since", it).apply() }
        AppModel.scope.launch { while (true) { kotlinx.coroutines.delay(5000); flush() } }
    }
    private fun key(net: String, k: DataKind) = "$net.${k.name}"

    fun add(k: DataKind, sentBytes: Long = 0, recvBytes: Long = 0) {
        if (sentBytes <= 0 && recvBytes <= 0 || !::ctx.isInitialized) return
        val net = if (NetType.cellular) "cell" else "wifi"
        synchronized(lock) {
            if (sentBytes > 0) sent[key(net, k)] = (sent[key(net, k)] ?: 0) + sentBytes
            if (recvBytes > 0) recv[key(net, k)] = (recv[key(net, k)] ?: 0) + recvBytes
            dirty = true
        }
    }
    fun flush() {
        if (!::ctx.isInitialized) return
        val js = synchronized(lock) {
            if (!dirty) return
            dirty = false
            JSONObject().put("s", JSONObject(sent as Map<*, *>)).put("r", JSONObject(recv as Map<*, *>)).toString()
        }
        prefs.edit().putString("data", js).apply()
        AppModel.scope.launch { rev++ }
    }
    /** net: null — обе сети, "cell", "wifi" */
    fun sent(k: DataKind, net: String?) = synchronized(lock) { (net?.let { listOf(it) } ?: listOf("cell", "wifi")).sumOf { sent[key(it, k)] ?: 0L } }
    fun recv(k: DataKind, net: String?) = synchronized(lock) { (net?.let { listOf(it) } ?: listOf("cell", "wifi")).sumOf { recv[key(it, k)] ?: 0L } }
    fun total(k: DataKind, net: String?) = sent(k, net) + recv(k, net)
    fun total(net: String?) = DataKind.entries.sumOf { total(it, net) }
    fun reset() {
        synchronized(lock) { sent.clear(); recv.clear(); dirty = false }
        since = System.currentTimeMillis()
        prefs.edit().putString("data", "{}").putLong("since", since).apply()
        rev++
    }

    /** считает всё, что идёт через общий HTTP-клиент (картинки, файлы, запросы к серверу) */
    val interceptor = Interceptor { chain ->
        val req: Request = chain.request()
        val resp = chain.proceed(req)
        runCatching {
            val url = req.url.toString()
            val out = req.body?.contentLength()?.takeIf { it > 0 } ?: 0L
            val inn = resp.body?.contentLength()?.takeIf { it > 0 } ?: 0L
            val reqKind = DataKind.ofType(req.body?.contentType()?.toString(), url)
            val respKind = DataKind.ofType(resp.header("Content-Type"), url)
            if (out > 0) add(if (url.contains("/storage/v1/object/") && reqKind != DataKind.Messages) reqKind else DataKind.Messages, sentBytes = out + 400)
            else add(DataKind.Messages, sentBytes = 400)
            add(respKind, recvBytes = inn + 300)
        }
        resp
    }
}


/** Автозагрузка медиа для одной сети */
data class AutoDl(val enabled: Boolean = true, val photos: Boolean = true, val videos: Boolean = true, val files: Boolean = true, val mediaMb: Double, val filesMb: Double) {
    val summary: String get() {
        if (!enabled || !(photos || videos || files)) return "Выключена"
        val parts = mutableListOf<String>()
        if (photos || videos) parts += "Медиа (${mb(mediaMb)})"
        if (files) parts += "файлы (${mb(filesMb)})"
        return parts.joinToString(", ")
    }
    fun json() = JSONObject().put("e", enabled).put("p", photos).put("v", videos).put("f", files).put("m", mediaMb).put("fm", filesMb).toString()
    companion object {
        val CELL = AutoDl(mediaMb = 10.0, filesMb = 1.0)
        val WIFI = AutoDl(mediaMb = 15.0, filesMb = 3.0)
        fun mb(v: Double) = if (v >= 1) "${v.toInt()} МБ" else String.format(java.util.Locale.US, "%.1f МБ", v)
        fun parse(s: String?, def: AutoDl): AutoDl = runCatching {
            val o = JSONObject(s ?: return def)
            AutoDl(o.optBoolean("e", true), o.optBoolean("p", true), o.optBoolean("v", true), o.optBoolean("f", true), o.optDouble("m", def.mediaMb), o.optDouble("fm", def.filesMb))
        }.getOrDefault(def)
    }
}

object AutoDownload {
    private lateinit var ctx: Context
    private val prefs get() = ctx.getSharedPreferences("lumo_autodl", Context.MODE_PRIVATE)
    var cell by mutableStateOf(AutoDl.CELL)
        private set
    var wifi by mutableStateOf(AutoDl.WIFI)
        private set
    fun init(c: Context) {
        ctx = c.applicationContext
        cell = AutoDl.parse(prefs.getString("cell", null), AutoDl.CELL)
        wifi = AutoDl.parse(prefs.getString("wifi", null), AutoDl.WIFI)
    }
    fun set(cellular: Boolean, v: AutoDl) {
        if (cellular) cell = v else wifi = v
        prefs.edit().putString(if (cellular) "cell" else "wifi", v.json()).apply()
    }
    fun reset() { set(true, AutoDl.CELL); set(false, AutoDl.WIFI) }
    val isDefault get() = cell == AutoDl.CELL && wifi == AutoDl.WIFI
    val current get() = if (NetType.cellular) cell else wifi
    /** можно ли скачать сразу, без нажатия */
    fun allow(k: DataKind, bytes: Long?): Boolean {
        if (!::ctx.isInitialized) return true
        val a = current
        if (!a.enabled) return false
        return when (k) {
            DataKind.Photo -> a.photos
            DataKind.Video -> a.videos && bytes != null && bytes <= a.mediaMb * 1_048_576
            DataKind.File -> a.files && bytes != null && bytes <= a.filesMb * 1_048_576
            else -> true
        }
    }
}

/** Что и сколько лежит на телефоне */
object DeviceStorage {
    enum class Bucket(val title: String, val color: Long, val dir: String?) {
        Video("Видео", 0xFF3D82F6, "vcache"), Photo("Фотографии", 0xFF6CC3F5, "image_cache"), File("Файлы", 0xFF4CC764, "lumo-files"),
        Voice("Голосовые", 0xFFA855F7, "lumo-voice"), Chats("Сообщения", 0xFF5A4FD8, "lumo-cache"), Other("Другое", 0xFFE9893A, null)
    }
    lateinit var ctx: Context
    private val prefs get() = ctx.getSharedPreferences("lumo_storage", Context.MODE_PRIVATE)
    fun dir(b: Bucket): File? = b.dir?.let { File(ctx.cacheDir, it) }
    fun ensure(b: Bucket): File = dir(b)!!.apply { mkdirs() }

    private fun size(f: File): Long = if (f.isFile) f.length() else (f.listFiles()?.sumOf { size(it) } ?: 0L)

    fun usage(): Map<Bucket, Long> {
        val out = HashMap<Bucket, Long>()
        Bucket.entries.forEach { b -> if (b != Bucket.Other) out[b] = dir(b)?.let { size(it) } ?: 0L }
        val mine = Bucket.entries.mapNotNull { it.dir }.toSet()
        out[Bucket.Other] = (ctx.cacheDir.listFiles()?.filter { it.name !in mine }?.sumOf { size(it) } ?: 0L)
        return out
    }

    fun clear(sel: Set<Bucket>) {
        sel.forEach { b ->
            when (b) {
                Bucket.Other -> { val mine = Bucket.entries.mapNotNull { it.dir }.toSet(); ctx.cacheDir.listFiles()?.filter { it.name !in mine }?.forEach { it.deleteRecursively() } }
                Bucket.Video -> LumoPlayer.clear(ctx)
                Bucket.Photo -> runCatching { coil.Coil.imageLoader(ctx).let { it.diskCache?.clear(); it.memoryCache?.clear() } }
                else -> dir(b)?.listFiles()?.forEach { it.deleteRecursively() }
            }
        }
    }

    val freeSpace: Long get() = runCatching { android.os.StatFs(ctx.cacheDir.path).availableBytes }.getOrDefault(0L)

    var keepDays: Int
        get() = prefs.getInt("keep", 0)
        set(v) { prefs.edit().putInt("keep", v).apply() }
    var maxGb: Int
        get() = prefs.getInt("max", 0)
        set(v) { prefs.edit().putInt("max", v).apply() }

    /** удалить давно не открытое и лишнее */
    fun trim() {
        val files = listOf(Bucket.File, Bucket.Voice).flatMap { dir(it)?.listFiles()?.toList() ?: emptyList() }.toMutableList()
        if (keepDays > 0) {
            val edge = System.currentTimeMillis() - keepDays * 86_400_000L
            files.removeAll { if (it.lastModified() < edge) { it.delete(); true } else false }
            runCatching { if (keepDays <= 7) coil.Coil.imageLoader(ctx).diskCache?.clear() }
        }
        if (maxGb > 0) {
            val limit = maxGb * 1_073_741_824L
            var total = usage().filterKeys { it != Bucket.Chats && it != Bucket.Other }.values.sum()
            for (f in files.sortedBy { it.lastModified() }) { if (total <= limit) break; total -= f.length(); f.delete() }
            if (total > limit) { LumoPlayer.clear(ctx) }
        }
    }

    fun fmt(b: Long): String = when {
        b < 1024 -> "$b Б"
        b < 1_048_576 -> String.format(java.util.Locale.US, "%.1f КБ", b / 1024.0)
        b < 1_073_741_824 -> String.format(java.util.Locale.US, "%.1f МБ", b / 1_048_576.0)
        else -> String.format(java.util.Locale.US, "%.1f ГБ", b / 1_073_741_824.0)
    }
}

/** Файлы и голосовые: скачиваются один раз и дальше открываются с телефона */
object FileStore {
    private val mutex = Mutex()
    private fun name(url: String): String {
        val ext = url.substringBefore('?').substringAfterLast('.', "bin").take(8).lowercase()
        return Integer.toHexString(url.hashCode()) + "_" + url.length + "." + ext
    }
    private fun bucket(k: DataKind) = if (k == DataKind.Voice || k == DataKind.Music) DeviceStorage.Bucket.Voice else DeviceStorage.Bucket.File
    fun local(url: String, k: DataKind): File? {
        if (!::ctxReady.isInitialized) return null
        val f = File(DeviceStorage.ensure(bucket(k)), name(url))
        return if (f.exists() && f.length() > 0) f.also { it.setLastModified(System.currentTimeMillis()) } else null
    }
    private lateinit var ctxReady: Context
    fun init(c: Context) { ctxReady = c.applicationContext; DeviceStorage.ctx = ctxReady }

    suspend fun fetch(url: String, k: DataKind): File? = withContext(Dispatchers.IO) {
        local(url, k)?.let { return@withContext it }
        mutex.withLock {
            local(url, k)?.let { return@withLock it }
            runCatching {
                val dst = File(DeviceStorage.ensure(bucket(k)), name(url))
                val tmp = File(dst.path + ".part")
                Api.http.newCall(Request.Builder().url(Net.px(url) ?: url).build()).execute().use { r ->
                    if (!r.isSuccessful) return@withLock null
                    r.body?.byteStream()?.use { inp -> tmp.outputStream().use { inp.copyTo(it) } } ?: return@withLock null
                }
                tmp.renameTo(dst); dst
            }.getOrNull()
        }
    }
}
