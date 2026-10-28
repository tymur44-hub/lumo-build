package ru.volshebnymir.lumo.core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.ToneGenerator
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import ru.volshebnymir.lumo.MainActivity
import ru.volshebnymir.lumo.R

/** Системные уведомления Android */
object Notifier {
    const val CH_MSG = "messages"
    const val CH_SERVICE = "service"
    const val CH_CALL = "calls_ring"

    fun setup(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CH_MSG, "Сообщения", NotificationManager.IMPORTANCE_HIGH).apply { description = "Новые сообщения" })
        nm.deleteNotificationChannel("calls")
        nm.createNotificationChannel(NotificationChannel(CH_CALL, "Входящие звонки", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Экран звонка, даже когда телефон заблокирован"
            setSound(null, null); enableVibration(false)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        })
        nm.createNotificationChannel(NotificationChannel(CH_SERVICE, "Работа в фоне", NotificationManager.IMPORTANCE_MIN).apply {
            description = "Чтобы сообщения и звонки приходили, когда Lumo свёрнут"; setShowBadge(false)
        })
    }

    fun openIntent(ctx: Context, chatId: String?, req: Int): PendingIntent {
        val i = Intent(ctx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            chatId?.let { putExtra("chat", it) }
        }
        return PendingIntent.getActivity(ctx, req, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    fun message(ctx: Context, id: Int, title: String, body: String, chatId: String) {
        val n = NotificationCompat.Builder(ctx, CH_MSG)
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle(title).setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setGroup(chatId)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setContentIntent(openIntent(ctx, chatId, chatId.hashCode()))
            .build()
        runCatching { NotificationManagerCompat.from(ctx).notify(chatId, id, n) }
    }

    fun clearChat(ctx: Context, chatId: String) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        nm.activeNotifications.filter { it.tag == chatId }.forEach { nm.cancel(it.tag, it.id) }
    }

    fun clearAll(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        nm.activeNotifications.filter { it.notification.channelId == CH_MSG }.forEach { nm.cancel(it.tag, it.id) }
    }


    const val CALL_ID = 77
    /** Входящий звонок: всплывающее окно на весь экран (и на заблокированном экране) */
    fun incomingCall(ctx: Context, name: String, video: Boolean, chatId: String) {
        val open = Intent(ctx, MainActivity::class.java).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP; putExtra("call", true) }
        val full = PendingIntent.getActivity(ctx, 701, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val ans = PendingIntent.getActivity(ctx, 702, Intent(open).putExtra("answer", true), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val dec = PendingIntent.getBroadcast(ctx, 703, Intent(ctx, CallActionReceiver::class.java).setAction("decline"), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val person = androidx.core.app.Person.Builder().setName(name).setImportant(true).build()
        val b = NotificationCompat.Builder(ctx, CH_CALL)
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle(name)
            .setContentText(if (video) "Входящий видеозвонок" else "Входящий звонок")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true).setAutoCancel(false)
            .setFullScreenIntent(full, true)
            .setContentIntent(full)
        runCatching { b.setStyle(NotificationCompat.CallStyle.forIncomingCall(person, dec, ans).setIsVideo(video)) }
            .onFailure { b.addAction(0, "Отклонить", dec).addAction(0, "Ответить", ans) }
        val n = b.build()
        runCatching { NotificationManagerCompat.from(ctx).notify(CALL_ID, n) }
            .onFailure { runCatching { NotificationManagerCompat.from(ctx).notify(CALL_ID, NotificationCompat.Builder(ctx, CH_CALL).setSmallIcon(R.drawable.ic_stat)
                .setContentTitle(name).setContentText("Входящий звонок").setCategory(NotificationCompat.CATEGORY_CALL).setPriority(NotificationCompat.PRIORITY_MAX)
                .setOngoing(true).setFullScreenIntent(full, true).setContentIntent(full).addAction(0, "Отклонить", dec).addAction(0, "Ответить", ans).build()) } }
        wakeScreen(ctx)
    }

    /** Включить экран, когда звонят (телефон заблокирован или экран погас) */
    @Suppress("DEPRECATION")
    fun wakeScreen(ctx: Context) {
        runCatching {
            val pm = ctx.getSystemService(android.os.PowerManager::class.java)
            if (!pm.isInteractive) pm.newWakeLock(android.os.PowerManager.SCREEN_BRIGHT_WAKE_LOCK or android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP or android.os.PowerManager.ON_AFTER_RELEASE, "lumo:ring").acquire(15_000)
        }
    }

    /** Разрешено ли показывать звонок на весь экран поверх блокировки (Android 14+) */
    fun canFullScreen(ctx: Context): Boolean =
        if (android.os.Build.VERSION.SDK_INT >= 34) ctx.getSystemService(NotificationManager::class.java).canUseFullScreenIntent() else true

    fun cancelCall(ctx: Context) { runCatching { NotificationManagerCompat.from(ctx).cancel(CALL_ID) } }

    private var lastBeep = 0L
    /** Короткий звук нового сообщения, когда Lumo открыт (в беззвучном режиме не звучит) */
    fun beep() {
        val now = System.currentTimeMillis()
        if (now - lastBeep < 800) return
        lastBeep = now
        val am = AppModel.ctx.getSystemService(AudioManager::class.java)
        if (am.ringerMode != AudioManager.RINGER_MODE_NORMAL) return
        runCatching {
            val tg = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 55)
            tg.startTone(ToneGenerator.TONE_PROP_BEEP2, 140)
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ tg.release() }, 400)
        }
    }
}

class CallActionReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "decline") Calls.endTapped()
    }
}
