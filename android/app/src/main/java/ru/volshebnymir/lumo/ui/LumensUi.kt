package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.*
import kotlin.math.cos
import kotlin.math.sin

/** Значок люмена: огранённый кристалл с четырёхлучевой искрой. Нарисован вручную, без эмодзи */
@Composable
fun LumenIcon(size: Dp = 20.dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size)) {
        val w = this.size.minDimension
        val c = Offset(w / 2, w / 2)
        val hex = Path().apply {
            for (i in 0 until 6) {
                val a = Math.toRadians(60.0 * i - 90.0)
                val x = c.x + cos(a).toFloat() * w * 0.48f; val y = c.y + sin(a).toFloat() * w * 0.48f
                if (i == 0) moveTo(x, y) else lineTo(x, y)
            }
            close()
        }
        drawPath(hex, Brush.linearGradient(listOf(Color(0xFFFFE08A), Color(0xFFFF9A3D), Color(0xFFFF5E8A)), start = Offset(0f, 0f), end = Offset(w, w)))
        drawPath(hex, Color.White.copy(alpha = 0.4f), style = Stroke(w * 0.045f, join = StrokeJoin.Round))
        val R = w * 0.29f; val r = w * 0.075f
        val star = Path().apply {
            for (i in 0 until 8) {
                val a = Math.toRadians(45.0 * i - 90.0)
                val rad = if (i % 2 == 0) R else r
                val x = c.x + cos(a).toFloat() * rad; val y = c.y + sin(a).toFloat() * rad
                if (i == 0) moveTo(x, y) else lineTo(x, y)
            }
            close()
        }
        drawPath(star, Color.White)
    }
}

private fun plr(n: Long, a: String, b: String, c: String): String {
    val m = n % 100
    return if (m in 11..14) c else when (n % 10) { 1L -> a; 2L, 3L, 4L -> b; else -> c }
}
fun lumenWord(n: Long) = plr(n, "люмен", "люмена", "люменов")

@Composable
fun WalletScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var rows by remember { mutableStateOf<List<LedgerRow>>(emptyList()) }
    var busy by remember { mutableStateOf(false) }
    suspend fun reload() {
        Lumens.load(); rows = Lumens.history()
        AppModel.loadProfiles(rows.mapNotNull { it.refUser })
    }
    LaunchedEffect(Unit) { reload() }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        TopBar("Люмены")
        Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(p.accent).padding(22.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            LumenIcon(72.dp)
            Spacer(Modifier.height(10.dp))
            Text(Lumens.balance.toString(), color = Color.White, fontSize = 46.sp, fontWeight = FontWeight.Black)
            Text(lumenWord(Lumens.balance), color = Color.White.copy(alpha = 0.85f), fontSize = 16.sp)
        }
        Column(Modifier.padding(horizontal = 14.dp)) {
            GradientButton(if (Lumens.canClaim) "Забрать ежедневный бонус" else "Бонус получен — загляните позже", busy, Lumens.canClaim) {
                busy = true
                scope.launch {
                    try { val n = Lumens.claim(); AppModel.say("Получено: $n ${lumenWord(n.toLong())}"); rows = Lumens.history() }
                    catch (e: Exception) { AppModel.say(e.message ?: "Ошибка") }
                    busy = false
                }
            }
            if (Lumens.streak > 0) Text("Серия: ${Lumens.streak} ${plr(Lumens.streak.toLong(), "день", "дня", "дней")} подряд. Чем длиннее серия, тем больше бонус — до 10 в день.",
                color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(top = 8.dp, start = 6.dp, end = 6.dp))
        }
        Card {
            SettingsRow(Icons.Filled.AddCard, Color(0xFF2BD67B), "Пополнить", "Покупка люменов — в разработке") { AppModel.say("Пополнение пока недоступно") }
            Divider()
            SettingsRow(Icons.Filled.Info, p.a1, "Как это работает", "Нажмите и удерживайте чужое сообщение и выберите «Отправить люмены». Автор получит их на свой счёт.") {}
        }
        Text("ИСТОРИЯ", color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 22.dp))
        if (rows.isEmpty()) Text("Пока пусто", color = p.muted, modifier = Modifier.padding(horizontal = 22.dp))
        else Card {
            rows.forEachIndexed { i, r ->
                if (i > 0) Divider()
                val who = r.refUser?.let { AppModel.displayName(it) } ?: ""
                Row(Modifier.fillMaxWidth().padding(vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(when (r.kind) { "daily" -> "Ежедневный бонус"; "tip_in" -> "От $who"; "tip_out" -> "Для $who"; "grant" -> "Начисление"; else -> "Операция" }, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                        Text(whenText(r.at), color = p.muted, fontSize = 12.5.sp)
                    }
                    Text((if (r.delta > 0) "+" else "") + r.delta, color = if (r.delta > 0) Color(0xFF2BD67B) else p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                    Spacer(Modifier.width(6.dp))
                    LumenIcon(18.dp)
                }
            }
        }
        Spacer(Modifier.height(30.dp))
    }
}

/** Отправить люмены за сообщение */
@Composable
fun TipDialog(m: Message, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var amount by remember { mutableStateOf(5) }
    var busy by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { Lumens.load() }
    AlertDialog(onDismissRequest = onClose,
        title = { Row(verticalAlignment = Alignment.CenterVertically) { LumenIcon(26.dp); Spacer(Modifier.width(8.dp)); Text("Отправить люмены") } },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Автору: " + AppModel.displayName(m.senderId), color = p.muted)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(1, 5, 10, 50, 100).forEach { n ->
                        Box(Modifier.clip(RoundedCornerShape(14.dp)).background(if (amount == n) p.accent else SolidColor(p.panel2)).clickable { amount = n }.padding(horizontal = 12.dp, vertical = 9.dp)) {
                            Text("$n", color = if (amount == n) Color.White else p.text, fontWeight = FontWeight.Bold)
                        }
                    }
                }
                Text("На вашем счёте: ${Lumens.balance} ${lumenWord(Lumens.balance)}", color = p.muted, fontSize = 13.sp)
            }
        },
        confirmButton = { TextButton({
            if (busy) return@TextButton
            busy = true
            scope.launch {
                try { Lumens.tip(m.id, amount); AppModel.say("Отправлено: $amount ${lumenWord(amount.toLong())}"); onClose() }
                catch (e: Exception) { AppModel.say(e.message ?: "Ошибка"); busy = false }
            }
        }) { Text("Отправить") } },
        dismissButton = { TextButton(onClose) { Text("Отмена") } })
}

/** Сумма люменов под сообщением */
@Composable
fun TipPill(m: Message, mine: Boolean) {
    val n = Lumens.tips[m.id] ?: 0L
    if (n <= 0) return
    val p = P
    Row(Modifier.padding(top = 3.dp).clip(RoundedCornerShape(14.dp)).background(if (mine) Color.White.copy(alpha = 0.2f) else p.panel).padding(horizontal = 8.dp, vertical = 3.dp), verticalAlignment = Alignment.CenterVertically) {
        LumenIcon(15.dp)
        Text(" $n", color = if (mine) Color.White else p.text, fontSize = 13.sp, fontWeight = FontWeight.Bold)
    }
}

/** Комментарии к посту канала: сообщения привязанной группы */
@Composable
fun CommentsScreen(chatId: String, postId: Int) {
    val p = P
    val scope = rememberCoroutineScope()
    var list by remember { mutableStateOf<List<Message>>(emptyList()) }
    var text by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var loaded by remember { mutableStateOf(false) }
    val post = AppModel.findMessage(postId, chatId)
    val state = rememberLazyListState()
    suspend fun reload() {
        val a = runCatching { Api.rpc("lm_comments", jsonOf("p_post" to postId)) as? org.json.JSONArray }.getOrNull().objects()
        list = a.map { Message.from(it) }
        AppModel.loadProfiles(list.mapNotNull { it.senderId })
        loaded = true
    }
    LaunchedEffect(postId) { while (true) { reload(); delay(4000) } }
    LaunchedEffect(list.size) { if (list.isNotEmpty()) state.animateScrollToItem(list.size - 1) }
    DisposableEffect(Unit) { onDispose { Lumens.refreshComments(postId) } }
    Column(Modifier.fillMaxSize().background(p.bg).imePadding()) {
        TopBar(if (list.isEmpty()) "Комментарии" else "${list.size} ${plr(list.size.toLong(), "комментарий", "комментария", "комментариев")}")
        post?.let {
            Box(Modifier.padding(horizontal = 14.dp, vertical = 4.dp).fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel).padding(12.dp)) {
                Text(it.preview, color = p.muted, maxLines = 3, fontSize = 14.sp)
            }
        }
        LazyColumn(Modifier.weight(1f).fillMaxWidth(), state = state, contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (loaded && list.isEmpty()) item { Text("Комментариев пока нет. Напишите первый.", color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp)) }
            items(list, key = { it.id }) { c ->
                val pr = c.senderId?.let { AppModel.profiles[it] }
                Row(verticalAlignment = Alignment.Top) {
                    Avatar(AppModel.displayName(c.senderId), pr?.avatarUrl, pr?.color ?: 0, 36.dp)
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.clip(RoundedCornerShape(16.dp)).background(p.bubble).padding(horizontal = 12.dp, vertical = 8.dp)) {
                        Text(AppModel.displayName(c.senderId), color = p.nameColor(pr?.color ?: 0), fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        RichText(c.body ?: "", p.text, false)
                        Text(Fmt.clock(c.createdAt), color = p.muted, fontSize = 11.sp, modifier = Modifier.align(Alignment.End))
                    }
                }
            }
        }
        Row(Modifier.fillMaxWidth().navigationBarsPadding().padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.weight(1f).clip(RoundedCornerShape(22.dp)).background(p.panel2).padding(horizontal = 16.dp, vertical = 12.dp)) {
                if (text.isEmpty()) Text("Комментарий", color = p.muted)
                BasicTextField(text, { text = it.take(2000) }, textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1), maxLines = 5, modifier = Modifier.fillMaxWidth())
            }
            Spacer(Modifier.width(8.dp))
            Box(Modifier.size(46.dp).clip(CircleShape).background(if (text.isBlank()) SolidColor(p.panel2) else p.accent).bouncy {
                if (text.isBlank() || busy) return@bouncy
                busy = true; val t = text
                scope.launch {
                    try { Api.rpc("lm_comment_add", jsonOf("p_post" to postId, "p_body" to t)); text = ""; reload() }
                    catch (e: Exception) { AppModel.say(e.message ?: "Ошибка") }
                    busy = false
                }
            }, contentAlignment = Alignment.Center) { Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White) }
        }
    }
}

fun lumenCommentWord(n: Int) = plr(n.toLong(), "комментарий", "комментария", "комментариев")
