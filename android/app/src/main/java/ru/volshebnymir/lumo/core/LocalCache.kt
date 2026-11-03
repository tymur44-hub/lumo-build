package ru.volshebnymir.lumo.core

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Локальный кэш списка чатов и переписки на диске устройства.
 * Храним последний успешно загруженный ответ сервера как есть,
 * чтобы при открытии без интернета чаты и сообщения показывались сразу,
 * а не пустым экраном.
 */
object LocalCache {
    private fun dir(ctx: Context): File {
        val d = File(ctx.cacheDir, "lumo-cache")
        if (!d.exists()) d.mkdirs()
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

    fun saveChats(ctx: Context, rows: List<JSONObject>) = save(ctx, "chats", rows)
    fun loadChats(ctx: Context): List<JSONObject>? = load(ctx, "chats")

    fun saveMessages(ctx: Context, chatId: String, rows: List<JSONObject>) =
        save(ctx, "msgs_" + safe(chatId), rows.take(80))
    fun loadMessages(ctx: Context, chatId: String): List<JSONObject>? = load(ctx, "msgs_" + safe(chatId))
}
