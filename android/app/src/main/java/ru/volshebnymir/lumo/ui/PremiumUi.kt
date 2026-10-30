package ru.volshebnymir.lumo.ui

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import org.json.JSONObject
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.ChatItem
import ru.volshebnymir.lumo.core.PREMIUM_SOON
import ru.volshebnymir.lumo.core.Scheduled
import ru.volshebnymir.lumo.core.cancelScheduled
import ru.volshebnymir.lumo.core.channelStats
import ru.volshebnymir.lumo.core.chatTtl
import ru.volshebnymir.lumo.core.isPremium
import ru.volshebnymir.lumo.core.premium
import ru.volshebnymir.lumo.core.scheduledList
import ru.volshebnymir.lumo.core.setChatTtl
import ru.volshebnymir.lumo.core.setEmojiStatus
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

private val dtFmt = SimpleDateFormat("d MMM, HH:mm", Locale("ru"))

/** Сначала дата, потом время */
fun pickDateTime(ctx: Context, onPicked: (Date) -> Unit) {
    val now = Calendar.getInstance().apply { add(Calendar.HOUR_OF_DAY, 1) }
    DatePickerDialog(ctx, { _, y, m, d ->
        TimePickerDialog(ctx, { _, h, min ->
            val c = Calendar.getInstance().apply { set(y, m, d, h, min, 0) }
            if (c.timeInMillis < System.currentTimeMillis() + 15_000) AppModel.say("Выберите время в будущем") else onPicked(c.time)
        }, now.get(Calendar.HOUR_OF_DAY), now.get(Calendar.MINUTE), true).show()
    }, now.get(Calendar.YEAR), now.get(Calendar.MONTH), now.get(Calendar.DAY_OF_MONTH)).apply { datePicker.minDate = System.currentTimeMillis() - 1000 }.show()
}

/** Исчезающие сообщения и статистика канала в информации о чате */
@Composable
fun PremiumChatCard(c: ChatItem?) {
    if (c == null) return
    val p = P
    val scope = rememberCoroutineScope()
    val canTtl = !c.isChannel && !(c.isPrivate && (c.peerId == AppModel.myId || c.peerBot))
    val stats = c.isChannel && c.isAdmin
    if (!canTtl && !stats) return
    var ttl by remember { mutableStateOf(0) }
    var ttlDlg by remember { mutableStateOf(false) }
    var statsData by remember { mutableStateOf<JSONObject?>(null) }
    LaunchedEffect(c.id) { if (canTtl) ttl = AppModel.chatTtl(c.id) }
    Card {
        if (canTtl) SettingsRow(Icons.Filled.Timer, Color(0xFF2BD67B), "Исчезающие сообщения",
            when (ttl) { 3600 -> "1 час"; 86400 -> "1 день"; 604800 -> "1 неделя"; 2592000 -> "1 месяц"; else -> "Выключено" }) { ttlDlg = true }
        if (canTtl && stats) Divider()
        if (stats) SettingsRow(Icons.Filled.BarChart, Color(0xFF3A7BFF), "Статистика канала", "Подписчики и посты") {
            AppModel.premium { scope.launch { statsData = AppModel.channelStats(c.id) } }
        }
    }
    Spacer(Modifier.height(14.dp))
    if (ttlDlg) AlertDialog(onDismissRequest = { ttlDlg = false }, title = { Text("Исчезающие сообщения") },
        text = {
            Column {
                Text("Сообщения в этом чате будут удаляться у всех через выбранное время после отправки.", color = p.muted, fontSize = 14.sp)
                Spacer(Modifier.height(8.dp))
                listOf(0 to "Выключить", 3600 to "1 час", 86400 to "1 день", 604800 to "1 неделя", 2592000 to "1 месяц").forEach { (v, t) ->
                    Text(t, color = if (v == ttl) p.a1 else p.text, fontWeight = if (v == ttl) FontWeight.Bold else FontWeight.Normal, fontSize = 16.sp,
                        modifier = Modifier.fillMaxWidth().bouncy {
                            if (v > 0 && !AppModel.isPremium) { AppModel.say(PREMIUM_SOON); return@clickable }
                            scope.launch { if (AppModel.setChatTtl(c.id, v)) { ttl = v; ttlDlg = false } }
                        }.padding(vertical = 10.dp))
                }
            }
        }, confirmButton = { TextButton({ ttlDlg = false }) { Text("Закрыть") } })
    statsData?.let { d -> StatsDialog(d) { statsData = null } }
}

@Composable
private fun StatsDialog(d: JSONObject, onClose: () -> Unit) {
    val p = P
    val days = d.optJSONArray("days")
    val joined = (0 until (days?.length() ?: 0)).map { days!!.getJSONObject(it).optInt("joined") }
    val posts = (0 until (days?.length() ?: 0)).map { days!!.getJSONObject(it).optInt("posts") }
    val mx = maxOf(1, (joined + posts).maxOrNull() ?: 1)
    AlertDialog(onDismissRequest = onClose, title = { Text("Статистика канала") }, text = {
        Column {
            listOf("Подписчиков" to "subscribers", "Новых за 7 дней" to "joined_7d", "Новых за 30 дней" to "joined_30d", "Постов всего" to "posts", "Постов за 7 дней" to "posts_7d").forEach { (t, k) ->
                Row(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                    Text(t, color = p.muted, modifier = Modifier.weight(1f)); Text("${d.optInt(k)}", color = p.text, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(Modifier.height(10.dp))
            Text("Последние 14 дней: подписчики и посты", color = p.muted, fontSize = 12.sp)
            Row(Modifier.fillMaxWidth().height(80.dp), horizontalArrangement = Arrangement.spacedBy(3.dp), verticalAlignment = Alignment.Bottom) {
                joined.indices.forEach { i ->
                    Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(1.dp), verticalAlignment = Alignment.Bottom) {
                        Box(Modifier.weight(1f).height(maxOf(2, joined[i] * 78 / mx).dp).clip(RoundedCornerShape(2.dp)).background(p.accent))
                        Box(Modifier.weight(1f).height(maxOf(2, posts[i] * 78 / mx).dp).clip(RoundedCornerShape(2.dp)).background(Color(0xFF2BD67B)))
                    }
                }
            }
        }
    }, confirmButton = { TextButton(onClose) { Text("Готово") } })
}

/** Список отложенных сообщений чата */
@Composable
fun ScheduledDialog(chatId: String, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val items = remember { mutableStateListOf<Scheduled>() }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(chatId) { items.clear(); items.addAll(AppModel.scheduledList(chatId)); loaded = true }
    AlertDialog(onDismissRequest = onClose, title = { Text("Запланированные") }, text = {
        Column {
            if (loaded && items.isEmpty()) Text("Запланированных сообщений нет", color = p.muted)
            items.forEach { it ->
                Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(dtFmt.format(it.at), color = p.text, fontWeight = FontWeight.SemiBold)
                        Text(it.text, color = p.muted, fontSize = 14.sp, maxLines = 2)
                    }
                    Text("Отменить", color = p.danger, fontWeight = FontWeight.SemiBold, modifier = Modifier.bouncy {
                        scope.launch { AppModel.cancelScheduled(it.id); items.remove(it) }
                    }.padding(8.dp))
                }
            }
        }
    }, confirmButton = { TextButton(onClose) { Text("Готово") } })
}

/** Выбор смайлик-статуса */
@Composable
fun EmojiStatusDialog(onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val list = listOf("⭐", "🔥", "💎", "🚀", "🎧", "📚", "🌴", "☕", "🎮", "💼", "🛠", "🌙", "❤️", "🎯", "🍀", "✈️")
    AlertDialog(onDismissRequest = onClose, title = { Text("Смайлик-статус") }, text = {
        Column {
            Text("Смайлик показывается рядом с вашим именем в чатах и профиле.", color = p.muted, fontSize = 14.sp)
            Spacer(Modifier.height(10.dp))
            list.chunked(4).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    row.forEach { e -> Text(e, fontSize = 30.sp, modifier = Modifier.clip(RoundedCornerShape(12.dp)).bouncy { scope.launch { AppModel.setEmojiStatus(e); onClose() } }.padding(10.dp)) }
                }
            }
        }
    }, confirmButton = { TextButton({ scope.launch { AppModel.setEmojiStatus(""); onClose() } }) { Text("Убрать статус") } },
        dismissButton = { TextButton(onClose) { Text("Закрыть") } })
}
