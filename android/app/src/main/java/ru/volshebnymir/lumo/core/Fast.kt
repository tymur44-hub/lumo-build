package ru.volshebnymir.lumo.core

import android.util.Base64
import org.json.JSONObject
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Локальный ускоритель соединения. Запускается только когда и прямой адрес,
 * и зеркало недоступны (сильное замедление у провайдера). Поднимает локальную
 * точку 127.0.0.1:28810, через которую клиент ходит к серверу.
 * Параметры узла хранятся в зашифрованном виде и собираются только в памяти.
 */
object Fast {
    const val PORT = 28810
    @Volatile private var running = false
    @Volatile var lastMsg = "не запускался"
    private var apiV = 3
    val isRunning get() = running

    private val kp = arrayOf("PmzgX3NcfQc=", "baNpVP/AMZ0=", "C1LiEt4/KtI=", "eid1yAdow/g=")
    private val km = byteArrayOf(-60, -78, 77, 83)
    private val bd =
        "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"

    private val bd0 =
        "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"

    private fun key(): ByteArray {
        val out = ByteArray(32)
        for (i in 0 until 4) {
            val d = Base64.decode(kp[i], Base64.DEFAULT)
            for (j in d.indices) out[i * 8 + j] = (d[j].toInt() xor km[i].toInt()).toByte()
        }
        return out
    }

    private fun conf(b: String): String {
        val raw = Base64.decode(b, Base64.DEFAULT)
        val iv = raw.copyOfRange(0, 12)
        val ct = raw.copyOfRange(12, raw.size)
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.DECRYPT_MODE, SecretKeySpec(key(), "AES"), GCMParameterSpec(128, iv))
        return String(c.doFinal(ct), Charsets.UTF_8)
    }

    // ---- несколько узлов, автовыбор по скорости ----
    @Volatile var prefs: android.content.SharedPreferences? = null
    private const val NK = "nodes_enc"

    private fun cachedNodes(): List<JSONObject> = runCatching {
        val b = prefs?.getString(NK, null) ?: return emptyList()
        val raw = Base64.decode(b, Base64.DEFAULT)
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.DECRYPT_MODE, SecretKeySpec(key(), "AES"), GCMParameterSpec(128, raw.copyOfRange(0, 12)))
        val a = org.json.JSONArray(String(c.doFinal(raw.copyOfRange(12, raw.size)), Charsets.UTF_8))
        (0 until a.length()).map { a.getJSONObject(it) }
    }.getOrDefault(emptyList())

    private fun merged(base: String): String? {
        val extra = cachedNodes()
        if (extra.isEmpty()) return null
        val c = JSONObject(base)
        val outs = c.getJSONArray("outbounds")
        val all = org.json.JSONArray()
        val rest = org.json.JSONArray()
        var n = 0
        for (i in 0 until outs.length()) {
            val o = outs.getJSONObject(i)
            if (o.optString("tag") == "proxy") { o.put("tag", "proxy-" + n++); all.put(o) } else rest.put(o)
        }
        for (o in extra) { o.put("tag", "proxy-" + n++); all.put(o) }
        for (i in 0 until rest.length()) all.put(rest.get(i))
        c.put("outbounds", all)
        val routing = c.getJSONObject("routing")
        val rules = routing.optJSONArray("rules") ?: org.json.JSONArray()
        for (i in 0 until rules.length()) {
            val r = rules.getJSONObject(i)
            if (r.optString("outboundTag") == "proxy") { r.remove("outboundTag"); r.put("balancerTag", "bal") }
        }
        rules.put(JSONObject().put("type", "field").put("network", "tcp,udp").put("balancerTag", "bal"))
        routing.put("rules", rules)
        routing.put("balancers", org.json.JSONArray().put(JSONObject().put("tag", "bal")
            .put("selector", org.json.JSONArray().put("proxy-")).put("strategy", JSONObject().put("type", "leastPing"))))
        c.put("observatory", JSONObject().put("subjectSelector", org.json.JSONArray().put("proxy-"))
            .put("probeUrl", "https://www.gstatic.com/generate_204").put("probeInterval", "30s").put("enableConcurrency", true))
        return c.toString()
    }

    /** Скачать актуальный список узлов (нужен вход) и сохранить зашифрованным. Применится при следующем запуске. */
    suspend fun refreshNodes() = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
        runCatching {
            val tok = runCatching { Api.token() }.getOrDefault(Config.ANON)
            val u = java.net.URL(Net.base + "/functions/v1/lumo-nodes")
            val h = u.openConnection() as java.net.HttpURLConnection
            h.connectTimeout = 15000; h.readTimeout = 15000
            h.setRequestProperty("apikey", Config.ANON); h.setRequestProperty("Authorization", "Bearer $tok")
            if (h.responseCode != 200) return@runCatching
            val a = JSONObject(h.inputStream.bufferedReader().readText()).getJSONArray("nodes")
            val iv = ByteArray(12).also { java.security.SecureRandom().nextBytes(it) }
            val c = Cipher.getInstance("AES/GCM/NoPadding")
            c.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key(), "AES"), GCMParameterSpec(128, iv))
            val ct = c.doFinal(a.toString().toByteArray(Charsets.UTF_8))
            prefs?.edit()?.putString(NK, Base64.encodeToString(iv + ct, Base64.NO_WRAP))?.apply()
        }
        Unit
    }

    @Synchronized
    fun ensure(): Boolean {
        if (running) return true
        return try {
            var ok = false
            // сначала набор из нескольких узлов с автовыбором по скорости, затем встроенные
            val cands = ArrayList<String>()
            runCatching { merged(conf(bd)) }.getOrNull()?.let { cands.add(it) }
            cands.add(conf(bd))
            runCatching { conf(bd0) }.getOrNull()?.let { cands.add(it) }
            for (cfg in cands) {
                // версия интерфейса ядра зависит от сборки — подбираем
                for (v in intArrayOf(1, 2, 3, 4, 5, 6)) {
                    val req = JSONObject().put("apiVersion", v).put("method", "runXrayFromJson")
                        .put("payload", JSONObject().put("configJSON", cfg))
                    val resp = libXray.LibXray.invoke(req.toString())
                    lastMsg = "v$v " + resp.take(200)
                    if (JSONObject(resp).optBoolean("success", false)) { ok = true; apiV = v; break }
                    if (!resp.contains("unsupported apiVersion")) break
                }
                if (ok) break
            }
            running = ok
            ok
        } catch (e: Throwable) {
            lastMsg = "исключение: " + e.javaClass.simpleName
            running = false
            false
        }
    }

    @Synchronized
    fun stop() {
        if (!running) return
        runCatching {
            libXray.LibXray.invoke(JSONObject().put("apiVersion", apiV).put("method", "stopXray").toString())
        }
        running = false
    }
}
