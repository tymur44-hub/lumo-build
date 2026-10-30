package ru.volshebnymir.lumo.ui

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Config

/** Мастер создания канала / группы: «Что такое канал?» → название и фото → тип и ссылка → участники */
@Composable
fun CreateChatWizard(mode: String, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val channel = mode == "channel"
    val noun = if (channel) "канал" else "группу"
    val nounOf = if (channel) "канала" else "группы"
    // шаги: 0 — что такое канал (только канал), 1 — название, 2 — тип, 3 — участники
    var step by remember { mutableIntStateOf(if (channel) 0 else 1) }
    var title by remember { mutableStateOf("") }
    var about by remember { mutableStateOf("") }
    var isPublic by remember { mutableStateOf(false) }
    var username by remember { mutableStateOf("") }
    var invite by remember { mutableStateOf(newCode()) }
    var requests by remember { mutableStateOf(false) }
    var noCopy by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var avatarUri by remember { mutableStateOf<Uri?>(null) }
    val picked = remember { mutableStateListOf<String>() }
    val link = Config.SITE + "#+" + invite
    val clean = username.replace("@", "").trim()
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u -> if (u != null) avatarUri = u }

    fun back() { if (step == 0 || (step == 1 && !channel)) onClose() else step -= 1 }
    BackHandler { back() }

    @Composable fun header(t: String, next: String? = null, enabled: Boolean = true, onNext: () -> Unit = {}) {
        Box(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 12.dp, vertical = 8.dp), contentAlignment = Alignment.Center) {
            Text(t, color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Box(Modifier.align(Alignment.CenterStart)) { RoundIcon(Icons.AutoMirrored.Filled.ArrowBack, 46.dp, bg = p.panel) { back() } }
            if (next != null) Text(next, color = if (enabled) p.a1 else p.muted, fontWeight = FontWeight.SemiBold, fontSize = 17.sp,
                modifier = Modifier.align(Alignment.CenterEnd).clip(RoundedCornerShape(23.dp)).background(p.panel).clickable(enabled = enabled, onClick = onNext).padding(horizontal = 18.dp, vertical = 12.dp))
        }
    }

    @Composable fun foot(t: String) = Text(t, color = p.muted, fontSize = 14.5.sp, modifier = Modifier.padding(horizontal = 28.dp, vertical = 6.dp))

    @Composable fun sw(t: String, v: Boolean, f: (Boolean) -> Unit) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(t, color = p.text, fontSize = 18.sp, modifier = Modifier.weight(1f))
            Switch(v, f, colors = SwitchDefaults.colors(checkedTrackColor = p.a1))
        }
    }

    @Composable fun typeRow(t: String, on: Boolean, f: () -> Unit) {
        Row(Modifier.fillMaxWidth().clickable(onClick = f).padding(horizontal = 18.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.width(34.dp)) { if (on) Icon(Icons.Filled.Check, null, tint = p.a1) }
            Text(t, color = p.text, fontSize = 19.sp)
        }
    }

    Column(Modifier.fillMaxSize().background(p.bg).imePadding()) {
        when (step) {
            0 -> {
                Box(Modifier.fillMaxWidth().statusBarsPadding().padding(12.dp)) { RoundIcon(Icons.AutoMirrored.Filled.ArrowBack, 46.dp, bg = p.panel) { back() } }
                Column(Modifier.weight(1f).fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    ChannelArt()
                    Spacer(Modifier.height(40.dp))
                    Text("Что такое канал?", color = p.text, fontWeight = FontWeight.Bold, fontSize = 28.sp)
                    Spacer(Modifier.height(14.dp))
                    Text("Каналы — инструмент, который позволяет транслировать сообщения на большую аудиторию.", color = p.text, fontSize = 19.sp,
                        textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 30.dp))
                }
                Box(Modifier.padding(18.dp).navigationBarsPadding().fillMaxWidth().height(56.dp).clip(RoundedCornerShape(28.dp)).background(p.accent).clickable { step = 1 },
                    contentAlignment = Alignment.Center) { Text("Создать канал", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp) }
            }
            1 -> {
                header("Создать $noun", "Далее", title.isNotBlank()) { step = 2 }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 14.dp, vertical = 12.dp)) {
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(p.panel).padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(76.dp).clip(CircleShape).background(p.a1.copy(alpha = 0.12f))
                            .clickable { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }, contentAlignment = Alignment.Center) {
                            if (avatarUri != null) AsyncImage(avatarUri, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                            else Icon(Icons.Filled.CameraAlt, null, tint = p.a1, modifier = Modifier.size(30.dp))
                        }
                        Spacer(Modifier.width(16.dp))
                        Box(Modifier.weight(1f)) {
                            if (title.isEmpty()) Text(if (channel) "Название канала" else "Название группы", color = p.muted, fontSize = 20.sp)
                            BasicTextField(title, { title = it.take(64) }, singleLine = true, textStyle = TextStyle(color = p.text, fontSize = 20.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth())
                        }
                    }
                    Spacer(Modifier.height(18.dp))
                    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel).padding(horizontal = 18.dp, vertical = 16.dp)) {
                        if (about.isEmpty()) Text("Описание", color = p.muted, fontSize = 19.sp)
                        BasicTextField(about, { about = it }, maxLines = 5, textStyle = TextStyle(color = p.text, fontSize = 19.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth())
                    }
                    foot("Можете указать дополнительное описание $nounOf.")
                }
            }
            2 -> {
                header("Тип $nounOf", "Далее", !isPublic || clean.length >= 5) { step = 3 }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(top = 8.dp, bottom = 30.dp)) {
                    Text("ССЫЛКА", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 28.dp, vertical = 6.dp))
                    Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel)) {
                        typeRow("Публичная", isPublic) { isPublic = true }
                        Divider()
                        typeRow("Частная", !isPublic) { isPublic = false }
                    }
                    val many = if (channel) "каналы" else "группы"
                    foot(if (isPublic) "Публичные $many можно найти через поиск, вступить в них может любой пользователь." else "На частные $many можно вступить только по ссылке-приглашению.")
                    if (isPublic) {
                        Row(Modifier.padding(horizontal = 14.dp, vertical = 12.dp).fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(p.panel).padding(horizontal = 18.dp, vertical = 16.dp)) {
                            Text("@", color = p.text, fontSize = 19.sp)
                            Box(Modifier.weight(1f)) {
                                if (username.isEmpty()) Text("ссылка", color = p.muted, fontSize = 19.sp)
                                BasicTextField(username, { username = it.filter { ch -> ch.isLetterOrDigit() || ch == '_' }.take(32) }, singleLine = true,
                                    textStyle = TextStyle(color = p.text, fontSize = 19.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth(),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii))
                            }
                        }
                        foot("Если у $nounOf будет постоянная публичная ссылка, другие пользователи смогут найти ${if (channel) "его" else "её"} и вступить.")
                        foot("Можно использовать латиницу (a-z), цифры (0-9) и подчёркивание. Минимальная длина — 5 символов.")
                    } else {
                        Text("ССЫЛКА-ПРИГЛАШЕНИЕ", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(start = 28.dp, end = 28.dp, top = 16.dp, bottom = 6.dp))
                        Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel).padding(10.dp)) {
                            var menu by remember { mutableStateOf(false) }
                            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.bg).padding(start = 16.dp, end = 8.dp, top = 8.dp, bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text("…#+" + invite, color = p.text, fontSize = 18.sp, textAlign = TextAlign.Center, maxLines = 1, modifier = Modifier.weight(1f))
                                Box {
                                    Box(Modifier.size(34.dp).clip(CircleShape).background(p.muted.copy(alpha = 0.7f)).clickable { menu = true }, contentAlignment = Alignment.Center) {
                                        Icon(Icons.Filled.MoreHoriz, null, tint = Color.White, modifier = Modifier.size(20.dp))
                                    }
                                    DropdownMenu(menu, { menu = false }) {
                                        DropdownMenuItem(text = { Text("Копировать") }, leadingIcon = { Icon(Icons.Filled.ContentCopy, null) }, onClick = { menu = false; copy(ctx, link); AppModel.say("Ссылка скопирована") })
                                        DropdownMenuItem(text = { Text("Создать новую") }, leadingIcon = { Icon(Icons.Filled.Refresh, null) }, onClick = { menu = false; invite = newCode() })
                                    }
                                }
                            }
                            Spacer(Modifier.height(10.dp))
                            Box(Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(26.dp)).background(p.accent).clickable {
                                val i = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, link) }
                                ctx.startActivity(Intent.createChooser(i, "Поделиться").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            }, contentAlignment = Alignment.Center) { Text("Поделиться", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp) }
                        }
                        foot("По этой ссылке можно вступить в ${if (channel) "канал" else "группу"}. Вы можете сбросить её в любой момент.")
                        Spacer(Modifier.height(10.dp))
                        Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel)) { sw("Заявки на вступление", requests) { requests = it } }
                        foot("Новые участники смогут вступить в ${if (channel) "канал" else "группу"} только после одобрения заявки администратором.")
                    }
                    Text("СОХРАНЕНИЕ И КОПИРОВАНИЕ МАТЕРИАЛОВ", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(start = 28.dp, end = 28.dp, top = 16.dp, bottom = 6.dp))
                    Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel)) { sw("Запретить копирование", noCopy) { noCopy = it } }
                    foot(if (channel) "Подписчики смогут копировать, сохранять или пересылать материалы из канала." else "Участники смогут копировать, сохранять или пересылать материалы из группы.")
                }
            }
            else -> {
                header(if (channel) "Подписчики" else "Участники")
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(top = 6.dp)) {
                    foot("Это необязательно — людей можно позвать позже по ссылке или из списка контактов.")
                    AppModel.contacts.forEach { id ->
                        val on = id in picked
                        val pr = AppModel.profiles[id]
                        Row(Modifier.fillMaxWidth().clickable { if (on) picked.remove(id) else picked.add(id) }.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                            Avatar(AppModel.displayName(id), pr?.avatarUrl, pr?.color ?: 0, 44.dp)
                            Spacer(Modifier.width(12.dp))
                            Text(AppModel.displayName(id), color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, modifier = Modifier.weight(1f))
                            Icon(if (on) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null, tint = if (on) p.a1 else p.muted)
                        }
                    }
                }
                Box(Modifier.padding(18.dp).navigationBarsPadding().fillMaxWidth().height(56.dp).clip(RoundedCornerShape(28.dp)).background(p.accent).clickable(enabled = !busy) {
                    busy = true
                    scope.launch {
                        val bytes = avatarUri?.let { u -> withContext(Dispatchers.IO) { MediaUtil.read(ctx, u)?.let { MediaUtil.jpeg(it)?.first } } }
                        val id = AppModel.createChat(mode, title.trim(), about, picked.toList(), if (isPublic) clean else null, noCopy, if (isPublic) false else requests, invite, bytes)
                        busy = false
                        if (id != null) onClose()
                    }
                }, contentAlignment = Alignment.Center) { Text(if (busy) "Создаём…" else "Создать $noun", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp) }
            }
        }
    }
}

private fun newCode(): String = (1..16).map { "0123456789abcdef".random() }.joinToString("")

@Composable
private fun ChannelArt() {
    Box(Modifier.size(260.dp, 250.dp), contentAlignment = Alignment.Center) {
        Box(Modifier.size(150.dp, 230.dp).clip(RoundedCornerShape(30.dp)).background(Color(0xFFB9D8F6)).border(5.dp, Color(0xFF3B4A5C), RoundedCornerShape(30.dp)))
        Text("🦆", fontSize = 86.sp, modifier = Modifier.offset(y = 34.dp))
        Box(Modifier.offset(x = (-4).dp, y = (-36).dp).size(96.dp, 34.dp).clip(RoundedCornerShape(10.dp)).background(Color.White.copy(alpha = 0.9f)))
        Column(Modifier.offset(x = (-82).dp, y = (-78).dp).size(98.dp).clip(CircleShape).background(Color(0xFFCFE4F8)).border(3.dp, Color.White, CircleShape),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text("Канал", color = Color(0xFF1D2733), fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Text("57k подписчиков", color = Color(0xFF5B6B7D), fontSize = 10.sp)
        }
        Column(Modifier.offset(x = 82.dp, y = 6.dp).size(96.dp).clip(CircleShape).background(Color(0xFFCFE4F8)).border(3.dp, Color.White, CircleShape),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text("просмотры", color = Color(0xFF5B6B7D), fontSize = 12.sp)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Visibility, null, tint = Color(0xFF5B6B7D), modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(4.dp))
                Text("1K", color = Color(0xFF5B6B7D), fontSize = 16.sp)
            }
        }
    }
}
