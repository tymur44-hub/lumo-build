package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material.icons.filled.Verified
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Message

/** Значки рядом с именем: «БОТ» у ботов и звезда у подписчиков Premium */
@Composable
fun NameBadges(bot: Boolean, premium: Boolean, emoji: String? = null) {
    val p = P
    if (bot) Text("БОТ", color = p.muted, fontWeight = FontWeight.ExtraBold, fontSize = 10.sp, maxLines = 1,
        modifier = Modifier.padding(start = 6.dp).clip(RoundedCornerShape(5.dp)).background(p.muted.copy(alpha = 0.16f)).padding(horizontal = 5.dp, vertical = 1.dp))
    else if (premium && emoji != null) StatusEmoji(emoji, 14.sp, Modifier.padding(start = 4.dp))
    else if (premium) Icon(Icons.Filled.Star, null, tint = Color(0xFFFFB020), modifier = Modifier.padding(start = 4.dp).size(16.dp))
}

/** Кнопки под сообщением бота */
@Composable
fun BotButtons(m: Message, mine: Boolean) {
    val rows = m.buttons
    if (rows.isEmpty() || m.deleted) return
    val p = P
    Column(Modifier.padding(top = 8.dp).widthIn(min = 200.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
        rows.forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                row.forEach { b ->
                    Text(b.text, color = if (mine) Color.White else p.a1, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, maxLines = 1,
                        overflow = TextOverflow.Ellipsis, textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        modifier = Modifier.weight(1f).clip(RoundedCornerShape(10.dp)).background(p.muted.copy(alpha = 0.18f))
                            .clickable { AppModel.botPress(m, b) }.padding(horizontal = 8.dp, vertical = 9.dp))
                }
            }
        }
    }
}

/** Галочка верификации, затем значки бота / Premium — рядом с именем собеседника */
@Composable
fun PeerBadges(chat: ru.volshebnymir.lumo.core.ChatItem?) {
    val p = P
    val pr = chat?.peerId?.let { AppModel.profiles[it] }
    if (pr?.verified == true || chat?.peerVerified == true) Icon(Icons.Filled.Verified, null, tint = p.a2, modifier = Modifier.padding(start = 4.dp).size(16.dp))
    val (b, pm, e) = peerBadges(chat)
    NameBadges(b, pm, e)
}

/** Бот и Premium для значков по профилю собеседника */
fun peerBadges(chat: ru.volshebnymir.lumo.core.ChatItem?): Triple<Boolean, Boolean, String?> {
    val pr = chat?.peerId?.let { AppModel.profiles[it] }
    return Triple(chat?.peerBot == true || pr?.isBot == true, chat?.peerPremium == true || pr?.premium == true, pr?.emojiStatus)
}
