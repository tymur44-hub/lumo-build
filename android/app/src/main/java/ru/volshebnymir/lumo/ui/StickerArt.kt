package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.unit.Dp
import androidx.compose.foundation.layout.size

/** Настоящие нарисованные стикеры на тему Хэллоуин (вместо обычных эмодзи) */
val STICKER_IDS = listOf("pumpkin", "ghost", "cat", "candy", "spider", "skull", "bat", "potion")
val STICKER_NAMES = mapOf(
    "pumpkin" to "Тыква", "ghost" to "Привидение", "cat" to "Чёрный кот", "candy" to "Конфета",
    "spider" to "Паук", "skull" to "Череп", "bat" to "Летучая мышь", "potion" to "Зелье",
)

/** Префикс, которым помечаются новые стикеры в теле сообщения (старые — просто эмодзи, остаются как есть) */
const val STICKER_ART_PREFIX = "art:"

private fun DrawScope.drawSticker(id: String) {
    when (id) {
        "pumpkin" -> {
            drawOval(Brush.verticalGradient(listOf(Color(0xFFFFA940), Color(0xFFFF7A00))), Offset(10f, 16f), Size(80f, 78f))
            for (x in listOf(30f, 50f, 70f)) drawLine(Color(0xFFE8690A).copy(alpha = 0.55f), Offset(x, 22f), Offset(x, 86f), 2.2f)
            drawPath(Path().apply { moveTo(44f, 2f); cubicTo(54f, -2f, 58f, 6f, 51f, 11f); cubicTo(48f, 13f, 42f, 11f, 41f, 7f); cubicTo(40f, 4f, 42f, 2f, 44f, 2f); close() }, Color(0xFF3A7A3A))
            drawPath(Path().apply { moveTo(30f, 46f); lineTo(42f, 46f); lineTo(36f, 58f); close() }, Color(0xFF2A1A08))
            drawPath(Path().apply { moveTo(58f, 46f); lineTo(70f, 46f); lineTo(64f, 58f); close() }, Color(0xFF2A1A08))
            drawPath(Path().apply {
                moveTo(26f, 68f); lineTo(74f, 68f); lineTo(66f, 80f); lineTo(58f, 72f); lineTo(50f, 80f); lineTo(42f, 72f); lineTo(34f, 80f); close()
            }, Color(0xFF2A1A08))
        }
        "ghost" -> {
            drawPath(Path().apply {
                moveTo(50f, 10f); cubicTo(28f, 10f, 14f, 26f, 14f, 46f); lineTo(14f, 92f); lineTo(24f, 84f); lineTo(34f, 92f); lineTo(44f, 84f)
                lineTo(50f, 92f); lineTo(56f, 84f); lineTo(66f, 92f); lineTo(76f, 84f); lineTo(86f, 92f); lineTo(86f, 46f); cubicTo(86f, 26f, 72f, 10f, 50f, 10f); close()
            }, Color(0xFFF4F2FF))
            drawCircle(Color(0xFF2A2240), 6f, Offset(37f, 42f)); drawCircle(Color(0xFF2A2240), 6f, Offset(63f, 42f))
            drawOval(Color(0xFFFFB3C6).copy(alpha = 0.6f), Offset(28f, 54f), Size(10f, 12f)); drawOval(Color(0xFFFFB3C6).copy(alpha = 0.6f), Offset(62f, 54f), Size(10f, 12f))
            drawPath(Path().apply { moveTo(40f, 58f); quadraticBezierTo(50f, 70f, 60f, 58f) }, Color(0xFF2A2240), style = Stroke(3.2f, cap = StrokeCap.Round))
        }
        "cat" -> {
            drawPath(Path().apply {
                moveTo(18f, 90f); cubicTo(18f, 66f, 24f, 50f, 30f, 40f); lineTo(22f, 14f); lineTo(42f, 32f)
                cubicTo(48f, 29f, 52f, 29f, 58f, 32f); lineTo(78f, 14f); lineTo(70f, 40f); cubicTo(76f, 50f, 82f, 66f, 82f, 90f); close()
            }, Color(0xFF1A1A2E))
            drawCircle(Color(0xFFFFD97A), 5.4f, Offset(38f, 56f)); drawCircle(Color(0xFFFFD97A), 5.4f, Offset(62f, 56f))
            drawPath(Path().apply { moveTo(50f, 62f); lineTo(45f, 70f); lineTo(55f, 70f); close() }, Color(0xFFFF8FAB))
            val line = Stroke(2.2f, cap = StrokeCap.Round)
            drawLine(Color(0xFF1A1A2E), Offset(16f, 56f), Offset(2f, 50f), 2.2f, StrokeCap.Round); drawLine(Color(0xFF1A1A2E), Offset(16f, 64f), Offset(0f, 66f), 2.2f, StrokeCap.Round)
            drawLine(Color(0xFF1A1A2E), Offset(84f, 56f), Offset(98f, 50f), 2.2f, StrokeCap.Round); drawLine(Color(0xFF1A1A2E), Offset(84f, 64f), Offset(100f, 66f), 2.2f, StrokeCap.Round)
        }
        "candy" -> {
            drawPath(Path().apply { moveTo(50f, 10f); cubicTo(66f, 32f, 74f, 48f, 74f, 62f); lineTo(26f, 62f); cubicTo(26f, 48f, 34f, 32f, 50f, 10f); close() }, Color.White)
            drawPath(Path().apply { moveTo(26f, 62f); lineTo(74f, 62f); cubicTo(74f, 76f, 68f, 84f, 68f, 84f); lineTo(32f, 84f); cubicTo(32f, 84f, 26f, 76f, 26f, 62f); close() }, Color(0xFFFFC83D))
            drawPath(Path().apply { moveTo(32f, 84f); lineTo(68f, 84f); cubicTo(68f, 94f, 60f, 98f, 50f, 98f); cubicTo(40f, 98f, 32f, 94f, 32f, 84f); close() }, Color(0xFFFF8A1E))
            for (x in listOf(36f, 50f, 64f)) drawLine(Color(0xFFFFE08A), Offset(x, 14f), Offset(x, 56f), 3f, StrokeCap.Round)
        }
        "spider" -> {
            val legStroke = Stroke(4.2f, cap = StrokeCap.Round)
            for ((a, b) in listOf(
                Offset(36f, 38f) to Offset(6f, 20f), Offset(36f, 48f) to Offset(0f, 48f), Offset(36f, 58f) to Offset(6f, 76f),
                Offset(64f, 38f) to Offset(94f, 20f), Offset(64f, 48f) to Offset(100f, 48f), Offset(64f, 58f) to Offset(94f, 76f),
            )) drawLine(Color(0xFF1A1A2E), a, b, 4.2f, StrokeCap.Round)
            drawCircle(Color(0xFF1A1A2E), 24f, Offset(50f, 56f))
            drawCircle(Color(0xFF1A1A2E), 15f, Offset(50f, 30f))
            drawCircle(Color.White, 3.2f, Offset(44f, 27f)); drawCircle(Color.White, 3.2f, Offset(56f, 27f))
            drawPath(Path().apply { moveTo(42f, 14f); lineTo(32f, 4f); lineTo(44f, 8f); close() }, Color(0xFFFF5B7A))
            drawPath(Path().apply { moveTo(58f, 14f); lineTo(68f, 4f); lineTo(56f, 8f); close() }, Color(0xFFFF5B7A))
        }
        "skull" -> {
            drawPath(Path().apply {
                moveTo(50f, 8f); cubicTo(24f, 8f, 10f, 28f, 10f, 48f); cubicTo(10f, 60f, 16f, 68f, 22f, 74f); lineTo(22f, 88f); lineTo(78f, 88f); lineTo(78f, 74f)
                cubicTo(84f, 68f, 90f, 60f, 90f, 48f); cubicTo(90f, 28f, 76f, 8f, 50f, 8f); close()
            }, Color(0xFFF4F2FF))
            drawCircle(Color(0xFF2A2240), 8.5f, Offset(34f, 46f)); drawCircle(Color(0xFF2A2240), 8.5f, Offset(66f, 46f))
            drawPath(Path().apply { moveTo(50f, 52f); lineTo(43f, 64f); lineTo(57f, 64f); close() }, Color(0xFF2A2240))
            drawLine(Color(0xFF2A2240), Offset(32f, 76f), Offset(68f, 76f), 3.2f, StrokeCap.Round)
        }
        "bat" -> {
            drawPath(Path().apply {
                moveTo(46f, 54f); lineTo(14f, 44f); lineTo(24f, 58f); lineTo(6f, 66f); lineTo(24f, 72f); lineTo(10f, 86f); lineTo(32f, 82f); lineTo(32f, 92f); lineTo(46f, 72f); close()
            }, Color(0xFF2A2240))
            drawPath(Path().apply {
                moveTo(54f, 54f); lineTo(86f, 44f); lineTo(76f, 58f); lineTo(94f, 66f); lineTo(76f, 72f); lineTo(90f, 86f); lineTo(68f, 82f); lineTo(68f, 92f); lineTo(54f, 72f); close()
            }, Color(0xFF2A2240))
            drawOval(Color(0xFF2A2240), Offset(38f, 50f), Size(24f, 30f))
            drawCircle(Color(0xFFFFD97A), 3.2f, Offset(44f, 62f)); drawCircle(Color(0xFFFFD97A), 3.2f, Offset(56f, 62f))
        }
        "potion" -> {
            drawRoundRect(Color(0xFF5A3FD6), Offset(42f, 8f), Size(16f, 10f), androidx.compose.ui.geometry.CornerRadius(3f, 3f))
            drawPath(Path().apply { moveTo(44f, 18f); lineTo(56f, 18f); lineTo(70f, 50f); cubicTo(70f, 68f, 58f, 80f, 50f, 80f); cubicTo(42f, 80f, 30f, 68f, 30f, 50f); close() }, Color(0xFF7C5CFF))
            drawPath(Path().apply { moveTo(28f, 56f); cubicTo(28f, 76f, 38f, 90f, 50f, 90f); cubicTo(62f, 90f, 72f, 76f, 72f, 56f); close() }, Color(0xFF9B7BFF))
            drawCircle(Color(0xFF2BD67B), 4.4f, Offset(50f, 70f)); drawCircle(Color(0xFF2BD67B), 3.2f, Offset(41f, 60f)); drawCircle(Color(0xFF2BD67B), 3.6f, Offset(59f, 63f))
        }
    }
}

@Composable
fun StickerImage(id: String, size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size)) {
        val s = this.size.minDimension / 100f
        scale(s, Offset.Zero) { drawSticker(id) }
    }
}

/** Отрисовывает тело стикера: новые ('art:xxx') — настоящая картинка, старые (просто эмодзи) — как раньше, текстом */
@Composable
fun StickerBody(body: String?, size: Dp, modifier: Modifier = Modifier) {
    if (body != null && body.startsWith(STICKER_ART_PREFIX)) {
        StickerImage(body.removePrefix(STICKER_ART_PREFIX), size, modifier)
    } else {
        androidx.compose.material3.Text(body ?: "", fontSize = androidx.compose.ui.unit.TextUnit(size.value * 0.66f, androidx.compose.ui.unit.TextUnitType.Sp), modifier = modifier)
    }
}
