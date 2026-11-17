package ru.volshebnymir.lumo.ui

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.DataKind
import ru.volshebnymir.lumo.core.FileStore
import ru.volshebnymir.lumo.core.Message
import kotlin.math.abs

data class Track(val id: Int, val chatId: String, val title: String, val artist: String, val url: String)

/** Музыка из чатов: играет в фоне, очередь — все аудио этого чата */
object Music {
    val AUDIO = setOf("mp3", "m4a", "wav", "flac", "aac", "opus", "ogg", "aiff", "alac")
    fun isAudio(name: String) = name.substringAfterLast('.', "").lowercase() in AUDIO

    var track by mutableStateOf<Track?>(null)
    var playing by mutableStateOf(false)
    var position by mutableLongStateOf(0L)
    var duration by mutableLongStateOf(0L)
    var queue by mutableStateOf<List<Track>>(emptyList())
    val progress: Float get() = if (duration > 0) (position.toFloat() / duration).coerceIn(0f, 1f) else 0f

    private var exo: ExoPlayer? = null
    private var ticker: Job? = null

    private fun trackOf(m: Message): Track? {
        val u = m.mediaUrl ?: return null
        val base = m.fileName.substringBeforeLast('.')
        val parts = base.split(" - ", limit = 2)
        return Track(m.id, m.chatId, if (parts.size > 1) parts[1] else base, if (parts.size > 1) parts[0] else "Lumo", u)
    }

    private fun player(): ExoPlayer = exo ?: ExoPlayer.Builder(AppModel.ctx).build().also { p ->
        // фокус звука: звонок, другое приложение — пауза; выдернули наушники — пауза
        p.setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(), true)
        p.setHandleAudioBecomingNoisy(true)
        p.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) { playing = isPlaying }
            override fun onPlaybackStateChanged(state: Int) {
                if (state == Player.STATE_READY) duration = p.duration.coerceAtLeast(0)
                if (state == Player.STATE_ENDED) next()
            }
        })
        exo = p
    }

    fun play(m: Message, all: List<Message>) {
        val q = all.filter { it.kind == "file" && !it.deleted && isAudio(it.fileName) }.mapNotNull { trackOf(it) }
        queue = q.ifEmpty { listOfNotNull(trackOf(m)) }
        trackOf(m)?.let { start(it) }
    }

    fun start(t: Track) {
        if (track?.id == t.id && exo != null) { resume(); return }
        Voice.stop()   // голосовое не играет вместе с музыкой
        track = t
        position = 0; duration = 0
        val p = player()
        val local = FileStore.local(t.url, DataKind.File)
        val src = local?.path ?: (ru.volshebnymir.lumo.core.Net.px(t.url) ?: t.url)
        p.setMediaItem(MediaItem.fromUri(src))
        p.prepare(); p.play()
        if (local == null) AppModel.scope.launch { FileStore.fetch(t.url, DataKind.File) }
        ticker?.cancel()
        ticker = AppModel.scope.launch {
            while (true) {
                exo?.let { position = it.currentPosition.coerceAtLeast(0); if (it.duration > 0) duration = it.duration }
                delay(200)
            }
        }
    }

    fun toggle() { if (playing) pause() else resume() }
    fun resume() { val p = exo; if (p == null) track?.let { start(it) } else p.play() }
    fun pause() { exo?.pause() }
    fun seek(f: Float) { val p = exo ?: return; if (duration > 0) { val t = (duration * f).toLong(); p.seekTo(t); position = t } }
    fun next() {
        val i = queue.indexOfFirst { it.id == track?.id }
        if (i >= 0 && i + 1 < queue.size) start(queue[i + 1]) else { pause(); exo?.seekTo(0); position = 0 }
    }
    fun prev() {
        if (position > 3000) { exo?.seekTo(0); position = 0; return }
        val i = queue.indexOfFirst { it.id == track?.id }
        if (i > 0) start(queue[i - 1]) else { exo?.seekTo(0); position = 0 }
    }
    fun stop() {
        ticker?.cancel(); ticker = null
        exo?.release(); exo = null
        track = null; playing = false; position = 0; duration = 0; queue = emptyList()
    }
}

private fun fmtMs(ms: Long): String { val s = (ms / 1000).toInt(); return "%d:%02d".format(s / 60, s % 60) }

/** Три «пляшущие» полоски */
@Composable
fun Equalizer(color: Color, playing: Boolean, height: Dp = 14.dp) {
    val inf = rememberInfiniteTransition(label = "eq")
    Row(horizontalArrangement = Arrangement.spacedBy(2.dp), verticalAlignment = Alignment.Bottom, modifier = Modifier.height(height)) {
        for (i in 0 until 3) {
            val f by inf.animateFloat(0.3f, 1f, infiniteRepeatable(tween(420, delayMillis = i * 120, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "b$i")
            val h by animateFloatAsState(if (playing) f else 0.45f, spring(stiffness = Spring.StiffnessLow), label = "h$i")
            Box(Modifier.width(2.5.dp).fillMaxHeight(h).clip(RoundedCornerShape(2.dp)).background(color))
        }
    }
}

/** Иконка «играть / пауза» перетекает с поворотом */
@Composable
fun PlayPauseIcon(playing: Boolean, tint: Color, size: Dp) {
    Box(contentAlignment = Alignment.Center) {
        val a by animateFloatAsState(if (playing) 1f else 0f, spring(0.7f, Spring.StiffnessMediumLow), label = "pp")
        Icon(Icons.Filled.PlayArrow, null, tint = tint, modifier = Modifier.size(size).graphicsLayer { alpha = 1 - a; scaleX = 1 - 0.6f * a; scaleY = 1 - 0.6f * a; rotationZ = -90 * a })
        Icon(Icons.Filled.Pause, null, tint = tint, modifier = Modifier.size(size).graphicsLayer { alpha = a; scaleX = 0.4f + 0.6f * a; scaleY = 0.4f + 0.6f * a; rotationZ = 90 * (1 - a) })
    }
}

/** Плашка «играет музыка» — над списком чатов и под шапкой чата */
@Composable
fun MiniPlayerBar(compact: Boolean = false) {
    val p = P
    var open by remember { mutableStateOf(false) }
    var drag by remember { mutableFloatStateOf(0f) }
    val dx by animateFloatAsState(drag, spring(0.8f, Spring.StiffnessMediumLow), label = "dx")
    val t = Music.track
    AnimatedVisibility(
        t != null,
        enter = expandVertically(spring(0.85f, Spring.StiffnessLow), expandFrom = Alignment.Top) + fadeIn(tween(260)) + scaleIn(initialScale = 0.94f),
        exit = shrinkVertically(spring(1f, Spring.StiffnessMediumLow)) + fadeOut(tween(200)) + scaleOut(targetScale = 0.94f),
    ) {
        val cur = t ?: Music.queue.firstOrNull() ?: return@AnimatedVisibility
        Box(
            Modifier.padding(horizontal = if (compact) 10.dp else 14.dp, vertical = if (compact) 4.dp else 6.dp)
                .graphicsLayer { translationX = dx; alpha = 1f - (abs(dx) / 700f).coerceAtMost(0.6f) }
                .pointerInput(Unit) {
                    detectHorizontalDragGestures(
                        onDragEnd = { if (abs(drag) > 260f) { drag = if (drag > 0) 1400f else -1400f; AppModel.scope.launch { delay(180); Music.stop(); drag = 0f } } else drag = 0f },
                        onDragCancel = { drag = 0f },
                    ) { _, d -> drag += d }
                }
                .clip(RoundedCornerShape(14.dp)).background(p.panel).border(0.5.dp, p.line, RoundedCornerShape(14.dp))
                .bouncy { open = true },
        ) {
            Row(Modifier.padding(horizontal = 10.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                val s by animateFloatAsState(if (Music.playing) 1f else 0.9f, spring(0.7f), label = "cov")
                Box(Modifier.size(if (compact) 30.dp else 36.dp).scale(s).clip(RoundedCornerShape(9.dp)).background(Brush.linearGradient(listOf(p.a1, p.a2))), contentAlignment = Alignment.Center) {
                    Equalizer(Color.White, Music.playing)
                }
                Spacer(Modifier.width(11.dp))
                AnimatedContent(cur.id, Modifier.weight(1f), transitionSpec = {
                    (slideInHorizontally { it / 3 } + fadeIn()) togetherWith (slideOutHorizontally { -it / 3 } + fadeOut())
                }, label = "tr") { _ ->
                    Column {
                        Text(cur.title, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = if (compact) 13.sp else 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Crossfade(Music.playing, label = "st") { pl -> Text(if (pl) cur.artist else "На паузе", color = p.muted, fontSize = if (compact) 11.sp else 12.sp, maxLines = 1) }
                    }
                }
                Box(Modifier.size(36.dp).clip(CircleShape).bouncy { Music.toggle() }, contentAlignment = Alignment.Center) { PlayPauseIcon(Music.playing, p.a1, 22.dp) }
                Box(Modifier.size(34.dp).clip(CircleShape).bouncy { Music.next() }, contentAlignment = Alignment.Center) { Icon(Icons.Filled.SkipNext, null, tint = p.muted, modifier = Modifier.size(20.dp)) }
                if (!compact) Box(Modifier.size(30.dp).clip(CircleShape).bouncy { Music.stop() }, contentAlignment = Alignment.Center) { Icon(Icons.Filled.Close, null, tint = p.muted, modifier = Modifier.size(16.dp)) }
            }
            val pr by animateFloatAsState(Music.progress, tween(220, easing = LinearEasing), label = "pr")
            Box(Modifier.align(Alignment.BottomStart).fillMaxWidth(pr).height(2.5.dp).background(p.a1.copy(alpha = 0.75f)))
        }
    }
    if (open && t != null) PlayerDialog { open = false }
    LaunchedEffect(t == null) { if (t == null) open = false }
}

@Composable
fun PlayerDialog(onClose: () -> Unit) {
    val p = P
    var scrub by remember { mutableStateOf<Float?>(null) }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Column(Modifier.fillMaxSize().background(p.bg).statusBarsPadding().navigationBarsPadding(), horizontalAlignment = Alignment.CenterHorizontally) {
            Row(Modifier.fillMaxWidth().padding(6.dp)) {
                RoundIcon(Icons.Filled.KeyboardArrowDown) { onClose() }
            }
            val t = Music.track ?: return@Column
            val s by animateFloatAsState(if (Music.playing) 1f else 0.88f, spring(0.65f, Spring.StiffnessLow), label = "art")
            Box(Modifier.padding(top = 16.dp).size(240.dp).scale(s).clip(RoundedCornerShape(28.dp)).background(Brush.linearGradient(listOf(p.a1, p.a2))), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.MusicNote, null, tint = Color.White.copy(alpha = 0.9f), modifier = Modifier.size(80.dp))
                Box(Modifier.align(Alignment.BottomCenter).padding(bottom = 26.dp)) { Equalizer(Color.White, Music.playing, 26.dp) }
            }
            AnimatedContent(t.id, transitionSpec = { (slideInHorizontally { it / 3 } + fadeIn()) togetherWith (slideOutHorizontally { -it / 3 } + fadeOut()) }, label = "pt") { _ ->
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(top = 26.dp, start = 30.dp, end = 30.dp)) {
                    Text(t.title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 22.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(t.artist, color = p.muted, fontSize = 15.sp)
                }
            }
            Column(Modifier.padding(horizontal = 30.dp, vertical = 16.dp)) {
                Slider(scrub ?: Music.progress, { scrub = it }, onValueChangeFinished = { scrub?.let { Music.seek(it) }; scrub = null },
                    colors = SliderDefaults.colors(thumbColor = p.a1, activeTrackColor = p.a1))
                Row {
                    Text(fmtMs(((scrub ?: Music.progress) * Music.duration).toLong()), color = p.muted, fontSize = 12.sp)
                    Spacer(Modifier.weight(1f))
                    Text(fmtMs(Music.duration), color = p.muted, fontSize = 12.sp)
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(36.dp)) {
                Box(Modifier.size(56.dp).clip(CircleShape).bouncy { Music.prev() }, contentAlignment = Alignment.Center) { Icon(Icons.Filled.SkipPrevious, null, tint = p.a1, modifier = Modifier.size(34.dp)) }
                Box(Modifier.size(76.dp).clip(CircleShape).background(p.a1).bouncy { Music.toggle() }, contentAlignment = Alignment.Center) { PlayPauseIcon(Music.playing, Color.White, 40.dp) }
                Box(Modifier.size(56.dp).clip(CircleShape).bouncy { Music.next() }, contentAlignment = Alignment.Center) { Icon(Icons.Filled.SkipNext, null, tint = p.a1, modifier = Modifier.size(34.dp)) }
            }
            if (Music.queue.size > 1) {
                Text("Из этого чата", color = p.muted, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, modifier = Modifier.fillMaxWidth().padding(start = 24.dp, top = 20.dp, bottom = 4.dp))
                LazyColumn(Modifier.fillMaxWidth().weight(1f)) {
                    items(Music.queue, key = { it.id }) { q ->
                        val cur = q.id == t.id
                        Row(Modifier.fillMaxWidth().animateItem().bouncy { Music.start(q) }.padding(horizontal = 24.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.width(22.dp)) { if (cur) Equalizer(p.a1, Music.playing) else Icon(Icons.Filled.MusicNote, null, tint = p.muted, modifier = Modifier.size(15.dp)) }
                            Text(q.title, color = if (cur) p.a1 else p.text, fontWeight = if (cur) FontWeight.SemiBold else FontWeight.Normal, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            } else Spacer(Modifier.weight(1f))
        }
    }
}

/** Пузырь аудиофайла в чате */
@Composable
fun AudioBubble(m: Message, mine: Boolean, fg: Color, sub: Color) {
    val p = P
    val cur = Music.track?.id == m.id
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.bouncy {
        if (cur) Music.toggle() else Music.play(m, AppModel.messages[m.chatId] ?: listOf(m))
    }) {
        Box(Modifier.size(44.dp).clip(CircleShape).background(if (mine) Color.White.copy(alpha = 0.22f) else p.a1), contentAlignment = Alignment.Center) {
            PlayPauseIcon(cur && Music.playing, Color.White, 26.dp)
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.widthIn(min = 120.dp, max = 200.dp).animateContentSize(spring(0.85f, Spring.StiffnessMediumLow))) {
            Text(m.fileName.substringBeforeLast('.'), color = fg, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (cur) {
                val pr by animateFloatAsState(Music.progress, tween(220, easing = LinearEasing), label = "bp")
                Box(Modifier.padding(vertical = 4.dp).fillMaxWidth().height(3.dp).clip(CircleShape).background((if (mine) Color.White else p.a1).copy(alpha = 0.25f))) {
                    Box(Modifier.fillMaxWidth(pr).fillMaxHeight().background(if (mine) Color.White else p.a1))
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (cur) { Equalizer(if (mine) Color.White else p.a1, Music.playing, 11.dp); Spacer(Modifier.width(6.dp)) }
                Text(m.fileSize?.let { ru.volshebnymir.lumo.core.Fmt.size(it) } ?: "Аудио", color = sub, fontSize = 12.5.sp)
            }
        }
    }
}
