package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.Alignment
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

/** Нарисованные анимированные значки статуса (не эмодзи): рисуются кистью, у каждого своя анимация */
@Composable
fun DrawnStatus(key: String, size: Dp, modifier: Modifier = Modifier) {
    val tr = rememberInfiniteTransition(label = "drawn")
    val t by tr.animateFloat(0f, 1f, infiniteRepeatable(tween(2400, easing = LinearEasing), RepeatMode.Restart), label = "t")
    Canvas(modifier.size(size)) {
        val s = this.size.minDimension / 100f
        scale(s, Offset.Zero) { drawStatusIcon(key, t) }
    }
}

private fun vg(y0: Float, y1: Float, vararg c: Long) = Brush.verticalGradient(c.map { Color(it) }, y0, y1)
private fun dg(vararg c: Long) = Brush.linearGradient(c.map { Color(it) }, Offset(0f, 0f), Offset(100f, 100f))

private fun starPath(cx: Float, cy: Float, r: Float, k: Float = 0.5f): Path {
    val p = Path()
    for (i in 0 until 10) {
        val rr = if (i % 2 == 0) r else r * k
        val a = -PI / 2 + i * PI / 5
        val x = cx + (rr * cos(a)).toFloat(); val y = cy + (rr * sin(a)).toFloat()
        if (i == 0) p.moveTo(x, y) else p.lineTo(x, y)
    }
    p.close(); return p
}

private fun DrawScope.sparkle(cx: Float, cy: Float, r: Float, alpha: Float, color: Color = Color.White) {
    if (alpha <= 0.01f) return
    val p = Path().apply {
        moveTo(cx, cy - r); quadraticBezierTo(cx, cy, cx + r, cy); quadraticBezierTo(cx, cy, cx, cy + r)
        quadraticBezierTo(cx, cy, cx - r, cy); quadraticBezierTo(cx, cy, cx, cy - r); close()
    }
    drawPath(p, color.copy(alpha = alpha.coerceIn(0f, 1f)))
}

private fun DrawScope.drawStatusIcon(k: String, t: Float) {
    val w = (2 * PI * t).toFloat()
    val sn = sin(w); val cs = cos(w)
    when (k) {
        "fire" -> {
            scale(1f - 0.03f * sn, 1f + 0.08f * sn, Offset(50f, 95f)) {
                val outer = Path().apply {
                    moveTo(50f, 4f); cubicTo(58f, 24f, 82f, 34f, 82f, 62f); cubicTo(82f, 83f, 67f, 95f, 50f, 95f)
                    cubicTo(33f, 95f, 18f, 83f, 18f, 62f); cubicTo(18f, 48f, 26f, 40f, 33f, 32f)
                    cubicTo(36f, 44f, 40f, 48f, 44f, 48f); cubicTo(40f, 30f, 44f, 14f, 50f, 4f); close()
                }
                drawPath(outer, vg(4f, 95f, 0xFFFFC93C, 0xFFFF7A18, 0xFFE8321E))
                scale(1f, 1f + 0.1f * cs, Offset(50f, 95f)) {
                    val inner = Path().apply {
                        moveTo(50f, 44f); cubicTo(56f, 56f, 68f, 62f, 68f, 76f); cubicTo(68f, 87f, 60f, 94f, 50f, 94f)
                        cubicTo(40f, 94f, 32f, 87f, 32f, 76f); cubicTo(32f, 64f, 46f, 58f, 50f, 44f); close()
                    }
                    drawPath(inner, vg(44f, 94f, 0xFFFFF3A0, 0xFFFFC93C))
                }
            }
        }
        "heart" -> {
            val s = 1f + 0.1f * max(0f, sn) + 0.05f * max(0f, sin(w * 2 + 1f))
            scale(s, s, Offset(50f, 52f)) {
                val h = Path().apply {
                    moveTo(50f, 90f); cubicTo(8f, 60f, 4f, 30f, 26f, 18f); cubicTo(40f, 11f, 48f, 20f, 50f, 28f)
                    cubicTo(52f, 20f, 60f, 11f, 74f, 18f); cubicTo(96f, 30f, 92f, 60f, 50f, 90f); close()
                }
                drawPath(h, dg(0xFFFF6B8B, 0xFFE0245E))
                drawOval(Color.White.copy(alpha = 0.55f), Offset(22f, 26f), Size(14f, 9f))
            }
        }
        "star" -> {
            rotate(14f * sn, Offset(50f, 54f)) {
                val s = 1f + 0.06f * cs
                scale(s, s, Offset(50f, 54f)) {
                    drawPath(starPath(50f, 54f, 46f, 0.48f), vg(8f, 98f, 0xFFFFE066, 0xFFFFB020, 0xFFFF8A00))
                    drawPath(starPath(50f, 54f, 46f, 0.48f), Color(0xFFFFFFFF).copy(alpha = 0.55f), style = Stroke(1.6f))
                }
            }
            sparkle(84f, 18f, 10f, max(0f, cs))
            sparkle(16f, 80f, 7f, max(0f, -cs))
        }
        "rocket" -> {
            translate(0f, 3f * sn) {
                rotate(35f, Offset(50f, 50f)) {
                    val flame = Path().apply { moveTo(40f, 72f); cubicTo(40f, 86f, 48f, 90f + 6f * sn, 50f, 96f + 6f * sn); cubicTo(52f, 90f + 6f * sn, 60f, 86f, 60f, 72f); close() }
                    drawPath(flame, vg(72f, 100f, 0xFFFFE066, 0xFFFF6A00))
                    val finL = Path().apply { moveTo(34f, 52f); lineTo(16f, 78f); lineTo(36f, 72f); close() }
                    val finR = Path().apply { moveTo(66f, 52f); lineTo(84f, 78f); lineTo(64f, 72f); close() }
                    drawPath(finL, Color(0xFFE8321E)); drawPath(finR, Color(0xFFE8321E))
                    val body = Path().apply { moveTo(50f, 4f); cubicTo(72f, 22f, 74f, 52f, 66f, 74f); lineTo(34f, 74f); cubicTo(26f, 52f, 28f, 22f, 50f, 4f); close() }
                    drawPath(body, vg(4f, 74f, 0xFFFFFFFF, 0xFFD8E1F0))
                    val nose = Path().apply { moveTo(50f, 4f); cubicTo(60f, 12f, 66f, 20f, 68f, 28f); lineTo(32f, 28f); cubicTo(34f, 20f, 40f, 12f, 50f, 4f); close() }
                    drawPath(nose, Color(0xFFE8321E))
                    drawCircle(Color(0xFF3A86FF), 9f, Offset(50f, 46f)); drawCircle(Color.White.copy(alpha = 0.6f), 3f, Offset(47f, 43f))
                    drawRect(Color(0xFF8A94A6), Offset(34f, 70f), Size(32f, 6f))
                }
            }
        }
        "crown" -> {
            translate(0f, -3f * abs(sn)) {
                val c = Path().apply {
                    moveTo(10f, 78f); lineTo(6f, 28f); lineTo(30f, 52f); lineTo(50f, 16f); lineTo(70f, 52f); lineTo(94f, 28f); lineTo(90f, 78f); close()
                }
                drawPath(c, vg(16f, 78f, 0xFFFFE066, 0xFFFFB020))
                drawRoundRect(Brush.horizontalGradient(listOf(Color(0xFFFFB020), Color(0xFFFFE066), Color(0xFFFFB020)), 10f, 90f), Offset(10f, 78f), Size(80f, 12f), androidx.compose.ui.geometry.CornerRadius(5f, 5f))
                drawCircle(Color(0xFFE8321E), 5.5f, Offset(50f, 66f)); drawCircle(Color(0xFF3A86FF), 4.5f, Offset(28f, 68f)); drawCircle(Color(0xFF2BD67B), 4.5f, Offset(72f, 68f))
                drawCircle(Color(0xFFFFE066), 5f, Offset(6f, 26f)); drawCircle(Color(0xFFFFE066), 5f, Offset(94f, 26f)); drawCircle(Color(0xFFFFE066), 5.5f, Offset(50f, 14f))
            }
            sparkle(30f + 40f * ((t + 0.0f) % 1f), 36f, 8f, sin((PI * ((t) % 1f)).toFloat()))
        }
        "gem" -> {
            val top = Path().apply { moveTo(28f, 16f); lineTo(72f, 16f); lineTo(94f, 40f); lineTo(6f, 40f); close() }
            val bot = Path().apply { moveTo(6f, 40f); lineTo(94f, 40f); lineTo(50f, 94f); close() }
            drawPath(bot, vg(40f, 94f, 0xFF29B6F6, 0xFF1565C0)); drawPath(top, vg(16f, 40f, 0xFF9BE7FF, 0xFF4FC3F7))
            val line = Color.White.copy(alpha = 0.7f)
            drawLine(line, Offset(40f, 16f), Offset(28f, 40f), 1.8f); drawLine(line, Offset(60f, 16f), Offset(72f, 40f), 1.8f)
            drawLine(line, Offset(28f, 40f), Offset(50f, 94f), 1.8f); drawLine(line, Offset(72f, 40f), Offset(50f, 94f), 1.8f)
            drawLine(line, Offset(40f, 16f), Offset(50f, 40f), 1.8f); drawLine(line, Offset(60f, 16f), Offset(50f, 40f), 1.8f)
            val a = (t * 3f) % 1f
            sparkle(24f + 52f * a, 24f + 8f * a, 11f, sin((PI * a).toFloat()))
        }
        "bolt" -> {
            val glow = 0.5f + 0.5f * max(0f, sn)
            drawCircle(Color(0xFFFFE066).copy(alpha = 0.25f * glow), 44f, Offset(50f, 50f))
            scale(1f + 0.04f * glow, 1f + 0.04f * glow, Offset(50f, 50f)) {
                val b = Path().apply { moveTo(60f, 2f); lineTo(18f, 56f); lineTo(44f, 56f); lineTo(34f, 98f); lineTo(82f, 38f); lineTo(54f, 38f); lineTo(70f, 2f); close() }
                drawPath(b, vg(2f, 98f, 0xFFFFF176, 0xFFFFC107, 0xFFFF9800))
            }
        }
        "ghost" -> {
            translate(0f, 4f * sn) {
                val g = Path().apply {
                    moveTo(16f, 94f); lineTo(16f, 46f); cubicTo(16f, 20f, 32f, 6f, 50f, 6f); cubicTo(68f, 6f, 84f, 20f, 84f, 46f); lineTo(84f, 94f)
                    lineTo(72f, 84f); lineTo(61f, 94f); lineTo(50f, 84f); lineTo(39f, 94f); lineTo(28f, 84f); close()
                }
                drawPath(g, vg(6f, 94f, 0xFFFFFFFF, 0xFFC9D6F2))
                drawOval(Color(0xFF2A2F4A), Offset(33f, 36f), Size(11f, 15f)); drawOval(Color(0xFF2A2F4A), Offset(56f, 36f), Size(11f, 15f))
                drawOval(Color(0xFF2A2F4A), Offset(44f, 60f), Size(12f, 9f + 3f * sn))
            }
        }
        "sun" -> {
            rotate(360f * t, Offset(50f, 50f)) {
                for (i in 0 until 8) rotate(i * 45f, Offset(50f, 50f)) {
                    drawLine(Color(0xFFFFB020), Offset(50f, 6f), Offset(50f, 20f), 7f, StrokeCap.Round)
                }
            }
            val s = 1f + 0.05f * sn
            scale(s, s, Offset(50f, 50f)) { drawCircle(Brush.radialGradient(listOf(Color(0xFFFFF176), Color(0xFFFFA000)), Offset(44f, 44f), 34f), 27f, Offset(50f, 50f)) }
        }
        "moon" -> {
            rotate(7f * sn, Offset(50f, 50f)) {
                val m = Path().apply { moveTo(64f, 6f); cubicTo(32f, 8f, 10f, 34f, 14f, 62f); cubicTo(18f, 88f, 50f, 100f, 82f, 84f); cubicTo(52f, 78f, 40f, 40f, 64f, 6f); close() }
                drawPath(m, dg(0xFFFFF3B0, 0xFFFFC94D))
            }
            val tw = 0.5f + 0.5f * sn
            sparkle(78f, 26f, 6f + 6f * tw, 0.4f + 0.6f * tw); sparkle(88f, 60f, 4f + 3f * (1 - tw), 0.3f + 0.6f * (1 - tw))
        }
        "clover" -> {
            rotate(14f * sn, Offset(50f, 50f)) {
                val stem = Path().apply { moveTo(50f, 50f); cubicTo(54f, 72f, 60f, 84f, 70f, 94f) }
                drawPath(stem, Color(0xFF1E8E4E), style = Stroke(6f, cap = StrokeCap.Round))
                for (i in 0 until 4) rotate(i * 90f + 45f, Offset(50f, 50f)) {
                    val leaf = Path().apply {
                        moveTo(50f, 50f); cubicTo(28f, 36f, 24f, 16f, 37f, 10f); cubicTo(44f, 7f, 49f, 13f, 50f, 20f)
                        cubicTo(51f, 13f, 56f, 7f, 63f, 10f); cubicTo(76f, 16f, 72f, 36f, 50f, 50f); close()
                    }
                    drawPath(leaf, vg(8f, 50f, 0xFF7BE495, 0xFF1FA85A))
                }
            }
        }
        "note" -> {
            rotate(9f * sn, Offset(50f, 80f)) {
                val s = 1f + 0.05f * abs(cs)
                scale(s, s, Offset(50f, 80f)) {
                    val flag = Path().apply { moveTo(52f, 14f); cubicTo(60f, 34f, 84f, 34f, 80f, 58f); cubicTo(72f, 44f, 58f, 46f, 52f, 40f); close() }
                    drawPath(flag, dg(0xFFB66CFF, 0xFFFF5BB8))
                    drawRoundRect(dg(0xFFB66CFF, 0xFFFF5BB8), Offset(46f, 14f), Size(8f, 64f), androidx.compose.ui.geometry.CornerRadius(3f, 3f))
                    rotate(-20f, Offset(32f, 78f)) { drawOval(dg(0xFF8A5BFF, 0xFFFF5BB8), Offset(14f, 66f), Size(36f, 26f)) }
                }
            }
        }
        else -> drawPath(starPath(50f, 54f, 46f, 0.48f), vg(8f, 98f, 0xFFFFE066, 0xFFFFB020))
    }
}

private val STAR3D: List<FloatArray> by lazy {
    var pts = List(10) { i ->
        val r = if (i % 2 == 0) 1f else 0.58f
        val a = -PI / 2 + i * PI / 5
        floatArrayOf((r * cos(a)).toFloat(), (r * sin(a)).toFloat())
    }
    repeat(3) {
        val out = ArrayList<FloatArray>()
        for (i in pts.indices) {
            val p0 = pts[i]; val p1 = pts[(i + 1) % pts.size]
            out.add(floatArrayOf(0.75f * p0[0] + 0.25f * p1[0], 0.75f * p0[1] + 0.25f * p1[1]))
            out.add(floatArrayOf(0.25f * p0[0] + 0.75f * p1[0], 0.25f * p0[1] + 0.75f * p1[1]))
        }
        pts = out
    }
    pts
}

private fun mix(a: Color, b: Color, t: Float) = Color(a.red + (b.red - a.red) * t, a.green + (b.green - a.green) * t, a.blue + (b.blue - a.blue) * t, 1f)

/** Объёмная звезда: настоящая призма с толщиной, вращается вокруг вертикальной оси, боковые грани освещены */
private fun DrawScope.draw3dStar(deg: Float, tiltDeg: Float, pulse: Float) {
    val th = Math.toRadians(deg.toDouble()); val c = cos(th).toFloat(); val sn = sin(th).toFloat()
    val tl = Math.toRadians(tiltDeg.toDouble()); val ct = cos(tl).toFloat(); val st = sin(tl).toFloat()
    val R = 36f * (0.97f + 0.03f * pulse); val D = 0.2f
    fun proj(x: Float, y: Float, z: Float): Triple<Float, Float, Float> {
        val x1 = x * c + z * sn; val z1 = -x * sn + z * c
        val y2 = y * ct - z1 * st; val z2 = y * st + z1 * ct
        val k = 1f / (1f - z2 * 0.28f)
        return Triple(50f + x1 * R * k, 53f + y2 * R * k, z2)
    }
    val pts = STAR3D; val n = pts.size
    var area = 0f
    for (i in 0 until n) { val a = pts[i]; val b = pts[(i + 1) % n]; area += a[0] * b[1] - b[0] * a[1] }
    val sgn = if (area > 0) 1f else -1f
    // тень под звездой
    drawOval(Color(0xFF6C4DFF).copy(alpha = 0.16f), Offset(26f, 90f), Size(48f, 6f))
    val c1 = Color(0xFF5B8CFF); val c2 = Color(0xFFA066FF); val c3 = Color(0xFFFF6BCB)
    // боковые грани (только повёрнутые к зрителю), дальние первыми
    class Side(val path: Path, val color: Color, val z: Float)
    val sides = ArrayList<Side>()
    for (i in 0 until n) {
        val a = pts[i]; val b = pts[(i + 1) % n]
        val dx = b[0] - a[0]; val dy = b[1] - a[1]
        val len = kotlin.math.sqrt(dx * dx + dy * dy).coerceAtLeast(1e-5f)
        val nx = sgn * dy / len; val ny = -sgn * dx / len
        val z1 = -nx * sn; val nz = ny * st + z1 * ct
        if (nz <= 0f) continue
        val pa = proj(a[0], a[1], D); val pb = proj(b[0], b[1], D); val qa = proj(a[0], a[1], -D); val qb = proj(b[0], b[1], -D)
        val path = Path().apply { moveTo(pa.first, pa.second); lineTo(pb.first, pb.second); lineTo(qb.first, qb.second); lineTo(qa.first, qa.second); close() }
        val t = i.toFloat() / n
        val base = if (t < 0.5f) mix(c2, c3, t * 2f) else mix(c3, c1, (t - 0.5f) * 2f)
        val light = (0.45f + 0.55f * nz).coerceIn(0f, 1f)
        sides.add(Side(path, mix(Color(0xFF2B1D7A), base, light), (pa.third + qa.third) / 2))
    }
    sides.sortedBy { it.z }.forEach { drawPath(it.path, it.color); drawPath(it.path, it.color, style = Stroke(0.6f)) }
    // лицевая или оборотная сторона
    val front = c * ct > 0f
    val zf = if (front) D else -D
    val face = Path()
    val inner = Path()
    for (i in 0 until n) {
        val q = proj(pts[i][0], pts[i][1], zf)
        if (i == 0) face.moveTo(q.first, q.second) else face.lineTo(q.first, q.second)
        val w = proj(pts[i][0] * 0.7f, pts[i][1] * 0.7f, zf + (if (front) 0.05f else -0.05f))
        if (i == 0) inner.moveTo(w.first, w.second) else inner.lineTo(w.first, w.second)
    }
    face.close(); inner.close()
    val g1 = proj(-1f, -1f, zf); val g2 = proj(1f, 1f, zf)
    val br = Brush.linearGradient(listOf(c1, c2, c3), Offset(g1.first, g1.second), Offset(g2.first, g2.second))
    drawPath(face, br)
    drawPath(face, Color.White.copy(alpha = 0.35f), style = Stroke(0.8f))
    drawPath(inner, Brush.linearGradient(listOf(Color.White.copy(alpha = 0.32f), Color.White.copy(alpha = 0.04f)), Offset(g1.first, g1.second), Offset(g2.first, g2.second)))
    val hi = proj(-0.35f + 0.5f * sn, -0.45f, zf)
    drawCircle(Brush.radialGradient(listOf(Color.White.copy(alpha = 0.55f), Color.Transparent), Offset(hi.first, hi.second), 15f), 15f, Offset(hi.first, hi.second))
}

/** Вращающаяся объёмная звезда Premium */
@Composable
fun PremiumStar(size: Dp, modifier: Modifier = Modifier) {
    val tr = rememberInfiniteTransition(label = "pstar")
    val spin by tr.animateFloat(0f, 360f, infiniteRepeatable(tween(4200, easing = androidx.compose.animation.core.FastOutSlowInEasing), RepeatMode.Restart), label = "spin")
    val tilt by tr.animateFloat(-14f, 14f, infiniteRepeatable(tween(2600, easing = androidx.compose.animation.core.FastOutSlowInEasing), RepeatMode.Reverse), label = "tilt")
    val pulse by tr.animateFloat(0f, 1f, infiniteRepeatable(tween(1800, easing = LinearEasing), RepeatMode.Reverse), label = "pulse")
    Canvas(modifier.size(size)) {
        val s = this.size.minDimension / 100f
        scale(s, Offset.Zero) { draw3dStar(spin, tilt, pulse) }
    }
}

/** Поле мерцающих искр (как в шапке Premium): фиолетовые крестики и звёздочки */
@Composable
fun SparkleField(modifier: Modifier = Modifier, count: Int = 46) {
    val tr = rememberInfiniteTransition(label = "sf")
    val t by tr.animateFloat(0f, 1f, infiniteRepeatable(tween(3200, easing = LinearEasing), RepeatMode.Restart), label = "t")
    val pts = androidx.compose.runtime.remember(count) {
        val r = kotlin.random.Random(7)
        List(count) { floatArrayOf(r.nextFloat(), r.nextFloat(), 3f + r.nextFloat() * 6f, r.nextFloat()) }
    }
    Canvas(modifier) {
        for (q in pts) {
            val ph = (t + q[3]) % 1f
            val a = (0.25f + 0.75f * sin((PI * ph).toFloat())).coerceIn(0f, 1f)
            val x = q[0] * size.width; val y = q[1] * size.height
            val col = if (q[3] > 0.5f) Color(0xFF9B6BFF) else Color(0xFF6C8CFF)
            val r = q[2] * (0.7f + 0.5f * a)
            drawLine(col.copy(alpha = a * 0.8f), Offset(x - r, y), Offset(x + r, y), 2f, StrokeCap.Round)
            drawLine(col.copy(alpha = a * 0.8f), Offset(x, y - r), Offset(x, y + r), 2f, StrokeCap.Round)
        }
    }
}

/** Звезда Premium с маленькими звёздочками, которые отлетают от неё во все стороны */
@Composable
fun StarEmitter(size: Dp = 130.dp, modifier: Modifier = Modifier) {
    val tr = rememberInfiniteTransition(label = "se")
    val t by tr.animateFloat(0f, 1f, infiniteRepeatable(tween(3600, easing = LinearEasing), RepeatMode.Restart), label = "t")
    Box(modifier.size(size * 2.4f), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val c = center
            val n = 16
            for (i in 0 until n) {
                val ph = (t + i.toFloat() / n) % 1f
                val ang = (i * 137.5f) * (PI / 180f).toFloat()
                val dist = size.toPx() * (0.38f + 0.9f * ph) + (i % 3) * 6f
                val x = c.x + cos(ang) * dist
                val y = c.y + sin(ang) * dist - ph * size.toPx() * 0.1f
                val a = (1f - ph) * (if (ph < 0.08f) ph / 0.08f else 1f)
                val r = (4f + (i % 4) * 2.2f) * (1f - 0.5f * ph) * density
                val col = if (i % 2 == 0) Color(0xFFFFD36B) else Color(0xFFB69CFF)
                val rot = ph * 220f + i * 20f
                rotate(rot, Offset(x, y)) {
                    val path = androidx.compose.ui.graphics.Path()
                    for (k in 0 until 10) {
                        val rr = if (k % 2 == 0) r else r * 0.45f
                        val aa = (k * 36f - 90f) * (PI / 180f).toFloat()
                        val px = x + cos(aa) * rr; val py = y + sin(aa) * rr
                        if (k == 0) path.moveTo(px, py) else path.lineTo(px, py)
                    }
                    path.close()
                    drawPath(path, col.copy(alpha = a.coerceIn(0f, 1f)))
                }
            }
        }
        PremiumStar(size)
    }
}

private fun Modifier.graphicsLayerSpin(deg: Float, density: Float): Modifier =
    this.then(Modifier.graphicsLayer { rotationY = deg; cameraDistance = 14f * density })
