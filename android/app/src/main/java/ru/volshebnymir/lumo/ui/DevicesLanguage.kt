package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class DeviceSession(val id: String, val deviceId: String, val name: String, val platform: String, val version: String, val lastActive: Date?)

private fun platformTitle(p: String) = when (p) { "ios" -> "iPhone / iPad"; "android" -> "Android"; "windows" -> "Windows"; else -> "Сайт" }
private fun platformIcon(p: String) = when (p) { "ios", "android" -> Icons.Filled.Smartphone; "windows" -> Icons.Filled.DesktopWindows; else -> Icons.Filled.Language }

private fun whenText(d: Date?): String {
    if (d == null) return ""
    if (System.currentTimeMillis() - d.time < 120_000) return Lang.tr("онлайн")
    val today = SimpleDateFormat("yyyyMMdd", Locale.US).let { it.format(d) == it.format(Date()) }
    val loc = Locale(if (Lang.code == "tt") "tt" else Lang.code)
    return if (today) Lang.tr("сегодня в HH:mm").replace("HH:mm", SimpleDateFormat("HH:mm", loc).format(d))
    else SimpleDateFormat("d MMM, HH:mm", loc).format(d)
}

@Composable
fun DevicesScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var items by remember { mutableStateOf<List<DeviceSession>>(emptyList()) }
    var loaded by remember { mutableStateOf(false) }
    var confirmAll by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { AppModel.touchSession(); items = AppModel.loadSessions(); loaded = true }
    val me = AppModel.deviceId
    val current = items.firstOrNull { it.deviceId == me }
    val others = items.filter { it.deviceId != me }

    @Composable
    fun Row1(d: DeviceSession, isCurrent: Boolean) {
        Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(Modifier.size(40.dp).clip(RoundedCornerShape(12.dp)).background(if (isCurrent) Color(0xFF2BD67B) else p.a1), contentAlignment = Alignment.Center) {
                Icon(platformIcon(d.platform), null, tint = Color.White, modifier = Modifier.size(22.dp))
            }
            Column(Modifier.weight(1f)) {
                Text(d.name, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, maxLines = 1)
                Text("Lumo ${d.version} · ${Lang.tr(platformTitle(d.platform))} · ${whenText(d.lastActive)}", color = p.muted, fontSize = 12.5.sp, maxLines = 2)
            }
            if (!isCurrent) {
                Text("Завершить", color = p.danger, fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                    modifier = Modifier.clip(RoundedCornerShape(10.dp)).clickable { scope.launch { AppModel.endSession(d.id); items = AppModel.loadSessions() } }.padding(8.dp))
            }
        }
    }

    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState())) {
        TopBar("Устройства")
        Spacer(Modifier.height(8.dp))
        Text("Это устройство".uppercase(), color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 24.dp, vertical = 4.dp))
        Card {
            Row1(current ?: DeviceSession("", me, AppModel.deviceName, "android", "", Date()), true)
        }
        if (others.isNotEmpty()) {
            Spacer(Modifier.height(10.dp))
            Box(Modifier.padding(horizontal = 16.dp).fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel2).clickable { confirmAll = true }.padding(vertical = 13.dp), contentAlignment = Alignment.Center) {
                Text("Завершить все другие сеансы", color = p.danger, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            }
            Spacer(Modifier.height(6.dp))
            Text("Активные сеансы".uppercase(), color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 24.dp, vertical = 4.dp))
            Card {
                others.forEachIndexed { i, d -> if (i > 0) Divider(); Row1(d, false) }
            }
        } else if (loaded) {
            Text("Других активных сеансов нет.", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp))
        }
        Text("Здесь видны устройства, на которых вы вошли в Lumo через приложения для iPhone и Android. Если не узнаёте устройство — завершите сеанс. Вход через сайт и Windows пока в списке не отображается.",
            color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 10.dp))
    }
    if (confirmAll) {
        AlertDialog(onDismissRequest = { confirmAll = false },
            title = { Text("Завершить все другие сеансы?") },
            confirmButton = { TextButton({ confirmAll = false; scope.launch { others.forEach { AppModel.endSession(it.id) }; items = AppModel.loadSessions() } }) { Text("Завершить", color = p.danger) } },
            dismissButton = { TextButton({ confirmAll = false }) { Text("Отмена") } })
    }
}

@Composable
fun LanguageScreen() {
    val p = P
    val ctx = androidx.compose.ui.platform.LocalContext.current
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState())) {
        TopBar("Язык")
        Spacer(Modifier.height(8.dp))
        Card {
            Lang.all.forEachIndexed { i, l ->
                if (i > 0) Divider()
                Row(Modifier.fillMaxWidth().clickable { Lang.set(ctx, l.first) }.padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        androidx.compose.material3.Text(l.second, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                        androidx.compose.material3.Text(l.third, color = p.muted, fontSize = 12.5.sp)
                    }
                    if (Lang.code == l.first) Icon(Icons.Filled.Check, null, tint = p.a1)
                }
            }
        }
        Text("Язык интерфейса меняется сразу. Названия чатов и сообщения не переводятся. Часть подписей пока доступна только на русском.",
            color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 10.dp))
    }
}
