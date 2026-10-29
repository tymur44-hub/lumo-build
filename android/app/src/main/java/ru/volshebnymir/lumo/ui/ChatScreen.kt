package ru.volshebnymir.lumo.ui

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.togetherWith
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Reply
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.foundation.border
import androidx.compose.material.icons.automirrored.filled.Forward
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.Lumens
import ru.volshebnymir.lumo.core.ChatItem
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.Message
import ru.volshebnymir.lumo.core.Screen
import ru.volshebnymir.lumo.core.jsonOf
import ru.volshebnymir.lumo.core.premium
import ru.volshebnymir.lumo.core.scheduleMessage
import java.util.Date
import kotlin.math.roundToInt

private sealed class Row2 {
    abstract val key: String
    data class Msg(val m: Message, val first: Boolean, val last: Boolean) : Row2() { override val key get() = "m" + m.id }
    data class Day(val d: Date) : Row2() { override val key get() = "d" + d.time }
}

val QUICK = listOf("👍", "❤️", "😂", "😮", "😢", "🔥", "🙏", "👏")

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChatScreen(chatId: String) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val chat = AppModel.chat(chatId)
    val msgs = AppModel.messages[chatId] ?: emptyList()
    var text by rememberSaveable(chatId) { mutableStateOf("") }
    var reply by remember { mutableStateOf<Message?>(null) }
    var editing by remember { mutableStateOf<Message?>(null) }
    var menuFor by remember { mutableStateOf<Message?>(null) }
    var showScheduled by remember { mutableStateOf(false) }
    var viewer by remember { mutableStateOf<Message?>(null) }
    var forwarding by remember { mutableStateOf<List<Message>?>(null) }
    var deleting by remember { mutableStateOf<List<Message>?>(null) }
    val selected = remember { mutableStateListOf<Int>() }
    val prot = ru.volshebnymir.lumo.core.Prot.map[chatId] == true
    LaunchedEffect(chatId) { ru.volshebnymir.lumo.core.Prot.load(chatId) }
    DisposableEffect(prot) {
        var ac: android.content.Context? = ctx
        while (ac is android.content.ContextWrapper && ac !is android.app.Activity) ac = ac.baseContext
        val w = (ac as? android.app.Activity)?.window
        if (prot) w?.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
        onDispose { w?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE) }
    }
    val list = rememberLazyListState()
    var loaded by remember { mutableStateOf(msgs.isNotEmpty()) }
    var flash by remember { mutableStateOf<Int?>(null) }
    var note by remember { mutableStateOf<NoteSession?>(null) }
    var reportMsg by remember { mutableStateOf<Message?>(null) }
    var tipMsg by remember { mutableStateOf<Message?>(null) }
    val notePerm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r ->
        if (r.values.all { it }) note = NoteSession(true) else AppModel.say("Нужен доступ к камере и микрофону")
    }

    LaunchedEffect(chatId) {
        if (ru.volshebnymir.lumo.core.Demo.openMenu) { ru.volshebnymir.lumo.core.Demo.openMenu = false; delay(600); menuFor = AppModel.messages[chatId]?.firstOrNull { it.id == 2 } }
        AppModel.openChatId = chatId
        AppModel.loadMessages(chatId); loaded = true
        AppModel.markRead(chatId)
    }
    DisposableEffect(chatId) { onDispose { if (AppModel.openChatId == chatId) AppModel.openChatId = null; Voice.stop() } }

    val rows = remember(msgs) {
        val msgs = msgs.distinctBy { it.id }.filter { !it.deleted }
        val out = mutableListOf<Row2>()
        for (i in msgs.indices.reversed()) {
            val m = msgs[i]
            val prev = msgs.getOrNull(i - 1); val next = msgs.getOrNull(i + 1)
            val first = prev == null || prev.senderId != m.senderId || prev.kind == "system" || !Fmt.isSameDay(prev.createdAt, m.createdAt)
            val last = next == null || next.senderId != m.senderId || next.kind == "system" || !Fmt.isSameDay(next.createdAt, m.createdAt)
            out.add(Row2.Msg(m, first, last))
            if (prev == null || !Fmt.isSameDay(prev.createdAt, m.createdAt)) out.add(Row2.Day(m.createdAt))
        }
        out
    }

    // новое сообщение: прочитать и прокрутить вниз, если мы внизу
    val newest = msgs.lastOrNull()?.id
    LaunchedEffect(newest) {
        AppModel.markRead(chatId)
        if (list.firstVisibleItemIndex <= 2 || msgs.lastOrNull()?.senderId == AppModel.myId) list.animateScrollToItem(0)
    }
    // подгрузка старых
    LaunchedEffect(list, rows.size) {
        snapshotFlow { list.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0 }.collect { last ->
            if (last >= rows.size - 4 && AppModel.hasMore[chatId] == true && loaded) {
                loaded = false; AppModel.loadMessages(chatId, older = true); loaded = true
            }
        }
    }

    LaunchedEffect(rows.size) {
        val j = AppModel.pendingJump ?: return@LaunchedEffect
        val i = rows.indexOfFirst { it is Row2.Msg && it.m.id == j }
        if (i >= 0) { AppModel.pendingJump = null; list.animateScrollToItem(i); flash = j; delay(1200); flash = null }
        else if (AppModel.hasMore[chatId] == true && loaded) { loaded = false; AppModel.loadMessages(chatId, older = true); loaded = true }
        else AppModel.pendingJump = null
    }
    fun scrollTo(id: Int) {
        val i = rows.indexOfFirst { it is Row2.Msg && it.m.id == id }
        if (i >= 0) scope.launch { list.animateScrollToItem(i); flash = id; delay(1200); flash = null } else AppModel.say("Сообщение далеко в истории")
    }

    val selecting = selected.isNotEmpty()
    BackHandler(selecting) { selected.clear() }

    Box(Modifier.fillMaxSize().background(p.chatBg)) {
        ChatWallBackground(chatId)
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(p.a1.copy(alpha = 0.07f), Color.Transparent, p.a2.copy(alpha = 0.06f)))))
        Column(Modifier.fillMaxSize().statusBarsPadding().imePadding()) {
            if (selecting) SelectHeader(selected.size, onClose = { selected.clear() },
                onCopy = {
                    if (prot) AppModel.say("В защищённом чате копирование запрещено") else {
                        val t = msgs.filter { it.id in selected }.joinToString("\n") { it.body ?: "" }.trim()
                        copy(ctx, t)
                    }
                    selected.clear()
                },
                onForward = { if (prot) { AppModel.say("В защищённом чате пересылка запрещена"); selected.clear() } else forwarding = msgs.filter { it.id in selected } },
                onDelete = { deleting = msgs.filter { it.id in selected }.takeIf { it.isNotEmpty() } },
            ) else ChatHeader(chatId, chat)
            NetStatusBar()
            PinnedBar(chat, chatId) { scrollTo(it) }
            Box(Modifier.weight(1f)) {
                LazyColumn(Modifier.fillMaxSize(), state = list, reverseLayout = true, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp)) {
                    items(rows, key = { it.key }) { r ->
                        when (r) {
                            is Row2.Day -> Box(Modifier.animateItem()) { DayChip(r.d) }
                            is Row2.Msg -> MessageRow(modifier = Modifier.animateItem(fadeInSpec = null),
                                m = r.m, chat = chat, first = r.first, last = r.last, selecting = selecting, isSelected = r.m.id in selected, flash = flash == r.m.id,
                                onTap = { m ->
                                    if (selecting) { if (m.id in selected) selected.remove(m.id) else if (m.id > 0) selected.add(m.id) }
                                    else if (m.kind == "image" || m.kind == "video") viewer = m
                                    else if (m.kind == "file") MediaUtil.open(ctx, m.mediaUrl)
                                },
                                onLong = { m -> if (selecting) { if (m.id > 0 && m.id !in selected) selected.add(m.id) } else if (m.kind != "system") menuFor = m },
                                onReply = { m -> if (chat?.canPost != false && m.id > 0) { reply = m; editing = null } },
                                onReplyTap = { scrollTo(it) },
                            )
                        }
                    }
                    if (!loaded && msgs.isEmpty()) item { Box(Modifier.fillMaxWidth().padding(40.dp), contentAlignment = Alignment.Center) { androidx.compose.material3.CircularProgressIndicator(color = p.a1) } }
                    if (loaded && msgs.isEmpty()) item {
                        Column(Modifier.fillMaxWidth().padding(50.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("👋", fontSize = 54.sp)
                            Text("Сообщений пока нет", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                            Text("Напишите что-нибудь!", color = p.muted, fontSize = 14.sp)
                        }
                    }
                }
                val showDown by remember { derivedStateOf { list.firstVisibleItemIndex > 3 } }
                androidx.compose.animation.AnimatedVisibility(showDown, Modifier.align(Alignment.BottomEnd).padding(14.dp), enter = scaleIn() + fadeIn(), exit = scaleOut() + fadeOut()) {
                    Box(Modifier.size(46.dp).clip(CircleShape).background(p.panel).bouncy { scope.launch { list.animateScrollToItem(0) } }, contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.KeyboardArrowDown, null, tint = p.text, modifier = Modifier.size(30.dp))
                    }
                }
            }
            val menuBot = if (chat?.isPrivate == true && peerBadges(chat).first) chat.peerId else null
            if (menuBot != null) {
                LaunchedEffect(menuBot) { AppModel.loadBotMenu(menuBot) }
                AppModel.botMenus[menuBot]?.let { mb ->
                    Row(Modifier.fillMaxWidth().background(p.panel).padding(start = 12.dp, end = 12.dp, top = 6.dp)) {
                        Row(Modifier.clip(RoundedCornerShape(14.dp)).background(p.a1.copy(alpha = 0.16f)).bouncy { AppModel.miniApp = ru.volshebnymir.lumo.core.MiniAppReq(menuBot) }
                            .padding(horizontal = 12.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Apps, null, tint = p.a1, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(6.dp))
                            Text(mb.first, color = p.a1, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        }
                    }
                }
            }
            val blockedText = if (chat?.isPrivate == true) AppModel.peerBlockText(chat.peerId) else null
            if (blockedText != null) {
                Text(blockedText, color = p.muted, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().background(p.panel).navigationBarsPadding().padding(16.dp))
            } else if (chat != null && chat.isPrivate && peerBadges(chat).first && loaded && msgs.none { it.senderId == AppModel.myId }) {
                Box(Modifier.fillMaxWidth().background(p.panel).navigationBarsPadding().padding(10.dp)) {
                    Text("НАЧАТЬ", color = Color.White, fontWeight = FontWeight.Black, fontSize = 16.sp, textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(p.accent)
                            .clickable { scope.launch { AppModel.send(chatId, "text", "/start") } }.padding(vertical = 14.dp))
                }
            } else if (chat != null && !chat.canPost) {
                Box(Modifier.fillMaxWidth().background(p.panel).navigationBarsPadding().padding(16.dp), contentAlignment = Alignment.Center) {
                    Text(if (chat.muted) "Включить уведомления" else "Выключить уведомления", color = p.a1, fontWeight = FontWeight.Bold,
                        modifier = Modifier.clickable { scope.launch { AppModel.setMuted(chatId, !chat.muted) } })
                }
            } else Composer(chatId, text, { text = it; if (it.isNotEmpty()) AppModel.userTyping(chatId) }, reply, editing,
                onCancel = { if (editing != null) text = ""; reply = null; editing = null },
                onSend = {
                    val t = text.trim()
                    if (t.isNotEmpty()) {
                        text = ""
                        val e = editing
                        if (e != null) { editing = null; if (t != e.body) scope.launch { AppModel.edit(e, t) } }
                        else { val r = reply?.id; reply = null; scope.launch { AppModel.send(chatId, "text", t, replyTo = r) } }
                    }
                },
                onSendMenu = { which ->
                    val t = text.trim()
                    when (which) {
                        2 -> showScheduled = true
                        else -> if (t.isNotEmpty()) run {
                            if (which == 0) { text = ""; val r = reply?.id; reply = null; scope.launch { AppModel.send(chatId, "text", t, meta = org.json.JSONObject().put("silent", true), replyTo = r) } }
                            else pickDateTime(ctx) { at ->
                                val r = reply?.id
                                scope.launch { if (AppModel.scheduleMessage(chatId, t, at, r)) { text = ""; reply = null; AppModel.say("Запланировано") } }
                            }
                        }
                    }
                },
                onFx = { e ->
                    val t = text.trim()
                    if (t.isNotEmpty()) AppModel.premium { text = ""; val r = reply?.id; reply = null; scope.launch { AppModel.send(chatId, "text", t, meta = org.json.JSONObject().put("fx", e), replyTo = r) } }
                },
                takeReply = { val r = reply?.id; reply = null; r },
                takeCaption = { val t = text.trim(); text = ""; t.ifEmpty { null } },
                onVideoNote = { lockedStart ->
                    val need = listOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
                        .filter { ContextCompat.checkSelfPermission(ctx, it) != PackageManager.PERMISSION_GRANTED }
                    if (need.isEmpty()) NoteSession(lockedStart).also { note = it } else { notePerm.launch(need.toTypedArray()); null }
                },
            )
        }

        if (showScheduled) ScheduledDialog(chatId) { showScheduled = false }
        var fxPlay by remember { mutableStateOf<String?>(null) }
        var fxSeen by remember { mutableStateOf(0) }
        LaunchedEffect(msgs.lastOrNull()?.id) {
            val m = msgs.lastOrNull() ?: return@LaunchedEffect
            val fx = m.meta.optString("fx")
            if (fx.isNotEmpty() && m.id > 0 && m.id != fxSeen && FX_LIST.contains(fx) && System.currentTimeMillis() - m.createdAt.time < 15000) { fxSeen = m.id; fxPlay = fx }
        }
        fxPlay?.let { e -> FxOverlay(e) { fxPlay = null } }
        menuFor?.let { m ->
            MessageMenu(m, chat, onClose = { menuFor = null },
                onReact = { e -> menuFor = null; scope.launch { AppModel.react(m, e) } },
                onReply = { menuFor = null; reply = m; editing = null },
                onCopy = { menuFor = null; copy(ctx, m.body ?: "") },
                onEdit = { menuFor = null; editing = m; reply = null; text = m.body ?: "" },
                onForward = { menuFor = null; forwarding = listOf(m) },
                onPin = { menuFor = null; scope.launch { AppModel.pin(if (chat?.pinnedMessageId == m.id) null else m, chatId) } },
                onSelect = { menuFor = null; if (m.id > 0) selected.add(m.id) },
                onDelete = { menuFor = null; deleting = listOf(m) },
                onOpen = { menuFor = null; MediaUtil.open(ctx, m.mediaUrl) },
                onReport = { menuFor = null; reportMsg = m },
                onTip = { menuFor = null; tipMsg = m },
            )
        }
        viewer?.let { MediaViewer(it) { viewer = null } }
        tipMsg?.let { m -> TipDialog(m) { tipMsg = null } }
        reportMsg?.let { m -> ReportDialog(m.senderId, chatId, m.id) { reportMsg = null } }
        LaunchedEffect(note) {
            val ns = note ?: return@LaunchedEffect
            try { while (note === ns) { AppModel.userTyping(chatId, "video"); delay(1500) } } finally { AppModel.userTyping(chatId, "stop") }
        }
        note?.let { ns -> VideoNoteRecorder(chatId, ns, { val r = reply?.id; reply = null; r }) { if (note === ns) note = null } }
        forwarding?.let { f ->
            ForwardPicker(onClose = { forwarding = null }) { to ->
                forwarding = null; selected.clear()
                scope.launch { for (m in f) AppModel.forward(m, to); AppModel.say("Переслано") }
            }
        }
        deleting?.let { d ->
            val saved = chat?.isPrivate == true && chat.peerId == AppModel.myId
            val forAll = !saved && (d.all { it.senderId == AppModel.myId } || (chat?.isAdmin == true && chat.isPrivate == false))
            fun go(everyone: Boolean) { deleting = null; selected.clear(); scope.launch { AppModel.delete(d, everyone) } }
            BackHandler { deleting = null }
            val mineAll = d.all { it.senderId == AppModel.myId }
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.5f)).clickable(remember { MutableInteractionSource() }, null) { deleting = null }) {
                Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().padding(horizontal = 12.dp, vertical = 24.dp),
                    horizontalAlignment = if (mineAll) Alignment.End else Alignment.Start, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(Modifier.clip(RoundedCornerShape(18.dp)).background(p.panel2).padding(12.dp).widthIn(max = 300.dp)) {
                        Text(if (d.size > 1) "Удалить ${plural(d.size, "сообщение", "сообщения", "сообщений")}?" else d[0].preview, color = p.text, maxLines = 4, overflow = TextOverflow.Ellipsis)
                    }
                    Column(Modifier.width(290.dp).clip(RoundedCornerShape(28.dp)).background(p.panel).clickable(remember { MutableInteractionSource() }, null) {}) {
                        if (forAll) {
                            Text(if (chat?.isPrivate == true) "Удалить у меня и у ${chat.displayName}" else "Удалить у всех", color = p.danger, fontSize = 18.sp,
                                modifier = Modifier.fillMaxWidth().clickable { go(true) }.padding(horizontal = 22.dp, vertical = 15.dp))
                            Box(Modifier.fillMaxWidth().height(1.dp).background(p.line))
                        }
                        Text(if (saved) "Удалить" else "Удалить у меня", color = p.danger, fontSize = 18.sp,
                            modifier = Modifier.fillMaxWidth().clickable { go(saved) }.padding(horizontal = 22.dp, vertical = 15.dp))
                    }
                }
            }
        }
    }
}

fun copy(ctx: Context, t: String) {
    if (t.isEmpty()) return
    ctx.getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText("Lumo", t))
    AppModel.say("Скопировано")
}

@Composable
private fun ChatHeader(chatId: String, chat: ChatItem?) {
    val p = P
    val saved = chat?.isPrivate == true && chat.peerId == AppModel.myId
    Row(Modifier.fillMaxWidth().background(p.panel.copy(alpha = 0.97f)).padding(horizontal = 4.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        RoundIcon(Icons.AutoMirrored.Filled.ArrowBack) { AppModel.pop() }
        Row(Modifier.weight(1f).clip(RoundedCornerShape(14.dp)).clickable {
            if (chat != null && !saved) AppModel.push(if (chat.isPrivate && chat.peerId != null) Screen.Person(chat.peerId) else Screen.Info(chatId))
        }.padding(4.dp), verticalAlignment = Alignment.CenterVertically) {
            if (saved) Box(Modifier.size(42.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) { Icon(Icons.Filled.Bookmark, null, tint = Color.White) }
            else Avatar(chat?.displayName ?: "", chat?.displayAvatar, chat?.displayColor ?: 0, 42.dp, online = chat?.isPrivate == true && AppModel.isOnline(chat.peerId))
            Spacer(Modifier.width(10.dp))
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(if (saved) "Избранное" else chat?.displayName ?: "Чат", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                    if (chat?.isPrivate == true) PeerBadges(chat)
                    if (chat?.isPrivate == true && ru.volshebnymir.lumo.core.E2E.active(chatId)) {
                        Spacer(Modifier.width(5.dp))
                        Icon(androidx.compose.material.icons.Icons.Filled.Lock, null, tint = p.a2, modifier = Modifier.size(14.dp))
                    }
                }
                val t = AppModel.typingText(chatId)
                val status = when {
                    t != null -> t
                    chat == null || saved -> ""
                    chat.isPrivate -> if (chat.peerBot) "бот" else AppModel.lastSeenText(chat.peerId, chat.peerLastSeen)
                    chat.isChannel -> plural(chat.membersCount, "подписчик", "подписчика", "подписчиков")
                    else -> plural(chat.membersCount, "участник", "участника", "участников")
                }
                androidx.compose.animation.AnimatedContent(status, transitionSpec = { (fadeIn(tween(200)) + androidx.compose.animation.slideInVertically { it / 2 }) togetherWith fadeOut(tween(150)) }, label = "st") { st ->
                    if (st.isNotEmpty()) Row(verticalAlignment = Alignment.CenterVertically) {
                        if (t != null) { TypingDots(p.a2); Spacer(Modifier.width(4.dp)) }
                        Text(st, color = if (t != null || st == "в сети") p.a2 else p.muted, fontSize = 13.sp, maxLines = 1)
                    }
                }
            }
        }
        if (chat?.isPrivate == true && !saved && !peerBadges(chat).first) {
            val call = rememberCallStarter()
            RoundIcon(Icons.Filled.Videocam) { call(chat, true) }
            RoundIcon(Icons.Filled.Call) { call(chat, false) }
        }
        if (chat != null) ChatMenu(chat)
    }
}

@Composable
private fun ChatMenu(c: ChatItem) {
    val p = P
    val scope = rememberCoroutineScope()
    var open by remember { mutableStateOf(false) }
    var confirmClear by remember { mutableStateOf(false) }
    var confirmLeave by remember { mutableStateOf(false) }
    var report by remember { mutableStateOf(false) }
    var bubDlg by remember { mutableStateOf(false) }
    if (bubDlg) BubbleColorDialog(c.id) { bubDlg = false }
    var wallDlg by remember { mutableStateOf(false) }
    if (wallDlg) ChatWallDialog(c.id, c.peerName, c.isPrivate) { wallDlg = false }
    Box {
        RoundIcon(Icons.Filled.MoreVert) { open = true }
        androidx.compose.material3.DropdownMenu(open, { open = false }) {
            @Composable fun item(icon: androidx.compose.ui.graphics.vector.ImageVector, t: String, danger: Boolean = false, f: () -> Unit) =
                androidx.compose.material3.DropdownMenuItem(text = { Text(t, color = if (danger) p.danger else p.text) }, leadingIcon = { Icon(icon, null, tint = if (danger) p.danger else p.text) }, onClick = { open = false; f() })
            item(Icons.Filled.Search, "Поиск по чату") { AppModel.push(Screen.ChatSearch(c.id)) }
            item(if (c.muted) Icons.Filled.Notifications else Icons.Filled.NotificationsOff, if (c.muted) "Включить уведомления" else "Без звука") { scope.launch { AppModel.setMuted(c.id, !c.muted) } }
            item(Icons.Filled.PushPin, if (c.pinned) "Открепить чат" else "Закрепить чат") { scope.launch { AppModel.setPinned(c.id, !c.pinned) } }
            item(Icons.Filled.Palette, "Цвет сообщений ★") { AppModel.premium { bubDlg = true } }
            if (!c.isChannel) item(Icons.Filled.Wallpaper, "Изменить обои ★") { AppModel.premium { wallDlg = true } }
            if (!c.isChannel && (c.isPrivate || c.isAdmin)) {
                val on = ru.volshebnymir.lumo.core.Prot.on(c.id)
                item(Icons.Filled.Shield, if (on) "Разрешить пересылку и скриншоты" else "Запретить пересылку и скриншоты ★") {
                    if (on) scope.launch { ru.volshebnymir.lumo.core.Prot.set(c.id, false) } else AppModel.premium { scope.launch { ru.volshebnymir.lumo.core.Prot.set(c.id, true) } }
                }
            }
            item(Icons.Filled.CleaningServices, "Очистить историю") { confirmClear = true }
            val peer = c.peerId
            if (c.isPrivate && peer != null && peer != AppModel.myId) {
                val blocked = peer in AppModel.blockedByMe
                item(Icons.Filled.Block, if (blocked) "Разблокировать" else "Заблокировать", danger = !blocked) { scope.launch { AppModel.setBlocked(peer, !blocked) } }
                item(Icons.Filled.Flag, "Пожаловаться", danger = true) { report = true }
            }
            if (!c.isPrivate) {
                item(Icons.Filled.Flag, "Пожаловаться", danger = true) { report = true }
                item(Icons.AutoMirrored.Filled.ExitToApp, if (c.isChannel) "Отписаться" else "Покинуть группу", danger = true) { confirmLeave = true }
            }
        }
    }
    if (confirmClear) AlertDialog(onDismissRequest = { confirmClear = false }, title = { Text("Очистить историю?") }, text = { Text("Сообщения исчезнут только у вас") },
        confirmButton = { TextButton({ confirmClear = false; scope.launch { AppModel.clearChat(c.id) } }) { Text("Очистить", color = p.danger) } },
        dismissButton = { TextButton({ confirmClear = false }) { Text("Отмена") } })
    if (confirmLeave) AlertDialog(onDismissRequest = { confirmLeave = false }, title = { Text(if (c.isChannel) "Отписаться от канала?" else "Покинуть группу?") },
        confirmButton = { TextButton({ confirmLeave = false; scope.launch { AppModel.leave(c.id) } }) { Text("Да", color = p.danger) } },
        dismissButton = { TextButton({ confirmLeave = false }) { Text("Отмена") } })
    if (report) ReportDialog(if (c.isPrivate) c.peerId else null, c.id, null) { report = false }
}

fun plural(n: Int, one: String, few: String, many: String): String {
    val a = n % 100; val b = n % 10
    val w = if (a in 11..14) many else if (b == 1) one else if (b in 2..4) few else many
    return "$n $w"
}

/** Три прыгающие точки «печатает…» */
@Composable
fun TypingDots(color: Color) {
    val t = rememberInfiniteTransition(label = "dots")
    Row(horizontalArrangement = Arrangement.spacedBy(2.5.dp), verticalAlignment = Alignment.CenterVertically) {
        for (i in 0..2) {
            val y by t.animateFloat(0f, 1f, infiniteRepeatable(androidx.compose.animation.core.keyframes {
                durationMillis = 900; 0f at (i * 150); 1f at (i * 150 + 200); 0f at (i * 150 + 400)
            }), label = "d$i")
            Box(Modifier.offset(y = (-3 * y).dp).size(4.5.dp).clip(CircleShape).background(color.copy(alpha = 0.5f + 0.5f * y)))
        }
    }
}

@Composable
private fun SelectHeader(n: Int, onClose: () -> Unit, onCopy: () -> Unit, onForward: () -> Unit, onDelete: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().background(p.panel).padding(horizontal = 4.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        RoundIcon(Icons.Filled.Close) { onClose() }
        Text("Выбрано: $n", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp, modifier = Modifier.weight(1f).padding(start = 6.dp))
        RoundIcon(Icons.Filled.ContentCopy) { onCopy() }
        RoundIcon(Icons.Filled.Shortcut) { onForward() }
        RoundIcon(Icons.Filled.Delete, tint = p.danger) { onDelete() }
    }
}

@Composable
private fun PinnedBar(chat: ChatItem?, chatId: String, onTap: (Int) -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val id = chat?.pinnedMessageId ?: return
    val m = AppModel.findMessage(id, chatId)
    Row(Modifier.fillMaxWidth().background(p.panel.copy(alpha = 0.94f)).clickable { onTap(id) }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(3.dp).height(34.dp).clip(RoundedCornerShape(2.dp)).background(p.accent))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text("Закреплённое сообщение", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            Text(m?.preview ?: "…", color = p.text, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (chat.isPrivate || chat.isAdmin) Icon(Icons.Filled.Close, null, tint = p.muted, modifier = Modifier.size(22.dp).clickable { scope.launch { AppModel.pin(null, chatId) } })
    }
}

@Composable
private fun DayChip(d: Date) {
    val p = P
    Box(Modifier.fillMaxWidth().padding(vertical = 8.dp), contentAlignment = Alignment.Center) {
        Text(Fmt.day(d), color = p.text, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.clip(RoundedCornerShape(12.dp)).background(p.panel.copy(alpha = 0.8f)).padding(horizontal = 12.dp, vertical = 4.dp))
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MessageRow(
    m: Message, chat: ChatItem?, first: Boolean, last: Boolean, selecting: Boolean, isSelected: Boolean, flash: Boolean,
    onTap: (Message) -> Unit, onLong: (Message) -> Unit, onReply: (Message) -> Unit, onReplyTap: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val p = P
    val haptic = LocalHapticFeedback.current
    val density = LocalDensity.current
    if (m.kind == "gift") { GiftMessageCard(m, chat); return }
    if (m.kind == "system") {
        Box(Modifier.fillMaxWidth().padding(vertical = 6.dp), contentAlignment = Alignment.Center) {
            Text(m.body ?: "", color = p.text, fontSize = 13.sp, textAlign = TextAlign.Center,
                modifier = Modifier.clip(RoundedCornerShape(12.dp)).background(p.panel.copy(alpha = 0.8f)).padding(horizontal = 12.dp, vertical = 5.dp))
        }
        return
    }
    val mine = m.senderId == AppModel.myId
    val group = chat?.type == "group"
    val scope = rememberCoroutineScope()
    val dx = remember { Animatable(0f) }
    val limit = with(density) { 70.dp.toPx() }
    val bgTarget = when { isSelected -> p.a1.copy(alpha = 0.18f); flash -> p.a2.copy(alpha = 0.18f); else -> Color.Transparent }
    val bg by androidx.compose.animation.animateColorAsState(bgTarget, tween(300), label = "bg")
    // новое сообщение «выпрыгивает» снизу
    val fresh = remember(m.id) { (m.pending || (m.senderId != AppModel.myId && System.currentTimeMillis() - m.createdAt.time < 5000)) }
    val enter = remember(m.id) { Animatable(if (fresh) 0f else 1f) }
    LaunchedEffect(m.id) { if (fresh) enter.animateTo(1f, androidx.compose.animation.core.spring(0.62f, 380f)) }
    Row(
        modifier.fillMaxWidth().background(bg)
            .graphicsLayer {
                val k = enter.value
                alpha = k.coerceIn(0f, 1f); translationY = (1 - k) * 60f
                scaleX = 0.85f + 0.15f * k; scaleY = 0.85f + 0.15f * k
                transformOrigin = androidx.compose.ui.graphics.TransformOrigin(if (mine) 1f else 0f, 1f)
            }
            .combinedClickable(interactionSource = remember { MutableInteractionSource() }, indication = null,
                onClick = { onTap(m) }, onLongClick = { haptic.performHapticFeedback(HapticFeedbackType.LongPress); onLong(m) })
            .pointerInput(m.id, selecting) {
                if (selecting) return@pointerInput
                var fired = false
                detectHorizontalDragGestures(
                    onDragStart = { fired = false },
                    onDragEnd = { if (dx.value <= -limit * 0.85f) onReply(m); scope.launch { dx.animateTo(0f, tween(180)) } },
                    onDragCancel = { scope.launch { dx.animateTo(0f) } },
                ) { _, d ->
                    val v = (dx.value + d).coerceIn(-limit * 1.2f, 0f)
                    scope.launch { dx.snapTo(v) }
                    if (!fired && v <= -limit * 0.85f) { fired = true; haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove) }
                }
            }
            .padding(top = if (first) 6.dp else 1.5.dp, bottom = 1.5.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        if (selecting) {
            Box(Modifier.padding(end = 6.dp, bottom = 6.dp).size(24.dp).clip(CircleShape).background(if (isSelected) p.accent else SolidColor(p.muted.copy(alpha = 0.3f))), contentAlignment = Alignment.Center) {
                if (isSelected) Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(16.dp))
            }
        }
        if (mine) Spacer(Modifier.weight(1f))
        if (group && !mine) {
            Box(Modifier.size(34.dp)) {
                if (last) { val pr = m.senderId?.let { AppModel.profiles[it] }; Avatar(AppModel.displayName(m.senderId), pr?.avatarUrl, pr?.color ?: 0, 34.dp) }
            }
            Spacer(Modifier.width(6.dp))
        }
        Box(Modifier.offset { IntOffset(dx.value.roundToInt(), 0) }.widthIn(max = 310.dp)) {
            Column(horizontalAlignment = if (mine) Alignment.End else Alignment.Start) {
                Bubble(m, chat, mine, group && !mine && first, last, onReplyTap)
                Reactions(m, mine)
                TipPill(m, mine)
            }
        }
        if (dx.value < -8f) {
            Icon(Icons.AutoMirrored.Filled.Reply, null, tint = p.a1, modifier = Modifier.align(Alignment.CenterVertically).alpha((-dx.value / limit).coerceIn(0f, 1f)).size(26.dp))
        }
        if (!mine) Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun Bubble(m: Message, chat: ChatItem?, mine: Boolean, showName: Boolean, tail: Boolean, onReplyTap: (Int) -> Unit) {
    val p = P
    val bare = (m.kind == "video_note" || m.kind == "sticker") && !m.deleted
    val r = 18.dp; val small = 5.dp
    val shape = if (mine) RoundedCornerShape(r, r, if (tail) small else r, r) else RoundedCornerShape(r, r, r, if (tail) small else r)
    val fg = if (mine) Color.White else p.text
    val sub = if (mine) Color.White.copy(alpha = 0.75f) else p.muted
    val mod = if (bare) Modifier else Modifier.clip(shape).background(if (mine) (Extra.bubBrush(m.chatId) ?: p.out) else SolidColor(p.bubble))
        .padding(if (m.kind == "image" || m.kind == "video") 4.dp else 10.dp, if (m.kind == "image" || m.kind == "video") 4.dp else 7.dp)
    Column(mod) {
        val pad = if (m.kind == "image" || m.kind == "video") Modifier.padding(horizontal = 6.dp, vertical = 2.dp) else Modifier
        if (showName) Text(AppModel.displayName(m.senderId), color = p.nameColor(m.senderId?.let { AppModel.profiles[it]?.color } ?: 0),
            fontWeight = FontWeight.Bold, fontSize = 14.sp, modifier = pad)
        if (!m.forwardedFrom.isNullOrEmpty()) Text("Переслано от ${m.forwardedFrom}", color = if (mine) Color.White.copy(alpha = 0.85f) else p.a1, fontSize = 13.sp, fontStyle = FontStyle.Italic, modifier = pad)
        m.replyTo?.let { rid ->
            val q = AppModel.findMessage(rid, m.chatId)
            Row(pad.padding(vertical = 3.dp).clip(RoundedCornerShape(8.dp)).background(if (mine) Color.White.copy(alpha = 0.16f) else p.a1.copy(alpha = 0.1f))
                .clickable { onReplyTap(rid) }.padding(end = 8.dp).height(IntrinsicSize.Min)) {
                Box(Modifier.width(3.dp).fillMaxHeight().background(if (mine) Color.White else p.a1))
                Column(Modifier.padding(start = 7.dp, top = 3.dp, bottom = 3.dp)) {
                    Text(q?.let { AppModel.displayName(it.senderId) } ?: "Сообщение", color = if (mine) Color.White else p.a1, fontWeight = FontWeight.Bold, fontSize = 13.sp, maxLines = 1)
                    Text(q?.preview ?: "…", color = fg.copy(alpha = 0.85f), fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
        if (m.deleted) {
            Text("Сообщение удалено", color = sub, fontStyle = FontStyle.Italic, fontSize = Look.fontSize.sp)
        } else when (m.kind) {
            "image" -> {
                val ratio = ((m.width ?: 1.0) / (m.height ?: 1.0)).toFloat().coerceIn(0.5f, 2f)
                AsyncImage(m.localPath ?: m.mediaUrl, null, Modifier.width(260.dp).aspectRatio(ratio).clip(RoundedCornerShape(14.dp)), contentScale = ContentScale.Crop)
            }
            "video" -> Box(Modifier.width(260.dp).aspectRatio(((m.width ?: 16.0) / (m.height ?: 9.0)).toFloat().coerceIn(0.56f, 1.8f)).clip(RoundedCornerShape(14.dp)).background(Color.Black), contentAlignment = Alignment.Center) {
                AsyncImage(m.localPath ?: m.mediaUrl, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                Box(Modifier.size(50.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.5f)), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.PlayArrow, null, tint = Color.White, modifier = Modifier.size(32.dp))
                }
            }
            "voice" -> VoiceBubble(m, mine)
            "video_note" -> VideoNoteBubble(m)
            "sticker" -> if (m.meta.has("anim")) AnimatedEmoji(m.body ?: "", 96.dp) else if (!m.mediaUrl.isNullOrEmpty()) AsyncImage(m.mediaUrl, null, Modifier.size(150.dp)) else Text(m.body ?: "", fontSize = 64.sp)
            "file" -> Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(44.dp).clip(CircleShape).background(if (mine) Color.White.copy(alpha = 0.22f) else p.a1), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Description, null, tint = Color.White)
                }
                Spacer(Modifier.width(10.dp))
                Column(Modifier.widthIn(max = 200.dp)) {
                    Text(m.fileName, color = fg, fontWeight = FontWeight.SemiBold, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    Text(m.fileSize?.let { Fmt.size(it) } ?: "Файл", color = sub, fontSize = 12.5.sp)
                }
            }
            "call" -> Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(if (m.isVideoCall) Icons.Filled.Videocam else Icons.Filled.Call, null, tint = fg, modifier = Modifier.size(22.dp))
                Spacer(Modifier.width(8.dp))
                Column {
                    Text(if (m.isVideoCall) "Видеозвонок" else "Звонок", color = fg, fontWeight = FontWeight.SemiBold)
                    val st = m.metaStatus
                    val d = m.duration
                    Text(when {
                        d > 0 -> Fmt.duration(d)
                        st == "rejected" -> "Отклонён"
                        st == "missed" || st == "ended" -> if (mine) "Нет ответа" else "Пропущенный"
                        else -> if (mine) "Исходящий" else "Входящий"
                    }, color = sub, fontSize = 13.sp)
                }
            }
        }
        if (!m.deleted && !m.body.isNullOrEmpty() && m.kind != "sticker" && m.kind != "system") {
            val cmdChat = if (!mine && m.senderId?.let { AppModel.profiles[it] }?.isBot == true) m.chatId else null
            if (m.kind == "text") RichText(m.body, fg, mine, cmdChat = cmdChat) else RichText(m.body, fg, mine, Modifier.padding(horizontal = 6.dp, vertical = 3.dp), cmdChat)
        }
        BotButtons(m, mine)
        val grp = if (chat?.isChannel == true) Lumens.linked(chat.id) else null
        LaunchedEffect(m.id) { if (m.id > 0 && !m.deleted) Lumens.request(m.id, grp != null) }
        if (grp != null && m.id > 0 && !m.deleted && m.kind != "system") {
            val n = Lumens.comments[m.id] ?: 0
            Row(Modifier.padding(top = 6.dp).fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(if (mine) Color.White.copy(alpha = 0.16f) else p.a1.copy(alpha = 0.1f))
                .clickable { AppModel.push(Screen.Comments(m.chatId, m.id)) }.padding(horizontal = 10.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.ChatBubbleOutline, null, tint = if (mine) Color.White else p.a1, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(if (n == 0) "Оставить комментарий" else "$n ${lumenCommentWord(n)}", color = if (mine) Color.White else p.a1, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, modifier = Modifier.weight(1f))
                Icon(Icons.Filled.ChevronRight, null, tint = if (mine) Color.White else p.a1, modifier = Modifier.size(18.dp))
            }
        }
        // время и галочки
        val read = mine && chat != null && chat.othersReadAt != null && !chat.othersReadAt.before(m.createdAt)
        Row(Modifier.align(Alignment.End).then(if (bare) Modifier.padding(top = 3.dp).clip(RoundedCornerShape(10.dp)).background(Color.Black.copy(alpha = 0.35f)).padding(horizontal = 7.dp, vertical = 1.dp) else pad),
            verticalAlignment = Alignment.CenterVertically) {
            if (m.editedAt != null && !m.deleted) Text("изм. ", color = if (bare) Color.White else sub, fontSize = 11.sp)
            Text(Fmt.clock(m.createdAt), color = if (bare) Color.White else sub, fontSize = 11.sp)
            if (mine && chat?.isChannel != true) {
                Spacer(Modifier.width(3.dp))
                Icon(when { m.pending -> Icons.Filled.Schedule; read -> Icons.Filled.DoneAll; else -> Icons.Filled.Done }, null,
                    tint = if (bare) Color.White else sub, modifier = Modifier.size(14.dp))
            }
        }
    }
}

private val TOKENS = Regex("""\*\*(.+?)\*\*|__(.+?)__|~~(.+?)~~|`([^`]+)`|(https?://[^\s]+)|(@[A-Za-z0-9_]{3,})|((?<![\w/])/[A-Za-z][A-Za-z0-9_]{1,31})""")

@Composable
fun RichText(s: String, color: Color, mine: Boolean, modifier: Modifier = Modifier, cmdChat: String? = null) {
    val p = P
    val link = if (mine) Color.White else p.a2
    val text: AnnotatedString = remember(s, mine, p.a2, cmdChat) {
        buildAnnotatedString {
            var i = 0
            for (mt in TOKENS.findAll(s)) {
                append(s.substring(i, mt.range.first))
                val g = mt.groupValues
                when {
                    g[1].isNotEmpty() -> withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(g[1]) }
                    g[2].isNotEmpty() -> withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(g[2]) }
                    g[3].isNotEmpty() -> withStyle(SpanStyle(textDecoration = TextDecoration.LineThrough)) { append(g[3]) }
                    g[4].isNotEmpty() -> withStyle(SpanStyle(fontFamily = FontFamily.Monospace, background = Color.Black.copy(alpha = 0.18f))) { append(g[4]) }
                    g[5].isNotEmpty() -> withLink(LinkAnnotation.Url(g[5], TextLinkStyles(SpanStyle(color = link, textDecoration = TextDecoration.Underline)))) { append(g[5]) }
                    g[6].isNotEmpty() -> withStyle(SpanStyle(color = link, fontWeight = FontWeight.SemiBold)) { append(g[6]) }
                    g[7].isNotEmpty() -> if (cmdChat != null) {
                        val cmd = g[7]
                        withLink(LinkAnnotation.Clickable("cmd", TextLinkStyles(SpanStyle(color = Color(0xFF3AA0FF), fontWeight = FontWeight.SemiBold))) {
                            AppModel.scope.launch { AppModel.send(cmdChat, "text", cmd) }
                        }) { append(cmd) }
                    } else append(g[7])
                }
                i = mt.range.last + 1
            }
            append(s.substring(i))
        }
    }
    val onlyEmoji = s.length <= 8 && s.none { it.isLetterOrDigit() } && s.isNotBlank() && s.codePoints().anyMatch { it > 0x2000 }
    Text(text, color = color, fontSize = if (onlyEmoji) 40.sp else Look.fontSize.sp, lineHeight = (Look.fontSize * 1.3f).sp, modifier = modifier)
}

@Composable
private fun Reactions(m: Message, mine: Boolean) {
    val p = P
    val scope = rememberCoroutineScope()
    val rs = AppModel.reactions[m.id] ?: return
    if (rs.isEmpty()) return
    Row(Modifier.padding(top = 3.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        rs.groupBy { it.emoji }.forEach { (e, l) ->
            val my = l.any { it.userId == AppModel.myId }
            Row(Modifier.popIn().clip(RoundedCornerShape(14.dp)).background(if (my) p.accent else SolidColor(p.panel)).clickable { scope.launch { AppModel.react(m, e) } }
                .padding(horizontal = 8.dp, vertical = 3.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(e, fontSize = 15.sp)
                if (l.size > 1 || true) Text(" ${l.size}", color = if (my) Color.White else p.text, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun MessageMenu(
    m: Message, chat: ChatItem?, onClose: () -> Unit, onReact: (String) -> Unit, onReply: () -> Unit, onCopy: () -> Unit, onEdit: () -> Unit,
    onForward: () -> Unit, onPin: () -> Unit, onSelect: () -> Unit, onDelete: () -> Unit, onOpen: () -> Unit, onReport: () -> Unit, onTip: () -> Unit = {},
) {
    val p = P
    BackHandler { onClose() }
    val mine = m.senderId == AppModel.myId
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { shown = true }
    // нажатие на пустое место закрывает меню
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.45f)).clickable(remember { MutableInteractionSource() }, null) { onClose() }, contentAlignment = Alignment.Center) {
        AnimatedVisibility(shown, enter = scaleIn(initialScale = 0.85f) + fadeIn(), exit = fadeOut()) {
            Column(Modifier.padding(24.dp).widthIn(max = 340.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                val allowedRx = Lumens.allowed(chat?.id)
                val rxList = if (allowedRx == null) QUICK else QUICK.filter { it in allowedRx } + allowedRx.filter { it !in QUICK }
                if (m.id > 0 && !m.deleted && rxList.isNotEmpty()) Row(Modifier.clip(RoundedCornerShape(28.dp)).background(p.panel).horizontalScroll(rememberScrollState()).padding(6.dp)) {
                    rxList.forEach { e -> Text(e, fontSize = 28.sp, modifier = Modifier.clip(CircleShape).bouncy { onReact(e) }.padding(6.dp)) }
                }
                Spacer(Modifier.height(10.dp))
                Box(Modifier.clip(RoundedCornerShape(18.dp)).background(p.panel2).padding(12.dp).widthIn(max = 300.dp)) {
                    Text(m.preview, color = p.text, maxLines = 4, overflow = TextOverflow.Ellipsis)
                }
                Spacer(Modifier.height(10.dp))
                // меню как в Telegram: время сверху, значки слева, «Выбрать» отдельно снизу
                Column(Modifier.widthIn(min = 250.dp, max = 290.dp).clip(RoundedCornerShape(26.dp))
                    .background(Brush.linearGradient(listOf(p.panel.copy(alpha = 0.97f), p.panel2.copy(alpha = 0.97f), p.a2.copy(alpha = 0.10f).compositeOver(p.panel))))
                    .border(0.8.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(26.dp)).padding(vertical = 4.dp)) {
                    @Composable fun item(icon: androidx.compose.ui.graphics.vector.ImageVector, t: String, danger: Boolean = false, f: () -> Unit) {
                        Row(Modifier.fillMaxWidth().clickable(onClick = f).padding(horizontal = 20.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(icon, null, tint = if (danger) p.danger else p.text, modifier = Modifier.size(23.dp))
                            Spacer(Modifier.width(18.dp))
                            Text(t, color = if (danger) p.danger else p.text, fontSize = 17.sp)
                        }
                    }
                    val read = mine && chat != null && chat.othersReadAt != null && !chat.othersReadAt.before(m.createdAt)
                    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(if (mine && chat?.isChannel != true) (if (read) Icons.Filled.DoneAll else Icons.Filled.Done) else Icons.Filled.Schedule, null,
                            tint = if (read) p.a2 else p.muted, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(20.dp))
                        Text((if (m.editedAt != null) "изм. · " else "") + whenText(m.createdAt), color = p.muted, fontSize = 15.sp)
                    }
                    Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp).height(1.dp).background(p.line))
                    val ok = m.id > 0 && !m.deleted
                    if (ok && chat?.canPost != false) item(Icons.AutoMirrored.Filled.Reply, "Ответить", f = onReply)
                    val prot = ru.volshebnymir.lumo.core.Prot.on(chat?.id)
                    if (!m.body.isNullOrEmpty() && ok && !prot) item(Icons.Filled.ContentCopy, "Копировать", f = onCopy)
                    if (mine && m.kind in listOf("text", "image", "video", "file") && ok) item(Icons.Filled.EditNote, "Изменить", f = onEdit)
                    if (ok && (chat?.isPrivate == true || chat?.isAdmin == true))
                        item(Icons.Filled.PushPin, if (chat.pinnedMessageId == m.id) "Открепить" else "Закрепить", f = onPin)
                    if (ok && !prot) item(Icons.AutoMirrored.Filled.Forward, "Переслать", f = onForward)
                    if (!m.mediaUrl.isNullOrEmpty() && ok && !prot) item(Icons.Filled.Download, "Скачать", f = onOpen)
                    if (!mine && ok && m.senderId != null) item(Icons.Filled.Star, "Отправить люмены", f = onTip)
                    if (!mine && ok) item(Icons.Filled.Flag, "Пожаловаться", f = onReport)
                    if (ok) item(Icons.Filled.DeleteOutline, "Удалить", danger = true, f = onDelete)
                    if (m.id > 0) {
                        Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp).height(1.dp).background(p.line))
                        item(Icons.Filled.CheckCircleOutline, "Выбрать", f = onSelect)
                    }
                }
            }
        }
    }
}

/** «сегодня в 23:32» */
fun whenText(d: java.util.Date): String {
    val now = java.util.Date()
    val hm = java.text.SimpleDateFormat("HH:mm", java.util.Locale("ru")).format(d)
    if (Fmt.isSameDay(d, now)) return "сегодня в $hm"
    if (Fmt.isSameDay(d, java.util.Date(now.time - 86_400_000))) return "вчера в $hm"
    return java.text.SimpleDateFormat("d MMM в HH:mm", java.util.Locale("ru")).format(d)
}

@Composable
private fun ForwardPicker(onClose: () -> Unit, onPick: (String) -> Unit) {
    val p = P
    BackHandler { onClose() }
    var q by remember { mutableStateOf("") }
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.5f)).clickable(remember { MutableInteractionSource() }, null) { onClose() }, contentAlignment = Alignment.BottomCenter) {
        Column(Modifier.fillMaxWidth().fillMaxHeight(0.75f).clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)).background(p.bg)
            .clickable(remember { MutableInteractionSource() }, null) {}.navigationBarsPadding()) {
            Text("Переслать в…", color = p.text, fontWeight = FontWeight.Black, fontSize = 20.sp, modifier = Modifier.padding(18.dp))
            SearchBox(q, { q = it }, Modifier.padding(horizontal = 14.dp).fillMaxWidth())
            LazyColumn(Modifier.fillMaxSize()) {
                items(AppModel.chats.filter { it.canPost && (q.isBlank() || it.displayName.contains(q, true)) }, key = { it.id }) { c ->
                    val saved = c.isPrivate && c.peerId == AppModel.myId
                    Row(Modifier.fillMaxWidth().clickable { onPick(c.id) }.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Avatar(c.displayName, c.displayAvatar, c.displayColor, 44.dp)
                        Spacer(Modifier.width(12.dp))
                        Text(if (saved) "Избранное" else c.displayName, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    }
                }
            }
        }
    }
}

@Composable
@OptIn(ExperimentalFoundationApi::class)
private fun Composer(
    chatId: String, text: String, onText: (String) -> Unit, reply: Message?, editing: Message?, onCancel: () -> Unit, onSend: () -> Unit,
    onSendMenu: (Int) -> Unit = {}, onFx: (String) -> Unit = {},
    takeReply: () -> Int?, takeCaption: () -> String?, onVideoNote: (Boolean) -> NoteSession?,
) {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current
    var attach by remember { mutableStateOf(false) }
    var sendLumensTo by remember { mutableStateOf<String?>(null) }
    val chat = AppModel.chat(chatId)
    var recording by remember { mutableStateOf(false) }
    var locked by remember { mutableStateOf(false) }
    var dragX by remember { mutableFloatStateOf(0f) }
    var recSec by remember { mutableIntStateOf(0) }
    var videoMode by remember { mutableStateOf(false) }
    var stickers by remember { mutableStateOf(false) }
    var level by remember { mutableFloatStateOf(0f) }
    val recorder = remember { VoiceRecorder(ctx) }
    val limit = with(density) { 80.dp.toPx() }

    val pickMedia = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(10)) { uris ->
        if (uris.isEmpty()) return@rememberLauncherForActivityResult
        val caption = takeCaption(); val r = takeReply()
        scope.launch {
            uris.forEachIndexed { i, u ->
                val type = ctx.contentResolver.getType(u) ?: ""
                val data = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u) } ?: run { AppModel.say("Не удалось открыть файл"); return@forEachIndexed }
                if (data.size > 50 * 1024 * 1024) { AppModel.say("Файл больше 50 МБ"); return@forEachIndexed }
                val body = if (i == 0) caption else null
                if (type.startsWith("video")) {
                    val ext = android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(type) ?: "mp4"
                    AppModel.sendMedia(chatId, "video", data, ext, type, jsonOf("name" to "video.$ext", "size" to data.size), body, r)
                } else {
                    val j = withContext(Dispatchers.Default) { MediaUtil.jpeg(data) } ?: return@forEachIndexed
                    AppModel.sendMedia(chatId, "image", j.first, "jpg", "image/jpeg", jsonOf("w" to j.second, "h" to j.third), body, r)
                }
            }
        }
    }
    val pickFile = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { u ->
        if (u == null) return@rememberLauncherForActivityResult
        scope.launch {
            val data = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u) } ?: run { AppModel.say("Не удалось открыть файл"); return@launch }
            if (data.size > 50 * 1024 * 1024) { AppModel.say("Файл больше 50 МБ"); return@launch }
            val name = MediaUtil.name(ctx, u)
            val type = ctx.contentResolver.getType(u) ?: "application/octet-stream"
            val ext = name.substringAfterLast('.', "").lowercase().ifEmpty { "bin" }
            AppModel.sendMedia(chatId, "file", data, ext, type, jsonOf("name" to name, "size" to data.size))
        }
    }
    // камера: снимок фото
    val photoFile = remember { java.io.File(ctx.cacheDir, "cam.jpg") }
    val photoUri = remember { androidx.core.content.FileProvider.getUriForFile(ctx, ctx.packageName + ".files", photoFile) }
    val takePhoto = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        if (!ok) return@rememberLauncherForActivityResult
        scope.launch {
            val j = withContext(Dispatchers.IO) { runCatching { photoFile.readBytes() }.getOrNull()?.let { MediaUtil.jpeg(MediaUtil.fixRotation(photoFile, it)) } } ?: return@launch
            AppModel.sendMedia(chatId, "image", j.first, "jpg", "image/jpeg", jsonOf("w" to j.second, "h" to j.third), takeCaption(), takeReply())
        }
    }
    val camPerm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { if (it) takePhoto.launch(photoUri) else AppModel.say("Нужен доступ к камере") }

    fun startRec(): Boolean {
        Voice.stop()
        return if (recorder.start()) { recording = true; recSec = 0; true } else { AppModel.say("Не удалось включить микрофон"); false }
    }
    fun finishRec() {
        recording = false; locked = false
        val res = recorder.stop()
        if (res == null || res.second < 0.7) return
        val data = res.first.readBytes()
        AppModel.sendMedia(chatId, "voice", data, "m4a", "audio/mp4",
            jsonOf("dur" to maxOf(1, Math.round(res.second).toInt()), "wave" to JSONArray(res.third)), replyTo = takeReply(), local = res.first.absolutePath)
    }
    fun cancelRec() { recorder.cancel(); recording = false; locked = false }
    val micPerm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok -> if (!ok) AppModel.say("Нужен доступ к микрофону") else AppModel.say("Удерживайте, чтобы записать") }
    LaunchedEffect(recording) {
        var t = 0
        while (recording) {
            if (t % 15 == 0) AppModel.userTyping(chatId, "voice")   // у собеседника: «записывает голосовое…»
            recorder.sample(); level = (recorder.levels.lastOrNull() ?: 0) / 31f; delay(100); t++; if (t % 10 == 0) recSec = t / 10
        }
        level = 0f
        if (t > 0) AppModel.userTyping(chatId, "stop")
    }
    DisposableEffect(Unit) { onDispose { if (recording) recorder.cancel() } }
    val haptic = LocalHapticFeedback.current

    Column(Modifier.fillMaxWidth().background(p.panel.copy(alpha = 0.97f)).navigationBarsPadding()) {
        if (reply != null || editing != null) {
            val m = editing ?: reply!!
            Row(Modifier.popIn(0.9f).fillMaxWidth().padding(start = 14.dp, end = 6.dp, top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(if (editing != null) Icons.Filled.Edit else Icons.AutoMirrored.Filled.Reply, null, tint = p.a1)
                Spacer(Modifier.width(10.dp))
                Box(Modifier.width(3.dp).height(34.dp).background(p.a1))
                Spacer(Modifier.width(8.dp))
                Column(Modifier.weight(1f)) {
                    Text(if (editing != null) "Редактирование" else "Ответ: " + AppModel.displayName(m.senderId), color = p.a1, fontWeight = FontWeight.Bold, fontSize = 13.5.sp)
                    Text(m.preview, color = p.text, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                RoundIcon(Icons.Filled.Close, 38.dp) { onCancel() }
            }
        }
        Row(Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 6.dp), verticalAlignment = Alignment.Bottom) {
            val hasText = text.isNotBlank()
            if (recording) {
                if (locked) RoundIcon(Icons.Filled.Delete, 48.dp, tint = p.danger) { cancelRec() }
                val inf = rememberInfiniteTransition(label = "rec")
                val a by inf.animateFloat(1f, 0.2f, infiniteRepeatable(tween(600), RepeatMode.Reverse), label = "a")
                Row(Modifier.weight(1f).height(48.dp).clip(RoundedCornerShape(22.dp)).background(p.panel2).padding(horizontal = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(10.dp).alpha(a).clip(CircleShape).background(Color(0xFFFF3B5C)))
                    Spacer(Modifier.width(10.dp))
                    Text(Fmt.duration(recSec.toDouble()), color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    Spacer(Modifier.weight(1f))
                    if (locked) Text("Запись без удержания", color = p.muted, fontSize = 14.sp)
                    else Row(Modifier.offset { IntOffset(dragX.coerceIn(-limit, 0f).roundToInt(), 0) }, verticalAlignment = Alignment.CenterVertically) {
                        Text(if (dragX < -limit * 0.75f) "Отпустите для отмены" else "‹ Влево — отмена", color = if (dragX < -limit * 0.75f) p.danger else p.muted, fontSize = 14.sp)
                        if (dragX > -limit * 0.75f) Icon(Icons.Filled.Lock, null, tint = p.muted, modifier = Modifier.padding(start = 4.dp).size(14.dp))
                    }
                }
                Spacer(Modifier.width(6.dp))
            } else {
                Box {
                    RoundIcon(Icons.Filled.AttachFile, 48.dp, tint = p.muted) { attach = true }
                    sendLumensTo?.let { u -> LumenSendDialog(u) { sendLumensTo = null } }
                    androidx.compose.material3.DropdownMenu(attach, { attach = false }) {
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Фото или видео") }, leadingIcon = { Icon(Icons.Filled.Photo, null) }, onClick = {
                            attach = false; pickMedia.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageAndVideo))
                        })
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Камера") }, leadingIcon = { Icon(Icons.Filled.CameraAlt, null) }, onClick = {
                            attach = false
                            if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) takePhoto.launch(photoUri)
                            else camPerm.launch(Manifest.permission.CAMERA)
                        })
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Файл") }, leadingIcon = { Icon(Icons.Filled.Description, null) }, onClick = {
                            attach = false; pickFile.launch(arrayOf("*/*"))
                        })
                        if (chat?.isPrivate == true && chat.peerId != AppModel.myId && !peerBadges(chat).first) androidx.compose.material3.DropdownMenuItem(text = { Text("Отправить люмены") }, leadingIcon = { Icon(Icons.Filled.Diamond, null) }, onClick = {
                            attach = false; sendLumensTo = chat.peerId
                        })
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Видеосообщение") }, leadingIcon = { Icon(Icons.Filled.SlowMotionVideo, null) }, onClick = {
                            attach = false; onVideoNote(true)
                        })
                    }
                }
                Row(Modifier.weight(1f).clip(RoundedCornerShape(22.dp)).background(p.panel2), verticalAlignment = Alignment.Bottom) {
                    Box(Modifier.weight(1f).padding(start = 16.dp, top = 12.dp, bottom = 12.dp)) {
                        if (text.isEmpty()) Text("Сообщение", color = p.muted, fontSize = 16.sp)
                        BasicTextField(text, onText, maxLines = 6, textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1),
                            modifier = Modifier.fillMaxWidth().onFocusChanged { if (it.isFocused) stickers = false })
                    }
                    RoundIcon(if (stickers) Icons.Filled.Keyboard else Icons.Filled.EmojiEmotions, 44.dp, tint = p.muted) { stickers = !stickers }
                }
                Spacer(Modifier.width(6.dp))
            }
            if (hasText && !recording) {
                var sendMenu by remember { mutableStateOf(false) }
                Box {
                    Box(Modifier.popIn().size(48.dp).clip(CircleShape).background(p.accent)
                        .combinedClickable(onClick = { onSend() }, onLongClick = { if (editing == null) sendMenu = true }), contentAlignment = Alignment.Center) {
                        Icon(if (editing != null) Icons.Filled.Check else Icons.AutoMirrored.Filled.Send, null, tint = Color.White)
                    }
                    if (sendMenu) SendMenuDialog(text.trim(), { sendMenu = false }, { e -> sendMenu = false; onFx(e) }, { w -> sendMenu = false; onSendMenu(w) }, { sendMenu = false; onSend() })
                }
            } else if (recording && locked) {
                Box(Modifier.size(48.dp).clip(CircleShape).background(p.accent).bouncy { finishRec() }, contentAlignment = Alignment.Center) {
                    Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White)
                }
            } else {
                // нажатие — переключить голосовое/кружок; удержание — запись (вверх — без удержания, влево — отмена)
                val size by androidx.compose.animation.core.animateDpAsState(if (recording) 56.dp else 48.dp, label = "rb")
                Box(Modifier.size(size).scale(1f + level * 0.25f).clip(CircleShape).background(if (recording) SolidColor(p.danger) else p.accent)
                    .pointerInput(videoMode) {
                        awaitEachGesture {
                            val down = awaitFirstDown()
                            val quick = withTimeoutOrNull(220) { waitForUpOrCancellation(); true }
                            if (quick == true) {
                                videoMode = !videoMode
                                AppModel.say(if (videoMode) "Удерживайте, чтобы записать кружок" else "Удерживайте, чтобы записать голосовое")
                                return@awaitEachGesture
                            }
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            var session: NoteSession? = null
                            var voice = false
                            if (videoMode) session = onVideoNote(false)
                            else if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) micPerm.launch(Manifest.permission.RECORD_AUDIO)
                            else voice = startRec()
                            var dx = 0f; var dy = 0f
                            while (true) {
                                val ev = awaitPointerEvent()
                                val ch = ev.changes.firstOrNull { it.id == down.id } ?: break
                                dx = ch.position.x - down.position.x; dy = ch.position.y - down.position.y
                                dragX = dx
                                if (dy < -limit) {
                                    if (voice && !locked) { locked = true; haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove) }
                                    if (session != null && !session.locked) session.locked = true
                                }
                                if (!ch.pressed) break
                            }
                            dragX = 0f
                            if (session != null) { if (!session.locked) session.command = if (dx < -limit) "cancel" else "send" }
                            else if (voice && !locked) { if (dx < -limit) cancelRec() else finishRec() }
                        }
                    }, contentAlignment = Alignment.Center) {
                    androidx.compose.animation.AnimatedContent(videoMode, label = "mode") { v ->
                        Icon(if (v) Icons.Filled.Videocam else Icons.Filled.Mic, null, tint = Color.White)
                    }
                }
            }
        }
        if (stickers && !recording) StickerPanel(onEmoji = { onText(text + it) }, onSticker = { s ->
            val r = takeReply(); scope.launch { AppModel.send(chatId, "sticker", s, replyTo = r) }
        }, onAnim = { e ->
            AppModel.premium { val r = takeReply(); scope.launch { AppModel.send(chatId, "sticker", e, meta = org.json.JSONObject().put("anim", true), replyTo = r) } }
        })
    }
}

private val EMOJI = "😀😃😄😁😆😅😂🤣😊😇🙂😉😍🥰😘😋😛😜🤪🤗🤔🤨😐😏😒🙄😬😌😔😴😷🤒🤧🥵🥶😎🤓🧐😕😟😮😲😳🥺😢😭😱😖😣😞😓😩😫🥱😤😡😠🤬😈💀💩🤡👻👽🤖😺😹😻🙈🙉🙊💋💌💘💝💖💗💓💞💕❣️💔❤️🧡💛💚💙💜🤎🖤🤍💯💥💫💦💨💬👋🤚🖐✋🖖👌🤌🤏✌️🤞🤟🤘🤙👈👉👆👇☝️👍👎✊👊🤛🤜👏🙌👐🤲🤝🙏💪🎉🎊🎁🔥⭐️🌟✨⚡️☀️🌙🌈❄️🍀🌹🌸🍕🍔🍟🍩🍰🎂☕️🍺🍷⚽️🏀🎮🎧🎵🚀✈️🚗🏠💡📱💻📷⏰✅❌❓❗️"
private val STICKERS = listOf("😂", "😍", "🥰", "😎", "🤔", "😭", "😡", "🥳", "😴", "🤯", "👍", "👏", "🙏", "💪", "🔥", "❤️", "💔", "🎉", "💯", "👋", "🐶", "🐱", "🦊", "🐼", "🐸", "🦄", "🌈", "⭐️", "🍕", "☕️")

private fun graphemes(s: String): List<String> {
    val it = java.text.BreakIterator.getCharacterInstance()
    it.setText(s)
    val out = mutableListOf<String>()
    var start = it.first(); var end = it.next()
    while (end != java.text.BreakIterator.DONE) { out.add(s.substring(start, end)); start = end; end = it.next() }
    return out
}

@Composable
private fun StickerPanel(onEmoji: (String) -> Unit, onSticker: (String) -> Unit, onAnim: (String) -> Unit = {}) {
    val p = P
    var tab by remember { mutableIntStateOf(0) }
    val emoji = remember { graphemes(EMOJI) }
    Column(Modifier.fillMaxWidth().height(270.dp)) {
        Row(Modifier.padding(horizontal = 10.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Pill("Эмодзи", tab == 0) { tab = 0 }
            Pill("Стикеры", tab == 1) { tab = 1 }
            Pill("Анимации ★", tab == 2) { tab = 2 }
        }
        androidx.compose.foundation.lazy.grid.LazyVerticalGrid(
            androidx.compose.foundation.lazy.grid.GridCells.Adaptive(if (tab == 0) 44.dp else 76.dp), Modifier.fillMaxSize().padding(horizontal = 6.dp),
        ) {
            val list = if (tab == 0) emoji else if (tab == 1) STICKERS else ANIMATED_EMOJI
            items(list.size) { i ->
                Box(Modifier.aspectRatio(1f).clip(RoundedCornerShape(10.dp)).clickable { if (tab == 0) onEmoji(list[i]) else if (tab == 1) onSticker(list[i]) else onAnim(list[i]) }, contentAlignment = Alignment.Center) {
                    if (tab == 2) AnimatedEmoji(list[i], 40.dp, tappable = false) else Text(list[i], fontSize = if (tab == 0) 26.sp else 46.sp)
                }
            }
        }
    }
}

/** Запись кружка: удержание кнопки или «без удержания» */
class NoteSession(locked: Boolean) {
    var locked by mutableStateOf(locked)
    var command by mutableStateOf<String?>(null)
}
