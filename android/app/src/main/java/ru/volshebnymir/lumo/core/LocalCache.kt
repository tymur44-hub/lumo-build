package ru.volshebnymir.lumo.core

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Локальный кэш списка чатов, переписки и данных аккаунта на диске устройства.
 * Храним последний успешно загруженный ответ сервера как есть,
 * чтобы при открытии без интернета чаты и сообщения показывались сразу,
 * а не пустым экраном.
 */
object LocalCache {
    private fun dir(ctx: Context): File {
        // постоянная папка (система её сама не чистит); очистить можно в «Данные и память»
        val d = File(ctx.filesDir, "lumo-cache")
        if (!d.exists()) {
            d.mkdirs()
            File(ctx.cacheDir, "lumo-cache").listFiles()?.forEach { runCatching { it.renameTo(File(d, it.name)) } }
        }
        return d
    }

    private fun safe(s: String) = s.replace("/", "_").replace(":", "_")

    private fun save(ctx: Context, name: String, rows: List<JSONObject>) {
        runCatching { File(dir(ctx), "$name.json").writeText(JSONArray(rows).toString()) }
    }

    private fun load(ctx: Context, name: String): List<JSONObject>? = runCatching {
        val f = File(dir(ctx), "$name.json")
        if (!f.exists()) return null
        (JSONArray(f.readText()) as JSONArray?).objects()
    }.getOrNull()

    /** чей это кэш: у каждого аккаунта на устройстве свои чаты, контакты и т.д. */
    var uid = ""
    private val u get() = if (uid.isEmpty()) "" else "u_" + safe(uid) + "_"

    fun saveChats(ctx: Context, rows: List<JSONObject>) = save(ctx, u + "chats", rows)
    fun loadChats(ctx: Context): List<JSONObject>? = load(ctx, u + "chats")

    /** Любые другие данные аккаунта: показываются сразу с устройства, потом обновляются с сервера */
    fun saveRows(ctx: Context, name: String, rows: List<JSONObject>) = save(ctx, u + name, rows)
    fun loadRows(ctx: Context, name: String): List<JSONObject>? = load(ctx, u + name)

    /** свежие строки с сервера + более старые, что уже были на устройстве; храним последние 300 */
    fun saveMessages(ctx: Context, chatId: String, rows: List<JSONObject>) {
        val lo = rows.mapNotNull { it.optInt("id", 0).takeIf { i -> i > 0 } }.minOrNull()
        val old = if (lo != null) (load(ctx, "msgs_" + safe(chatId)) ?: emptyList()).filter { it.optInt("id", Int.MAX_VALUE) < lo } else emptyList()
        save(ctx, "msgs_" + safe(chatId), (rows + old).sortedByDescending { it.optInt("id", 0) }.take(300))
    }
    fun loadMessages(ctx: Context, chatId: String): List<JSONObject>? = load(ctx, "msgs_" + safe(chatId))
}
