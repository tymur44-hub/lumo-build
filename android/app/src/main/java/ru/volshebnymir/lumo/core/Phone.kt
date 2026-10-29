package ru.volshebnymir.lumo.core

import android.Manifest
import android.content.pm.PackageManager
import android.provider.ContactsContract
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

data class MatchedContact(val id: String, val phone: String, val name: String, val username: String, val avatarUrl: String?, val color: Int, val bookName: String)
data class InviteContact(val phone: String, val name: String)

/** Номер телефона, двухэтапная защита, сверка контактов */
object PhoneStore {
    var phone by mutableStateOf<String?>(null)
    var status by mutableStateOf("ok")       // ok | remind | skipped | required
    var tfa by mutableStateOf(false)
    var hint by mutableStateOf("")
    var loaded by mutableStateOf(false)
    var reminderShown by mutableStateOf(false)
    var skipUntil by mutableStateOf<String?>(null)
    val matched = mutableStateListOf<MatchedContact>()
    val invites = mutableStateListOf<InviteContact>()
    var syncing by mutableStateOf(false)
    var contactsDenied by mutableStateOf(false)

    fun reset() {
        phone = null; status = "ok"; tfa = false; hint = ""; loaded = false; reminderShown = false
        matched.clear(); invites.clear()
    }

    /** Запрос к функции lumo-phone. Ошибки сервера приходят полем error */
    suspend fun call(path: String, body: JSONObject, auth: Boolean = false): JSONObject {
        return try {
            Api.raw("POST", "/functions/v1/lumo-phone/$path", body = body, auth = auth) as? JSONObject ?: JSONObject()
        } catch (e: ApiError) {
            val m = e.message ?: ""
            if (e.status in 400..499 && Regex("^[a-z_]{3,20}$").matches(m)) JSONObject().put("error", m) else throw e
        }
    }

    fun message(code: String): String = when (code) {
        "bad_phone" -> "Введите российский номер мобильного телефона"
        "bad_code" -> "Неверный код"
        "expired" -> "Код устарел — запросите новый"
        "locked" -> "Слишком много попыток — запросите новый код"
        "too_many" -> "Слишком много кодов. Попробуйте через час"
        "wait" -> "Новый код можно запросить через минуту"
        "busy" -> "Сервис занят, попробуйте позже"
        "sms_off", "sms_fail" -> "Отправка кодов пока недоступна"
        "phone_taken" -> "Этот номер уже привязан к другому аккаунту"
        "banned" -> "Аккаунт заблокирован"
        "bad_tfa" -> "Неверный пароль"
        else -> "Не удалось выполнить действие"
    }

    suspend fun load() {
        val r = runCatching { Api.rpc("lm_my_phone") }.getOrNull() ?: return
        val o = (r as? JSONObject) ?: (r as? JSONArray)?.optJSONObject(0) ?: return
        phone = o.str("phone")
        status = o.str("status") ?: "ok"
        tfa = o.bool("tfa")
        hint = o.str("hint") ?: ""
        skipUntil = o.str("skip_until")
        loaded = true
    }

    suspend fun skip() { runCatching { Api.rpc("lm_phone_skip") }; load() }

    fun skipText(): String {
        val s = skipUntil ?: return "окончания отсрочки"
        return runCatching {
            val d = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).parse(s.take(10))!!
            java.text.SimpleDateFormat("d MMMM", java.util.Locale("ru")).format(d)
        }.getOrDefault("окончания отсрочки")
    }

    fun pretty(p: String?): String {
        if (p == null || p.length != 11) return p ?: ""
        return "+7 (${p.substring(1, 4)}) ${p.substring(4, 7)}-${p.substring(7, 9)}-${p.substring(9, 11)}"
    }

    fun normalize(raw: String): String? {
        var d = raw.filter { it.isDigit() }
        if (d.length == 11 && d.startsWith("8")) d = "7" + d.drop(1)
        if (d.length == 10 && d.startsWith("9")) d = "7$d"
        return if (d.length == 11 && d.startsWith("79")) d else null
    }

    fun canWriteContacts(): Boolean =
        ContextCompat.checkSelfPermission(AppModel.ctx, Manifest.permission.WRITE_CONTACTS) == PackageManager.PERMISSION_GRANTED

    /** Сохранить человека в записную книжку телефона (если номер известен и его там ещё нет) */
    suspend fun saveToPhonebook(userId: String, name: String): Boolean {
        if (!canWriteContacts()) return false
        val raw = runCatching { Api.rpc("lm_phone_of", jsonOf("p_user" to userId))?.toString() }.getOrNull()
        val num = raw?.filter { it.isDigit() }.orEmpty()
        if (num.length < 10) return false
        return withContext(Dispatchers.IO) {
            runCatching {
                val cr = AppModel.ctx.contentResolver
                val lookup = android.net.Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, android.net.Uri.encode("+$num"))
                val exists = cr.query(lookup, arrayOf(ContactsContract.PhoneLookup._ID), null, null, null)?.use { it.moveToFirst() } ?: false
                if (exists) return@runCatching true
                val ops = ArrayList<android.content.ContentProviderOperation>()
                ops.add(android.content.ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null).withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null).build())
                ops.add(android.content.ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name).build())
                ops.add(android.content.ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, "+$num")
                    .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE).build())
                cr.applyBatch(ContactsContract.AUTHORITY, ops)
                true
            }.getOrDefault(false)
        }
    }

    fun hasContactsAccess(): Boolean =
        ContextCompat.checkSelfPermission(AppModel.ctx, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED

    /** Прочитать записную книжку и узнать, кто из знакомых уже в Lumo */
    suspend fun syncContacts() {
        if (syncing) return
        if (!hasContactsAccess()) { contactsDenied = true; return }
        contactsDenied = false
        syncing = true
        try {
            val names = withContext(Dispatchers.IO) {
                val out = LinkedHashMap<String, String>()
                runCatching {
                    AppModel.ctx.contentResolver.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                        arrayOf(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.NUMBER), null, null, null)?.use { c ->
                        while (c.moveToNext()) {
                            val n = normalize(c.getString(1) ?: "") ?: continue
                            if (!out.containsKey(n)) out[n] = (c.getString(0) ?: "").ifBlank { "+$n" }
                        }
                    }
                }
                out
            }
            val phones = names.keys.toList()
            val found = ArrayList<MatchedContact>()
            for (chunk in phones.chunked(400)) {
                val rows = runCatching { Api.rpc("lm_match_contacts", jsonOf("p_phones" to JSONArray(chunk))) as? JSONArray }.getOrNull() ?: continue
                for (r in rows.objects()) {
                    val uid = r.str("user_id") ?: continue
                    val ph = r.str("phone") ?: continue
                    found.add(MatchedContact(uid, ph, r.str("name") ?: "", r.str("username") ?: "", r.str("avatar_url"), r.optInt("color", 0), names[ph] ?: ""))
                }
            }
            val fp = found.map { it.phone }.toSet()
            matched.clear(); matched.addAll(found.sortedBy { it.bookName.lowercase() })
            invites.clear(); invites.addAll(phones.filter { it !in fp }.map { InviteContact(it, names[it] ?: "") }.sortedBy { it.name.lowercase() })
        } finally { syncing = false }
    }
}
