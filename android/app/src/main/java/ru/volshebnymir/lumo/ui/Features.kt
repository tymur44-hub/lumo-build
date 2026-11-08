package ru.volshebnymir.lumo.ui

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import ru.volshebnymir.lumo.core.*
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

private val RU = Locale("ru")
private val ORANGE = listOf(Color(0xFFFFB347), Color(0xFFFF6A3D))
private val VIOLET = listOf(Color(0xFF7C5CFF), Color(0xFF4F7CFF))
private val URGENT = listOf(Color(0xFFFFB020), Color(0xFFFF4D3D))

/** «сегодня в 20:00», «завтра в 09:00», «12 ноября в 10:00» */
fun futureText(d: Date): String {
    val c = Calendar.getInstance(); val t = Calendar.getInstance().apply { time = d }
    val hm = SimpleDateFormat("HH:mm", RU).format(d)
    fun same(a: Calendar, b: Calendar) = a.get(Calendar.YEAR) == b.get(Calendar.YEAR) && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
    if (same(c, t)) return "сегодня в $hm"
    c.add(Calendar.DAY_OF_YEAR, 1)
    if (same(c, t)) return "завтра в $hm"
    return SimpleDateFormat("d MMMM в HH:mm", RU).format(d)
}

fun fullDate(d: Date): String = SimpleDateFormat("d MMMM yyyy, HH:mm", RU).format(d)

// ================= Ответить позже =================

data class ReplyReminder(val id: Int, val chatId: String, val messageId: Int, val at: Date)

/** Напоминания «Ответить позже»: список на сервере, будильники — на телефоне */
object Reminders {
    val list = mutableStateListOf<ReplyReminder>()
    val previews = mutableStateMapOf<Int, Message>()

    suspend fun load() {
        val a = runCatching { Api.rpc("lm_remind_list") as? JSONArray }.getOrNull() ?: return
        val l = a.objects().mapNotNull { j ->
            val id = j.int("id"); val c = j.str("chat_id"); val m = j.int("message_id"); val at = j.date("remind_at")
            if (id == null || c == null || m == null || at == null) null else ReplyReminder(id, c, m, at)
        }
        list.clear(); list.addAll(l)
        loadPreviews()
        schedule()
    }

    private suspend fun loadPreviews() {
        val need = list.map { it.messageId }.filter { !previews.containsKey(it) }
        if (need.isEmpty()) return
        val rows = runCatching { Api.select("lm_messages", mapOf("select" to "*", "id" to "in.(" + need.joinToString(",") + ")")) }.getOrNull() ?: return
        for (r in rows) {
            var m = Message.from(r)
            if (E2E.isEnc(m.body)) { AppModel.prep(m.chatId); m = m.copy(body = E2E.decrypt(m.chatId, m.body)) }
            previews[m.id] = m
            m.senderId?.let { AppModel.loadProfiles(listOf(it)) }
        }
    }

    suspend fun set(m: Message, at: Date) {
        try {
            Api.rpc("lm_remind_set", jsonOf("p_msg" to m.id, "p_at" to Dates.string(at)))
            previews[m.id] = m
            load()
            AppModel.say("Напомню " + futureText(at))
        } catch (e: Exception) { AppModel.say(e.message ?: "Не удалось") }
    }

    suspend fun remove(msgId: Int) {
        runCatching { Api.rpc("lm_remind_del", jsonOf("p_msg" to msgId)) }
        list.removeAll { it.messageId == msgId }
        schedule()
    }

    /** ответили в чате — сервер уже снял напоминания по нему */
    fun repliedIn(chatId: String) {
        if (list.none { it.chatId == chatId }) return
        list.removeAll { it.chatId == chatId }
        schedule()
    }

    private fun pi(ctx: Context, r: ReplyReminder?, msgId: Int): PendingIntent {
        val i = Intent(ctx, RemindReceiver::class.java).putExtra("msg", msgId)
        if (r != null) {
            val m = previews[r.messageId]
            val who = AppModel.displayName(m?.senderId)
            val text = m?.let { Message.previewText(it.kind, it.body) } ?: "Сообщение"
            i.putExtra("chat", r.chatId).putExtra("body", "Вы хотели ответить: $who — «${text.take(90)}»")
        }
        return PendingIntent.getBroadcast(ctx, 40_000 + (msgId % 1_000_000), i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    /** будильники на время напоминаний; снятые — отменяем */
    fun schedule() {
        val ctx = AppModel.ctx
        val am = ctx.getSystemService(AlarmManager::class.java) ?: return
        val prefs = ctx.getSharedPreferences("lumo_remind", Context.MODE_PRIVATE)
        val old = prefs.getStringSet("ids", emptySet()) ?: emptySet()
        val now = System.currentTimeMillis()
        val keep = list.filter { it.at.time > now }
        for (s in old) { val id = s.toIntOrNull() ?: continue; if (keep.none { it.messageId == id }) am.cancel(pi(ctx, null, id)) }
        for (r in keep) runCatching { am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, r.at.time, pi(ctx, r, r.messageId)) }
        prefs.edit().putStringSet("ids", keep.map { it.messageId.toString() }.toSet()).apply()
    }
}

/** Будильник «Ответить позже» сработал — показываем уведомление */
class RemindReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val chat = intent.getStringExtra("chat") ?: return
        val msg = intent.getIntExtra("msg", 0)
        Notifier.remind(context, msg, "Ответить позже", intent.getStringExtra("body") ?: "Вы хотели ответить на сообщение", chat)
    }
}

@Composable
private fun IconBadge(icon: androidx.compose.ui.graphics.vector.ImageVector, colors: List<Color>, size: Int = 44) {
    Box(Modifier.size(size.dp).clip(CircleShape).background(Brush.linearGradient(colors)), contentAlignment = Alignment.Center) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size((size * 0.48f).dp))
    }
}

/** Выбор времени «Ответить позже» */
@Composable
fun RemindPickerDialog(m: Message, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val presets = remember {
        val out = ArrayList<Triple<String, androidx.compose.ui.graphics.vector.ImageVector, Date>>()
        val now = System.currentTimeMillis()
        out.add(Triple("Через час", Icons.Filled.Schedule, Date(now + 3_600_000)))
        val ev = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY, 20); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }
        if (ev.timeInMillis > now + 1_800_000) out.add(Triple("Сегодня вечером", Icons.Filled.NightsStay, ev.time))
        val mo = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1); set(Calendar.HOUR_OF_DAY, 9); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }
        out.add(Triple("Завтра утром", Icons.Filled.WbSunny, mo.time))
        val we = Calendar.getInstance().apply {
            while (get(Calendar.DAY_OF_WEEK) != Calendar.SATURDAY || timeInMillis < now + 3_600_000) add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 10); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0)
        }
        out.add(Triple("В выходные", Icons.Filled.LocalCafe, we.time))
        out
    }
    fun pick(d: Date) { onClose(); AppModel.scope.launch { Reminders.set(m, d) } }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.5f)).clickable(remember { MutableInteractionSource() }, null) { onClose() }, contentAlignment = Alignment.BottomCenter) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(topStart = 26.dp, topEnd = 26.dp)).background(p.bg)
                .clickable(remember { MutableInteractionSource() }, null) {}.navigationBarsPadding().padding(16.dp)) {
                Box(Modifier.align(Alignment.CenterHorizontally).size(40.dp, 5.dp).clip(CircleShape).background(p.line))
                Spacer(Modifier.height(14.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconBadge(Icons.Filled.NotificationsActive, ORANGE)
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text("Ответить позже", color = p.text, fontWeight = FontWeight.Bold, fontSize = 19.sp)
                        Text("Напомню и открою это сообщение", color = p.muted, fontSize = 14.sp)
                    }
                }
                Spacer(Modifier.height(12.dp))
                Text("«" + Message.previewText(m.kind, m.body).take(120) + "»", color = p.muted, fontSize = 14.sp, maxLines = 2, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(p.panel2).padding(12.dp))
                Spacer(Modifier.height(12.dp))
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel)) {
                    presets.forEachIndexed { i, (t, ic, d) ->
                        if (i > 0) Box(Modifier.padding(start = 56.dp).fillMaxWidth().height(1.dp).background(p.line))
                        Row(Modifier.fillMaxWidth().clickable { pick(d) }.padding(horizontal = 16.dp, vertical = 15.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(ic, null, tint = p.a1, modifier = Modifier.size(22.dp))
                            Spacer(Modifier.width(18.dp))
                            Text(t, color = p.text, fontSize = 17.sp, modifier = Modifier.weight(1f))
                            Text(futureText(d), color = p.muted, fontSize = 14.sp)
                        }
                    }
                    Box(Modifier.padding(start = 56.dp).fillMaxWidth().height(1.dp).background(p.line))
                    Row(Modifier.fillMaxWidth().clickable { pickDateTime(ctx) { d -> pick(d) } }.padding(horizontal = 16.dp, vertical = 15.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.CalendarMonth, null, tint = p.a1, modifier = Modifier.size(22.dp))
                        Spacer(Modifier.width(18.dp))
                        Text("Выбрать время", color = p.text, fontSize = 17.sp, modifier = Modifier.weight(1f))
                        Icon(Icons.Filled.ChevronRight, null, tint = p.muted)
                    }
                }
            }
        }
    }
}

/** Полоска «Ждут ответа · N» над чатами */
@Composable
fun RemindersBar() {
    val p = P
    if (Reminders.list.isEmpty()) return
    val first = Reminders.list.minByOrNull { it.at.time }
    Row(Modifier.padding(horizontal = 12.dp, vertical = 6.dp).fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel)
        .bouncy { AppModel.push(Screen.Reminders) }.padding(horizontal = 12.dp, vertical = 9.dp), verticalAlignment = Alignment.CenterVertically) {
        IconBadge(Icons.Filled.NotificationsActive, ORANGE, 34)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text("Ждут ответа · ${Reminders.list.size}", color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
            first?.let { Text("Ближайшее — " + futureText(it.at), color = p.muted, fontSize = 13.sp) }
        }
        Icon(Icons.Filled.ChevronRight, null, tint = p.muted)
    }
}

@Composable
fun RemindersScreen() {
    val p = P
    LaunchedEffect(Unit) { Reminders.load() }
    Column(Modifier.fillMaxSize().background(p.bg)) {
        TopBar("Ждут ответа")
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(14.dp)) {
            if (Reminders.list.isEmpty()) {
                Column(Modifier.fillMaxWidth().padding(top = 60.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Filled.CheckCircle, null, tint = p.a2, modifier = Modifier.size(48.dp))
                    Spacer(Modifier.height(10.dp))
                    Text("Вы на всё ответили", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
            }
            Reminders.list.sortedBy { it.at.time }.forEach { r ->
                val m = Reminders.previews[r.messageId]
                val c = AppModel.chat(r.chatId)
                Row(Modifier.padding(bottom = 10.dp).fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel)
                    .bouncy {
                        AppModel.pendingReply = r.chatId to r.messageId
                        AppModel.stack.clear(); AppModel.push(Screen.Chat(r.chatId))
                    }.padding(12.dp)) {
                    Avatar(c?.displayName ?: "", c?.displayAvatar, c?.displayColor ?: 0, 46.dp)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(c?.displayName ?: "Чат", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                            Text(futureText(r.at), color = if (r.at.before(Date())) Color(0xFFFF6A3D) else p.muted, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold)
                        }
                        if (m != null && c?.isPrivate == false) Text(AppModel.displayName(m.senderId), color = p.a2, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        Text(m?.let { Message.previewText(it.kind, it.body) } ?: "Сообщение", color = p.muted, fontSize = 14.5.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                    Icon(Icons.Filled.Close, "Убрать", tint = p.muted, modifier = Modifier.padding(start = 6.dp).size(20.dp).clip(CircleShape).clickable { AppModel.scope.launch { Reminders.remove(r.messageId) } })
                }
            }
        }
    }
}

// ================= Не беспокоить + Срочно =================

data class PeerDnd(val until: Date, val text: String?, val urgentOk: Boolean)

object Dnd {
    var until by mutableStateOf<Date?>(null)
    var text by mutableStateOf<String?>(null)
    var urgentFrom by mutableStateOf("contacts")
    val peers = mutableStateMapOf<String, PeerDnd>()
    var summary by mutableStateOf<String?>(null)

    val active: Boolean get() = until?.after(Date()) == true
    private val prefs get() = AppModel.ctx.getSharedPreferences("lumo_dnd", Context.MODE_PRIVATE)

    suspend fun load() {
        val j = runCatching { Api.rpc("lm_my_dnd") as? JSONObject }.getOrNull() ?: return
        until = j.date("until"); text = j.str("text"); urgentFrom = j.str("urgent") ?: "contacts"
        remember()
        checkEnded()
    }

    suspend fun set(u: Date?, t: String?, urgent: String): Boolean = try {
        Api.rpc("lm_set_dnd", jsonOf("p_until" to u?.let { Dates.string(it) }, "p_text" to (t ?: ""), "p_urgent" to urgent))
        val was = active
        until = u; text = t; urgentFrom = urgent
        if (u != null && !was) prefs.edit().putLong("from", System.currentTimeMillis()).apply()
        if (u == null && was) showSummary()
        remember()
        true
    } catch (e: Exception) { AppModel.say(e.message ?: "Не удалось"); false }

    private fun remember() {
        val u = until ?: return
        if (!u.after(Date())) return
        prefs.edit().putLong("until", u.time).apply()
        if (prefs.getLong("from", 0) == 0L) prefs.edit().putLong("from", System.currentTimeMillis()).apply()
        AppModel.scope.launch { delay(max(1000L, u.time - System.currentTimeMillis())); checkEnded() }
    }

    /** режим закончился — показываем итог «пока вас не было» */
    suspend fun checkEnded() {
        val u = prefs.getLong("until", 0)
        if (u == 0L || System.currentTimeMillis() < u || active) return
        showSummary()
    }

    private suspend fun showSummary() {
        val from = prefs.getLong("from", 0)
        prefs.edit().remove("until").remove("from").apply()
        if (from == 0L) return
        val j = runCatching { Api.rpc("lm_dnd_summary", jsonOf("p_from" to Dates.string(Date(from)), "p_to" to Dates.string(Date()))) as? JSONObject }.getOrNull() ?: return
        val n = j.optInt("msgs"); val c = j.optInt("chats"); val u2 = j.optInt("urgent")
        summary = if (n == 0) "Пока вы были в режиме «Не беспокоить», новых сообщений не было."
        else "$n ${plural(n, "сообщение", "сообщения", "сообщений")} в $c ${plural(c, "чате", "чатах", "чатах")}. " + (if (u2 == 0) "Срочных не было." else "Срочных: $u2.")
    }

    suspend fun loadPeers(ids: List<String>) {
        val l = ids.filter { it.isNotEmpty() && it != AppModel.myId }.distinct()
        if (l.isEmpty()) return
        val a = runCatching { Api.rpc("lm_dnd_get", jsonOf("p_ids" to JSONArray(l))) as? JSONArray }.getOrNull() ?: return
        val got = HashMap<String, PeerDnd>()
        for (j in a.objects()) { val id = j.str("id") ?: continue; val u = j.date("dnd_until") ?: continue; if (u.after(Date())) got[id] = PeerDnd(u, j.str("dnd_text"), j.bool("urgent_ok")) }
        for (id in l) { val g = got[id]; if (g != null) peers[id] = g else peers.remove(id) }
    }

    fun peer(id: String?): PeerDnd? = id?.let { peers[it] }?.takeIf { it.until.after(Date()) }

    suspend fun report(m: Message) {
        try { Api.rpc("lm_urgent_report", jsonOf("p_msg" to m.id)); AppModel.say("Понятно. Неделю этот человек не сможет отправлять вам срочные") }
        catch (e: Exception) { AppModel.say(e.message ?: "Не удалось") }
    }

    fun untilText(d: Date): String {
        val hm = SimpleDateFormat("HH:mm", RU).format(d)
        val f = futureText(d)
        return when {
            f.startsWith("сегодня") -> "до $hm"
            f.startsWith("завтра") -> "до завтра $hm"
            else -> "до " + SimpleDateFormat("d MMMM HH:mm", RU).format(d)
        }
    }

    fun peerLine(p: PeerDnd): String = (p.text?.takeIf { it.isNotBlank() } ?: "Не беспокоить") + " " + untilText(p.until) + " · без звука"

    private fun plural(n: Int, a: String, b: String, c: String): String {
        val m10 = n % 10; val m100 = n % 100
        return if (m10 == 1 && m100 != 11) a else if (m10 in 2..4 && (m100 < 10 || m100 >= 20)) b else c
    }
}

@Composable
private fun Chip(t: String, on: Boolean, modifier: Modifier = Modifier, colors: List<Color> = VIOLET, onClick: () -> Unit) {
    val p = P
    Box(modifier.height(42.dp).clip(RoundedCornerShape(13.dp)).background(if (on) Brush.linearGradient(colors) else SolidColor(p.panel)).bouncy(onClick).padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center) {
        Text(t, color = if (on) Color.White else p.text, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 1)
    }
}

@Composable
fun DndScreen() {
    val p = P
    var status by remember { mutableStateOf("😴 Сплю") }
    var custom by remember { mutableStateOf("") }
    var dur by remember { mutableStateOf(-1) }
    var urgent by remember { mutableStateOf(Dnd.urgentFrom) }
    var busy by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { Dnd.load(); urgent = Dnd.urgentFrom }
    val statuses = listOf("😴 Сплю", "📅 На встрече", "🚗 За рулём", "🎧 Занят", "✈️ В дороге", "✏️ Свой")
    val durations = listOf("1 час" to 1, "2 часа" to 2, "4 часа" to 4, "До утра" to -1, "До завтра" to 24)
    fun untilDate(): Date {
        if (dur == -1) {
            val c = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY, 8); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }
            if (c.timeInMillis <= System.currentTimeMillis()) c.add(Calendar.DAY_OF_YEAR, 1)
            return c.time
        }
        return Date(System.currentTimeMillis() + dur * 3_600_000L)
    }
    Column(Modifier.fillMaxSize().background(p.bg)) {
        TopBar("Не беспокоить")
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.padding(top = 6.dp).size(96.dp).clip(CircleShape).background(if (Dnd.active) Brush.linearGradient(listOf(Color(0xFF7C5CFF), Color(0xFF3A2A8A))) else SolidColor(p.panel2)),
                contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Bedtime, null, tint = if (Dnd.active) Color.White else p.muted, modifier = Modifier.size(42.dp))
            }
            Spacer(Modifier.height(12.dp))
            val u = Dnd.until
            if (Dnd.active && u != null) {
                Text((Dnd.text ?: "Не беспокоить") + " " + Dnd.untilText(u), color = p.text, fontWeight = FontWeight.Bold, fontSize = 20.sp, textAlign = TextAlign.Center)
                Text("Сообщения приходят без звука. Срочные — со звуком.", color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center)
                Spacer(Modifier.height(14.dp))
                Box(Modifier.fillMaxWidth().height(50.dp).clip(RoundedCornerShape(16.dp)).background(p.danger.copy(alpha = 0.12f))
                    .bouncy { if (!busy) { busy = true; AppModel.scope.launch { Dnd.set(null, Dnd.text, Dnd.urgentFrom); busy = false } } }, contentAlignment = Alignment.Center) {
                    Text("Выключить", color = p.danger, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
            } else {
                Text("Не беспокоить", color = p.text, fontWeight = FontWeight.Bold, fontSize = 22.sp)
                Text("Собеседники увидят ваш статус, а сообщения придут без звука. Если что-то правда важное — вам смогут написать срочно.",
                    color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 8.dp))
                Spacer(Modifier.height(16.dp))
                Text("СТАТУС", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(8.dp))
                statuses.chunked(2).forEach { row ->
                    Row(Modifier.fillMaxWidth().padding(bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        row.forEach { s -> Chip(s, status == s, Modifier.weight(1f)) { status = s } }
                    }
                }
                if (status == "✏️ Свой") {
                    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(p.panel2).padding(14.dp)) {
                        if (custom.isEmpty()) Text("Например: 🏋️ На тренировке", color = p.muted, fontSize = 16.sp)
                        BasicTextField(custom, { custom = it.take(40) }, singleLine = true, textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth())
                    }
                }
                Spacer(Modifier.height(10.dp))
                Text("НА СКОЛЬКО", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(8.dp))
                durations.chunked(3).forEach { row ->
                    Row(Modifier.fillMaxWidth().padding(bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        row.forEach { (t, v) -> Chip(t, dur == v, Modifier.weight(1f)) { dur = v } }
                        repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
                Text("Выключится " + Dnd.untilText(untilDate()).replace("до ", "в "), color = p.muted, fontSize = 13.sp, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(14.dp))
                Row(Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(Brush.linearGradient(VIOLET))
                    .bouncy {
                        if (busy) return@bouncy
                        val t = if (status == "✏️ Свой") custom.trim() else status
                        busy = true
                        AppModel.scope.launch { Dnd.set(untilDate(), t.ifEmpty { "Не беспокоить" }, urgent); busy = false }
                    }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                    Icon(Icons.Filled.Bedtime, null, tint = Color.White); Spacer(Modifier.width(8.dp))
                    Text("Включить", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
            }
            Spacer(Modifier.height(20.dp))
            Text("КТО МОЖЕТ НАПИСАТЬ СРОЧНО", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(8.dp))
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel)) {
                listOf("all" to "Все", "contacts" to "Только контакты", "none" to "Никто").forEachIndexed { i, (k, t) ->
                    if (i > 0) Box(Modifier.padding(start = 14.dp).fillMaxWidth().height(1.dp).background(p.line))
                    Row(Modifier.fillMaxWidth().clickable {
                        urgent = k
                        if (Dnd.active) AppModel.scope.launch { Dnd.set(Dnd.until, Dnd.text, k) }
                    }.padding(horizontal = 14.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(t, color = p.text, fontSize = 16.sp, modifier = Modifier.weight(1f))
                        if (urgent == k) Icon(Icons.Filled.Check, null, tint = p.a1, modifier = Modifier.size(20.dp))
                    }
                }
            }
            Text("⚡ Срочное сообщение приходит со звуком даже в этом режиме. Каждый может отправить вам не больше одного срочного в сутки. Если сообщение было не срочным — зажмите его и выберите «Это было не срочно»: человек на неделю потеряет эту возможность.",
                color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(top = 8.dp, bottom = 30.dp))
        }
    }
}

/** Итог после «Не беспокоить» — показывается поверх всего */
@Composable
fun DndSummaryDialog() {
    val s = Dnd.summary ?: return
    AlertDialog(onDismissRequest = { Dnd.summary = null }, title = { Text("Пока вас не было") }, text = { Text(s) },
        confirmButton = { TextButton({ Dnd.summary = null }) { Text("Хорошо") } })
}

@Composable
fun UrgentTag() {
    Row(Modifier.padding(bottom = 3.dp).clip(CircleShape).background(Brush.linearGradient(URGENT)).padding(horizontal = 8.dp, vertical = 3.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.Bolt, null, tint = Color.White, modifier = Modifier.size(12.dp))
        Spacer(Modifier.width(3.dp))
        Text("СРОЧНО", color = Color.White, fontWeight = FontWeight.Black, fontSize = 10.5.sp)
    }
}

// ================= Капсула времени =================

data class CapsuleContent(val kind: String, val text: String?, val image: String?)

object Capsules {
    val opened = mutableStateMapOf<Int, CapsuleContent>()
    val views = mutableStateMapOf<Int, Int>()

    /** содержимое: сервер отдаёт его только после даты открытия (автору — сразу) */
    suspend fun open(m: Message): String? = try {
        val j = Api.rpc("lm_capsule_open", jsonOf("p_msg" to m.id)) as? JSONObject ?: throw ApiError("Не удалось открыть", 0)
        val pl = j.optJSONObject("payload") ?: JSONObject()
        AppModel.prep(m.chatId)
        fun dec(s: String?): String? = if (s == null) null else if (E2E.isEnc(s)) (E2E.decrypt(m.chatId, s) ?: "🔒") else s
        opened[m.id] = CapsuleContent(pl.str("kind") ?: "text", dec(pl.str("text")), dec(pl.str("image")))
        views[m.id] = j.optInt("views")
        null
    } catch (e: Exception) { e.message ?: "Не удалось открыть" }

    suspend fun send(chatId: String, at: Date, text: String, image: ByteArray?, replyTo: Int?): Boolean = try {
        AppModel.prep(chatId)
        val pl = JSONObject().put("kind", if (image == null) "text" else "image")
        val t = text.trim()
        if (t.isNotEmpty()) pl.put("text", E2E.encrypt(chatId, t) ?: t)
        if (image != null) { val url = Api.upload(image, "jpg", "image/jpeg"); pl.put("image", E2E.encrypt(chatId, url) ?: url) }
        val params = jsonOf("p_chat" to chatId, "p_open_at" to Dates.string(at), "p_payload" to pl)
        if (replyTo != null) params.put("p_reply", replyTo)
        Api.rpc("lm_capsule_send", params)
        AppModel.loadMessages(chatId)
        true
    } catch (e: Exception) { AppModel.say(e.message ?: "Не удалось отправить"); false }

    fun countdown(to: Date, now: Long): String {
        val s = max(0L, (to.time - now) / 1000)
        val d = s / 86400; val h = (s % 86400) / 3600; val m = (s % 3600) / 60; val sec = s % 60
        return when { d > 0 -> "$d д $h ч $m мин"; h > 0 -> "$h ч $m мин $sec с"; else -> String.format(Locale.US, "%d:%02d", m, sec) }
    }
}

/** Конверт с восковой печатью */
@Composable
fun CapsuleEnvelope(modifier: Modifier, opened: Boolean = false, crack: Float = 0f) {
    Canvas(modifier) {
        val w = size.width; val h = size.height
        drawRoundRect(Brush.linearGradient(listOf(Color(0xFFF7E3C0), Color(0xFFE8C48C)), Offset.Zero, Offset(w, h)), Offset(0f, h * 0.12f), Size(w, h * 0.88f), CornerRadius(w * 0.07f))
        val low = Path().apply { moveTo(0f, h); lineTo(w * 0.5f, h * 0.58f); lineTo(w, h) }
        drawPath(low, Color(0xFFC9A36A).copy(alpha = 0.8f), style = Stroke(1.4f))
        val flap = Path().apply {
            if (opened) { moveTo(0f, h * 0.12f); lineTo(w * 0.5f, -h * 0.2f); lineTo(w, h * 0.12f) }
            else { moveTo(0f, h * 0.14f); lineTo(w * 0.5f, h * 0.62f); lineTo(w, h * 0.14f) }
            close()
        }
        drawPath(flap, Brush.verticalGradient(listOf(Color(0xFFF0D3A2), Color(0xFFDCB170))))
        drawPath(flap, Color(0xFFB8894A).copy(alpha = 0.7f), style = Stroke(1.2f))
        if (!opened) {
            val c = Offset(w * 0.5f, h * 0.6f); val r = w * 0.15f
            val seal = Path()
            for (i in 0 until 16) {
                val a = i / 16.0 * Math.PI * 2; val rr = r * (if (i % 2 == 0) 1f else 0.9f)
                val pt = Offset(c.x + (cos(a) * rr).toFloat(), c.y + (sin(a) * rr).toFloat())
                if (i == 0) seal.moveTo(pt.x, pt.y) else seal.lineTo(pt.x, pt.y)
            }
            seal.close()
            drawPath(seal, Brush.radialGradient(listOf(Color(0xFFFF5A6E), Color(0xFFB3122E)), Offset(c.x - r * 0.3f, c.y - r * 0.3f), r * 1.3f))
            drawCircle(Color.White.copy(alpha = 0.35f), r * 0.62f, c, style = Stroke(1.2f))
            val st = Path()
            for (i in 0 until 10) {
                val a = i / 10.0 * Math.PI * 2 - Math.PI / 2; val rr = r * (if (i % 2 == 0) 0.46f else 0.2f)
                val pt = Offset(c.x + (cos(a) * rr).toFloat(), c.y + (sin(a) * rr).toFloat())
                if (i == 0) st.moveTo(pt.x, pt.y) else st.lineTo(pt.x, pt.y)
            }
            st.close()
            drawPath(st, Color(0xFFFFD2D8).copy(alpha = 0.9f))
            if (crack > 0f) {
                val cr = Path().apply {
                    moveTo(c.x - r * 0.8f * crack, c.y - r * 0.2f); lineTo(c.x - r * 0.1f, c.y + r * 0.15f)
                    lineTo(c.x + r * 0.2f, c.y - r * 0.25f); lineTo(c.x + r * 0.85f * crack, c.y + r * 0.1f)
                }
                drawPath(cr, Color.White.copy(alpha = 0.9f), style = Stroke(2.2f))
            }
        }
    }
}

/** Сообщение-капсула в чате */
@Composable
fun CapsuleCard(m: Message, mine: Boolean, group: Boolean) {
    val openAt = m.meta.date("open_at") ?: m.createdAt
    var now by remember { mutableStateOf(System.currentTimeMillis()) }
    LaunchedEffect(m.id) { while (true) { now = System.currentTimeMillis(); delay(1000) } }
    val ready = now >= openAt.time
    val content = Capsules.opened[m.id]
    var opening by remember { mutableStateOf(false) }
    val crack = remember { Animatable(0f) }
    val shake = remember { Animatable(0f) }
    val burst = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    var full by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(m.id) { if (mine && Capsules.opened[m.id] == null) Capsules.open(m) }
    val brown = Color(0xFF3B2A14); val soft = Color(0xFF8A6A3E)
    Column(Modifier.width(250.dp).clip(RoundedCornerShape(20.dp))
        .background(Brush.verticalGradient(listOf(Color(0xFFFFF6E6), Color(0xFFFFE9C7))))
        .border(1.dp, Color(0xFFE8C48C), RoundedCornerShape(20.dp)).padding(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.HourglassTop, null, tint = Color(0xFFB07A2A), modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(5.dp))
            Text("КАПСУЛА ВРЕМЕНИ", color = Color(0xFFB07A2A), fontWeight = FontWeight.Black, fontSize = 11.5.sp, letterSpacing = 0.6.sp)
        }
        Spacer(Modifier.height(10.dp))
        if (content != null && (ready || mine)) {
            content.image?.let { u ->
                coil.compose.AsyncImage(u, null, contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxWidth().heightIn(max = 260.dp).clip(RoundedCornerShape(14.dp)).clickable { full = u })
                Spacer(Modifier.height(8.dp))
            }
            content.text?.takeIf { it.isNotEmpty() }?.let { Text(it, color = brown, fontSize = 16.sp) }
            Spacer(Modifier.height(6.dp))
            val v = Capsules.views[m.id] ?: 0
            Text(if (ready) "Открыта " + fullDate(openAt) + (if (group && v > 0) " · открыли: $v" else "") else "Откроется " + fullDate(openAt) + " · видно только вам",
                color = soft, fontSize = 12.sp)
        } else {
            Box(Modifier.fillMaxWidth().height(140.dp)
                .graphicsLayer { translationX = shake.value }
                .clickable(remember { MutableInteractionSource() }, null) {
                    if (!ready) {
                        scope.launch { for (x in listOf(14f, -12f, 9f, -6f, 3f, 0f)) shake.animateTo(x, tween(45)) }
                        AppModel.say("Ещё рано 🙂 Откроется " + fullDate(openAt))
                    } else if (!opening) {
                        opening = true
                        scope.launch {
                            crack.animateTo(1f, tween(350))
                            burst.animateTo(1f, spring(0.6f, 260f))
                            val err = Capsules.open(m)
                            delay(300)
                            burst.animateTo(0f, tween(400))
                            opening = false
                            if (err != null) { AppModel.say(err); crack.snapTo(0f) }
                        }
                    }
                }, contentAlignment = Alignment.Center) {
                CapsuleEnvelope(Modifier.size(210.dp, 140.dp), crack = crack.value)
                if (burst.value > 0f) {
                    for (i in 0 until 12) {
                        val a = i / 12.0 * Math.PI * 2
                        Text("✦", color = if (i % 2 == 0) Color(0xFFFFD24C) else Color(0xFFFF8AE3), fontSize = (12 + (i % 3) * 5).sp,
                            modifier = Modifier.graphicsLayer {
                                translationX = (cos(a) * 300 * burst.value).toFloat(); translationY = (sin(a) * 200 * burst.value).toFloat()
                                alpha = burst.value; scaleX = burst.value; scaleY = burst.value
                            })
                    }
                }
            }
            if (ready) Text(if (opening) "Открываем…" else "Нажмите, чтобы открыть", color = brown, fontWeight = FontWeight.Bold, fontSize = 15.sp)
            else {
                Text("Откроется через", color = soft, fontSize = 12.5.sp)
                Text(Capsules.countdown(openAt, now), color = brown, fontWeight = FontWeight.Black, fontSize = 20.sp)
                Text(fullDate(openAt), color = soft, fontSize = 12.sp)
            }
        }
        Text(Fmt.clock(m.createdAt), color = soft, fontSize = 11.5.sp, modifier = Modifier.align(Alignment.End))
    }
    full?.let { u ->
        Dialog(onDismissRequest = { full = null }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
            Box(Modifier.fillMaxSize().background(Color.Black).clickable { full = null }, contentAlignment = Alignment.Center) {
                coil.compose.AsyncImage(u, null, contentScale = ContentScale.Fit, modifier = Modifier.fillMaxSize())
            }
        }
    }
}

/** Плашка «капсула открылась» */
@Composable
fun CapsuleOpenPill(m: Message, onJump: (Int) -> Unit) {
    val mine = m.senderId == AppModel.myId
    Box(Modifier.fillMaxWidth().padding(vertical = 4.dp), contentAlignment = Alignment.Center) {
        Row(Modifier.clip(CircleShape).background(Brush.horizontalGradient(listOf(Color(0xFFFFF1D6), Color(0xFFFFE0B0))))
            .bouncy { m.meta.int("capsule")?.let(onJump) }.padding(horizontal = 12.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.CardGiftcard, null, tint = Color(0xFF8A5A1A), modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(6.dp))
            Text((if (mine) "Ваша капсула открылась" else AppModel.displayName(m.senderId) + ": капсула открылась") + " · посмотреть",
                color = Color(0xFF8A5A1A), fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
        }
    }
}

/** Создание капсулы */
@Composable
fun CapsuleComposeDialog(chatId: String, replyTo: Int?, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    var text by remember { mutableStateOf("") }
    var image by remember { mutableStateOf<Uri?>(null) }
    var busy by remember { mutableStateOf(false) }
    val presets = remember {
        val out = ArrayList<Pair<String, Date>>()
        out.add("Завтра" to Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1); set(Calendar.HOUR_OF_DAY, 9); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }.time)
        out.add("Через неделю" to Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 7) }.time)
        out.add("Через месяц" to Calendar.getInstance().apply { add(Calendar.MONTH, 1) }.time)
        out.add("Новый год" to Calendar.getInstance().apply { add(Calendar.YEAR, 1); set(Calendar.MONTH, Calendar.JANUARY); set(Calendar.DAY_OF_MONTH, 1); set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }.time)
        out.add("Через год" to Calendar.getInstance().apply { add(Calendar.YEAR, 1) }.time)
        out
    }
    var at by remember { mutableStateOf(presets[1].second) }
    var preset by remember { mutableStateOf(1) }
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u -> if (u != null) image = u }
    Dialog(onDismissRequest = { if (!busy) onClose() }, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Column(Modifier.fillMaxSize().background(p.bg).statusBarsPadding().navigationBarsPadding().imePadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                TextButton({ if (!busy) onClose() }) { Text("Отмена", color = p.a1, fontSize = 16.sp) }
            }
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                CapsuleEnvelope(Modifier.size(170.dp, 114.dp))
                Spacer(Modifier.height(12.dp))
                Text("Капсула времени", color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp)
                Text("Сообщение откроется только в выбранный момент. До этого собеседник увидит запечатанный конверт с обратным отсчётом.",
                    color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp))
                Box(Modifier.fillMaxWidth().heightIn(min = 110.dp).clip(RoundedCornerShape(16.dp)).background(p.panel).padding(14.dp)) {
                    if (text.isEmpty()) Text("Что вы хотите сказать в будущем?", color = p.muted, fontSize = 16.sp)
                    BasicTextField(text, { text = it.take(4000) }, textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth())
                }
                Spacer(Modifier.height(10.dp))
                val img = image
                if (img != null) {
                    Box {
                        coil.compose.AsyncImage(img, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(14.dp)))
                        Box(Modifier.align(Alignment.TopEnd).padding(8.dp).size(28.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.55f)).clickable { image = null }, contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Close, null, tint = Color.White, modifier = Modifier.size(16.dp))
                        }
                    }
                } else {
                    Row(Modifier.fillMaxWidth().height(44.dp).clip(RoundedCornerShape(14.dp)).background(p.a1.copy(alpha = 0.1f))
                        .bouncy { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                        Icon(Icons.Filled.AddPhotoAlternate, null, tint = p.a1); Spacer(Modifier.width(8.dp))
                        Text("Добавить фото", color = p.a1, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                    }
                }
                Spacer(Modifier.height(14.dp))
                Text("КОГДА ОТКРЫТЬ", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(8.dp))
                Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    presets.forEachIndexed { i, (t, d) -> Chip(t, preset == i, colors = ORANGE) { preset = i; at = d } }
                }
                Spacer(Modifier.height(8.dp))
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(p.panel).clickable { pickDateTime(ctx) { d -> at = d; preset = -1 } }
                    .padding(horizontal = 14.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.CalendarMonth, null, tint = p.a1, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(12.dp))
                    Text(fullDate(at), color = p.text, fontSize = 16.sp, modifier = Modifier.weight(1f))
                    Text("Изменить", color = p.a1, fontSize = 14.sp)
                }
                Spacer(Modifier.height(20.dp))
            }
            Row(Modifier.padding(16.dp).fillMaxWidth().height(54.dp).clip(RoundedCornerShape(18.dp))
                .background(Brush.linearGradient(listOf(Color(0xFFFF8A3D), Color(0xFFE8336A))))
                .bouncy {
                    if (busy) return@bouncy
                    if (text.isBlank() && image == null) { AppModel.say("Напишите что-нибудь или добавьте фото"); return@bouncy }
                    busy = true
                    AppModel.scope.launch {
                        val bytes = image?.let { u -> runCatching { compressJpeg(ctx, u) }.getOrNull() }
                        if (Capsules.send(chatId, at, text, bytes, replyTo)) onClose()
                        busy = false
                    }
                }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                if (busy) androidx.compose.material3.CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.5.dp)
                else {
                    Icon(Icons.Filled.Lock, null, tint = Color.White, modifier = Modifier.size(20.dp)); Spacer(Modifier.width(8.dp))
                    Text("Запечатать до " + fullDate(at), color = Color.White, fontWeight = FontWeight.Bold, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
    }
}

/** Фото для капсулы: уменьшаем до 1600 px и сжимаем в JPEG */
private fun compressJpeg(ctx: Context, u: Uri): ByteArray {
    val src = ctx.contentResolver.openInputStream(u)!!.use { android.graphics.BitmapFactory.decodeStream(it) }
    val k = 1600f / max(src.width, src.height).toFloat()
    val bmp = if (k < 1f) android.graphics.Bitmap.createScaledBitmap(src, (src.width * k).toInt(), (src.height * k).toInt(), true) else src
    val out = java.io.ByteArrayOutputStream()
    bmp.compress(android.graphics.Bitmap.CompressFormat.JPEG, 84, out)
    return out.toByteArray()
}

/** Шкатулка: все капсулы в моих чатах */
@Composable
fun CapsulesScreen() {
    val p = P
    var items by remember { mutableStateOf<List<JSONObject>?>(null) }
    LaunchedEffect(Unit) { items = (runCatching { Api.rpc("lm_capsule_list") as? JSONArray }.getOrNull()).objects() }
    Column(Modifier.fillMaxSize().background(p.bg)) {
        TopBar("Капсулы времени")
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(14.dp)) {
            val list = items
            if (list == null) Box(Modifier.fillMaxWidth().padding(40.dp), contentAlignment = Alignment.Center) { androidx.compose.material3.CircularProgressIndicator(color = p.a1) }
            else if (list.isEmpty()) {
                Column(Modifier.fillMaxWidth().padding(top = 50.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    CapsuleEnvelope(Modifier.size(150.dp, 100.dp))
                    Spacer(Modifier.height(12.dp))
                    Text("Капсул пока нет", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                    Text("Отправьте капсулу из меню вложений в любом чате — она откроется в выбранный день.", color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 30.dp, vertical = 6.dp))
                }
            } else {
                val sealed = list.filter { !it.bool("opened") }; val opened = list.filter { it.bool("opened") }.reversed()
                @Composable fun header(t: String) = Text(t, color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(start = 4.dp, top = 6.dp, bottom = 8.dp))
                @Composable fun row(j: JSONObject) {
                    val chatId = j.str("chat_id") ?: ""
                    val c = AppModel.chat(chatId)
                    val at = j.date("open_at") ?: Date()
                    val op = j.bool("opened"); val mine = j.bool("mine")
                    Row(Modifier.padding(bottom = 10.dp).fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel)
                        .bouncy {
                            AppModel.pendingJump = j.int("message_id")
                            AppModel.stack.clear(); AppModel.push(Screen.Chat(chatId))
                        }.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        CapsuleEnvelope(Modifier.size(54.dp, 38.dp), opened = op)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(if (mine) "Вы → " + (c?.displayName ?: "чат") else "От " + AppModel.displayName(j.str("sender_id")) + (if (c?.isPrivate == false) " · " + c.displayName else ""),
                                color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.5.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            Text((if (op) "Открыта " else "Откроется ") + fullDate(at), color = if (op) p.muted else Color(0xFFD08A2A), fontSize = 13.sp)
                        }
                        Icon(Icons.Filled.ChevronRight, null, tint = p.muted)
                    }
                }
                if (sealed.isNotEmpty()) { header("ЗАПЕЧАТАНЫ · ${sealed.size}"); sealed.forEach { row(it) } }
                if (opened.isNotEmpty()) { header("ОТКРЫТЫ · ${opened.size}"); opened.forEach { row(it) } }
            }
        }
    }
}

// ================= Серия (огонёк) =================

data class Streak(val chatId: String, val count: Int, val best: Int, val level: Int, val done: Boolean, val mine: Boolean, val peer: Boolean)

object Streaks {
    val map = mutableStateMapOf<String, Streak>()
    val levels = listOf(3, 10, 30, 100, 200)
    private var lastLoad = 0L

    suspend fun load(force: Boolean = true) {
        if (!force && System.currentTimeMillis() - lastLoad < 20_000) return
        lastLoad = System.currentTimeMillis()
        val a = runCatching { Api.rpc("lm_streaks") as? JSONArray }.getOrNull() ?: return
        val got = a.objects().mapNotNull { j ->
            val c = j.str("chat_id") ?: return@mapNotNull null
            Streak(c, j.optInt("count"), j.optInt("best"), j.optInt("level"), j.bool("done"), j.bool("mine"), j.bool("peer"))
        }.associateBy { it.chatId }
        map.keys.filter { it !in got }.forEach { map.remove(it) }
        map.putAll(got)
    }

    /** огонёк виден с 3 дней */
    fun of(chatId: String?): Streak? = chatId?.let { map[it] }?.takeIf { it.count >= 3 }

    fun colors(level: Int, lit: Boolean): List<Color> = if (!lit) listOf(Color(0xFFD9D9DE), Color(0xFF9EA0A8)) else when (level) {
        200 -> listOf(Color(0xFFFFE27A), Color(0xFFB45CFF), Color(0xFF5B2BFF))
        100 -> listOf(Color(0xFFB6F0FF), Color(0xFF3FA9FF), Color(0xFF2155FF))
        30 -> listOf(Color(0xFFFFD1F0), Color(0xFFFF4FA3), Color(0xFFE0145A))
        10 -> listOf(Color(0xFFFFE07A), Color(0xFFFF5A2A), Color(0xFFD9141E))
        else -> listOf(Color(0xFFFFE680), Color(0xFFFFA318), Color(0xFFFF6A00))
    }

    fun days(n: Int): String {
        val m10 = n % 10; val m100 = n % 100
        return if (m10 == 1 && m100 != 11) "день" else if (m10 in 2..4 && (m100 < 10 || m100 >= 20)) "дня" else "дней"
    }
}

/** Нарисованный огонёк: чем выше уровень — тем больше языков пламени */
@Composable
fun Flame(modifier: Modifier, level: Int, lit: Boolean) {
    val cs = Streaks.colors(level, lit)
    Canvas(modifier) {
        val w = size.width; val h = size.height
        val outer = Path().apply {
            moveTo(w * 0.5f, h * 0.98f)
            cubicTo(w * 0.12f, h * 0.98f, w * 0.02f, h * 0.62f, w * 0.2f, h * 0.38f)
            cubicTo(w * 0.24f, h * 0.52f, w * 0.32f, h * 0.56f, w * 0.36f, h * 0.55f)
            cubicTo(w * 0.3f, h * 0.3f, w * 0.44f, h * 0.1f, w * 0.6f, h * 0.02f)
            cubicTo(w * 0.58f, h * 0.22f, w * 0.7f, h * 0.3f, w * 0.78f, h * 0.4f)
            if (level >= 30 && lit) { cubicTo(w * 0.8f, h * 0.32f, w * 0.84f, h * 0.26f, w * 0.88f, h * 0.2f); cubicTo(w * 0.96f, h * 0.4f, w * 0.98f, h * 0.55f, w * 0.96f, h * 0.65f) }
            cubicTo(w * 1.0f, h * 0.84f, w * 0.82f, h * 0.98f, w * 0.5f, h * 0.98f)
            close()
        }
        drawPath(outer, Brush.verticalGradient(listOf(cs[1], cs.getOrElse(2) { cs[1] }), 0f, h))
        val inner = Path().apply {
            moveTo(w * 0.5f, h * 0.96f)
            cubicTo(w * 0.3f, h * 0.96f, w * 0.26f, h * 0.76f, w * 0.36f, h * 0.64f)
            cubicTo(w * 0.42f, h * 0.7f, w * 0.46f, h * 0.7f, w * 0.48f, h * 0.68f)
            cubicTo(w * 0.46f, h * 0.56f, w * 0.52f, h * 0.48f, w * 0.6f, h * 0.44f)
            cubicTo(w * 0.62f, h * 0.56f, w * 0.74f, h * 0.66f, w * 0.72f, h * 0.8f)
            cubicTo(w * 0.7f, h * 0.92f, w * 0.62f, h * 0.96f, w * 0.5f, h * 0.96f)
            close()
        }
        drawPath(inner, Brush.verticalGradient(listOf(cs[0].copy(alpha = 0.95f), Color.White.copy(alpha = if (lit) 0.9f else 0.6f)), h * 0.44f, h))
    }
}

/** 🔥 3 — рядом с именем в списке чатов и в шапке чата */
@Composable
fun StreakBadge(chatId: String?, size: Int = 15, onClick: (() -> Unit)? = null) {
    val s = Streaks.of(chatId) ?: return
    val p = P
    Row(Modifier.padding(start = 4.dp).then(if (onClick != null) Modifier.clip(CircleShape).clickable { onClick() } else Modifier),
        verticalAlignment = Alignment.CenterVertically) {
        Flame(Modifier.size((size * 0.85f).dp, size.dp), s.level, s.done)
        Text("${s.count}", color = if (s.done) Color(0xFFFF7A1A) else p.muted, fontWeight = FontWeight.Black, fontSize = (size - 1).sp, modifier = Modifier.padding(start = 1.dp))
    }
}

/** Окно серии (как в TikTok) */
@Composable
fun StreakSheet(chatId: String, onClose: () -> Unit) {
    val p = P
    val s = Streaks.map[chatId]
    val c = AppModel.chat(chatId)
    val me = AppModel.myId?.let { AppModel.profiles[it] }
    val count = s?.count ?: 0
    val lit = s?.done == true
    val bob = remember { Animatable(0f) }
    LaunchedEffect(Unit) { while (true) { bob.animateTo(1f, tween(900)); bob.animateTo(0f, tween(900)) } }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.5f)).clickable(remember { MutableInteractionSource() }, null) { onClose() }, contentAlignment = Alignment.BottomCenter) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(topStart = 30.dp, topEnd = 30.dp)).background(p.bg)
                .clickable(remember { MutableInteractionSource() }, null) {}.navigationBarsPadding().padding(horizontal = 22.dp, vertical = 18.dp),
                horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.fillMaxWidth()) {
                    Flame(Modifier.size(54.dp, 64.dp).graphicsLayer { translationY = -8f * bob.value; rotationZ = -8f + 16f * bob.value }, s?.level ?: 3, true)
                    Icon(Icons.Filled.Close, "Закрыть", tint = p.text, modifier = Modifier.align(Alignment.TopEnd).size(28.dp).clip(CircleShape).clickable { onClose() })
                }
                Box(Modifier.height(110.dp).width(190.dp)) {
                    Box(Modifier.align(Alignment.CenterStart).border(3.dp, p.bg, CircleShape)) { Avatar(AppModel.displayName(AppModel.myId), me?.avatarUrl, me?.color ?: 0, 104.dp) }
                    Box(Modifier.align(Alignment.CenterEnd).border(3.dp, p.bg, CircleShape)) { Avatar(c?.displayName ?: "", c?.displayAvatar, c?.displayColor ?: 0, 104.dp) }
                }
                Spacer(Modifier.height(18.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(if (count >= 3) "Ваша серия длится " else "Серия: ", color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp)
                    Flame(Modifier.size(22.dp, 26.dp), s?.level ?: 3, lit)
                    Text(" $count ${Streaks.days(count)}", color = if (lit) Color(0xFFFF7A1A) else p.muted, fontWeight = FontWeight.Black, fontSize = 24.sp)
                }
                Spacer(Modifier.height(14.dp))
                val todo = when {
                    s == null || count == 0 -> "Пишите друг другу каждый день — через 3 дня появится огонёк."
                    lit -> "Сегодня вы оба уже написали — огонёк горит. Возвращайтесь завтра!"
                    s.mine -> "Вы сегодня уже написали. Ждём ответа от ${c?.displayName ?: "собеседника"} — иначе серия погаснет в полночь."
                    s.peer -> "${c?.displayName ?: "Собеседник"} уже написал(а) сегодня. Ответьте до полуночи, чтобы серия продолжилась!"
                    else -> "Напишите друг другу сегодня до полуночи (по Москве), чтобы серия не погасла."
                }
                Column(Modifier.fillMaxWidth()) {
                    listOf("Серия растёт, когда вы оба пишете друг другу каждый день.", todo, "Продолжайте общаться, чтобы огонёк становился ярче!").forEach { t ->
                        Row(Modifier.padding(vertical = 4.dp)) {
                            Text("•", color = p.muted, fontSize = 16.sp, modifier = Modifier.padding(end = 8.dp))
                            Text(t, color = p.muted, fontSize = 16.sp)
                        }
                    }
                }
                Spacer(Modifier.height(20.dp))
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Streaks.levels.forEachIndexed { i, lv ->
                        if (i > 0) Box(Modifier.weight(1f).height(3.dp).clip(CircleShape).background(if (count >= lv) Color(0xFFFF9A3D) else p.line))
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Flame(Modifier.size(30.dp, 36.dp), lv, count >= lv)
                            Spacer(Modifier.height(4.dp))
                            Text("$lv д", color = if (count >= lv) p.text else p.muted, fontSize = 13.sp, fontWeight = if (count >= lv) FontWeight.Bold else FontWeight.Normal)
                        }
                    }
                }
                if ((s?.best ?: 0) > count) Text("Рекорд: ${s?.best} ${Streaks.days(s?.best ?: 0)}", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(top = 12.dp))
                Spacer(Modifier.height(20.dp))
                Box(Modifier.fillMaxWidth().height(54.dp).clip(CircleShape).background(Color(0xFFE8455A)).bouncy(onClose), contentAlignment = Alignment.Center) {
                    Text("Понятно", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                }
            }
        }
    }
}

/** просьба открыть клавиатуру в поле ввода (после «Ответить позже») */
object ComposerFocus { var tick by mutableStateOf(0) }

/** Полоска над полем ввода: собеседник в «Не беспокоить» + переключатель «Срочно» */
@Composable
fun UrgentStrip(name: String, d: PeerDnd, on: Boolean, onToggle: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().background(p.panel).padding(start = 14.dp, end = 10.dp, top = 8.dp, bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.Bedtime, null, tint = Color(0xFF8E7BFF), modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Column(Modifier.weight(1f)) {
            Text(name + ": " + (d.text?.takeIf { it.isNotBlank() } ?: "Не беспокоить") + " " + Dnd.untilText(d.until), color = p.text, fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(if (on) "Сообщение придёт со звуком — только если правда важно" else "Сообщения придут без звука", color = if (on) Color(0xFFFF7A1A) else p.muted, fontSize = 12.sp, maxLines = 1)
        }
        if (d.urgentOk) {
            Row(Modifier.clip(CircleShape).background(if (on) Brush.linearGradient(URGENT) else SolidColor(p.panel2)).bouncy(onToggle).padding(horizontal = 10.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Bolt, null, tint = if (on) Color.White else Color(0xFFFF7A1A), modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(3.dp))
                Text("Срочно", color = if (on) Color.White else p.text, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            }
        }
    }
}

/** Системное сообщение о серии */
@Composable
fun StreakSystemPill(m: Message) {
    var open by remember { mutableStateOf(false) }
    val n = m.meta.optInt("streak")
    val lost = m.meta.has("streak_lost")
    Box(Modifier.fillMaxWidth().padding(vertical = 6.dp), contentAlignment = Alignment.Center) {
        Row(Modifier.clip(CircleShape)
            .background(if (lost) Brush.horizontalGradient(listOf(Color(0xFFDADCE2), Color(0xFFC4C7CF))) else Brush.horizontalGradient(listOf(Color(0xFFFFE3B8), Color(0xFFFFC2A0))))
            .bouncy { open = true }.padding(horizontal = 14.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
            Flame(Modifier.size(15.dp, 18.dp), Streaks.levels.lastOrNull { it <= n } ?: 3, !lost)
            Spacer(Modifier.width(6.dp))
            Text((m.body ?: "").removePrefix("🔥 ").removePrefix("💨 "), color = if (lost) Color(0xFF55585F) else Color(0xFF8A3A0A), fontWeight = FontWeight.SemiBold, fontSize = 13.sp, textAlign = TextAlign.Center)
        }
    }
    if (open) StreakSheet(m.chatId) { open = false }
}
