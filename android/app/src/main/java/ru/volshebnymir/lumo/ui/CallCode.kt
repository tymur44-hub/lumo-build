package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Extension
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Park
import androidx.compose.material.icons.filled.PedalBike
import androidx.compose.material.icons.filled.Pets
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Sailing
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import java.security.MessageDigest

/**
 * Код проверки звонка, как в Telegram: из ключей шифрования обоих телефонов (отпечатки DTLS в SDP)
 * получаются четыре значка. Одинаковые у обоих собеседников — посередине никого нет.
 * Тот же алгоритм на iOS, Android и в веб-версии.
 */
class CallIcon(val name: String, val icon: ImageVector, val a: Long, val b: Long)

object CallCode {
    val icons = listOf(
        CallIcon("Звезда", Icons.Filled.Star, 0xFFFFC93C, 0xFFFF8A00),
        CallIcon("Сердце", Icons.Filled.Favorite, 0xFFFF5A7A, 0xFFE0245E),
        CallIcon("Луна", Icons.Filled.Bedtime, 0xFF8E8CFF, 0xFF5B4BDB),
        CallIcon("Солнце", Icons.Filled.WbSunny, 0xFFFFB703, 0xFFFB8500),
        CallIcon("Молния", Icons.Filled.Bolt, 0xFFFFE066, 0xFFF4A100),
        CallIcon("Лист", Icons.Filled.Eco, 0xFF7BD88F, 0xFF2E9E5B),
        CallIcon("Огонь", Icons.Filled.LocalFireDepartment, 0xFFFF8A3D, 0xFFE63946),
        CallIcon("Капля", Icons.Filled.WaterDrop, 0xFF5AC8FA, 0xFF1A73E8),
        CallIcon("Снежинка", Icons.Filled.AcUnit, 0xFFA0E9FF, 0xFF4CA9E0),
        CallIcon("Облако", Icons.Filled.Cloud, 0xFFB8C6FF, 0xFF6C7FD8),
        CallIcon("Самолёт", Icons.Filled.Flight, 0xFF74C0FC, 0xFF3B82F6),
        CallIcon("Ключ", Icons.Filled.Key, 0xFFFFD166, 0xFFD4A017),
        CallIcon("Колокол", Icons.Filled.Notifications, 0xFFFFB4A2, 0xFFE5737F),
        CallIcon("Нота", Icons.Filled.MusicNote, 0xFFC77DFF, 0xFF7B2CBF),
        CallIcon("Камера", Icons.Filled.PhotoCamera, 0xFF9AA5B1, 0xFF52606D),
        CallIcon("Подарок", Icons.Filled.CardGiftcard, 0xFFFF8FAB, 0xFFC9184A),
        CallIcon("Флаг", Icons.Filled.Flag, 0xFFFF6B6B, 0xFFC92A2A),
        CallIcon("Планета", Icons.Filled.Public, 0xFF63E6BE, 0xFF0CA678),
        CallIcon("Лапа", Icons.Filled.Pets, 0xFFE6A57E, 0xFFA0522D),
        CallIcon("Машина", Icons.Filled.DirectionsCar, 0xFFFF922B, 0xFFD9480F),
        CallIcon("Велосипед", Icons.Filled.PedalBike, 0xFF94D82D, 0xFF5C940D),
        CallIcon("Дом", Icons.Filled.Home, 0xFFF9A8D4, 0xFFDB2777),
        CallIcon("Парусник", Icons.Filled.Sailing, 0xFF66D9E8, 0xFF1098AD),
        CallIcon("Мяч", Icons.Filled.SportsSoccer, 0xFFCED4DA, 0xFF495057),
        CallIcon("Кубок", Icons.Filled.EmojiEvents, 0xFFFCC419, 0xFFE67700),
        CallIcon("Палитра", Icons.Filled.Palette, 0xFFDA77F2, 0xFF9C36B5),
        CallIcon("Лампочка", Icons.Filled.Lightbulb, 0xFFFFF3BF, 0xFFFAB005),
        CallIcon("Зонт", Icons.Filled.Umbrella, 0xFF91A7FF, 0xFF4263EB),
        CallIcon("Компас", Icons.Filled.Explore, 0xFF38D9A9, 0xFF087F5B),
        CallIcon("Гора", Icons.Filled.Landscape, 0xFFA9E34B, 0xFF2B8A3E),
        CallIcon("Пазл", Icons.Filled.Extension, 0xFFFFA94D, 0xFFE8590C),
        CallIcon("Дерево", Icons.Filled.Park, 0xFF8CE99A, 0xFF2F9E44)
    )

    fun make(localSdp: String, remoteSdp: String): List<Int>? {
        val fp = fingerprints(localSdp + "\n" + remoteSdp)
        if (fp.split(",").size < 2) return null
        val h = MessageDigest.getInstance("SHA-256").digest(("lumo-callcode1|$fp").toByteArray(Charsets.UTF_8))
        return (0 until 4).map { (h[it].toInt() and 0xFF) % icons.size }
    }

    fun fingerprints(s: String): String =
        Regex("a=fingerprint:(\\S+) (\\S+)", RegexOption.IGNORE_CASE).findAll(s)
            .map { it.groupValues[1].lowercase() + " " + it.groupValues[2].uppercase() }.toSet().sorted().joinToString(",")
}

@Composable
fun CallIconView(i: Int, size: Dp = 26.dp) {
    val ic = CallCode.icons[i % CallCode.icons.size]
    Box(Modifier.size(size).shadow(size * 0.18f, CircleShape, ambientColor = Color(ic.b), spotColor = Color(ic.b))
        .clip(CircleShape).background(Brush.linearGradient(listOf(Color(ic.a), Color(ic.b))))
        .border((size.value * 0.04f).coerceAtLeast(1f).dp, Color.White.copy(alpha = 0.35f), CircleShape),
        contentAlignment = Alignment.Center) {
        Icon(ic.icon, ic.name, tint = Color.White, modifier = Modifier.size(size * 0.55f))
    }
}

/** Маленькая плашка с кодом в звонке; нажатие — крупная карточка с объяснением */
@Composable
fun CallCodeBadge(code: List<Int>, modifier: Modifier = Modifier) {
    var open by remember { mutableStateOf(false) }
    Row(modifier.clip(RoundedCornerShape(50)).background(Color.Black.copy(alpha = 0.35f))
        .clickable { open = true }.padding(horizontal = 8.dp, vertical = 5.dp), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        code.forEachIndexed { k, i ->
            val s = remember { Animatable(0.2f) }
            LaunchedEffect(Unit) { delay(70L * k); s.animateTo(1f, spring(0.55f, Spring.StiffnessMediumLow)) }
            Box(Modifier.graphicsLayer { scaleX = s.value; scaleY = s.value; alpha = ((s.value - 0.2f) / 0.8f).coerceIn(0f, 1f) }) { CallIconView(i, 24.dp) }
        }
    }
    if (open) CallCodeCard(code) { open = false }
}

@Composable
fun CallCodeCard(code: List<Int>, close: () -> Unit) {
    Dialog(onDismissRequest = close, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().clickable(remember { MutableInteractionSource() }, null) { close() }, contentAlignment = Alignment.Center) {
            Column(Modifier.padding(horizontal = 22.dp).clip(RoundedCornerShape(28.dp)).background(Color(0xEE1C1C28))
                .clickable(remember { MutableInteractionSource() }, null) {}.padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    code.forEachIndexed { k, i ->
                        val s = remember { Animatable(0.3f) }
                        LaunchedEffect(Unit) { delay(80L + 80L * k); s.animateTo(1f, spring(0.55f, Spring.StiffnessLow)) }
                        Column(Modifier.width(66.dp).graphicsLayer { scaleX = s.value; scaleY = s.value; rotationZ = (1f - s.value) * -35f; alpha = ((s.value - 0.3f) / 0.7f).coerceIn(0f, 1f) },
                            horizontalAlignment = Alignment.CenterHorizontally) {
                            CallIconView(i, 58.dp)
                            Spacer(Modifier.height(7.dp))
                            Text(CallCode.icons[i].name, color = Color.White.copy(alpha = 0.85f), fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                        }
                    }
                }
                Text("Звонок зашифрован", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                Text("Если у собеседника на экране те же четыре значка, разговор защищён сквозным шифрованием и никто посередине его не слышит.",
                    color = Color.White.copy(alpha = 0.8f), fontSize = 15.sp, textAlign = TextAlign.Center)
                Box(Modifier.fillMaxWidth().height(48.dp).clip(RoundedCornerShape(50)).background(Color.White.copy(alpha = 0.18f)).clickable { close() },
                    contentAlignment = Alignment.Center) { Text("Понятно", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold) }
            }
        }
    }
}
