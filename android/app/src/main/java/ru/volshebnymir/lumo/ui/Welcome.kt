package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Приветствие перед вводом номера: элементы появляются по очереди */
@Composable
fun WelcomeScreen(onContinue: () -> Unit) {
    val p = P
    val items: List<Triple<ImageVector, String, String>> = listOf(
        Triple(Icons.Filled.Bolt, "Быстрые сообщения", "Доставляются мгновенно и без лишних шагов"),
        Triple(Icons.Filled.Videocam, "Звонки и видеосообщения", "Голос, видео и кружки — всё в одном месте"),
        Triple(Icons.Filled.Shield, "Вход без паролей", "Только номер телефона и код"),
    )
    val logo = remember { Animatable(0f) }
    val title = remember { Animatable(0f) }
    val rows = remember { List(3) { Animatable(0f) } }
    val button = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        logo.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 180f))
    }
    LaunchedEffect(Unit) { kotlinx.coroutines.delay(250); title.animateTo(1f, tween(600, easing = FastOutSlowInEasing)) }
    rows.forEachIndexed { i, a -> LaunchedEffect(Unit) { kotlinx.coroutines.delay(500L + i * 140L); a.animateTo(1f, spring(dampingRatio = 0.8f, stiffness = 200f)) } }
    LaunchedEffect(Unit) { kotlinx.coroutines.delay(1050); button.animateTo(1f, spring(dampingRatio = 0.8f, stiffness = 200f)) }
    val inf = rememberInfiniteTransition(label = "wl")
    val float by inf.animateFloat(-6f, 6f, infiniteRepeatable(tween(2600, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "f")
    val pulse by inf.animateFloat(0f, 1f, infiniteRepeatable(tween(2200, easing = LinearOutSlowInEasing)), label = "p")

    Box(Modifier.fillMaxSize().background(p.bg)) {
        Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(horizontal = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.weight(1f))
            Box(Modifier.size(150.dp).graphicsLayer { translationY = float * density }, contentAlignment = Alignment.Center) {
                Box(Modifier.size(104.dp).scale(1f + pulse * 0.9f).alpha((1f - pulse) * 0.35f).clip(CircleShape).background(p.a1))
                Box(Modifier.size(104.dp).scale(0.4f + 0.6f * logo.value).alpha(logo.value.coerceIn(0f, 1f))
                    .clip(RoundedCornerShape(30.dp)).background(p.accent), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.ChatBubble, null, tint = Color.White, modifier = Modifier.size(52.dp))
                }
            }
            Spacer(Modifier.height(18.dp))
            Text("Добро пожаловать\nв Lumo", fontSize = 32.sp, fontWeight = FontWeight.Black, color = p.text, textAlign = TextAlign.Center,
                modifier = Modifier.alpha(title.value).graphicsLayer { translationY = (1f - title.value) * 40f })
            Spacer(Modifier.height(10.dp))
            Text("Быстрый и красивый мессенджер, в котором приятно общаться", fontSize = 16.sp, color = p.muted, textAlign = TextAlign.Center,
                modifier = Modifier.alpha(title.value).graphicsLayer { translationY = (1f - title.value) * 40f })
            Spacer(Modifier.height(30.dp))
            items.forEachIndexed { i, (ic, t, d) ->
                Row(Modifier.fillMaxWidth().padding(vertical = 7.dp).alpha(rows[i].value.coerceIn(0f, 1f)).graphicsLayer { translationX = (1f - rows[i].value) * -80f },
                    verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(44.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) {
                        Icon(ic, null, tint = Color.White, modifier = Modifier.size(22.dp))
                    }
                    Spacer(Modifier.width(14.dp))
                    Column {
                        Text(t, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = p.text)
                        Text(d, fontSize = 13.sp, color = p.muted)
                    }
                }
            }
            Spacer(Modifier.weight(1f))
            Box(Modifier.fillMaxWidth().padding(bottom = 44.dp).alpha(button.value.coerceIn(0f, 1f)).graphicsLayer { translationY = (1f - button.value) * 80f }) {
                GradientButton("Продолжить") { onContinue() }
            }
        }
    }
}
