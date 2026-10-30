package ru.volshebnymir.lumo.ui

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.foundation.Canvas
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONObject
import ru.volshebnymir.lumo.core.*
import kotlin.math.cos
import kotlin.math.sin

object PhoneUi { var bind by mutableStateOf(false) }

private enum class PStep { Phone, Code, Name, Tfa, Done }

/** Номер → код → (имя) → (пароль двухэтапной защиты) → анимация успеха */
@Composable
fun PhoneAuthScreen(bind: Boolean, required: Boolean = false, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var step by remember { mutableStateOf(PStep.Phone) }
    var digits by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var tfaPwd by remember { mutableStateOf("") }
    var tfaHint by remember { mutableStateOf("") }
    var err by remember { mutableStateOf<String?>(null) }
    var note by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    var resend by remember { mutableStateOf(0) }
    val full = "7$digits"
    val purpose = if (bind) "bind" else "auth"
    val focus = remember { FocusRequester() }

    LaunchedEffect(resend) { if (resend > 0) { delay(1000); resend -= 1 } }
    LaunchedEffect(step) { if (step != PStep.Done) runCatching { focus.requestFocus() } }

    fun back() {
        err = null; note = null
        when (step) {
            PStep.Phone -> if (!required) onClose()
            PStep.Code -> { code = ""; step = PStep.Phone }
            PStep.Name, PStep.Tfa -> { code = ""; tfaPwd = ""; step = PStep.Code }
            PStep.Done -> {}
        }
    }
    BackHandler { back() }

    fun fail(j: JSONObject) {
        val c = j.str("error") ?: ""
        err = PhoneStore.message(c)
        if (c == "bad_code" || c == "expired" || c == "locked") code = ""
        if (c == "bad_tfa") tfaPwd = ""
    }

    var chan by remember { mutableStateOf("sms") }
    var tgLink by remember { mutableStateOf<String?>(null) }
    var tgDirect by remember { mutableStateOf(false) }
    val ctxp = androidx.compose.ui.platform.LocalContext.current
    fun openTg() { tgLink?.let { runCatching { ctxp.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(it)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) } } }

    fun sendCode(viaTg: Boolean = false) {
        if (digits.length != 10 || busy) return
        busy = true; err = null
        scope.launch {
            try {
                val body = jsonOf("phone" to full, "purpose" to purpose)
                if (viaTg) body.put("channel", "telegram")
                val j = PhoneStore.call("send", body, auth = bind)
                if (j.str("error") != null) fail(j) else {
                    code = ""; resend = 45; step = PStep.Code
                    chan = j.str("channel") ?: "sms"; tgLink = j.str("link"); tgDirect = j.bool("direct")
                    if (chan == "telegram" && !tgDirect) openTg()
                }
            } catch (e: Exception) { err = "Нет соединения. Попробуйте ещё раз" }
            busy = false
        }
    }

    fun verify(reset: Boolean = false, codeNow: String = code) {
        if (busy) return
        busy = true; err = null
        scope.launch {
            try {
                val body = jsonOf("phone" to full, "code" to codeNow, "purpose" to purpose)
                if (name.isNotBlank()) body.put("name", name.trim())
                if (tfaPwd.isNotEmpty()) body.put("tfa", tfaPwd)
                if (reset) body.put("reset_tfa", true)
                val j = PhoneStore.call("verify", body, auth = bind)
                val e = j.str("error")
                when {
                    e != null -> { fail(j); if (e == "expired" || e == "locked") step = PStep.Code }
                    j.bool("need_name") -> step = PStep.Name
                    j.bool("need_tfa") -> { tfaHint = j.str("hint") ?: ""; step = PStep.Tfa }
                    j.bool("reset_pending") -> note = "Запрос на сброс пароля принят. Сбросить его можно через 7 дней: повторите вход и нажмите «Забыли пароль» ещё раз."
                    bind -> {
                        step = PStep.Done
                        PhoneStore.load()
                        delay(1700); onClose()
                    }
                    j.str("token_hash") != null -> {
                        val th = j.str("token_hash")!!
                        step = PStep.Done
                        delay(1800)
                        AppModel.phoneLogin(th, j.bool("created"))
                        onClose()
                    }
                }
            } catch (e: Exception) { err = e.message ?: "Нет соединения. Попробуйте ещё раз" }
            busy = false
        }
    }

    Box(Modifier.fillMaxSize().background(p.bg)) {
        if (step == PStep.Done) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { SuccessBurst(if (bind) "Номер привязан" else "Готово") }
        } else Column(Modifier.fillMaxSize().statusBarsPadding().imePadding()) {
            Box(Modifier.padding(12.dp).height(44.dp)) {
                if (step != PStep.Phone || !required) RoundIcon(if (step == PStep.Phone) Icons.Filled.Close else Icons.AutoMirrored.Filled.ArrowBack) { back() }
            }
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Spacer(Modifier.height(16.dp))
                val ic: ImageVector = when (step) { PStep.Phone -> Icons.Filled.Phone; PStep.Code -> Icons.Filled.Sms; PStep.Name -> Icons.Filled.Person; else -> Icons.Filled.Lock }
                Box(Modifier.size(84.dp).clip(CircleShape).background(p.accent), contentAlignment = Alignment.Center) { Icon(ic, null, tint = Color.White, modifier = Modifier.size(38.dp)) }
                Text(when (step) {
                    PStep.Phone -> if (bind) "Привяжите номер телефона" else "Ваш номер телефона"
                    PStep.Code -> "Введите код"; PStep.Name -> "Как вас зовут?"; else -> "Пароль защиты"
                }, color = p.text, fontSize = 26.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
                Text(when (step) {
                    PStep.Phone -> if (bind) "Номер нужен для входа и защиты аккаунта. Видеть его можно ограничить в настройках." else "Мы отправим код в SMS или в Telegram. Если аккаунта с этим номером нет, он будет создан."
                    PStep.Code -> if (chan == "telegram") (if (tgDirect) "Код отправлен вам в Telegram (бот Lumo)" else "Откройте бота Lumo в Telegram, нажмите «Старт» и поделитесь номером — код придёт в чат") else "Код отправлен на " + PhoneStore.pretty(full)
                    PStep.Name -> "Это имя увидят ваши контакты. Его можно поменять позже."
                    else -> "Для аккаунта включена двухэтапная аутентификация. Введите пароль." + (if (tfaHint.isEmpty()) "" else "\nПодсказка: $tfaHint")
                }, color = p.muted, fontSize = 15.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 12.dp))
                Spacer(Modifier.height(4.dp))
                when (step) {
                    PStep.Phone -> {
                        Row(Modifier.fillMaxWidth().height(56.dp).clip(RoundedCornerShape(16.dp)).background(p.panel2).padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text("🇷🇺 +7", color = p.text, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
                            Spacer(Modifier.width(10.dp))
                            Box(Modifier.weight(1f)) {
                                val shown = formatDigits(digits)
                                if (digits.isEmpty()) Text("900 123-45-67", color = p.muted, fontSize = 20.sp)
                                BasicTextField(shown, { v ->
                                    var d = v.filter { it.isDigit() }
                                    if (d.length > 10 && (d.startsWith("7") || d.startsWith("8"))) d = d.drop(1)
                                    digits = d.take(10); err = null
                                }, singleLine = true, modifier = Modifier.fillMaxWidth().focusRequester(focus),
                                    textStyle = TextStyle(color = p.text, fontSize = 20.sp, fontWeight = FontWeight.SemiBold), cursorBrush = SolidColor(p.a1),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone))
                            }
                        }
                        GradientButton("Получить код", busy, digits.length == 10) { sendCode() }
                    }
                    PStep.Code -> {
                        Box(contentAlignment = Alignment.Center) {
                            BasicTextField(code, { v ->
                                code = v.filter { it.isDigit() }.take(5); err = null
                                if (code.length == 5) verify(codeNow = code)
                            }, modifier = Modifier.size(1.dp).alpha(0.01f).focusRequester(focus), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword))
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.clickable(remember { MutableInteractionSource() }, null) { runCatching { focus.requestFocus() } }) {
                                for (i in 0 until 5) {
                                    val ch = code.getOrNull(i)?.toString() ?: ""
                                    val sc by animateFloatAsState(if (i == code.length - 1) 1.08f else 1f, spring(0.5f, 500f), label = "c")
                                    Box(Modifier.size(width = 52.dp, height = 64.dp).graphicsScale(sc).clip(RoundedCornerShape(16.dp)).background(p.panel2)
                                        .border(2.dp, if (i == code.length) p.a1 else if (err != null) p.danger.copy(alpha = 0.6f) else Color.Transparent, RoundedCornerShape(16.dp)),
                                        contentAlignment = Alignment.Center) { Text(ch, color = p.text, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold) }
                                }
                            }
                        }
                        if (busy) CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.5.dp)
                        if (chan == "telegram" && !tgDirect && tgLink != null) GradientButton("Открыть Telegram", false, true) { openTg() }
                        if (chan == "sms") Text("Получить код в Telegram", color = p.a1, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.bouncy { sendCode(true) })
                        Text(if (resend > 0) "Отправить ещё раз через $resend с" else "Отправить код ещё раз",
                            color = if (resend > 0) p.muted else p.a1, fontWeight = FontWeight.SemiBold, modifier = Modifier.bouncy { if (resend == 0) sendCode() })
                        Text("Изменить номер", color = p.a1, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.bouncy { code = ""; err = null; step = PStep.Phone })
                    }
                    PStep.Name -> {
                        Box(Modifier.focusRequester(focus)) { LumoField(name, { name = it }, "Имя") }
                        GradientButton("Продолжить", busy, name.isNotBlank()) { verify() }
                    }
                    PStep.Tfa -> {
                        Box(Modifier.focusRequester(focus)) { LumoField(tfaPwd, { tfaPwd = it }, "Пароль", password = true) }
                        GradientButton("Войти", busy, tfaPwd.isNotEmpty()) { verify() }
                        Text("Забыли пароль?", color = p.a1, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.bouncy { verify(reset = true) })
                    }
                    PStep.Done -> {}
                }
                err?.let { Text(it, color = p.danger, fontSize = 14.sp, textAlign = TextAlign.Center) }
                note?.let { Text(it, color = p.muted, fontSize = 13.sp, textAlign = TextAlign.Center) }
                Spacer(Modifier.height(30.dp))
            }
        }
    }
}

private fun Modifier.graphicsScale(s: Float) = this.then(Modifier.graphicsLayer(scaleX = s, scaleY = s))

private fun formatDigits(d: String): String {
    val sb = StringBuilder()
    d.forEachIndexed { i, c ->
        if (i == 3) sb.append(' ') else if (i == 6 || i == 8) sb.append('-')
        sb.append(c)
    }
    return sb.toString()
}

/** Анимация после верного кода: круг рисуется, заливка, галочка, волны и искры */
@Composable
fun SuccessBurst(title: String) {
    val p = P
    val t = remember { Animatable(0f) }
    LaunchedEffect(Unit) { t.animateTo(1f, tween(1700, easing = LinearEasing)) }
    val v = t.value
    fun seg(a: Float, b: Float) = ((v - a) / (b - a)).coerceIn(0f, 1f)
    val fill = FastOutSlowInEasing.transform(seg(0.25f, 0.5f))
    val ring = FastOutSlowInEasing.transform(seg(0f, 0.3f))
    val check = FastOutSlowInEasing.transform(seg(0.4f, 0.65f))
    val a1 = p.a1; val a2 = p.a2
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
        Canvas(Modifier.size(300.dp)) {
            val c = center
            val r = 56.dp.toPx()
            for (i in 0 until 3) {
                val w = seg(0.3f + i * 0.1f, 0.85f + i * 0.05f)
                if (w > 0f) drawCircle(a1.copy(alpha = 0.5f * (1 - w)), radius = r * (1f + 1.4f * w), center = c, style = Stroke(3.dp.toPx()))
            }
            val sp = seg(0.3f, 0.8f)
            if (sp > 0f && sp < 1f) {
                val cols = listOf(a1, a2, Color(0xFFFFD54F), Color(0xFFFF6FB5))
                for (i in 0 until 14) {
                    val ang = i / 14.0 * 2 * Math.PI
                    val d = r * 0.9f + 90.dp.toPx() * sp
                    drawCircle(cols[i % 4].copy(alpha = 1 - sp), radius = (if (i % 2 == 0) 4.5.dp.toPx() else 3.dp.toPx()) * (1 - sp * 0.7f),
                        center = Offset(c.x + cos(ang).toFloat() * d, c.y + sin(ang).toFloat() * d))
                }
            }
            drawArc(a1, -90f, 360f * ring, false, topLeft = Offset(c.x - r, c.y - r), size = Size(r * 2, r * 2), style = Stroke(6.dp.toPx(), cap = StrokeCap.Round))
            if (fill > 0f) drawCircle(a1, radius = r * (0.2f + 0.8f * fill), center = c, alpha = fill)
            if (check > 0f) {
                val pts = listOf(Offset(c.x - 24.dp.toPx(), c.y + 2.dp.toPx()), Offset(c.x - 7.dp.toPx(), c.y + 19.dp.toPx()), Offset(c.x + 25.dp.toPx(), c.y - 17.dp.toPx()))
                val l1 = (pts[1] - pts[0]).getDistance(); val l2 = (pts[2] - pts[1]).getDistance()
                val cur = check * (l1 + l2)
                val path = androidx.compose.ui.graphics.Path().apply {
                    moveTo(pts[0].x, pts[0].y)
                    if (cur <= l1) { val f = cur / l1; lineTo(pts[0].x + (pts[1].x - pts[0].x) * f, pts[0].y + (pts[1].y - pts[0].y) * f) }
                    else { lineTo(pts[1].x, pts[1].y); val f = (cur - l1) / l2; lineTo(pts[1].x + (pts[2].x - pts[1].x) * f, pts[1].y + (pts[2].y - pts[1].y) * f) }
                }
                drawPath(path, Color.White, style = Stroke(8.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
            }
        }
        Text(title, color = p.text, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.alpha(fill))
    }
}

/** Напоминание: отсрочка на 7 дней один раз, потом привязка обязательна */
@Composable
fun PhoneReminderDialog() {
    val scope = rememberCoroutineScope()
    val first = PhoneStore.status == "remind"
    AlertDialog(
        onDismissRequest = { PhoneStore.reminderShown = true },
        title = { Text("Привяжите номер телефона") },
        text = { Text(if (first) "Теперь в Lumo можно входить по номеру и защитить аккаунт кодом. Привязать номер нужно в течение 7 дней."
            else "Привязать номер нужно до ${PhoneStore.skipText()}. После этого пользоваться Lumo без номера будет нельзя.") },
        confirmButton = { TextButton({ PhoneStore.reminderShown = true; PhoneUi.bind = true }) { Text("Привязать номер") } },
        dismissButton = { TextButton({ scope.launch { if (first) PhoneStore.skip(); PhoneStore.reminderShown = true } }) { Text(if (first) "Напомнить через 7 дней" else "Позже") } },
    )
}

@Composable
fun PhoneSettingsScreen() {
    val p = P
    LaunchedEffect(Unit) { PhoneStore.load() }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        TopBar("Номер телефона")
        Card {
            SettingsRow(Icons.Filled.Phone, Color(0xFF2BD67B), "Номер", PhoneStore.phone?.let { PhoneStore.pretty(it) } ?: "Не привязан") {}
            Divider()
            SettingsRow(Icons.Filled.Edit, p.a1, if (PhoneStore.phone == null) "Привязать номер" else "Изменить номер") { PhoneUi.bind = true }
            Divider()
            SettingsRow(Icons.Filled.Visibility, Color(0xFF5B6CFF), "Кто видит мой номер", privLabel(AppModel.me?.priv("phone") ?: "contacts")) { AppModel.push(Screen.PrivacyKey("phone")) }
        }
        Text("Номер нужен для входа и сверки контактов. Если выбрать «Никто», друзья не найдут вас по номеру в записной книжке.", color = p.muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 30.dp))
    }
}

@Composable
fun TwoFaScreen() {
    val p = P
    val scope = rememberCoroutineScope()
    var old by remember { mutableStateOf("") }
    var pwd by remember { mutableStateOf("") }
    var pwd2 by remember { mutableStateOf("") }
    var hint by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var msg by remember { mutableStateOf<String?>(null) }
    var confirmOff by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { PhoneStore.load() }
    val on = PhoneStore.tfa
    fun save() {
        if (pwd.length < 4) { msg = "Пароль — не меньше 4 символов"; return }
        if (pwd != pwd2) { msg = "Пароли не совпадают"; return }
        busy = true; msg = null
        scope.launch {
            try {
                Api.rpc("lm_tfa_set", jsonOf("p_old" to old, "p_new" to pwd, "p_hint" to hint))
                old = ""; pwd = ""; pwd2 = ""; hint = ""
                PhoneStore.load(); msg = "✓ Готово"
            } catch (e: Exception) { msg = e.message ?: "Ошибка" }
            busy = false
        }
    }
    if (confirmOff) AlertDialog(onDismissRequest = { confirmOff = false },
        title = { Text("Отключить защиту?") },
        text = { LumoField(old, { old = it }, "Пароль", password = true) },
        confirmButton = { TextButton({
            confirmOff = false; val o = old; old = ""
            scope.launch { try { Api.rpc("lm_tfa_remove", jsonOf("p_pwd" to o)); PhoneStore.load(); msg = "✓ Защита отключена" } catch (e: Exception) { msg = e.message ?: "Ошибка" } }
        }) { Text("Отключить") } },
        dismissButton = { TextButton({ confirmOff = false; old = "" }) { Text("Отмена") } })
    Column(Modifier.fillMaxSize().background(p.bg).imePadding().verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        TopBar("Двухэтапная защита")
        Box(Modifier.size(88.dp).clip(CircleShape).background(if (on) Color(0xFF2BD67B) else p.a1), contentAlignment = Alignment.Center) {
            Icon(if (on) Icons.Filled.Shield else Icons.Filled.LockOpen, null, tint = Color.White, modifier = Modifier.size(40.dp))
        }
        Text(if (on) "Защита включена" else "Двухэтапная аутентификация", color = p.text, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
        Text(if (on) "При входе на новом устройстве, кроме кода из SMS, нужно ввести ваш пароль."
            else "Задайте дополнительный пароль. Тогда даже тот, кто получит код из SMS, не сможет войти в ваш аккаунт.",
            color = p.muted, fontSize = 15.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 28.dp))
        if (PhoneStore.phone == null) Text("Сначала привяжите номер телефона", color = p.danger, fontWeight = FontWeight.SemiBold)
        else Column(Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (on) LumoField(old, { old = it }, "Текущий пароль", password = true)
            LumoField(pwd, { pwd = it }, if (on) "Новый пароль" else "Пароль (не меньше 4 символов)", password = true)
            LumoField(pwd2, { pwd2 = it }, "Повторите пароль", password = true)
            LumoField(hint, { hint = it }, "Подсказка (необязательно)")
            GradientButton(if (on) "Сменить пароль" else "Включить защиту", busy) { save() }
            if (on) Text("Отключить защиту", color = p.danger, fontWeight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.CenterHorizontally).padding(8.dp).bouncy { old = ""; confirmOff = true })
        }
        msg?.let { Text(it, color = if (it.startsWith("✓")) Color(0xFF2BD67B) else p.danger, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 24.dp)) }
        Spacer(Modifier.height(30.dp))
    }
}

/** Первый запуск: сразу просим всё, что понадобится приложению */
@Composable
fun PermissionsScreen(onDone: () -> Unit) {
    val p = P
    val perms = remember {
        buildList {
            if (Build.VERSION.SDK_INT >= 33) { add(Manifest.permission.POST_NOTIFICATIONS); add(Manifest.permission.READ_MEDIA_IMAGES); add(Manifest.permission.READ_MEDIA_VIDEO) }
            else add(Manifest.permission.READ_EXTERNAL_STORAGE)
            add(Manifest.permission.CAMERA); add(Manifest.permission.RECORD_AUDIO); add(Manifest.permission.READ_CONTACTS); add(Manifest.permission.WRITE_CONTACTS)
        }.toTypedArray()
    }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { onDone() }
    val items = listOf(
        Triple(Icons.Filled.Notifications, Color(0xFFFF5B5B), "Уведомления|Сообщения и звонки, когда Lumo свёрнут"),
        Triple(Icons.Filled.CameraAlt, Color(0xFF2B8CFF), "Камера|Фото, видеосообщения и видеозвонки"),
        Triple(Icons.Filled.Mic, Color(0xFFA35BFF), "Микрофон|Голосовые сообщения и звонки"),
        Triple(Icons.Filled.Photo, Color(0xFF2BD67B), "Фото и видео|Отправка и сохранение медиа"),
        Triple(Icons.Filled.People, Color(0xFFFF8A3D), "Контакты|Найти друзей, которые уже в Lumo"),
    )
    Column(Modifier.fillMaxSize().background(p.bg).statusBarsPadding().navigationBarsPadding()) {
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Spacer(Modifier.height(30.dp))
            Box(Modifier.size(84.dp).clip(RoundedCornerShape(26.dp)).background(p.accent), contentAlignment = Alignment.Center) { Icon(Icons.Filled.ChatBubble, null, tint = Color.White, modifier = Modifier.size(42.dp)) }
            Text("Добро пожаловать в Lumo", color = p.text, fontSize = 26.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
            Text("Чтобы всё работало сразу, разрешите доступ. Изменить его можно в настройках телефона.", color = p.muted, fontSize = 15.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 12.dp))
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(p.panel)) {
                items.forEachIndexed { i, it ->
                    if (i > 0) Divider()
                    val (t, s) = it.third.split("|")
                    Row(Modifier.padding(horizontal = 14.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(it.second), contentAlignment = Alignment.Center) { Icon(it.first, null, tint = Color.White, modifier = Modifier.size(19.dp)) }
                        Column { Text(t, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp); Text(s, color = p.muted, fontSize = 13.sp) }
                    }
                }
            }
        }
        Column(Modifier.padding(horizontal = 20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            GradientButton("Разрешить") { launcher.launch(perms) }
            Text("Не сейчас", color = p.muted, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(14.dp).bouncy { onDone() })
        }
    }
}

/** Контакты из записной книжки: кто в Lumo и кого можно пригласить */
@Composable
fun PhoneContactsSection() {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok ->
        if (ok) scope.launch { PhoneStore.syncContacts() } else PhoneStore.contactsDenied = true
    }
    LaunchedEffect(Unit) { if (PhoneStore.hasContactsAccess() && PhoneStore.matched.isEmpty() && PhoneStore.invites.isEmpty()) PhoneStore.syncContacts() }
    if (!PhoneStore.hasContactsAccess()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp).clip(RoundedCornerShape(18.dp)).background(p.panel)
            .bouncy {
                if (PhoneStore.contactsDenied) runCatching { ctx.startActivity(Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + ctx.packageName)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                else launcher.launch(Manifest.permission.READ_CONTACTS)
            }.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clip(CircleShape).background(Color(0xFFFF8A3D)), contentAlignment = Alignment.Center) { Icon(Icons.Filled.People, null, tint = Color.White) }
            Spacer(Modifier.width(12.dp))
            Column {
                Text("Найти друзей по контактам", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                Text(if (PhoneStore.contactsDenied) "Доступ закрыт — откройте настройки телефона" else "Разрешите доступ к контактам", color = p.muted, fontSize = 13.sp)
            }
        }
        return
    }
    if (PhoneStore.syncing && PhoneStore.matched.isEmpty() && PhoneStore.invites.isEmpty())
        Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.5.dp) }
    if (PhoneStore.matched.isNotEmpty()) {
        Text("В LUMO", color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 20.dp, top = 12.dp, bottom = 4.dp))
        PhoneStore.matched.forEach { m ->
            Row(Modifier.fillMaxWidth().clickable { AppModel.push(Screen.Person(m.id)) }.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Avatar(m.name, m.avatarUrl, m.color, 50.dp)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(m.name, color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    Text(if (m.bookName.isNotBlank() && m.bookName != m.name) "В контактах: ${m.bookName}" else "@" + m.username, color = p.muted, fontSize = 13.5.sp)
                }
            }
        }
    }
    if (PhoneStore.invites.isNotEmpty()) {
        Text("НЕ В LUMO — ПРИГЛАСИТЬ", color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 20.dp, top = 14.dp, bottom = 4.dp))
        PhoneStore.invites.take(300).forEach { c ->
            Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Avatar(c.name, null, (c.phone.hashCode() and 0x7fffffff) % 8, 46.dp)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(c.name, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, maxLines = 1)
                    Text(PhoneStore.pretty(c.phone), color = p.muted, fontSize = 13.sp)
                }
                Box(Modifier.clip(RoundedCornerShape(14.dp)).background(p.accent).bouncy {
                    val text = "Я в Lumo — напиши мне: " + AppModel.profileLink
                    runCatching { ctx.startActivity(Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:+" + c.phone)).putExtra("sms_body", text).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                }.padding(horizontal = 14.dp, vertical = 8.dp)) { Text("Пригласить", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp) }
            }
        }
    }
}
