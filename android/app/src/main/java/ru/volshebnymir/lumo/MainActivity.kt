package ru.volshebnymir.lumo

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.content.ContextCompat
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Screen
import ru.volshebnymir.lumo.ui.LumoTheme
import ru.volshebnymir.lumo.ui.Root

class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge(statusBarStyle = SystemBarStyle.dark(0), navigationBarStyle = SystemBarStyle.dark(0))
        super.onCreate(savedInstanceState)
        AppModel.init(applicationContext)
        AppModel.openUrl = { u -> runCatching { startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(u))) } }
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        if (intent?.getBooleanExtra("demo", false) == true && !AppModel.loggedIn) ru.volshebnymir.lumo.core.Demo.load()
        intent?.getStringExtra("screen")?.let { sc ->
            when (sc) {
                "chat" -> AppModel.push(Screen.Chat("c1"))
                "menu" -> { ru.volshebnymir.lumo.core.Demo.openMenu = true; AppModel.push(Screen.Chat("c1")) }
                "settings" -> AppModel.tab = ru.volshebnymir.lumo.core.Tab.Settings
                "profile" -> AppModel.push(Screen.MyProfile)
                "edit" -> { AppModel.tab = ru.volshebnymir.lumo.core.Tab.Settings; AppModel.push(Screen.EditProfile) }
                "privacy" -> { AppModel.tab = ru.volshebnymir.lumo.core.Tab.Settings; AppModel.push(Screen.Privacy) }
                "person" -> AppModel.push(Screen.Person("u1"))
                "call" -> ru.volshebnymir.lumo.core.Calls.demoIncoming("Лилия")
                "ring" -> ru.volshebnymir.lumo.core.Calls.demoRing("Лилия")
                "qr" -> ru.volshebnymir.lumo.ui.Ui.qrMine = true
                "selftest" -> ru.volshebnymir.lumo.core.Calls.selfTest()
            }
        }
        handle(intent)
        setContent {
            LumoTheme { Root() }
            // во время звонка окно Lumo показывается поверх экрана блокировки и включает экран
            val inCall = ru.volshebnymir.lumo.core.Calls.state != ru.volshebnymir.lumo.core.Calls.State.Idle
            androidx.compose.runtime.LaunchedEffect(inCall) {
                setShowWhenLocked(inCall); setTurnScreenOn(inCall)
                if (inCall) window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                else window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(i: Intent?) {
        if (i?.getBooleanExtra("call", false) == true || i?.getBooleanExtra("answer", false) == true) { setShowWhenLocked(true); setTurnScreenOn(true) }
        if (i?.getBooleanExtra("answer", false) == true) {
            i.removeExtra("answer")
            val C = ru.volshebnymir.lumo.core.Calls
            val need = listOfNotNull(Manifest.permission.RECORD_AUDIO.takeIf { !C.has(it) }, Manifest.permission.CAMERA.takeIf { C.video && !C.has(it) })
            if (need.isEmpty()) C.answer() else requestPermissions(need.toTypedArray(), 2)
        }
        val chat = i?.getStringExtra("chat") ?: return
        i.removeExtra("chat")
        if (!AppModel.loggedIn) return
        AppModel.tab = ru.volshebnymir.lumo.core.Tab.Chats
        if ((AppModel.stack.lastOrNull() as? Screen.Chat)?.id != chat) {
            AppModel.stack.clear(); AppModel.push(Screen.Chat(chat))
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 2) ru.volshebnymir.lumo.core.Calls.answer()
    }

    override fun onResume() { super.onResume(); AppModel.foreground(true) }
    override fun onPause() { super.onPause(); AppModel.foreground(false) }
}
