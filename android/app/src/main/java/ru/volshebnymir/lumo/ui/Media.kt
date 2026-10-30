package ru.volshebnymir.lumo.ui

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import coil.compose.AsyncImage
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.Message
import java.io.ByteArrayOutputStream
import java.io.File

/** Работа с файлами: чтение выбранного, сжатие фото */
object MediaUtil {
    fun read(ctx: Context, uri: Uri): ByteArray? = runCatching { ctx.contentResolver.openInputStream(uri)?.use { it.readBytes() } }.getOrNull()

    fun name(ctx: Context, uri: Uri): String {
        runCatching {
            ctx.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) return c.getString(0) ?: "file"
            }
        }
        return uri.lastPathSegment ?: "file"
    }

    /** Фото → JPEG не больше 1600 px */
    fun jpeg(bytes: ByteArray): Triple<ByteArray, Int, Int>? {
        val b0 = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        val s = minOf(1f, 1600f / maxOf(b0.width, b0.height))
        val b = if (s < 1f) Bitmap.createScaledBitmap(b0, (b0.width * s).toInt(), (b0.height * s).toInt(), true) else b0
        val out = ByteArrayOutputStream()
        b.compress(Bitmap.CompressFormat.JPEG, 85, out)
        return Triple(out.toByteArray(), b.width, b.height)
    }

    /** Снимок с камеры: поворачиваем по данным EXIF */
    fun fixRotation(file: File, bytes: ByteArray): ByteArray {
        val deg = runCatching {
            when (android.media.ExifInterface(file.absolutePath).getAttributeInt(android.media.ExifInterface.TAG_ORIENTATION, 1)) {
                android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90; android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180
                android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270; else -> 0
            }
        }.getOrDefault(0)
        if (deg == 0) return bytes
        val b = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return bytes
        val r = Bitmap.createBitmap(b, 0, 0, b.width, b.height, android.graphics.Matrix().apply { postRotate(deg.toFloat()) }, true)
        val out = ByteArrayOutputStream(); r.compress(Bitmap.CompressFormat.JPEG, 92, out); return out.toByteArray()
    }

    /** Сохраняет фото, видео или файл прямо в галерею или «Загрузки», без перехода по ссылке */
    fun save(ctx: Context, url: String?, kind: String) {
        if (url.isNullOrEmpty()) return
        if (android.os.Build.VERSION.SDK_INT < 29) { open(ctx, url); return }
        ru.volshebnymir.lumo.core.AppModel.say("Сохраняю…")
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main).launch {
            val ok = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                runCatching {
                    val req = okhttp3.Request.Builder().url(ru.volshebnymir.lumo.core.Net.px(url) ?: url).build()
                    ru.volshebnymir.lumo.core.Api.http.newCall(req).execute().use { r ->
                        if (!r.isSuccessful) error("http " + r.code)
                        var mime = r.header("Content-Type")?.substringBefore(';')?.trim().orEmpty()
                        if (mime.isEmpty() || mime == "application/octet-stream") mime = when (kind) { "video" -> "video/mp4"; "image" -> "image/jpeg"; else -> "application/octet-stream" }
                        val ext = android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: url.substringAfterLast('.', "bin").take(5)
                        val name = "Lumo_" + System.currentTimeMillis() + "." + ext
                        val (coll, dir) = when {
                            mime.startsWith("image/") -> android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI to "Pictures/Lumo"
                            mime.startsWith("video/") -> android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI to "Movies/Lumo"
                            else -> android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI to "Download/Lumo"
                        }
                        val cv = android.content.ContentValues().apply {
                            put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, name)
                            put(android.provider.MediaStore.MediaColumns.MIME_TYPE, mime)
                            put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, dir)
                            put(android.provider.MediaStore.MediaColumns.IS_PENDING, 1)
                        }
                        val uri = ctx.contentResolver.insert(coll, cv) ?: error("insert")
                        ctx.contentResolver.openOutputStream(uri)!!.use { out -> r.body!!.byteStream().copyTo(out) }
                        cv.clear(); cv.put(android.provider.MediaStore.MediaColumns.IS_PENDING, 0)
                        ctx.contentResolver.update(uri, cv, null, null)
                    }
                }.isSuccess
            }
            ru.volshebnymir.lumo.core.AppModel.say(if (ok) "Сохранено в галерею" else "Не удалось сохранить")
        }
    }

    fun open(ctx: Context, url: String?) {
        if (url.isNullOrEmpty()) return
        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(ru.volshebnymir.lumo.core.Net.px(url))).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
}

/** Проигрыватель голосовых: один на всё приложение */
object Voice {
    var current by mutableStateOf<Int?>(null)
    var playing by mutableStateOf(false)
    var progress by mutableFloatStateOf(0f)
    var position by mutableFloatStateOf(0f)
    var speed by mutableFloatStateOf(1f)
    private var mp: MediaPlayer? = null

    /** Скорость прослушивания: 1× → 1.5× → 2× */
    fun cycleSpeed() {
        speed = when (speed) { 1f -> 1.5f; 1.5f -> 2f; else -> 1f }
        val p = mp ?: return
        runCatching { val was = p.isPlaying; p.playbackParams = p.playbackParams.setSpeed(speed); if (!was) p.pause() }
    }

    fun toggle(m: Message) {
        val src = m.localPath ?: m.mediaUrl ?: return
        if (current == m.id && mp != null) {
            val p = mp!!
            if (p.isPlaying) { p.pause(); playing = false } else { p.start(); playing = true }
            return
        }
        stop()
        current = m.id
        progress = 0f
        val p = MediaPlayer()
        mp = p
        runCatching {
            p.setDataSource(ru.volshebnymir.lumo.core.Net.px(src) ?: src)
            p.setOnPreparedListener { runCatching { it.playbackParams = it.playbackParams.setSpeed(speed) }; it.start(); playing = true }
            p.setOnCompletionListener { stop() }
            p.setOnErrorListener { _, _, _ -> stop(); true }
            p.prepareAsync()
        }.onFailure { stop() }
    }

    fun tick() {
        val p = mp ?: return
        runCatching { if (p.duration > 0) { progress = p.currentPosition.toFloat() / p.duration; position = p.currentPosition / 1000f } }
    }

    fun stop() {
        runCatching { mp?.release() }
        mp = null; current = null; playing = false; progress = 0f; position = 0f
    }
}

/** Запись голосового (AAC в m4a) */
class VoiceRecorder(private val ctx: Context) {
    private var rec: MediaRecorder? = null
    var file: File? = null
    val levels = mutableListOf<Int>()
    var startedAt = 0L

    fun start(): Boolean {
        val f = File(ctx.cacheDir, "voice-${System.currentTimeMillis()}.m4a")
        val r = if (android.os.Build.VERSION.SDK_INT >= 31) MediaRecorder(ctx) else @Suppress("DEPRECATION") MediaRecorder()
        return try {
            r.setAudioSource(MediaRecorder.AudioSource.MIC)
            r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            r.setAudioSamplingRate(44100)
            r.setAudioEncodingBitRate(64000)
            r.setOutputFile(f.absolutePath)
            r.prepare(); r.start()
            rec = r; file = f; levels.clear(); startedAt = System.currentTimeMillis()
            true
        } catch (e: Exception) { runCatching { r.release() }; false }
    }

    fun sample() {
        val a = runCatching { rec?.maxAmplitude ?: 0 }.getOrDefault(0)
        levels.add(minOf(31, (Math.sqrt(a / 32767.0) * 40).toInt()))
    }

    /** Остановить: возвращает файл, длительность (сек) и волну */
    fun stop(): Triple<File, Double, List<Int>>? {
        val r = rec ?: return null
        rec = null
        val dur = (System.currentTimeMillis() - startedAt) / 1000.0
        val ok = runCatching { r.stop() }.isSuccess
        runCatching { r.release() }
        val f = file ?: return null
        if (!ok) return null
        val src = if (levels.isEmpty()) listOf(4) else levels
        val wave = (0 until 40).map { i -> src[(i * src.size / 40).coerceIn(0, src.size - 1)] }
        return Triple(f, dur, wave)
    }

    fun cancel() { runCatching { rec?.stop() }; runCatching { rec?.release() }; rec = null; file?.delete() }
}

@Composable
fun WaveBars(wave: List<Int>, progress: Float, mine: Boolean, modifier: Modifier = Modifier) {
    val p = P
    val bars = wave.ifEmpty { List(40) { 6 } }
    Canvas(modifier.height(26.dp)) {
        val n = bars.size
        val step = size.width / n
        bars.forEachIndexed { i, v ->
            val done = i.toFloat() / n < progress
            val c = if (mine) (if (done) Color.White else Color.White.copy(alpha = 0.45f)) else (if (done) p.a1 else p.muted.copy(alpha = 0.45f))
            val h = (4 + v.coerceIn(0, 31) / 31f * 20).dp.toPx()
            val x = i * step + step / 2
            drawLine(c, Offset(x, size.height / 2 - h / 2), Offset(x, size.height / 2 + h / 2), strokeWidth = 2.5.dp.toPx(), cap = StrokeCap.Round)
        }
    }
}

@Composable
fun VoiceBubble(m: Message, mine: Boolean) {
    val p = P
    val cur = Voice.current == m.id
    LaunchedEffect(cur, Voice.playing) { while (cur && Voice.playing) { Voice.tick(); delay(80) } }
    Row(Modifier.width(252.dp).padding(vertical = 2.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(42.dp).clip(CircleShape).background(if (mine) Color.White.copy(alpha = 0.22f) else p.a1).bouncy { Voice.toggle(m) }, contentAlignment = Alignment.Center) {
            Icon(if (cur && Voice.playing) Icons.Filled.Pause else Icons.Filled.PlayArrow, null, tint = Color.White, modifier = Modifier.size(26.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            WaveBars(m.wave, if (cur) Voice.progress else 0f, mine, Modifier.fillMaxWidth())
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(if (cur) Fmt.duration(Voice.position.toDouble()) else Fmt.duration(m.duration), fontSize = 12.sp,
                    color = if (mine) Color.White.copy(alpha = 0.8f) else p.muted)
                if (cur) {
                    Spacer(Modifier.width(8.dp))
                    Text(if (Voice.speed == 1f) "1×" else if (Voice.speed == 1.5f) "1.5×" else "2×", fontSize = 11.sp, fontWeight = FontWeight.Bold,
                        color = if (mine) Color.White else p.a1,
                        modifier = Modifier.popIn().clip(androidx.compose.foundation.shape.RoundedCornerShape(8.dp))
                            .background(if (mine) Color.White.copy(alpha = 0.2f) else p.a1.copy(alpha = 0.15f)).bouncy { Voice.cycleSpeed() }.padding(horizontal = 6.dp, vertical = 1.dp))
                }
            }
        }
        Spacer(Modifier.width(8.dp))
        TranscribeButton(mine)
    }
}

/** Кнопка расшифровки справа от голосового: со значком замка, пока нет Premium */
@Composable
fun TranscribeButton(mine: Boolean) {
    val p = P
    val prem = ru.volshebnymir.lumo.core.AppModel.me?.premium == true
    val fg = if (mine) Color.White else p.a1
    Box(Modifier.size(width = 38.dp, height = 32.dp).clip(androidx.compose.foundation.shape.RoundedCornerShape(12.dp))
        .background(if (mine) Color.White.copy(alpha = 0.2f) else p.a1.copy(alpha = 0.14f))
        .bouncy {
            if (!prem) ru.volshebnymir.lumo.core.AppModel.say(ru.volshebnymir.lumo.core.PREMIUM_SOON)
            else ru.volshebnymir.lumo.core.AppModel.say("Расшифровка на Android пока в разработке")
        }, contentAlignment = Alignment.Center) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = fg, modifier = Modifier.size(13.dp))
            Text("A", color = fg, fontWeight = FontWeight.Black, fontSize = 15.sp)
        }
        if (!prem) Icon(Icons.Filled.Lock, null, tint = fg, modifier = Modifier.align(Alignment.BottomEnd).padding(end = 4.dp, bottom = 3.dp).size(11.dp))
    }
}

/** Видеокружок: по нажатию воспроизводится со звуком и плавно увеличивается */
@Composable
fun VideoNoteBubble(m: Message) {
    Row(verticalAlignment = Alignment.Bottom) {
        VideoNoteCircle(m)
        Spacer(Modifier.width(8.dp))
        TranscribeButton(false)
    }
}

@Composable
private fun VideoNoteCircle(m: Message) {
    val p = P
    val ctx = LocalContext.current
    var playing by remember { mutableStateOf(false) }
    var prog by remember { mutableFloatStateOf(0f) }
    val size by animateDpAsState(if (playing) 270.dp else 210.dp, tween(280), label = "vn")
    val src = m.localPath ?: m.mediaUrl
    Box(Modifier.size(size).clip(CircleShape).background(p.panel2).bouncy { playing = !playing }, contentAlignment = Alignment.Center) {
        if (playing && src != null) {
            val player = remember {
                ExoPlayer.Builder(ctx).build().apply {
                    setMediaItem(MediaItem.fromUri(ru.volshebnymir.lumo.core.Net.px(src) ?: src)); prepare(); playWhenReady = true
                    addListener(object : Player.Listener {
                        override fun onPlaybackStateChanged(s: Int) { if (s == Player.STATE_ENDED) playing = false }
                    })
                }
            }
            DisposableEffect(Unit) { onDispose { player.release() } }
            LaunchedEffect(Unit) { while (true) { if (player.duration > 0) prog = player.currentPosition.toFloat() / player.duration; delay(50) } }
            AndroidView({ PlayerView(it).apply { useController = false; resizeMode = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_ZOOM; this.player = player } },
                Modifier.fillMaxSize().clip(CircleShape))
            Canvas(Modifier.fillMaxSize()) {
                drawArc(Color.White, -90f, 360f * prog, false, style = Stroke(4.dp.toPx(), cap = StrokeCap.Round))
            }
        } else {
            if (src != null) AsyncImage(src, null, Modifier.fillMaxSize().clip(CircleShape), contentScale = ContentScale.Crop)
            Box(Modifier.size(46.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.45f)), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.PlayArrow, null, tint = Color.White, modifier = Modifier.size(30.dp))
            }
            Box(Modifier.align(Alignment.BottomCenter).padding(bottom = 14.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.45f)).padding(horizontal = 8.dp, vertical = 2.dp)) {
                Text(Fmt.duration(m.duration), color = Color.White, fontSize = 12.sp)
            }
        }
    }
}

/** Просмотр фото/видео на весь экран — по центру, с масштабом */
@Composable
fun MediaViewer(m: Message, onClose: () -> Unit) {
    val ctx = LocalContext.current
    BackHandler { onClose() }
    var scale by remember { mutableFloatStateOf(1f) }
    var off by remember { mutableStateOf(Offset.Zero) }
    val tr = rememberTransformableState { z, pan, _ -> scale = (scale * z).coerceIn(1f, 5f); off = if (scale > 1f) off + pan else Offset.Zero }
    val src = m.localPath ?: m.mediaUrl
    Box(Modifier.fillMaxSize().background(Color.Black).clickable(enabled = false) {}) {
        if (m.kind == "video" && src != null) {
            val player = remember { ExoPlayer.Builder(ctx).build().apply { setMediaItem(MediaItem.fromUri(ru.volshebnymir.lumo.core.Net.px(src) ?: src)); prepare(); playWhenReady = true } }
            DisposableEffect(Unit) { onDispose { player.release() } }
            AndroidView({ PlayerView(it).apply { this.player = player } }, Modifier.fillMaxSize())
        } else {
            AsyncImage(src, null, Modifier.fillMaxSize().transformable(tr)
                .pointerInput(Unit) { detectTapGestures(onDoubleTap = { if (scale > 1f) { scale = 1f; off = Offset.Zero } else scale = 2.5f }) }
                .graphicsLayer { scaleX = scale; scaleY = scale; translationX = off.x; translationY = off.y },
                contentScale = ContentScale.Fit, alignment = Alignment.Center)
        }
        Row(Modifier.statusBarsPadding().fillMaxWidth().padding(10.dp), horizontalArrangement = Arrangement.SpaceBetween) {
            RoundIcon(Icons.Filled.Close, tint = Color.White, bg = Color.Black.copy(alpha = 0.4f)) { onClose() }
            RoundIcon(Icons.Filled.Download, tint = Color.White, bg = Color.Black.copy(alpha = 0.4f)) { MediaUtil.save(ctx, m.mediaUrl, m.kind) }
        }
        if (!m.body.isNullOrEmpty()) Text(m.body, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Medium,
            modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth().background(Color.Black.copy(alpha = 0.5f)).padding(18.dp).padding(bottom = 24.dp))
    }
}

