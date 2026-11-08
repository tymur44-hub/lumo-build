package ru.volshebnymir.lumo.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.Canvas
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.BanInfo

private val BRICKS = listOf(Color(0xFFC8553D), Color(0xFFB4472F), Color(0xFFD76A4C), Color(0xFFA63F2B), Color(0xFFBF5A3F))
private val RED1 = Color(0xFFFF6A5B)
private val RED2 = Color(0xFFE0284F)

/** Кирпичная стена: кирпичи падают сверху и выкладываются ряд за рядом */
@Composable
fun BrickWall(modifier: Modifier, rows: Int = 6, perRow: Int = 5) {
    val t = remember { Animatable(0f) }
    LaunchedEffect(Unit) { t.animateTo(1f, tween(1300, easing = LinearEasing)) }
    Canvas(modifier) {
        val gap = 4.dp.toPx()
        val bw = (size.width - gap * (perRow - 1)) / perRow
        val bh = (size.height - gap * (rows - 1)) / rows
        val total = rows * (perRow + 1)
        for (r in 0 until rows) {
            val shift = if (r % 2 == 1) -bw / 2 else 0f
            val count = if (r % 2 == 1) perRow + 1 else perRow
            for (i in 0 until count) {
                val order = (rows - 1 - r) * (perRow + 1) + i
                val start = order.toFloat() / total * 0.7f
                val k = ((t.value - start) / 0.3f).coerceIn(0f, 1f)
                if (k <= 0f) continue
                // падение с лёгким отскоком
                val e = 1f - (1f - k) * (1f - k) * (1f - k)
                val dy = (1f - e) * -size.height * 0.6f
                val x = shift + i * (bw + gap)
                val y = r * (bh + gap) + dy
                val base = BRICKS[(r * 3 + i * 7) % BRICKS.size]
                // верх стены растворяется
                val fade = (0.25f + r.toFloat() / rows).coerceAtMost(1f) * k
                drawRoundRect(Brush.verticalGradient(listOf(base, base.copy(alpha = 0.8f)), startY = y, endY = y + bh),
                    Offset(x, y), Size(bw, bh), CornerRadius(4.dp.toPx()), alpha = fade)
                drawRoundRect(Color.White.copy(alpha = 0.18f), Offset(x + 3.dp.toPx(), y + 2.dp.toPx()), Size(bw - 6.dp.toPx(), 2.dp.toPx()),
                    CornerRadius(2.dp.toPx()), alpha = fade)
            }
        }
    }
}

/** Окно «Ваш аккаунт заблокирован» поверх всего приложения (из аккаунта не выкидывает) */
@Composable
fun BannedOverlay() {
    val ban = AppModel.myBan
    AnimatedVisibility(ban != null && AppModel.loggedIn, enter = fadeIn(tween(350)) + scaleIn(initialScale = 1.04f), exit = fadeOut(tween(300))) {
        ban?.let { BannedScreen(it) }
    }
}

@Composable
private fun BannedScreen(ban: BanInfo) {
    val p = P
    var appeal by remember { mutableStateOf(false) }
    var confirmOut by remember { mutableStateOf(false) }
    val lock = remember { Animatable(0f) }
    LaunchedEffect(Unit) { delay(750); lock.animateTo(1f, spring(dampingRatio = 0.5f, stiffness = 300f)) }
    LaunchedEffect(Unit) { while (true) { delay(20_000); AppModel.checkBan() } }
    BackHandler { }
    val pending = ban.appealStatus == "pending"
    Box(Modifier.fillMaxSize().background(p.bg).clickable(remember { MutableInteractionSource() }, null) {}) {
        Box(Modifier.fillMaxWidth().height(380.dp).background(Brush.radialGradient(listOf(Color(0xFFFF5B5B).copy(alpha = 0.26f), Color.Transparent), center = Offset(540f, 0f), radius = 900f)))
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).statusBarsPadding().navigationBarsPadding().padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.padding(top = 50.dp).size(250.dp, 190.dp), contentAlignment = Alignment.TopCenter) {
                BrickWall(Modifier.size(250.dp, 150.dp))
                Box(Modifier.align(Alignment.BottomCenter).graphicsLayer { scaleX = lock.value; scaleY = lock.value; alpha = lock.value.coerceIn(0f, 1f) }
                    .size(84.dp).clip(CircleShape).background(p.bg).padding(4.dp)
                    .shadow(16.dp, CircleShape, ambientColor = RED2, spotColor = RED2)
                    .clip(CircleShape).background(Brush.linearGradient(listOf(RED1, RED2))), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Lock, null, tint = Color.White, modifier = Modifier.size(34.dp))
                }
            }
            Text("Ваш аккаунт заблокирован", color = p.text, fontSize = 26.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 18.dp, start = 20.dp, end = 20.dp))
            Text("Администрация Lumo ограничила доступ к аккаунту" + (AppModel.me?.username?.let { " @$it" } ?: "") + ". Пока блокировка действует, нельзя писать сообщения и пользоваться Lumo.",
                color = p.muted, fontSize = 15.sp, textAlign = TextAlign.Center, lineHeight = 21.sp, modifier = Modifier.padding(horizontal = 28.dp, vertical = 10.dp))
            Column(Modifier.padding(horizontal = 20.dp, vertical = 12.dp).fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel)
                .border(1.dp, RED1.copy(alpha = 0.35f), RoundedCornerShape(18.dp)).padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Warning, null, tint = RED1, modifier = Modifier.size(15.dp)); Spacer(Modifier.width(6.dp))
                    Text("ПРИЧИНА", color = RED1, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
                Text(ban.reason?.takeIf { it.isNotBlank() } ?: "Причина не указана", color = p.text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 6.dp))
            }
            if (ban.appealStatus != null && ban.appealStatus != "accepted") {
                val rej = ban.appealStatus == "rejected"
                Row(Modifier.padding(horizontal = 20.dp).fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel).padding(14.dp)) {
                    Icon(if (rej) Icons.Filled.Cancel else Icons.Filled.HourglassTop, null, tint = if (rej) p.danger else Color(0xFFF0A23A), modifier = Modifier.size(24.dp))
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(if (rej) "Апелляция отклонена" else "Апелляция отправлена", color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                        Text(if (rej) (ban.appealReply?.takeIf { it.isNotBlank() }?.let { "Ответ модератора: $it" } ?: "Модераторы оставили блокировку в силе.")
                             else "Модераторы рассмотрят её и снимут блокировку, если согласятся. Это окно обновится само.",
                            color = p.muted, fontSize = 13.5.sp, lineHeight = 18.sp, modifier = Modifier.padding(top = 3.dp))
                    }
                }
            }
            Row(Modifier.padding(start = 20.dp, end = 20.dp, top = 20.dp).fillMaxWidth().height(54.dp).clip(RoundedCornerShape(16.dp))
                .background(p.accent).graphicsLayer { alpha = if (pending) 0.5f else 1f }.bouncy { if (!pending) appeal = true },
                horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                Icon(if (pending) Icons.Filled.Schedule else Icons.Filled.Drafts, null, tint = Color.White, modifier = Modifier.size(20.dp)); Spacer(Modifier.width(8.dp))
                Text(if (pending) "Апелляция на рассмотрении" else if (ban.appealStatus == "rejected") "Подать апелляцию ещё раз" else "Подать апелляцию",
                    color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
            }
            Text("Выйти из аккаунта", color = p.muted, fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                modifier = Modifier.padding(top = 10.dp).clip(RoundedCornerShape(10.dp)).clickable { confirmOut = true }.padding(horizontal = 16.dp, vertical = 12.dp))
        }
        AnimatedVisibility(appeal, enter = slideInVertically { it } + fadeIn(), exit = slideOutVertically { it } + fadeOut()) {
            AppealScreen { appeal = false }
        }
    }
    if (confirmOut) AlertDialog(onDismissRequest = { confirmOut = false }, title = { Text("Выйти из аккаунта?") },
        confirmButton = { TextButton({ confirmOut = false; AppModel.logout() }) { Text("Выйти", color = p.danger) } },
        dismissButton = { TextButton({ confirmOut = false }) { Text("Отмена") } })
}

/** Апелляция: пользователь объясняет, за что его могли заблокировать */
@Composable
private fun AppealScreen(onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var text by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var err by remember { mutableStateOf<String?>(null) }
    var sent by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    val ok = text.trim().length >= 10
    BackHandler { onClose() }
    LaunchedEffect(Unit) { delay(350); runCatching { focus.requestFocus() } }
    Column(Modifier.fillMaxSize().background(p.bg).clickable(remember { MutableInteractionSource() }, null) {}.statusBarsPadding().navigationBarsPadding().imePadding()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(40.dp).clip(CircleShape).background(p.panel).bouncy { onClose() }, contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Close, null, tint = p.text, modifier = Modifier.size(20.dp))
            }
            Text("Апелляция", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
            Spacer(Modifier.size(40.dp))
        }
        if (sent) {
            Column(Modifier.weight(1f).fillMaxWidth().padding(30.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                Box(Modifier.size(88.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(48.dp))
                }
                Text("Апелляция отправлена", color = p.text, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.padding(top = 18.dp))
                Text("Модераторы прочитают ваше обращение. Если блокировку снимут, Lumo откроется сам.", color = p.muted, fontSize = 15.sp,
                    textAlign = TextAlign.Center, modifier = Modifier.padding(top = 8.dp))
            }
            Box(Modifier.padding(20.dp).fillMaxWidth().height(54.dp).clip(RoundedCornerShape(16.dp)).background(p.accent).bouncy { onClose() }, contentAlignment = Alignment.Center) {
                Text("Готово", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
            }
        } else {
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(48.dp).clip(RoundedCornerShape(14.dp)).background(p.accent), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.Chat, null, tint = Color.White, modifier = Modifier.size(24.dp))
                    }
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text("Расскажите, что случилось", color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                        Text("За что вас могли заблокировать и почему блокировку стоит снять", color = p.muted, fontSize = 13.5.sp)
                    }
                }
                Box(Modifier.padding(top = 14.dp).fillMaxWidth().heightIn(min = 200.dp).clip(RoundedCornerShape(18.dp)).background(p.panel).padding(16.dp)) {
                    if (text.isEmpty()) Text("Например: я отправил много одинаковых сообщений, потому что…", color = p.muted.copy(alpha = 0.7f), fontSize = 16.sp)
                    BasicTextField(text, { text = it.take(2000) }, Modifier.fillMaxWidth().focusRequester(focus),
                        textStyle = androidx.compose.ui.text.TextStyle(color = p.text, fontSize = 16.sp, lineHeight = 22.sp), cursorBrush = SolidColor(p.a1))
                }
                Row(Modifier.padding(top = 8.dp)) {
                    Text("Пишите честно и спокойно — так апелляцию рассмотрят быстрее.", color = p.muted, fontSize = 12.5.sp, modifier = Modifier.weight(1f))
                    Text("${text.length}/2000", color = p.muted, fontSize = 12.5.sp)
                }
                err?.let { Text(it, color = p.danger, fontSize = 14.sp, modifier = Modifier.padding(top = 8.dp)) }
            }
            Row(Modifier.padding(horizontal = 20.dp, vertical = 14.dp).fillMaxWidth().height(54.dp).clip(RoundedCornerShape(16.dp)).background(p.accent)
                .graphicsLayer { alpha = if (ok) 1f else 0.45f }
                .bouncy {
                    if (!ok || busy) return@bouncy
                    busy = true; err = null
                    scope.launch { val e = AppModel.submitAppeal(text.trim()); busy = false; if (e == null) sent = true else err = e }
                },
                horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                if (busy) CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
                else {
                    Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White, modifier = Modifier.size(20.dp)); Spacer(Modifier.width(8.dp))
                    Text("Отправить апелляцию", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
            }
        }
    }
}
