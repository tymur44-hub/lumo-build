package ru.volshebnymir.lumo.core

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import ru.volshebnymir.lumo.R

/** Пока Lumo свёрнут, служба держит соединение с сервером — сообщения и звонки приходят сразу */
class LumoService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val n = NotificationCompat.Builder(this, Notifier.CH_SERVICE)
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle("Lumo на связи")
            .setContentText("Сообщения и звонки будут приходить, даже когда приложение свёрнуто")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setContentIntent(Notifier.openIntent(this, null, 1))
            .build()
        var type = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        if (intent?.getBooleanExtra("mic", false) == true && Calls.has(android.Manifest.permission.RECORD_AUDIO)) type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        if (intent?.getBooleanExtra("cam", false) == true && Calls.has(android.Manifest.permission.CAMERA)) type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
        val ok = runCatching { if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, type) else startForeground(1, n) }.isSuccess
        if (!ok) runCatching { if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC) else startForeground(1, n) }
        AppModel.init(applicationContext)
        if (AppModel.loggedIn) AppModel.start()
        return START_STICKY
    }

    companion object {
        fun start(ctx: Context) {
            runCatching { ContextCompat.startForegroundService(ctx, Intent(ctx, LumoService::class.java)) }
        }
        /** Во время звонка служба получает право на микрофон и камеру — разговор не прерывается, если свернуть Lumo */
        fun callMode(ctx: Context, on: Boolean, cam: Boolean) {
            runCatching { ContextCompat.startForegroundService(ctx, Intent(ctx, LumoService::class.java).putExtra("mic", on).putExtra("cam", on && cam)) }
        }
        fun stop(ctx: Context) { runCatching { ctx.stopService(Intent(ctx, LumoService::class.java)) } }
    }
}

class BootReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            AppModel.init(context.applicationContext)
            if (AppModel.loggedIn) LumoService.start(context)
        }
    }
}
