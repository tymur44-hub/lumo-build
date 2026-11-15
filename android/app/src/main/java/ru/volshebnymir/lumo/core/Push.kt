package ru.volshebnymir.lumo.core

import android.content.Context
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

/**
 * Firebase Cloud Messaging — уведомления и звонки, когда приложение закрыто.
 * Это запасной путь: пока приложение живо и держит соединение, уведомления показывает realtime,
 * поэтому пуш в этом случае не дублируется.
 */
object Push {
    private val io = CoroutineScope(Dispatchers.IO)

    /** Получить токен устройства и отправить на сервер (после входа и при каждом запуске) */
    fun register(ctx: Context) {
        if (!AppModel.loggedIn) return
        FirebaseMessaging.getInstance().token.addOnCompleteListener { t ->
            val token = if (t.isSuccessful) t.result else null
            if (!token.isNullOrBlank()) save(ctx, token)
        }
    }

    /** Сохранить токен на сервере для текущего пользователя */
    fun save(ctx: Context, token: String) {
        val prefs = ctx.getSharedPreferences("lumo_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
        if (!AppModel.loggedIn) return
        io.launch { runCatching { Api.rpc("lm_fcm_register", JSONObject().put("p_token", token).put("p_platform", "android")) } }
    }

    /** Отвязать токен от аккаунта при выходе — чтобы чужие уведомления не приходили */
    fun unregister(ctx: Context) {
        val token = ctx.getSharedPreferences("lumo_prefs", Context.MODE_PRIVATE).getString("fcm_token", null) ?: return
        io.launch { runCatching { Api.rpc("lm_fcm_unregister", JSONObject().put("p_token", token)) } }
    }

    /** Обработать входящий пуш (может прийти в «мёртвый» процесс — поднимаем, что нужно) */
    fun handle(ctx: Context, data: Map<String, String>) {
        AppModel.init(ctx.applicationContext)
        val chat = data["chat"] ?: return
        Notifier.setup(ctx)

        if (data["t"] == "call") {
            val name = data["title"]?.takeIf { it.isNotBlank() } ?: "Входящий звонок"
            Notifier.wakeScreen(ctx)
            Notifier.incomingCall(ctx, name, data["video"] == "1", chat)
            return
        }

        // приложение живо и на связи — realtime уже покажет это сообщение
        if (LumoService.running && Realtime.isOpen && AppModel.loggedIn) return
        if (AppModel.isActive && AppModel.openChatId == chat) return

        val id = data["id"]?.toLongOrNull()?.toInt() ?: chat.hashCode()
        val title = data["title"]?.takeIf { it.isNotBlank() } ?: "Lumo"
        var body = data["body"] ?: ""
        if (data["enc"] == "1") {
            val dec = data["e"]?.let { runCatching { E2E.decrypt(chat, it) }.getOrNull() }
            body = if (dec != null && dec != E2E.LOCKED) dec else "Новое сообщение"
        }
        if (body.isBlank()) body = "Новое сообщение"
        val quiet = ru.volshebnymir.lumo.ui.Dnd.active
        Notifier.message(ctx, id, title, body, chat, quiet = quiet)
    }
}

class LumoFcm : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        Push.save(applicationContext, token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        if (message.data.isNotEmpty()) Push.handle(applicationContext, message.data)
    }
}
