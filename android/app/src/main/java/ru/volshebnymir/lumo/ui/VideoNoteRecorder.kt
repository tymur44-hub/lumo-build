package ru.volshebnymir.lumo.ui

import android.annotation.SuppressLint
import androidx.activity.compose.BackHandler
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import kotlinx.coroutines.delay
import org.json.JSONObject
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.jsonOf
import java.io.File

/** Запись видеокружка (до 60 секунд): круглое превью, отмена, переворот камеры, отправка */
@SuppressLint("MissingPermission")
@Composable
fun VideoNoteRecorder(chatId: String, session: NoteSession, replyTo: () -> Int?, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val owner = LocalLifecycleOwner.current
    var front by remember { mutableStateOf(true) }
    var sec by remember { mutableFloatStateOf(0f) }
    var recording by remember { mutableStateOf<Recording?>(null) }
    var capture by remember { mutableStateOf<VideoCapture<Recorder>?>(null) }
    var send by remember { mutableStateOf(false) }
    var gen by remember { mutableIntStateOf(0) }
    var camera by remember { mutableStateOf<androidx.camera.core.Camera?>(null) }
    var zoom by remember { mutableFloatStateOf(1f) }
    var flash by remember { mutableStateOf(false) }
    val activity = ctx as? android.app.Activity
    // вспышка: у задней камеры — фонарик, у передней — белый экран на полной яркости
    LaunchedEffect(flash, front, camera) {
        runCatching { camera?.cameraControl?.enableTorch(flash && !front) }
        activity?.window?.let { w -> val a = w.attributes; a.screenBrightness = if (flash && front) 1f else -1f; w.attributes = a }
    }
    DisposableEffect(Unit) { onDispose { activity?.window?.let { w -> val a = w.attributes; a.screenBrightness = -1f; w.attributes = a } } }
    val maxZoom = camera?.cameraInfo?.zoomState?.value?.maxZoomRatio?.coerceAtMost(8f) ?: 1f
    fun setZoom(z: Float) { zoom = z.coerceIn(1f, maxOf(1f, maxZoom)); runCatching { camera?.cameraControl?.setZoomRatio(zoom) } }
    val previewView = remember { PreviewView(ctx).apply { scaleType = PreviewView.ScaleType.FILL_CENTER; implementationMode = PreviewView.ImplementationMode.COMPATIBLE } }
    val grow by animateFloatAsState(if (capture != null) 1f else 0.6f, tween(350), label = "g")
    BackHandler { recording?.stop(); send = false; onClose() }

    fun startRecording(vc: VideoCapture<Recorder>) {
        val my = ++gen
        val file = File(ctx.cacheDir, "note-${System.currentTimeMillis()}.mp4")
        val startAt = System.currentTimeMillis()
        recording = vc.output.prepareRecording(ctx, FileOutputOptions.Builder(file).build())
            .withAudioEnabled()
            .start(ContextCompat.getMainExecutor(ctx)) { e ->
                if (e is VideoRecordEvent.Finalize) {
                    if (my != gen) { file.delete(); return@start }
                    val dur = (System.currentTimeMillis() - startAt) / 1000.0
                    if (send && file.length() > 0 && dur >= 1) {
                        AppModel.sendMedia(chatId, "video_note", file.readBytes(), "mp4", "video/mp4",
                            jsonOf("dur" to maxOf(1, Math.round(dur).toInt()), "size" to file.length()), replyTo = replyTo(), local = file.absolutePath)
                    }
                    onClose()
                }
            }
    }

    // камера: при перевороте пересоздаём и продолжаем запись заново
    LaunchedEffect(front) {
        val providerF = ProcessCameraProvider.getInstance(ctx)
        val provider = runCatching { providerF.get() }.getOrNull() ?: run { AppModel.say("Камера недоступна"); onClose(); return@LaunchedEffect }
        recording?.let { r -> gen++; send = false; r.stop() }
        val preview = Preview.Builder().build().also { it.setSurfaceProvider(previewView.surfaceProvider) }
        val recorder = Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.SD, androidx.camera.video.FallbackStrategy.lowerQualityOrHigherThan(Quality.SD))).build()
        val vc = VideoCapture.withOutput(recorder)
        try {
            provider.unbindAll()
            camera = provider.bindToLifecycle(owner, if (front) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA, preview, vc)
            zoom = 1f
            capture = vc
            sec = 0f
            startRecording(vc)
        } catch (e: Exception) { AppModel.say("Не удалось включить камеру"); onClose() }
    }
    LaunchedEffect(recording) {
        val r = recording ?: return@LaunchedEffect
        val t0 = System.currentTimeMillis()
        while (recording === r) {
            sec = (System.currentTimeMillis() - t0) / 1000f
            if (sec >= 60f) { send = true; r.stop(); break }
            delay(50)
        }
    }
    LaunchedEffect(session.command) {
        when (session.command) {
            "send" -> { send = true; if (sec < 1f) { AppModel.say("Слишком коротко"); send = false }; recording?.stop() ?: onClose() }
            "cancel" -> { send = false; recording?.stop() ?: onClose() }
        }
    }
    DisposableEffect(Unit) {
        onDispose {
            runCatching { recording?.stop() }
            runCatching { ProcessCameraProvider.getInstance(ctx).get().unbindAll() }
        }
    }

    val white by androidx.compose.animation.animateColorAsState(if (flash && front) Color.White else Color.Black.copy(alpha = 0.82f), label = "fl")
    val fg = if (flash && front) Color.Black else Color.White
    Box(Modifier.fillMaxSize().background(white).clickable(remember { MutableInteractionSource() }, null) {}, contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(290.dp).scale(grow).pointerInput(Unit) {
                detectTransformGestures { _, _, z, _ -> setZoom(zoom * z) }
            }.pointerInput(Unit) { detectTapGestures(onDoubleTap = { setZoom(if (zoom > 1.5f) 1f else 2f) }) }, contentAlignment = Alignment.Center) {
                AndroidView({ previewView }, Modifier.size(280.dp).clip(CircleShape))
                Canvas(Modifier.fillMaxSize()) {
                    drawCircle(Color.White.copy(alpha = 0.15f), style = Stroke(5.dp.toPx()))
                    drawArc(p.a1, -90f, 360f * (sec / 60f), false, style = Stroke(5.dp.toPx(), cap = StrokeCap.Round))
                }
            }
            Spacer(Modifier.height(12.dp))
            // приближение: щипок по кружку, двойное касание или кнопки
            Row(Modifier.clip(RoundedCornerShape(20.dp)).background(Color.Gray.copy(alpha = 0.35f)).padding(4.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                listOf(1f, 2f, 3f).filter { it <= maxOf(1f, maxZoom) }.forEach { z ->
                    val on = kotlin.math.abs(zoom - z) < 0.25f
                    Box(Modifier.size(40.dp).clip(CircleShape).background(if (on) Color.White else Color.Transparent).clickable { setZoom(z) }, contentAlignment = Alignment.Center) {
                        Text(if (on || z == 1f) String.format(java.util.Locale.US, "%.1f×", if (on) zoom else z).replace(".0×", "×") else "${z.toInt()}×",
                            color = if (on) Color.Black else Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                }
            }
            Spacer(Modifier.height(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(10.dp).clip(CircleShape).background(Color(0xFFFF3B5C)))
                Spacer(Modifier.width(8.dp))
                Text(Fmt.duration(sec.toDouble()), color = fg, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Spacer(Modifier.width(16.dp))
                Box(Modifier.size(40.dp).clip(CircleShape).background(if (flash) Color(0xFFFFD84A) else Color.Gray.copy(alpha = 0.35f)).bouncy { flash = !flash },
                    contentAlignment = Alignment.Center) {
                    Icon(if (flash) Icons.Filled.FlashOn else Icons.Filled.FlashOff, null, tint = if (flash) Color.Black else Color.White, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(Modifier.height(28.dp))
            if (!session.locked) Text("Отпустите — отправить · влево — отмена · вверх — без удержания", color = fg.copy(alpha = 0.8f), fontSize = 14.sp,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center, modifier = Modifier.padding(horizontal = 30.dp))
            else Row(horizontalArrangement = Arrangement.spacedBy(28.dp), verticalAlignment = Alignment.CenterVertically) {
                RoundIcon(Icons.Filled.Delete, 56.dp, tint = Color.White, bg = Color.White.copy(alpha = 0.18f)) { send = false; recording?.stop() ?: onClose() }
                Box(Modifier.size(72.dp).clip(CircleShape).background(p.accent).bouncy {
                    send = true
                    if (sec < 1f) { AppModel.say("Слишком коротко"); return@bouncy }
                    recording?.stop()
                }, contentAlignment = Alignment.Center) { Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White, modifier = Modifier.size(32.dp)) }
                RoundIcon(Icons.Filled.Cameraswitch, 56.dp, tint = Color.White, bg = Color.White.copy(alpha = 0.18f)) { front = !front }
            }
        }
    }
}
