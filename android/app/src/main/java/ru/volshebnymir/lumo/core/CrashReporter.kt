package ru.volshebnymir.lumo.core

import android.content.Context
import android.os.Build
import org.json.JSONObject
import java.io.File

/** Падения приложения: при сбое пишем, что случилось, в файл; при следующем запуске отправляем на сервер. */
object CrashReporter {
    private lateinit var file: File

    fun install(c: Context) {
        file = File(c.filesDir, "lumo_crash.txt")
        val prev = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { t, e ->
            runCatching {
                val sw = java.io.StringWriter(); e.printStackTrace(java.io.PrintWriter(sw))
                file.writeText("${e.javaClass.name}: ${e.message ?: ""}\nпоток: ${t.name}\n$sw".take(20000))
            }
            prev?.uncaughtException(t, e)
        }
    }

    /** после входа: отправить отчёт о прошлом падении, если он есть */
    suspend fun flush(c: Context) {
        if (!::file.isInitialized || !file.exists()) return
        val text = runCatching { file.readText() }.getOrDefault("")
        if (text.isBlank()) { file.delete(); return }
        val ver = runCatching { c.packageManager.getPackageInfo(c.packageName, 0).let { "${it.versionName} (${it.longVersionCode})" } }.getOrDefault("?")
        val row = JSONObject().put("platform", "android").put("app_version", ver).put("os_version", "Android ${Build.VERSION.RELEASE} (${Build.VERSION.SDK_INT})")
            .put("device", "${Build.MANUFACTURER} ${Build.MODEL}").put("message", text.lineSequence().first().take(500)).put("stack", text)
        if (runCatching { Api.insertQuiet("lm_crash_reports", row) }.isSuccess) file.delete()
    }
}
