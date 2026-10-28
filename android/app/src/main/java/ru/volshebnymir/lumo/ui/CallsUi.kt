package ru.volshebnymir.lumo.ui

import android.Manifest
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.delay
import org.webrtc.VideoTrack
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Calls
import ru.volshebnymir.lumo.core.ChatItem
import ru.volshebnymir.lumo.core.Fmt
import kotlin.math.cos
import kotlin.math.sin

/** Начать звонок: сперва спрашиваем микрофон (и камеру для видео) */
@Composable
fun rememberCallStarter(): (ChatItem, Boolean) -> Unit {
    var pending by remember { mutableStateOf<Pair<ChatItem, Boolean>?>(null) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { res ->
        val p = pending ?: return@rememberLauncherForActivityResult
        pending = null
        if (res[Manifest.permission.RECORD_AUDIO] == false && !Calls.has(Manifest.permission.RECORD_AUDIO)) { AppModel.say("Нужен доступ к микрофону"); return@rememberLauncherForActivityResult }
        Calls.startCall(p.first, p.second)
    }
    return { chat, video ->
        val need = mutableListOf<String>()
        if (!Calls.has(Manifest.permission.RECORD_AUDIO)) need.add(Manifest.permission.RECORD_AUDIO)
        if (video && !Calls.has(Manifest.permission.CAMERA)) need.add(Manifest.permission.CAMERA)
        if (need.isEmpty()) Calls.startCall(chat, video) else { pending = chat to video; launcher.launch(need.toTypedArray()) }
    }
}

@Composable
fun rememberAnswer(): () -> Unit {
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { Calls.answer() }
    return {
        val need = mutableListOf<String>()
        if (!Calls.has(Manifest.permission.RECORD_AUDIO)) need.add(Manifest.permission.RECORD_AUDIO)
        if (Calls.video && !Calls.has(Manifest.permission.CAMERA)) need.add(Manifest.permission.CAMERA)
        if (need.isEmpty()) Calls.answer() else launcher.launch(need.toTypedArray())
    }
}

@Composable
fun VideoView(track: VideoTrack?, mirror: Boolean, overlay: Boolean, modifier: Modifier) {
    var view by remember { mutableStateOf<TextureRenderer?>(null) }
    AndroidView({ c -> TextureRenderer(c).apply { init(Calls.eglBase.eglBaseContext, mirror); view = this } }, modifier, onRelease = { it.release() })
    DisposableEffect(track, view) {
        val v = view
        if (v != null) track?.addSink(v)
        onDispose { if (v != null) runCatching { track?.removeSink(v) } }
    }
}

/** Переливающийся фон звонка */
@Composable
fun AuroraBackground(speed: Float) {
    val p = P
    val t = rememberInfiniteTransition(label = "aur")
    val a by t.animateFloat(0f, (2 * Math.PI).toFloat(), infiniteRepeatable(tween((9000 / speed).toInt(), easing = LinearEasing)), label = "a")
    Canvas(Modifier.fillMaxSize()) {
        drawRect(Color(0xFF0B0B1E))
        val w = size.width; val h = size.height
        val blobs = listOf(p.a1 to 0f, p.a2 to 2.1f, Color(0xFFFF5B8A) to 4.2f)
        blobs.forEach { (c, ph) ->
            val cx = w * (0.5f + 0.35f * cos(a + ph)); val cy = h * (0.45f + 0.3f * sin(a * 0.8f + ph))
            drawCircle(Brush.radialGradient(listOf(c.copy(alpha = 0.55f), Color.Transparent), Offset(cx, cy), w * 0.8f), w * 0.8f, Offset(cx, cy))
        }
    }
}

@Composable
private fun PulseRings(size: Int) {
    val t = rememberInfiniteTransition(label = "pulse")
    val k by t.animateFloat(0f, 1f, infiniteRepeatable(tween(1800, easing = LinearEasing)), label = "k")
    Canvas(Modifier.size((size * 1.9f).dp)) {
        for (i in 0..2) {
            val f = (k + i / 3f) % 1f
            drawCircle(Color.White.copy(alpha = 0.35f * (1 - f)), radius = size.dp.toPx() / 2 * (1 + f * 0.85f), style = androidx.compose.ui.graphics.drawscope.Stroke(2.dp.toPx()))
        }
    }
}

object CallsUi {
    @Composable
    fun Overlay() {
        val show = Calls.state != Calls.State.Idle
        AnimatedVisibility(show, enter = fadeIn() + slideInVertically { it / 6 }, exit = fadeOut()) { Screen() }
    }

    @Composable
    private fun Screen() {
        BackHandler { /* звонок сворачивается только кнопкой «Завершить» */ }
        var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
        LaunchedEffect(Unit) { while (true) { now = System.currentTimeMillis(); delay(1000) } }
        val active = Calls.state == Calls.State.Active
        val showRemote = Calls.video && active && Calls.p2p && Calls.remoteVideo != null && !Calls.peerCamOff
        val relay = Calls.relayImage
        val showRelay = Calls.video && active && !Calls.p2p && relay != null && !Calls.peerCamOff
        val status = Calls.statusText.ifEmpty { Calls.startedAt?.let { Fmt.duration((now - it) / 1000.0) } ?: "" }
        Box(Modifier.fillMaxSize().clickable(remember { MutableInteractionSource() }, null) {}) {
            AuroraBackground(if (active) 0.7f else 1.4f)
            if (showRemote) VideoView(Calls.remoteVideo, false, false, Modifier.fillMaxSize())
            else if (showRelay && relay != null) Image(relay.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
            Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding(), horizontalAlignment = Alignment.CenterHorizontally) {
                if (!showRemote && !showRelay) {
                    Spacer(Modifier.height(50.dp))
                    Box(Modifier.height(220.dp), contentAlignment = Alignment.Center) {
                        if (!active) PulseRings(130)
                        Box(Modifier.border(2.dp, Color.White.copy(alpha = 0.35f), CircleShape)) { Avatar(Calls.peerName, Calls.peerAvatar, Calls.peerColor, 130.dp) }
                    }
                    Text(Calls.peerName, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 30.sp)
                    Spacer(Modifier.height(6.dp))
                    Text(status, color = Color.White.copy(alpha = 0.75f), fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                } else {
                    Text("${Calls.peerName} · $status", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp,
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 10.dp))
                }
                Spacer(Modifier.weight(1f))
                Controls()
                Spacer(Modifier.height(30.dp))
            }
            val lv = Calls.localVideo
            if (Calls.video && lv != null && !Calls.camOff && Calls.state != Calls.State.Incoming) {
                VideoView(lv, true, true, Modifier.statusBarsPadding().padding(top = 50.dp, end = 16.dp).align(Alignment.TopEnd)
                    .size(112.dp, 160.dp).clip(RoundedCornerShape(16.dp)).border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(16.dp)))
            }
        }
    }

    @Composable
    private fun Controls() {
        val p = P
        val answer = rememberAnswer()
        if (Calls.state == Calls.State.Incoming) {
            Row(horizontalArrangement = Arrangement.spacedBy(80.dp)) {
                Ringing(Icons.Filled.CallEnd, p.danger, "Отклонить", false) { Calls.endTapped() }
                Ringing(if (Calls.video) Icons.Filled.Videocam else Icons.Filled.Call, Color(0xFF2ECC71), "Ответить", true) { answer() }
            }
        } else {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(22.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                    Round(if (Calls.muted) Icons.Filled.MicOff else Icons.Filled.Mic, Calls.muted, "Микрофон") { Calls.toggleMute() }
                    val camOn = Calls.localVideo != null && !Calls.camOff
                    Round(if (camOn) Icons.Filled.Videocam else Icons.Filled.VideocamOff, !camOn, "Камера") {
                        if (Calls.localVideo == null && !Calls.has(Manifest.permission.CAMERA)) AppModel.say("Разрешите доступ к камере в настройках Android") else Calls.toggleCamera()
                    }
                    AnimatedVisibility(camOn, enter = scaleIn() + fadeIn(), exit = scaleOut() + fadeOut()) {
                        Round(Icons.Filled.Cameraswitch, false, "Повернуть") { Calls.flipCamera() }
                    }
                    Round(Icons.AutoMirrored.Filled.VolumeUp, Calls.speaker, "Динамик") { Calls.toggleSpeaker() }
                }
                Round(Icons.Filled.CallEnd, false, "Завершить", bg = p.danger) { Calls.endTapped() }
            }
        }
    }

    @Composable
    private fun Round(icon: ImageVector, on: Boolean, label: String, bg: Color? = null, onClick: () -> Unit) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(64.dp).clip(CircleShape).background(bg ?: if (on) Color.White else Color.White.copy(alpha = 0.18f)).bouncy(onClick), contentAlignment = Alignment.Center) {
                Icon(icon, null, tint = if (on && bg == null) Color.Black else Color.White, modifier = Modifier.size(28.dp))
            }
            Spacer(Modifier.height(6.dp))
            Text(label, color = Color.White.copy(alpha = 0.85f), fontSize = 12.sp)
        }
    }

    /** Кнопки входящего: «Ответить» покачивается, обе пульсируют */
    @Composable
    private fun Ringing(icon: ImageVector, color: Color, label: String, answer: Boolean, onClick: () -> Unit) {
        val t = rememberInfiniteTransition(label = "r")
        val s by t.animateFloat(1f, 1.12f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "s")
        val r by t.animateFloat(-14f, 14f, infiniteRepeatable(tween(160), RepeatMode.Reverse), label = "rot")
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(74.dp).scale(s).clip(CircleShape).background(color).bouncy(onClick), contentAlignment = Alignment.Center) {
                Icon(icon, null, tint = Color.White, modifier = Modifier.size(34.dp).rotate(if (answer) r else 0f))
            }
            Spacer(Modifier.height(8.dp))
            Text(label, color = Color.White, fontSize = 13.sp)
        }
    }
}
