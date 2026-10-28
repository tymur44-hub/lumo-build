package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Text
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

val ANIMATED_EMOJI = listOf("😂", "🤣", "😍", "🥰", "😎", "🤩", "😜", "🥳", "😱", "😭", "😡", "🤯", "🔥", "❤️", "💖", "💯", "🎉", "✨", "⭐️", "👋", "👍", "👏", "🙏", "💪")

private enum class Kind { Beat, Flicker, Shake, Party, Spin, Wave, Bounce }

private fun kindOf(e: String) = when (e) {
    "❤️", "💖", "💗", "💓", "💯" -> Kind.Beat
    "🔥" -> Kind.Flicker
    "😂", "🤣", "😡", "😱", "🤯" -> Kind.Shake
    "🎉", "🥳", "🤩" -> Kind.Party
    "⭐️", "✨", "🌟" -> Kind.Spin
    "👋", "🙏" -> Kind.Wave
    else -> Kind.Bounce
}

/** Оживающее эмодзи: у каждого вида своё движение; по нажатию — всплеск */
@Composable
fun AnimatedEmoji(emoji: String, size: Dp, tappable: Boolean = true) {
    val kind = remember(emoji) { kindOf(emoji) }
    val inf = rememberInfiniteTransition(label = "ae")
    val t by inf.animateFloat(0f, 1000f, infiniteRepeatable(tween(1_000_000, easing = LinearEasing)), label = "t")
    val boost = remember { Animatable(0f) }
    var burst by remember { mutableStateOf(0) }
    val haptic = LocalHapticFeedback.current
    val scope = rememberCoroutineScope()
    val px = with(LocalDensity.current) { size.toPx() }
    val a = 1f + boost.value * 1.2f

    var sc = 1f; var rot = 0f; var dy = 0f; var origin = TransformOrigin.Center
    val s = t.toDouble()
    when (kind) {
        Kind.Beat -> {
            val p = ((s % 1.1) / 1.1).toFloat()
            val k = when { p < 0.15f -> 0.2f * (p / 0.15f); p < 0.3f -> 0.2f - 0.2f * ((p - 0.15f) / 0.15f); p < 0.42f -> 0.12f * ((p - 0.3f) / 0.12f); p < 0.58f -> 0.12f - 0.12f * ((p - 0.42f) / 0.16f); else -> 0f }
            sc = 1f + k * a
        }
        Kind.Flicker -> { sc = 1f + 0.06f * a * sin(s * 9).toFloat() + 0.04f * sin(s * 13).toFloat(); rot = 5f * a * sin(s * 7).toFloat(); dy = -2f * abs(sin(s * 5)).toFloat(); origin = TransformOrigin(0.5f, 1f) }
        Kind.Shake -> { val p = (s % 1.6); val on = p < 0.7; sc = if (on) 1.06f else 1f; rot = if (on) 11f * a * sin(p * 30).toFloat() else 0f }
        Kind.Party -> { val p = (s % 1.2) / 1.2; sc = 1f + 0.08f * a * sin(p * PI).toFloat(); rot = 14f * a * sin(p * PI * 4).toFloat(); dy = -px * 0.12f * a * abs(sin(p * PI * 2)).toFloat() / 2.6f; origin = TransformOrigin(0.5f, 1f) }
        Kind.Spin -> { val p = ((s % 2.4) / 2.4).toFloat(); sc = 1f + 0.15f * a * sin(p * 2 * PI).toFloat(); rot = 360f * p * (if (a > 1.05f) 2 else 1) }
        Kind.Wave -> { rot = 22f * a * sin(s * 6).toFloat() * (if (sin(s * 1.3) > -0.3) 1f else 0.15f); origin = TransformOrigin(1f, 1f) }
        Kind.Bounce -> { val p = (s % 1.3) / 1.3; val h = abs(sin(p * PI)).toFloat() * px * 0.14f * a; sc = 1f - 0.07f * (1f - abs(sin(p * PI)).toFloat()); dy = -h / 2.6f; origin = TransformOrigin(0.5f, 1f) }
    }
    Box(Modifier.size(size * 1.25f).then(if (tappable) Modifier.clickable(remember { MutableInteractionSource() }, null) {
        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        burst++
        scope.launch { boost.snapTo(1f); boost.animateTo(0f, tween(700)) }
    } else Modifier), contentAlignment = Alignment.Center) {
        Text(emoji, fontSize = (size.value * 0.9f).sp, modifier = Modifier.graphicsLayer { scaleX = sc; scaleY = sc; rotationZ = rot; translationY = dy * density; transformOrigin = origin })
        if (burst > 0) key(burst) { for (i in 0 until 7) Particle(emoji, size * 0.4f, burst * 7 + i) }
    }
}

@Composable
private fun Particle(emoji: String, size: Dp, seed: Int) {
    val p = remember { Animatable(0f) }
    LaunchedEffect(Unit) { p.animateTo(1f, tween(900, easing = FastOutSlowInEasing)) }
    val ang = ((seed * 53) % 360) * PI / 180
    val dist = 50 + (seed * 17) % 40
    if (p.value < 1f) Text(emoji, fontSize = size.value.sp, modifier = Modifier.graphicsLayer {
        translationX = (cos(ang) * dist * p.value * density).toFloat()
        translationY = ((sin(ang) * dist - 20) * p.value * density).toFloat()
        scaleX = 1f - 0.7f * p.value; scaleY = 1f - 0.7f * p.value; alpha = 1f - p.value
    })
}
