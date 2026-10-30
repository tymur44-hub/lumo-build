package ru.volshebnymir.lumo.ui

import ru.volshebnymir.lumo.core.isPremium
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.ChatWall

/** Готовые обои (номера такие же, как на iPhone) */
fun wallPresetBrush(i: Int, p: Palette): Brush? = when (i) {
    1 -> Brush.linearGradient(listOf(Color(0xFF7C5CFF).copy(alpha = 0.16f), Color(0xFF22C1FF).copy(alpha = 0.12f)))
    2 -> Brush.linearGradient(listOf(Color(0xFFFF5B8A).copy(alpha = 0.18f), Color(0xFF7C5CFF).copy(alpha = 0.18f)))
    3 -> Brush.linearGradient(listOf(Color(0xFF8080AA).copy(alpha = 0.14f), Color(0xFF8080AA).copy(alpha = 0.06f)))
    4 -> Brush.linearGradient(listOf(Color(0xFF13B0A5).copy(alpha = 0.18f), Color(0xFF2EE6A6).copy(alpha = 0.08f)))
    5 -> Brush.linearGradient(listOf(Color(0xFF8080AA).copy(alpha = 0.10f), Color(0xFF8080AA).copy(alpha = 0.16f)))
    6 -> Brush.verticalGradient(listOf(Color(0xFF1B2A49), Color(0xFF3B1F4A)))
    7 -> Brush.verticalGradient(listOf(Color(0xFF0F3D3E), Color(0xFF1B6B4A)))
    8 -> Brush.verticalGradient(listOf(Color(0xFF4A1F2E), Color(0xFF7A3B1F)))
    9 -> Brush.verticalGradient(listOf(Color(0xFF1F2A4A), Color(0xFF2E6BA8)))
    else -> null
}

/** Фон чата: обои этого чата, иначе общие */
@Composable
fun ChatWallBackground(chatId: String) {
    val cw = AppModel.chatWalls[chatId]
    val p = P
    if (cw?.url != null) {
        AsyncImage(cw.url, null, Modifier.fillMaxSize().then(if (cw.blur) Modifier.blur(14.dp) else Modifier), contentScale = ContentScale.Crop)
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = cw.dim / 100f)))
    } else if (cw?.preset != null) {
        WallLayer(cw.preset, p)
        if (cw.dim > 0) Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = cw.dim / 100f)))
    } else if (Extra.wall != 0 && (!wallIsPremium(Extra.wall) || AppModel.isPremium)) WallLayer(Extra.wall, p)
}

/** Обои для этого чата: только для себя или для себя и собеседника (как в Telegram) */
@Composable
fun ChatWallDialog(chatId: String, peerName: String?, isPrivate: Boolean, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var preview by remember { mutableStateOf(false) }
    var preset by remember { mutableStateOf<Int?>(null) }
    var uri by remember { mutableStateOf<Uri?>(null) }
    var blur by remember { mutableStateOf(false) }
    var dim by remember { mutableFloatStateOf(0f) }
    var busy by remember { mutableStateOf(false) }
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u -> if (u != null) { uri = u; preset = null; preview = true } }

    fun apply(both: Boolean) {
        busy = true
        scope.launch {
            var url: String? = null
            val u = uri
            if (u != null) {
                val data = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u) }
                val j = data?.let { withContext(Dispatchers.Default) { MediaUtil.jpeg(it) } }
                url = j?.let { runCatching { Api.upload(it.first, "jpg", "image/jpeg") }.getOrNull() }
                if (url == null) { AppModel.say("Не удалось загрузить фото"); busy = false; return@launch }
            }
            val ok = AppModel.setWall(chatId, if (url == null) (preset ?: 0) else null, url, blur, dim.toInt(), both)
            busy = false
            if (ok) onClose()
        }
    }

    Dialog(onDismissRequest = { if (preview) preview = false else onClose() }, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Box(Modifier.fillMaxSize().background(p.bg)) {
            if (!preview) {
                Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(40.dp).bouncy { onClose() }, contentAlignment = Alignment.Center) { Icon(Icons.Filled.Close, null, tint = p.text) }
                        Text("Обои чата", color = p.text, fontWeight = FontWeight.Bold, fontSize = 20.sp, modifier = Modifier.padding(start = 8.dp))
                    }
                    Spacer(Modifier.height(12.dp))
                    LazyVerticalGrid(GridCells.Fixed(3), Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        items(WALL_ALL) { i ->
                            Box(Modifier.height(140.dp).clip(RoundedCornerShape(16.dp)).background(p.chatBg).border(1.dp, p.line, RoundedCornerShape(16.dp))
                                .bouncy { preset = i; uri = null; preview = true }) {
                                WallLayer(i, p)
                                if (wallIsPremium(i)) Icon(Icons.Filled.Star, null, tint = Color(0xFFFFC247), modifier = Modifier.align(Alignment.TopEnd).padding(6.dp).size(16.dp))
                            }
                        }
                    }
                    Row(Modifier.fillMaxWidth().padding(top = 12.dp).clip(RoundedCornerShape(16.dp)).background(p.panel2)
                        .bouncy { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }.padding(14.dp),
                        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.PhotoLibrary, null, tint = p.a1)
                        Spacer(Modifier.width(8.dp))
                        Text("Выбрать обои из фото", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    }
                    if (AppModel.chatWalls[chatId] != null) {
                        Text("Сбросить обои этого чата", color = p.danger, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth().bouncy { scope.launch { AppModel.clearWall(chatId); onClose() } }.padding(vertical = 14.dp))
                    }
                }
            } else {
                val bmp = remember(uri) { uri?.let { u -> runCatching { ctx.contentResolver.openInputStream(u)?.use { BitmapFactory.decodeStream(it) } }.getOrNull() } }
                Box(Modifier.fillMaxSize()) {
                    if (bmp != null) Image(bmp.asImageBitmap(), null, Modifier.fillMaxSize().then(if (blur) Modifier.blur(14.dp) else Modifier), contentScale = ContentScale.Crop)
                    else { Box(Modifier.fillMaxSize().background(p.chatBg)); WallLayer(preset ?: 0, p) }
                    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = dim / 100f)))
                }
                Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(12.dp)) {
                    Box(Modifier.size(40.dp).clip(RoundedCornerShape(20.dp)).background(Color.Black.copy(alpha = 0.35f)).bouncy { preview = false }, contentAlignment = Alignment.Center) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = Color.White)
                    }
                    Spacer(Modifier.height(10.dp))
                    Text("Привет! Так будут выглядеть обои", color = p.text, fontSize = 15.sp, modifier = Modifier.clip(RoundedCornerShape(16.dp)).background(p.bubble).padding(horizontal = 12.dp, vertical = 8.dp))
                    Spacer(Modifier.height(8.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        Text("Отлично выглядит!", color = Color.White, fontSize = 15.sp, modifier = Modifier.clip(RoundedCornerShape(16.dp)).background(p.out).padding(horizontal = 12.dp, vertical = 8.dp))
                    }
                    Spacer(Modifier.weight(1f))
                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(p.panel.copy(alpha = 0.92f)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (uri != null) Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("Размытие", color = p.text, modifier = Modifier.weight(1f)); Switch(blur, { blur = it })
                        }
                        Slider(dim, { dim = it }, valueRange = 0f..80f)
                        ApplyButton(if (busy) null else "Применить для этого чата", true) { if (!busy) apply(false) }
                        if (isPrivate) ApplyButton(if (busy) null else "Применить для меня и ${peerName ?: "собеседника"}", false) { if (!busy) apply(true) }
                    }
                }
            }
        }
    }
}

@Composable
private fun ApplyButton(text: String?, filled: Boolean, onClick: () -> Unit) {
    val p = P
    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).then(if (filled) Modifier.background(p.accent) else Modifier.background(p.a1.copy(alpha = 0.14f)))
        .clickable(onClick = onClick).padding(vertical = 13.dp), contentAlignment = Alignment.Center) {
        if (text == null) CircularProgressIndicator(Modifier.size(20.dp), color = if (filled) Color.White else p.a1, strokeWidth = 2.dp)
        else Text(text, color = if (filled) Color.White else p.a1, fontWeight = FontWeight.Bold, fontSize = 16.sp)
    }
}
