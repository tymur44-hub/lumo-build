package ru.volshebnymir.lumo.core

import android.content.Context
import androidx.compose.runtime.mutableStateListOf
import org.json.JSONArray
import org.json.JSONObject

/** Несколько аккаунтов в одном приложении: токены каждого хранятся на устройстве */
object Accounts {
    data class Acc(val id: String, val name: String, val username: String, val avatar: String?, val a: String, val r: String, val e: Long)

    private lateinit var ctx: Context
    val list = mutableStateListOf<Acc>()

    fun init(c: Context) {
        ctx = c.applicationContext
        list.clear()
        val arr = runCatching { JSONArray(ctx.getSharedPreferences("lumo_accounts", Context.MODE_PRIVATE).getString("l", "[]")) }.getOrNull() ?: JSONArray()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            list.add(Acc(o.optString("id"), o.optString("name"), o.optString("username"), o.optString("avatar").ifEmpty { null }, o.optString("a"), o.optString("r"), o.optLong("e")))
        }
    }

    private fun save() {
        val arr = JSONArray()
        list.forEach { arr.put(JSONObject().put("id", it.id).put("name", it.name).put("username", it.username).put("avatar", it.avatar ?: "").put("a", it.a).put("r", it.r).put("e", it.e)) }
        ctx.getSharedPreferences("lumo_accounts", Context.MODE_PRIVATE).edit().putString("l", arr.toString()).apply()
    }

    fun saveTokens(s: Session) {
        if (!::ctx.isInitialized || s.userId.isEmpty()) return
        val i = list.indexOfFirst { it.id == s.userId }
        if (i >= 0) list[i] = list[i].copy(a = s.access, r = s.refresh, e = s.expiresAt)
        else list.add(Acc(s.userId, "", "", null, s.access, s.refresh, s.expiresAt))
        save()
    }

    fun info(id: String, name: String, username: String, avatar: String?) {
        if (!::ctx.isInitialized) return
        val i = list.indexOfFirst { it.id == id }
        if (i < 0) return
        list[i] = list[i].copy(name = name, username = username, avatar = avatar)
        save()
    }

    fun remove(id: String) {
        if (!::ctx.isInitialized) return
        list.removeAll { it.id == id }
        save()
    }

    /** Premium — до 3 аккаунтов, без Premium — один */
    fun limit(): Int = if (AppModel.isPremium) 3 else 1
}
