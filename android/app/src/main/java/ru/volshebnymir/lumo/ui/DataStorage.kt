package ru.volshebnymir.lumo.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ru.volshebnymir.lumo.core.*
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.sin

/** Фото в сообщении: с телефона; из сети — сразу или по нажатию (по настройкам автозагрузки) */
@Composable
fun AutoPhoto(src: String?, size: Long?, modifier: Modifier) {
    val ctx = LocalContext.current
    val remote = src?.startsWith("http") == true
    val cached = remember(src) {
        !remote || runCatching { coil.Coil.imageLoader(ctx).diskCache?.openSnapshot(src!!)?.use { true } ?: false }.getOrDefault(false)
    }
    var go by remember(src) { mutableStateOf(cached || AutoDownload.allow(DataKind.Photo, size)) }
    if (go) AsyncImage(src, null, modifier, contentScale = ContentScale.Crop)
    else Box(modifier.background(Color.White.copy(alpha = 0.06f)).clickable { go = true }, contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(48.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.45f)), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Download, null, tint = Color.White)
            }
            if (size != null) Text(Fmt.size(size), color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(top = 6.dp).clip(RoundedCornerShape(10.dp)).background(Color.Black.copy(alpha = 0.45f)).padding(horizontal = 8.dp, vertical = 2.dp))
        }
    }
}

/** Кольцевая диаграмма с долями на секторах */
@Composable
fun Donut(values: List<Pair<Long, Long>>, center: String, size: Dp = 220.dp) {
    val p = P
    val total = values.sumOf { it.first }.coerceAtLeast(1)
    Box(Modifier.fillMaxWidth().height(size), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(size)) {
            val w = this.size.minDimension * 0.25f
            val inset = w / 2
            val arc = Size(this.size.width - w, this.size.height - w)
            if (values.all { it.first <= 0 }) drawArc(p.line, 0f, 360f, false, Offset(inset, inset), arc, style = Stroke(w))
            var a = -90f
            values.filter { it.first > 0 }.forEach { (v, c) ->
                val sweep = v.toFloat() / total * 360f
                drawArc(Color(c), a + 0.6f, (sweep - 1.2f).coerceAtLeast(0.4f), false, Offset(inset, inset), arc, style = Stroke(w))
                a += sweep
            }
        }
        // подписи долей
        var acc = 0L
        values.filter { it.first > 0 }.forEach { (v, _) ->
            val frac = v.toDouble() / total
            val mid = (acc + v / 2.0) / total * 2 * Math.PI - Math.PI / 2
            acc += v
            if (frac > 0.045) {
                val r = size.value / 2 - size.value * 0.125f
                Text(pct(frac * 100), color = Color.White, fontWeight = FontWeight.Bold, fontSize = if (frac > 0.12) 14.sp else 10.sp,
                    modifier = Modifier.offset((cos(mid) * r).dp, (sin(mid) * r).dp))
            }
        }
        Text(center, color = p.text, fontWeight = FontWeight.Bold, fontSize = 24.sp)
    }
}

private fun pct(p: Double) = if (p >= 10) "${p.toInt()}%" else String.format(java.util.Locale.US, "%.1f%%", p)

@Composable
private fun Check(on: Boolean, color: Color) {
    val p = P
    Box(Modifier.size(24.dp).clip(CircleShape).background(if (on) color else Color.Transparent).border(1.6.dp, if (on) color else p.muted, CircleShape), contentAlignment = Alignment.Center) {
        if (on) Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(15.dp))
    }
}

/** «Данные и память» */
@Composable
fun DataStorageScreen() {
    val p = P
    var usage by remember { mutableStateOf<Long?>(null) }
    var confirm by remember { mutableStateOf(false) }
    val rev = NetStats.rev
    LaunchedEffect(Unit) { usage = withContext(Dispatchers.IO) { DeviceStorage.usage().values.sum() } }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        TopBar("Данные и память")
        Card {
            ValueRow(Icons.Filled.PieChart, Color(0xFFF4A73A), "Использование памяти", usage?.let { DeviceStorage.fmt(it) } ?: "…") { AppModel.push(Screen.StorageUsage) }
            Divider()
            key(rev) { ValueRow(Icons.Filled.BarChart, Color(0xFFA855F7), "Использование трафика", DeviceStorage.fmt(NetStats.total(null))) { AppModel.push(Screen.NetUsage) } }
        }
        SectionTitle("Автозагрузка медиа")
        Card {
            SettingsRow(Icons.Filled.SignalCellularAlt, Color(0xFF4CC764), "Через мобильную сеть", AutoDownload.cell.summary) { AppModel.push(Screen.AutoDl(true)) }
            Divider()
            SettingsRow(Icons.Filled.Wifi, Color(0xFF3D82F6), "Через Wi-Fi", AutoDownload.wifi.summary) { AppModel.push(Screen.AutoDl(false)) }
            Divider()
            Row(Modifier.fillMaxWidth().clickable(enabled = !AutoDownload.isDefault) { confirm = true }.padding(vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Restore, null, tint = if (AutoDownload.isDefault) p.muted else p.a1, modifier = Modifier.padding(start = 6.dp, end = 18.dp))
                Text("Сбросить настройки", color = if (AutoDownload.isDefault) p.muted else p.a1, fontSize = 16.sp)
            }
        }
        Text("Медиа меньше указанного размера скачиваются сами, остальное — по нажатию. Всё скачанное хранится на телефоне и открывается без интернета.",
            color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp))
        Spacer(Modifier.height(30.dp))
    }
    if (confirm) ConfirmDialog("Вернуть настройки автозагрузки по умолчанию?", "Сбросить", onDismiss = { confirm = false }) { AutoDownload.reset(); confirm = false }
}

@Composable
private fun ValueRow(icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color, title: String, value: String, onClick: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(color), contentAlignment = Alignment.Center) { Icon(icon, null, tint = Color.White, modifier = Modifier.size(19.dp)) }
        Text(title, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, modifier = Modifier.weight(1f))
        Text(value, color = p.muted, fontSize = 15.sp)
        Icon(Icons.Filled.ChevronRight, null, tint = p.muted)
    }
}

@Composable
fun ConfirmDialog(text: String, ok: String, onDismiss: () -> Unit, onOk: () -> Unit) {
    androidx.compose.material3.AlertDialog(onDismissRequest = onDismiss, text = { Text(text) },
        confirmButton = { androidx.compose.material3.TextButton(onClick = onOk) { Text(ok, color = P.danger) } },
        dismissButton = { androidx.compose.material3.TextButton(onClick = onDismiss) { Text("Отмена") } })
}

/** Использование памяти */
@Composable
fun StorageUsageScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var usage by remember { mutableStateOf<Map<DeviceStorage.Bucket, Long>>(emptyMap()) }
    var loaded by remember { mutableStateOf(false) }
    val selected = remember { mutableStateListOf(*DeviceStorage.Bucket.entries.toTypedArray()) }
    var clearing by remember { mutableStateOf(false) }
    var confirm by remember { mutableStateOf(false) }
    var keep by remember { mutableIntStateOf(DeviceStorage.keepDays) }
    var maxGb by remember { mutableIntStateOf(DeviceStorage.maxGb) }
    suspend fun reload() { usage = withContext(Dispatchers.IO) { DeviceStorage.usage() }; loaded = true }
    LaunchedEffect(Unit) { reload() }
    val order = DeviceStorage.Bucket.entries.sortedByDescending { usage[it] ?: 0L }
    val total = usage.values.sum()
    val chosen = selected.sumOf { usage[it] ?: 0L }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        TopBar("")
        Donut(order.map { (usage[it] ?: 0L) to it.color }, if (loaded) DeviceStorage.fmt(total) else "…")
        Text("Использование памяти", color = p.text, fontWeight = FontWeight.Bold, fontSize = 22.sp)
        val free = DeviceStorage.freeSpace
        val share = if (free > 0) total.toDouble() / (free + total) else 0.0
        Text("Lumo занимает ${if (share * 100 < 1) String.format(java.util.Locale.US, "%.1f", share * 100) else (share * 100).toInt().toString()}% свободного места на устройстве.",
            color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 30.dp))
        Box(Modifier.padding(horizontal = 60.dp).fillMaxWidth().height(6.dp).clip(CircleShape).background(p.a1.copy(alpha = 0.18f))) {
            Box(Modifier.fillMaxWidth(share.toFloat().coerceIn(0.02f, 1f)).fillMaxHeight().clip(CircleShape).background(p.a1))
        }
        Card {
            order.forEachIndexed { i, b ->
                val v = usage[b] ?: 0L
                Row(Modifier.fillMaxWidth().clickable { if (b in selected) selected.remove(b) else selected.add(b) }.padding(vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                    Check(b in selected, Color(b.color))
                    Text(b.title, color = p.text, fontSize = 16.sp, modifier = Modifier.padding(start = 14.dp))
                    if (total > 0 && v > 0) Text("  " + pct(v * 100.0 / total), color = p.muted, fontSize = 16.sp)
                    Spacer(Modifier.weight(1f))
                    Text(DeviceStorage.fmt(v), color = p.muted, fontSize = 15.sp)
                }
                if (i < order.size - 1) Divider()
            }
            Box(Modifier.padding(vertical = 10.dp).fillMaxWidth().height(52.dp).clip(CircleShape).background(androidx.compose.ui.graphics.Brush.horizontalGradient(listOf(p.a1, p.a2)))
                .clickable(enabled = chosen > 0 && !clearing) { confirm = true }, contentAlignment = Alignment.Center) {
                Text((if (selected.size == DeviceStorage.Bucket.entries.size) "Очистить весь кэш  " else "Очистить выбранное  ") + DeviceStorage.fmt(chosen),
                    color = Color.White.copy(alpha = if (chosen > 0) 1f else 0.5f), fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            }
        }
        Text("Все фото, видео, файлы и голосовые хранятся в облаке Lumo — после очистки их можно скачать снова.",
            color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp))
        SectionTitle("Хранить медиа")
        Card { Segments(listOf(3 to "3 дня", 7 to "1 неделю", 30 to "1 месяц", 0 to "Всегда"), keep) { keep = it; DeviceStorage.keepDays = it; scope.launch { withContext(Dispatchers.IO) { DeviceStorage.trim() }; reload() } } }
        SectionTitle("Максимальный размер кэша")
        Card { Segments(listOf(1 to "1 ГБ", 5 to "5 ГБ", 20 to "20 ГБ", 0 to "Нет"), maxGb) { maxGb = it; DeviceStorage.maxGb = it; scope.launch { withContext(Dispatchers.IO) { DeviceStorage.trim() }; reload() } } }
        Text("Медиа, которые давно не открывали, удаляются сами — чтобы Lumo не занимал лишнее место.",
            color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp))
        Spacer(Modifier.height(40.dp))
    }
    if (confirm) ConfirmDialog("Очистить ${DeviceStorage.fmt(chosen)}?", "Очистить", onDismiss = { confirm = false }) {
        confirm = false; clearing = true
        val sel = selected.toSet()
        scope.launch { withContext(Dispatchers.IO) { DeviceStorage.clear(sel) }; reload(); clearing = false; AppModel.say("Кэш очищен") }
    }
}

@Composable
private fun <T> Segments(items: List<Pair<T, String>>, value: T, onPick: (T) -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp).clip(RoundedCornerShape(12.dp)).background(p.panel2).padding(3.dp)) {
        items.forEach { (v, t) ->
            Box(Modifier.weight(1f).clip(RoundedCornerShape(10.dp)).background(if (v == value) p.panel else Color.Transparent).clickable { onPick(v) }.padding(vertical = 8.dp), contentAlignment = Alignment.Center) {
                Text(t, color = p.text, fontSize = 13.5.sp, fontWeight = if (v == value) FontWeight.SemiBold else FontWeight.Normal, maxLines = 1)
            }
        }
    }
}

private fun kindIcon(k: DataKind) = when (k) {
    DataKind.Video -> Icons.Filled.Videocam; DataKind.Photo -> Icons.Filled.Image; DataKind.Messages -> Icons.Filled.ChatBubble
    DataKind.Sticker -> Icons.Filled.EmojiEmotions; DataKind.Voice -> Icons.Filled.Mic; DataKind.File -> Icons.Filled.Description
    DataKind.Music -> Icons.Filled.PlayCircle; DataKind.Calls -> Icons.Filled.Call
}

/** Использование трафика */
@Composable
fun NetUsageScreen() {
    val p = P
    var net by remember { mutableStateOf<String?>(null) }
    val open = remember { mutableStateListOf<DataKind>() }
    var confirm by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { NetStats.flush() }
    val rev = NetStats.rev
    key(rev, net) {
        val order = DataKind.entries.sortedByDescending { NetStats.total(it, net) }
        val total = NetStats.total(net)
        Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            TopBar("")
            Donut(order.map { NetStats.total(it, net) to it.color }, DeviceStorage.fmt(total))
            Text("Использование сети", color = p.text, fontWeight = FontWeight.Bold, fontSize = 22.sp)
            Text("Статистика использования сети с " + java.text.SimpleDateFormat("d MMM yyyy 'в' HH:mm", java.util.Locale("ru")).format(java.util.Date(NetStats.since)),
                color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 30.dp))
            Box(Modifier.padding(horizontal = 30.dp)) { Segments(listOf(null to "Весь", "cell" to "Мобильный", "wifi" to "Wi-Fi"), net) { net = it } }
            Card {
                order.forEachIndexed { i, k ->
                    val t = NetStats.total(k, net)
                    val rot by animateFloatAsState(if (k in open) 180f else 0f, label = "r")
                    Row(Modifier.fillMaxWidth().clickable { if (k in open) open.remove(k) else open.add(k) }.padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(30.dp).clip(RoundedCornerShape(8.dp)).background(Color(k.color)), contentAlignment = Alignment.Center) { Icon(kindIcon(k), null, tint = Color.White, modifier = Modifier.size(17.dp)) }
                        Text(k.title, color = p.text, fontSize = 16.sp, modifier = Modifier.padding(start = 14.dp))
                        if (total > 0 && t > 0) Text("  " + pct(t * 100.0 / total), color = p.muted, fontSize = 16.sp)
                        Spacer(Modifier.weight(1f))
                        Text(DeviceStorage.fmt(t), color = p.muted, fontSize = 15.sp)
                        Icon(Icons.Filled.ExpandMore, null, tint = p.muted, modifier = Modifier.rotate(rot))
                    }
                    AnimatedVisibility(k in open) {
                        Column(Modifier.padding(start = 44.dp, bottom = 8.dp)) {
                            Row { Text("Отправлено", color = p.muted, fontSize = 14.sp, modifier = Modifier.weight(1f)); Text(DeviceStorage.fmt(NetStats.sent(k, net)), color = p.muted, fontSize = 14.sp) }
                            Row { Text("Получено", color = p.muted, fontSize = 14.sp, modifier = Modifier.weight(1f)); Text(DeviceStorage.fmt(NetStats.recv(k, net)), color = p.muted, fontSize = 14.sp) }
                        }
                    }
                    if (i < order.size - 1) Divider()
                }
            }
            Text("При нажатии на строку появится подробная статистика: сколько отправлено и сколько получено.",
                color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp))
            Card {
                Box(Modifier.fillMaxWidth().clickable { confirm = true }.padding(vertical = 14.dp), contentAlignment = Alignment.Center) {
                    Text("Сбросить статистику", color = p.danger, fontSize = 16.sp)
                }
            }
            Spacer(Modifier.height(40.dp))
        }
    }
    if (confirm) ConfirmDialog("Сбросить статистику трафика?", "Сбросить", onDismiss = { confirm = false }) { NetStats.reset(); confirm = false }
}

/** Автозагрузка для мобильной сети или Wi-Fi */
@Composable
fun AutoDlScreen(cellular: Boolean) {
    val p = P
    val s = if (cellular) AutoDownload.cell else AutoDownload.wifi
    fun upd(v: AutoDl) = AutoDownload.set(cellular, v)
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        TopBar(if (cellular) "Мобильная сеть" else "Wi-Fi")
        Card { ToggleRow(if (cellular) Icons.Filled.SignalCellularAlt else Icons.Filled.Wifi, Color(if (cellular) 0xFF4CC764 else 0xFF3D82F6), "Автозагрузка медиа", null, s.enabled) { upd(s.copy(enabled = it)) } }
        SectionTitle("Типы медиа")
        Card(Modifier.then(if (s.enabled) Modifier else Modifier.background(Color.Transparent))) {
            ToggleRow(Icons.Filled.Image, Color(0xFF6CC3F5), "Фото", null, s.photos, s.enabled) { upd(s.copy(photos = it)) }
            Divider()
            ToggleRow(Icons.Filled.Videocam, Color(0xFF3D82F6), "Видео", "До " + AutoDl.mb(s.mediaMb), s.videos, s.enabled) { upd(s.copy(videos = it)) }
            if (s.videos && s.enabled) LimitSlider(s.mediaMb, 1.0, 200.0) { upd(s.copy(mediaMb = it)) }
            Divider()
            ToggleRow(Icons.Filled.Description, Color(0xFF4CC764), "Файлы", "До " + AutoDl.mb(s.filesMb), s.files, s.enabled) { upd(s.copy(files = it)) }
            if (s.files && s.enabled) LimitSlider(s.filesMb, 0.5, 100.0) { upd(s.copy(filesMb = it)) }
        }
        Text((if (cellular) "Работает, когда телефон в мобильной сети." else "Работает при подключении к Wi-Fi.") + " Голосовые и видеосообщения скачиваются всегда — они маленькие.",
            color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp))
    }
}

@Composable
private fun ToggleRow(icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color, title: String, sub: String?, on: Boolean, enabled: Boolean = true, onChange: (Boolean) -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(color.copy(alpha = if (enabled) 1f else 0.5f)), contentAlignment = Alignment.Center) { Icon(icon, null, tint = Color.White, modifier = Modifier.size(19.dp)) }
        Column(Modifier.weight(1f)) {
            Text(title, color = p.text.copy(alpha = if (enabled) 1f else 0.5f), fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            if (sub != null) Text(sub, color = p.muted, fontSize = 12.5.sp)
        }
        Switch(on, onChange, enabled = enabled, colors = SwitchDefaults.colors(checkedTrackColor = p.a1))
    }
}

@Composable
private fun LimitSlider(v: Double, lo: Double, hi: Double, onSet: (Double) -> Unit) {
    val p = P
    // шкала логарифмическая: маленькие значения настраиваются точнее
    val a = ln(lo); val b = ln(hi)
    var pos by remember(v) { mutableFloatStateOf(((ln(v.coerceIn(lo, hi)) - a) / (b - a)).toFloat()) }
    Row(Modifier.fillMaxWidth().padding(start = 48.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(AutoDl.mb(lo), color = p.muted, fontSize = 12.sp)
        Slider(pos, { pos = it }, Modifier.weight(1f).padding(horizontal = 8.dp), onValueChangeFinished = {
            val x = exp(a + pos * (b - a)); onSet(if (x >= 1) Math.round(x).toDouble() else Math.round(x * 10) / 10.0)
        }, colors = SliderDefaults.colors(thumbColor = p.a1, activeTrackColor = p.a1))
        Text(AutoDl.mb(hi), color = p.muted, fontSize = 12.sp)
    }
}
