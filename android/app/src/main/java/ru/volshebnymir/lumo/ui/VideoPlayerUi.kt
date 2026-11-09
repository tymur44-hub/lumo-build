package ru.volshebnymir.lumo.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Forward10
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Replay10
import androidx.compose.material.icons.filled.VolumeOff
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.coerceIn
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import kotlinx.coroutines.delay

private fun fmtT(ms: Long): String {
    val t = (ms / 1000).coerceAtLeast(0)
    val h = t / 3600
    val m = (t % 3600) / 60
    val s = t % 60
    return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
}

private fun rateText(r: Float): String {
    val s = if (r == r.toInt().toFloat()) r.toInt().toString() else r.toString()
    return s.replace('.', ',') + "×"
}

/** Полоса перемотки: буфер, ползунок, метка времени при перетаскивании */
@Composable
private fun VpScrubber(pos: Long, dur: Long, buf: Long, onScrub: (Long) -> Unit, onEnd: (Long) -> Unit) {
    var drag by remember { mutableStateOf(false) }
    var dv by remember { mutableLongStateOf(0L) }
    BoxWithConstraints(Modifier.fillMaxWidth().height(40.dp)) {
        val wPx = constraints.maxWidth.toFloat().coerceAtLeast(1f)
        val full: Dp = maxWidth
        fun at(x: Float): Long = if (dur > 0) (dur * (x / wPx).coerceIn(0f, 1f)).toLong() else 0L
        val shown = if (drag) dv else pos
        val frac = if (dur > 0) (shown.toFloat() / dur).coerceIn(0f, 1f) else 0f
        val bfrac = if (dur > 0) (buf.toFloat() / dur).coerceIn(0f, 1f) else 0f
        val h = if (drag) 8.dp else 4.dp
        val k = if (drag) 22.dp else 14.dp
        Box(
            Modifier.fillMaxSize()
                .pointerInput(dur) { detectTapGestures { o -> val t = at(o.x); onScrub(t); onEnd(t) } }
                .pointerInput(dur) {
                    detectHorizontalDragGestures(
                        onDragStart = { o -> drag = true; dv = at(o.x); onScrub(dv) },
                        onDragEnd = { drag = false; onEnd(dv) },
                        onDragCancel = { drag = false; onEnd(dv) },
                    ) { change, _ -> change.consume(); dv = at(change.position.x); onScrub(dv) }
                }
        ) {
            Box(Modifier.align(Alignment.CenterStart).fillMaxWidth().height(h).clip(CircleShape).background(Color.White.copy(alpha = 0.25f)))
            Box(Modifier.align(Alignment.CenterStart).fillMaxWidth(bfrac).height(h).clip(CircleShape).background(Color.White.copy(alpha = 0.38f)))
            Box(Modifier.align(Alignment.CenterStart).fillMaxWidth(frac).height(h).clip(CircleShape).background(Color.White))
            Box(Modifier.align(Alignment.CenterStart).offset(x = full * frac - k / 2).size(k).clip(CircleShape).background(Color.White))
            if (drag) {
                Box(
                    Modifier.align(Alignment.TopStart)
                        .offset(x = (full * frac - 30.dp).coerceIn(0.dp, (full - 60.dp).coerceAtLeast(0.dp)), y = (-30).dp)
                        .size(60.dp, 26.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.65f)),
                    contentAlignment = Alignment.Center
                ) { Text(fmtT(shown), color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold) }
            }
        }
    }
}

@Composable
private fun VpCircle(icon: androidx.compose.ui.graphics.vector.ImageVector, size: Dp = 40.dp, onClick: () -> Unit) {
    Box(Modifier.size(size).clip(CircleShape).background(Color.White.copy(alpha = 0.16f)).clickable { onClick() }, contentAlignment = Alignment.Center) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(size * 0.5f))
    }
}

/** Собственный видеоплеер: перемотка, скорость, ±10 секунд двойным касанием, свайп вниз — закрыть */
@Composable
fun LumoVideoPlayer(src: String, onClose: () -> Unit, onSave: () -> Unit) {
    val ctx = LocalContext.current
    val player = remember { ru.volshebnymir.lumo.core.LumoPlayer.build(ctx).apply { setMediaItem(MediaItem.fromUri(src)); prepare(); playWhenReady = true } }

    var wants by remember { mutableStateOf(true) }
    var buffering by remember { mutableStateOf(true) }
    var ended by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    var pos by remember { mutableLongStateOf(0L) }
    var dur by remember { mutableLongStateOf(0L) }
    var buf by remember { mutableLongStateOf(0L) }
    var speed by remember { mutableFloatStateOf(1f) }
    var muted by remember { mutableStateOf(false) }
    var visible by remember { mutableStateOf(true) }
    var scrubbing by remember { mutableStateOf(false) }
    var dragY by remember { mutableFloatStateOf(0f) }
    var flash by remember { mutableIntStateOf(0) }
    var flashKey by remember { mutableIntStateOf(0) }
    var tick by remember { mutableIntStateOf(0) }
    var menu by remember { mutableStateOf(false) }

    DisposableEffect(player) {
        val l = object : Player.Listener {
            override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) { wants = playWhenReady }
            override fun onPlaybackStateChanged(state: Int) {
                buffering = state == Player.STATE_BUFFERING
                ended = state == Player.STATE_ENDED
                if (state == Player.STATE_READY && player.duration > 0) dur = player.duration
            }
            override fun onPlayerError(error: PlaybackException) { failed = true; buffering = false }
        }
        player.addListener(l)
        onDispose { player.removeListener(l); player.release() }
    }
    LaunchedEffect(player) {
        while (true) {
            if (!scrubbing) pos = player.currentPosition
            if (player.duration > 0) dur = player.duration
            buf = player.bufferedPosition
            delay(100)
        }
    }
    LaunchedEffect(visible, wants, scrubbing, ended, tick) {
        if (visible && wants && !scrubbing && !ended) { delay(3200); visible = false }
    }
    LaunchedEffect(ended) { if (ended) visible = true }
    LaunchedEffect(flashKey) { if (flash != 0) { delay(550); flash = 0 } }

    fun poke() { tick++ }
    fun toggle() {
        if (ended) { player.seekTo(0); player.play() }
        else if (player.playWhenReady) player.pause() else player.play()
        poke()
    }
    fun jump(d: Long, side: Int) {
        val to = (player.currentPosition + d).coerceIn(0L, if (dur > 0) dur else Long.MAX_VALUE)
        player.seekTo(to); pos = to
        flash = side; flashKey++
    }

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        AndroidView(
            { c -> PlayerView(c).apply { useController = false; resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT; this.player = player } },
            Modifier.fillMaxSize().graphicsLayer {
                translationY = dragY
                val s = 1f - (dragY / 3000f).coerceAtMost(0.25f)
                scaleX = s; scaleY = s
            }
        )

        // жесты: касание — показать/скрыть кнопки, двойное слева/справа — ±10 секунд, свайп вниз — закрыть
        Box(
            Modifier.fillMaxSize()
                .pointerInput(Unit) {
                    detectTapGestures(
                        onTap = { visible = !visible; if (visible) poke() },
                        onDoubleTap = { o ->
                            val w = size.width
                            when {
                                o.x < w / 3f -> jump(-10_000, -1)
                                o.x > w * 2f / 3f -> jump(10_000, 1)
                                else -> toggle()
                            }
                        }
                    )
                }
                .pointerInput(Unit) {
                    detectVerticalDragGestures(
                        onDragEnd = { if (dragY > 300f) onClose() else dragY = 0f },
                        onDragCancel = { dragY = 0f },
                    ) { _, dy -> dragY = (dragY + dy).coerceAtLeast(0f) }
                }
        )

        if (buffering && !failed && !visible) {
            CircularProgressIndicator(Modifier.align(Alignment.Center).size(46.dp), color = Color.White, strokeWidth = 3.dp)
        }

        if (flash != 0) {
            Column(
                Modifier.align(if (flash < 0) Alignment.CenterStart else Alignment.CenterEnd).padding(horizontal = 28.dp)
                    .size(104.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.2f)),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center
            ) {
                Icon(if (flash < 0) Icons.Filled.Replay10 else Icons.Filled.Forward10, null, tint = Color.White, modifier = Modifier.size(36.dp))
                Text("10 сек", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }
        }

        if (failed) {
            Text("Не удалось загрузить видео", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.Center))
        }

        AnimatedVisibility(visible, enter = fadeIn(), exit = fadeOut()) {
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.6f), Color.Transparent, Color.Transparent, Color.Black.copy(alpha = 0.7f)))
                )
            ) {
                Row(
                    Modifier.align(Alignment.TopCenter).statusBarsPadding().fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    VpCircle(Icons.Filled.Close) { onClose() }
                    Box(Modifier.weight(1f)) {}
                    Box {
                        Box(
                            Modifier.height(40.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.16f)).clickable { menu = true; poke() }.padding(horizontal = 14.dp),
                            contentAlignment = Alignment.Center
                        ) { Text(rateText(speed), color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Bold) }
                        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                            listOf(0.5f, 0.75f, 1f, 1.25f, 1.5f, 2f).forEach { r ->
                                DropdownMenuItem(
                                    text = { Text(rateText(r) + if (r == speed) "   •" else "") },
                                    onClick = { speed = r; player.setPlaybackSpeed(r); menu = false; poke() }
                                )
                            }
                        }
                    }
                    VpCircle(if (muted) Icons.Filled.VolumeOff else Icons.Filled.VolumeUp) {
                        muted = !muted; player.volume = if (muted) 0f else 1f; poke()
                    }
                    VpCircle(Icons.Filled.Download) { onSave(); poke() }
                }

                if (!failed) {
                    Row(Modifier.align(Alignment.Center), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(36.dp)) {
                        VpCircle(Icons.Filled.Replay10, 52.dp) { jump(-10_000, -1); poke() }
                        Box(Modifier.size(76.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.45f)).clickable { toggle() }, contentAlignment = Alignment.Center) {
                            if (buffering) CircularProgressIndicator(Modifier.size(34.dp), color = Color.White, strokeWidth = 3.dp)
                            else Icon(
                                if (ended) Icons.Filled.Replay else if (wants) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                                null, tint = Color.White, modifier = Modifier.size(38.dp)
                            )
                        }
                        VpCircle(Icons.Filled.Forward10, 52.dp) { jump(10_000, 1); poke() }
                    }
                }

                Column(Modifier.align(Alignment.BottomCenter).navigationBarsPadding().fillMaxWidth().padding(start = 18.dp, end = 18.dp, bottom = 10.dp)) {
                    VpScrubber(pos, dur, buf,
                        onScrub = { t -> scrubbing = true; pos = t },
                        onEnd = { t -> player.seekTo(t); pos = t; scrubbing = false; poke() })
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(fmtT(pos), color = Color.White.copy(alpha = 0.92f), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        Text(fmtT(dur), color = Color.White.copy(alpha = 0.92f), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}
