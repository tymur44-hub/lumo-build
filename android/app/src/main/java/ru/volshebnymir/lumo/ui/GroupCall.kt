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
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.foundation.clickable
import androidx.compose.animation.core.*
import androidx.compose.ui.graphics.graphicsLayer
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
data class GroupCallInfo(val url: String, val token: String, val title: String, val video: Boolean, val chatId: String = "", val auth: String = "")
data class GroupCallInvite(val chatId: String, val title: String, val avatar: String?, val color: Int, val from: String, val names: List<String>, val at: Long = System.currentTimeMillis())

object GroupCalls {
    var current by mutableStateOf<GroupCallInfo?>(null)
    var invite by mutableStateOf<GroupCallInvite?>(null)
    private var uid: String? = null

    /** приглашения в групповой звонок приходят по каналу lm-gc-<мой id> */
    fun attach(id: String) {
        if (uid == id) return
        uid?.let { ru.volshebnymir.lumo.core.Realtime.leave("lm-gc-$it") }
        uid = id
        val ch = ru.volshebnymir.lumo.core.Realtime.channel("lm-gc-$id")
        ch.onBroadcast = { ev, p ->
            if (ev == "invite") android.os.Handler(android.os.Looper.getMainLooper()).post {
                if (current == null) {
                    val names = p.optJSONArray("names")?.let { a -> (0 until a.length()).map { a.optString(it) } } ?: emptyList()
                    invite = GroupCallInvite(p.optString("chat_id"), p.optString("title", "Группа"), p.optString("avatar").takeIf { it.isNotEmpty() && it != "null" },
                        p.optInt("color"), p.optString("from", "Участник"), names)
                }
            }
        }
    }

    suspend fun start(chatId: String, title: String, video: Boolean, join: Boolean = false): GroupCallInfo? = try {
        val r = Api.raw("POST", "/functions/v1/lumo-lk", body = jsonOf("chat_id" to chatId, "action" to if (join) "join" else "start")) as? JSONObject
        val e = r?.optString("error")?.takeIf { it.isNotEmpty() }
        if (e != null) { AppModel.say(e); null }
        else if (r == null || r.optString("token").isEmpty()) { AppModel.say("Не удалось начать звонок"); null }
        else GroupCallInfo(r.getString("url"), r.getString("token"), title, video, chatId, runCatching { Api.token() }.getOrDefault(""))
    } catch (e: Exception) { AppModel.say(e.message ?: "Ошибка"); null }

    suspend fun mode(chatId: String): Triple<String, Boolean, Boolean> = try {
        val r = Api.raw("POST", "/functions/v1/lumo-lk", body = jsonOf("chat_id" to chatId, "action" to "status")) as? JSONObject
        Triple(r?.optString("mode")?.ifEmpty { "all" } ?: "all", r?.optBoolean("can_start", true) ?: true, r?.optBoolean("admin") ?: false)
    } catch (e: Exception) { Triple("all", true, false) }

    suspend fun setMode(chatId: String, mode: String): Boolean = try {
        Api.rpc("lm_set_group_calls", jsonOf("p_chat" to chatId, "p_mode" to mode)); true
    } catch (e: Exception) { AppModel.say(e.message ?: "Ошибка"); false }

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
                    .put("chat_id", info.chatId).put("auth", info.auth).put("apikey", ru.volshebnymir.lumo.core.Config.ANON)
                    .put("fn", ru.volshebnymir.lumo.core.Net.base + "/functions/v1/lumo-lk")
                val html = c.assets.open("gcall.html").bufferedReader().use { it.readText() }.replace("/*CFG*/", "window.LUMO_CALL=$conf;")
                loadDataWithBaseURL("https://lumomess.ru/", html, "text/html", "utf-8", null)
                web = this
            }
        }, Modifier.fillMaxSize().background(Color(0xFF0B0B10)))
    }
}


/** «Входящий групповой звонок»: кто приглашает, кто уже в звонке, «Отклонить» и «Присоединиться» */
@Composable
fun IncomingGroupCallOverlay() {
    val inv = GroupCalls.invite
    val scope = rememberCoroutineScope()
    var joinVideo by remember { mutableStateOf(false) }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { res ->
        val i = GroupCalls.invite ?: return@rememberLauncherForActivityResult
        GroupCalls.invite = null
        if (res[Manifest.permission.RECORD_AUDIO] == false) { AppModel.say("Разрешите доступ к микрофону"); return@rememberLauncherForActivityResult }
        scope.launch { GroupCalls.start(i.chatId, i.title, joinVideo, join = true)?.let { GroupCalls.current = it } }
    }
    LaunchedEffect(inv) { if (inv != null) { delay(45000); if (GroupCalls.invite === inv) GroupCalls.invite = null } }
    AnimatedVisibility(inv != null, enter = slideInVertically { it } + fadeIn(), exit = slideOutVertically { it } + fadeOut()) {
        val i = inv ?: return@AnimatedVisibility
        val pulse = rememberInfiniteTransition(label = "gp")
        val k by pulse.animateFloat(0.95f, 1.25f, infiniteRepeatable(tween(1600), RepeatMode.Restart), label = "k")
        BackHandler { GroupCalls.invite = null }
        Box(Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Brush.verticalGradient(listOf(Color(0xFF1B2A4A), Color(0xFF0B0B10))))
            .clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) {}) {
            Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Spacer(Modifier.weight(1f))
                Box(contentAlignment = Alignment.Center) {
                    Box(Modifier.size(150.dp).graphicsLayer { scaleX = k; scaleY = k; alpha = (1.25f - k) / 0.3f }.clip(CircleShape).background(Color.White.copy(alpha = 0.12f)))
                    Avatar(i.title, i.avatar, i.color, 120.dp)
                }
                Spacer(Modifier.height(16.dp))
                Text(i.title, color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Bold, textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                Text("Входящий групповой звонок", color = Color.White.copy(alpha = 0.7f), fontSize = 16.sp, modifier = Modifier.padding(top = 6.dp))
                Text("${i.from} приглашает вас", color = Color.White.copy(alpha = 0.9f), fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 4.dp))
                if (i.names.isNotEmpty()) Column(Modifier.padding(top = 18.dp).fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Color.White.copy(alpha = 0.08f)).padding(14.dp),
                    horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("УЖЕ В ЗВОНКЕ", color = Color.White.copy(alpha = 0.55f), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    Text(i.names.take(6).joinToString(", ") + if (i.names.size > 6) " и ещё ${i.names.size - 6}" else "", color = Color.White, fontSize = 15.sp,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center, modifier = Modifier.padding(top = 6.dp))
                }
                Spacer(Modifier.weight(1f))
                Row(horizontalArrangement = Arrangement.spacedBy(70.dp), modifier = Modifier.padding(bottom = 30.dp)) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(Modifier.size(74.dp).clip(CircleShape).background(Color(0xFFFF3B30)).bouncy { GroupCalls.invite = null }, contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.CallEnd, null, tint = Color.White, modifier = Modifier.size(32.dp))
                        }
                        Text("Отклонить", color = Color.White.copy(alpha = 0.85f), fontSize = 14.sp, modifier = Modifier.padding(top = 8.dp))
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(Modifier.size(74.dp).clip(CircleShape).background(Color(0xFF34C759)).bouncy { joinVideo = false; perm.launch(arrayOf(Manifest.permission.RECORD_AUDIO)) }, contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Call, null, tint = Color.White, modifier = Modifier.size(32.dp))
                        }
                        Text("Присоединиться", color = Color.White.copy(alpha = 0.85f), fontSize = 14.sp, modifier = Modifier.padding(top = 8.dp))
                    }
                }
            }
        }
    }
}

/** Настройка «Кто может начинать групповые звонки» (видят только администраторы) */
@Composable
fun GroupCallModeSection(chatId: String) {
    val p = P
    val scope = rememberCoroutineScope()
    var mode by remember { mutableStateOf("all") }
    var admin by remember { mutableStateOf(false) }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(chatId) { val r = GroupCalls.mode(chatId); mode = r.first; admin = r.third; loaded = true }
    if (!loaded) {
        Box(Modifier.fillMaxWidth().padding(vertical = 20.dp), contentAlignment = Alignment.Center) { androidx.compose.material3.CircularProgressIndicator(color = p.muted, strokeWidth = 2.dp, modifier = Modifier.size(22.dp)) }
        return
    }
    if (!admin) {
        Text("Настройки звонков может менять только владелец или администратор группы.", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp))
        return
    }
    Text("ГРУППОВЫЕ ЗВОНКИ", color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(start = 32.dp, top = 14.dp, bottom = 6.dp))
    Column(Modifier.padding(horizontal = 16.dp).clip(RoundedCornerShape(16.dp)).background(p.panel)) {
        listOf("all" to "Все могут начать звонок", "admins" to "Только администраторы начинают", "off" to "Звонки отключены").forEachIndexed { i, (k, t) ->
            if (i > 0) Box(Modifier.padding(start = 16.dp).fillMaxWidth().height(1.dp).background(p.line))
            Row(Modifier.fillMaxWidth().clickable { val old = mode; mode = k; scope.launch { if (!GroupCalls.setMode(chatId, k)) mode = old } }.padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Text(t, color = p.text, fontSize = 16.sp, modifier = Modifier.weight(1f))
                if (mode == k) Icon(Icons.Filled.Check, null, tint = p.a1, modifier = Modifier.size(20.dp))
            }
        }
    }
    Text(when (mode) { "admins" -> "Участники смогут присоединиться, когда звонок начнёт администратор."; "off" -> "Никто не сможет звонить в этой группе."; else -> "Любой участник может начать звонок." },
        color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 32.dp, vertical = 6.dp))
}


/** Окно «Групповые звонки» из профиля группы */
@Composable
fun GroupCallSettingsDialog(chatId: String, onClose: () -> Unit) {
    val p = P
    androidx.compose.ui.window.Dialog(onDismissRequest = onClose) {
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.bg).padding(vertical = 14.dp)) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("Групповые звонки", color = p.text, fontSize = 18.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold, modifier = Modifier.weight(1f))
                Icon(Icons.Filled.Close, null, tint = p.muted, modifier = Modifier.size(24.dp).clickable { onClose() })
            }
            GroupCallModeSection(chatId)
        }
    }
}
