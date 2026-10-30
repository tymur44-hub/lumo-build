package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.animateFloat
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.Slider
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
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
            SettingsRow(Icons.Filled.CardGiftcard, Color(0xFFFF5E8A), "Подарки", "NFT-подарки за люмены") { AppModel.push(Screen.Gifts) }
            Divider()
            SettingsRow(Icons.Filled.Info, p.a1, "Как это работает", "Откройте профиль человека и нажмите «Люмены», либо удерживайте его сообщение, либо нажмите на скрепку в личном чате.") {}
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

/** Живая иконка люмена: мерцающее свечение, покачивание и искры, которые разлетаются вокруг */
@Composable
fun LumenLive(size: Dp = 96.dp, modifier: Modifier = Modifier) {
    val tr = androidx.compose.animation.core.rememberInfiniteTransition(label = "lumen")
    val t by tr.animateFloat(0f, 1f, androidx.compose.animation.core.infiniteRepeatable(androidx.compose.animation.core.tween(3000, easing = androidx.compose.animation.core.LinearEasing)), label = "t")
    val pulse by tr.animateFloat(0.9f, 1.08f, androidx.compose.animation.core.infiniteRepeatable(androidx.compose.animation.core.tween(1600, easing = androidx.compose.animation.core.FastOutSlowInEasing), androidx.compose.animation.core.RepeatMode.Reverse), label = "p")
    val sway by tr.animateFloat(-9f, 9f, androidx.compose.animation.core.infiniteRepeatable(androidx.compose.animation.core.tween(2400, easing = androidx.compose.animation.core.FastOutSlowInEasing), androidx.compose.animation.core.RepeatMode.Reverse), label = "s")
    Box(modifier.size(size * 2.2f), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val c = center
            val R = this.size.minDimension / 2
            drawCircle(Brush.radialGradient(listOf(Color(0xFFFFB347).copy(alpha = 0.55f * pulse), Color.Transparent), center = c, radius = R * 0.9f * pulse), radius = R * 0.9f * pulse, center = c)
            for (i in 0 until 12) {
                val ph = (t + i / 12f) % 1f
                val ang = Math.toRadians(i * 30.0 + 360.0 * t * 0.25)
                val d = size.toPx() * (0.5f + 0.62f * ph)
                val a = (1f - ph).coerceIn(0f, 1f)
                val x = c.x + cos(ang).toFloat() * d; val y = c.y + sin(ang).toFloat() * d
                val r = (3.5f + 4f * (1 - ph)) * density
                val col = if (i % 2 == 0) Color(0xFFFFE08A) else Color(0xFFFF8FB5)
                drawLine(col.copy(alpha = a), Offset(x - r, y), Offset(x + r, y), 2.2f * density, androidx.compose.ui.graphics.StrokeCap.Round)
                drawLine(col.copy(alpha = a), Offset(x, y - r), Offset(x, y + r), 2.2f * density, androidx.compose.ui.graphics.StrokeCap.Round)
            }
        }
        LumenIcon(size, Modifier.graphicsLayer { rotationZ = sway; scaleX = pulse; scaleY = pulse })
    }
}

/** Стеклянная карточка в стиле «жидкого стекла» */
@Composable
fun GlassCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    val shape = RoundedCornerShape(34.dp)
    Column(
        modifier.clip(shape)
            .background(Brush.linearGradient(listOf(Color.White.copy(alpha = 0.22f), Color.White.copy(alpha = 0.07f), Color(0xFFB69CFF).copy(alpha = 0.14f))))
            .border(1.2.dp, Brush.linearGradient(listOf(Color.White.copy(alpha = 0.65f), Color.White.copy(alpha = 0.08f), Color.White.copy(alpha = 0.35f))), shape),
        content = content,
    )
}

/** Отправить люмены человеку (msgId — если это благодарность за конкретное сообщение) */
@Composable
fun LumenSendDialog(userId: String, msgId: Int? = null, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val owner = AppModel.staffRole == "owner"
    var amount by remember { mutableStateOf("5") }
    var busy by remember { mutableStateOf(false) }
    var done by remember { mutableStateOf(false) }
    val pr = AppModel.profiles[userId]
    LaunchedEffect(Unit) { Lumens.load() }
    val n = amount.toIntOrNull() ?: 0
    androidx.compose.ui.window.Dialog(onDismissRequest = { if (!busy) onClose() }, properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.55f)).clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) { if (!busy) onClose() }, contentAlignment = Alignment.Center) {
            Box(Modifier.padding(18.dp).widthIn(max = 380.dp).clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) {}) {
                // цветные пятна позади стекла
                Canvas(Modifier.matchParentSize().padding(0.dp)) {
                    drawCircle(Brush.radialGradient(listOf(Color(0xFFFF9A3D).copy(alpha = 0.45f), Color.Transparent), center = Offset(size.width * 0.15f, size.height * 0.1f), radius = size.width * 0.7f), center = Offset(size.width * 0.15f, size.height * 0.1f), radius = size.width * 0.7f)
                    drawCircle(Brush.radialGradient(listOf(Color(0xFF7C5CFF).copy(alpha = 0.5f), Color.Transparent), center = Offset(size.width * 0.9f, size.height * 0.85f), radius = size.width * 0.8f), center = Offset(size.width * 0.9f, size.height * 0.85f), radius = size.width * 0.8f)
                }
                GlassCard(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(horizontal = 22.dp, vertical = 14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        if (done) {
                            Spacer(Modifier.height(10.dp))
                            LumenLive(110.dp)
                            Text("Отправлено", color = Color.White, fontSize = 26.sp, fontWeight = FontWeight.Black)
                            Text("$n ${lumenWord(n.toLong())} для ${AppModel.displayName(userId)}", color = Color.White.copy(alpha = 0.8f), fontSize = 15.sp)
                            Spacer(Modifier.height(24.dp))
                            LaunchedEffect(Unit) { delay(1700); onClose() }
                        } else {
                            LumenLive(84.dp, Modifier.offset(y = (-6).dp))
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.offset(y = (-14).dp)) {
                                Avatar(AppModel.displayName(userId), pr?.avatarUrl, pr?.color ?: 0, 34.dp)
                                Spacer(Modifier.width(10.dp))
                                Column {
                                    Text("Получатель", color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp)
                                    Text(AppModel.displayName(userId), color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                                }
                            }
                            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(Color.White.copy(alpha = 0.12f)).border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(22.dp)).padding(vertical = 10.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                                BasicTextField(amount, { amount = it.filter { c -> c.isDigit() }.take(if (owner) 7 else 4) },
                                    textStyle = TextStyle(color = Color.White, fontSize = 44.sp, fontWeight = FontWeight.Black, textAlign = TextAlign.Center), cursorBrush = SolidColor(Color.White),
                                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = androidx.compose.ui.text.input.KeyboardType.Number), modifier = Modifier.widthIn(min = 60.dp, max = 200.dp))
                                Spacer(Modifier.width(8.dp))
                                LumenIcon(30.dp)
                            }
                            Spacer(Modifier.height(12.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                listOf(1, 5, 10, 50, 100, 500).forEach { v ->
                                    val on = n == v
                                    Box(Modifier.clip(RoundedCornerShape(16.dp)).background(if (on) Color.White.copy(alpha = 0.32f) else Color.White.copy(alpha = 0.1f))
                                        .border(1.dp, Color.White.copy(alpha = if (on) 0.7f else 0.25f), RoundedCornerShape(16.dp)).bouncy { amount = v.toString() }.padding(horizontal = 11.dp, vertical = 8.dp)) {
                                        Text("$v", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                    }
                                }
                            }
                            Spacer(Modifier.height(12.dp))
                            Text(if (owner) "Вы владелец: люмены начисляются без списания с вашего счёта" else "На вашем счёте: ${Lumens.balance} ${lumenWord(Lumens.balance)}",
                                color = Color.White.copy(alpha = 0.75f), fontSize = 13.sp, textAlign = TextAlign.Center)
                            Spacer(Modifier.height(14.dp))
                            Box(Modifier.fillMaxWidth().height(54.dp).clip(RoundedCornerShape(20.dp)).background(if (n > 0) p.accent else SolidColor(Color.White.copy(alpha = 0.15f)))
                                .border(1.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(20.dp)).bouncy {
                                    if (n <= 0 || busy) return@bouncy
                                    busy = true
                                    scope.launch {
                                        try {
                                            if (msgId != null) Lumens.tip(msgId, n) else Lumens.send(userId, n)
                                            done = true
                                        } catch (e: Exception) { AppModel.say(e.message ?: "Ошибка"); busy = false }
                                    }
                                }, contentAlignment = Alignment.Center) {
                                if (busy) androidx.compose.material3.CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.5.dp)
                                else Text("Отправить", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                            }
                            Spacer(Modifier.height(10.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TipDialog(m: Message, onClose: () -> Unit) {
    val id = m.senderId
    if (id == null) { onClose(); return }
    LumenSendDialog(id, m.id, onClose)
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


/** Люмены как реакция на пост канала (без имени получателя) */
@Composable
fun LumenReactDialog(m: Message, channel: String, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val owner = AppModel.staffRole == "owner"
    LaunchedEffect(Unit) { Lumens.load() }
    val maxV = if (owner) 1000 else minOf(1000L, Lumens.balance).toInt()
    var amount by remember { mutableStateOf(10f) }
    var busy by remember { mutableStateOf(false) }
    var done by remember { mutableStateOf(false) }
    val n = amount.coerceIn(1f, maxOf(1, maxV).toFloat()).toInt()
    AlertDialog(
        onDismissRequest = { if (!busy) onClose() }, containerColor = p.panel,
        title = { Text("Реакция люменами", color = p.text) },
        text = {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                if (done) {
                    LumenLive(90.dp)
                    Text("Отправлено", color = p.text, fontSize = 22.sp, fontWeight = FontWeight.Black)
                } else if (maxV < 1) {
                    LumenLive(80.dp)
                    Text("У вас пока нет люменов. Их можно получить в разделе «Мои люмены» в настройках.", color = p.muted, textAlign = TextAlign.Center)
                } else {
                    Row(Modifier.clip(RoundedCornerShape(20.dp)).background(Brush.verticalGradient(listOf(Color(0xFFFFB347), Color(0xFFF2994A)))).padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        LumenIcon(22.dp)
                        Text(" $n", color = Color.White, fontSize = 26.sp, fontWeight = FontWeight.Black)
                    }
                    if (maxV > 1) Slider(value = n.toFloat(), onValueChange = { amount = it }, valueRange = 1f..maxV.toFloat())
                    Text("Выберите количество люменов для отправки $channel в поддержку этой публикации.", color = p.text, textAlign = TextAlign.Center, fontSize = 15.sp)
                }
            }
        },
        confirmButton = {
            if (!done && maxV >= 1) TextButton(enabled = !busy, onClick = {
                busy = true
                scope.launch {
                    runCatching { Lumens.tip(m.id, n) }
                        .onSuccess { done = true; delay(1200); onClose() }
                        .onFailure { AppModel.say(it.message ?: "Ошибка"); busy = false }
                }
            }) { Text("Отправить $n") }
        },
        dismissButton = { TextButton({ onClose() }) { Text("Закрыть") } },
    )
}

/** Кнопка-реакция «люмены» под постом канала */
@Composable
fun LumenReactChip(m: Message, onClick: () -> Unit) {
    val p = P
    val n = Lumens.tips[m.id] ?: 0L
    Row(Modifier.padding(top = 3.dp).clip(RoundedCornerShape(16.dp)).background(Color(0xFFF5B04A).copy(alpha = 0.22f))
        .border(1.dp, Color(0xFFF5B04A).copy(alpha = 0.5f), RoundedCornerShape(16.dp)).bouncy(onClick).padding(horizontal = 10.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        LumenIcon(17.dp)
        if (n > 0) Text(" $n", color = p.text, fontSize = 13.sp, fontWeight = FontWeight.Bold)
    }
}

/** Кто прочитал сообщение в группе и кто поставил реакцию */
@Composable
fun ReadersDialog(m: Message, onClose: () -> Unit) {
    val p = P
    var rows by remember { mutableStateOf<List<Triple<String, java.util.Date?, String?>>>(emptyList()) }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(m.id) {
        val a = runCatching { Api.rpc("lm_msg_readers", jsonOf("p_msg" to m.id)) as? org.json.JSONArray }.getOrNull()
        val out = ArrayList<Triple<String, java.util.Date?, String?>>(); val seen = HashSet<String>()
        if (a != null) for (i in 0 until a.length()) {
            val o = a.optJSONObject(i) ?: continue
            val u = o.optString("user_id"); if (u.isEmpty() || !seen.add(u)) continue
            out.add(Triple(u, o.date("read_at"), o.str("emoji")))
        }
        AppModel.loadProfiles(out.map { it.first })
        rows = out; loaded = true
    }
    AlertDialog(onDismissRequest = onClose, containerColor = p.panel, title = { Text("Просмотры", color = p.text) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                if (loaded && rows.isEmpty()) Text("Пока никто не прочитал", color = p.muted)
                rows.forEach { (u, d, e) ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        val pr = AppModel.profiles[u]
                        Avatar(AppModel.displayName(u), pr?.avatarUrl, pr?.color ?: 0, 42.dp)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(AppModel.displayName(u), color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, maxLines = 1)
                            if (d != null) Text(whenText(d), color = p.muted, fontSize = 13.sp)
                        }
                        if (e != null) Text(e, fontSize = 24.sp)
                    }
                }
            }
        },
        confirmButton = { TextButton(onClose) { Text("Готово") } })
}
