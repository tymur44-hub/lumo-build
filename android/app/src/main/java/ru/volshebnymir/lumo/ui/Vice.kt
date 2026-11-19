package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.material.icons.filled.Star
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.RemoteConfig
import kotlin.math.cos
import kotlin.math.sin

/**
 * Временная тема «Vice Nights» (до 1 декабря): закат над океаном, неон, пальмы.
 * Основные формы Lumo остаются — тема только добавляет краски.
 * Включает и выключает сервер (look.event), пользователь может отключить её в «Оформлении».
 */
object Vice {
    val pink = Color(0xFFFF4F8B); val orange = Color(0xFFFF8A3D); val sun = Color(0xFFFFD36B)
    val teal = Color(0xFF2FD6D0); val night = Color(0xFF140A2E)
    val outBrush = Brush.linearGradient(listOf(Color(0xFFFF4F8B), Color(0xFFFF8A3D)))
    private val prefs get() = AppModel.ctx.getSharedPreferences("lumo_vice", android.content.Context.MODE_PRIVATE)
    var off by mutableStateOf(runCatching { prefs.getBoolean("off", false) }.getOrDefault(false))
        private set
    fun changeOff(v: Boolean) { off = v; runCatching { prefs.edit().putBoolean("off", v).apply() } }
    val available: Boolean get() = RemoteConfig.eventTheme == "vice"
    val on: Boolean get() = available && !off
    /** узкий жирный шрифт заголовков */
    val titleFont = FontFamily(android.graphics.Typeface.create("sans-serif-condensed", android.graphics.Typeface.BOLD))
}

/** Небо на закате за шапкой списка чатов: градиент, солнце, город и пальмы, плавно уходит в фон */
fun Modifier.viceSky(height: androidx.compose.ui.unit.Dp = 240.dp): Modifier = composed {
    val t by rememberInfiniteTransition(label = "vice").animateFloat(0f, (2 * Math.PI).toFloat(), infiniteRepeatable(tween(6000, easing = LinearEasing)), label = "t")
    val bg = P.bg
    drawBehind { drawSky(size.width, height.toPx(), t, bg) }
}

private fun DrawScope.drawSky(w: Float, h: Float, t: Float, bg: Color) {
    val sky = Brush.verticalGradient(0f to Color(0xFF2A0F52), 0.38f to Color(0xFF8A2C8F), 0.66f to Color(0xFFFF4F8B), 0.86f to Color(0xFFFF9A3D), 1f to Color(0xFFFFD36B), startY = 0f, endY = h)
    drawRect(sky, size = Size(w, h))
    // солнце с полосами
    val r = w * 0.2f * (1 + 0.015f * sin(t)); val c = Offset(w / 2, h * 0.78f)
    val circle = Path().apply { addOval(androidx.compose.ui.geometry.Rect(c, r)) }
    clipPath(circle) {
        drawRect(Brush.verticalGradient(listOf(Color(0xFFFFE58A), Color(0xFFFF8A3D)), startY = c.y - r, endY = c.y + r), Offset(c.x - r, c.y - r), Size(r * 2, r * 2))
        for (i in 0 until 5) drawRect(Color(0xFFFF4F8B).copy(alpha = 0.85f), Offset(c.x - r, c.y + r * (0.15f + i * 0.18f)), Size(r * 2, 2f + i * 1.5f))
    }
    // город
    val blocks = listOf(0f to .16f, .07f to .24f, .12f to .13f, .18f to .34f, .22f to .18f, .3f to .12f, .62f to .15f, .66f to .32f, .69f to .4f, .72f to .28f, .78f to .14f, .85f to .22f, .9f to .11f, 1f to .11f)
    val city = Path().apply {
        moveTo(0f, h); var y = h - h * blocks[0].second; lineTo(0f, y)
        for ((x, hh) in blocks) { lineTo(w * x, y); y = h - h * hh; lineTo(w * x, y) }
        lineTo(w, h); close()
    }
    drawPath(city, Color(0xFF1A0B33))
    // пальмы
    fun palm(x: Float, top: Float, lean: Float, ph: Float) {
        val tip = Offset(x + lean, top)
        drawPath(Path().apply { moveTo(x, h); quadraticBezierTo(x + lean * 0.2f, (h + top) / 2, tip.x, tip.y) }, Color(0xFF120826), style = Stroke(5.dp.toPx(), cap = StrokeCap.Round))
        val sway = sin(t * 1.3f + ph) * 3.dp.toPx(); val len = 40.dp.toPx()
        for (a in listOf(-160.0, -125.0, -95.0, -60.0, -25.0, 10.0)) {
            val rad = Math.toRadians(a)
            val end = Offset(tip.x + (cos(rad) * len).toFloat() + sway, tip.y + (sin(rad) * len * 0.55).toFloat() + 14.dp.toPx())
            val ctl = Offset(tip.x + (cos(rad) * len * 0.6).toFloat() + sway, tip.y + (sin(rad) * len * 0.6).toFloat() - 6.dp.toPx())
            drawPath(Path().apply { moveTo(tip.x, tip.y); quadraticBezierTo(ctl.x, ctl.y, end.x, end.y) }, Color(0xFF120826), style = Stroke(4.5.dp.toPx(), cap = StrokeCap.Round))
        }
    }
    palm(w * 0.1f, h * 0.36f, 10.dp.toPx(), 0f)
    palm(w * 0.88f, h * 0.46f, -12.dp.toPx(), 1.7f)
    // плавный переход в фон
    drawRect(Brush.verticalGradient(listOf(Color.Transparent, bg), startY = h * 0.62f, endY = h), size = Size(w, h))
}

/** Ночная сцена для фона переписки: градиент, неоновая сетка и пальма */
@Composable
fun ViceNightWall() {
    Canvas(Modifier.fillMaxSize()) {
        val w = size.width; val h = size.height
        drawRect(Brush.verticalGradient(listOf(Color(0xFF1A0B3A), Color(0xFF2B0F4F), Color(0xFF4A1559), Color(0xFF6B1D55))))
        val horizon = h * 0.62f
        for (i in 0..8) { val k = i / 8f; val y = horizon + (h - horizon) * k * k; drawLine(Color(0xFF2FD6D0).copy(alpha = 0.18f), Offset(0f, y), Offset(w, y), 1.dp.toPx()) }
        for (i in -6..6) drawLine(Color(0xFFFF4F8B).copy(alpha = 0.16f), Offset(w / 2 + i * 14.dp.toPx(), horizon), Offset(w / 2 + i * w * 0.28f, h), 1.dp.toPx())
        val x = w * 0.78f; val top = h * 0.3f; val tip = Offset(x - 14.dp.toPx(), top)
        val col = Color(0xFFFF9A3D).copy(alpha = 0.18f)
        drawPath(Path().apply { moveTo(x, horizon); quadraticBezierTo(x, (horizon + top) / 2, tip.x, tip.y) }, col, style = Stroke(6.dp.toPx(), cap = StrokeCap.Round))
        for (a in listOf(-165.0, -130.0, -95.0, -60.0, -20.0, 15.0)) {
            val rad = Math.toRadians(a); val L = 70.dp.toPx()
            drawPath(Path().apply { moveTo(tip.x, tip.y); quadraticBezierTo(tip.x + (cos(rad) * L * 0.6).toFloat(), tip.y + (sin(rad) * L * 0.6).toFloat() - 8.dp.toPx(), tip.x + (cos(rad) * L).toFloat(), tip.y + (sin(rad) * L * 0.55).toFloat() + 22.dp.toPx()) }, col, style = Stroke(5.dp.toPx(), cap = StrokeCap.Round))
        }
    }
}

/** Плашка-«стикер» как на загрузочных экранах: жёлтая, с чёрной обводкой и тенью, чуть наклонена */
@Composable
fun VicePlaque(text: String) {
    Box(Modifier.rotate(-2f)) {
        Box(Modifier.matchParentSize().offset(2.5.dp, 2.5.dp).background(Color(0xFF0C0620), RoundedCornerShape(7.dp)))
        Text(text.uppercase(), color = Color(0xFF140A2E), fontSize = 13.sp, fontWeight = FontWeight.Black, fontFamily = Vice.titleFont, letterSpacing = 0.8.sp,
            modifier = Modifier.background(Vice.sun, RoundedCornerShape(7.dp)).padding(horizontal = 11.dp, vertical = 3.dp))
    }
}

/** Заголовок в стиле темы: узкий жирный капслок с неоновым свечением */
val viceTitleStyle = TextStyle(color = Color.White, fontFamily = Vice.titleFont, fontWeight = FontWeight.Black,
    shadow = Shadow(Color(0xCCFF4F8B), Offset(0f, 2f), 14f))

/** Папка в списке чатов в теме: выбранная — жёлтая плашка с тенью, остальные — белым на стеклянной полосе */
@Composable
fun VicePill(text: String, on: Boolean, onClick: () -> Unit) {
    Box(Modifier.then(if (on) Modifier.rotate(-2f) else Modifier)) {
        if (on) Box(Modifier.matchParentSize().offset(2.dp, 2.dp).background(Color(0xFF0C0620), RoundedCornerShape(10.dp)))
        Box(Modifier.clip(RoundedCornerShape(10.dp)).background(if (on) Vice.sun else Color(0x57160A30))
            .clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 8.dp)) {
            Text(if (on) text.uppercase() else text, color = if (on) Vice.night else Color.White, fontWeight = if (on) FontWeight.Black else FontWeight.SemiBold,
                fontFamily = if (on) Vice.titleFont else null, fontSize = 14.5.sp, maxLines = 1, softWrap = false)
        }
    }
}

/** Звёзды «уровня розыска»: сколько чатов с непрочитанными (до пяти) */
@Composable
fun ViceStars(n: Int) {
    val t by rememberInfiniteTransition(label = "stars").animateFloat(0f, 1f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "s")
    Row(Modifier.padding(start = 4.dp), horizontalArrangement = Arrangement.spacedBy(1.dp)) {
        for (i in 0 until 5) {
            val on = i < n
            androidx.compose.material3.Icon(androidx.compose.material.icons.Icons.Filled.Star, null,
                tint = if (on) Vice.sun else Color.White.copy(alpha = 0.3f),
                modifier = Modifier.size(13.dp).then(if (on) Modifier.graphicsLayer { val s = 1f + 0.15f * t; scaleX = s; scaleY = s } else Modifier))
        }
    }
}

/** Закат над океаном — фон входящего звонка */
@Composable
fun ViceCallSunset() {
    Box(Modifier.fillMaxSize()) {
        ViceNightWall()
        Box(Modifier.fillMaxSize().viceSky(560.dp))
    }
}

/** Вступление при запуске: комикс-панели, LUMO и плашка VICE NIGHTS */
@Composable
fun ViceIntro(onDone: () -> Unit) {
    var step by remember { mutableIntStateOf(0) }
    var out by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        for (s in 1..5) { kotlinx.coroutines.delay(if (s == 4) 250 else if (s == 5) 400 else 150); step = s }
        kotlinx.coroutines.delay(1150); out = true; kotlinx.coroutines.delay(500); onDone()
    }
    val spec = spring<Float>(dampingRatio = 0.62f, stiffness = 420f)
    val a1 by animateFloatAsState(if (step >= 1) 1f else 0f, spec, label = "a1")
    val a2 by animateFloatAsState(if (step >= 2) 1f else 0f, spec, label = "a2")
    val a3 by animateFloatAsState(if (step >= 3) 1f else 0f, spec, label = "a3")
    val lg by animateFloatAsState(if (step >= 4) 1f else 0f, spring(dampingRatio = 0.5f, stiffness = 500f), label = "lg")
    val st by animateFloatAsState(if (step >= 5) 1f else 0f, spring(dampingRatio = 0.45f, stiffness = 600f), label = "st")
    val wipe by animateFloatAsState(if (out) 1f else 0f, tween(500, easing = FastOutSlowInEasing), label = "w")
    androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxSize()
        .graphicsLayer { translationX = size.width * wipe }
        .background(Color(0xFF140A2E))
        .clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) { out = true }) {
        val w = maxWidth; val h = maxHeight
        @Composable fun panel(m: Modifier, content: @Composable () -> Unit) {
            Box(m.background(Color.White).padding(5.dp).border(4.dp, Color(0xFF0C0620)).clip(RoundedCornerShape(0.dp))) { content() }
        }
        panel(Modifier.size(w * 0.68f, h * 0.46f).offset(-w * 0.04f, -h * 0.03f).graphicsLayer { alpha = a1; rotationZ = -12f + 8f * a1; translationX = -200f * (1 - a1); translationY = -120f * (1 - a1) }) {
            Box(Modifier.fillMaxSize().viceSky(h * 0.46f))
        }
        panel(Modifier.size(w * 0.56f, h * 0.44f).offset(w * 0.5f, h * 0.22f).graphicsLayer { alpha = a2; rotationZ = 14f - 9f * a2; translationX = 260f * (1 - a2) }) {
            VicePalms()
        }
        panel(Modifier.size(w * 0.76f, h * 0.4f).offset(-w * 0.06f, h * 0.64f).graphicsLayer { alpha = a3; rotationZ = -6f + 9f * a3; translationY = 220f * (1 - a3) }) {
            ViceNightWall()
        }
        Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.graphicsLayer { alpha = lg; val s = 2.6f - 1.6f * lg; scaleX = s; scaleY = s; rotationZ = -10f + 6f * lg }) {
                Text("LUMO", fontFamily = Vice.titleFont, fontWeight = FontWeight.Black, fontSize = 112.sp, color = Color(0xFF140A2E), modifier = Modifier.offset(7.dp, 7.dp))
                Text("LUMO", fontFamily = Vice.titleFont, fontWeight = FontWeight.Black, fontSize = 112.sp,
                    style = TextStyle(brush = Brush.verticalGradient(listOf(Color(0xFFFFE58A), Color(0xFFFFB347), Color(0xFFFF4F8B))),
                        shadow = Shadow(Color(0x99FF4F8B), Offset.Zero, 30f)))
            }
            Spacer(Modifier.height(10.dp))
            Box(Modifier.graphicsLayer { alpha = st; val s = 2.4f - 1f * st; scaleX = s; scaleY = s; rotationZ = 12f - 7f * st }) { VicePlaque("Vice Nights") }
        }
        if (step == 4) Box(Modifier.fillMaxSize().background(Color.White.copy(alpha = 0.6f)))
    }
}

/** Неоновые пальмы для вступления */
@Composable
fun VicePalms() {
    Canvas(Modifier.fillMaxSize()) {
        val w = size.width; val h = size.height
        drawRect(Color(0xFF0F0828))
        drawCircle(Color(0x2EFF4F8B), w * 0.18f, Offset(w * 0.72f, h * 0.28f))
        fun palm(x: Float, top: Float, c: Color, lw: Float, len: Float) {
            val tip = Offset(x + 22f, top)
            drawPath(Path().apply { moveTo(x, h); quadraticBezierTo(x + 4f, (h + top) / 2, tip.x, tip.y) }, c, style = Stroke(lw, cap = StrokeCap.Round))
            for (a in listOf(-160.0, -125.0, -95.0, -60.0, -25.0, 10.0)) {
                val r = Math.toRadians(a)
                drawPath(Path().apply { moveTo(tip.x, tip.y); quadraticBezierTo(tip.x + (cos(r) * len * 0.6).toFloat(), tip.y + (sin(r) * len * 0.6).toFloat() - 8f, tip.x + (cos(r) * len).toFloat(), tip.y + (sin(r) * len * 0.55).toFloat() + len * 0.3f) },
                    c, style = Stroke(lw * 0.85f, cap = StrokeCap.Round))
            }
        }
        palm(w * 0.5f, h * 0.36f, Color(0xFFFF4F8B), 6.dp.toPx(), w * 0.3f)
        palm(w * 0.2f, h * 0.62f, Color(0xD92FD6D0), 5.dp.toPx(), w * 0.2f)
    }
}
