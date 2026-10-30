package ru.volshebnymir.lumo.ui

import android.graphics.Bitmap
import android.graphics.Color as AColor
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.ui.geometry.Offset
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import coil.compose.AsyncImage
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.EncodeHintType
import com.google.zxing.PlanarYUVLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.google.zxing.qrcode.QRCodeWriter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.StoryItem
import ru.volshebnymir.lumo.core.jsonOf
import java.util.concurrent.Executors

/** Окна поверх всего приложения: истории, QR-коды */
object Ui {
    var storyUser by mutableStateOf<String?>(null)
    var addStory by mutableStateOf(false)
    var qrMine by mutableStateOf(false)
    var qrScan by mutableStateOf(false)

    @Composable
    fun Overlays() {
        storyUser?.let { StoryViewer(it) { storyUser = null } }
        if (addStory) AddStoryScreen { addStory = false }
        androidx.compose.animation.AnimatedVisibility(qrMine, enter = androidx.compose.animation.fadeIn(androidx.compose.animation.core.tween(380)) + androidx.compose.animation.scaleIn(androidx.compose.animation.core.tween(420), initialScale = 0.88f), exit = androidx.compose.animation.fadeOut(androidx.compose.animation.core.tween(220)) + androidx.compose.animation.scaleOut(androidx.compose.animation.core.tween(220), targetScale = 0.92f)) { MyQRScreen { qrMine = false } }
        if (qrScan) QRScanScreen { qrScan = false }
        AppModel.miniApp?.let { MiniAppScreen(it) { AppModel.miniApp = null } }
    }
}

// ---------------- истории ----------------

@Composable
private fun Ring(unseen: Boolean, mine: Boolean, content: @Composable () -> Unit) {
    val p = P
    val b = when {
        mine -> Brush.sweepGradient(listOf(p.a1, p.a2, p.a1))
        unseen -> Brush.sweepGradient(listOf(Color(0xFFFF9F1A), Color(0xFFFF3B8A), p.a1, p.a2, Color(0xFFFF9F1A)))
        else -> SolidColor(p.line)
    }
    Box(Modifier.border(3.dp, b, CircleShape).padding(5.dp)) { content() }
}

@Composable
fun StoriesBar() {
    val p = P
    val me = AppModel.me
    val mine = AppModel.stories.firstOrNull { it.userId == AppModel.myId }
    val others = AppModel.stories.filter { it.userId != AppModel.myId }
    Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(Modifier.width(78.dp).bouncy { if (mine != null) Ui.storyUser = AppModel.myId else Ui.addStory = true }, horizontalAlignment = Alignment.CenterHorizontally) {
            Box {
                if (mine != null) Ring(false, true) { Avatar(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, 54.dp) }
                else Box(Modifier.padding(8.dp)) { Avatar(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, 54.dp) }
                Box(Modifier.align(Alignment.BottomEnd).size(22.dp).clip(CircleShape).background(p.bg).padding(2.dp).clip(CircleShape).background(p.a1)
                    .bouncy { Ui.addStory = true }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Add, null, tint = Color.White, modifier = Modifier.size(14.dp))
                }
            }
            Text("Моя история", color = p.text, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, softWrap = false)
        }
        others.forEach { g ->
            Column(Modifier.width(72.dp).bouncy { Ui.storyUser = g.userId }, horizontalAlignment = Alignment.CenterHorizontally) {
                Ring(g.unseen, false) { Avatar(g.name, g.avatarUrl, g.color, 54.dp) }
                Text(g.name.split(" ").first(), color = p.text, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

@Composable
fun StoryViewer(startUser: String, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val groups = AppModel.stories.toList()
    var gi by remember { mutableIntStateOf(groups.indexOfFirst { it.userId == startUser }.coerceAtLeast(0)) }
    var ii by remember { mutableIntStateOf(0) }
    var progress by remember { mutableFloatStateOf(0f) }
    var paused by remember { mutableStateOf(false) }
    var reply by remember { mutableStateOf("") }
    var viewers by remember { mutableStateOf<List<JSONObject>?>(null) }
    var confirmDelete by remember { mutableStateOf(false) }
    BackHandler { onClose() }
    if (groups.isEmpty()) { LaunchedEffect(Unit) { onClose() }; return }
    val g = groups.getOrNull(gi) ?: run { LaunchedEffect(Unit) { onClose() }; return }
    // начинаем с первой непросмотренной
    LaunchedEffect(gi) { ii = g.items.indexOfFirst { !it.seen && g.userId != AppModel.myId }.takeIf { it >= 0 } ?: 0 }
    val s = g.items.getOrNull(ii) ?: g.items.first()
    val mine = g.userId == AppModel.myId
    fun next() {
        if (ii < g.items.size - 1) ii++ else if (gi < groups.size - 1) { gi++ } else onClose()
        progress = 0f
    }
    fun prev() { if (ii > 0) ii-- else if (gi > 0) gi--; progress = 0f }
    var videoDur by remember(s.id) { mutableLongStateOf(0L) }
    LaunchedEffect(s.id) { AppModel.viewStory(s); progress = 0f }
    LaunchedEffect(s.id, paused, videoDur, viewers, confirmDelete) {
        val total = if (s.kind == "video") (if (videoDur > 0) videoDur else 15_000L) else 6_000L
        while (progress < 1f) {
            delay(50)
            if (!paused && viewers == null && !confirmDelete) progress += 50f / total
        }
        next()
    }
    var dragY by remember { mutableFloatStateOf(0f) }
    val dy by androidx.compose.animation.core.animateFloatAsState(dragY, label = "dy")
    Box(Modifier.fillMaxSize().graphicsLayer { translationY = dy; val k = 1f - (dy / 2500f).coerceIn(0f, 0.15f); scaleX = k; scaleY = k }
        .background(Color.Black).clickable(remember { MutableInteractionSource() }, null) {}
        .pointerInput(Unit) {
            // смахнуть вниз — закрыть
            detectVerticalDragGestures(
                onDragEnd = { if (dragY > 220f) onClose() else { dragY = 0f; paused = false } },
                onDragCancel = { dragY = 0f; paused = false },
            ) { _, d -> dragY = (dragY + d).coerceAtLeast(0f); paused = true }
        }) {
        Box(Modifier.fillMaxSize().pointerInput(s.id) {
            detectTapGestures(
                onPress = { paused = true; tryAwaitRelease(); paused = false },
                onTap = { o -> if (o.x < size.width / 3) prev() else next() },
            )
        }) {
            if (s.kind == "video") {
                val player = remember(s.id) {
                    ExoPlayer.Builder(ctx).build().apply {
                        setMediaItem(MediaItem.fromUri(ru.volshebnymir.lumo.core.Net.px(s.mediaUrl) ?: s.mediaUrl)); prepare(); playWhenReady = true
                        addListener(object : Player.Listener {
                            override fun onPlaybackStateChanged(st: Int) { if (st == Player.STATE_READY && duration > 0) videoDur = duration }
                        })
                    }
                }
                LaunchedEffect(paused) { player.playWhenReady = !paused }
                DisposableEffect(s.id) { onDispose { player.release() } }
                AndroidView({ PlayerView(it).apply { useController = false; this.player = player } }, Modifier.fillMaxSize())
            } else AsyncImage(s.mediaUrl, null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
        }
        Column(Modifier.statusBarsPadding().padding(horizontal = 10.dp, vertical = 6.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                g.items.forEachIndexed { i, _ ->
                    val f = if (i < ii) 1f else if (i == ii) progress.coerceIn(0f, 1f) else 0f
                    Box(Modifier.weight(1f).height(3.dp).clip(RoundedCornerShape(2.dp)).background(Color.White.copy(alpha = 0.3f))) {
                        Box(Modifier.fillMaxHeight().fillMaxWidth(f).background(Color.White))
                    }
                }
            }
            Row(Modifier.padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Avatar(g.name, g.avatarUrl, g.color, 36.dp)
                Spacer(Modifier.width(8.dp))
                Column(Modifier.weight(1f)) {
                    Text(if (mine) "Моя история" else g.name, color = Color.White, fontWeight = FontWeight.Bold)
                    Text(Fmt.listTime(s.createdAt), color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp)
                }
                RoundIcon(Icons.Filled.Close, tint = Color.White) { onClose() }
            }
        }
        Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().imePadding().padding(12.dp)) {
            if (s.caption.isNotEmpty()) Text(s.caption, color = Color.White, fontSize = 16.sp, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color.Black.copy(alpha = 0.45f)).padding(10.dp))
            Spacer(Modifier.height(10.dp))
            if (mine) Row(verticalAlignment = Alignment.CenterVertically) {
                Row(Modifier.clip(RoundedCornerShape(20.dp)).background(Color.White.copy(alpha = 0.15f)).bouncy {
                    scope.launch { viewers = AppModel.storyViewers(s) }
                }.padding(horizontal = 14.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Visibility, null, tint = Color.White, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("${s.views} просмотров", color = Color.White, fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.weight(1f))
                RoundIcon(Icons.Filled.Delete, tint = Color.White, bg = Color.White.copy(alpha = 0.15f)) { confirmDelete = true }
            } else Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f).clip(RoundedCornerShape(22.dp)).border(1.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(22.dp)).padding(horizontal = 14.dp, vertical = 12.dp)) {
                    if (reply.isEmpty()) Text("Ответить…", color = Color.White.copy(alpha = 0.6f))
                    BasicTextField(reply, { reply = it; paused = it.isNotEmpty() }, textStyle = TextStyle(color = Color.White, fontSize = 16.sp), cursorBrush = SolidColor(Color.White), modifier = Modifier.fillMaxWidth())
                }
                Spacer(Modifier.width(8.dp))
                if (reply.isNotBlank()) RoundIcon(Icons.AutoMirrored.Filled.Send, tint = Color.White, bg = p.a1) {
                    val t = reply.trim(); reply = ""; paused = false; scope.launch { AppModel.replyStory(s, t) }
                } else RoundIcon(Icons.Filled.Favorite, tint = Color(0xFFFF3B5C)) { scope.launch { AppModel.reactStory(s) } }
            }
        }
    }
    viewers?.let { list ->
        AlertDialog(onDismissRequest = { viewers = null }, title = { Text("Просмотры") }, confirmButton = { TextButton({ viewers = null }) { Text("Закрыть") } },
            text = {
                Column(Modifier.heightIn(max = 400.dp).verticalScroll(rememberScrollState())) {
                    if (list.isEmpty()) Text("Пока никто не посмотрел")
                    list.forEach { v ->
                        Row(Modifier.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Avatar(v.optString("name"), v.optString("avatar_url").ifEmpty { null }, v.optInt("color"), 40.dp)
                            Spacer(Modifier.width(10.dp))
                            Text(v.optString("name"), fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            if (!v.isNull("reaction") && v.optString("reaction").isNotEmpty()) Text(v.optString("reaction"), fontSize = 20.sp)
                        }
                    }
                }
            })
    }
    if (confirmDelete) AlertDialog(onDismissRequest = { confirmDelete = false }, title = { Text("Удалить историю?") },
        confirmButton = { TextButton({ confirmDelete = false; scope.launch { AppModel.deleteStory(s); if (AppModel.stories.none { it.userId == AppModel.myId }) onClose() } }) { Text("Удалить", color = p.danger) } },
        dismissButton = { TextButton({ confirmDelete = false }) { Text("Отмена") } })
}

@Composable
fun AddStoryScreen(onClose: () -> Unit) {
    var uri by remember { mutableStateOf<android.net.Uri?>(null) }
    var isVideo by remember { mutableStateOf(false) }
    val u = uri
    if (u == null) StoryCamera(onClose) { x, v -> uri = x; isVideo = v }
    else StoryEdit(u, isVideo, onClose) { uri = null }
}

/** Камера для историй: сетка, вспышка, переключение ФОТО/ВИДЕО, галерея слева, переворот справа */
@android.annotation.SuppressLint("MissingPermission")
@Composable
private fun StoryCamera(onClose: () -> Unit, onPicked: (android.net.Uri, Boolean) -> Unit) {
    val ctx = LocalContext.current
    val owner = androidx.compose.ui.platform.LocalLifecycleOwner.current
    var granted by remember { mutableStateOf(androidx.core.content.ContextCompat.checkSelfPermission(ctx, android.Manifest.permission.CAMERA) == android.content.pm.PackageManager.PERMISSION_GRANTED) }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r -> granted = r[android.Manifest.permission.CAMERA] == true }
    LaunchedEffect(Unit) { if (!granted) perm.launch(arrayOf(android.Manifest.permission.CAMERA, android.Manifest.permission.RECORD_AUDIO)) }
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u ->
        if (u != null) onPicked(u, ctx.contentResolver.getType(u)?.startsWith("video") == true)
    }
    var front by remember { mutableStateOf(false) }
    var video by remember { mutableStateOf(false) }
    var grid by remember { mutableStateOf(false) }
    var flash by remember { mutableStateOf(false) }
    var camera by remember { mutableStateOf<androidx.camera.core.Camera?>(null) }
    var imageCap by remember { mutableStateOf<androidx.camera.core.ImageCapture?>(null) }
    var videoCap by remember { mutableStateOf<androidx.camera.video.VideoCapture<androidx.camera.video.Recorder>?>(null) }
    var rec by remember { mutableStateOf<androidx.camera.video.Recording?>(null) }
    var sec by remember { mutableStateOf(0) }
    val previewView = remember { androidx.camera.view.PreviewView(ctx).apply { scaleType = androidx.camera.view.PreviewView.ScaleType.FILL_CENTER; implementationMode = androidx.camera.view.PreviewView.ImplementationMode.COMPATIBLE } }
    BackHandler { rec?.stop(); onClose() }
    LaunchedEffect(front, granted) {
        if (!granted) return@LaunchedEffect
        val provider = runCatching { androidx.camera.lifecycle.ProcessCameraProvider.getInstance(ctx).get() }.getOrNull() ?: run { AppModel.say("Камера недоступна"); return@LaunchedEffect }
        val preview = androidx.camera.core.Preview.Builder().build().also { it.setSurfaceProvider(previewView.surfaceProvider) }
        val ic = androidx.camera.core.ImageCapture.Builder().setCaptureMode(androidx.camera.core.ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY).build()
        val recorder = androidx.camera.video.Recorder.Builder().setQualitySelector(androidx.camera.video.QualitySelector.from(androidx.camera.video.Quality.HD, androidx.camera.video.FallbackStrategy.lowerQualityOrHigherThan(androidx.camera.video.Quality.SD))).build()
        val vc = androidx.camera.video.VideoCapture.withOutput(recorder)
        runCatching {
            provider.unbindAll()
            camera = provider.bindToLifecycle(owner, if (front) androidx.camera.core.CameraSelector.DEFAULT_FRONT_CAMERA else androidx.camera.core.CameraSelector.DEFAULT_BACK_CAMERA, preview, ic, vc)
            imageCap = ic; videoCap = vc
        }.onFailure { AppModel.say("Не удалось включить камеру") }
    }
    LaunchedEffect(flash, camera, front) {
        runCatching { camera?.cameraControl?.enableTorch(flash && video && !front) }
        imageCap?.flashMode = if (flash) androidx.camera.core.ImageCapture.FLASH_MODE_ON else androidx.camera.core.ImageCapture.FLASH_MODE_OFF
    }
    LaunchedEffect(rec) { val r = rec ?: return@LaunchedEffect; sec = 0; while (rec === r) { delay(1000); sec++; if (sec >= 60) r.stop() } }
    DisposableEffect(Unit) { onDispose { runCatching { rec?.stop() } } }

    fun shoot() {
        if (!video) {
            val ic = imageCap ?: return
            val f = java.io.File(ctx.cacheDir, "story-${System.currentTimeMillis()}.jpg")
            ic.takePicture(androidx.camera.core.ImageCapture.OutputFileOptions.Builder(f).build(), androidx.core.content.ContextCompat.getMainExecutor(ctx),
                object : androidx.camera.core.ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(r: androidx.camera.core.ImageCapture.OutputFileResults) { onPicked(android.net.Uri.fromFile(f), false) }
                    override fun onError(e: androidx.camera.core.ImageCaptureException) { AppModel.say("Не удалось сделать снимок") }
                })
        } else {
            val cur = rec
            if (cur != null) { cur.stop(); return }
            val vc = videoCap ?: return
            val f = java.io.File(ctx.cacheDir, "story-${System.currentTimeMillis()}.mp4")
            rec = vc.output.prepareRecording(ctx, androidx.camera.video.FileOutputOptions.Builder(f).build()).withAudioEnabled()
                .start(androidx.core.content.ContextCompat.getMainExecutor(ctx)) { e ->
                    if (e is androidx.camera.video.VideoRecordEvent.Finalize) { rec = null; if (f.length() > 0) onPicked(android.net.Uri.fromFile(f), true) }
                }
        }
    }

    Box(Modifier.fillMaxSize().background(Color.Black).clickable(remember { MutableInteractionSource() }, null) {}) {
        Box(Modifier.fillMaxSize().statusBarsPadding().padding(bottom = 150.dp).clip(RoundedCornerShape(28.dp)).background(Color(0xFF1B1B1F))) {
            if (granted) androidx.compose.ui.viewinterop.AndroidView({ previewView }, Modifier.fillMaxSize())
            else Column(Modifier.align(Alignment.Center).padding(30.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Нужен доступ к камере", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                Text("Или выберите фото из галереи", color = Color.White.copy(alpha = 0.7f), fontSize = 14.sp)
            }
            if (grid) Canvas(Modifier.fillMaxSize()) {
                val c = Color.White.copy(alpha = 0.45f)
                for (i in 1..2) {
                    drawLine(c, Offset(size.width * i / 3f, 0f), Offset(size.width * i / 3f, size.height), 1.5f)
                    drawLine(c, Offset(0f, size.height * i / 3f), Offset(size.width, size.height * i / 3f), 1.5f)
                }
            }
            Row(Modifier.align(Alignment.TopEnd).padding(10.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                RoundIcon(Icons.Filled.GridOn, tint = Color.White, bg = if (grid) Color.White.copy(alpha = 0.35f) else Color.Black.copy(alpha = 0.3f)) { grid = !grid }
                RoundIcon(if (flash) Icons.Filled.FlashOn else Icons.Filled.FlashOff, tint = Color.White, bg = if (flash) Color.White.copy(alpha = 0.35f) else Color.Black.copy(alpha = 0.3f)) { flash = !flash }
                RoundIcon(Icons.Filled.Close, tint = Color.White, bg = Color.Black.copy(alpha = 0.3f)) { rec?.stop(); onClose() }
            }
            if (rec != null) Text("%d:%02d".format(sec / 60, sec % 60), color = Color.White, fontWeight = FontWeight.Bold, fontSize = 16.sp,
                modifier = Modifier.align(Alignment.TopStart).padding(16.dp).clip(RoundedCornerShape(10.dp)).background(Color(0xFFFF3B30)).padding(horizontal = 10.dp, vertical = 3.dp))
        }
        Column(Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(78.dp).clip(CircleShape).border(4.dp, Color.White.copy(alpha = 0.55f), CircleShape).padding(6.dp).clip(CircleShape)
                .background(if (video) Color(0xFFFF3B30) else Color.White).bouncy { shoot() }, contentAlignment = Alignment.Center) {
                if (rec != null) Box(Modifier.size(24.dp).clip(RoundedCornerShape(5.dp)).background(Color.White))
            }
            Spacer(Modifier.height(14.dp))
            Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                Box(Modifier.size(54.dp).clip(RoundedCornerShape(14.dp)).background(Color.White.copy(alpha = 0.18f))
                    .bouncy { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageAndVideo)) }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.PhotoLibrary, null, tint = Color.White, modifier = Modifier.size(26.dp))
                }
                Row(Modifier.clip(RoundedCornerShape(28.dp)).background(Color.White.copy(alpha = 0.16f)).padding(4.dp)) {
                    listOf(true to "ВИДЕО", false to "ФОТО").forEach { (v, t) ->
                        Text(t, color = if (video == v) Color(0xFFFFD60A) else Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp,
                            modifier = Modifier.clip(RoundedCornerShape(24.dp)).background(if (video == v) Color.White.copy(alpha = 0.18f) else Color.Transparent)
                                .bouncy { if (rec == null) video = v }.padding(horizontal = 22.dp, vertical = 12.dp))
                    }
                }
                Box(Modifier.size(54.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.18f)).bouncy { if (rec == null) front = !front }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Cameraswitch, null, tint = Color.White, modifier = Modifier.size(26.dp))
                }
            }
        }
    }
}

@Composable
private fun StoryEdit(first: android.net.Uri, firstVideo: Boolean, onClose: () -> Unit, onRetake: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var uri by remember { mutableStateOf<android.net.Uri?>(first) }
    var isVideo by remember { mutableStateOf(firstVideo) }
    var caption by remember { mutableStateOf("") }
    var hours by remember { mutableStateOf(24) }
    var aud by remember { mutableStateOf("all") }
    var allow by remember { mutableStateOf(listOf<String>()) }
    var busy by remember { mutableStateOf(false) }
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u ->
        if (u != null) { uri = u; isVideo = ctx.contentResolver.getType(u)?.startsWith("video") == true }
    }
    BackHandler { onRetake() }
    Column(Modifier.fillMaxSize().background(p.bg).clickable(remember { MutableInteractionSource() }, null) {}.statusBarsPadding().navigationBarsPadding().imePadding()) {
        Row(Modifier.fillMaxWidth().padding(6.dp), verticalAlignment = Alignment.CenterVertically) {
            RoundIcon(Icons.Filled.Close) { onRetake() }
            Text("Новая история", color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp)
        }
        Box(Modifier.weight(1f).fillMaxWidth().padding(14.dp).clip(RoundedCornerShape(22.dp)).background(p.panel2)
            .bouncy { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageAndVideo)) }, contentAlignment = Alignment.Center) {
            val u = uri
            if (u == null) Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Filled.AddPhotoAlternate, null, tint = p.muted, modifier = Modifier.size(48.dp))
                Text("Выбрать фото или видео", color = p.muted)
            } else AsyncImage(u, null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
            if (isVideo) Icon(Icons.Filled.PlayCircle, null, tint = Color.White, modifier = Modifier.size(56.dp))
        }
        Column(Modifier.padding(horizontal = 14.dp)) {
            LumoField(caption, { caption = it.take(200) }, "Подпись (необязательно)")
            Spacer(Modifier.height(6.dp))
            StoryHoursPicker(hours) { hours = it }
            Spacer(Modifier.height(6.dp))
            StoryAudiencePicker(aud, allow, { aud = it }, { allow = it })
            Spacer(Modifier.height(10.dp))
            GradientButton("Опубликовать", busy, enabled = uri != null) {
                val u = uri ?: return@GradientButton
                busy = true
                scope.launch {
                    val ok = withContext(Dispatchers.IO) {
                        val raw = MediaUtil.read(ctx, u) ?: return@withContext null
                        if (isVideo) {
                            val type = ctx.contentResolver.getType(u) ?: "video/mp4"
                            Triple(raw, android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(type) ?: "mp4", type) to JSONObject()
                        } else MediaUtil.jpeg(raw)?.let { Triple(it.first, "jpg", "image/jpeg") to jsonOf("w" to it.second, "h" to it.third) }
                    }
                    if (ok == null) { AppModel.say("Не удалось открыть файл"); busy = false; return@launch }
                    if (ok.first.first.size > 50 * 1024 * 1024) { AppModel.say("Файл больше 50 МБ"); busy = false; return@launch }
                    val done = AppModel.addStory(if (isVideo) "video" else "image", ok.first.first, ok.first.second, ok.first.third, caption.trim(), ok.second, hours, aud, allow)
                    busy = false
                    if (done) onClose()
                }
            }
            Spacer(Modifier.height(14.dp))
        }
    }
}

// ---------------- QR-коды ----------------

fun qrBitmap(text: String, size: Int = 720): Bitmap {
    val m = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size, mapOf(EncodeHintType.MARGIN to 1))
    val px = IntArray(size * size) { i -> if (m.get(i % size, i / size)) AColor.BLACK else AColor.WHITE }
    return Bitmap.createBitmap(px, size, size, Bitmap.Config.ARGB_8888)
}

@Composable
fun MyQRScreen(onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val me = AppModel.me
    val link = AppModel.profileLink
    val bmp = remember(link) { qrBitmap(link) }
    BackHandler { onClose() }
    Box(Modifier.fillMaxSize().background(Brush.linearGradient(listOf(p.a1, p.a2))).clickable(remember { MutableInteractionSource() }, null) {}) {
        RoundIcon(Icons.Filled.Close, tint = Color.White, bg = Color.Black.copy(alpha = 0.2f), modifier = Modifier.statusBarsPadding().padding(10.dp)) { onClose() }
        Column(Modifier.align(Alignment.Center).padding(30.dp).clip(RoundedCornerShape(28.dp)).background(Color.White).padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Avatar(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, 64.dp)
            Spacer(Modifier.height(8.dp))
            Text("@" + (me?.username ?: ""), color = Color(0xFF14163A), fontWeight = FontWeight.Black, fontSize = 20.sp)
            Spacer(Modifier.height(12.dp))
            Image(bmp.asImageBitmap(), null, Modifier.size(240.dp))
            Spacer(Modifier.height(10.dp))
            Text("Покажите код, чтобы открыть мой профиль. Кнопка «Сканировать» — открыть чужой профиль или войти на компьютере", color = Color(0xFF7276A0), fontSize = 13.sp, textAlign = TextAlign.Center)
        }
        Row(Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(24.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Pill("Поделиться ссылкой", true) {
                runCatching { ctx.startActivity(android.content.Intent.createChooser(android.content.Intent(android.content.Intent.ACTION_SEND).setType("text/plain")
                    .putExtra(android.content.Intent.EXTRA_TEXT, "Я в Lumo — напиши мне: $link"), "Поделиться").addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)) }
            }
            Pill("Сканировать", true) { onClose(); Ui.qrScan = true }
        }
    }
}

@Composable
fun QRScanScreen(onClose: () -> Unit) {
    val ctx = LocalContext.current
    val owner = LocalLifecycleOwner.current
    val scope = rememberCoroutineScope()
    var granted by remember { mutableStateOf(ContextCompat.checkSelfPermission(ctx, android.Manifest.permission.CAMERA) == android.content.pm.PackageManager.PERMISSION_GRANTED) }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted = it; if (!it) { AppModel.say("Нужен доступ к камере"); onClose() } }
    LaunchedEffect(Unit) { if (!granted) perm.launch(android.Manifest.permission.CAMERA) }
    var done by remember { mutableStateOf(false) }
    BackHandler { onClose() }
    fun handle(code: String) {
        if (done) return
        val login = Regex("lmqr=([A-Za-z0-9_-]{16,64})").find(code)?.groupValues?.get(1)
        val user = Regex("#@([A-Za-z0-9_]{3,32})").find(code)?.groupValues?.get(1)
        if (login == null && user == null) return
        done = true
        scope.launch {
            onClose()
            if (login != null) { AppModel.say("Входим на компьютере…"); AppModel.approveQR(login) } else if (user != null) AppModel.openByUsername(user)
        }
    }
    Box(Modifier.fillMaxSize().background(Color.Black).clickable(remember { MutableInteractionSource() }, null) {}) {
        if (granted) {
            val exec = remember { Executors.newSingleThreadExecutor() }
            val pv = remember { PreviewView(ctx) }
            AndroidView({ pv }, Modifier.fillMaxSize())
            DisposableEffect(Unit) {
                val f = ProcessCameraProvider.getInstance(ctx)
                f.addListener({
                    val provider = f.get()
                    val preview = Preview.Builder().build().also { it.setSurfaceProvider(pv.surfaceProvider) }
                    val reader = QRCodeReader()
                    val an = ImageAnalysis.Builder().setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
                    an.setAnalyzer(exec) { img ->
                        try {
                            val pl = img.planes[0]
                            val buf = pl.buffer
                            val bytes = ByteArray(buf.remaining()).also { buf.get(it) }
                            val src = PlanarYUVLuminanceSource(bytes, pl.rowStride, img.height, 0, 0, img.width, img.height, false)
                            val r = runCatching { reader.decode(BinaryBitmap(HybridBinarizer(src))) }.getOrNull()
                            if (r != null) scope.launch { handle(r.text) }
                        } finally { img.close() }
                    }
                    runCatching { provider.unbindAll(); provider.bindToLifecycle(owner, CameraSelector.DEFAULT_BACK_CAMERA, preview, an) }
                }, ContextCompat.getMainExecutor(ctx))
                onDispose { runCatching { f.get().unbindAll() }; exec.shutdown() }
            }
        }
        Box(Modifier.align(Alignment.Center).size(250.dp).border(3.dp, Color.White, RoundedCornerShape(28.dp)))
        Column(Modifier.statusBarsPadding().fillMaxWidth().padding(10.dp)) {
            RoundIcon(Icons.Filled.Close, tint = Color.White, bg = Color.Black.copy(alpha = 0.4f)) { onClose() }
        }
        Text("Наведите на QR-код профиля или на код входа на сайте Lumo (на компьютере)", color = Color.White, textAlign = TextAlign.Center, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(30.dp))
    }
}


/** Кто увидит историю: все, только контакты, выбранные люди или все, кроме выбранных */
@Composable
fun StoryAudiencePicker(aud: String, allow: List<String>, onAud: (String) -> Unit, onAllow: (List<String>) -> Unit) {
    val p = P
    var dlg by remember { mutableStateOf(false) }
    Text("Кто увидит историю", color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(top = 2.dp, bottom = 4.dp))
    Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        listOf("all" to "Все", "contacts" to "Контакты", "only" to "Выбранные", "except" to "Все, кроме…").forEach { (k, t) ->
            Pill(t, aud == k) { onAud(k); if ((k == "only" || k == "except")) dlg = true }
        }
    }
    val hint = when (aud) {
        "contacts" -> "Только люди из ваших контактов"
        "only" -> if (allow.isEmpty()) "Выберите, кто увидит историю" else "Увидят ${allow.size} чел. · нажмите, чтобы изменить"
        "except" -> if (allow.isEmpty()) "Выберите, от кого скрыть" else "Скрыто от ${allow.size} чел. · нажмите, чтобы изменить"
        else -> "Контакты и те, с кем у вас есть чат"
    }
    Text(hint, color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(top = 6.dp).clickable(enabled = aud == "only" || aud == "except") { dlg = true })
    if (dlg) {
        var sel by remember { mutableStateOf(allow.toSet()) }
        val people = AppModel.contacts.toList()
        AlertDialog(
            onDismissRequest = { dlg = false },
            containerColor = p.panel,
            title = { Text(if (aud == "only") "Кто увидит" else "Скрыть от", color = p.text) },
            text = {
                if (people.isEmpty()) Text("В контактах пока никого", color = p.muted)
                else LazyColumn(Modifier.heightIn(max = 380.dp)) {
                    items(people) { id ->
                        val pr = AppModel.profiles[id]
                        Row(Modifier.fillMaxWidth().bouncy { sel = if (id in sel) sel - id else sel + id }.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Avatar(AppModel.displayName(id), pr?.avatarUrl, pr?.color ?: 0, 38.dp)
                            Text(AppModel.displayName(id), color = p.text, modifier = Modifier.weight(1f).padding(start = 10.dp), maxLines = 1, overflow = TextOverflow.Ellipsis)
                            Checkbox(id in sel, { sel = if (id in sel) sel - id else sel + id })
                        }
                    }
                }
            },
            confirmButton = { TextButton({ onAllow(sel.toList()); dlg = false }) { Text("Готово", color = p.accent) } },
            dismissButton = { TextButton({ dlg = false }) { Text("Отмена", color = p.muted) } },
        )
    }
}
