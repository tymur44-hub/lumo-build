package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.random.Random

/** Только что поставленные реакции — чтобы разлёт эмодзи играл один раз, а не при каждой прокрутке */
object ReactionFX {
    private val fresh = HashMap<String, Long>()
    fun mark(mid: Long, emoji: String) { fresh["$mid|$emoji"] = System.currentTimeMillis() }
    fun take(mid: Long, emoji: String): Boolean {
        val t = fresh.remove("$mid|$emoji") ?: return false
        return System.currentTimeMillis() - t < 2500
    }
}

/** Точка «в сети»: появляется как упавшая капля (колышется), исчезает — стекает вниз и тает */
@Composable
fun OnlineDot(online: Boolean, size: Dp, ring: Color, fill: Color, modifier: Modifier = Modifier) {
    val sx by animateFloatAsState(if (online) 1f else 0.2f,
        if (online) spring(0.42f, Spring.StiffnessMediumLow) else tween(260, easing = CubicBezierEasing(0.5f, 0f, 1f, 1f)), label = "sx")
    val sy by animateFloatAsState(if (online) 1f else 1.55f,
        if (online) spring(0.5f, Spring.StiffnessLow) else tween(300, easing = CubicBezierEasing(0.5f, 0f, 1f, 1f)), label = "sy")
    val a by animateFloatAsState(if (online) 1f else 0f, if (online) tween(120) else tween(320, 40), label = "a")
    val dy by animateFloatAsState(if (online) 0f else 0.55f, if (online) spring(0.6f) else tween(320), label = "dy")
    if (a <= 0.01f && !online) return
    Box(modifier.size(size).graphicsLayer {
        scaleX = sx; scaleY = sy; alpha = a
        transformOrigin = TransformOrigin(0.5f, 0f)
        translationY = dy * this.size.height
    }.clip(CircleShape).background(ring).padding(2.dp).clip(CircleShape).background(fill))
}

/** Разлёт эмодзи из реакции: крупная взмывает вверх, мелкие разлетаются по кругу и тают */
@Composable
fun EmojiBurst(emoji: String, key: Int) {
    val parts = remember(key) { List(9) { i -> Triple(i / 9.0 * 2 * Math.PI + Random.nextDouble(-0.25, 0.25), Random.nextInt(34, 58), Random.nextInt(11, 17)) } }
    val t = remember(key) { Animatable(0f) }
    LaunchedEffect(key) { t.animateTo(1f, tween(800, easing = CubicBezierEasing(0.15f, 0.85f, 0.35f, 1f))) }
    val v = t.value
    if (v >= 1f) return
    Box {
        Text(emoji, fontSize = 22.sp, modifier = Modifier.graphicsLayer {
            scaleX = 0.6f + 1.5f * v; scaleY = scaleX; alpha = 1f - v; translationY = -46.dp.toPx() * v
        })
        parts.forEach { (ang, dist, sz) ->
            Text(emoji, fontSize = sz.sp, modifier = Modifier.offset {
                IntOffset((cos(ang) * dist * v * density).roundToInt(), ((sin(ang) * dist - 14) * v * density).roundToInt())
            }.graphicsLayer { val s = 1.15f - 0.6f * v; scaleX = s; scaleY = s; alpha = 1f - v })
        }
    }
}
