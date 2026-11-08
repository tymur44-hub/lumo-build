package ru.volshebnymir.lumo.ui

import android.media.MediaPlayer
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.isPremium
import ru.volshebnymir.lumo.core.date
import kotlin.math.cos
import kotlin.math.sin

// ---------------- оформление профиля (как в iOS) ----------------

object ProfileStyleKt {
    val colors: List<Pair<Long, Long>> = listOf(
        0xFF6F8CFF to 0xFF3D4FD8, 0xFFB06BFF to 0xFF6A2FD8, 0xFFFF6FAE to 0xFFD8336F, 0xFFFF8A4C to 0xFFE0442A,
        0xFFFFC24C to 0xFFE08A12, 0xFF4CD98A to 0xFF1F9E5C, 0xFF3CC6E0 to 0xFF1A7FA8, 0xFF7A8296 to 0xFF434A5E,
        0xFFFF5F6D to 0xFFC0263A, 0xFF9BE15D to 0xFF4CAF2E, 0xFF5EE7DF to 0xFF2A9D8F, 0xFF2B2D42 to 0xFF101120,
    )
    /** названия узоров общие с iOS (SF Symbols) → значки Material */
    val patterns: List<Pair<String, ImageVector>> = listOf(
        "star.fill" to Icons.Filled.Star, "heart.fill" to Icons.Filled.Favorite, "sparkles" to Icons.Filled.AutoAwesome,
        "moon.stars.fill" to Icons.Filled.NightsStay, "leaf.fill" to Icons.Filled.Eco, "bolt.fill" to Icons.Filled.Bolt,
        "music.note" to Icons.Filled.MusicNote, "pawprint.fill" to Icons.Filled.Pets, "snowflake" to Icons.Filled.AcUnit,
        "flame.fill" to Icons.Filled.LocalFireDepartment, "gamecontroller.fill" to Icons.Filled.SportsEsports, "crown.fill" to Icons.Filled.WorkspacePremium,
        "cloud.fill" to Icons.Filled.Cloud, "camera.fill" to Icons.Filled.PhotoCamera, "airplane" to Icons.Filled.Flight, "sun.max.fill" to Icons.Filled.WbSunny,
    )
    fun icon(name: String?): ImageVector = patterns.firstOrNull { it.first == name }?.second ?: Icons.Filled.Star
    fun brush(i: Int?): Brush? = i?.let { colors.getOrNull(it) }?.let { Brush.verticalGradient(listOf(Color(it.first), Color(it.second))) }

    private data class Dot(val dx: Float, val dy: Float, val size: Float, val alpha: Float)
    private val dots: List<Dot> = buildList {
        val counts = intArrayOf(7, 11, 15); val radii = floatArrayOf(92f, 140f, 190f); val sizes = floatArrayOf(22f, 19f, 16f)
        for (ring in 0..2) for (k in 0 until counts[ring]) {
            val a = k.toDouble() / counts[ring] * Math.PI * 2 + ring * 0.35
            add(Dot((cos(a) * radii[ring]).toFloat(), (sin(a) * radii[ring] * 0.82).toFloat(), sizes[ring], 0.42f - ring * 0.1f))
        }
    }

    /** Фон шапки: градиент, свечение за аватаром и узор кольцами, который медленно покачивается */
    @Composable
    fun Background(bg: Int?, pattern: String?, status: String?, centerY: Dp, modifier: Modifier = Modifier) {
        val p = P
        val tr = rememberInfiniteTransition(label = "pat")
        val k by tr.animateFloat(-1f, 1f, infiniteRepeatable(tween(7000, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "k")
        BoxWithConstraints(modifier) {
            val w = maxWidth
            brush(bg)?.let { b ->
                Box(Modifier.matchParentSize().background(b))
                Box(Modifier.offset(x = w / 2 - 210.dp, y = centerY - 210.dp).size(420.dp)
                    .background(Brush.radialGradient(listOf(Color.White.copy(alpha = 0.32f), Color.Transparent))))
            }
            if (!pattern.isNullOrEmpty()) {
                val useStatus = pattern == "@status" && !status.isNullOrEmpty()
                val tint = if (bg == null) p.a1 else Color.White
                val h = maxHeight
                Box(Modifier.matchParentSize().graphicsLayer {
                    rotationZ = 7f * k; val s = 1.01f + 0.04f * k; scaleX = s; scaleY = s
                    transformOrigin = TransformOrigin(0.5f, (centerY / h).coerceIn(0f, 1f))
                }) {
                    dots.forEach { d ->
                        val a = if (useStatus) d.alpha * 0.9f else if (bg == null) d.alpha * 0.6f else d.alpha * 0.8f
                        Box(Modifier.offset(x = w / 2 + d.dx.dp - (d.size / 2).dp, y = centerY + d.dy.dp - (d.size / 2).dp).size(d.size.dp).graphicsLayer { alpha = a },
                            contentAlignment = Alignment.Center) {
                            if (useStatus) StatusEmoji(status!!, (d.size * 0.8f).sp)
                            else Icon(icon(if (pattern == "@status") "star.fill" else pattern), null, tint = tint, modifier = Modifier.size((d.size * 0.8f).dp))
                        }
                    }
                }
            }
        }
    }
}

/** Кнопка-«стекло» в цветной шапке */
@Composable
fun GlassTile(icon: ImageVector, label: String, light: Boolean, modifier: Modifier = Modifier, danger: Boolean = false, onClick: () -> Unit) {
    val p = P
    val fg = if (light) Color.White else if (danger) p.danger else p.a1
    Column(modifier.clip(RoundedCornerShape(16.dp)).background(if (light) Color.White.copy(alpha = 0.18f) else p.panel)
        .border(0.7.dp, Color.White.copy(alpha = if (light) 0.22f else 0f), RoundedCornerShape(16.dp))
        .bouncy(onClick).padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, null, tint = fg, modifier = Modifier.size(24.dp))
        Spacer(Modifier.height(4.dp))
        Text(label, color = if (light) Color.White else p.text, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
    }
}

/**
 * Шапка профиля в стиле Telegram: цвет и узор, аватар, имя с эмодзи-статусом.
 * Нажатие на аватар раскрывает фото на всю ширину, повторное — открывает его целиком.
 */
@Composable
fun TgProfileHero(
    name: String, avatarUrl: String?, color: Int, status: String?, premiumStar: Boolean, verified: Boolean,
    subtitle: String, subtitleAccent: Boolean, bg: Int?, pattern: String?, storyUid: String?,
    onOpenPhoto: () -> Unit, onStatus: (() -> Unit)? = null,
    top: @Composable RowScope.(light: Boolean) -> Unit,
    bottom: @Composable ColumnScope.(light: Boolean) -> Unit,
) {
    val p = P
    var expanded by remember { mutableStateOf(false) }
    val styled = bg != null
    val screenW = LocalConfiguration.current.screenWidthDp.dp
    AnimatedContent(expanded && !avatarUrl.isNullOrEmpty(), transitionSpec = { fadeIn(tween(260)) togetherWith fadeOut(tween(200)) }, label = "hero") { big ->
        if (big) Column {
            Box(Modifier.fillMaxWidth().height(screenW).clickable { onOpenPhoto() }) {
                AsyncImage(avatarUrl, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.45f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.6f))))
                Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 6.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) { top(true) }
                Column(Modifier.align(Alignment.BottomStart).padding(18.dp)) {
                    NameRow(name, status, premiumStar, verified, true, 26, onStatus)
                    Text(subtitle, color = Color.White.copy(alpha = 0.85f), fontSize = 15.sp)
                }
                Box(Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 54.dp).clip(RoundedCornerShape(10.dp)).background(Color.Black.copy(alpha = 0.3f))
                    .clickable { expanded = false }.padding(horizontal = 10.dp, vertical = 4.dp)) {
                    Icon(Icons.Filled.KeyboardArrowUp, null, tint = Color.White, modifier = Modifier.size(18.dp))
                }
            }
            Spacer(Modifier.height(12.dp))
            Column(Modifier.fillMaxWidth()) { bottom(false) }
        } else Box(Modifier.fillMaxWidth()) {
            ProfileStyleKt.Background(bg, pattern, status, 150.dp, Modifier.matchParentSize())
            Column(Modifier.fillMaxWidth().statusBarsPadding().padding(bottom = if (styled) 20.dp else 6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Row(Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) { top(styled) }
                Box(Modifier.clip(CircleShape).clickable { if (!avatarUrl.isNullOrEmpty()) expanded = true }) { Avatar(name, avatarUrl, color, 108.dp, storyUid = storyUid) }
                Spacer(Modifier.height(12.dp))
                NameRow(name, status, premiumStar, verified, styled, 25, onStatus)
                if (subtitle.isNotEmpty()) Text(subtitle, color = if (styled) Color.White.copy(alpha = 0.85f) else if (subtitleAccent) p.a2 else p.muted, fontSize = 15.sp,
                    textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 20.dp))
                Spacer(Modifier.height(12.dp))
                bottom(styled)
            }
        }
    }
}

@Composable
private fun NameRow(name: String, status: String?, premiumStar: Boolean, verified: Boolean, white: Boolean, size: Int, onStatus: (() -> Unit)?) {
    val p = P
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(horizontal = 20.dp)) {
        Text(name, color = if (white) Color.White else p.text, fontWeight = FontWeight.Black, fontSize = size.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
        if (verified) Icon(Icons.Filled.Verified, null, tint = if (white) Color.White else p.a2, modifier = Modifier.padding(start = 5.dp).size((size * 0.75).dp))
        val m = Modifier.padding(start = 6.dp).clip(CircleShape).then(if (onStatus != null) Modifier.clickable { onStatus() } else Modifier).padding(2.dp)
        if (!status.isNullOrEmpty()) Box(m) { StatusEmoji(status, (size * 0.85).sp) }
        else if (premiumStar) Box(m) { Icon(Icons.Filled.Star, null, tint = if (white) Color.White else Color(0xFFFFB020), modifier = Modifier.size((size * 0.8).dp)) }
    }
}

// ---------------- музыка профиля ----------------

object ProfileMusic {
    var playing by mutableStateOf<String?>(null)
    private var mp: MediaPlayer? = null
    fun toggle(url: String) {
        if (playing == url) { stop(); return }
        stop()
        val src = ru.volshebnymir.lumo.core.Net.px(url) ?: url
        mp = MediaPlayer().apply {
            setDataSource(src)
            setOnPreparedListener { it.start() }
            setOnCompletionListener { playing = null }
            setOnErrorListener { _, _, _ -> playing = null; true }
            prepareAsync()
        }
        playing = url
    }
    fun stop() { runCatching { mp?.stop(); mp?.release() }; mp = null; playing = null }
}

@Composable
fun ProfileMusicRow(url: String, title: String, artist: String, light: Boolean, modifier: Modifier = Modifier) {
    val p = P
    val on = ProfileMusic.playing == url
    val tr = rememberInfiniteTransition(label = "wave")
    val w by tr.animateFloat(0f, 1f, infiniteRepeatable(tween(420), RepeatMode.Reverse), label = "w")
    DisposableEffect(url) { onDispose { if (ProfileMusic.playing == url) ProfileMusic.stop() } }
    Row(modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(if (light) Color.White.copy(alpha = 0.18f) else p.panel)
        .bouncy { ProfileMusic.toggle(url) }.padding(horizontal = 10.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(32.dp).clip(CircleShape).background(if (light) Color.White else p.a1), contentAlignment = Alignment.Center) {
            Icon(if (on) Icons.Filled.Pause else Icons.Filled.PlayArrow, null, tint = if (light) Color.Black else Color.White, modifier = Modifier.size(18.dp))
        }
        Column(Modifier.weight(1f).padding(horizontal = 10.dp)) {
            Text(title.ifEmpty { "Без названия" }, color = if (light) Color.White else p.text, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (artist.isNotEmpty()) Text(artist, color = (if (light) Color.White else p.text).copy(alpha = 0.75f), fontSize = 13.sp, maxLines = 1)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp), verticalAlignment = Alignment.CenterVertically, modifier = Modifier.height(18.dp)) {
            listOf(14, 8, 16, 10).forEachIndexed { i, hgt ->
                val f = if (on) (if (i % 2 == 0) w else 1f - w) else 0f
                Box(Modifier.width(3.dp).height((5 + (hgt - 5) * f).dp).clip(CircleShape).background(if (light) Color.White.copy(alpha = 0.85f) else p.a1))
            }
        }
        Icon(Icons.Filled.MusicNote, null, tint = if (light) Color.White.copy(alpha = 0.7f) else p.muted, modifier = Modifier.padding(start = 8.dp).size(16.dp))
    }
}

/** Строка редактирования: выбрать трек для профиля */
@Composable
fun ProfileMusicEditRow() {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var busy by remember { mutableStateOf(false) }
    val me = AppModel.me
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { u ->
        if (u != null) {
            busy = true
            scope.launch {
                val r = withContext(Dispatchers.IO) {
                    val data = runCatching { ctx.contentResolver.openInputStream(u)?.use { it.readBytes() } }.getOrNull()
                    val mmr = android.media.MediaMetadataRetriever()
                    val (t, a) = runCatching {
                        mmr.setDataSource(ctx, u)
                        (mmr.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_TITLE) ?: "") to (mmr.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_ARTIST) ?: "")
                    }.getOrDefault("" to "")
                    runCatching { mmr.release() }
                    var fname = ""
                    runCatching { ctx.contentResolver.query(u, null, null, null, null)?.use { c -> if (c.moveToFirst()) fname = c.getString(c.getColumnIndexOrThrow(android.provider.OpenableColumns.DISPLAY_NAME)) ?: "" } }
                    val ext = fname.substringAfterLast('.', "mp3").lowercase().takeIf { it in listOf("mp3", "m4a", "wav", "ogg") } ?: "mp3"
                    Triple(data, ext, (t.ifEmpty { fname.substringBeforeLast('.') }) to a)
                }
                val d = r.first
                if (d == null) AppModel.say("Не удалось открыть файл")
                else if (d.size > 15 * 1024 * 1024) AppModel.say("Файл больше 15 МБ")
                else AppModel.setProfileMusic(d, r.second, r.third.first, r.third.second)
                busy = false
            }
        }
    }
    Row(Modifier.fillMaxWidth().clickable { pick.launch("audio/*") }.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(30.dp).clip(RoundedCornerShape(8.dp)).background(Color(0xFFFF2D55)), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.MusicNote, null, tint = Color.White, modifier = Modifier.size(18.dp))
        }
        Column(Modifier.weight(1f).padding(start = 14.dp)) {
            Text("Музыка профиля", color = p.text, fontSize = 16.sp)
            Text(if (me?.musicUrl == null) "Не выбрана" else me.musicTitle, color = p.muted, fontSize = 13.sp, maxLines = 1)
        }
        if (busy) CircularProgressIndicator(Modifier.size(20.dp), color = p.a1, strokeWidth = 2.dp)
        else if (me?.musicUrl != null) Icon(Icons.Filled.Cancel, null, tint = p.muted, modifier = Modifier.clip(CircleShape).clickable { busy = true; scope.launch { AppModel.setProfileMusic(null); busy = false } }.padding(4.dp))
    }
}

// ---------------- выбор оформления профиля ----------------

@Composable
fun ProfileStyleDialog(onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val me = AppModel.me
    var bg by remember { mutableStateOf(me?.profileBg) }
    var pattern by remember { mutableStateOf(me?.profilePattern) }
    var busy by remember { mutableStateOf(false) }
    Dialog(onClose, DialogProperties(usePlatformDefaultWidth = false)) {
        Column(Modifier.fillMaxWidth().padding(14.dp).clip(RoundedCornerShape(26.dp)).background(p.bg).verticalScroll(rememberScrollState())) {
            Box(Modifier.fillMaxWidth().height(230.dp)) {
                ProfileStyleKt.Background(bg, pattern, me?.emojiStatus, 105.dp, Modifier.matchParentSize())
                Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                    Avatar(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, 86.dp)
                    Spacer(Modifier.height(8.dp))
                    Text(me?.name ?: "", color = if (bg != null) Color.White else p.text, fontWeight = FontWeight.Black, fontSize = 20.sp)
                }
            }
            Text("ЦВЕТ", color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(start = 18.dp, top = 12.dp, bottom = 6.dp))
            Row(Modifier.padding(horizontal = 14.dp).horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.size(40.dp).clip(CircleShape).background(p.panel2).border(if (bg == null) 3.dp else 0.dp, p.a1, CircleShape).bouncy { bg = null }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Block, null, tint = p.muted, modifier = Modifier.size(18.dp))
                }
                ProfileStyleKt.colors.forEachIndexed { i, _ ->
                    Box(Modifier.size(40.dp).clip(CircleShape).background(ProfileStyleKt.brush(i)!!).border(if (bg == i) 3.dp else 0.dp, Color.White, CircleShape).bouncy { bg = i })
                }
            }
            Text("УЗОР · PREMIUM", color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(start = 18.dp, top = 14.dp, bottom = 6.dp))
            val opts = buildList { add(null); if (!me?.emojiStatus.isNullOrEmpty()) add("@status"); addAll(ProfileStyleKt.patterns.map { it.first }) }
            opts.chunked(6).forEach { row ->
                Row(Modifier.padding(horizontal = 14.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    row.forEach { o ->
                        Box(Modifier.size(46.dp).clip(RoundedCornerShape(12.dp)).background(if (pattern == o) p.a1.copy(alpha = 0.2f) else p.panel2)
                            .border(if (pattern == o) 2.dp else 0.dp, p.a1, RoundedCornerShape(12.dp))
                            .bouncy { if (o == null || AppModel.isPremium) pattern = o else AppModel.say("Узоры доступны в Lumo Premium") }, contentAlignment = Alignment.Center) {
                            when (o) {
                                null -> Icon(Icons.Filled.Block, null, tint = p.muted, modifier = Modifier.size(20.dp))
                                "@status" -> StatusEmoji(me?.emojiStatus ?: "", 20.sp)
                                else -> Icon(ProfileStyleKt.icon(o), null, tint = p.text, modifier = Modifier.size(22.dp))
                            }
                        }
                    }
                }
            }
            Spacer(Modifier.height(14.dp))
            Row(Modifier.padding(horizontal = 14.dp, vertical = 10.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.weight(1f).height(48.dp).clip(RoundedCornerShape(24.dp)).background(p.panel2).bouncy(onClose), contentAlignment = Alignment.Center) { Text("Отмена", color = p.text, fontWeight = FontWeight.SemiBold) }
                Box(Modifier.weight(1f).height(48.dp).clip(RoundedCornerShape(24.dp)).background(p.accent).bouncy {
                    if (!busy) { busy = true; scope.launch { if (AppModel.setProfileStyle(bg, pattern)) onClose(); busy = false } }
                }, contentAlignment = Alignment.Center) { if (busy) CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp) else Text("Сохранить", color = Color.White, fontWeight = FontWeight.Bold) }
            }
        }
    }
}

// ---------------- публикации в профиле ----------------

@Composable
fun PostsGrid(items: List<JSONObject>, showPin: Boolean = false, open: (JSONObject) -> Unit) {
    items.chunked(3).forEach { row ->
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            row.forEach { st ->
                val kind = st.optString("kind"); val url = st.optString("media_url")
                val thumb = if (kind == "video") st.optJSONObject("meta")?.optString("thumb")?.takeIf { it.isNotEmpty() } else url
                Box(Modifier.weight(1f).aspectRatio(9f / 16f).background(Color.Black).bouncy { open(st) }) {
                    if (thumb != null) AsyncImage(thumb, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                    else Icon(Icons.Filled.PlayCircle, null, tint = Color.White.copy(alpha = 0.6f), modifier = Modifier.align(Alignment.Center))
                    Row(Modifier.align(Alignment.BottomStart).padding(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        if (kind == "video") Icon(Icons.Filled.PlayArrow, null, tint = Color.White, modifier = Modifier.size(14.dp))
                        val v = st.optInt("views", 0)
                        if (v > 0) { Icon(Icons.Filled.Visibility, null, tint = Color.White, modifier = Modifier.size(13.dp)); Text(" $v", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold) }
                    }
                    if (showPin && st.optBoolean("pinned")) Icon(Icons.Filled.PushPin, null, tint = Color.White,
                        modifier = Modifier.align(Alignment.TopEnd).padding(5.dp).size(20.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.45f)).padding(3.dp))
                }
            }
            repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
        }
        Spacer(Modifier.height(2.dp))
    }
}

/** Просмотр публикации на весь экран; владелец может убрать её из профиля или удалить */
@Composable
fun PostViewer(st: JSONObject, mine: Boolean, onClose: () -> Unit) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var pinned by remember { mutableStateOf(st.optBoolean("pinned", true)) }
    var menu by remember { mutableStateOf(false) }
    var confirm by remember { mutableStateOf(false) }
    val id = st.optInt("id")
    BackHandler { onClose() }
    Dialog(onClose, DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black)) {
            if (st.optString("kind") == "video") {
                val player = remember(id) {
                    androidx.media3.exoplayer.ExoPlayer.Builder(ctx).build().apply {
                        setMediaItem(androidx.media3.common.MediaItem.fromUri(ru.volshebnymir.lumo.core.Net.px(st.optString("media_url")) ?: st.optString("media_url"))); prepare(); playWhenReady = true
                    }
                }
                DisposableEffect(id) { onDispose { player.release() } }
                androidx.compose.ui.viewinterop.AndroidView({ c -> androidx.media3.ui.PlayerView(c).apply { useController = false; this.player = player } }, Modifier.fillMaxSize())
            } else AsyncImage(st.optString("media_url"), null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
            Row(Modifier.fillMaxWidth().statusBarsPadding().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(ru.volshebnymir.lumo.core.Fmt.listTime(st.date("created_at")), color = Color.White, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f).padding(start = 8.dp))
                if (mine) Box {
                    RoundIcon(Icons.Filled.MoreHoriz, tint = Color.White) { menu = true }
                    androidx.compose.material3.DropdownMenu(menu, { menu = false }) {
                        androidx.compose.material3.DropdownMenuItem(text = { Text(if (pinned) "Убрать из профиля" else "Опубликовать в профиле") },
                            leadingIcon = { Icon(Icons.Filled.PushPin, null) }, onClick = { menu = false; scope.launch { AppModel.setStoryPinned(id, !pinned); pinned = !pinned } })
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Удалить", color = P.danger) }, leadingIcon = { Icon(Icons.Filled.Delete, null, tint = P.danger) },
                            onClick = { menu = false; confirm = true })
                    }
                }
                RoundIcon(Icons.Filled.Close, tint = Color.White) { onClose() }
            }
            val cap = st.optString("caption")
            if (cap.isNotEmpty() && cap != "null") Text(cap, color = Color.White, textAlign = TextAlign.Center, modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.6f)))).navigationBarsPadding().padding(16.dp))
        }
    }
    if (confirm) AlertDialog(onDismissRequest = { confirm = false }, title = { Text("Удалить историю навсегда?") },
        confirmButton = { TextButton({ confirm = false; scope.launch { runCatching { ru.volshebnymir.lumo.core.Api.rpc("lm_story_delete", ru.volshebnymir.lumo.core.jsonOf("p_id" to id)) }; AppModel.loadStories(); AppModel.loadMe(); onClose() } }) { Text("Удалить", color = P.danger) } },
        dismissButton = { TextButton({ confirm = false }) { Text("Отмена") } })
}

/** Вкладка «Публикации» профиля */
@Composable
fun ProfilePostsTab(userId: String) {
    val p = P
    var posts by remember(userId) { mutableStateOf<List<JSONObject>?>(null) }
    var open by remember { mutableStateOf<JSONObject?>(null) }
    var rev by remember { mutableIntStateOf(0) }
    LaunchedEffect(userId, rev) { posts = AppModel.profilePosts(userId) }
    val l = posts
    when {
        l == null -> Box(Modifier.fillMaxWidth().height(100.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = p.a1, modifier = Modifier.size(26.dp)) }
        l.isEmpty() -> Column(Modifier.fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Filled.GridOn, null, tint = p.muted, modifier = Modifier.size(30.dp))
            Text(if (userId == AppModel.myId) "Опубликуйте историю в профиле — она останется здесь" else "Пока нет публикаций", color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 6.dp))
        }
        else -> Column(Modifier.padding(horizontal = 14.dp).clip(RoundedCornerShape(14.dp))) { PostsGrid(l) { open = it } }
    }
    open?.let { PostViewer(it, userId == AppModel.myId) { open = null; rev++ } }
}

/** Экран «Архив историй» / «Опубликованные истории» */
@Composable
fun StoryArchiveScreen(postsOnly: Boolean, onClose: () -> Unit) {
    val p = P
    var items by remember { mutableStateOf<List<JSONObject>?>(null) }
    var open by remember { mutableStateOf<JSONObject?>(null) }
    var rev by remember { mutableIntStateOf(0) }
    LaunchedEffect(rev) { items = if (postsOnly) AppModel.profilePosts(AppModel.myId ?: "") else AppModel.storyArchive() }
    BackHandler { onClose() }
    Column(Modifier.fillMaxSize().background(p.bg).clickable(remember { MutableInteractionSource() }, null) {}.statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().padding(6.dp), verticalAlignment = Alignment.CenterVertically) {
            RoundIcon(Icons.Filled.Close) { onClose() }
            Text(if (postsOnly) "Опубликованные истории" else "Архив историй", color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp)
        }
        val l = items
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            when {
                l == null -> Box(Modifier.fillMaxWidth().padding(60.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = p.a1) }
                l.isEmpty() -> Text(if (postsOnly) "Нет опубликованных историй.\nВключите «Опубликовать в моём профиле» при публикации." else "Архив пуст. Здесь хранятся все ваши истории, их видите только вы.",
                    color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp))
                else -> PostsGrid(l, showPin = !postsOnly) { open = it }
            }
        }
    }
    open?.let { PostViewer(it, true) { open = null; rev++ } }
}

// ---------------- «Поделиться историей» ----------------

private val SBG = Color(0xFF121217)
private val SPANEL = Color(0xFF212128)
private val SBLUE = Color(0xFF2F8CFF)

@Composable
fun PeoplePickDialog(title: String, initial: Set<String>, onDone: (Set<String>) -> Unit, onDismiss: () -> Unit) {
    val p = P
    var sel by remember { mutableStateOf(initial) }
    val people = AppModel.contacts.toList()
    AlertDialog(onDismissRequest = onDismiss, containerColor = p.panel,
        title = { Text(title, color = p.text) },
        text = {
            if (people.isEmpty()) Text("В контактах пока никого", color = p.muted)
            else LazyColumn(Modifier.heightIn(max = 400.dp)) {
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
        confirmButton = { TextButton({ onDone(sel) }) { Text("Готово", color = p.a1) } },
        dismissButton = { TextButton(onDismiss) { Text("Отмена", color = p.muted) } })
}

class StoryShareState {
    var choice by mutableStateOf("all")
    var excl by mutableStateOf(setOf<String>())
    var sel by mutableStateOf(setOf<String>())
    var pinned by mutableStateOf(true)
    var shots by mutableStateOf(true)
    var hours by mutableIntStateOf(24)
    /** в формат сервера: аудитория и список */
    fun resolve(): Pair<String, List<String>> = when (choice) {
        "contacts" -> "contacts" to excl.toList()
        "close" -> "close" to emptyList()
        "only" -> "only" to sel.toList()
        else -> if (excl.isEmpty()) "all" to emptyList() else "except" to excl.toList()
    }
}

@Composable
fun StoryShareScreen(st: StoryShareState, busy: Boolean, onBack: () -> Unit, onPublish: () -> Unit) {
    val scope = rememberCoroutineScope()
    var pick by remember { mutableStateOf<String?>(null) }
    var close by remember { mutableStateOf(setOf<String>()) }
    LaunchedEffect(Unit) { close = AppModel.closeFriends() }
    BackHandler { onBack() }
    val me = AppModel.me
    Box(Modifier.fillMaxSize().background(SBG).clickable(remember { MutableInteractionSource() }, null) {}) {
        Column(Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp)) {
            Box(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                Box(Modifier.size(34.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f)).bouncy(onBack), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Close, null, tint = Color.White, modifier = Modifier.size(18.dp))
                }
                Text("Поделиться историей", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.align(Alignment.Center))
            }
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(SPANEL).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Avatar(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, 40.dp)
                Column(Modifier.padding(start = 12.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(me?.name ?: "", color = Color.White, fontWeight = FontWeight.SemiBold)
                        if (me?.premium == true) { if (!me.emojiStatus.isNullOrEmpty()) StatusEmoji(me.emojiStatus, 15.sp, Modifier.padding(start = 4.dp)) else Icon(Icons.Filled.Star, null, tint = SBLUE, modifier = Modifier.padding(start = 4.dp).size(14.dp)) }
                    }
                    Text("личный аккаунт", color = Color.White.copy(alpha = 0.55f), fontSize = 13.sp)
                }
            }
            Text("КТО ВИДИТ ЭТУ ИСТОРИЮ", color = Color.White.copy(alpha = 0.55f), fontSize = 12.5.sp, modifier = Modifier.padding(start = 14.dp, top = 18.dp, bottom = 6.dp))
            Column(Modifier.clip(RoundedCornerShape(14.dp)).background(SPANEL)) {
                AudRow(st, "all", Icons.Filled.Campaign, Color(0xFF2F8CFF), "Все", if (st.choice == "all" && st.excl.isNotEmpty()) "кроме ${st.excl.size} чел." else "добавить исключения") { pick = "excl" }
                AudRow(st, "contacts", Icons.Filled.Person, Color(0xFF9B5CFF), "Мои контакты", if (st.choice == "contacts" && st.excl.isNotEmpty()) "кроме ${st.excl.size} чел." else "добавить исключения") { pick = "excl" }
                AudRow(st, "close", Icons.Filled.Star, Color(0xFF34C759), "Близкие друзья", if (close.isEmpty()) "выбрать" else "${close.size} чел. · изменить") { pick = "close" }
                AudRow(st, "only", Icons.Filled.Group, Color(0xFFFF9500), "Выбранные пользователи", if (st.sel.isEmpty()) "выбрать" else "${st.sel.size} чел. · изменить", last = true) { pick = "only" }
            }
            Text("Выберите пользователей, которые не будут видеть Вашу историю.", color = Color.White.copy(alpha = 0.55f), fontSize = 12.5.sp, modifier = Modifier.padding(14.dp, 6.dp))
            Column(Modifier.padding(top = 8.dp).clip(RoundedCornerShape(14.dp)).background(SPANEL)) {
                ToggleRow("Разрешить снимки экрана", st.shots) { st.shots = it }
                Box(Modifier.padding(start = 14.dp).fillMaxWidth().height(1.dp).background(Color.White.copy(alpha = 0.08f)))
                ToggleRow("Опубликовать в моём профиле", st.pinned) { st.pinned = it }
            }
            Text("История в профиле останется после 24 часов. Её смогут увидеть только те, кого Вы выбрали выше.", color = Color.White.copy(alpha = 0.55f), fontSize = 12.5.sp, modifier = Modifier.padding(14.dp, 6.dp))
            Row(Modifier.padding(top = 8.dp).fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(SPANEL).padding(horizontal = 14.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("Срок", color = Color.White, modifier = Modifier.weight(1f))
                listOf(24 to "24 ч", 48 to "48 ч", 72 to "3 дня", 168 to "7 дней").forEach { (h, t) ->
                    Text(t, color = if (st.hours == h) Color.White else SBLUE, fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(start = 4.dp).clip(RoundedCornerShape(10.dp)).background(if (st.hours == h) SBLUE else Color.Transparent)
                            .clickable { if (h == 24 || AppModel.isPremium) st.hours = h else AppModel.say("Дольше 24 часов — в Lumo Premium") }.padding(horizontal = 8.dp, vertical = 5.dp))
                }
            }
            Spacer(Modifier.height(110.dp))
        }
        Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().background(SBG.copy(alpha = 0.96f)).navigationBarsPadding().padding(16.dp)) {
            val ok = !(st.choice == "only" && st.sel.isEmpty())
            StoryPublishBar(busy, AppModel.storyUpload, ok) { if (ok && !busy) onPublish() }
        }
    }
    when (pick) {
        "excl" -> PeoplePickDialog("Скрыть от", st.excl, { st.excl = it; pick = null }) { pick = null }
        "only" -> PeoplePickDialog("Кто увидит", st.sel, { st.sel = it; st.choice = "only"; pick = null }) { pick = null }
        "close" -> PeoplePickDialog("Близкие друзья", close, { close = it; pick = null; scope.launch { AppModel.setCloseFriends(it) } }) { pick = null }
    }
}

@Composable
private fun AudRow(st: StoryShareState, key: String, icon: ImageVector, tint: Color, title: String, sub: String, last: Boolean = false, subTap: () -> Unit) {
    Column {
        Row(Modifier.fillMaxWidth().clickable { st.choice = key; if (key == "only" && st.sel.isEmpty()) subTap() }.padding(horizontal = 12.dp, vertical = 9.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(if (st.choice == key) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null, tint = if (st.choice == key) SBLUE else Color.White.copy(alpha = 0.3f), modifier = Modifier.size(24.dp))
            Box(Modifier.padding(start = 12.dp).size(38.dp).clip(CircleShape).background(tint), contentAlignment = Alignment.Center) { Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp)) }
            Column(Modifier.padding(start = 12.dp)) {
                Text(title, color = Color.White, fontWeight = FontWeight.Medium, fontSize = 16.sp)
                Text("$sub ›", color = SBLUE, fontSize = 13.sp, modifier = Modifier.clickable { subTap() })
            }
        }
        if (!last) Box(Modifier.padding(start = 96.dp).fillMaxWidth().height(1.dp).background(Color.White.copy(alpha = 0.08f)))
    }
}

@Composable
private fun ToggleRow(t: String, v: Boolean, f: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().clickable { f(!v) }.padding(horizontal = 14.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(t, color = Color.White, modifier = Modifier.weight(1f))
        Switch(v, f, colors = SwitchDefaults.colors(checkedTrackColor = Color(0xFF34C759), checkedThumbColor = Color.White))
    }
}

/** Кадр из видео для превью публикации */
fun videoThumb(ctx: android.content.Context, uri: android.net.Uri): ByteArray? = runCatching {
    val mmr = android.media.MediaMetadataRetriever()
    mmr.setDataSource(ctx, uri)
    val bmp = mmr.getFrameAtTime(100_000) ?: return null
    mmr.release()
    val scale = 540f / maxOf(bmp.width, 1)
    val b = if (scale < 1f) android.graphics.Bitmap.createScaledBitmap(bmp, (bmp.width * scale).toInt(), (bmp.height * scale).toInt(), true) else bmp
    java.io.ByteArrayOutputStream().also { b.compress(android.graphics.Bitmap.CompressFormat.JPEG, 72, it) }.toByteArray()
}.getOrNull()


/** Кнопка публикации: во время загрузки заливается слева направо, показывает проценты, потом «Публикуем…» */
@Composable
fun StoryPublishBar(busy: Boolean, progress: Float?, enabled: Boolean, onClick: () -> Unit) {
    val p = (progress ?: if (busy) 1f else 0f).coerceIn(0f, 1f)
    val anim by animateFloatAsState(p, tween(250), label = "pub")
    val done = busy && (progress == null || p >= 0.95f)
    val tr = rememberInfiniteTransition(label = "sh")
    val sh by tr.animateFloat(-0.3f, 1.3f, infiniteRepeatable(tween(1300, easing = LinearEasing)), label = "shx")
    BoxWithConstraints(Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(26.dp))
        .background(if (busy) SBLUE.copy(alpha = 0.35f) else SBLUE.copy(alpha = if (enabled) 1f else 0.5f)).bouncy(onClick)) {
        if (busy) {
            val w = maxWidth
            Box(Modifier.fillMaxHeight().width(maxOf(52.dp, w * anim)).clip(RoundedCornerShape(26.dp)).background(SBLUE)) {
                Box(Modifier.fillMaxHeight().width(80.dp).offset(x = w * sh - 40.dp)
                    .background(Brush.horizontalGradient(listOf(Color.Transparent, Color.White.copy(alpha = 0.35f), Color.Transparent))))
            }
        }
        Row(Modifier.align(Alignment.Center), verticalAlignment = Alignment.CenterVertically) {
            if (done) { CircularProgressIndicator(Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp); Spacer(Modifier.width(8.dp)) }
            Text(if (!busy) "Опубликовать историю" else if (done) "Публикуем…" else "Загрузка ${(p * 100 / 0.95f).toInt().coerceAtMost(100)}%",
                color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
        }
    }
}
