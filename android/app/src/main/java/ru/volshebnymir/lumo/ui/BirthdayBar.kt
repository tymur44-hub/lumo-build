package ru.volshebnymir.lumo.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Birthday
import java.util.Calendar

/** Над списком чатов: у контакта сегодня день рождения — нажмите, чтобы подарить подарок */
@Composable
fun BirthdayBar() {
    val p = P
    val cal = Calendar.getInstance()
    val m = cal.get(Calendar.MONTH) + 1
    val d = cal.get(Calendar.DAY_OF_MONTH)
    val today = AppModel.contacts.mapNotNull { AppModel.profiles[it] }.filter { pr ->
        !pr.banned && Birthday.parts(pr.birthday)?.let { it.second == m && it.third == d } == true
    }
    var gift by remember { mutableStateOf<String?>(null) }
    var list by remember { mutableStateOf(false) }
    AnimatedVisibility(today.isNotEmpty()) {
        val names = if (today.size == 1) today[0].name else "${today[0].name} и ещё ${today.size - 1}"
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 4.dp).clip(RoundedCornerShape(18.dp))
                .background(Brush.horizontalGradient(listOf(Color(0xFFFF7AB6), Color(0xFFFF9D4D))))
                .bouncy { if (today.size == 1) gift = today[0].id else list = true }.padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.CardGiftcard, null, tint = Color.White, modifier = Modifier.size(26.dp))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(if (today.size == 1) "У $names день рождения" else "День рождения: $names", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp, maxLines = 1)
                Text("Нажмите, чтобы подарить подарок", color = Color.White.copy(alpha = 0.9f), fontSize = 12.5.sp)
            }
        }
    }
    gift?.let { GiftShopDialog(it) { gift = null } }
    if (list) androidx.compose.ui.window.Dialog(onDismissRequest = { list = false }) {
        Column(Modifier.clip(RoundedCornerShape(22.dp)).background(p.panel).padding(vertical = 10.dp)) {
            Text("Сегодня день рождения", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.padding(16.dp))
            for (pr in today) {
                Row(Modifier.fillMaxWidth().bouncy { list = false; gift = pr.id }.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(pr.name, pr.avatarUrl, pr.color, 42.dp)
                    Spacer(Modifier.width(12.dp))
                    Text(pr.name, color = p.text, fontSize = 16.sp, modifier = Modifier.weight(1f))
                    Icon(Icons.Filled.CardGiftcard, null, tint = p.a1)
                }
            }
        }
    }
}
