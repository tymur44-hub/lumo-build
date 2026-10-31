package ru.volshebnymir.lumo.ui

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.Message
import ru.volshebnymir.lumo.core.Profile

/** Особые текстовые сообщения (без изменения схемы): геопозиция и контакт. Формат общий с iOS и вебом. */
sealed class SpecialMsg {
    data class Loc(val title: String, val lat: Double, val lng: Double) : SpecialMsg()
    data class Contact(val name: String, val id: String) : SpecialMsg()

    companion object {
        fun locationBody(title: String?, lat: Double, lng: Double) =
            "📍 ${if (title.isNullOrEmpty()) "Геопозиция" else title}\nhttps://maps.apple.com/?ll=" + String.format(java.util.Locale.US, "%.6f,%.6f", lat, lng)

        fun contactBody(name: String, id: String) = "👤 $name\nlumo://user/$id"

        fun parse(body: String?): SpecialMsg? {
            if (body == null) return null
            val lines = body.split("\n")
            if (lines.size < 2) return null
            val last = lines.last()
            val head = lines.dropLast(1).joinToString("\n")
            val pre = "https://maps.apple.com/?ll="
            if (head.startsWith("📍 ") && last.startsWith(pre)) {
                val c = last.removePrefix(pre).split(",")
                val la = c.getOrNull(0)?.toDoubleOrNull(); val lo = c.getOrNull(1)?.toDoubleOrNull()
                if (c.size == 2 && la != null && lo != null) return Loc(head.removePrefix("📍 "), la, lo)
            }
            if (head.startsWith("👤 ") && last.startsWith("lumo://user/")) return Contact(head.removePrefix("👤 "), last.removePrefix("lumo://user/"))
            return null
        }
    }
}

/** Карточка геопозиции/контакта в ленте */
@Composable
fun SpecialCard(sp: SpecialMsg, fg: Color, mine: Boolean) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    when (sp) {
        is SpecialMsg.Loc -> Row(Modifier.widthIn(min = 220.dp).clip(RoundedCornerShape(12.dp)).clickable {
            val u = Uri.parse("geo:${sp.lat},${sp.lng}?q=${sp.lat},${sp.lng}(${Uri.encode(sp.title)})")
            runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, u).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        }.padding(6.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(48.dp).clip(CircleShape).background(Color(0xFFE5484D)), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.LocationOn, null, tint = Color.White)
            }
            Spacer(Modifier.width(10.dp))
            Column {
                Text(sp.title, color = fg, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Text("Открыть на карте", color = fg.copy(alpha = 0.7f), fontSize = 13.sp)
            }
        }
        is SpecialMsg.Contact -> {
            LaunchedEffect(sp.id) { if (AppModel.profiles[sp.id] == null) AppModel.loadProfiles(listOf(sp.id)) }
            val pr = AppModel.profiles[sp.id]
            Row(Modifier.widthIn(min = 220.dp).clip(RoundedCornerShape(12.dp)).clickable { scope.launch { AppModel.openDM(sp.id) } }.padding(6.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Avatar(sp.name, pr?.avatarUrl, pr?.color ?: 0, 46.dp)
                Spacer(Modifier.width(10.dp))
                Column {
                    Text(sp.name, color = fg, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text("Контакт", color = fg.copy(alpha = 0.7f), fontSize = 13.sp)
                }
            }
        }
    }
}

@Composable
private fun PanelRow(icon: ImageVector, color: Color, title: String, sub: String, onClick: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(48.dp).clip(CircleShape).background(color), contentAlignment = Alignment.Center) { Icon(icon, null, tint = Color.White) }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(title, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (sub.isNotEmpty()) Text(sub, color = p.muted, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

/** Вкладка «Геопозиция» */
@SuppressLint("MissingPermission")
@Composable
fun LocationPanel(onPick: (Double, Double) -> Unit) {
    val p = P
    val ctx = LocalContext.current
    var busy by remember { mutableStateOf(false) }
    var denied by remember { mutableStateOf(false) }

    fun fetch() {
        busy = true
        val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val provs = lm.getProviders(true)
        if (provs.isEmpty()) { busy = false; AppModel.say("Включите геолокацию в настройках телефона"); return }
        val last: Location? = provs.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }.maxByOrNull { it.time }
        if (last != null && System.currentTimeMillis() - last.time < 120_000) { busy = false; onPick(last.latitude, last.longitude); return }
        val prov = if (provs.contains(LocationManager.GPS_PROVIDER)) LocationManager.GPS_PROVIDER else provs.first()
        androidx.core.location.LocationManagerCompat.getCurrentLocation(lm, prov, null, ContextCompat.getMainExecutor(ctx),
            androidx.core.util.Consumer<Location?> { loc ->
                busy = false
                val l = loc ?: last
                if (l != null) onPick(l.latitude, l.longitude) else AppModel.say("Не удалось определить положение")
            })
    }

    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r ->
        if (r.values.any { it }) fetch() else denied = true
    }
    fun start() {
        val ok = ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (ok) fetch() else perm.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION))
    }

    Column(Modifier.fillMaxWidth().padding(top = 8.dp)) {
        PanelRow(Icons.Filled.LocationOn, Color(0xFF3390EC), "Отправить геопозицию", if (busy) "Определяем…" else "Ваше текущее местоположение") { if (!busy) start() }
        PanelRow(Icons.Filled.NearMe, Color(0xFF4CAF50), "Транслировать геопозицию", "Обновляется в реальном времени · в разработке") {
            AppModel.say("Трансляция геопозиции: в разработке")
        }
        if (denied) Text("Разрешите доступ к геопозиции в настройках телефона", color = p.muted, fontSize = 14.sp, modifier = Modifier.padding(20.dp))
        Text("Места рядом: в разработке", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 20.dp, vertical = 14.dp))
    }
}

/** Вкладка «Контакт» */
@Composable
fun ContactsPanel(onPick: (Profile) -> Unit) {
    val p = P
    val ids = remember(AppModel.contacts.size, AppModel.chats.size) {
        (AppModel.contacts.toSet() + AppModel.chats.filter { it.isPrivate }.mapNotNull { it.peerId }).minus(AppModel.myId ?: "")
    }
    LaunchedEffect(ids) { AppModel.loadProfiles(ids) }
    fun nm(x: Profile) = AppModel.aliases[x.id] ?: x.name
    val list = ids.mapNotNull { AppModel.profiles[it] }.filter { !it.isBot }.sortedBy { nm(it).lowercase() }
    if (list.isEmpty()) { Text("Контактов пока нет", color = p.muted, modifier = Modifier.padding(24.dp)); return }
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 120.dp)) {
        items(list, key = { it.id }) { x ->
            Row(Modifier.fillMaxWidth().clickable { onPick(x) }.padding(horizontal = 16.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
                Avatar(nm(x), x.avatarUrl, x.color, 46.dp)
                Spacer(Modifier.width(12.dp))
                Column {
                    Text(nm(x), color = p.text, fontWeight = FontWeight.Medium, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    if (x.username.isNotEmpty()) Text("@" + x.username, color = p.muted, fontSize = 14.sp)
                }
            }
        }
    }
}

private val AUDIO_EXT = setOf("mp3", "m4a", "wav", "flac", "ogg", "aac", "opus")

/** Вкладки «Файл» и «Звук» */
@Composable
fun FilesPanel(audio: Boolean, onPickFile: () -> Unit, onGallery: () -> Unit, onResend: (Message) -> Unit) {
    val p = P
    val recent = remember(audio) {
        AppModel.messages.values.flatten().filter { m ->
            m.kind == "file" && !m.deleted && !m.mediaUrl.isNullOrEmpty() && m.id > 0 &&
                (m.fileName.substringAfterLast('.', "").lowercase() in AUDIO_EXT) == audio
        }.sortedByDescending { it.createdAt }.distinctBy { it.mediaUrl }.take(30)
    }
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 120.dp)) {
        item {
            Column(Modifier.padding(horizontal = 14.dp).clip(RoundedCornerShape(22.dp)).background(p.panel)) {
                if (!audio) Row(Modifier.fillMaxWidth().clickable(onClick = onGallery).padding(horizontal = 18.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.PhotoLibrary, null, tint = p.a1); Spacer(Modifier.width(14.dp)); Text("Выбрать из Галереи", color = p.a1, fontSize = 19.sp)
                }
                Row(Modifier.fillMaxWidth().clickable(onClick = onPickFile).padding(horizontal = 18.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Folder, null, tint = p.a1); Spacer(Modifier.width(14.dp)); Text("Выбрать из файлов", color = p.a1, fontSize = 19.sp)
                }
            }
            Text(if (recent.isEmpty()) (if (audio) "Здесь появятся аудиофайлы из ваших чатов" else "Здесь появятся файлы, которые вы отправляли")
                else if (audio) "ВАШИ ЧАТЫ" else "НЕДАВНО ОТПРАВЛЕННЫЕ",
                color = p.muted, fontSize = 14.sp, modifier = Modifier.padding(horizontal = 28.dp, vertical = 16.dp))
        }
        items(recent, key = { it.id }) { m ->
            Row(Modifier.fillMaxWidth().clickable { onResend(m) }.padding(horizontal = 16.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(48.dp).clip(CircleShape).background(p.a1), contentAlignment = Alignment.Center) {
                    Icon(if (audio) Icons.Filled.PlayArrow else Icons.Filled.Description, null, tint = Color.White)
                }
                Spacer(Modifier.width(12.dp))
                Column {
                    Text(m.fileName, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(listOfNotNull(m.fileSize?.let { Fmt.size(it) }, Fmt.day(m.createdAt)).joinToString(" · "), color = p.muted, fontSize = 14.sp)
                }
            }
        }
    }
}
