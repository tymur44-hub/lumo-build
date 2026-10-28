package ru.volshebnymir.lumo.ui

import android.os.Build
import android.view.WindowManager
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.FormatListBulleted
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.PREMIUM_SOON
import ru.volshebnymir.lumo.core.isPremium
import ru.volshebnymir.lumo.core.premium
import ru.volshebnymir.lumo.core.setEmojiStatus
import kotlin.random.Random

// ---------------- анимированные смайлик-статусы ----------------

/** Анимированные значки: ключ хранится в профиле как «a:ключ», у остальных клиентов он показывается как обычный эмодзи */
val ANIM_EMOJI = listOf("fire" to "🔥", "heart" to "❤️", "star" to "⭐", "rocket" to "🚀", "crown" to "👑", "gem" to "💎",
    "bolt" to "⚡", "ghost" to "👻", "sun" to "☀️", "moon" to "🌙", "clover" to "🍀", "note" to "🎵")

val CLASSIC_EMOJI = listOf("🎧", "📚", "🌴", "☕", "🎮", "💼", "🛠", "🎯", "✈️", "🏆", "🎨", "📷")

fun emojiGlyph(s: String): String = if (s.startsWith("a:")) ANIM_EMOJI.firstOrNull { it.first == s.removePrefix("a:") }?.second ?: "⭐" else s

/** Значок статуса: анимированный (пульс и покачивание) или обычный */
@Composable
fun StatusEmoji(s: String, size: TextUnit = 16.sp, modifier: Modifier = Modifier) {
    val glyph = emojiGlyph(s)
    if (!s.startsWith("a:")) { Text(glyph, fontSize = size, modifier = modifier); return }
    val tr = rememberInfiniteTransition(label = "emo")
    val k = s.hashCode() and 3
    val sc by tr.animateFloat(0.88f, 1.14f, infiniteRepeatable(tween(900 + k * 120, easing = LinearEasing), RepeatMode.Reverse), label = "sc")
    val rot by tr.animateFloat(-9f, 9f, infiniteRepeatable(tween(1300 + k * 150, easing = LinearEasing), RepeatMode.Reverse), label = "rot")
    Text(glyph, fontSize = size, modifier = modifier.graphicsLayer { scaleX = sc; scaleY = sc; rotationZ = rot })
}

/** Выбор смайлик-статуса: анимированные и обычные */
@Composable
fun EmojiPickerDialog(onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    Dialog(onDismissRequest = onClose) {
        Column(Modifier.clip(RoundedCornerShape(26.dp)).background(p.panel).padding(18.dp)) {
            Text("Смайлик-статус", color = p.text, fontWeight = FontWeight.Black, fontSize = 20.sp)
            Text("Значок показывается рядом с вашим именем. Анимированные двигаются у всех, кто пользуется Lumo.", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(top = 4.dp, bottom = 10.dp))
            Column(Modifier.verticalScroll(rememberScrollState()).height(300.dp)) {
                Text("Анимированные", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(vertical = 4.dp))
                ANIM_EMOJI.chunked(4).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        row.forEach { (k, _) ->
                            Box(Modifier.size(60.dp).clip(RoundedCornerShape(16.dp)).clickable { scope.launch { AppModel.setEmojiStatus("a:$k"); onClose() } }, contentAlignment = Alignment.Center) {
                                StatusEmoji("a:$k", 32.sp)
                            }
                        }
                    }
                }
                Text("Обычные", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(top = 10.dp, bottom = 4.dp))
                CLASSIC_EMOJI.chunked(4).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        row.forEach { e ->
                            Box(Modifier.size(60.dp).clip(RoundedCornerShape(16.dp)).clickable { scope.launch { AppModel.setEmojiStatus(e); onClose() } }, contentAlignment = Alignment.Center) {
                                Text(e, fontSize = 30.sp)
                            }
                        }
                    }
                }
            }
            Row(Modifier.fillMaxWidth().padding(top = 10.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Убрать статус", color = p.danger, fontWeight = FontWeight.Bold, modifier = Modifier.clickable { scope.launch { AppModel.setEmojiStatus(""); onClose() } }.padding(8.dp))
                Text("Закрыть", color = p.a1, fontWeight = FontWeight.Bold, modifier = Modifier.clickable { onClose() }.padding(8.dp))
            }
        }
    }
}

// ---------------- страница Lumo Premium ----------------

private data class Plan(val id: String, val title: String, val price: String, val note: String)

private val PLANS = listOf(
    Plan("year", "12 месяцев", "2 490 ₽", "около 207 ₽ в месяц · выгода 48%"),
    Plan("half", "6 месяцев", "1 490 ₽", "около 248 ₽ в месяц"),
    Plan("month", "1 месяц", "199 ₽", "без скидки"),
)

private val FEATURES = listOf(
    Triple("✨", "Анимированные смайлик-статусы", "Двигающийся значок рядом с именем"),
    Triple("🎉", "Анимированные эффекты сообщений", "Удерживайте кнопку отправки и выберите эффект"),
    Triple("🔕", "Отправка без звука", "Сообщение придёт тихо"),
    Triple("⏰", "Отложенные сообщения", "Уйдут сами в нужное время"),
    Triple("⏳", "Исчезающие сообщения", "Автоудаление в чате через час, день, неделю или месяц"),
    Triple("📊", "Статистика каналов", "Подписчики и посты по дням"),
    Triple("🤖", "Создание своих ботов", "Через @botfather командой /newbot"),
    Triple("⭐", "Значок Premium", "Звезда рядом с именем в чатах и профиле"),
)

@Composable
fun PremiumScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var plan by remember { mutableStateOf("year") }
    var until by remember { mutableStateOf<String?>(null) }
    var owner by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        val r = runCatching { Api.rpc("lm_my_premium") }.getOrNull()
        val o = (r as? JSONObject) ?: (r as? JSONArray)?.optJSONObject(0)
        if (o != null) { owner = o.optBoolean("owner"); until = o.optString("until").takeIf { it.isNotEmpty() && it != "null" } }
    }
    val gold = Brush.linearGradient(listOf(Color(0xFF7C5CFF), Color(0xFFFF5BB8), Color(0xFFFFB020)))
    Column(Modifier.fillMaxSize().background(p.bg)) {
        TopBar("Lumo Premium")
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.height(10.dp))
            Box(Modifier.size(96.dp).clip(CircleShape).background(gold), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Star, null, tint = Color.White, modifier = Modifier.size(58.dp))
            }
            Spacer(Modifier.height(12.dp))
            Text("Lumo Premium", color = p.text, fontWeight = FontWeight.Black, fontSize = 26.sp)
            Text("Больше возможностей для общения", color = p.muted, fontSize = 15.sp, textAlign = TextAlign.Center)
            Spacer(Modifier.height(16.dp))
            if (AppModel.isPremium) {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel).padding(14.dp)) {
                    Text("У вас активен Premium", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    Text(if (owner) "Бессрочно — вы владелец Lumo" else until?.let { "Действует до " + it.take(10) } ?: "Подписка активна", color = p.muted, fontSize = 14.sp)
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Ваш смайлик-статус:", color = p.muted, fontSize = 14.sp)
                        Spacer(Modifier.width(8.dp))
                        AppModel.me?.emojiStatus?.let { StatusEmoji(it, 22.sp) } ?: Text("не выбран", color = p.muted, fontSize = 14.sp)
                    }
                }
                Spacer(Modifier.height(14.dp))
            }
            PLANS.forEach { pl ->
                val on = plan == pl.id
                Row(Modifier.fillMaxWidth().padding(bottom = 8.dp).clip(RoundedCornerShape(16.dp)).background(p.panel)
                    .border(2.dp, if (on) p.a1 else Color.Transparent, RoundedCornerShape(16.dp)).clickable { plan = pl.id }.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(22.dp).clip(CircleShape).border(2.dp, if (on) p.a1 else p.muted, CircleShape).padding(4.dp)) { if (on) Box(Modifier.fillMaxSize().clip(CircleShape).background(p.a1)) }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(pl.title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text(pl.note, color = p.muted, fontSize = 13.sp)
                    }
                    Text(pl.price, color = p.text, fontWeight = FontWeight.Black, fontSize = 17.sp)
                }
            }
            Spacer(Modifier.height(10.dp))
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel).padding(vertical = 6.dp)) {
                FEATURES.forEachIndexed { i, (ic, t, d) ->
                    if (i > 0) Box(Modifier.padding(start = 58.dp).fillMaxWidth().height(1.dp).background(p.line))
                    Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(ic, fontSize = 26.sp, modifier = Modifier.width(34.dp))
                        Spacer(Modifier.width(8.dp))
                        Column {
                            Text(t, color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                            Text(d, color = p.muted, fontSize = 13.sp)
                        }
                    }
                }
            }
            Text("Шифрование медиа остаётся бесплатным для всех.", color = p.muted, fontSize = 12.5.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(16.dp))
        }
        Box(Modifier.fillMaxWidth().background(p.panel).navigationBarsPadding().padding(12.dp)) {
            Text(if (AppModel.isPremium) "Продлить подписку" else "Оформить Premium", color = Color.White, fontWeight = FontWeight.Black, fontSize = 17.sp, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(gold).clickable {
                    if (owner) scope.launch { AppModel.openByUsername("lumo_premium") } else AppModel.say("Оплата пока временно недоступна")
                }.padding(vertical = 15.dp))
        }
    }
}

// ---------------- эффекты сообщений ----------------

val FX_LIST = listOf("👍", "👎", "❤️", "🔥", "🎉", "💩", "😍", "🤩", "🥳", "💯", "👏", "😂", "😢", "😡")

private class Particle(val x: Float, val delay: Float, val size: Float, val dx: Float, val dy: Float, val rot: Float)

/** Облако эмодзи, летящее по экрану */
@Composable
fun FxOverlay(emoji: String, onDone: () -> Unit) {
    val up = emoji == "🔥" || emoji == "❤️" || emoji == "😍"
    val down = emoji == "💩"
    val parts = remember(emoji) {
        List(28) {
            Particle(0.08f + Random.nextFloat() * 0.84f, Random.nextFloat() * 0.35f, 22f + Random.nextFloat() * 32f,
                (Random.nextFloat() - 0.5f) * (if (up || down) 0.3f else 0.9f),
                if (up) -(0.4f + Random.nextFloat() * 0.35f) else if (down) (0.5f + Random.nextFloat() * 0.3f) else (Random.nextFloat() - 0.5f) * 0.6f,
                (Random.nextFloat() - 0.5f) * 120f)
        }
    }
    val prog = remember(emoji) { Animatable(0f) }
    LaunchedEffect(emoji) { prog.animateTo(1f, tween(2800, easing = LinearEasing)); onDone() }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val w = with(LocalDensity.current) { maxWidth.toPx() }
        val h = with(LocalDensity.current) { maxHeight.toPx() }
        parts.forEach { q ->
            val t = ((prog.value - q.delay) / (1f - q.delay)).coerceIn(0f, 1f)
            val alpha = if (t < 0.15f) t / 0.15f else 1f - (t - 0.15f) / 0.85f
            val y0 = if (up) h * (0.7f + q.delay * 0.7f) else if (down) h * 0.05f else h * 0.5f
            Text(emoji, fontSize = q.size.sp, modifier = Modifier.graphicsLayer {
                translationX = w * q.x + q.dx * w * t
                translationY = y0 + q.dy * h * t
                this.alpha = alpha.coerceIn(0f, 1f)
                val s = 0.3f + 0.9f * t; scaleX = s; scaleY = s; rotationZ = q.rot * t
            })
        }
    }
}

/** Меню долгого нажатия на кнопку отправки: эффекты и действия */
@Composable
fun SendMenuDialog(text: String, onClose: () -> Unit, onFx: (String) -> Unit, onAction: (Int) -> Unit, onSend: () -> Unit) {
    val p = P
    val prem = AppModel.isPremium
    var more by remember { mutableStateOf(false) }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        val w = (LocalView.current.parent as? DialogWindowProvider)?.window
        SideEffect {
            try {
                w?.setDimAmount(0.3f)
                if (Build.VERSION.SDK_INT >= 31 && w != null) {
                    w.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
                    val lp = w.attributes; lp.blurBehindRadius = 40; w.attributes = lp
                }
            } catch (_: Throwable) {}
        }
        Box(Modifier.fillMaxSize().clickable(indication = null, interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() }) { onClose() }.padding(14.dp), contentAlignment = Alignment.BottomEnd) {
            Column(Modifier.navigationBarsPadding().padding(bottom = 70.dp), horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(p.panel2.copy(alpha = 0.94f)).padding(horizontal = 10.dp, vertical = 10.dp)) {
                    Text("Добавить анимированный эффект", color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp))
                    val first = FX_LIST.take(7)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        first.forEach { e -> FxCell(e, prem) { onFx(e) } }
                    }
                    if (more) Row(Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                        FX_LIST.drop(7).forEach { e -> FxCell(e, prem) { onFx(e) } }
                    } else Box(Modifier.align(Alignment.End).padding(top = 2.dp).size(32.dp).clip(CircleShape).background(p.a1.copy(alpha = 0.35f)).clickable { more = true }, contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.KeyboardArrowDown, null, tint = Color.White, modifier = Modifier.size(20.dp))
                    }
                }
                Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(text.take(400), color = Color.White, fontSize = 16.sp, modifier = Modifier.weight(1f, fill = false)
                        .clip(RoundedCornerShape(20.dp, 20.dp, 6.dp, 20.dp)).background(p.accent).padding(horizontal = 14.dp, vertical = 9.dp))
                    Box(Modifier.size(48.dp).clip(CircleShape).background(p.accent).clickable { onSend() }, contentAlignment = Alignment.Center) {
                        Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White)
                    }
                }
                Column(Modifier.width(260.dp).clip(RoundedCornerShape(26.dp)).background(p.panel2.copy(alpha = 0.94f)).padding(6.dp)) {
                    MenuRow(Icons.Filled.NotificationsOff, "Отправить без звука") { onAction(0) }
                    MenuRow(Icons.Filled.Schedule, "Отложить отправку") { onAction(1) }
                    MenuRow(Icons.Filled.FormatListBulleted, "Запланированные") { onAction(2) }
                }
            }
        }
    }
}

@Composable
private fun FxCell(e: String, prem: Boolean, onClick: () -> Unit) {
    val p = P
    Box(Modifier.size(42.dp).clip(CircleShape).clickable { onClick() }, contentAlignment = Alignment.Center) {
        Text(e, fontSize = 28.sp)
        if (!prem) Box(Modifier.align(Alignment.BottomEnd).size(15.dp).clip(CircleShape).background(p.muted), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Lock, null, tint = Color.White, modifier = Modifier.size(9.dp))
        }
    }
}

@Composable
private fun MenuRow(icon: androidx.compose.ui.graphics.vector.ImageVector, t: String, onClick: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).clickable { onClick() }.padding(horizontal = 14.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = p.text, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(14.dp))
        Text(t, color = p.text, fontSize = 16.sp)
    }
}
