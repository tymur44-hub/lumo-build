package ru.volshebnymir.lumo.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.premium
import ru.volshebnymir.lumo.core.isPremium
import ru.volshebnymir.lumo.core.Message
import ru.volshebnymir.lumo.core.Screen
import ru.volshebnymir.lumo.core.SearchResult

@Composable
fun TopBar(title: String, right: (@Composable () -> Unit)? = null) {
    val p = P
    Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 4.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        RoundIcon(Icons.AutoMirrored.Filled.ArrowBack) { AppModel.pop() }
        Text(title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp, modifier = Modifier.weight(1f).padding(start = 4.dp))
        right?.invoke()
    }
}

/** Шапка профиля как в Telegram: большое фото, имя, статус и кнопки действий */
@Composable
private fun ProfileHead(name: String, url: String?, color: Int, status: String, statusOn: Boolean, onAvatar: () -> Unit) {
    val p = P
    Column(Modifier.fillMaxWidth().padding(top = 6.dp, bottom = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.clickable(enabled = !url.isNullOrEmpty()) { onAvatar() }) { Avatar(name, url, color, 112.dp) }
        Spacer(Modifier.height(12.dp))
        Text(name, color = p.text, fontWeight = FontWeight.Black, fontSize = 25.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 20.dp))
        if (status.isNotEmpty()) Text(status, color = if (statusOn) p.a2 else p.muted, fontSize = 15.sp)
    }
}

@Composable
private fun ActionTile(icon: ImageVector, label: String, modifier: Modifier, danger: Boolean = false, onClick: () -> Unit) {
    val p = P
    Column(modifier.clip(RoundedCornerShape(16.dp)).background(p.panel).bouncy(onClick).padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, null, tint = if (danger) p.danger else p.a1, modifier = Modifier.size(24.dp))
        Spacer(Modifier.height(4.dp))
        Text(label, color = if (danger) p.danger else p.text, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun InfoLine(value: String, label: String, onClick: (() -> Unit)? = null) {
    val p = P
    Column(Modifier.fillMaxWidth().then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier).padding(vertical = 10.dp)) {
        Text(value, color = p.text, fontSize = 16.sp)
        Text(label, color = p.muted, fontSize = 13.sp)
    }
}

/** Раздел «Медиа / Файлы / Голосовые» */
@Composable
fun SharedMediaSection(chatId: String?) {
    val p = P
    val ctx = LocalContext.current
    if (chatId == null) return
    var tab by remember { mutableStateOf(0) }
    var items by remember { mutableStateOf<List<Message>?>(null) }
    var viewer by remember { mutableStateOf<Message?>(null) }
    val kinds = listOf(listOf("image", "video"), listOf("file"), listOf("voice", "video_note"))
    LaunchedEffect(chatId, tab) { items = null; items = AppModel.sharedMedia(chatId, kinds[tab]) }
    Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(p.panel).padding(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            listOf("Медиа", "Файлы", "Аудио").forEachIndexed { i, t -> Pill(t, tab == i) { tab = i } }
        }
        Spacer(Modifier.height(10.dp))
        val list = items
        when {
            list == null -> Box(Modifier.fillMaxWidth().height(80.dp), contentAlignment = Alignment.Center) { androidx.compose.material3.CircularProgressIndicator(color = p.a1, modifier = Modifier.size(26.dp)) }
            list.isEmpty() -> Text("Здесь пока пусто", color = p.muted, modifier = Modifier.fillMaxWidth().padding(20.dp), textAlign = TextAlign.Center)
            tab == 0 -> {
                list.chunked(3).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                        row.forEach { m ->
                            Box(Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(6.dp)).background(Color.Black).clickable { viewer = m }, contentAlignment = Alignment.Center) {
                                AsyncImage(m.mediaUrl, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                                if (m.kind == "video") Icon(Icons.Filled.PlayCircle, null, tint = Color.White)
                            }
                        }
                        repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                    Spacer(Modifier.height(3.dp))
                }
            }
            else -> list.forEach { m ->
                Row(Modifier.fillMaxWidth().clickable { MediaUtil.open(ctx, m.mediaUrl) }.padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(40.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) {
                        Icon(when (m.kind) { "voice" -> Icons.Filled.Mic; "video_note" -> Icons.Filled.SlowMotionVideo; else -> Icons.Filled.Description }, null, tint = Color.White)
                    }
                    Spacer(Modifier.width(10.dp))
                    Column {
                        Text(if (m.kind == "file") m.fileName else m.preview, color = p.text, fontWeight = FontWeight.SemiBold, maxLines = 1)
                        Text(AppModel.displayName(m.senderId) + " · " + ru.volshebnymir.lumo.core.Fmt.listTime(m.createdAt), color = p.muted, fontSize = 13.sp)
                    }
                }
            }
        }
    }
    viewer?.let { Box(Modifier.fillMaxSize()) { MediaViewer(it) { viewer = null } } }
}

private fun avatarMsg(url: String) = Message(0, "", null, "image", null, url, JSONObject(), null, null, null, false, java.util.Date())

/** Личный канал в профиле */
@Composable
fun ChannelCard(pr: ru.volshebnymir.lumo.core.Profile) {
    val p = P
    val scope = rememberCoroutineScope()
    val id = pr.channelId ?: return
    Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(p.panel).clickable {
        scope.launch { if (AppModel.chat(id) != null) AppModel.open(id) else AppModel.join(id) }
    }.padding(16.dp)) {
        Text("КАНАЛ", color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Avatar(pr.channelTitle ?: "", pr.channelAvatar, pr.channelColor, 46.dp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(pr.channelTitle ?: "Канал", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                Text(ru.volshebnymir.lumo.ui.plural(pr.channelMembers, "подписчик", "подписчика", "подписчиков") + (pr.channelUsername?.let { " · @$it" } ?: ""), color = p.muted, fontSize = 13.sp)
            }
            Icon(Icons.Filled.ChevronRight, null, tint = p.muted)
        }
    }
    Spacer(Modifier.height(14.dp))
}

// ---------------- профиль человека ----------------

@Composable
fun PersonScreen(userId: String) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val pr = AppModel.profiles[userId]
    var viewer by remember { mutableStateOf<Message?>(null) }
    var alias by remember { mutableStateOf<String?>(null) }
    var menu by remember { mutableStateOf(false) }
    var report by remember { mutableStateOf(false) }
    var confirmBlock by remember { mutableStateOf(false) }
    var safety by remember { mutableStateOf(false) }
    LaunchedEffect(userId) { AppModel.refreshProfile(userId); AppModel.loadBlocks() }
    val dm = AppModel.chats.firstOrNull { it.isPrivate && it.peerId == userId }
    val call = rememberCallStarter()
    val blocked = userId in AppModel.blockedByMe
    Box(Modifier.fillMaxSize().background(p.bg)) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            TopBar("", right = {
                Box {
                    RoundIcon(Icons.Filled.MoreVert) { menu = true }
                    androidx.compose.material3.DropdownMenu(menu, { menu = false }) {
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Скопировать @" + (pr?.username ?: "")) }, leadingIcon = { Icon(Icons.Filled.ContentCopy, null) },
                            onClick = { menu = false; copy(ctx, "@" + (pr?.username ?: "")) })
                        if (dm != null) androidx.compose.material3.DropdownMenuItem(text = { Text("Поиск в чате") }, leadingIcon = { Icon(Icons.Filled.Search, null) },
                            onClick = { menu = false; AppModel.push(Screen.ChatSearch(dm.id)) })
                        if (dm != null) androidx.compose.material3.DropdownMenuItem(text = { Text("Очистить историю") }, leadingIcon = { Icon(Icons.Filled.CleaningServices, null) },
                            onClick = { menu = false; scope.launch { AppModel.clearChat(dm.id) } })
                        androidx.compose.material3.DropdownMenuItem(text = { Text(if (blocked) "Разблокировать" else "Заблокировать", color = p.danger) }, leadingIcon = { Icon(Icons.Filled.Block, null, tint = p.danger) },
                            onClick = { menu = false; if (blocked) scope.launch { AppModel.setBlocked(userId, false) } else confirmBlock = true })
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Пожаловаться", color = p.danger) }, leadingIcon = { Icon(Icons.Filled.Flag, null, tint = p.danger) },
                            onClick = { menu = false; report = true })
                    }
                }
            })
            ProfileHead(AppModel.displayName(userId), pr?.avatarUrl, pr?.color ?: 0, AppModel.lastSeenText(userId), AppModel.isOnline(userId)) {
                pr?.avatarUrl?.let { viewer = avatarMsg(it) }
            }
            Row(Modifier.padding(horizontal = 14.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ActionTile(Icons.Filled.ChatBubble, "Чат", Modifier.weight(1f)) { scope.launch { AppModel.openDM(userId) } }
                if (pr?.isBot != true && dm?.peerBot != true) {
                    ActionTile(Icons.Filled.Call, "Звонок", Modifier.weight(1f)) {
                        if (dm != null) call(dm, false) else scope.launch { AppModel.openDM(userId) }
                    }
                    ActionTile(Icons.Filled.Videocam, "Видео", Modifier.weight(1f)) {
                        if (dm != null) call(dm, true) else scope.launch { AppModel.openDM(userId) }
                    }
                }
                if (dm != null) ActionTile(if (dm.muted) Icons.Filled.NotificationsActive else Icons.Filled.NotificationsOff, if (dm.muted) "Звук" else "Без звука", Modifier.weight(1f)) {
                    scope.launch { AppModel.setMuted(dm.id, !dm.muted) }
                }
            }
            Spacer(Modifier.height(14.dp))
            Card {
                InfoLine("@" + (pr?.username ?: ""), "Юзернейм") { copy(ctx, "@" + (pr?.username ?: "")) }
                if (!pr?.bio.isNullOrEmpty()) { Divider(); InfoLine(pr!!.bio, "О себе") }
                ru.volshebnymir.lumo.core.Birthday.text(pr?.birthday, withAge = true)?.let { Divider(); InfoLine(it, "День рождения") }
                if (AppModel.isContact(userId)) { Divider(); InfoLine(AppModel.aliases[userId]?.takeIf { it.isNotEmpty() } ?: "Не задано", "Имя в контактах · видите только вы") { alias = AppModel.aliases[userId] ?: "" } }
            }
            Spacer(Modifier.height(14.dp))
            if (pr?.premium == true && pr.isBot != true) ProfileLinks(userId)
            Card {
                SettingsRow(Icons.Filled.Lock, p.a1, "Код безопасности", "Проверить сквозное шифрование") { safety = true }
                Divider()
                if (AppModel.isContact(userId)) SettingsRow(Icons.Filled.PersonRemove, p.danger, "Удалить из контактов", titleColor = p.danger) { scope.launch { AppModel.removeContact(userId) } }
                else SettingsRow(Icons.Filled.PersonAdd, p.a1, "Добавить в контакты") { scope.launch { AppModel.addContact(userId) } }
                Divider()
                SettingsRow(Icons.Filled.Block, p.danger, if (blocked) "Разблокировать" else "Заблокировать", titleColor = p.danger) {
                    if (blocked) scope.launch { AppModel.setBlocked(userId, false) } else confirmBlock = true
                }
            }
            Spacer(Modifier.height(14.dp))
            if (dm != null && pr?.isBot != true) PremiumChatCard(dm)
            pr?.let { ChannelCard(it) }
            SharedMediaSection(dm?.id)
            Spacer(Modifier.height(30.dp))
        }
        viewer?.let { MediaViewer(it) { viewer = null } }
    }
    alias?.let { a ->
        var v by remember { mutableStateOf(a) }
        AlertDialog(onDismissRequest = { alias = null }, title = { Text("Имя в контактах") },
            text = { LumoField(v, { v = it }, "Имя") },
            confirmButton = { TextButton({ alias = null; scope.launch { AppModel.setAlias(userId, v.trim()) } }) { Text("Сохранить") } },
            dismissButton = { TextButton({ alias = null }) { Text("Отмена") } })
    }
    if (report) ReportDialog(userId, null, null) { report = false }
    if (safety) SafetyDialog(userId) { safety = false }
    if (confirmBlock) AlertDialog(onDismissRequest = { confirmBlock = false }, title = { Text("Заблокировать ${AppModel.displayName(userId)}?") },
        text = { Text("Человек не сможет писать и звонить вам") },
        confirmButton = { TextButton({ confirmBlock = false; scope.launch { AppModel.setBlocked(userId, true) } }) { Text("Заблокировать", color = p.danger) } },
        dismissButton = { TextButton({ confirmBlock = false }) { Text("Отмена") } })
}

// ---------------- группа / канал ----------------

@Composable
fun InfoScreen(chatId: String) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val c = AppModel.chat(chatId)
    var members by remember { mutableStateOf<List<Pair<String, String>>>(emptyList()) }
    var viewer by remember { mutableStateOf<Message?>(null) }
    var confirmLeave by remember { mutableStateOf(false) }
    var confirmClear by remember { mutableStateOf(false) }
    var edit by remember { mutableStateOf(false) }
    var adding by remember { mutableStateOf(false) }
    var report by remember { mutableStateOf(false) }
    var memberMenu by remember { mutableStateOf<Pair<String, String>?>(null) }
    suspend fun reload() { members = AppModel.members(chatId) }
    LaunchedEffect(chatId) { reload() }
    val admin = c?.isAdmin == true
    val owner = c?.role == "owner"
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u ->
        if (u == null) return@rememberLauncherForActivityResult
        scope.launch {
            val d = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u)?.let { MediaUtil.jpeg(it) } } ?: return@launch
            AppModel.setChatAvatar(chatId, d.first)
        }
    }
    Box(Modifier.fillMaxSize().background(p.bg)) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            TopBar("", right = { if (admin) Text("Изм.", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.clickable { edit = true }.padding(12.dp)) })
            ProfileHead(c?.displayName ?: "", c?.displayAvatar, c?.displayColor ?: 0,
                if (c?.isChannel == true) "${c.membersCount} подписч." else "${c?.membersCount ?: 0} участн.", false) {
                c?.displayAvatar?.let { viewer = avatarMsg(it) }
            }
            Row(Modifier.padding(horizontal = 14.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (c != null) ActionTile(if (c.muted) Icons.Filled.NotificationsActive else Icons.Filled.NotificationsOff, if (c.muted) "Звук" else "Без звука", Modifier.weight(1f)) {
                    scope.launch { AppModel.setMuted(chatId, !c.muted) }
                }
                ActionTile(Icons.Filled.Search, "Поиск", Modifier.weight(1f)) { AppModel.push(Screen.ChatSearch(chatId)) }
                ActionTile(Icons.Filled.CleaningServices, "Очистить", Modifier.weight(1f)) { confirmClear = true }
                ActionTile(Icons.AutoMirrored.Filled.ExitToApp, "Выйти", Modifier.weight(1f), danger = true) { confirmLeave = true }
            }
            Spacer(Modifier.height(14.dp))
            if (!c?.description.isNullOrEmpty() || !c?.username.isNullOrEmpty()) {
                Card {
                    if (!c?.description.isNullOrEmpty()) InfoLine(c!!.description!!, "Описание")
                    if (!c?.username.isNullOrEmpty()) { if (!c?.description.isNullOrEmpty()) Divider(); InfoLine("@" + c!!.username, "Нажмите, чтобы скопировать") { copy(ctx, "@" + c.username) } }
                }
                Spacer(Modifier.height(14.dp))
            }
            if (admin) {
                Card {
                    SettingsRow(Icons.Filled.Edit, p.a1, "Изменить название и описание") { edit = true }
                    Divider()
                    SettingsRow(Icons.Filled.CameraAlt, Color(0xFF22A6FF), "Сменить фото") { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }
                    if (c?.type == "group") { Divider(); SettingsRow(Icons.Filled.PersonAdd, Color(0xFF2BD67B), "Добавить участников") { adding = true } }
                }
                Spacer(Modifier.height(14.dp))
            }
            PremiumChatCard(c)
            SharedMediaSection(chatId)
            Spacer(Modifier.height(14.dp))
            if (c?.isChannel != true || admin) Card {
                Text("Участники", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.padding(top = 10.dp))
                members.forEach { (uid, role) ->
                    val pr = AppModel.profiles[uid]
                    Box {
                        Row(Modifier.fillMaxWidth().clickable { if (uid != AppModel.myId) memberMenu = uid to role }.padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                            Avatar(AppModel.displayName(uid), pr?.avatarUrl, pr?.color ?: 0, 42.dp, online = AppModel.isOnline(uid))
                            Spacer(Modifier.width(10.dp))
                            Column(Modifier.weight(1f)) {
                                Text(AppModel.displayName(uid), color = p.text, fontWeight = FontWeight.SemiBold)
                                Text(AppModel.lastSeenText(uid), color = p.muted, fontSize = 13.sp)
                            }
                            if (role == "owner" || role == "admin") Text(if (role == "owner") "владелец" else "админ", color = p.a1, fontSize = 13.sp)
                        }
                        androidx.compose.material3.DropdownMenu(memberMenu?.first == uid, { memberMenu = null }) {
                            androidx.compose.material3.DropdownMenuItem(text = { Text("Профиль") }, onClick = { memberMenu = null; AppModel.push(Screen.Person(uid)) })
                            androidx.compose.material3.DropdownMenuItem(text = { Text("Написать") }, onClick = { memberMenu = null; scope.launch { AppModel.openDM(uid) } })
                            if (owner && role != "owner") androidx.compose.material3.DropdownMenuItem(
                                text = { Text(if (role == "admin") "Снять админа" else "Сделать админом") },
                                onClick = { memberMenu = null; scope.launch { AppModel.setRole(chatId, uid, if (role == "admin") "member" else "admin"); reload() } })
                            if (admin && role != "owner" && (owner || role != "admin")) androidx.compose.material3.DropdownMenuItem(
                                text = { Text("Исключить", color = p.danger) },
                                onClick = { memberMenu = null; scope.launch { AppModel.removeMember(chatId, uid); reload() } })
                        }
                    }
                }
            }
            Spacer(Modifier.height(14.dp))
            Card { SettingsRow(Icons.Filled.Flag, p.danger, "Пожаловаться", titleColor = p.danger) { report = true } }
            Spacer(Modifier.height(30.dp))
        }
        viewer?.let { MediaViewer(it) { viewer = null } }
    }
    if (confirmLeave) AlertDialog(onDismissRequest = { confirmLeave = false }, title = { Text("Выйти из чата?") },
        confirmButton = { TextButton({ confirmLeave = false; scope.launch { AppModel.leave(chatId) } }) { Text("Выйти", color = p.danger) } },
        dismissButton = { TextButton({ confirmLeave = false }) { Text("Отмена") } })
    if (confirmClear) AlertDialog(onDismissRequest = { confirmClear = false }, title = { Text("Очистить историю?") }, text = { Text("Сообщения исчезнут только у вас") },
        confirmButton = { TextButton({ confirmClear = false; scope.launch { AppModel.clearChat(chatId) } }) { Text("Очистить", color = p.danger) } },
        dismissButton = { TextButton({ confirmClear = false }) { Text("Отмена") } })
    if (report) ReportDialog(null, chatId, null) { report = false }
    if (edit && c != null) {
        var t by remember { mutableStateOf(c.title ?: "") }
        var d by remember { mutableStateOf(c.description ?: "") }
        AlertDialog(onDismissRequest = { edit = false }, title = { Text("Изменить") },
            text = { Column(verticalArrangement = Arrangement.spacedBy(10.dp)) { LumoField(t, { t = it }, "Название"); LumoField(d, { d = it.take(300) }, "Описание", singleLine = false) } },
            confirmButton = { TextButton({ if (t.isNotBlank()) { edit = false; scope.launch { AppModel.saveChat(chatId, t.trim(), d.trim()) } } }) { Text("Сохранить") } },
            dismissButton = { TextButton({ edit = false }) { Text("Отмена") } })
    }
    if (adding) {
        val picked = remember { mutableStateListOf<String>() }
        val cand = AppModel.contacts.filter { id -> members.none { it.first == id } }
        AlertDialog(onDismissRequest = { adding = false }, title = { Text("Добавить участников") },
            text = {
                Column(Modifier.heightIn(max = 420.dp).verticalScroll(rememberScrollState())) {
                    if (cand.isEmpty()) Text("Все ваши контакты уже в группе", color = p.muted)
                    cand.forEach { id ->
                        val on = id in picked
                        Row(Modifier.fillMaxWidth().clickable { if (on) picked.remove(id) else picked.add(id) }.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(if (on) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null, tint = if (on) p.a1 else p.muted)
                            Spacer(Modifier.width(8.dp))
                            Text(AppModel.displayName(id), color = p.text)
                        }
                    }
                }
            },
            confirmButton = { TextButton({ adding = false; if (picked.isNotEmpty()) scope.launch { AppModel.addMembers(chatId, picked.toList()); reload() } }) { Text("Добавить") } },
            dismissButton = { TextButton({ adding = false }) { Text("Отмена") } })
    }
}

// ---------------- поиск по сообщениям ----------------

@Composable
fun ChatSearchScreen(chatId: String) {
    val p = P
    var q by remember { mutableStateOf("") }
    var res by remember { mutableStateOf<List<Message>?>(null) }
    LaunchedEffect(q) { res = if (q.trim().length >= 2) { kotlinx.coroutines.delay(300); AppModel.searchMessages(chatId, q.trim()) } else null }
    Column(Modifier.fillMaxSize().background(p.bg).imePadding()) {
        TopBar("Поиск в чате")
        SearchBox(q, { q = it }, Modifier.padding(horizontal = 14.dp).fillMaxWidth())
        LazyColumn(Modifier.fillMaxSize()) {
            val r = res
            if (r != null && r.isEmpty()) item { Text("Ничего не найдено", color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp)) }
            items(r ?: emptyList(), key = { it.id }) { m ->
                val pr = m.senderId?.let { AppModel.profiles[it] }
                Row(Modifier.fillMaxWidth().clickable { AppModel.pop(); AppModel.pendingJump = m.id; if (AppModel.stack.lastOrNull() !is Screen.Chat) AppModel.push(Screen.Chat(chatId)) }
                    .padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(AppModel.displayName(m.senderId), pr?.avatarUrl, pr?.color ?: 0, 42.dp)
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Row { Text(AppModel.displayName(m.senderId), color = p.text, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f)); Text(ru.volshebnymir.lumo.core.Fmt.listTime(m.createdAt), color = p.muted, fontSize = 12.sp) }
                        Text(m.body ?: "", color = p.muted, maxLines = 2)
                    }
                }
            }
        }
    }
}

// ---------------- мой профиль ----------------

@Composable
fun MyProfileScreen() {
    val p = P
    val ctx = LocalContext.current
    val me = AppModel.me
    var viewer by remember { mutableStateOf<Message?>(null) }
    val saved = AppModel.chats.firstOrNull { it.isPrivate && it.peerId == AppModel.myId }
    Box(Modifier.fillMaxSize().background(p.bg)) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            TopBar("", right = { Text("Изм.", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.clickable { AppModel.push(Screen.EditProfile) }.padding(12.dp)) })
            ProfileHead(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, "в сети", true) { me?.avatarUrl?.let { viewer = avatarMsg(it) } }
            Row(Modifier.padding(horizontal = 14.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ActionTile(Icons.Filled.QrCode, "QR-код", Modifier.weight(1f)) { Ui.qrMine = true }
                ActionTile(Icons.Filled.Edit, "Изменить", Modifier.weight(1f)) { AppModel.push(Screen.EditProfile) }
                ActionTile(Icons.Filled.Share, "Поделиться", Modifier.weight(1f)) {
                    val link = ru.volshebnymir.lumo.core.Config.SITE + "#@" + (me?.username ?: "")
                    runCatching { ctx.startActivity(android.content.Intent.createChooser(android.content.Intent(android.content.Intent.ACTION_SEND).setType("text/plain")
                        .putExtra(android.content.Intent.EXTRA_TEXT, "Пиши мне в Lumo: $link"), "Поделиться").addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)) }
                }
            }
            Spacer(Modifier.height(14.dp))
            Card {
                InfoLine("@" + (me?.username ?: ""), "Юзернейм") { copy(ctx, "@" + (me?.username ?: "")) }
                if (!me?.bio.isNullOrEmpty()) { Divider(); InfoLine(me!!.bio, "О себе") }
                ru.volshebnymir.lumo.core.Birthday.text(me?.birthday, withAge = true)?.let { Divider(); InfoLine(it, "День рождения") }
            }
            Spacer(Modifier.height(14.dp))
            me?.let { ChannelCard(it) }
            SharedMediaSection(saved?.id)
            Spacer(Modifier.height(30.dp))
        }
        viewer?.let { MediaViewer(it) { viewer = null } }
    }
}

/** Поле внутри карточки без собственного фона */
@Composable
private fun PlainField(value: String, onChange: (String) -> Unit, hint: String, singleLine: Boolean = true) {
    val p = P
    Box(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 17.dp)) {
        if (value.isEmpty()) Text(hint, color = p.muted.copy(alpha = 0.7f), fontSize = 17.sp)
        androidx.compose.foundation.text.BasicTextField(value, onChange, singleLine = singleLine, maxLines = if (singleLine) 1 else 4,
            textStyle = androidx.compose.ui.text.TextStyle(color = p.text, fontSize = 17.sp), cursorBrush = androidx.compose.ui.graphics.SolidColor(p.a1),
            modifier = Modifier.fillMaxWidth())
    }
}

@Composable
private fun GroupCard(content: @Composable ColumnScope.() -> Unit) {
    val p = P
    Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel), content = content)
}

@Composable
private fun CardDivider(start: Int = 20) { val p = P; Box(Modifier.padding(start = start.dp, end = 20.dp).fillMaxWidth().height(1.dp).background(p.line)) }

/** Подсказка под карточкой со ссылкой «Изменить ›» */
@Composable
private fun HintWithLink(text: String, link: String? = null, onLink: () -> Unit = {}) {
    val p = P
    Column(Modifier.padding(start = 30.dp, end = 30.dp, top = 6.dp, bottom = 14.dp)) {
        Text(text, color = p.muted, fontSize = 13.5.sp)
        if (link != null) Text("$link ›", color = p.a1, fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable(onClick = onLink).padding(top = 2.dp))
    }
}

@Composable
private fun IconRow(icon: ImageVector, color: Color, title: String, value: String?, onClick: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 18.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(color), contentAlignment = Alignment.Center) { Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp)) }
        Spacer(Modifier.width(16.dp))
        Text(title, color = p.text, fontSize = 17.sp, modifier = Modifier.weight(1f), maxLines = 1)
        if (value != null) Text(value, color = p.muted, fontSize = 16.sp, maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 170.dp))
        Icon(Icons.Filled.ChevronRight, null, tint = p.muted.copy(alpha = 0.6f), modifier = Modifier.size(22.dp))
    }
}

/** Изменение профиля — как в Telegram */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen() {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val me = AppModel.me
    var first by remember { mutableStateOf(me?.firstName ?: "") }
    var last by remember { mutableStateOf(me?.lastName ?: "") }
    var bio by remember { mutableStateOf(me?.bio ?: "") }
    var birthday by remember { mutableStateOf(me?.birthday?.take(10)) }
    var busy by remember { mutableStateOf(false) }
    var photoMenu by remember { mutableStateOf(false) }
    var datePick by remember { mutableStateOf(false) }
    var channelPick by remember { mutableStateOf(false) }
    var pwDialog by remember { mutableStateOf(false) }
    var extraDlg by remember { mutableStateOf(false) }
    var delAcc by remember { mutableStateOf(false) }
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u ->
        if (u == null) return@rememberLauncherForActivityResult
        scope.launch {
            val d = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u)?.let { MediaUtil.jpeg(it) } } ?: return@launch
            runCatching { AppModel.setAvatar(d.first) }.onSuccess { AppModel.say("Фото обновлено") }.onFailure { AppModel.say(it.message ?: "Ошибка") }
        }
    }
    fun save() {
        if (busy) return
        busy = true
        scope.launch {
            runCatching { AppModel.saveProfileFull(first, last, bio.take(70), birthday) }
                .onSuccess { AppModel.say("Сохранено"); AppModel.pop() }.onFailure { AppModel.say(it.message ?: "Ошибка") }
            busy = false
        }
    }
    Box(Modifier.fillMaxSize().background(p.bg)) {
        Column(Modifier.fillMaxSize().statusBarsPadding().imePadding().verticalScroll(rememberScrollState())) {
            Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
                Box(Modifier.align(Alignment.TopStart).size(52.dp).clip(CircleShape).background(p.panel).bouncy { AppModel.pop() }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Close, null, tint = p.text, modifier = Modifier.size(28.dp))
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.align(Alignment.TopCenter).padding(top = 4.dp)) {
                    Box(Modifier.clickable { photoMenu = true }) {
                        Avatar(listOf(first, last).joinToString(" ").trim(), me?.avatarUrl, me?.color ?: 0, 120.dp)
                        androidx.compose.material3.DropdownMenu(photoMenu, { photoMenu = false }) {
                            androidx.compose.material3.DropdownMenuItem(text = { Text("Выбрать фото") }, leadingIcon = { Icon(Icons.Filled.Photo, null) },
                                onClick = { photoMenu = false; pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) })
                            if (!me?.avatarUrl.isNullOrEmpty()) androidx.compose.material3.DropdownMenuItem(text = { Text("Удалить фото", color = p.danger) },
                                leadingIcon = { Icon(Icons.Filled.Delete, null, tint = p.danger) },
                                onClick = { photoMenu = false; scope.launch { runCatching { AppModel.setAvatar(null) } } })
                        }
                    }
                    Text("Изменить фотографию", color = p.a1, fontSize = 18.sp, modifier = Modifier.padding(top = 12.dp).clickable { photoMenu = true })
                }
                Box(Modifier.align(Alignment.TopEnd).size(52.dp).clip(CircleShape).background(p.accent).bouncy { save() }, contentAlignment = Alignment.Center) {
                    if (busy) androidx.compose.material3.CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.5.dp)
                    else Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(30.dp))
                }
            }
            Spacer(Modifier.height(16.dp))
            GroupCard {
                PlainField(first, { first = it.take(64) }, "Имя")
                CardDivider()
                PlainField(last, { last = it.take(64) }, "Фамилия")
            }
            HintWithLink("Укажите имя и, если хотите, добавьте фотографию для Вашего профиля.")
            GroupCard { PlainField(bio, { bio = it.take(70) }, "О себе", singleLine = false) }
            HintWithLink("Раздел «О себе» видят: " + privLabel(me?.priv("bio") ?: "all").lowercase() + ".", "Изменить") { AppModel.push(Screen.PrivacyKey("bio")) }
            GroupCard {
                Row(Modifier.fillMaxWidth().clickable { datePick = true }.padding(horizontal = 18.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(Color(0xFF3A8DFF)), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.Cake, null, tint = Color.White, modifier = Modifier.size(20.dp))
                    }
                    Spacer(Modifier.width(16.dp))
                    Text("День рождения", color = p.text, fontSize = 17.sp, modifier = Modifier.weight(1f))
                    Text(ru.volshebnymir.lumo.core.Birthday.text(birthday) ?: "Указать", color = if (birthday == null) p.a1 else p.muted, fontSize = 16.sp)
                }
            }
            HintWithLink("Ваш день рождения видят: " + privLabel(me?.priv("birthday") ?: "contacts").lowercase() + ".", "Изменить") { AppModel.push(Screen.PrivacyKey("birthday")) }
            GroupCard {
                IconRow(Icons.Filled.AlternateEmail, Color(0xFF7C5CFF), "Имя пользователя", "@" + (me?.username ?: "")) { AppModel.push(Screen.EditUsername) }
                CardDivider(68)
                IconRow(Icons.Filled.Brush, Color(0xFF3AB8FF), "Персональные цвета", null) { AppModel.push(Screen.EditColor) }
                CardDivider(68)
                IconRow(Icons.Filled.Link, Color(0xFFFFB020), "Расширенный профиль", "Ссылки · Premium") { ru.volshebnymir.lumo.core.AppModel.premium { extraDlg = true } }
                CardDivider(68)
                IconRow(Icons.Filled.Campaign, Color(0xFFFFA33A), "Канал", me?.channelTitle ?: "Добавить") { channelPick = true }
            }
            Spacer(Modifier.height(18.dp))
            GroupCard {
                IconRow(Icons.Filled.Key, Color(0xFF2BD67B), "Пароль", "Изменить") { pwDialog = true }
            }
            Spacer(Modifier.height(18.dp))
            GroupCard {
                Text("Удалить аккаунт", color = p.danger, fontSize = 17.sp, textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().clickable { delAcc = true }.padding(17.dp))
            }
            Spacer(Modifier.height(40.dp))
        }
    }
    if (datePick) {
        val init = ru.volshebnymir.lumo.core.Birthday.parts(birthday)?.let { (y, m, d) ->
            java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC")).apply { clear(); set(y, m - 1, d) }.timeInMillis
        }
        val st = androidx.compose.material3.rememberDatePickerState(initialSelectedDateMillis = init, yearRange = 1920..java.util.Calendar.getInstance().get(java.util.Calendar.YEAR))
        androidx.compose.material3.DatePickerDialog(onDismissRequest = { datePick = false },
            confirmButton = { TextButton({
                st.selectedDateMillis?.let { ms ->
                    val c = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC")).apply { timeInMillis = ms }
                    birthday = String.format(java.util.Locale.US, "%04d-%02d-%02d", c.get(java.util.Calendar.YEAR), c.get(java.util.Calendar.MONTH) + 1, c.get(java.util.Calendar.DAY_OF_MONTH))
                }
                datePick = false
            }) { Text("Готово") } },
            dismissButton = { Row {
                if (birthday != null) TextButton({ birthday = null; datePick = false }) { Text("Удалить", color = p.danger) }
                TextButton({ datePick = false }) { Text("Отмена") }
            } }) { androidx.compose.material3.DatePicker(st, title = null, headline = null, showModeToggle = true) }
    }
    if (channelPick) {
        val mine = AppModel.chats.filter { it.isChannel && it.role == "owner" }
        AlertDialog(onDismissRequest = { channelPick = false }, title = { Text("Канал в профиле") },
            text = {
                Column(Modifier.heightIn(max = 420.dp).verticalScroll(rememberScrollState())) {
                    if (mine.isEmpty()) Text("У вас пока нет своих каналов. Создайте канал — и его можно будет показать в профиле.", color = p.muted)
                    mine.forEach { c ->
                        Row(Modifier.fillMaxWidth().clickable { channelPick = false; scope.launch { AppModel.setChannel(c.id) } }.padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                            Avatar(c.displayName, c.displayAvatar, c.displayColor, 40.dp)
                            Spacer(Modifier.width(10.dp))
                            Text(c.displayName, color = p.text, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            if (me?.channelId == c.id) Icon(Icons.Filled.Check, null, tint = p.a1)
                        }
                    }
                }
            },
            confirmButton = {
                if (mine.isEmpty()) TextButton({ channelPick = false; AppModel.push(Screen.NewChat) }) { Text("Создать канал") }
                else if (me?.channelId != null) TextButton({ channelPick = false; scope.launch { AppModel.setChannel(null) } }) { Text("Убрать из профиля", color = p.danger) }
            },
            dismissButton = { TextButton({ channelPick = false }) { Text("Закрыть") } })
    }
    if (extraDlg) ProfileExtraDialog { extraDlg = false }
    if (pwDialog) {
        var pw by remember { mutableStateOf("") }
        AlertDialog(onDismissRequest = { pwDialog = false }, title = { Text("Новый пароль") },
            text = { LumoField(pw, { pw = it }, "Не меньше 6 символов", password = true) },
            confirmButton = { TextButton({
                if (pw.length < 6) { AppModel.say("Пароль слишком короткий"); return@TextButton }
                pwDialog = false
                scope.launch { runCatching { AppModel.setPassword(pw) }.onSuccess { AppModel.say("Пароль изменён") }.onFailure { AppModel.say(it.message ?: "Ошибка") } }
            }) { Text("Сохранить") } },
            dismissButton = { TextButton({ pwDialog = false }) { Text("Отмена") } })
    }
    if (delAcc) AlertDialog(onDismissRequest = { delAcc = false }, title = { Text("Удалить аккаунт навсегда?") },
        text = { Text("Профиль, переписки и файлы будут удалены. Это нельзя отменить.") },
        confirmButton = { TextButton({ delAcc = false; scope.launch { runCatching { AppModel.deleteAccount() }.onFailure { AppModel.say(it.message ?: "Ошибка") } } }) { Text("Удалить", color = p.danger) } },
        dismissButton = { TextButton({ delAcc = false }) { Text("Отмена") } })
}

@Composable
fun EditUsernameScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var u by remember { mutableStateOf(AppModel.me?.username ?: "") }
    var busy by remember { mutableStateOf(false) }
    val ok = Regex("^[a-z0-9_]{3,32}$").matches(u.lowercase())
    Column(Modifier.fillMaxSize().background(p.bg).imePadding()) {
        TopBar("Имя пользователя", right = {
            Text("Готово", color = if (ok) p.a1 else p.muted, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.clickable(enabled = ok && !busy) {
                busy = true
                scope.launch { runCatching { AppModel.setUsername(u) }.onSuccess { AppModel.say("Сохранено"); AppModel.pop() }.onFailure { AppModel.say(it.message ?: "Ошибка") }; busy = false }
            }.padding(12.dp))
        })
        GroupCard {
            Row(Modifier.padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("@", color = p.muted, fontSize = 17.sp)
                Box(Modifier.weight(1f)) { PlainField(u, { u = it.trim().removePrefix("@").take(32) }, "username") }
            }
        }
        HintWithLink("Латинские буквы, цифры и _, от 3 до 32 символов. По этому имени вас смогут найти в Lumo.\nСсылка: " + ru.volshebnymir.lumo.core.Config.SITE + "#@" + u)
    }
}

@Composable
fun EditColorScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    val me = AppModel.me
    var c by remember { mutableIntStateOf(me?.color ?: 0) }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState())) {
        TopBar("Персональные цвета", right = {
            Text("Готово", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.clickable {
                scope.launch { AppModel.setColor(c); AppModel.say("Цвет сохранён"); AppModel.pop() }
            }.padding(12.dp))
        })
        // как вас видят другие: аватар и имя в группах
        GroupCard {
            Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                Avatar(me?.name ?: "", null, c, 56.dp)
                Spacer(Modifier.width(14.dp))
                Column(Modifier.clip(RoundedCornerShape(16.dp)).background(p.bubble).padding(horizontal = 12.dp, vertical = 8.dp)) {
                    Text(me?.name ?: "", color = p.nameColor(c), fontWeight = FontWeight.Bold, fontSize = 14.sp)
                    Text("Так ваше имя выглядит в группах", color = p.text, fontSize = 15.sp)
                }
            }
        }
        HintWithLink("Цвет используется для кружка с инициалами и вашего имени в группах.")
        GroupCard {
            Row(Modifier.fillMaxWidth().padding(18.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                (0 until 8).forEach { i ->
                    Box(Modifier.size(36.dp).clip(CircleShape).background(p.avatar(i)).border(3.dp, if (c == i) p.text else Color.Transparent, CircleShape).bouncy { c = i },
                        contentAlignment = Alignment.Center) { if (c == i) Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(18.dp)) }
                }
            }
        }
    }
}

@Composable
fun AppearanceScreen() {
    val p = P
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        TopBar("Оформление")
        Card {
            Text("Тема", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.padding(top = 10.dp))
            Row(Modifier.padding(vertical = 10.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf("dark" to "Тёмная", "light" to "Светлая", "system" to "Как в системе").forEach { (k, t) -> Pill(t, Look.theme == k) { Look.theme = k; Look.save() } }
            }
        }
        var icoDlg by remember { mutableStateOf(false) }
        if (icoDlg) AppIconDialog { icoDlg = false }
        Card {
            SettingsRow(Icons.Filled.Apps, Color(0xFF5B6CFF), "Иконка приложения", "Шесть оформлений, часть — с премиум-значком") { icoDlg = true }
        }
        Card {
            Text("Цвет", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.padding(top = 10.dp))
            Look.accents.withIndex().toList().chunked(6).forEach { row ->
                Row(Modifier.padding(vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { (i, ab) ->
                        Box(Modifier.size(40.dp).clip(CircleShape).background(Brush.linearGradient(listOf(Color(ab.first), Color(ab.second))))
                            .border(3.dp, if (Look.accent == i) p.text else Color.Transparent, CircleShape)
                            .bouncy { if (i >= 6 && !AppModel.isPremium) AppModel.say(ru.volshebnymir.lumo.core.PREMIUM_SOON) else { Look.accent = i; Look.save() } })
                    }
                }
            }
            Text("Нижний ряд — эксклюзивные цвета Premium", color = p.muted, fontSize = 12.sp, modifier = Modifier.padding(bottom = 10.dp))
        }
        Card {
            Text("Фон чатов", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.padding(top = 10.dp))
            Row(Modifier.padding(vertical = 12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Extra.WALLS.forEachIndexed { i, w ->
                    Box(Modifier.size(width = 52.dp, height = 70.dp).clip(RoundedCornerShape(12.dp))
                        .background(if (w == null) Brush.linearGradient(listOf(p.chatBg, p.chatBg)) else Brush.verticalGradient(listOf(Color(w.first), Color(w.second))))
                        .border(3.dp, if (Extra.wall == i) p.text else Color.Transparent, RoundedCornerShape(12.dp))
                        .bouncy { if (i > 0 && !AppModel.isPremium) AppModel.say(ru.volshebnymir.lumo.core.PREMIUM_SOON) else Extra.chooseWall(i) })
                }
            }
        }
        Card {
            Text("Размер текста: ${Look.fontSize.toInt()}", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.padding(top = 10.dp))
            Slider(Look.fontSize, { Look.fontSize = it }, valueRange = 13f..22f, steps = 8, onValueChangeFinished = { Look.save() },
                colors = SliderDefaults.colors(thumbColor = p.a1, activeTrackColor = p.a1))
            Box(Modifier.padding(bottom = 12.dp).clip(RoundedCornerShape(18.dp)).background(p.out).padding(horizontal = 12.dp, vertical = 8.dp)) {
                Text("Так выглядит текст сообщения", color = Color.White, fontSize = Look.fontSize.sp)
            }
        }
    }
}

@Composable
fun AboutScreen() {
    val p = P
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
        TopBar("О Lumo")
        Spacer(Modifier.height(20.dp))
        Box(Modifier.size(96.dp).clip(RoundedCornerShape(28.dp)).background(p.accent), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.ChatBubble, null, tint = Color.White, modifier = Modifier.size(50.dp))
        }
        Spacer(Modifier.height(14.dp))
        Text("Lumo", color = p.text, fontWeight = FontWeight.Black, fontSize = 30.sp)
        Spacer(Modifier.height(6.dp))
        BetaBadge()
        Spacer(Modifier.height(8.dp))
        Text("Бета-версия 1.6 для Android", color = p.muted, fontSize = 15.sp)
        Spacer(Modifier.height(20.dp))
        Card {
            Text("Это бета-версия: что-то может работать не идеально. В этой версии — чаты, группы, каналы, фото, видео, файлы, голосовые, видеокружки (просмотр), реакции, ответы, пересылка и уведомления.",
                color = p.text, fontSize = 15.sp, modifier = Modifier.padding(vertical = 12.dp))
        }
    }
}

// ---------------- новый чат ----------------

@Composable
fun NewChatScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var q by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<SearchResult>>(emptyList()) }
    var creating by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(q) { results = if (q.trim().length >= 2) { kotlinx.coroutines.delay(250); AppModel.search(q.trim().removePrefix("@")).filter { it.kind == "user" } } else emptyList() }
    Column(Modifier.fillMaxSize().background(p.bg).imePadding()) {
        TopBar("Новый чат")
        SearchBox(q, { q = it }, Modifier.padding(horizontal = 14.dp).fillMaxWidth())
        Spacer(Modifier.height(8.dp))
        LazyColumn(Modifier.fillMaxSize()) {
            if (q.isBlank()) {
                item {
                    Card {
                        SettingsRow(Icons.Filled.Groups, Color(0xFF3A7BFF), "Создать группу") { creating = "group" }
                        Divider()
                        SettingsRow(Icons.Filled.Campaign, Color(0xFFFF8A3D), "Создать канал") { creating = "channel" }
                        Divider()
                        SettingsRow(Icons.Filled.SmartToy, Color(0xFF7C5CFF), "Создать бота", "Конструктор ботов и мини-приложений") { scope.launch { AppModel.openBotFather() } }
                    }
                    Spacer(Modifier.height(10.dp))
                }
                items(AppModel.contacts.toList(), key = { it }) { id ->
                    val pr = AppModel.profiles[id]
                    Row(Modifier.fillMaxWidth().clickable { scope.launch { AppModel.openDM(id) } }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Avatar(AppModel.displayName(id), pr?.avatarUrl, pr?.color ?: 0, 46.dp, online = AppModel.isOnline(id))
                        Spacer(Modifier.width(12.dp))
                        Text(AppModel.displayName(id), color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    }
                }
            } else items(results, key = { it.id }) { r ->
                Row(Modifier.fillMaxWidth().clickable { scope.launch { AppModel.openDM(r.id) } }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(r.name, r.avatarUrl, r.color, 46.dp)
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(r.name, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                        Text("@" + (r.username ?: ""), color = p.muted, fontSize = 13.sp)
                    }
                }
            }
        }
    }
    creating?.let { type ->
        var title by remember { mutableStateOf("") }
        val picked = remember { mutableStateListOf<String>() }
        AlertDialog(onDismissRequest = { creating = null },
            title = { Text(if (type == "group") "Новая группа" else "Новый канал") },
            text = {
                Column(Modifier.heightIn(max = 400.dp).verticalScroll(rememberScrollState())) {
                    LumoField(title, { title = it }, "Название")
                    if (type == "group") {
                        Spacer(Modifier.height(10.dp))
                        Text("Участники из контактов", color = p.muted, fontSize = 13.sp)
                        AppModel.contacts.forEach { id ->
                            val on = id in picked
                            Row(Modifier.fillMaxWidth().clickable { if (on) picked.remove(id) else picked.add(id) }.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                                Icon(if (on) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null, tint = if (on) p.a1 else p.muted)
                                Spacer(Modifier.width(8.dp))
                                Text(AppModel.displayName(id), color = p.text)
                            }
                        }
                    }
                }
            },
            confirmButton = { TextButton({
                val t = title.trim(); if (t.isEmpty()) return@TextButton
                creating = null
                scope.launch { AppModel.createChat(type, t, "", picked.toList()) }
            }) { Text("Создать") } },
            dismissButton = { TextButton({ creating = null }) { Text("Отмена") } })
    }
}
