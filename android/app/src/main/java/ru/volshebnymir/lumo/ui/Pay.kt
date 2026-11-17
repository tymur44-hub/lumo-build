package ru.volshebnymir.lumo.ui

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONObject
import ru.volshebnymir.lumo.core.*

/**
 * Оплата внутри Lumo: окно без адресной строки и кнопок браузера — только крестик.
 * После оплаты ЮMoney возвращает на lumomess.ru/?lumo_paid=1 — окно закрывается само,
 * а статус заказа проверяется, пока люмены или Premium не будут зачислены.
 */
object Pay {
    const val RETURN = "https://lumomess.ru/?lumo_paid=1"
    const val RATE = 1.7
    var url by mutableStateOf<String?>(null)
    var buy by mutableStateOf(false)
    var plans by mutableStateOf<Pair<String?, Int>?>(null)
    var friend by mutableStateOf(false)
    /** растёт после каждой успешной оплаты — экраны перезагружают историю */
    var paidTick by mutableIntStateOf(0)
    private val watching = HashSet<String>()

    fun rub(v: Double): String {
        val f = java.text.NumberFormat.getNumberInstance(java.util.Locale("ru", "RU"))
        f.maximumFractionDigits = if (v == Math.rint(v)) 0 else 2
        f.minimumFractionDigits = f.maximumFractionDigits
        return f.format(v) + " ₽"
    }

    fun showPlans(to: String? = null, months: Int = 12) { plans = to to months }

    /** Создаёт заказ и открывает окно оплаты */
    suspend fun create(kind: String, qty: Int, to: String? = null) {
        try {
            val b = JSONObject().put("action", "create").put("kind", kind).put("qty", qty).put("return_url", RETURN)
            if (to != null) b.put("to", to)
            val r = Api.function("-yoomoney", b) as? JSONObject
            val u = r?.optString("url")?.takeIf { it.startsWith("https://") }
            if (u == null) { AppModel.say(r?.optString("error")?.takeIf { it.isNotEmpty() } ?: "Не удалось создать платёж"); return }
            open(u, r.optString("order_id").takeIf { it.isNotEmpty() }, to)
        } catch (e: Exception) {
            AppModel.say(e.message?.takeIf { it.isNotBlank() } ?: "Не удалось создать платёж, проверьте соединение")
        }
    }

    fun open(u: String, order: String?, to: String? = null) {
        url = u
        if (order != null) watch(order, to)
    }

    fun orderFrom(u: String): String? = runCatching { Uri.parse(u).getQueryParameter("label") }.getOrNull()

    private fun watch(order: String, to: String?) {
        if (!watching.add(order)) return
        AppModel.scope.launch {
            try {
                repeat(400) {
                    delay(3000)
                    val j = runCatching { Api.rpc("lm_pay_status", jsonOf("p_order" to order)) }.getOrNull() as? JSONObject ?: return@repeat
                    when (j.optString("status")) {
                        "paid" -> {
                            val q = j.optInt("qty")
                            if (j.optString("kind") == "prem") {
                                AppModel.loadMe()
                                AppModel.say(if (to == null) "Оплата прошла. Lumo Premium активирован" else "Оплата прошла. Premium подарен")
                            } else AppModel.say("Оплата прошла. Начислено $q ${lumenWord(q.toLong())}")
                            Lumens.load(); paidTick++
                            return@launch
                        }
                        "unknown" -> return@launch
                    }
                }
            } finally { watching.remove(order) }
        }
    }
}

@Composable
fun PayHost() {
    if (Pay.buy) BuyLumensDialog { Pay.buy = false }
    Pay.plans?.let { (to, m) -> PremiumPlansDialog(to, m) { Pay.plans = null } }
    if (Pay.friend) FriendPickDialog { Pay.friend = false }
    Pay.url?.let { u -> key(u) { PaySheet(u) { paid -> Pay.url = null; if (paid) AppModel.say("Платёж принят. Зачисляем…") } } }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
private fun PaySheet(start: String, onClose: (Boolean) -> Unit) {
    val p = P
    var web by remember { mutableStateOf<WebView?>(null) }
    var progress by remember { mutableIntStateOf(0) }
    fun close(paid: Boolean) { web?.destroy(); web = null; onClose(paid) }
    Dialog(onDismissRequest = { close(false) }, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        BackHandler { if (web?.canGoBack() == true) web?.goBack() else close(false) }
        Column(Modifier.fillMaxSize().background(p.bg).statusBarsPadding().navigationBarsPadding()) {
            Box(Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp)) {
                Box(Modifier.align(Alignment.CenterStart).size(38.dp).clip(CircleShape).background(p.panel2).bouncy { close(false) }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Close, "Закрыть", tint = p.text, modifier = Modifier.size(20.dp))
                }
                Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Оплата", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Lock, null, tint = p.muted, modifier = Modifier.size(11.dp))
                        Text("Банковская карта · ЮMoney", color = p.muted, fontSize = 12.sp, modifier = Modifier.padding(start = 3.dp))
                    }
                }
            }
            val pr by animateFloatAsState(progress / 100f, tween(200), label = "pp")
            Box(Modifier.fillMaxWidth().height(2.5.dp)) {
                if (progress in 1..99) Box(Modifier.fillMaxWidth(pr).fillMaxHeight().background(p.accent))
            }
            Box(Modifier.weight(1f).fillMaxWidth()) {
                AndroidView(factory = { c ->
                    WebView(c).apply {
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                        settings.loadWithOverviewMode = true
                        settings.useWideViewPort = true
                        setBackgroundColor(android.graphics.Color.TRANSPARENT)
                        webViewClient = object : WebViewClient() {
                            override fun shouldOverrideUrlLoading(view: WebView, req: WebResourceRequest): Boolean {
                                val u = req.url
                                // вернулись после оплаты — закрываем окно
                                if ((u.host ?: "").endsWith("lumomess.ru") && u.toString().contains("lumo_paid")) { close(true); return true }
                                if (u.scheme == "http" || u.scheme == "https") return false
                                // приложения банков (СБП, SberPay и т.п.)
                                runCatching {
                                    val i = if (u.scheme == "intent") Intent.parseUri(u.toString(), Intent.URI_INTENT_SCHEME) else Intent(Intent.ACTION_VIEW, u)
                                    c.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                                }
                                return true
                            }
                            override fun onPageStarted(view: WebView, url: String?, favicon: android.graphics.Bitmap?) {
                                val u = Uri.parse(url ?: "")
                                if ((u.host ?: "").endsWith("lumomess.ru") && (url ?: "").contains("lumo_paid")) { view.stopLoading(); close(true) }
                            }
                        }
                        webChromeClient = object : WebChromeClient() {
                            override fun onProgressChanged(view: WebView, newProgress: Int) { progress = newProgress }
                        }
                        loadUrl(start)
                        web = this
                    }
                }, modifier = Modifier.fillMaxSize())
                if (progress < 30) Column(Modifier.fillMaxSize().background(p.bg), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    LumenLive(46.dp)
                    Text("Открываем оплату…", color = p.muted, fontSize = 15.sp)
                }
            }
        }
    }
}

/** Стопка кристаллов: чем больше пакет, тем больше кристаллов */
@Composable
fun GemStack(n: Int, size: Dp = 24.dp) {
    Box(Modifier.width(size + (7 * (n - 1)).dp).height(size)) {
        for (i in n - 1 downTo 0) LumenIcon(size, Modifier.offset(x = (7 * i).dp))
    }
}

@Composable
private fun SheetDialog(onClose: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    val p = P
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        BackHandler { onClose() }
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.45f)).clickable(remember { MutableInteractionSource() }, null) { onClose() }, contentAlignment = Alignment.BottomCenter) {
            Column(Modifier.fillMaxWidth().fillMaxHeight(0.94f).clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)).background(p.bg)
                .clickable(remember { MutableInteractionSource() }, null) {}.navigationBarsPadding().imePadding(), content = content)
        }
    }
}

@Composable
private fun CloseBtn(onClose: () -> Unit) {
    val p = P
    Box(Modifier.size(38.dp).clip(CircleShape).background(p.panel2).bouncy(onClose), contentAlignment = Alignment.Center) {
        Icon(Icons.Filled.Close, "Закрыть", tint = p.text, modifier = Modifier.size(20.dp))
    }
}

@Composable
fun BuyLumensDialog(onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var more by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf<Int?>(null) }
    var custom by remember { mutableStateOf("") }
    LaunchedEffect(Unit) { Lumens.load() }
    fun pay(n: Int) {
        if (busy != null) return
        busy = n
        scope.launch { Pay.create("lum", n); busy = null }
    }
    SheetDialog(onClose) {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                CloseBtn(onClose)
                Spacer(Modifier.weight(1f))
                Column(horizontalAlignment = Alignment.End) {
                    Text("Баланс", color = p.muted, fontSize = 12.sp)
                    Row(verticalAlignment = Alignment.CenterVertically) { LumenIcon(15.dp); Spacer(Modifier.width(4.dp)); Text("${Lumens.balance}", color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp) }
                }
            }
            Box(Modifier.height(120.dp), contentAlignment = Alignment.Center) { LumenLive(54.dp) }
            Text("Купить люмены", color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp)
            Text("Выберите нужное количество", color = p.muted, fontSize = 15.sp, modifier = Modifier.padding(top = 4.dp, bottom = 12.dp))
            val packs = listOf(50 to 1, 100 to 2, 250 to 3, 500 to 4, 1000 to 5, 2500 to 6)
            val extra = listOf(1500 to 5, 5000 to 7)
            val list = if (more) (packs + extra).sortedBy { it.first } else packs
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(p.panel)) {
                list.forEachIndexed { i, (n, g) ->
                    if (i > 0) Box(Modifier.padding(start = 16.dp).fillMaxWidth().height(1.dp).background(p.line))
                    Row(Modifier.fillMaxWidth().clickable(enabled = busy == null) { pay(n) }.padding(horizontal = 16.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.width(70.dp)) { GemStack(g) }
                        Text("$n ${lumenWord(n.toLong())}", color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.5.sp, modifier = Modifier.weight(1f))
                        if (busy == n) CircularProgressIndicator(Modifier.size(20.dp), color = p.a1, strokeWidth = 2.dp)
                        else Text(Pay.rub(n * Pay.RATE), color = p.muted, fontSize = 15.5.sp)
                    }
                }
            }
            if (!more) Row(Modifier.padding(top = 10.dp).bouncy { more = true }.padding(6.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("Показать другие варианты", color = p.a1, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                Icon(Icons.Filled.KeyboardArrowDown, null, tint = p.a1, modifier = Modifier.size(18.dp))
            } else {
                val n = custom.toIntOrNull() ?: 0
                val ok = n >= 50 && n * Pay.RATE <= 10000
                Row(Modifier.padding(top = 12.dp).fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(p.panel).padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    LumenIcon(24.dp); Spacer(Modifier.width(10.dp))
                    Box(Modifier.weight(1f)) {
                        if (custom.isEmpty()) Text("Своё количество (от 50)", color = p.muted, fontSize = 16.sp)
                        BasicTextField(custom, { t -> custom = t.filter { it.isDigit() }.take(4) }, singleLine = true,
                            textStyle = TextStyle(color = p.text, fontSize = 16.5.sp, fontWeight = FontWeight.SemiBold), cursorBrush = SolidColor(p.a1),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number), modifier = Modifier.fillMaxWidth())
                    }
                    if (n > 0) Text(Pay.rub(n * Pay.RATE), color = p.muted, fontSize = 15.sp)
                }
                if (n > 0) {
                    Spacer(Modifier.height(10.dp))
                    GradientButton(if (ok) "Купить $n ${lumenWord(n.toLong())} за ${Pay.rub(n * Pay.RATE)}" else if (n < 50) "Минимум 50 люменов" else "Не больше 10 000 ₽ за раз", busy == n, ok) { pay(n) }
                }
            }
            Row(Modifier.padding(top = 14.dp, start = 6.dp, end = 6.dp)) {
                Icon(Icons.Filled.VerifiedUser, null, tint = Color(0xFF2BD67B), modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Оплата банковской картой через ЮMoney прямо в Lumo. Люмены зачисляются автоматически, обычно за минуту. 1 люмен = 1,7 ₽.", color = p.muted, fontSize = 13.sp)
            }
        }
    }
}

@Composable
fun PremiumPlansDialog(to: String?, months: Int, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var sel by remember { mutableIntStateOf(months) }
    var busy by remember { mutableStateOf(false) }
    val plans = listOf(Triple(12, 2490, "Год"), Triple(6, 1490, "Полгода"), Triple(1, 199, "Месяц"))
    SheetDialog(onClose) {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Row(Modifier.fillMaxWidth()) { CloseBtn(onClose) }
            Box(Modifier.size(110.dp).clip(CircleShape).background(Brush.radialGradient(listOf(Color(0x66A48BFF), Color.Transparent))), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Star, null, tint = Color(0xFF9B7BFF), modifier = Modifier.size(64.dp))
            }
            Text(if (to != null) "Premium в подарок" else if (AppModel.isPremium) "Продлить Lumo Premium" else "Lumo Premium", color = p.text, fontWeight = FontWeight.Black, fontSize = 24.sp)
            Text(if (to != null) "Для ${AppModel.displayName(to)} · выберите срок" else "Выберите срок подписки", color = p.muted, fontSize = 15.sp, modifier = Modifier.padding(top = 4.dp, bottom = 12.dp))
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(p.panel)) {
                plans.forEachIndexed { i, (m, price, title) ->
                    if (i > 0) Box(Modifier.padding(start = 54.dp).fillMaxWidth().height(1.dp).background(p.line))
                    Row(Modifier.fillMaxWidth().clickable { sel = m }.padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(if (sel == m) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null, tint = if (sel == m) p.a1 else p.muted.copy(alpha = 0.6f), modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(14.dp))
                        Column(Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(title, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.5.sp)
                                val badge = when (m) { 12 -> "−58%"; 6 -> "−38%"; else -> null }
                                if (badge != null) Text(badge, color = Color.White, fontWeight = FontWeight.Black, fontSize = 11.5.sp,
                                    modifier = Modifier.padding(start = 6.dp).clip(RoundedCornerShape(6.dp)).background(p.accent).padding(horizontal = 6.dp, vertical = 2.dp))
                            }
                            if (m > 1) Text("${Pay.rub(price.toDouble() / m)}/мес", color = p.muted, fontSize = 13.sp)
                        }
                        Text(Pay.rub(price.toDouble()), color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    }
                }
            }
            Spacer(Modifier.height(18.dp))
            val price = plans.first { it.first == sel }.second
            GradientButton("Оплатить ${Pay.rub(price.toDouble())}", busy) {
                busy = true
                scope.launch { Pay.create("prem", sel, to); busy = false }
            }
            Text(if (to != null) "Оплата картой через ЮMoney прямо в Lumo. Premium включится у получателя сразу после оплаты, он получит уведомление."
                 else "Оплата картой через ЮMoney прямо в Lumo. Premium включается автоматически сразу после оплаты.",
                color = p.muted, fontSize = 12.5.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 10.dp))
        }
    }
}

/** Выбор друга, которому отправить люмены */
@Composable
private fun FriendPickDialog(onClose: () -> Unit) {
    val p = P
    var q by remember { mutableStateOf("") }
    var to by remember { mutableStateOf<String?>(null) }
    to?.let { u -> LumenSendDialog(u) { to = null; onClose(); Pay.paidTick++ }; return }
    SheetDialog(onClose) {
        Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            CloseBtn(onClose)
            Text("Кому отправить люмены", color = p.text, fontWeight = FontWeight.Black, fontSize = 19.sp, modifier = Modifier.padding(start = 12.dp))
        }
        SearchBox(q, { q = it }, Modifier.padding(horizontal = 14.dp).fillMaxWidth())
        val list = AppModel.chats.filter { it.isPrivate && it.peerId != null && it.peerId != AppModel.myId && AppModel.profiles[it.peerId]?.isBot != true && (q.isBlank() || it.displayName.contains(q, true)) }
        LazyColumn(Modifier.weight(1f)) {
            if (list.isEmpty()) item { Text("Никого не найдено", color = p.muted, modifier = Modifier.fillMaxWidth().padding(24.dp), textAlign = TextAlign.Center) }
            items(list, key = { it.id }) { c ->
                Row(Modifier.fillMaxWidth().clickable { to = c.peerId }.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Avatar(c.displayName, c.displayAvatar, c.displayColor, 44.dp)
                    Spacer(Modifier.width(12.dp))
                    Text(c.displayName, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, modifier = Modifier.weight(1f))
                }
            }
        }
    }
}
