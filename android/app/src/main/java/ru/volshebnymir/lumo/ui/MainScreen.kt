package ru.volshebnymir.lumo.ui

import android.content.Intent
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.runtime.SideEffect
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MarkChatRead
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import ru.volshebnymir.lumo.core.Message
import ru.volshebnymir.lumo.core.PhoneStore
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Done
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.EmojiEmotions
import androidx.compose.material.icons.filled.SlowMotionVideo
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.ChatItem
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.Screen
import ru.volshebnymir.lumo.core.SearchResult
import ru.volshebnymir.lumo.core.Tab

@Composable
fun Root() {
    val p = P
    Box(Modifier.fillMaxSize().background(p.bg)) {
        val prefs = remember { AppModel.ctx.getSharedPreferences("lumo_prefs", android.content.Context.MODE_PRIVATE) }
        var permsDone by remember { mutableStateOf(prefs.getBoolean("lm_perms_done", false)) }
        if (!permsDone) PermissionsScreen { prefs.edit().putBoolean("lm_perms_done", true).apply(); permsDone = true }
        else if (AppModel.loggedIn) MainScreen() else LoginScreen()
        if (permsDone && AppModel.loggedIn && AppModel.demoId == null) {
            if (PhoneStore.loaded && PhoneStore.status == "required") PhoneAuthScreen(bind = true, required = true) {}
            else if (PhoneUi.bind) PhoneAuthScreen(bind = true) { PhoneUi.bind = false }
            else if (PhoneStore.loaded && !PhoneStore.reminderShown && (PhoneStore.status == "remind" || PhoneStore.status == "skipped")) PhoneReminderDialog()
        }
        if (AppModel.loggedIn) { Ui.Overlays(); if (AppModel.demoId == null) FullScreenPrompt(); E2EDialogs() }
        CallsUi.Overlay()
        if (AppModel.loggedIn) LockOverlay()
        AnimatedVisibility(AppModel.toast != null, Modifier.align(Alignment.BottomCenter).padding(bottom = 110.dp, start = 24.dp, end = 24.dp),
            enter = fadeIn() + slideInVertically { it / 2 }, exit = fadeOut()) {
            Box(Modifier.clip(RoundedCornerShape(22.dp)).background(Color(0xEE1D1F3D)).padding(horizontal = 16.dp, vertical = 11.dp)) {
                Text(AppModel.toast ?: "", color = Color.White, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
            }
        }
    }
}

@Composable
fun MainScreen() {
    val p = P
    LaunchedEffect(Unit) { AppModel.start() }
    BackHandler(AppModel.stack.isNotEmpty()) { AppModel.pop() }
    val top = AppModel.stack.lastOrNull()
    AnimatedContent(top, transitionSpec = {
        val forward = (targetState != null && initialState == null) || AppModel.stack.size > 0 && targetState != null && initialState != null && AppModel.stack.contains(initialState!!)
        if (forward) slideInHorizontally(tween(260)) { it } togetherWith slideOutHorizontally(tween(260)) { -it / 4 } + fadeOut(tween(260))
        else slideInHorizontally(tween(260)) { -it / 4 } + fadeIn() togetherWith slideOutHorizontally(tween(260)) { it }
    }, label = "nav") { s ->
        when (s) {
            null -> Tabs()
            is Screen.Chat -> ChatScreen(s.id)
            is Screen.Info -> InfoScreen(s.chatId)
            is Screen.Person -> PersonScreen(s.userId)
            Screen.MyProfile -> MyProfileScreen()
            Screen.EditProfile -> EditProfileScreen()
            Screen.Appearance -> AppearanceScreen()
            Screen.About -> AboutScreen()
            Screen.NewChat -> NewChatScreen()
            Screen.CallsHistory -> CallsHistoryScreen()
            Screen.Notifications -> NotificationsScreen()
            Screen.Privacy -> PrivacyScreen()
            Screen.Blocked -> BlockedScreen()
            is Screen.ChatSearch -> ChatSearchScreen(s.chatId)
            is Screen.PrivacyKey -> PrivacyKeyScreen(s.key)
            Screen.EditUsername -> EditUsernameScreen()
            Screen.EditColor -> EditColorScreen()
            Screen.Premium -> PremiumScreen()
            Screen.MsgPrivacy -> MsgPrivacyScreen()
            Screen.Devices -> DevicesScreen()
            Screen.Language -> LanguageScreen()
            Screen.Phone -> PhoneSettingsScreen()
            is Screen.EditChat -> EditChatScreen(s.chatId)
            Screen.TwoFa -> TwoFaScreen()
        }
    }
}

@Composable
fun Tabs() {
    val p = P
    Box(Modifier.fillMaxSize().background(p.bg)) {
        AnimatedContent(AppModel.tab, transitionSpec = {
            (fadeIn(tween(320)) + androidx.compose.animation.scaleIn(tween(320), initialScale = 0.985f)) togetherWith fadeOut(tween(220))
        }, label = "tabs") { t ->
            when (t) {
                Tab.Chats -> ChatListScreen()
                Tab.Contacts -> ContactsScreen()
                Tab.Settings -> SettingsScreen()
            }
        }
        TabBar(Modifier.align(Alignment.BottomCenter))
    }
}

@Composable
fun TabBar(modifier: Modifier) {
    val p = P
    // внешний слой съедает все касания по области панели, чтобы нажатие между кнопками не попадало в чат под ней
    Box(modifier.fillMaxWidth().pointerInput(Unit) { detectTapGestures { } }) {
        Row(
            Modifier.navigationBarsPadding().padding(horizontal = 12.dp, vertical = 6.dp).fillMaxWidth()
                .clip(RoundedCornerShape(36.dp)).background(p.panel.copy(alpha = 0.96f)).padding(6.dp),
            horizontalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            TabItem(Tab.Contacts, Icons.Filled.AccountCircle, "Контакты", 0)
            TabItem(Tab.Chats, Icons.Filled.ChatBubble, "Чаты", AppModel.unreadTotal)
            TabItem(Tab.Settings, Icons.Filled.Settings, "Настройки", 0)
        }
    }
}

@Composable
fun androidx.compose.foundation.layout.RowScope.TabItem(t: Tab, icon: ImageVector, label: String, badge: Int) {
    val p = P
    val on = AppModel.tab == t
    val scope = rememberCoroutineScope()
    val pop = remember { Animatable(1f) }
    val rot = remember { Animatable(0f) }
    val dy = remember { Animatable(0f) }
    Box(
        Modifier.weight(1f).clip(RoundedCornerShape(30.dp)).background(if (on) p.a1.copy(alpha = 0.16f) else Color.Transparent)
            .clickable {
                AppModel.tab = t
                scope.launch { pop.animateTo(1.1f, tween(200)); pop.animateTo(1f, spring(0.85f, Spring.StiffnessLow)) }
                when (t) {
                    Tab.Settings -> scope.launch { rot.animateTo(rot.value + 120f, spring(0.85f, Spring.StiffnessVeryLow)) }
                    Tab.Chats -> scope.launch { for (a in listOf(-7f, 6f, 0f)) rot.animateTo(a, tween(200)) }
                    Tab.Contacts -> scope.launch { dy.animateTo(-3f, tween(200)); dy.animateTo(0f, spring(0.85f, Spring.StiffnessLow)) }
                }
            }
            .padding(vertical = 7.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(icon, null, tint = if (on) p.a1 else p.text, modifier = Modifier.size(25.dp).offset(y = dy.value.dp).scale(pop.value).rotate(rot.value))
            Text(label, fontSize = 11.5.sp, fontWeight = FontWeight.Bold, color = if (on) p.a1 else p.text)
        }
        if (badge > 0) Box(Modifier.align(Alignment.TopCenter).offset(x = 18.dp).clip(CircleShape).background(p.danger).padding(horizontal = 6.dp, vertical = 1.dp)) {
            Text(if (badge > 99) "99+" else "$badge", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Black)
        }
    }
}

@Composable
fun SearchBox(q: String, onQ: (String) -> Unit, modifier: Modifier = Modifier) {
    val p = P
    Row(modifier.clip(RoundedCornerShape(24.dp)).background(p.panel2).padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.Search, null, tint = p.muted, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Box(Modifier.weight(1f)) {
            if (q.isEmpty()) Text("Поиск", color = p.muted, fontSize = 16.sp)
            BasicTextField(q, onQ, singleLine = true, textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
fun NetStatusBar() {
    val p = P
    AnimatedVisibility(AppModel.netStatus != null) {
        Row(Modifier.fillMaxWidth().height(32.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            CircularProgressIndicator(Modifier.size(14.dp), color = p.muted, strokeWidth = 2.dp)
            Spacer(Modifier.width(8.dp))
            Text(AppModel.netStatus ?: "", color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
        }
    }
}

// ---------------- список чатов ----------------

@Composable
fun ChatListScreen() {
    val p = P
    var q by remember { mutableStateOf("") }
    var folder by remember { mutableStateOf("all") }
    val results = remember { mutableStateListOf<SearchResult>() }
    LaunchedEffect(q) {
        results.clear()
        if (q.trim().length >= 2) { delay(250); results.addAll(AppModel.search(q.trim().removePrefix("@"))) }
    }
    Column(Modifier.fillMaxSize().statusBarsPadding()) {
        NetStatusBar()
        Row(Modifier.padding(start = 18.dp, end = 14.dp, top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Lumo", fontWeight = FontWeight.Black, fontSize = 30.sp, style = TextStyle(brush = p.accent), modifier = Modifier.weight(1f))
            Box(Modifier.size(44.dp).clip(RoundedCornerShape(16.dp)).background(p.panel2).bouncy { Ui.qrMine = true }, contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.QrCodeScanner, null, tint = p.text, modifier = Modifier.size(22.dp))
            }
            Spacer(Modifier.width(8.dp))
            Box(Modifier.size(44.dp).clip(RoundedCornerShape(16.dp)).background(p.panel2).bouncy { AppModel.push(Screen.NewChat) }, contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.EditNote, null, tint = p.text)
            }
        }
        SearchBox(q, { q = it }, Modifier.padding(horizontal = 14.dp, vertical = 8.dp).fillMaxWidth())
        if (q.isBlank()) {
            val unreadOf = { f: (ChatItem) -> Boolean -> AppModel.chats.count { it.unread > 0 && !it.muted && f(it) } }
            Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 14.dp, vertical = 2.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                for ((k, t) in listOf("all" to "Все", "private" to "Чаты", "group" to "Группы", "channel" to "Каналы", "unread" to "Непрочитанные")) {
                    val n = when (k) { "private" -> unreadOf { it.isPrivate }; "group" -> unreadOf { it.type == "group" }; "channel" -> unreadOf { it.isChannel }; "unread" -> unreadOf { true }; else -> 0 }
                    Pill(if (n > 0) "$t  $n" else t, folder == k) { folder = k }
                }
            }
            val list = AppModel.chats.filter {
                when (folder) { "private" -> it.isPrivate; "group" -> it.type == "group"; "channel" -> it.isChannel; "unread" -> it.unread > 0; else -> true }
            }
            if (!AppModel.chatsLoaded) Box(Modifier.fillMaxWidth().padding(40.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = p.a1) }
            LazyColumn(Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 110.dp)) {
                if (folder == "all") item(key = "stories") { StoriesBar() }
                items(list, key = { it.id }) { c -> ChatRow(c, Modifier.animateItem()) }
                if (AppModel.chatsLoaded && list.isEmpty()) item {
                    Text(if (folder == "all") "Пока нет чатов.\nНайдите людей через поиск или нажмите карандаш" else "Здесь пусто",
                        color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp))
                }
            }
        } else {
            LazyColumn(Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 110.dp)) {
                val local = AppModel.chats.filter { it.displayName.contains(q.trim(), ignoreCase = true) }
                items(local, key = { "l" + it.id }) { ChatRow(it) }
                items(results.filter { r -> local.none { it.peerId == r.id || it.id == r.id } }, key = { "r" + it.id }) { r -> ResultRow(r) }
            }
        }
    }
}

@Composable
fun ResultRow(r: SearchResult) {
    val p = P
    val scope = rememberCoroutineScope()
    Row(Modifier.fillMaxWidth().clickable {
        scope.launch { if (r.kind == "user") AppModel.openDM(r.id) else if (AppModel.chat(r.id) != null) AppModel.open(r.id) else AppModel.join(r.id) }
    }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        Avatar(r.name, r.avatarUrl, r.color, 52.dp)
        Spacer(Modifier.width(12.dp))
        Column {
            Text(r.name, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Text((r.username?.let { "@$it" } ?: "") + (if (r.kind == "group") " · группа" else if (r.kind == "channel") " · канал" else ""), color = p.muted, fontSize = 14.sp)
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChatRow(c: ChatItem, modifier: Modifier = Modifier) {
    val p = P
    val scope = rememberCoroutineScope()
    var menu by remember { mutableStateOf(false) }
    val saved = c.isPrivate && c.peerId == AppModel.myId
    Box(modifier) {
        Row(
            Modifier.fillMaxWidth().combinedClickable(onClick = { AppModel.push(Screen.Chat(c.id)) }, onLongClick = { menu = true })
                .padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (saved) Box(Modifier.size(56.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) { Icon(Icons.Filled.Bookmark, null, tint = Color.White) }
            else Avatar(c.displayName, c.displayAvatar, c.displayColor, 56.dp, online = c.isPrivate && AppModel.isOnline(c.peerId))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (c.type == "group") Icon(Icons.Filled.Groups, null, tint = p.muted, modifier = Modifier.size(16.dp).padding(end = 3.dp))
                    if (c.isChannel) Icon(Icons.Filled.Campaign, null, tint = p.muted, modifier = Modifier.size(16.dp).padding(end = 3.dp))
                    Text(if (saved) "Избранное" else c.displayName, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.5.sp, maxLines = 1,
                        overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                    if (c.isPrivate && !saved) PeerBadges(c)
                    if (c.muted) Icon(Icons.Filled.NotificationsOff, null, tint = p.muted, modifier = Modifier.size(15.dp).padding(start = 3.dp))
                    Spacer(Modifier.weight(1f))
                    val mine = c.lastSender == AppModel.myId && c.lastKind != "system" && !saved && !c.isChannel
                    if (mine) {
                        val read = c.othersReadAt != null && c.lastAt != null && !c.othersReadAt.before(c.lastAt)
                        Icon(if (read) Icons.Filled.DoneAll else Icons.Filled.Done, null, tint = p.a2, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(3.dp))
                    }
                    Text(Fmt.listTime(c.lastAt), color = p.muted, fontSize = 12.5.sp)
                }
                Spacer(Modifier.height(2.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val t = AppModel.typingText(c.id)
                    if (t != null) Text(t, color = p.a2, fontWeight = FontWeight.SemiBold, fontSize = 14.5.sp, maxLines = 1, modifier = Modifier.weight(1f))
                    else {
                        kindIcon(c.lastKind)?.takeIf { c.lastId != null && !c.lastDeleted }?.let { Icon(it, null, tint = p.muted, modifier = Modifier.size(16.dp).padding(end = 4.dp)) }
                        Text(c.preview(AppModel.myId), color = p.muted, fontSize = 14.5.sp, maxLines = 2, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                    }
                    if (c.unread > 0) Box(Modifier.clip(CircleShape).background(if (c.muted) SolidColor(p.muted) else p.accent).padding(horizontal = 7.dp, vertical = 2.dp)) {
                        Text(if (c.unread > 99) "99+" else "${c.unread}", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Black)
                    } else if (c.pinned) Icon(Icons.Filled.PushPin, null, tint = p.muted, modifier = Modifier.size(16.dp))
                }
            }
        }
        if (menu) ChatPreviewMenu(c) { menu = false }
    }
}

/** Меню по долгому нажатию на чат: превью последних сообщений и действия под ним */
@Composable
fun ChatPreviewMenu(c: ChatItem, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    LaunchedEffect(c.id) { AppModel.loadMessages(c.id) }
    val msgs = (AppModel.messages[c.id] ?: emptyList()).filter { !it.deleted && it.kind != "system" }.takeLast(6)
    androidx.compose.ui.window.Dialog(onDismissRequest = onClose, properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)) {
        val w = (androidx.compose.ui.platform.LocalView.current.parent as? androidx.compose.ui.window.DialogWindowProvider)?.window
        SideEffect {
            try {
                w?.setDimAmount(0.25f)
                if (android.os.Build.VERSION.SDK_INT >= 31 && w != null) {
                    w.addFlags(android.view.WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
                    val lp = w.attributes; lp.blurBehindRadius = 40; w.attributes = lp
                }
            } catch (_: Throwable) {}
        }
        Box(Modifier.fillMaxSize().clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) { onClose() }.padding(horizontal = 16.dp), contentAlignment = Alignment.Center) {
            Column(Modifier.statusBarsPadding().navigationBarsPadding(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Column(Modifier.fillMaxWidth().heightIn(max = 430.dp).clip(RoundedCornerShape(30.dp)).background(p.chatBg).padding(12.dp)) {
                    Column(Modifier.align(Alignment.CenterHorizontally).clip(RoundedCornerShape(22.dp)).background(p.panel.copy(alpha = 0.9f)).padding(horizontal = 22.dp, vertical = 6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(c.displayName, color = p.text, fontWeight = FontWeight.Black, fontSize = 17.sp, maxLines = 1)
                        Text(if (c.isPrivate) (if (c.peerBot) "бот" else AppModel.lastSeenText(c.peerId, c.peerLastSeen)) else plural(c.membersCount, "участник", "участника", "участников"), color = p.muted, fontSize = 12.sp)
                    }
                    Spacer(Modifier.height(10.dp))
                    Column(Modifier.weight(1f, fill = false), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                        msgs.forEach { m ->
                            val mine = m.senderId == AppModel.myId
                            Box(Modifier.fillMaxWidth(), contentAlignment = if (mine) Alignment.CenterEnd else Alignment.CenterStart) {
                                Text(if (m.body.isNullOrEmpty()) Message.previewText(m.kind, m.body) else m.body!!.take(160), color = if (mine) Color.White else p.text, fontSize = 15.sp, maxLines = 4, overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.widthIn(max = 280.dp).clip(RoundedCornerShape(18.dp)).background(if (mine) p.accent else SolidColor(p.bubble)).padding(horizontal = 12.dp, vertical = 7.dp))
                            }
                        }
                    }
                }
                Column(Modifier.width(270.dp).align(Alignment.End).clip(RoundedCornerShape(26.dp)).background(p.panel2.copy(alpha = 0.97f)).padding(6.dp)) {
                    @Composable fun row(icon: ImageVector, t: String, danger: Boolean = false, f: () -> Unit) {
                        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).clickable { onClose(); f() }.padding(horizontal = 14.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(icon, null, tint = if (danger) p.danger else p.text, modifier = Modifier.size(22.dp))
                            Spacer(Modifier.width(14.dp))
                            Text(t, color = if (danger) p.danger else p.text, fontSize = 16.sp)
                        }
                    }
                    if (c.unread > 0) row(Icons.Filled.MarkChatRead, "Прочитано") { scope.launch { AppModel.loadMessages(c.id); AppModel.markRead(c.id) } }
                    row(Icons.Filled.PushPin, if (c.pinned) "Открепить" else "Закрепить") { scope.launch { AppModel.setPinned(c.id, !c.pinned) } }
                    row(if (c.muted) Icons.Filled.Notifications else Icons.Filled.NotificationsOff, if (c.muted) "Включить уведомления" else "Выключить уведомления") { scope.launch { AppModel.setMuted(c.id, !c.muted) } }
                    if (!c.isPrivate) row(Icons.AutoMirrored.Filled.ExitToApp, if (c.isChannel) "Отписаться" else "Покинуть группу", danger = true) { scope.launch { AppModel.leave(c.id) } }
                    else row(Icons.Filled.Delete, "Очистить историю", danger = true) { scope.launch { AppModel.clearChat(c.id) } }
                }
            }
        }
    }
}

fun kindIcon(kind: String?): ImageVector? = when (kind) {
    "voice" -> Icons.Filled.Mic
    "video_note" -> Icons.Filled.SlowMotionVideo
    "image" -> Icons.Filled.Photo
    "video" -> Icons.Filled.Videocam
    "file" -> Icons.Filled.Description
    "sticker" -> Icons.Filled.EmojiEmotions
    "call" -> Icons.Filled.Call
    else -> null
}

// ---------------- контакты ----------------

@Composable
fun ContactsScreen() {
    val p = P
    var q by remember { mutableStateOf("") }
    val results = remember { mutableStateListOf<SearchResult>() }
    LaunchedEffect(q) {
        results.clear()
        if (q.trim().length >= 2) { delay(250); results.addAll(AppModel.search(q.trim().removePrefix("@")).filter { it.kind == "user" }) }
    }
    Column(Modifier.fillMaxSize().statusBarsPadding()) {
        Text("Контакты", color = p.text, fontWeight = FontWeight.Black, fontSize = 28.sp, modifier = Modifier.padding(horizontal = 18.dp, vertical = 8.dp))
        SearchBox(q, { q = it }, Modifier.padding(horizontal = 14.dp).fillMaxWidth())
        LazyColumn(Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(top = 8.dp, bottom = 110.dp)) {
            if (q.isBlank()) item {
                val ctx = LocalContext.current
                Row(Modifier.fillMaxWidth().clickable {
                    runCatching { ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, "Я в Lumo — напиши мне: " + AppModel.profileLink), "Поделиться").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(50.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) { Icon(Icons.Filled.PersonAdd, null, tint = Color.White) }
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text("Пригласить друзей", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text("Поделиться ссылкой на мой профиль", color = p.muted, fontSize = 13.5.sp)
                    }
                }
            }
            if (q.isBlank()) {
                val list = AppModel.contacts.mapNotNull { AppModel.profiles[it] }.sortedWith(compareByDescending<ru.volshebnymir.lumo.core.Profile> { AppModel.isOnline(it.id) }.thenBy { AppModel.displayName(it.id) })
                if (list.isEmpty()) item { Text("Контактов пока нет. Найдите человека через поиск и добавьте его.", color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp)) }
                item { PhoneContactsSection() }
                items(list, key = { it.id }) { pr ->
                    Row(Modifier.fillMaxWidth().clickable { AppModel.push(Screen.Person(pr.id)) }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Avatar(AppModel.displayName(pr.id), pr.avatarUrl, pr.color, 50.dp, online = AppModel.isOnline(pr.id))
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text(AppModel.displayName(pr.id), color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                            Text(AppModel.lastSeenText(pr.id), color = if (AppModel.isOnline(pr.id)) p.a2 else p.muted, fontSize = 13.5.sp)
                        }
                    }
                }
            } else items(results, key = { it.id }) { r ->
                Row(Modifier.fillMaxWidth().clickable { AppModel.push(Screen.Person(r.id)) }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(r.name, r.avatarUrl, r.color, 50.dp)
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(r.name, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text("@" + (r.username ?: ""), color = p.muted, fontSize = 13.5.sp)
                    }
                }
            }
        }
    }
}

// ---------------- настройки ----------------

