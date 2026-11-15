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
    private var netCb: android.net.ConnectivityManager.NetworkCallback? = null

    override fun onCreate() {
        super.onCreate()
        running = true
        Realtime.keepAwake = { ms -> wake(this, ms) }
        // сменилась сеть (Wi-Fi ⇄ мобильная) — старый сокет мёртв, переподключаемся сразу
        runCatching {
            val cm = getSystemService(android.net.ConnectivityManager::class.java)
            val cb = object : android.net.ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: android.net.Network) { wake(this@LumoService, 15_000); Realtime.kick() }
            }
            cm.registerDefaultNetworkCallback(cb); netCb = cb
        }
        schedule(this)
    }

    override fun onDestroy() {
        runCatching { netCb?.let { getSystemService(android.net.ConnectivityManager::class.java).unregisterNetworkCallback(it) } }
        Realtime.keepAwake = null
        running = false
        super.onDestroy()
    }

    /** Lumo смахнули из недавних — служба перезапускается сама */
    override fun onTaskRemoved(rootIntent: Intent?) {
        if (AppModel.keepAlive && AppModel.loggedIn) {
            runCatching {
                val pi = android.app.PendingIntent.getForegroundService(this, 7, Intent(this, LumoService::class.java),
                    android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT)
                getSystemService(android.app.AlarmManager::class.java).set(android.app.AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    android.os.SystemClock.elapsedRealtime() + 1500, pi)
            }
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val n = NotificationCompat.Builder(this, Notifier.CH_SERVICE)
            .setSmallIcon(R.drawable.ic_stat)
            .setContentTitle("Lumo на связи")
            .setContentText("Сообщения и звонки будут приходить, даже когда приложение свёрнуто")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setContentIntent(Notifier.openIntent(this, null, 1))
            .build()
        // Android 14+: тип «обмен сообщениями» — без ограничения по времени, в отличие от синхронизации данных
        var type = if (Build.VERSION.SDK_INT >= 34) ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING else ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        if (intent?.getBooleanExtra("mic", false) == true && Calls.has(android.Manifest.permission.RECORD_AUDIO)) type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        if (intent?.getBooleanExtra("cam", false) == true && Calls.has(android.Manifest.permission.CAMERA)) type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
        val ok = runCatching { if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, type) else startForeground(1, n) }.isSuccess
        if (!ok) runCatching { if (Build.VERSION.SDK_INT >= 29) startForeground(1, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC) else startForeground(1, n) }
        AppModel.init(applicationContext)
        if (AppModel.loggedIn) { AppModel.start(); Realtime.kick() }
        return START_STICKY
    }

    companion object {
        @Volatile var running = false
        fun start(ctx: Context) {
            runCatching { ContextCompat.startForegroundService(ctx, Intent(ctx, LumoService::class.java)) }
        }
        /** Во время звонка служба получает право на микрофон и камеру — разговор не прерывается, если свернуть Lumo */
        fun callMode(ctx: Context, on: Boolean, cam: Boolean) {
            runCatching { ContextCompat.startForegroundService(ctx, Intent(ctx, LumoService::class.java).putExtra("mic", on).putExtra("cam", on && cam)) }
        }
        fun stop(ctx: Context) {
            runCatching { ctx.stopService(Intent(ctx, LumoService::class.java)) }
            runCatching { ctx.getSystemService(android.app.AlarmManager::class.java).cancel(watchIntent(ctx)) }
        }

        private var lock: android.os.PowerManager.WakeLock? = null
        /** Короткая блокировка сна — чтобы переподключение успело пройти при выключенном экране */
        fun wake(ctx: Context, ms: Long) {
            runCatching {
                val l = lock ?: ctx.getSystemService(android.os.PowerManager::class.java)
                    .newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "lumo:rt").also { it.setReferenceCounted(false); lock = it }
                l.acquire(ms.coerceIn(5_000, 40_000))
            }
        }

        private fun watchIntent(ctx: Context) = android.app.PendingIntent.getBroadcast(ctx, 8, Intent(ctx, WatchReceiver::class.java),
            android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT)

        /** Проверка соединения раз в несколько минут — срабатывает и в режиме сна (Doze) */
        fun schedule(ctx: Context) {
            runCatching {
                ctx.getSystemService(android.app.AlarmManager::class.java).setAndAllowWhileIdle(
                    android.app.AlarmManager.ELAPSED_REALTIME_WAKEUP, android.os.SystemClock.elapsedRealtime() + 4 * 60_000, watchIntent(ctx))
            }
        }
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

class WatchReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AppModel.init(context.applicationContext)
        if (!AppModel.loggedIn || !AppModel.keepAlive) return
        LumoService.wake(context, 20_000)
        if (LumoService.running) { AppModel.start(); Realtime.kick() } else LumoService.start(context)
        LumoService.schedule(context)
    }
}
