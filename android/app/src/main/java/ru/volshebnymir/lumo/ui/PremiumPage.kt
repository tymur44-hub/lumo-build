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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Apps
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.BlurOn
import androidx.compose.material.icons.filled.FiberManualRecord
import androidx.compose.material.icons.filled.Check
import androidx.compose.ui.draw.drawWithContent
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

/** Значок статуса: анимированный нарисованный значок или обычный эмодзи */
@Composable
fun StatusEmoji(s: String, size: TextUnit = 16.sp, modifier: Modifier = Modifier) {
    if (!s.startsWith("a:")) { Text(emojiGlyph(s), fontSize = size, modifier = modifier); return }
    val dp = with(LocalDensity.current) { size.toDp() } * 1.15f
    DrawnStatus(s.removePrefix("a:"), dp, modifier)
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

private class Feat(val icon: androidx.compose.ui.graphics.vector.ImageVector, val color: Color, val title: String, val desc: String, val soon: Boolean = false)

private val FEATURES = listOf(
    Feat(Icons.Filled.AutoAwesome, Color(0xFFFF9F0A), "Анимированные смайлик-статусы", "Двигающийся значок рядом с именем"),
    Feat(Icons.Filled.Celebration, Color(0xFFFF5B7A), "Анимированные эффекты сообщений", "Удерживайте кнопку отправки и выберите эффект"),
    Feat(Icons.Filled.NotificationsOff, Color(0xFF8E8E93), "Отправка без звука", "Сообщение придёт тихо"),
    Feat(Icons.Filled.Schedule, Color(0xFF2BD67B), "Отложенные сообщения", "Уйдут сами в нужное время"),
    Feat(Icons.Filled.Timer, Color(0xFF1FB6A6), "Исчезающие сообщения", "Автоудаление в чате через час, день, неделю или месяц"),
    Feat(Icons.Filled.BarChart, Color(0xFF22A6FF), "Статистика каналов", "Подписчики и посты по дням"),
    Feat(Icons.Filled.SmartToy, Color(0xFFFF8A3D), "Создание своих ботов", "Через @botfather командой /newbot"),
    Feat(Icons.Filled.Mic, Color(0xFFA35BFF), "Расшифровка голосовых и кружков", "Текст под голосовым. На iPhone работает, на Android — в разработке"),
    Feat(Icons.Filled.Apps, Color(0xFF5B6CFF), "Иконки приложения", "Шесть оформлений иконки с премиум-значком"),
    Feat(Icons.Filled.Fingerprint, Color(0xFF5B6CFF), "Блокировка и биометрия", "Код, отпечаток пальца или Face ID при входе"),
    Feat(Icons.Filled.Mail, Color(0xFFFFB020), "Писать мне только Premium", "Ограничьте входящие сообщения в «Конфиденциальности»"),
    Feat(Icons.Filled.Palette, Color(0xFFE05BFF), "Свои цвета и фоны чатов", "Цвет сообщений, обои и акценты оформления"),
    Feat(Icons.Filled.Shield, Color(0xFF2B8CFF), "Запрет пересылки и скриншотов", "Защищённый чат: на Android скриншоты блокируются, на iPhone экран скрывается при записи"),
    Feat(Icons.Filled.Groups, Color(0xFF34C759), "Групповые голосовые и видеозвонки", "Звонок с несколькими участниками", soon = true),
    Feat(Icons.Filled.BlurOn, Color(0xFF64D2FF), "Размытие и замена фона в звонке", "Скройте комнату за спиной", soon = true),
    Feat(Icons.Filled.FiberManualRecord, Color(0xFFFF453A), "Запись звонка с согласия собеседника", "Собеседник должен подтвердить запись", soon = true),
    Feat(Icons.Filled.Star, Color(0xFFFFB020), "Значок Premium", "Звезда рядом с именем в чатах и профиле"),
)

private val ABOUT = listOf(
    "Что это" to "Lumo Premium — необязательная подписка с дополнительными возможностями для общения. Основные функции мессенджера остаются бесплатными.",
    "Где работает" to "Подписка привязана к вашему аккаунту и действует на всех устройствах: сайт, iOS, Android и Windows.",
    "Как оформить" to "Оплата проходит через встроенного бота @lumo_premium прямо в Lumo. После оплаты значок и функции включаются сами.",
    "Безопасность" to "Шифрование медиа остаётся бесплатным для всех. Premium не даёт доступа к чужим перепискам.",
    "Скоро" to "Функции с пометкой «в разработке» появятся в следующих обновлениях.",
)

/** Кнопка с градиентом и бегущим бликом */
@Composable
fun ShimmerButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val tr = rememberInfiniteTransition(label = "shim")
    val x by tr.animateFloat(-0.4f, 1.4f, infiniteRepeatable(tween(2200, easing = LinearEasing), RepeatMode.Restart), label = "x")
    val base = Brush.horizontalGradient(listOf(Color(0xFF5B8CFF), Color(0xFFA066FF), Color(0xFFD86BFF)))
    Box(modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(base).clickable { onClick() }
        .drawWithContent {
            drawContent()
            val w = size.width
            val cx = w * x
            drawRect(Brush.horizontalGradient(listOf(Color.Transparent, Color.White.copy(alpha = 0.38f), Color.Transparent), cx - w * 0.18f, cx + w * 0.18f))
        }.padding(vertical = 15.dp), contentAlignment = Alignment.Center) {
        Text(text, color = Color.White, fontWeight = FontWeight.Black, fontSize = 17.sp, textAlign = TextAlign.Center)
    }
}

@Composable
fun PremiumScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var plan by remember { mutableStateOf("year") }
    var until by remember { mutableStateOf<String?>(null) }
    var owner by remember { mutableStateOf(false) }
    var emo by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        val r = runCatching { Api.rpc("lm_my_premium") }.getOrNull()
        val o = (r as? JSONObject) ?: (r as? JSONArray)?.optJSONObject(0)
        if (o != null) { owner = o.optBoolean("owner"); until = o.optString("until").takeIf { it.isNotEmpty() && it != "null" } }
    }
    if (emo) EmojiPickerDialog { emo = false }
    Column(Modifier.fillMaxSize().background(p.bg)) {
        Box {
            TopBar("")
        }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.fillMaxWidth().height(230.dp).background(Brush.verticalGradient(listOf(Color(0xFF9B6BFF).copy(alpha = 0.22f), Color.Transparent))), contentAlignment = Alignment.TopCenter) {
                SparkleField(Modifier.fillMaxSize())
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    PremiumStar(130.dp)
                    Text("Lumo Premium", color = p.text, fontWeight = FontWeight.Black, fontSize = 26.sp)
                    Text("Больше свободы и десятки эксклюзивных функций", color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 40.dp, vertical = 4.dp))
                }
            }
            Column(Modifier.padding(horizontal = 16.dp)) {
                if (AppModel.isPremium) {
                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel).padding(14.dp)) {
                        Text("У вас активен Premium", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text(if (owner) "Бессрочно — вы владелец Lumo" else until?.let { "Действует до " + it.take(10) } ?: "Подписка активна", color = p.muted, fontSize = 14.sp)
                        Spacer(Modifier.height(8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { emo = true }) {
                            Text("Ваш смайлик-статус:", color = p.muted, fontSize = 14.sp)
                            Spacer(Modifier.width(8.dp))
                            AppModel.me?.emojiStatus?.let { StatusEmoji(it, 22.sp) } ?: Text("выбрать", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                }
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel)) {
                    PLANS.forEachIndexed { i, pl ->
                        val on = plan == pl.id
                        if (i > 0) Box(Modifier.padding(start = 50.dp).fillMaxWidth().height(1.dp).background(p.line))
                        Row(Modifier.fillMaxWidth().clickable { plan = pl.id }.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(24.dp).clip(CircleShape).background(if (on) p.a1 else Color.Transparent).border(2.dp, if (on) p.a1 else p.muted, CircleShape), contentAlignment = Alignment.Center) {
                                if (on) Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(16.dp))
                            }
                            Spacer(Modifier.width(12.dp))
                            Column(Modifier.weight(1f)) {
                                Text(pl.title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                Text(pl.note, color = p.muted, fontSize = 12.5.sp)
                            }
                            Text(pl.price, color = p.text, fontWeight = FontWeight.Black, fontSize = 16.sp)
                        }
                    }
                }
                Text("ПРЕИМУЩЕСТВА ПОДПИСКИ", color = p.muted, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = 14.dp, top = 18.dp, bottom = 8.dp))
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel)) {
                    FEATURES.forEachIndexed { i, f ->
                        if (i > 0) Box(Modifier.padding(start = 62.dp).fillMaxWidth().height(1.dp).background(p.line))
                        Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(f.color), contentAlignment = Alignment.Center) {
                                Icon(f.icon, null, tint = Color.White, modifier = Modifier.size(20.dp))
                            }
                            Spacer(Modifier.width(14.dp))
                            Column(Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(f.title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp, modifier = Modifier.weight(1f, fill = false))
                                    if (f.soon) Text("в разработке", color = p.a1, fontSize = 11.sp, fontWeight = FontWeight.Bold,
                                        modifier = Modifier.padding(start = 6.dp).clip(RoundedCornerShape(6.dp)).background(p.a1.copy(alpha = 0.14f)).padding(horizontal = 6.dp, vertical = 1.dp))
                                }
                                Text(f.desc, color = p.muted, fontSize = 12.5.sp)
                            }
                        }
                    }
                }
                Spacer(Modifier.height(16.dp))
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(p.panel).padding(16.dp)) {
                    Text("О Lumo Premium", color = p.text, fontWeight = FontWeight.Black, fontSize = 18.sp)
                    ABOUT.forEach { (h, d) ->
                        Text(h, color = p.a1, fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.padding(top = 12.dp))
                        Text(d, color = p.muted, fontSize = 14.sp)
                    }
                }
                Spacer(Modifier.height(24.dp))
            }
        }
        Box(Modifier.fillMaxWidth().background(p.panel).navigationBarsPadding().padding(12.dp)) {
            ShimmerButton(if (AppModel.isPremium) "Продлить подписку" else "Оформить Premium") {
                if (owner) scope.launch { AppModel.openByUsername("lumo_premium") } else AppModel.say("Оплата пока временно недоступна")
            }
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


// ---------------- иконка приложения ----------------

private val ICONS = listOf(
    Triple("Classic", "Классика", ru.volshebnymir.lumo.R.drawable.ic_alt_classic),
    Triple("Gold", "Золото", ru.volshebnymir.lumo.R.drawable.ic_alt_gold),
    Triple("Aurora", "Аврора", ru.volshebnymir.lumo.R.drawable.ic_alt_aurora),
    Triple("Midnight", "Полночь", ru.volshebnymir.lumo.R.drawable.ic_alt_midnight),
    Triple("Sakura", "Сакура", ru.volshebnymir.lumo.R.drawable.ic_alt_sakura),
    Triple("Neon", "Неон", ru.volshebnymir.lumo.R.drawable.ic_alt_neon),
)

private fun iconComponent(ctx: android.content.Context, k: String) = android.content.ComponentName(ctx.packageName, "ru.volshebnymir.lumo.Icon$k")

private fun currentIcon(ctx: android.content.Context): String {
    val pm = ctx.packageManager
    for ((k, _, _) in ICONS) {
        val st = pm.getComponentEnabledSetting(iconComponent(ctx, k))
        if (st == android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED) return k
    }
    return "Classic"
}

private fun applyIcon(ctx: android.content.Context, key: String) {
    val pm = ctx.packageManager
    pm.setComponentEnabledSetting(iconComponent(ctx, key), android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED, android.content.pm.PackageManager.DONT_KILL_APP)
    for ((k, _, _) in ICONS) if (k != key)
        pm.setComponentEnabledSetting(iconComponent(ctx, k), android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_DISABLED, android.content.pm.PackageManager.DONT_KILL_APP)
}

@Composable
fun AppIconDialog(onClose: () -> Unit) {
    val p = P
    val ctx = androidx.compose.ui.platform.LocalContext.current
    var cur by remember { mutableStateOf(currentIcon(ctx)) }
    Dialog(onDismissRequest = onClose) {
        Column(Modifier.clip(RoundedCornerShape(26.dp)).background(p.panel).padding(18.dp)) {
            Text("Иконка приложения", color = p.text, fontWeight = FontWeight.Black, fontSize = 20.sp)
            Text("Иконка на экране телефона поменяется. Лаунчер может обновить её через несколько секунд.", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(top = 4.dp, bottom = 12.dp))
            ICONS.chunked(3).forEach { row ->
                Row(Modifier.fillMaxWidth().padding(bottom = 10.dp), horizontalArrangement = Arrangement.SpaceEvenly) {
                    row.forEach { (k, title, res) ->
                        Column(Modifier.clip(RoundedCornerShape(16.dp)).clickable {
                            if (k != "Classic" && !AppModel.isPremium) AppModel.say(PREMIUM_SOON)
                            else { applyIcon(ctx, k); cur = k }
                        }.padding(6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            androidx.compose.foundation.Image(androidx.compose.ui.res.painterResource(res), null,
                                Modifier.size(70.dp).clip(RoundedCornerShape(16.dp)).then(if (cur == k) Modifier.border(3.dp, p.a1, RoundedCornerShape(16.dp)) else Modifier))
                            Text(title, color = if (cur == k) p.a1 else p.text, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 4.dp))
                        }
                    }
                }
            }
            Text("Закрыть", color = p.a1, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.End).clickable { onClose() }.padding(8.dp))
        }
    }
}
