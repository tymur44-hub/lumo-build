package ru.volshebnymir.lumo.core

import android.util.Base64
import org.json.JSONObject
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Локальный ускоритель соединения. Запускается только когда и прямой адрес,
 * и зеркало недоступны (сильное замедление у провайдера). Поднимает локальную
 * точку 127.0.0.1:10808, через которую клиент ходит к серверу.
 * Параметры узла хранятся в зашифрованном виде и собираются только в памяти.
 */
object Fast {
    const val PORT = 10808
    @Volatile private var running = false
    @Volatile var lastMsg = "не запускался"
    private var apiV = 3
    val isRunning get() = running

    private val kp = arrayOf("PmzgX3NcfQc=", "baNpVP/AMZ0=", "C1LiEt4/KtI=", "eid1yAdow/g=")
    private val km = byteArrayOf(-60, -78, 77, 83)
    private val bd =
        "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"

    private fun key(): ByteArray {
        val out = ByteArray(32)
        for (i in 0 until 4) {
            val d = Base64.decode(kp[i], Base64.DEFAULT)
            for (j in d.indices) out[i * 8 + j] = (d[j].toInt() xor km[i].toInt()).toByte()
        }
        return out
    }

    private fun conf(): String {
        val raw = Base64.decode(bd, Base64.DEFAULT)
        val iv = raw.copyOfRange(0, 12)
        val ct = raw.copyOfRange(12, raw.size)
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.DECRYPT_MODE, SecretKeySpec(key(), "AES"), GCMParameterSpec(128, iv))
        return String(c.doFinal(ct), Charsets.UTF_8)
    }

    @Synchronized
    fun ensure(): Boolean {
        if (running) return true
        return try {
            val cfg = conf()
            var ok = false
            // версия интерфейса ядра зависит от сборки — подбираем
            for (v in intArrayOf(1, 2, 3, 4, 5, 6)) {
                val req = JSONObject().put("apiVersion", v).put("method", "runXrayFromJson")
                    .put("payload", JSONObject().put("configJSON", cfg))
                val resp = libXray.LibXray.invoke(req.toString())
                lastMsg = "v$v " + resp.take(200)
                if (JSONObject(resp).optBoolean("success", false)) { ok = true; apiV = v; break }
                if (!resp.contains("unsupported apiVersion")) break
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
