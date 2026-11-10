package ru.volshebnymir.lumo.ui

import android.annotation.SuppressLint
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONObject
import ru.volshebnymir.lumo.core.*

// ================= Мини-игры: броски в чате и игры вдвоём =================

object LumoGames {
    val titles = mapOf("ttt" to "Крестики-нолики", "checkers" to "Шашки", "sea" to "Морской бой")
    val descs = mapOf("ttt" to "Три в ряд на поле 3×3", "checkers" to "Русские шашки, взятие обязательно", "sea" to "Флот 10 кораблей, поле 10×10")
    val throws = listOf("dice" to "Кубик", "darts" to "Дартс", "basket" to "Баскетбол", "football" to "Футбол", "coin" to "Монетка")
    val colors = mapOf("ttt" to listOf(Color(0xFF22C1FF), Color(0xFF3A7BFF)), "checkers" to listOf(Color(0xFFA7743F), Color(0xFF6B4426)),
        "sea" to listOf(Color(0xFF2BB3FF), Color(0xFF1460C8)))
    fun label(k: String, v: Int) = when (k) {
        "dice" -> "Выпало $v"
        "darts" -> if (v == 6) "В яблочко!" else if (v == 1) "Мимо" else "Очков: $v"
        "basket" -> if (v >= 4) "Попал!" else "Мимо"
        "football" -> if (v >= 3) "Гол!" else "Мимо"
        else -> if (v == 1) "Орёл" else "Решка"
    }
    /** открытая игра — показывается поверх всего приложения */
    var open by mutableStateOf<String?>(null)
    val seen = HashSet<Int>()

    suspend fun call(body: JSONObject): JSONObject {
        val r = Api.raw("POST", "/functions/v1/lumo-games", body = body) as? JSONObject ?: JSONObject()
        if (r.has("error")) throw Exception(r.optString("error"))
        return r
    }
}

private fun DrawScope.dice(v: Int, s: Float) {
    val pips = mapOf(1 to listOf(.5f to .5f), 2 to listOf(.3f to .3f, .7f to .7f), 3 to listOf(.28f to .28f, .5f to .5f, .72f to .72f),
        4 to listOf(.3f to .3f, .7f to .3f, .3f to .7f, .7f to .7f), 5 to listOf(.28f to .28f, .72f to .28f, .5f to .5f, .28f to .72f, .72f to .72f),
        6 to listOf(.3f to .26f, .7f to .26f, .3f to .5f, .7f to .5f, .3f to .74f, .7f to .74f))[v] ?: emptyList()
    drawRoundRect(Color.Black.copy(alpha = .18f), Offset(s * .1f, s * .13f), Size(s * .8f, s * .8f), CornerRadius(s * .2f))
    drawRoundRect(Brush.linearGradient(listOf(Color.White, Color(0xFFDCD8F4)), Offset(s * .1f, s * .1f), Offset(s * .9f, s * .9f)),
        Offset(s * .1f, s * .1f), Size(s * .8f, s * .8f), CornerRadius(s * .2f))
    pips.forEach { (x, y) -> drawCircle(if (v == 1) Color(0xFFE0284F) else Color(0xFF25264A), s * .08f, Offset(s * x, s * y)) }
}

@Composable
fun ThrowArt(kind: String, v: Int, modifier: Modifier) {
    Canvas(modifier) {
        val s = size.minDimension
        when (kind) {
            "dice" -> dice(v, s)
            "darts" -> {
                val c = Offset(s / 2, s / 2)
                listOf(.42f to Color(0xFF25264A), .34f to Color(0xFFF2EFE4), .26f to Color(0xFFE0284F), .18f to Color(0xFFF2EFE4),
                    .1f to Color(0xFF2BB673), .04f to Color(0xFFE0284F)).forEach { (r, col) -> drawCircle(col, s * r, c) }
                val p = mapOf(6 to (.5f to .5f), 5 to (.56f to .42f), 4 to (.38f to .58f), 3 to (.66f to .64f), 2 to (.3f to .34f), 1 to (.88f to .14f))[v] ?: (.5f to .5f)
                val tip = Offset(s * p.first, s * p.second)
                rotate(-35f, tip) {
                    drawRoundRect(Color(0xFF5A5D86), Offset(tip.x - s * .016f, tip.y - s * .26f), Size(s * .032f, s * .24f), CornerRadius(s * .014f))
                    val path = androidx.compose.ui.graphics.Path().apply {
                        moveTo(tip.x, tip.y - s * .3f); lineTo(tip.x - s * .07f, tip.y - s * .38f); lineTo(tip.x + s * .07f, tip.y - s * .38f); close()
                    }
                    drawPath(path, Color(0xFF7C5CFF))
                }
            }
            "basket" -> {
                val ok = v >= 4
                drawRoundRect(Color(0xFFF2EFE4), Offset(s * .18f, s * .08f), Size(s * .64f, s * .4f), CornerRadius(s * .05f))
                drawRect(Color(0xFFE0284F), Offset(s * .38f, s * .22f), Size(s * .24f, s * .16f), style = Stroke(s * .025f))
                drawRoundRect(Color(0xFFFF6A2B), Offset(s * .3f, s * .41f), Size(s * .4f, s * .05f), CornerRadius(s * .025f))
                val bc = Offset(s * (if (ok) .5f else .76f), s * (if (ok) .62f else .76f))
                drawCircle(Color(0xFFFF8A3D), s * .13f, bc)
                drawLine(Color(0xFF7A2E0A), Offset(bc.x - s * .13f, bc.y), Offset(bc.x + s * .13f, bc.y), s * .016f)
                drawLine(Color(0xFF7A2E0A), Offset(bc.x, bc.y - s * .13f), Offset(bc.x, bc.y + s * .13f), s * .016f)
                drawCircle(Color(0xFF7A2E0A), s * .13f, bc, style = Stroke(s * .016f))
            }
            "football" -> {
                val ok = v >= 3
                val goal = androidx.compose.ui.graphics.Path().apply { moveTo(s * .1f, s * .7f); lineTo(s * .1f, s * .24f); lineTo(s * .9f, s * .24f); lineTo(s * .9f, s * .7f) }
                drawPath(goal, Color(0xFFF2EFE4), style = Stroke(s * .04f))
                drawRect(Color(0xFF2BB673).copy(alpha = .7f), Offset(0f, s * .8f), Size(s, s * .2f))
                val bc = Offset(s * (if (ok) .4f else .88f), s * (if (ok) .48f else .22f))
                drawCircle(Color.White, s * .12f, bc); drawCircle(Color(0xFF222222), s * .12f, bc, style = Stroke(s * .015f))
                drawCircle(Color(0xFF222222), s * .045f, bc)
            }
            else -> {
                drawCircle(Brush.radialGradient(listOf(Color(0xFFFFE7A1), Color(0xFFD79B22)), Offset(s * .35f, s * .3f), s * .5f), s * .4f, Offset(s / 2, s / 2))
                drawCircle(Color(0xFFB07A12), s * .4f, Offset(s / 2, s / 2), style = Stroke(s * .03f))
                drawCircle(Color(0xFFB07A12), s * .31f, Offset(s / 2, s / 2), style = Stroke(s * .012f, pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(4f, 6f))))
            }
        }
    }
    if (kind == "coin") Box(modifier, contentAlignment = Alignment.Center) {
        Text(if (v == 1) "О" else "Р", color = Color(0xFF8A5C08), fontWeight = FontWeight.Black, fontFamily = FontFamily.Serif, fontSize = 34.sp)
    }
}

/** Сообщение-бросок: свежие сообщения прилетают с анимацией */
@Composable
fun ThrowBubble(m: Message, mine: Boolean) {
    val p = P
    val k = m.meta.optString("g", "dice"); val v = m.meta.optInt("v", 1)
    val fresh = remember(m.id) { val f = !LumoGames.seen.contains(m.id) && System.currentTimeMillis() - m.createdAt.time < 6000; LumoGames.seen.add(m.id); f }
    val t = remember(m.id) { Animatable(if (fresh) 0f else 1f) }
    LaunchedEffect(m.id) { if (fresh) t.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 140f)) }
    Column(Modifier.width(168.dp).clip(RoundedCornerShape(18.dp)).background(if (mine) p.accent else SolidColor(p.panel)).padding(start = 10.dp, end = 10.dp, top = 8.dp, bottom = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally) {
        val a = t.value
        ThrowArt(k, v, Modifier.size(132.dp).graphicsLayer {
            if (k == "coin") rotationY = (1 - a) * 1440f else rotationZ = (1 - a) * -200f
            translationY = (1 - a) * -30.dp.toPx(); scaleX = .6f + .4f * a; scaleY = .6f + .4f * a; alpha = (.2f + .8f * a).coerceIn(0f, 1f)
        })
        Text(LumoGames.label(k, v), color = if (mine) Color.White else p.text, fontWeight = FontWeight.Black, fontSize = 15.sp,
            modifier = Modifier.graphicsLayer { alpha = ((a - .85f) / .15f).coerceIn(0f, 1f) })
        Text(fmtTime(m), color = if (mine) Color.White.copy(alpha = .7f) else p.muted, fontSize = 11.sp, modifier = Modifier.align(Alignment.End))
    }
}

private fun fmtTime(m: Message): String = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(m.createdAt)

@Composable
fun GameIcon(kind: String, size: Int = 46) {
    Box(Modifier.size(size.dp).clip(RoundedCornerShape((size * .3f).dp)).background(Brush.linearGradient(LumoGames.colors[kind] ?: listOf(Color(0xFF7C5CFF), Color(0xFF22C1FF)))),
        contentAlignment = Alignment.Center) {
        when (kind) {
            "ttt" -> Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Close, null, tint = Color.White, modifier = Modifier.size((size * .36f).dp))
                Icon(Icons.Filled.RadioButtonUnchecked, null, tint = Color.White, modifier = Modifier.size((size * .3f).dp))
            }
            "checkers" -> Canvas(Modifier.size((size * .62f).dp)) {
                val s = this.size.minDimension
                drawCircle(Color(0xFF2A1A10), s / 2, Offset(s / 2, s / 2 + s * .1f)); drawCircle(Color(0xFFF4EAD6), s / 2, Offset(s / 2, s / 2))
                drawCircle(Color(0xFFC9A46A), s * .28f, Offset(s / 2, s / 2), style = Stroke(s * .05f))
            }
            else -> Icon(Icons.Filled.DirectionsBoat, null, tint = Color.White, modifier = Modifier.size((size * .5f).dp))
        }
    }
}

/** Карточка игры вдвоём в чате */
@Composable
fun GameBubble(m: Message, mine: Boolean) {
    val p = P
    val mt = m.meta; val k = mt.optString("g", "ttt"); val st = mt.optString("st", "invite"); val me = AppModel.myId
    fun s(key: String) = if (mt.has(key) && !mt.isNull(key)) mt.optString(key) else null
    val p1 = s("p1"); val p2 = s("p2")
    val player = me != null && (me == p1 || me == p2)
    val btn = when (st) {
        "invite" -> if (p1 != me && m.senderId != me) "Принять" else "Открыть"
        "active", "setup" -> if (player) "Играть" else "Смотреть"
        else -> "Посмотреть"
    }
    val status = when (st) {
        "invite" -> if (p1 == me) "Ждём соперника" else "Приглашение сыграть"
        "setup" -> "Расстановка кораблей"
        "active" -> "Идёт игра"
        "declined" -> "Приглашение отклонено"
        "canceled" -> "Игра отменена"
        else -> s("winner")?.let { if (it == me) "Вы победили" else "Победил(а) " + (s("wn") ?: "") } ?: "Ничья"
    }
    val fg = if (mine) Color.White else p.text
    Column(Modifier.width(270.dp).clip(RoundedCornerShape(18.dp)).background(if (mine) p.accent else SolidColor(p.panel)).padding(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            GameIcon(k); Spacer(Modifier.width(11.dp))
            Column {
                Text(LumoGames.titles[k] ?: "Игра", color = fg, fontWeight = FontWeight.Bold, fontSize = 15.5.sp)
                Text(status, color = fg.copy(alpha = .8f), fontSize = 13.sp)
            }
        }
        Row(Modifier.padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(s("p1n") ?: AppModel.displayName(m.senderId), color = fg, fontWeight = FontWeight.Bold, fontSize = 13.5.sp, maxLines = 1)
            Text("  VS  ", color = fg.copy(alpha = .6f), fontWeight = FontWeight.Black, fontSize = 11.sp)
            Text(if (p2 == null) "ждём соперника" else s("p2n") ?: "", color = fg.copy(alpha = if (p2 == null) .7f else 1f),
                fontWeight = if (p2 == null) FontWeight.Normal else FontWeight.Bold, fontSize = 13.5.sp, maxLines = 1, modifier = Modifier.weight(1f))
            val stake = mt.optInt("stake", 0)
            if (stake > 0) {
                Icon(Icons.Filled.Diamond, null, tint = Color(0xFFF5B942), modifier = Modifier.size(13.dp))
                Text(" $stake", color = Color(0xFFF5B942), fontWeight = FontWeight.Black, fontSize = 13.5.sp)
            }
        }
        Box(Modifier.padding(top = 10.dp).fillMaxWidth().height(40.dp).clip(RoundedCornerShape(12.dp))
            .background(if (mine) SolidColor(Color.White.copy(alpha = .18f)) else if (btn == "Посмотреть") SolidColor(p.panel2) else p.accent)
            .bouncy { s("game")?.let { LumoGames.open = it } }, contentAlignment = Alignment.Center) {
            Text(btn, color = if (!mine && btn == "Посмотреть") p.text else Color.White, fontWeight = FontWeight.Black, fontSize = 14.5.sp)
        }
        Text(fmtTime(m), color = fg.copy(alpha = .6f), fontSize = 11.sp, modifier = Modifier.align(Alignment.End).padding(top = 4.dp))
    }
}

/** Меню игр: броски в чат и приглашение сыграть вдвоём со ставкой */
@Composable
fun GamesDialog(chatId: String, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var game by remember { mutableStateOf("ttt") }
    var stake by remember { mutableStateOf(0) }
    var custom by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    Dialog(onClose, DialogProperties(usePlatformDefaultWidth = false)) {
        Column(Modifier.fillMaxWidth().fillMaxHeight(.92f).clip(RoundedCornerShape(topStart = 26.dp, topEnd = 26.dp)).background(p.bg).navigationBarsPadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("Игры", color = p.text, fontWeight = FontWeight.Bold, fontSize = 19.sp, modifier = Modifier.weight(1f))
                Box(Modifier.size(36.dp).clip(CircleShape).background(p.panel2).clickable { onClose() }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Close, null, tint = p.text, modifier = Modifier.size(18.dp))
                }
            }
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp)) {
                @Composable fun hdr(t: String) = Text(t, color = p.muted, fontWeight = FontWeight.Black, fontSize = 12.sp, modifier = Modifier.padding(top = 14.dp, bottom = 8.dp))
                hdr("БРОСИТЬ В ЧАТ")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    LumoGames.throws.forEach { (k, name) ->
                        Column(Modifier.weight(1f).clip(RoundedCornerShape(16.dp)).background(p.panel2).bouncy {
                            onClose()
                            scope.launch { runCatching { Api.rpc("lm_throw", JSONObject().put("p_chat", chatId).put("p_kind", k)) }.onFailure { AppModel.say(it.message ?: "Ошибка") } }
                        }.padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            ThrowArt(k, when (k) { "dice" -> 5; "coin" -> 1; "darts" -> 6; else -> 5 }, Modifier.size(40.dp))
                            Text(name, color = p.text, fontWeight = FontWeight.Bold, fontSize = 11.sp, maxLines = 1, modifier = Modifier.padding(top = 6.dp))
                        }
                    }
                }
                hdr("ИГРАТЬ ВДВОЁМ")
                listOf("ttt", "checkers", "sea").forEach { k ->
                    Row(Modifier.padding(bottom = 8.dp).fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel2)
                        .border(2.dp, if (game == k) p.a1 else Color.Transparent, RoundedCornerShape(16.dp)).clickable { game = k }.padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        GameIcon(k, 44); Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(LumoGames.titles[k]!!, color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                            Text(LumoGames.descs[k]!!, color = p.muted, fontSize = 12.5.sp)
                        }
                        if (game == k) Icon(Icons.Filled.CheckCircle, null, tint = p.a1, modifier = Modifier.size(22.dp))
                    }
                }
                hdr("СТАВКА ЛЮМЕНАМИ")
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    listOf(0, 10, 50, 100, 500).forEach { v ->
                        val on = stake == v && custom.isEmpty()
                        Row(Modifier.clip(RoundedCornerShape(12.dp)).background(if (on) p.accent else SolidColor(p.panel2)).clickable { stake = v; custom = "" }
                            .padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                            if (v > 0) { Icon(Icons.Filled.Diamond, null, tint = if (on) Color.White else p.text, modifier = Modifier.size(12.dp)); Spacer(Modifier.width(4.dp)) }
                            Text(if (v == 0) "Без ставки" else "$v", color = if (on) Color.White else p.text, fontWeight = FontWeight.Bold, fontSize = 13.5.sp)
                        }
                    }
                    Box(Modifier.width(80.dp).clip(RoundedCornerShape(12.dp)).background(p.panel2).padding(horizontal = 10.dp, vertical = 8.dp)) {
                        if (custom.isEmpty()) Text("Своя", color = p.muted, fontWeight = FontWeight.Bold, fontSize = 13.5.sp)
                        BasicTextField(custom, { v -> val d = v.filter { it.isDigit() }.take(4); val n = minOf(d.toIntOrNull() ?: 0, 1000)
                            custom = if (d.isEmpty()) "" else "$n"; if (custom.isNotEmpty()) stake = n },
                            textStyle = TextStyle(color = p.text, fontWeight = FontWeight.Bold, fontSize = 13.5.sp), singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number), cursorBrush = SolidColor(p.a1))
                    }
                }
                Text("Ставку вносят оба игрока, победитель забирает обе. При ничьей ставки возвращаются. Если соперник не примет приглашение, ставку можно вернуть отменой. Максимум — 1000 люменов.",
                    color = p.muted, fontSize = 12.5.sp, lineHeight = 17.sp, modifier = Modifier.padding(top = 8.dp, bottom = 12.dp))
            }
            Row(Modifier.padding(16.dp).fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(p.accent).bouncy {
                if (busy) return@bouncy
                busy = true
                scope.launch {
                    try {
                        val g = LumoGames.call(JSONObject().put("action", "new").put("chat_id", chatId).put("kind", game).put("stake", stake))
                        onClose(); AppModel.say("Приглашение отправлено")
                        g.optString("id").takeIf { it.isNotEmpty() }?.let { delay(300); LumoGames.open = it }
                    } catch (e: Exception) { AppModel.say(e.message ?: "Ошибка") }
                    busy = false
                }
            }, horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                if (busy) CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
                else {
                    Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White, modifier = Modifier.size(20.dp)); Spacer(Modifier.width(8.dp))
                    Text("Пригласить" + if (stake > 0) " · ставка $stake" else "", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                }
            }
        }
    }
}

/** Экран игры вдвоём: общая страница игр в WebView */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun GameOverlay() {
    val id = LumoGames.open ?: return
    val p = P
    var token by remember(id) { mutableStateOf<String?>(null) }
    LaunchedEffect(id) { token = runCatching { Api.token() }.getOrNull(); if (token == null) LumoGames.open = null }
    val close = { LumoGames.open = null }
    BackHandler { close() }
    val dark = p.bg.luminance() < .5f
    Dialog(onDismissRequest = { close() }, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        val t = token
        if (t == null) Box(Modifier.fillMaxSize().background(p.bg), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = p.muted) }
        else AndroidView({ c ->
            WebView(c).apply {
                setBackgroundColor(android.graphics.Color.TRANSPARENT)
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                addJavascriptInterface(object { @JavascriptInterface fun leave() { post { close() } } }, "LumoBridge")
                val conf = JSONObject().put("api", Net.base + "/functions/v1/lumo-games").put("apikey", Config.ANON).put("token", t)
                    .put("gameId", id).put("theme", if (dark) "dark" else "light")
                val html = (ru.volshebnymir.lumo.core.RemoteConfig.gamesHtml() ?: c.assets.open("games.html").bufferedReader().use { it.readText() }).replace("/*CFG*/", "window.LUMO_GAME=$conf;")
                loadDataWithBaseURL("https://lumomess.ru/", html, "text/html", "utf-8", null)
            }
        }, Modifier.fillMaxSize().background(p.bg).systemBarsPadding())
    }
}
