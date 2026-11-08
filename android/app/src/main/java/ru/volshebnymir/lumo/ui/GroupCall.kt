package ru.volshebnymir.lumo.ui

import android.Manifest
import android.annotation.SuppressLint
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONObject
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.jsonOf

/** Групповой звонок через LiveKit: доступ выдаёт сервер (lumo-lk), сам звонок — встроенная страница */
data class GroupCallInfo(val url: String, val token: String, val title: String, val video: Boolean)

object GroupCalls {
    var current by mutableStateOf<GroupCallInfo?>(null)

    suspend fun start(chatId: String, title: String, video: Boolean): GroupCallInfo? = try {
        val r = Api.raw("POST", "/functions/v1/lumo-lk", body = jsonOf("chat_id" to chatId, "action" to "start")) as? JSONObject
        val e = r?.optString("error")?.takeIf { it.isNotEmpty() }
        if (e != null) { AppModel.say(e); null }
        else if (r == null || r.optString("token").isEmpty()) { AppModel.say("Не удалось начать звонок"); null }
        else GroupCallInfo(r.getString("url"), r.getString("token"), title, video)
    } catch (e: Exception) { AppModel.say(e.message ?: "Ошибка"); null }

    suspend fun count(chatId: String): Int = try {
        (Api.raw("POST", "/functions/v1/lumo-lk", body = jsonOf("chat_id" to chatId, "action" to "status")) as? JSONObject)?.optInt("count") ?: 0
    } catch (e: Exception) { 0 }
}

/** Кнопка и плашка группового звонка для групп */
@Composable
fun rememberGroupCallStarter(chatId: String, title: String): (Boolean) -> Unit {
    val scope = rememberCoroutineScope()
    var wantVideo by remember { mutableStateOf(false) }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { res ->
        if (res[Manifest.permission.RECORD_AUDIO] == false) { AppModel.say("Разрешите доступ к микрофону"); return@rememberLauncherForActivityResult }
        scope.launch { GroupCalls.start(chatId, title, wantVideo)?.let { GroupCalls.current = it } }
    }
    return { video ->
        wantVideo = video
        perm.launch(if (video) arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA) else arrayOf(Manifest.permission.RECORD_AUDIO))
    }
}

@Composable
fun GroupCallBanner(chatId: String, onJoin: () -> Unit) {
    var n by remember(chatId) { mutableIntStateOf(0) }
    val cur = GroupCalls.current
    LaunchedEffect(chatId, cur) { while (true) { n = GroupCalls.count(chatId); delay(15000) } }
    val p = P
    AnimatedVisibility(n > 0, enter = expandVertically() + fadeIn(), exit = shrinkVertically() + fadeOut()) {
        Row(Modifier.fillMaxWidth().background(p.panel).bouncy(onJoin).padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(30.dp).clip(CircleShape).background(Color(0xFF34C759)), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Call, null, tint = Color.White, modifier = Modifier.size(16.dp))
            }
            Column(Modifier.weight(1f).padding(start = 10.dp)) {
                Text("Групповой звонок", color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                Text(plural(n, "участник", "участника", "участников"), color = p.muted, fontSize = 13.sp)
            }
            Text("Войти", color = Color.White, fontWeight = FontWeight.Bold, modifier = Modifier.clip(RoundedCornerShape(16.dp)).background(Color(0xFF34C759)).padding(horizontal = 16.dp, vertical = 7.dp))
        }
    }
}

/** Полноэкранное окно звонка (рисуется поверх всего) */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun GroupCallOverlay() {
    val info = GroupCalls.current ?: return
    val ctx = LocalContext.current
    var web by remember { mutableStateOf<WebView?>(null) }
    val close = { GroupCalls.current = null }
    BackHandler { web?.evaluateJavascript("window.GCall&&GCall.leave&&GCall.leave()", null) ?: close() }
    DisposableEffect(info) {
        val am = ctx.getSystemService(android.content.Context.AUDIO_SERVICE) as android.media.AudioManager
        val prevMode = am.mode
        am.mode = android.media.AudioManager.MODE_IN_COMMUNICATION
        @Suppress("DEPRECATION") am.isSpeakerphoneOn = true
        (ctx as? android.app.Activity)?.window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        onDispose {
            am.mode = prevMode
            @Suppress("DEPRECATION") am.isSpeakerphoneOn = false
            (ctx as? android.app.Activity)?.window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            web?.destroy()
        }
    }
    Dialog(onDismissRequest = {}, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false, dismissOnBackPress = false)) {
        AndroidView({ c ->
            WebView(c).apply {
                setBackgroundColor(android.graphics.Color.rgb(11, 11, 16))
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.mediaPlaybackRequiresUserGesture = false
                addJavascriptInterface(object {
                    @JavascriptInterface fun leave() { post { close() } }
                }, "LumoBridge")
                webChromeClient = object : WebChromeClient() {
                    override fun onPermissionRequest(request: PermissionRequest) { post { request.grant(request.resources) } }
                }
                val conf = JSONObject().put("url", info.url).put("token", info.token).put("title", info.title).put("video", info.video)
                val html = c.assets.open("gcall.html").bufferedReader().use { it.readText() }.replace("/*CFG*/", "window.LUMO_CALL=$conf;")
                loadDataWithBaseURL("https://lumomess.ru/", html, "text/html", "utf-8", null)
                web = this
            }
        }, Modifier.fillMaxSize().background(Color(0xFF0B0B10)))
    }
}
