package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import ru.volshebnymir.lumo.core.AppModel
import kotlin.math.*
import kotlin.random.Random

private fun giftGlow(id: String) = when (id) {
    "pearl" -> Color(0xFF35D6E8); "comet" -> Color(0xFFFF8A3D); "crystal" -> Color(0xFF7D8DFF)
    "key" -> Color(0xFFFFC247); "flower" -> Color(0xFFC066FF); else -> Color(0xFFB069FF)
}

private class Spark(val a: Float, val r: Float, val s: Float, val d: Float)
private class Conf(val x: Float, val v: Float, val w: Float, val ph: Float, val c: Int, val sz: Float)

/** Магическая анимация после покупки/подарка: сбор света → вспышка → лучи, конфетти, искры, название и плашка. */
@Composable
fun GiftCelebration(giftId: String, to: String?, name: String, serial: Int, supply: Int, onClose: () -> Unit) {
    val glow = remember(giftId) { giftGlow(giftId) }
    val gifting = to != null
    val t = remember { Animatable(0f) }
    val sparks = remember { List(70) { Spark(Random.nextFloat() * 6.283f, 0.55f + Random.nextFloat() * 0.5f, 1.5f + Random.nextFloat() * 3.5f, Random.nextFloat()) } }
    val conf = remember { List(60) { Conf(Random.nextFloat(), 0.25f + Random.nextFloat() * 0.5f, 0.4f + Random.nextFloat(), Random.nextFloat() * 6.28f, Random.nextInt(4), 5f + Random.nextFloat() * 7f) } }
    val confCols = remember(glow) { listOf(glow, Color.White, Color(0xFFFFC247), Color(0xFFFF6FB5)) }
    LaunchedEffect(Unit) {
        t.animateTo(if (gifting) 6.2f else 5.6f, tween(if (gifting) 6200 else 5600, easing = LinearEasing))
        delay(500); onClose()
    }
    val time = t.value
    val reveal = 1.4f
    val fly = if (gifting) 3.0f else 99f
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Box(Modifier.fillMaxSize().background(Brush.radialGradient(listOf(glow.copy(alpha = 0.28f), Color(0xFF05060F).copy(alpha = 0.96f))))
            .clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) { onClose() },
            contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                val c = Offset(size.width / 2, size.height * 0.40f)
                val m = min(size.width, size.height)
                // сбор света
                if (time < reveal) {
                    val k = time / reveal
                    sparks.forEach { s ->
                        val rr = m * 0.55f * s.r * (1 - k).pow(1.6f)
                        val ang = s.a + k * 5f * (1 + s.d)
                        drawCircle(glow.copy(alpha = (0.2f + 0.8f * k).coerceAtMost(1f)), s.s.dp.toPx(), c + Offset(cos(ang) * rr, sin(ang) * rr))
                    }
                    drawCircle(Brush.radialGradient(listOf(Color.White.copy(alpha = k), glow.copy(alpha = 0.6f * k), Color.Transparent), c, m * 0.12f * (0.4f + k)), m * 0.2f, c)
                }
                if (time >= reveal) {
                    val a = time - reveal
                    // вспышка и ударная волна
                    val fl = (1 - a / 0.6f).coerceIn(0f, 1f)
                    if (fl > 0) drawRect(Color.White.copy(alpha = fl * 0.85f))
                    for (i in 0..1) {
                        val w = ((a - i * 0.18f) / 1.3f).coerceIn(0f, 1f)
                        if (w in 0.001f..0.999f) drawCircle(glow.copy(alpha = (1 - w) * 0.8f), m * (0.1f + 0.85f * w), c, style = Stroke(width = (6 * (1 - w) + 1).dp.toPx()))
                    }
                    // лучи
                    val ra = (a / 0.8f).coerceIn(0f, 1f) * (if (time > fly + 0.8f) (1 - ((time - fly - 0.8f) / 1.2f)).coerceIn(0f, 1f) else 1f)
                    rotate(a * 18f, c) {
                        for (i in 0 until 14) {
                            val ang = i * (2 * PI / 14).toFloat()
                            val len = m * (0.55f + 0.1f * sin(a * 2 + i))
                            val e = c + Offset(cos(ang) * len, sin(ang) * len)
                            drawLine(Brush.linearGradient(listOf(glow.copy(alpha = 0.35f * ra), Color.Transparent), c, e), c, e, strokeWidth = (14 + 6 * (i % 3)).dp.toPx() / 3f)
                        }
                    }
                    // искры на орбитах
                    sparks.forEachIndexed { i, s ->
                        if (i % 2 == 0) {
                            val ang = s.a + a * (0.8f + s.d)
                            val rr = m * (0.22f + 0.2f * s.r) * (1f + 0.05f * sin(a * 3 + i))
                            val al = (0.4f + 0.6f * sin(a * 4 + s.d * 9).absoluteValue) * ra
                            drawCircle(Color.White.copy(alpha = al), s.s.dp.toPx() * 0.8f, c + Offset(cos(ang) * rr, sin(ang) * rr * 0.8f))
                            drawCircle(glow.copy(alpha = al * 0.4f), s.s.dp.toPx() * 2.2f, c + Offset(cos(ang) * rr, sin(ang) * rr * 0.8f))
                        }
                    }
                    // конфетти
                    if (a > 0.15f) conf.forEach { f ->
                        val ca = a - 0.15f
                        val y = c.y - m * 0.15f + ca * f.v * m * 0.55f - 0.18f * m * (1 - (ca * 2).coerceAtMost(1f))
                        if (y < size.height + 20) {
                            val x = f.x * size.width + sin(ca * 3 * f.w + f.ph) * 28.dp.toPx()
                            rotate(ca * 200f * f.w + f.ph * 50, Offset(x, y)) {
                                drawRect(confCols[f.c].copy(alpha = (1 - ca / 4.5f).coerceIn(0f, 1f)), Offset(x, y), androidx.compose.ui.geometry.Size(f.sz.dp.toPx() * 0.6f, f.sz.dp.toPx()))
                            }
                        }
                    }
                    // взрыв при полёте подарка
                    if (gifting && time > fly) {
                        val b = ((time - fly - 0.55f) / 1.1f)
                        if (b in 0f..1f) for (i in 0 until 40) {
                            val ang = i * 0.157f + sparks[i % sparks.size].d
                            val rr = m * 0.5f * b * (0.5f + sparks[i % sparks.size].d)
                            val p0 = Offset(size.width / 2, size.height * 0.08f)
                            drawCircle(glow.copy(alpha = 1 - b), (4 * (1 - b) + 1).dp.toPx(), p0 + Offset(cos(ang) * rr, sin(ang) * rr))
                        }
                    }
                }
            }
            // подарок
            if (time >= reveal * 0.7f) {
                val a = (time - reveal * 0.7f)
                val appear = (a / 1.1f).coerceIn(0f, 1f)
                val fk = if (gifting) ((time - fly) / 0.9f).coerceIn(0f, 1f) else 0f
                val ease = fk * fk
                Box(Modifier.fillMaxSize()) {
                    Box(Modifier.align(Alignment.TopCenter).padding(top = 150.dp).size(260.dp)
                        .graphicsLayer {
                            val sc = (0.2f + 0.8f * (1 - (1 - appear).pow(3))) * (1 - 0.8f * ease)
                            scaleX = sc; scaleY = sc
                            rotationY = (1 - appear) * 540f
                            cameraDistance = 14f * density
                            translationY = -ease * size.height * 1.7f
                            alpha = appear * (1 - (if (fk >= 1f) 1f else 0f))
                        }) { GiftAnimated(giftId, Modifier.fillMaxSize()) }
                }
            }
            // название по буквам + плашка
            if (time >= reveal + 0.5f) {
                val a = time - reveal - 0.5f
                val outA = if (gifting && time > fly + 2.4f) (1 - (time - fly - 2.4f) / 0.5f).coerceIn(0f, 1f) else 1f
                Column(Modifier.align(Alignment.Center).padding(top = 340.dp).alpha(outA), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(if (gifting) "Подарок отправлен" else "Ваш подарок", color = Color.White.copy(alpha = 0.75f), fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.height(6.dp))
                    Row {
                        name.forEachIndexed { i, ch ->
                            val k = ((a - i * 0.06f) / 0.5f).coerceIn(0f, 1f)
                            Text(ch.toString(), color = Color.White, fontSize = 32.sp, fontWeight = FontWeight.Black,
                                modifier = Modifier.alpha(k).blur(((1 - k) * 8).dp).graphicsLayer { translationY = (1 - k) * 18f })
                        }
                    }
                    Spacer(Modifier.height(10.dp))
                    val pk = ((a - 0.6f) / 0.5f).coerceIn(0f, 1f)
                    Box(Modifier.alpha(pk).graphicsLayer { scaleX = 0.8f + 0.2f * pk; scaleY = 0.8f + 0.2f * pk }
                        .clip(RoundedCornerShape(50)).background(glow.copy(alpha = 0.28f)).padding(horizontal = 18.dp, vertical = 8.dp)) {
                        Text("№$serial из $supply", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    }
                    if (gifting) {
                        Spacer(Modifier.height(10.dp))
                        Text("Получатель: ${AppModel.displayName(to)}", color = Color.White.copy(alpha = 0.8f * pk), fontSize = 15.sp, textAlign = TextAlign.Center)
                    }
                }
            }
        }
    }
}
