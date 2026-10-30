package ru.volshebnymir.lumo.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

/** Подробности функции Premium: свайп между функциями, как в Telegram */
@Composable
fun PremiumDetailDialog(start: Int, owner: Boolean, onClose: () -> Unit, onBuy: () -> Unit) {
    val p = P
    val count = FEATURES.size + 1
    val pager = rememberPagerState(initialPage = start) { count }
    val accent by animateColorAsState(if (pager.currentPage < FEATURES.size) FEATURES[pager.currentPage].color else p.a1, tween(350), label = "acc")
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Box(Modifier.fillMaxSize().background(p.bg)) {
            Box(Modifier.fillMaxWidth().height(340.dp).background(Brush.verticalGradient(listOf(accent.copy(alpha = 0.55f), accent.copy(alpha = 0.18f), Color.Transparent))))
            SparkleField(Modifier.fillMaxWidth().height(300.dp))
            Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                HorizontalPager(pager, Modifier.weight(1f)) { i ->
                    if (i < FEATURES.size) FeaturePage(FEATURES[i]) else ListPage()
                }
                Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                    val dots = minOf(count, 12)
                    repeat(dots) { d ->
                        val target = if (count <= 12) d else Math.round(d / 11f * (count - 1))
                        val on = target == pager.currentPage
                        val w by animateDpAsState(if (on) 18.dp else 6.dp, label = "dot")
                        Box(Modifier.padding(horizontal = 3.dp).height(6.dp).width(w).clip(CircleShape).background(if (on) accent else p.muted.copy(alpha = 0.35f)))
                    }
                }
                Box(Modifier.padding(horizontal = 16.dp).padding(bottom = 14.dp)) {
                    ShimmerButton(if (owner) "Открыть Premium" else "Подключить за 199 ₽ в месяц") { onBuy() }
                }
            }
            Box(Modifier.statusBarsPadding().padding(16.dp).size(36.dp).clip(CircleShape).background(p.panel.copy(alpha = 0.85f)).bouncy { onClose() }, contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Close, null, tint = p.text, modifier = Modifier.size(20.dp))
            }
        }
    }
}

@Composable
private fun FeaturePage(f: Feat) {
    val p = P
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(54.dp))
        PhoneMock(f)
        Spacer(Modifier.height(22.dp))
        Text(f.title, color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 24.dp))
        if (f.soon) Text("в разработке", color = p.a1, fontSize = 12.sp, fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(top = 8.dp).clip(RoundedCornerShape(7.dp)).background(p.a1.copy(alpha = 0.14f)).padding(horizontal = 8.dp, vertical = 2.dp))
        Text(f.desc, color = p.muted, fontSize = 16.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp))
    }
}

@Composable
private fun ListPage() {
    val p = P
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(54.dp))
        PremiumStar(96.dp)
        Text("Lumo Premium", color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp, modifier = Modifier.padding(vertical = 14.dp))
        Column(Modifier.padding(horizontal = 28.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            FEATURES.take(5).forEach { f ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(f.icon, null, tint = f.color, modifier = Modifier.size(26.dp))
                    Spacer(Modifier.width(14.dp))
                    Column {
                        Text(f.title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text(f.desc, color = p.muted, fontSize = 13.5.sp, maxLines = 2)
                    }
                }
            }
        }
    }
}

/** Нарисованный телефон со «сценой» функции */
@Composable
private fun PhoneMock(f: Feat) {
    val p = P
    val c = f.color
    val t = rememberInfiniteTransition(label = "ph")
    val pulse by t.animateFloat(0.92f, 1.12f, infiniteRepeatable(tween(1600, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "pu")
    Box(Modifier.size(150.dp, 240.dp).scale(0.97f + (pulse - 0.92f) * 0.15f), contentAlignment = Alignment.Center) {
        Box(Modifier.fillMaxSize().clip(RoundedCornerShape(30.dp)).background(p.panel).border(3.dp, p.text.copy(alpha = 0.18f), RoundedCornerShape(30.dp)))
        Box(Modifier.size(134.dp, 224.dp).clip(RoundedCornerShape(24.dp)).background(Brush.verticalGradient(listOf(c.copy(alpha = 0.30f), c.copy(alpha = 0.08f)))))
        Box(Modifier.align(Alignment.TopCenter).padding(top = 10.dp).size(40.dp, 6.dp).clip(CircleShape).background(p.text.copy(alpha = 0.25f)))
        Box(Modifier.size(130.dp, 200.dp), contentAlignment = Alignment.Center) { Scene(f, c, pulse) }
    }
}

@Composable
private fun Bubble(w: Int, mine: Boolean, c: Color, modifier: Modifier = Modifier) {
    val p = P
    Box(modifier.size(w.dp, 26.dp).clip(RoundedCornerShape(12.dp)).background(if (mine) Brush.horizontalGradient(listOf(c, c.copy(alpha = 0.7f))) else Brush.horizontalGradient(listOf(p.text.copy(alpha = 0.14f), p.text.copy(alpha = 0.14f)))))
}

@Composable
private fun Scene(f: Feat, c: Color, pulse: Float) {
    val p = P
    when (f.title) {
        "До 3 реакций на сообщение" -> Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(horizontal = 6.dp)) {
            Bubble(92, false, c, Modifier.align(Alignment.Start))
            Bubble(80, true, c)
            Row(Modifier.scale(pulse).clip(CircleShape).background(p.panel).padding(horizontal = 8.dp, vertical = 4.dp)) {
                listOf("❤️", "🔥", "👍").forEach { Text(it, fontSize = 17.sp, modifier = Modifier.padding(horizontal = 2.dp)) }
            }
        }
        "Анимированные эмодзи" -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("😍", fontSize = 56.sp, modifier = Modifier.scale(pulse))
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) { listOf("🔥", "🎉", "😂").forEach { Text(it, fontSize = 30.sp) } }
        }
        "Обои для вас и собеседника" -> Box(Modifier.size(126.dp, 190.dp).clip(RoundedCornerShape(20.dp))
            .background(Brush.linearGradient(listOf(Color(0xFF4D8BFF), Color(0xFFB26BFF), Color(0xFFFF7AB6))))) {
            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(8.dp), horizontalAlignment = Alignment.End) {
                Bubble(70, false, Color.White, Modifier.align(Alignment.Start))
                Bubble(84, true, Color.White)
                Bubble(56, false, Color.White, Modifier.align(Alignment.Start))
            }
        }
        "Анимированные эффекты сообщений" -> Box(contentAlignment = Alignment.Center) {
            val cols = listOf(Color.Yellow, Color(0xFFFF6BA6), Color.Cyan, Color(0xFFFF9F0A), Color.Green)
            repeat(14) { i ->
                Box(Modifier.offset(x = (((i * 37) % 110) - 55).dp, y = ((((i * 53) % 150) - 90) + (pulse - 0.92f) * 150).dp).size(7.dp).clip(CircleShape).background(cols[i % 5]))
            }
            Text("🎉", fontSize = 54.sp, modifier = Modifier.scale(pulse))
        }
        else -> Box(contentAlignment = Alignment.Center) {
            Box(Modifier.size((96 * pulse).dp).clip(CircleShape).background(c.copy(alpha = 0.25f)))
            Box(Modifier.size(76.dp).clip(CircleShape).background(c), contentAlignment = Alignment.Center) {
                Icon(f.icon, null, tint = Color.White, modifier = Modifier.size(38.dp))
            }
        }
    }
}
