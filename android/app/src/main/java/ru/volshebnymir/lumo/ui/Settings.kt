package ru.volshebnymir.lumo.ui

import android.content.Intent
import android.net.Uri
import android.provider.Settings
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
import androidx.compose.material.icons.automirrored.filled.CallMade
import androidx.compose.material.icons.automirrored.filled.CallReceived
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.premium
import ru.volshebnymir.lumo.core.PREMIUM_SOON
import ru.volshebnymir.lumo.core.isPremium
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.Screen

private fun share(ctx: android.content.Context, text: String) {
    runCatching { ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text), "Поделиться").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
}

@Composable
fun SectionTitle(t: String) {
    val p = P
    Text(t.uppercase(), color = p.muted, fontSize = 12.5.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 30.dp, top = 6.dp))
}

@Composable
fun SettingsScreen() {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val me = AppModel.me
    var confirm by remember { mutableStateOf(false) }
    var emojiDlg by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { AppModel.loadExtras() }
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { u ->
        if (u == null) return@rememberLauncherForActivityResult
        scope.launch {
            val d = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u)?.let { MediaUtil.jpeg(it) } } ?: return@launch
            runCatching { AppModel.setAvatar(d.first) }.onSuccess { AppModel.say("Фото обновлено") }.onFailure { AppModel.say(it.message ?: "Ошибка") }
        }
    }
    Column(Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Spacer(Modifier.height(4.dp))
        // шапка
        Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp))
            .background(Brush.linearGradient(listOf(p.a1.copy(alpha = 0.16f), p.a2.copy(alpha = 0.1f))))
            .border(1.dp, p.line, RoundedCornerShape(26.dp)).padding(vertical = 18.dp, horizontal = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.clickable { pick.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }) {
                Avatar(me?.name ?: "", me?.avatarUrl, me?.color ?: 0, 110.dp)
                Box(Modifier.align(Alignment.BottomEnd).size(34.dp).clip(CircleShape).background(p.bg).padding(3.dp).clip(CircleShape).background(p.a1), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.CameraAlt, null, tint = Color.White, modifier = Modifier.size(16.dp))
                }
            }
            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(me?.name ?: "", color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp)
                if (me?.verified == true) Icon(Icons.Filled.Verified, null, tint = p.a2, modifier = Modifier.padding(start = 6.dp).size(20.dp))
                if (me?.premium == true) { val es = me?.emojiStatus; Box(Modifier.padding(start = 6.dp).clip(CircleShape).clickable { emojiDlg = true }.padding(2.dp)) { if (es != null) StatusEmoji(es, 22.sp) else Icon(Icons.Filled.Star, null, tint = Color(0xFFFFB020), modifier = Modifier.size(20.dp)) } }
            }
            Text("@" + (me?.username ?: ""), color = p.muted, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            if (!me?.bio.isNullOrEmpty()) Text(me!!.bio, color = p.text, fontSize = 14.5.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 4.dp, start = 14.dp, end = 14.dp))
            Row(Modifier.padding(top = 10.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Chip(Icons.Filled.Edit, "Изменить профиль") { AppModel.push(Screen.MyProfile) }
                Chip(Icons.Filled.QrCode, "QR-код") { Ui.qrMine = true }
            }
        }
        AppModel.staffRole?.let { r ->
            Card {
                SettingsRow(Icons.Filled.Shield, Color(0xFFFF8A3D), "Админ-панель", (if (r == "owner") "Вы владелец Lumo" else "Вы администратор Lumo") + " · открывается на сайте") {
                    runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(ru.volshebnymir.lumo.core.Config.SITE)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                }
            }
        }
        if (emojiDlg) EmojiPickerDialog { emojiDlg = false }
        Card {
            SettingsRow(Icons.Filled.Star, Color(0xFF2A1B5E), "Lumo Premium", "Дополнительные возможности и боты", lead = { PremiumStar(34.dp) }) { AppModel.push(Screen.Premium) }
        }
        Card {
            SettingsRow(Icons.Filled.Person, p.a1, "Мой профиль", "Имя, юзернейм, о себе, пароль") { AppModel.push(Screen.MyProfile) }
            Divider()
            SettingsRow(Icons.Filled.Bookmark, Color(0xFF3A7BFF), "Избранное", "Заметки и сохранённые сообщения") { scope.launch { AppModel.myId?.let { AppModel.openDM(it) } } }
            Divider()
            SettingsRow(Icons.Filled.Call, Color(0xFF2BD67B), "Звонки", "Недавние и пропущенные") { AppModel.push(Screen.CallsHistory) }
            Divider()
            SettingsRow(Icons.Filled.Computer, Color(0xFFFF8A3D), "Устройства", "Войти на компьютере по QR-коду") { Ui.qrScan = true }
        }
        Card {
            SettingsRow(Icons.Filled.Notifications, Color(0xFFFF5B5B), "Уведомления и звуки", if (AppModel.tgLinked) "Telegram подключён" else "Telegram не подключён") { AppModel.push(Screen.Notifications) }
            Divider()
            SettingsRow(Icons.Filled.Lock, Color(0xFF5B6CFF), "Конфиденциальность", "Время захода, звонки, блокировки") { AppModel.push(Screen.Privacy) }
            Divider()
            SettingsRow(Icons.Filled.Palette, Color(0xFF22A6FF), "Оформление",
                (when (Look.theme) { "light" -> "Светлая тема"; "dark" -> "Тёмная тема"; else -> "Как в системе" }) + " · цвет, текст") { AppModel.push(Screen.Appearance) }
        }
        Card {
            SettingsRow(Icons.Filled.PersonAdd, Color(0xFFFF5B8A), "Пригласить друзей", "Поделиться ссылкой на ваш профиль") { share(ctx, "Я в Lumo — напиши мне: " + AppModel.profileLink) }
            Divider()
            SettingsRow(Icons.Filled.QrCodeScanner, p.a1, "Сканировать QR-код", "Открыть профиль человека или войти на компьютере") { Ui.qrScan = true }
            Divider()
            SettingsRow(Icons.Filled.Info, Color(0xFF8E8EA8), "О Lumo") { AppModel.push(Screen.About) }
        }
        Card {
            SettingsRow(Icons.AutoMirrored.Filled.Logout, Color(0xFFFF3B5C), "Выйти из аккаунта", titleColor = p.danger) { confirm = true }
        }
        Text("Lumo · бета-версия 1.6 для Android", color = p.muted, fontSize = 13.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Spacer(Modifier.height(110.dp))
    }
    if (confirm) AlertDialog(
        onDismissRequest = { confirm = false },
        confirmButton = { TextButton({ confirm = false; AppModel.logout() }) { Text("Выйти", color = p.danger) } },
        dismissButton = { TextButton({ confirm = false }) { Text("Отмена") } },
        title = { Text("Выйти из аккаунта на этом телефоне?") },
    )
}

@Composable
private fun Chip(icon: ImageVector, t: String, onClick: () -> Unit) {
    val p = P
    Row(Modifier.clip(RoundedCornerShape(20.dp)).background(p.panel2).bouncy(onClick).padding(horizontal = 12.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = p.text, modifier = Modifier.size(17.dp))
        Spacer(Modifier.width(6.dp))
        Text(t, color = p.text, fontWeight = FontWeight.Bold, fontSize = 14.sp, maxLines = 1, softWrap = false)
    }
}

// ---------------- звонки ----------------

@Composable
fun CallsHistoryScreen() {
    val p = P
    val call = rememberCallStarter()
    var loading by remember { mutableStateOf(true) }
    LaunchedEffect(Unit) { AppModel.loadCalls(); loading = false }
    val rows = AppModel.calls.mapNotNull { m -> AppModel.chat(m.chatId)?.takeIf { it.isPrivate }?.let { m to it } }
    Column(Modifier.fillMaxSize().background(p.bg)) {
        TopBar("Звонки")
        LazyColumn(Modifier.fillMaxSize()) {
            if (!loading && rows.isEmpty()) item {
                Text("Звонков пока нет.\nПозвонить можно из чата или из контактов", color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp))
            }
            items(rows, key = { it.first.id }) { (m, c) ->
                val out = m.senderId == AppModel.myId
                val st = m.metaStatus ?: ""
                val ok = st == "ended"
                val missed = !ok && !out && st != "rejected"
                var label = when { out -> if (ok) "Исходящий" else "Отменённый"; ok -> "Входящий"; st == "rejected" -> "Отклонённый"; else -> "Пропущенный" }
                label += (if (m.isVideoCall) " видеозвонок" else " звонок") + " · " + Fmt.listTime(m.createdAt)
                if (ok && m.duration > 0) label += " · " + Fmt.duration(m.duration)
                Row(Modifier.fillMaxWidth().clickable { AppModel.push(Screen.Chat(c.id)) }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(c.displayName, c.displayAvatar, c.displayColor, 50.dp, online = AppModel.isOnline(c.peerId))
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(c.displayName, color = if (missed) p.danger else p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(if (out) Icons.AutoMirrored.Filled.CallMade else Icons.AutoMirrored.Filled.CallReceived, null, tint = if (ok) p.ok else p.danger, modifier = Modifier.size(15.dp))
                            Spacer(Modifier.width(4.dp))
                            Text(label, color = p.muted, fontSize = 13.5.sp, maxLines = 1)
                        }
                    }
                    RoundIcon(if (m.isVideoCall) Icons.Filled.Videocam else Icons.Filled.Call, 40.dp, tint = p.a1, bg = p.panel2) { call(c, m.isVideoCall) }
                }
            }
        }
    }
}

// ---------------- уведомления ----------------

@Composable
fun NotificationsScreen() {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var keep by remember { mutableStateOf(AppModel.keepAlive) }
    LaunchedEffect(Unit) { AppModel.loadExtras() }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        TopBar("Уведомления и звуки")
        Card {
            Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(Color(0xFFFF5B5B)), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.NotificationsActive, null, tint = Color.White, modifier = Modifier.size(19.dp))
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text("Уведомления, когда Lumo свёрнут", color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    Text("Сообщения и звонки приходят сразу. Расходует больше батареи", color = p.muted, fontSize = 12.5.sp)
                }
                Switch(keep, { keep = it; AppModel.keepAlive = it }, colors = SwitchDefaults.colors(checkedTrackColor = p.a1))
            }
            Divider()
            SettingsRow(Icons.Filled.Settings, Color(0xFF8E8EA8), "Настройки уведомлений Android", "Звук, баннеры, значок на иконке") {
                runCatching { ctx.startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
            }
            Divider()
            SettingsRow(Icons.Filled.PhoneInTalk, Color(0xFF7C5CFF), "Звонки на заблокированном экране",
                if (ru.volshebnymir.lumo.core.Notifier.canFullScreen(ctx)) "Разрешено — экран включится, когда звонят" else "Не разрешено — нажмите, чтобы включить") { openFullScreenSettings(ctx) }
            Divider()
            SettingsRow(Icons.Filled.Layers, Color(0xFFFF8A3D), "Поверх других приложений",
                if (Settings.canDrawOverlays(ctx)) "Разрешено — звонок откроется сразу" else "Нужно, чтобы звонок открывался, когда Lumo свёрнут") { openOverlaySettings(ctx) }
            Divider()
            SettingsRow(Icons.Filled.BatteryChargingFull, Color(0xFF2BD67B), "Работа в фоне", "Отключите экономию батареи для Lumo, чтобы звонки не пропадали") {
                runCatching { ctx.startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:" + ctx.packageName)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                    .onFailure { runCatching { ctx.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } }
            }
        }
        SectionTitle("Telegram")
        Card {
            if (AppModel.tgLinked) {
                SettingsRow(Icons.Filled.Send, Color(0xFF2AABEE), "Уведомления в Telegram", "Подключено" + (AppModel.botName?.let { " · @$it" } ?: "")) {}
                Divider()
                SettingsRow(Icons.Filled.NotificationsOff, p.danger, "Отключить", titleColor = p.danger) { scope.launch { AppModel.telegramOff() } }
            } else {
                SettingsRow(Icons.Filled.Send, Color(0xFF2AABEE), "Подключить Telegram", "Бот пришлёт сообщения и звонки, даже когда Lumo закрыт") {
                    scope.launch {
                        val u = AppModel.telegramLink()
                        if (u == null) AppModel.say("Бот уведомлений ещё не подключён")
                        else runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(u)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                    }
                }
            }
        }
    }
}

// ---------------- конфиденциальность ----------------

/** Пункты конфиденциальности: ключ, название, вопрос, пояснение */
data class PrivItem(val key: String, val title: String, val question: String, val hint: String, val noneAllowed: Boolean = true)

val PRIVACY_ITEMS = listOf(
    PrivItem("seen", "Время захода", "Кто видит время моего последнего входа?", "Если вы скрываете время захода, вы тоже не увидите его у других. Вместо времени будет «был(а) недавно»."),
    PrivItem("photo", "Фотографии профиля", "Кто видит фотографию моего профиля?", "Те, кому фото недоступно, увидят цветной кружок с инициалами."),
    PrivItem("bio", "Раздел «О себе»", "Кто видит раздел «О себе»?", "Текст из раздела «О себе» в вашем профиле."),
    PrivItem("birthday", "День рождения", "Кто видит мой день рождения?", "Дата рождения в вашем профиле."),
    PrivItem("calls", "Звонки", "Кто может мне звонить?", "Остальные не смогут вам позвонить."),
    PrivItem("voice", "Голосовые сообщения", "Кто может присылать мне голосовые и видеосообщения?", "Остальные смогут писать только текстом."),
    PrivItem("messages", "Сообщения", "Кто может писать мне первым?", "Тем, с кем вы уже переписываетесь, ограничение не помешает ответить.", noneAllowed = false),
    PrivItem("invites", "Приглашения", "Кто может приглашать меня в группы и каналы?", "Вы можете выбрать, кому разрешаете приглашать Вас в группы и каналы."),
)

fun privLabel(v: String) = when (v) { "contacts" -> "Контакты"; "none" -> "Никто"; else -> "Все" }

@Composable
fun PrivacyScreen() {
    val p = P
    val me = AppModel.me
    LaunchedEffect(Unit) { AppModel.loadBlocks(); AppModel.loadMe() }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        TopBar("Конфиденциальность")
        Card {
            SettingsRow(Icons.Filled.Block, p.danger, "Заблокированные", if (AppModel.blockedByMe.isEmpty()) "Никого" else "${AppModel.blockedByMe.size}") { AppModel.push(Screen.Blocked) }
        }
        Spacer(Modifier.height(6.dp))
        Card {
            SettingsRow(Icons.Filled.Lock, p.a1, "Сквозное шифрование",
                if (ru.volshebnymir.lumo.core.E2E.status == ru.volshebnymir.lumo.core.E2E.Status.Ready) (if (ru.volshebnymir.lumo.core.E2E.backedUp) "Личные чаты · копия ключей сохранена" else "Личные чаты · задайте пароль копии") else "Личные чаты") {
                if (ru.volshebnymir.lumo.core.E2E.status == ru.volshebnymir.lumo.core.E2E.Status.Ready) ru.volshebnymir.lumo.core.E2E.promptBackup = true
            }
        }
        Spacer(Modifier.height(6.dp))
        var lockDlg by remember { mutableStateOf(false) }
        if (lockDlg) LockSettingsDialog { lockDlg = false }
        Card {
            SettingsRow(Icons.Filled.Lock, Color(0xFF5B6CFF), "Блокировка приложения", if (Extra.hasLock) "Включена" else "Код при входе в Lumo") { lockDlg = true }
        }
        Spacer(Modifier.height(6.dp))
        SectionTitle("Конфиденциальность")
        Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel)) {
            PRIVACY_ITEMS.forEachIndexed { i, it ->
                Row(Modifier.fillMaxWidth().clickable { AppModel.push(Screen.PrivacyKey(it.key)) }.padding(horizontal = 20.dp, vertical = 17.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Text(it.title, color = p.text, fontSize = 17.sp, modifier = Modifier.weight(1f))
                    Text(privLabel(me?.priv(it.key) ?: "all"), color = p.muted, fontSize = 16.sp)
                    Icon(Icons.Filled.ChevronRight, null, tint = p.muted.copy(alpha = 0.6f), modifier = Modifier.size(22.dp))
                }
                if (i < PRIVACY_ITEMS.size - 1) Box(Modifier.padding(start = 20.dp).fillMaxWidth().height(1.dp).background(p.line))
            }
        }
        Text("Вы можете выбрать, кому разрешаете приглашать Вас в группы и каналы.", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 30.dp))
        Spacer(Modifier.height(6.dp))
        val scopeP = rememberCoroutineScope()
        val msgPrem = me?.privacy?.optString("msg_prem") == "premium"
        Card {
            Row(Modifier.fillMaxWidth().clickable {
                if (!AppModel.isPremium) AppModel.say(PREMIUM_SOON)
                else scopeP.launch { AppModel.setPrivacyKey("msg_prem", if (msgPrem) "all" else "premium") }
            }.padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(Color(0xFFFFB020)), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Star, null, tint = Color.White, modifier = Modifier.size(19.dp))
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text("Писать мне только Premium", color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    Text("Люди без Lumo Premium не смогут написать первыми. Контакты и уже начатые переписки не затрагиваются.", color = p.muted, fontSize = 12.5.sp)
                }
                androidx.compose.material3.Switch(checked = msgPrem, onCheckedChange = null)
            }
        }
        Spacer(Modifier.height(30.dp))
    }
}

@Composable
fun PrivacyKeyScreen(key: String) {
    val p = P
    val scope = rememberCoroutineScope()
    val item = PRIVACY_ITEMS.firstOrNull { it.key == key } ?: return
    val cur = AppModel.me?.priv(key) ?: "all"
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        TopBar(item.title)
        SectionTitle(item.question)
        Column(Modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(p.panel).padding(horizontal = 6.dp)) {
            val opts = listOfNotNull("all", "contacts", "none".takeIf { item.noneAllowed })
            opts.forEachIndexed { i, v ->
                Radio(if (v == "contacts") "Мои контакты" else privLabel(v), null, cur == v) { scope.launch { AppModel.setPrivacyKey(key, v) } }
                if (i < opts.size - 1) Divider()
            }
        }
        Text(item.hint, color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 30.dp))
    }
}

@Composable
private fun Radio(title: String, subtitle: String?, on: Boolean, onClick: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp, horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            if (subtitle != null) Text(subtitle, color = p.muted, fontSize = 12.5.sp)
        }
        Icon(if (on) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null, tint = if (on) p.a1 else p.muted)
    }
}

@Composable
fun BlockedScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    LaunchedEffect(Unit) { AppModel.loadBlocks(); AppModel.loadProfiles(AppModel.blockedByMe.toList()) }
    Column(Modifier.fillMaxSize().background(p.bg)) {
        TopBar("Заблокированные")
        LazyColumn(Modifier.fillMaxSize()) {
            if (AppModel.blockedByMe.isEmpty()) item { Text("Вы никого не заблокировали", color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(40.dp)) }
            items(AppModel.blockedByMe.toList(), key = { it }) { id ->
                val pr = AppModel.profiles[id]
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(AppModel.displayName(id), pr?.avatarUrl, pr?.color ?: 0, 46.dp)
                    Spacer(Modifier.width(12.dp))
                    Text(AppModel.displayName(id), color = p.text, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    Text("Разблокировать", color = p.a1, fontWeight = FontWeight.Bold, modifier = Modifier.clickable { scope.launch { AppModel.setBlocked(id, false) } }.padding(8.dp))
                }
            }
        }
    }
}

// ---------------- жалоба ----------------

@Composable
fun ReportDialog(user: String?, chat: String?, message: Int?, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var reason by remember { mutableStateOf(ru.volshebnymir.lumo.core.ReportReason.spam) }
    var comment by remember { mutableStateOf("") }
    AlertDialog(onDismissRequest = onClose, title = { Text("Пожаловаться") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                Text("Жалобу увидит только администрация Lumo.", color = p.muted, fontSize = 13.sp)
                ru.volshebnymir.lumo.core.ReportReason.entries.forEach { r -> Radio(r.title, null, reason == r) { reason = r } }
                LumoField(comment, { comment = it.take(500) }, "Комментарий (необязательно)", singleLine = false)
            }
        },
        confirmButton = { TextButton({ scope.launch { if (AppModel.report(user, chat, message, reason, comment.trim())) onClose() } }) { Text("Отправить", color = p.danger) } },
        dismissButton = { TextButton(onClose) { Text("Отмена") } })
}


fun openOverlaySettings(ctx: android.content.Context) {
    runCatching { ctx.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + ctx.packageName)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
}

fun openFullScreenSettings(ctx: android.content.Context) {
    val i = if (android.os.Build.VERSION.SDK_INT >= 34) Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:" + ctx.packageName))
    else Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName)
    runCatching { ctx.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        .onFailure { runCatching { ctx.startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } }
}

/** Попросить разрешения, без которых звонок не откроется на заблокированном экране */
@Composable
fun FullScreenPrompt() {
    val ctx = LocalContext.current
    val prefs = remember { ctx.getSharedPreferences("lumo_prefs", android.content.Context.MODE_PRIVATE) }
    var step by remember { mutableStateOf(0) }
    val owner = androidx.compose.ui.platform.LocalLifecycleOwner.current
    // проверяем при каждом возвращении в приложение
    DisposableEffect(owner) {
        val obs = androidx.lifecycle.LifecycleEventObserver { _, e ->
            if (e == androidx.lifecycle.Lifecycle.Event.ON_RESUME) {
                step = when {
                    !ru.volshebnymir.lumo.core.Notifier.canFullScreen(ctx) && !prefs.getBoolean("fsi_asked2", false) -> 1
                    !Settings.canDrawOverlays(ctx) && !prefs.getBoolean("ovl_asked", false) -> 2
                    else -> 0
                }
            }
        }
        owner.lifecycle.addObserver(obs)
        onDispose { owner.lifecycle.removeObserver(obs) }
    }
    if (step == 1) AlertDialog(onDismissRequest = { step = 0; prefs.edit().putBoolean("fsi_asked2", true).apply() },
        title = { Text("Звонки на заблокированном экране") },
        text = { Text("Разрешите Lumo показывать входящий звонок на весь экран — тогда экран включится, и можно будет сразу ответить или отклонить.") },
        confirmButton = { TextButton({ step = 0; prefs.edit().putBoolean("fsi_asked2", true).apply(); openFullScreenSettings(ctx) }) { Text("Разрешить") } },
        dismissButton = { TextButton({ step = 0; prefs.edit().putBoolean("fsi_asked2", true).apply() }) { Text("Позже") } })
    if (step == 2) AlertDialog(onDismissRequest = { step = 0; prefs.edit().putBoolean("ovl_asked", true).apply() },
        title = { Text("Звонок поверх других приложений") },
        text = { Text("Включите для Lumo «Поверх других приложений» — тогда экран звонка откроется сразу, даже если Lumo свёрнут или телефон заблокирован.") },
        confirmButton = { TextButton({ step = 0; prefs.edit().putBoolean("ovl_asked", true).apply(); openOverlaySettings(ctx) }) { Text("Открыть настройки") } },
        dismissButton = { TextButton({ step = 0; prefs.edit().putBoolean("ovl_asked", true).apply() }) { Text("Позже") } })
}
