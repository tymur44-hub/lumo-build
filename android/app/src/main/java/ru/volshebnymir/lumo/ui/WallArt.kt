package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import kotlin.math.*

/** Номера обоев общие для чатов и настроек, такие же на iPhone: 0 — без обоев, 1–5 и 10–17 — для всех, 6–9 и 20–27 — Premium */
val WALL_FREE = listOf(0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16, 17)
val WALL_PREMIUM = listOf(6, 7, 8, 9, 20, 21, 22, 23, 24, 25, 26, 27)
val WALL_ALL = WALL_FREE + WALL_PREMIUM
fun wallIsPremium(i: Int) = i in 6..9 || i >= 20

/** Слой обоев с нужным номером (поверх цвета фона чата) */
@Composable
fun WallLayer(i: Int, p: Palette, modifier: Modifier = Modifier.fillMaxSize()) {
    if (i >= 10) WallArt(i, modifier)
    else wallPresetBrush(i, p)?.let { Box(modifier.background(it)) }
}

private val PURPLE = Color(0xFF7C5CFF)
private val TEAL = Color(0xFF13B0A5)
private val PINK = Color(0xFFFF5B8A)
private val BLUE = Color(0xFF22A6FF)

@Composable
fun WallArt(i: Int, modifier: Modifier = Modifier.fillMaxSize()) {
    Canvas(modifier) { drawWall(i) }
}

private fun DrawScope.star4(c: Offset, s: Float, col: Color) {
    val p = Path().apply {
        moveTo(c.x, c.y - s); quadraticTo(c.x, c.y, c.x + s, c.y); quadraticTo(c.x, c.y, c.x, c.y + s)
        quadraticTo(c.x, c.y, c.x - s, c.y); quadraticTo(c.x, c.y, c.x, c.y - s); close()
    }
    drawPath(p, col)
}

private fun DrawScope.scatterStars(n: Int, seed: Long, col: Color, maxR: Float) {
    val r = java.util.Random(seed)
    repeat(n) {
        val c = Offset(r.nextFloat() * size.width, r.nextFloat() * size.height)
        star4(c, (0.4f + r.nextFloat()) * maxR, col.copy(alpha = col.alpha * (0.4f + 0.6f * r.nextFloat())))
    }
}

private fun DrawScope.blob(c: Offset, rad: Float, col: Color) {
    drawCircle(Brush.radialGradient(listOf(col, Color.Transparent), c, rad), rad, c)
}

private fun DrawScope.drawWall(i: Int) {
    val w = size.width; val h = size.height; val d = density
    fun dp(x: Float) = x * d
    val line = Stroke(width = dp(1.4f))
    when (i) {
        // ----- для всех -----
        10 -> { // горошек в шахматном порядке
            val st = dp(26f); var y = 0f; var row = 0
            while (y < h + st) { var x = if (row % 2 == 0) 0f else st / 2; while (x < w + st) { drawCircle(PURPLE.copy(alpha = 0.22f), dp(2.8f), Offset(x, y)); x += st }; y += st * 0.8f; row++ }
        }
        11 -> { // соты
            val r = dp(26f); val dx = sqrt(3f) * r; val dy = 1.5f * r; var row = 0; var y = 0f
            while (y < h + r) {
                var x = if (row % 2 == 0) 0f else dx / 2
                while (x < w + r) {
                    val p = Path(); for (k in 0 until 6) { val a = (PI / 180 * (60 * k - 30)).toFloat(); val px = x + r * cos(a); val py = y + r * sin(a); if (k == 0) p.moveTo(px, py) else p.lineTo(px, py) }
                    p.close(); drawPath(p, TEAL.copy(alpha = 0.2f), style = line); x += dx
                }
                y += dy; row++
            }
        }
        12 -> { // волны
            var y = dp(20f); var k = 0
            while (y < h + dp(20f)) {
                val p = Path(); var x = 0f; p.moveTo(0f, y)
                while (x <= w) { p.lineTo(x, y + sin((x / dp(40f)) + k) * dp(8f)); x += dp(6f) }
                drawPath(p, (if (k % 2 == 0) PINK else PURPLE).copy(alpha = 0.2f), style = line); y += dp(30f); k++
            }
        }
        13 -> { // ромбы
            val st = dp(42f); var x = -h
            while (x < w + h) {
                drawLine(BLUE.copy(alpha = 0.18f), Offset(x, 0f), Offset(x + h, h), dp(1.2f)); drawLine(BLUE.copy(alpha = 0.18f), Offset(x + h, 0f), Offset(x, h), dp(1.2f)); x += st
            }
        }
        14 -> { scatterStars(70, 14, PURPLE.copy(alpha = 0.42f), dp(7f)); scatterStars(40, 15, PINK.copy(alpha = 0.35f), dp(4f)) } // звёзды
        15 -> { // кольца от углов
            for (c in listOf(Offset(0f, 0f), Offset(w, h))) { var r = dp(30f); while (r < max(w, h) * 1.3f) { drawCircle(TEAL.copy(alpha = 0.18f), r, c, style = line); r += dp(30f) } }
        }
        16 -> { // зигзаг
            var y = dp(18f); var k = 0
            while (y < h + dp(20f)) {
                val p = Path(); var x = 0f; var up = true; p.moveTo(0f, y)
                while (x <= w + dp(14f)) { x += dp(14f); p.lineTo(x, y + if (up) -dp(7f) else dp(7f)); up = !up }
                drawPath(p, (if (k % 2 == 0) PURPLE else TEAL).copy(alpha = 0.2f), style = line); y += dp(26f); k++
            }
        }
        17 -> { // плюсики
            val st = dp(38f); var y = st / 2; var row = 0
            while (y < h + st) {
                var x = if (row % 2 == 0) st / 2 else st
                while (x < w + st) { val s = dp(5f); val c = PINK.copy(alpha = 0.26f); drawLine(c, Offset(x - s, y), Offset(x + s, y), dp(1.6f)); drawLine(c, Offset(x, y - s), Offset(x, y + s), dp(1.6f)); x += st }
                y += st / 2; row++
            }
        }
        // ----- Premium -----
        20 -> { // аврора
            drawRect(Brush.verticalGradient(listOf(Color(0xFF071A2E), Color(0xFF1A0B3A))))
            blob(Offset(w * 0.2f, h * 0.22f), w * 0.8f, Color(0xFF2EE6A6).copy(alpha = 0.34f))
            blob(Offset(w * 0.85f, h * 0.35f), w * 0.75f, Color(0xFF22C1FF).copy(alpha = 0.30f))
            blob(Offset(w * 0.4f, h * 0.7f), w * 0.9f, Color(0xFFB069FF).copy(alpha = 0.30f))
            scatterStars(60, 20, Color.White.copy(alpha = 0.6f), dp(3f))
        }
        21 -> { // неоновая сетка
            drawRect(Brush.verticalGradient(listOf(Color(0xFF0D0221), Color(0xFF2A0A4A))))
            val hy = h * 0.62f
            drawCircle(Brush.verticalGradient(listOf(Color(0xFFFFD24A), Color(0xFFFF3D8A)), hy - w * 0.22f, hy), w * 0.22f, Offset(w / 2, hy - w * 0.04f))
            drawRect(Color(0xFF0D0221), Offset(0f, hy), Size(w, h - hy))
            val neon = Color(0xFFFF2BD6).copy(alpha = 0.45f)
            var k = -12; while (k <= 12) { drawLine(neon, Offset(w / 2, hy), Offset(w / 2 + k * w * 0.18f, h), dp(1.2f)); k++ }
            var t = 0f; while (t < 1f) { val y = hy + (h - hy) * t * t; drawLine(Color(0xFF22E6FF).copy(alpha = 0.4f), Offset(0f, y), Offset(w, y), dp(1.2f)); t += 0.09f }
            drawLine(Color(0xFFFF2BD6), Offset(0f, hy), Offset(w, hy), dp(1.6f))
        }
        22 -> { // галактика
            drawRect(Brush.verticalGradient(listOf(Color(0xFF04050E), Color(0xFF150C32))))
            blob(Offset(w * 0.3f, h * 0.3f), w * 0.9f, Color(0xFF7C3DFF).copy(alpha = 0.30f))
            blob(Offset(w * 0.8f, h * 0.6f), w * 0.8f, Color(0xFFFF4DA6).copy(alpha = 0.22f))
            blob(Offset(w * 0.2f, h * 0.85f), w * 0.7f, Color(0xFF2E7BFF).copy(alpha = 0.24f))
            val r = java.util.Random(22); repeat(160) { drawCircle(Color.White.copy(alpha = 0.3f + 0.6f * r.nextFloat()), dp(0.6f + r.nextFloat() * 1.2f), Offset(r.nextFloat() * w, r.nextFloat() * h)) }
            scatterStars(14, 23, Color.White.copy(alpha = 0.85f), dp(7f))
        }
        23 -> { // золотое ар-деко (чешуя)
            drawRect(Brush.verticalGradient(listOf(Color(0xFF14110A), Color(0xFF2B2210))))
            val gold = Color(0xFFE8C26A); val r = dp(24f); var y = 0f; var row = 0
            while (y < h + r) {
                var x = if (row % 2 == 0) 0f else r
                while (x < w + r * 2) { for (k in 1..3) drawArc(gold.copy(alpha = 0.34f - k * 0.07f), 180f, 180f, false, Offset(x - r * k / 3f, y - r * k / 3f), Size(2 * r * k / 3f, 2 * r * k / 3f), style = Stroke(dp(1.1f))); x += r * 2 }
                y += r * 0.9f; row++
            }
        }
        24 -> { // океан
            drawRect(Brush.verticalGradient(listOf(Color(0xFF042B40), Color(0xFF0B6A85))))
            for (k in 0 until 6) {
                val y0 = h * (0.25f + 0.13f * k); val p = Path(); p.moveTo(0f, h); p.lineTo(0f, y0)
                var x = 0f; while (x <= w) { p.lineTo(x, y0 + sin(x / dp(50f) + k * 1.3f) * dp(10f)); x += dp(6f) }
                p.lineTo(w, h); p.close(); drawPath(p, Color(0xFF9BF0FF).copy(alpha = 0.07f))
                val l = Path(); x = 0f; l.moveTo(0f, y0); while (x <= w) { l.lineTo(x, y0 + sin(x / dp(50f) + k * 1.3f) * dp(10f)); x += dp(6f) }
                drawPath(l, Color(0xFFBDF7FF).copy(alpha = 0.22f), style = Stroke(dp(1.2f)))
            }
            val r = java.util.Random(24); repeat(22) { drawCircle(Color.White.copy(alpha = 0.18f), dp(2f + r.nextFloat() * 5f), Offset(r.nextFloat() * w, r.nextFloat() * h), style = Stroke(dp(1f))) }
        }
        25 -> { // сакура
            drawRect(Brush.verticalGradient(listOf(Color(0xFF2A0F24), Color(0xFF5E2146))))
            blob(Offset(w * 0.8f, h * 0.15f), w * 0.8f, Color(0xFFFF8FB8).copy(alpha = 0.22f))
            val r = java.util.Random(25)
            repeat(46) {
                val c = Offset(r.nextFloat() * w, r.nextFloat() * h); val s = dp(5f + r.nextFloat() * 6f); val a = r.nextFloat() * 180f
                rotate(a, c) { drawOval(Color(0xFFFFB3D1).copy(alpha = 0.25f + 0.4f * r.nextFloat()), Offset(c.x - s, c.y - s * 0.55f), Size(s * 2, s * 1.1f)) }
            }
        }
        26 -> { // топография
            drawRect(Brush.verticalGradient(listOf(Color(0xFF0E2B25), Color(0xFF15483A))))
            for ((ci, c) in listOf(Offset(w * 0.25f, h * 0.3f), Offset(w * 0.8f, h * 0.75f)).withIndex()) {
                for (k in 1..16) {
                    val p = Path(); var t = 0f; val base = dp(16f) * k
                    while (t <= 6.3f) { val rr = base * (1f + 0.1f * sin(3 * t + k * 0.4f + ci) + 0.05f * sin(5 * t - k * 0.3f)); val x = c.x + rr * cos(t); val y = c.y + rr * sin(t); if (t == 0f) p.moveTo(x, y) else p.lineTo(x, y); t += 0.1f }
                    p.close(); drawPath(p, Color(0xFF7DFFD0).copy(alpha = 0.2f), style = Stroke(dp(1.1f)))
                }
            }
        }
        27 -> { // голограмма
            drawRect(Color(0xFF12101F))
            drawRect(Brush.linearGradient(listOf(Color(0xFF7AF0FF), Color(0xFFFF9BE8), Color(0xFFB59BFF), Color(0xFF9BFFD6)), Offset(0f, 0f), Offset(w, h)), alpha = 0.5f)
            var x = -h; while (x < w + h) { drawLine(Color.White.copy(alpha = 0.09f), Offset(x, 0f), Offset(x + h, h), dp(5f)); x += dp(18f) }
            blob(Offset(w * 0.7f, h * 0.2f), w * 0.7f, Color.White.copy(alpha = 0.22f))
        }
    }
}
