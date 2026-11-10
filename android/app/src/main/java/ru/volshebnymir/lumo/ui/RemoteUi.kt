package ru.volshebnymir.lumo.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.SystemUpdate
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.RemoteConfig

/** Экран «Обновите приложение» — когда версия старше указанной на сервере */
@Composable
fun UpdateRequiredScreen() {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    Box(Modifier.fillMaxSize().background(Color(0xFF0C0D1A))) {
        AuroraBackground(1f)
        Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.weight(1f))
            Box(Modifier.size(110.dp).clip(CircleShape).background(Brush.linearGradient(listOf(P.a1, P.a2))), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.SystemUpdate, null, tint = Color.White, modifier = Modifier.size(52.dp))
            }
            Spacer(Modifier.height(18.dp))
            Text("Нужно обновление", color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(10.dp))
            Text(RemoteConfig.updateText, color = Color.White.copy(alpha = 0.85f), fontSize = 16.sp, textAlign = TextAlign.Center)
            Spacer(Modifier.weight(1f))
            RemoteConfig.updateUrl?.let { u ->
                GradientButton("Обновить") { runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(u)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } }
                Spacer(Modifier.height(12.dp))
            }
            Text("Проверить ещё раз", color = Color.White.copy(alpha = 0.8f), fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                modifier = Modifier.bouncy { scope.launch { RemoteConfig.refresh(force = true) } }.padding(10.dp))
        }
    }
}

/** Объявление в списке чатов (текст задаётся на сервере), крестик скрывает его до следующего */
@Composable
fun AnnounceCard() {
    val a = RemoteConfig.announce ?: return
    val ctx = LocalContext.current
    val prefs = remember { ctx.getSharedPreferences("lumo_prefs", android.content.Context.MODE_PRIVATE) }
    var hidden by remember { mutableStateOf(prefs.getString("ann_hide", "")) }
    if (hidden == a.id) return
    val p = P
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 6.dp).clip(RoundedCornerShape(18.dp)).background(p.panel).padding(12.dp), verticalAlignment = Alignment.Top) {
        Box(Modifier.size(38.dp).clip(CircleShape).background(Brush.linearGradient(listOf(p.a1, p.a2))), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Campaign, null, tint = Color.White, modifier = Modifier.size(20.dp))
        }
        Column(Modifier.weight(1f).padding(start = 12.dp)) {
            Text(a.title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
            Text(a.text, color = p.muted, fontSize = 14.sp)
            a.url?.let { u ->
                Text(a.button ?: "Подробнее", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 14.sp,
                    modifier = Modifier.padding(top = 4.dp).bouncy { runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(u)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } })
            }
        }
        Box(Modifier.size(30.dp).bouncy { prefs.edit().putString("ann_hide", a.id).apply(); hidden = a.id }, contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Close, null, tint = p.muted, modifier = Modifier.size(16.dp))
        }
    }
}

/** Стикер-картинка с сервера */
@Composable
fun RemoteSticker(url: String, size: Dp, modifier: Modifier = Modifier) {
    AsyncImage(url, null, modifier.size(size), contentScale = ContentScale.Fit)
}

/** Обои с сервера (номер 1000+n) */
@Composable
fun RemoteWallLayer(i: Int, modifier: Modifier = Modifier.fillMaxSize()) {
    val w = RemoteConfig.wall(i) ?: return
    AsyncImage(w.url, null, modifier, contentScale = ContentScale.Crop)
}
