package ru.volshebnymir.lumo.ui

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.OptIn
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import org.json.JSONObject
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.math.max
import kotlin.math.min

/** Фото профиля: сетка галереи (как при отправке) → выбор области → галочка. Видео — первые 10 секунд. */
@Composable
fun AvatarPickerDialog(onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var granted by remember { mutableStateOf(galPerms().any { ContextCompatCheck(ctx, it) }) }
    var gallery by remember { mutableStateOf<List<GalItem>>(emptyList()) }
    var crop by remember { mutableStateOf<Uri?>(null) }
    var busy by remember { mutableStateOf<String?>(null) }
    var askDelete by remember { mutableStateOf(false) }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r ->
        granted = r.values.any { it } || galPerms().any { ContextCompatCheck(ctx, it) }
    }
    val sys = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u -> if (u != null) crop = u }
    LaunchedEffect(Unit) { if (!granted) perm.launch(galPerms()) }
    LaunchedEffect(granted) { if (granted) gallery = withContext(Dispatchers.IO) { loadGallery(ctx) } }

    fun video(u: Uri) {
        busy = "Готовим видео…"
        scope.launch {
            val ok = runCatching { AvatarVideo.set(ctx, u) }.getOrElse { AppModel.say(it.message ?: "Ошибка"); false }
            busy = null
            if (ok) { AppModel.say("Видео-аватарка установлена"); onClose() }
        }
    }

    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(p.bg)) {
            Column(Modifier.fillMaxSize().statusBarsPadding()) {
                Box(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 6.dp)) {
                    Text("Отмена", color = p.a1, fontSize = 17.sp, modifier = Modifier.align(Alignment.CenterStart).clip(RoundedCornerShape(12.dp)).bouncy { onClose() }.padding(10.dp))
                    Text("Фото профиля", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.align(Alignment.Center))
                }
                if (!granted) {
                    Column(Modifier.fillMaxWidth().weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                        Icon(Icons.Filled.PhotoLibrary, null, tint = p.muted, modifier = Modifier.size(48.dp))
                        Text("Нет доступа к галерее", color = p.text, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 10.dp))
                        Text("Разрешить", color = p.a1, fontSize = 16.sp, modifier = Modifier.padding(top = 10.dp).bouncy { perm.launch(galPerms()) }.padding(8.dp))
                        Text("Выбрать из системной галереи", color = p.a1, fontSize = 16.sp, modifier = Modifier.bouncy {
                            sys.launch(androidx.activity.result.PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                        }.padding(8.dp))
                    }
                } else LazyVerticalGrid(GridCells.Fixed(3), Modifier.fillMaxWidth().weight(1f), horizontalArrangement = Arrangement.spacedBy(2.dp), verticalArrangement = Arrangement.spacedBy(2.dp),
                    contentPadding = PaddingValues(bottom = 100.dp)) {
                    items(gallery, key = { it.uri.toString() }) { g ->
                        Box(Modifier.aspectRatio(1f).clickable { if (g.video) video(g.uri) else crop = g.uri }) {
                            AsyncImage(g.uri, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                            if (g.video) Row(Modifier.align(Alignment.BottomStart).padding(5.dp).clip(RoundedCornerShape(10.dp)).background(Color.Black.copy(alpha = 0.45f)).padding(horizontal = 6.dp, vertical = 2.dp), verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.Videocam, null, tint = Color.White, modifier = Modifier.size(12.dp))
                                Text(" " + ru.volshebnymir.lumo.core.Fmt.duration(g.dur / 1000.0), color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }
                }
            }
            if (!AppModel.me?.avatarUrl.isNullOrEmpty()) Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().padding(14.dp)
                .clip(RoundedCornerShape(16.dp)).background(p.panel).bouncy { askDelete = true }.padding(vertical = 15.dp), contentAlignment = Alignment.Center) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Delete, null, tint = p.danger, modifier = Modifier.size(20.dp))
                    Text("  Удалить фотографию", color = p.danger, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                }
            }
            busy?.let { b ->
                Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.45f)).clickable(enabled = true) {}, contentAlignment = Alignment.Center) {
                    Column(Modifier.clip(RoundedCornerShape(18.dp)).background(p.panel).padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(color = p.a1)
                        Text(b, color = p.text, modifier = Modifier.padding(top = 12.dp))
                    }
                }
            }
        }
    }
    if (askDelete) androidx.compose.material3.AlertDialog(onDismissRequest = { askDelete = false },
        title = { Text("Удалить фото профиля?") },
        confirmButton = { androidx.compose.material3.TextButton({ askDelete = false; scope.launch { runCatching { AppModel.setAvatar(null) }; onClose() } }) { Text("Удалить", color = p.danger) } },
        dismissButton = { androidx.compose.material3.TextButton({ askDelete = false }) { Text("Отмена") } })
    crop?.let { u ->
        AvatarCropDialog(u, onCancel = { crop = null }) { bytes ->
            crop = null
            busy = "Сохраняем…"
            scope.launch {
                runCatching { AppModel.setAvatar(bytes) }.onSuccess { AppModel.say("Фото обновлено"); onClose() }.onFailure { AppModel.say(it.message ?: "Ошибка") }
                busy = null
            }
        }
    }
}

/** Выбор видимой области: двигаем и масштабируем, круг показывает, что попадёт в профиль */
@Composable
fun AvatarCropDialog(uri: Uri, onCancel: () -> Unit, onDone: (ByteArray) -> Unit) {
    val ctx = LocalContext.current
    var bmp by remember { mutableStateOf<Bitmap?>(null) }
    LaunchedEffect(uri) { bmp = withContext(Dispatchers.IO) { decode(ctx, uri, 2000) } }
    var box by remember { mutableStateOf(IntSize.Zero) }
    var scale by remember { mutableFloatStateOf(1f) }
    var off by remember { mutableStateOf(Offset.Zero) }
    val density = LocalDensity.current
    Dialog(onDismissRequest = onCancel, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black).onSizeChanged { box = it }) {
            val b = bmp
            val side = min(box.width, box.height) - with(density) { 40.dp.toPx() }
            if (b == null || side <= 0) CircularProgressIndicator(Modifier.align(Alignment.Center), color = Color.White)
            else {
                val base = max(side / b.width, side / b.height)
                fun clamp(o: Offset, s: Float): Offset {
                    val w = b.width * base * s; val h = b.height * base * s
                    val mx = max(0f, (w - side) / 2); val my = max(0f, (h - side) / 2)
                    return Offset(o.x.coerceIn(-mx, mx), o.y.coerceIn(-my, my))
                }
                Image(b.asImageBitmap(), null, contentScale = ContentScale.None, modifier = Modifier.fillMaxSize()
                    .pointerInputTransform { pan, zoom ->
                        val ns = (scale * zoom).coerceIn(1f, 5f)
                        scale = ns
                        off = clamp(off + pan, ns)
                    }
                    .graphicsLayer { val k = base * scale; scaleX = k; scaleY = k; translationX = off.x; translationY = off.y })
                // затемнение вокруг круга
                Canvas(Modifier.fillMaxSize().graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }) {
                    drawRect(Color.Black.copy(alpha = 0.55f))
                    drawCircle(Color.Transparent, side / 2, center, blendMode = BlendMode.Clear)
                    drawCircle(Color.White.copy(alpha = 0.9f), side / 2, center, style = Stroke(2.dp.toPx()))
                }
                Text("Двигайте и масштабируйте", color = Color.White.copy(alpha = 0.8f), fontSize = 13.sp,
                    modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 90.dp))
            }
            Row(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().padding(horizontal = 24.dp, vertical = 18.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Box(Modifier.size(56.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.15f)).bouncy { onCancel() }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Close, null, tint = Color.White, modifier = Modifier.size(28.dp))
                }
                Box(Modifier.size(56.dp).clip(CircleShape).background(P.a1).bouncy {
                    val bb = bmp ?: return@bouncy
                    val base = max(side / bb.width, side / bb.height)
                    val k = base * scale
                    // видимый квадрат в координатах картинки
                    val cx = bb.width / 2f - off.x / k
                    val cy = bb.height / 2f - off.y / k
                    val half = side / 2f / k
                    val l = (cx - half).toInt().coerceIn(0, bb.width - 1)
                    val t = (cy - half).toInt().coerceIn(0, bb.height - 1)
                    val s = (half * 2).toInt().coerceAtMost(min(bb.width - l, bb.height - t)).coerceAtLeast(1)
                    val out = Bitmap.createScaledBitmap(Bitmap.createBitmap(bb, l, t, s, s), min(s, 1024), min(s, 1024), true)
                    val bos = ByteArrayOutputStream(); out.compress(Bitmap.CompressFormat.JPEG, 90, bos)
                    onDone(bos.toByteArray())
                }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(30.dp))
                }
            }
        }
    }
}

private fun Modifier.pointerInputTransform(on: (Offset, Float) -> Unit): Modifier =
    this.then(Modifier.pointerInput(Unit) { detectTransformGestures { _, pan, zoom, _ -> on(pan, zoom) } })

/** Картинка с учётом поворота из EXIF, не больше maxSide по длинной стороне */
private fun decode(ctx: android.content.Context, uri: Uri, maxSide: Int): Bitmap? = runCatching {
    val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, o) }
    var sample = 1
    while (max(o.outWidth, o.outHeight) / sample > maxSide) sample *= 2
    val bm = ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample }) } ?: return null
    val rot = ctx.contentResolver.openInputStream(uri)?.use {
        when (android.media.ExifInterface(it).getAttributeInt(android.media.ExifInterface.TAG_ORIENTATION, 1)) {
            android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90
            android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180
            android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270
            else -> 0
        }
    } ?: 0
    if (rot == 0) bm else Bitmap.createBitmap(bm, 0, 0, bm.width, bm.height, android.graphics.Matrix().apply { postRotate(rot.toFloat()) }, true)
}.getOrNull()

/** Видео-аватарка: первые 10 секунд, квадрат 480×480, без звука; обложка — первый кадр */
@OptIn(UnstableApi::class)
object AvatarVideo {
    suspend fun set(ctx: android.content.Context, uri: Uri): Boolean {
        val dst = File(ctx.cacheDir, "va-${UUID.randomUUID()}.mp4")
        try {
            val ok = suspendCancellableCoroutine { cont ->
                Handler(Looper.getMainLooper()).post {
                    try {
                        val t = Transformer.Builder(ctx.applicationContext)
                            .addListener(object : Transformer.Listener {
                                override fun onCompleted(composition: Composition, exportResult: ExportResult) { if (cont.isActive) cont.resume(true) }
                                override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) { if (cont.isActive) cont.resume(false) }
                            }).build()
                        val mi = MediaItem.Builder().setUri(uri)
                            .setClippingConfiguration(MediaItem.ClippingConfiguration.Builder().setEndPositionMs(10_000).build()).build()
                        val item = EditedMediaItem.Builder(mi).setRemoveAudio(true)
                            .setEffects(Effects(emptyList(), listOf(Presentation.createForWidthAndHeight(480, 480, Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP)))).build()
                        t.start(item, dst.absolutePath)
                    } catch (_: Throwable) { if (cont.isActive) cont.resume(false) }
                }
            }
            if (!ok || dst.length() == 0L) throw Exception("Не удалось подготовить видео")
            val cover = withContext(Dispatchers.IO) {
                val r = MediaMetadataRetriever()
                try {
                    r.setDataSource(dst.absolutePath)
                    r.getFrameAtTime(0)?.let { f ->
                        val bos = ByteArrayOutputStream(); f.compress(Bitmap.CompressFormat.JPEG, 88, bos); bos.toByteArray()
                    }
                } finally { r.release() }
            }
            val coverUrl = cover?.let { Api.upload(it, "jpg", "image/jpeg") }
            val videoUrl = Api.upload(withContext(Dispatchers.IO) { dst.readBytes() }, "mp4", "video/mp4")
            val prm = JSONObject().put("p_video", videoUrl)
            if (coverUrl != null) prm.put("p_cover", coverUrl)
            Api.rpc("lm_set_avatar_video", prm)
            AppModel.loadMe()
            return true
        } finally { dst.delete() }
    }
}
