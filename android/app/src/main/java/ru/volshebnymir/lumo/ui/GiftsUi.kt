package ru.volshebnymir.lumo.ui

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.webkit.WebView
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import ru.volshebnymir.lumo.core.*

data class Gift(val id: String, val name: String, val rarity: String, val price: Int, val supply: Int, val sold: Int) {
    val left get() = (supply - sold).coerceAtLeast(0)
}
data class OwnedGift(val id: Long, val giftId: String, val name: String, val rarity: String, val serial: Int, val supply: Int, val from: String?, val at: String? = null)

fun rarityName(r: String) = when (r) { "rare" -> "Редкий"; "epic" -> "Эпический"; "legendary" -> "Легендарный"; "mythic" -> "Мифический"; else -> r }
fun rarityColor(r: String) = when (r) { "rare" -> Color(0xFF22C7E0); "epic" -> Color(0xFFFF8A3D); "legendary" -> Color(0xFFB069FF); "mythic" -> Color(0xFFFFC247); else -> Color.Gray }

object Gifts {
    val catalog = mutableStateListOf<Gift>()
    val mine = mutableStateListOf<OwnedGift>()
    val of = mutableStateMapOf<String, List<OwnedGift>>()

    private fun parse(a: JSONArray?) = a.objects().map {
        OwnedGift(it.optLong("id"), it.optString("gift_id"), it.optString("name"), it.optString("rarity"), it.optInt("serial"), it.optInt("supply"), it.str("from_user"), it.str("at"))
    }

    suspend fun load() {
        val a = runCatching { Api.rpc("lm_gift_list") as? JSONArray }.getOrNull() ?: return
        val l = a.objects().map { Gift(it.optString("id"), it.optString("name"), it.optString("rarity"), it.optInt("price"), it.optInt("supply"), it.optInt("sold")) }
        catalog.clear(); catalog.addAll(l)
        loadUser(null)
    }

    suspend fun loadUser(user: String?) {
        val a = runCatching { Api.rpc("lm_gift_mine", if (user == null) jsonOf() else jsonOf("p_user" to user)) as? JSONArray }.getOrNull() ?: return
        val l = parse(a)
        if (user == null || user == AppModel.myId) { mine.clear(); mine.addAll(l) }
        of[user ?: AppModel.myId ?: ""] = l
    }

    suspend fun buy(giftId: String, to: String?): String {
        val r = Api.rpc("lm_gift_buy", if (to == null) jsonOf("p_gift" to giftId) else jsonOf("p_gift" to giftId, "p_to" to to))
        Lumens.load(); load()
        if (to != null) loadUser(to)
        return (r as? org.json.JSONObject)?.optInt("serial")?.toString() ?: ""
    }
}

@Composable
fun GiftThumb(id: String, modifier: Modifier = Modifier) {
    val ctx = LocalContext.current
    val bmp = remember(id) { runCatching { ctx.assets.open("gifts/$id.png").use { BitmapFactory.decodeStream(it) }?.asImageBitmap() }.getOrNull() }
    if (bmp != null) Image(bmp, null, modifier.clip(RoundedCornerShape(20.dp)), contentScale = ContentScale.Crop)
    else Box(modifier.clip(RoundedCornerShape(20.dp)).background(Color.Gray.copy(alpha = 0.3f)))
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun GiftAnimated(id: String, modifier: Modifier = Modifier) {
    val ctx = LocalContext.current
    val html = remember(id) {
        val svg = runCatching { ctx.assets.open("gifts/$id.svg").bufferedReader().use { it.readText() } }.getOrDefault("")
        "<html><head><meta name='viewport' content='width=device-width,initial-scale=1'><style>html,body{margin:0;height:100%;background:transparent;overflow:hidden}svg{width:100%;height:100%;display:block}</style></head><body>$svg</body></html>"
    }
    AndroidView(factory = { c ->
        WebView(c).apply {
            setBackgroundColor(android.graphics.Color.TRANSPARENT)
            isVerticalScrollBarEnabled = false; isHorizontalScrollBarEnabled = false
            isClickable = false; isLongClickable = false
            loadDataWithBaseURL(null, html, "text/html", "utf-8", null)
        }
    }, modifier = modifier.clip(RoundedCornerShape(26.dp)))
}

@Composable
private fun RarityBadge(r: String) {
    val c = rarityColor(r)
    Box(Modifier.clip(RoundedCornerShape(10.dp)).background(c.copy(alpha = 0.18f)).border(1.dp, c.copy(alpha = 0.6f), RoundedCornerShape(10.dp)).padding(horizontal = 8.dp, vertical = 3.dp)) {
        Text(rarityName(r).uppercase(), color = c, fontSize = 10.5.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun GiftCard(g: Gift, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val p = P
    Column(modifier.clip(RoundedCornerShape(24.dp)).background(p.panel).bouncy(onClick).padding(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        GiftThumb(g.id, Modifier.fillMaxWidth().aspectRatio(1f))
        Spacer(Modifier.height(8.dp))
        Text(g.name, color = p.text, fontWeight = FontWeight.Bold, fontSize = 15.sp, textAlign = TextAlign.Center)
        Spacer(Modifier.height(4.dp))
        RarityBadge(g.rarity)
        Spacer(Modifier.height(6.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            LumenIcon(16.dp); Spacer(Modifier.width(4.dp))
            Text(if (g.left > 0) "${g.price}" else "Раскуплено", color = p.text, fontWeight = FontWeight.Black, fontSize = 15.sp)
        }
        Text("${g.left} из ${g.supply}", color = p.muted, fontSize = 12.sp)
    }
}

/** Карточка подарка с анимацией; to — получатель (null = купить себе) */
@Composable
fun GiftDetailDialog(g: Gift, to: String?, onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var busy by remember { mutableStateOf(false) }
    var done by remember { mutableStateOf<String?>(null) }
    val owner = AppModel.staffRole == "owner"
    if (done != null) { GiftCelebration(g.id, to, g.name, done!!.toIntOrNull() ?: 0, g.supply, onClose); return }
    Dialog(onDismissRequest = { if (!busy) onClose() }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.6f)).clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) { if (!busy) onClose() }, contentAlignment = Alignment.Center) {
            GlassCard(Modifier.padding(18.dp).widthIn(max = 380.dp).clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) {}) {
                Column(Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    GiftAnimated(g.id, Modifier.fillMaxWidth().aspectRatio(1f))
                    Spacer(Modifier.height(12.dp))
                    if (done != null) {
                        Text("Готово!", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Black)
                        Text(if (to != null) "${g.name} №$done подарен: ${AppModel.displayName(to)}" else "${g.name} №$done теперь у вас",
                            color = Color.White.copy(alpha = 0.85f), fontSize = 15.sp, textAlign = TextAlign.Center)
                        LaunchedEffect(Unit) { delay(1900); onClose() }
                    } else {
                        RarityBadge(g.rarity)
                        Spacer(Modifier.height(6.dp))
                        Text("Осталось ${g.left} из ${g.supply}", color = Color.White.copy(alpha = 0.75f), fontSize = 13.sp)
                        if (to != null) Text("Получатель: ${AppModel.displayName(to)}", color = Color.White.copy(alpha = 0.75f), fontSize = 13.sp)
                        Spacer(Modifier.height(12.dp))
                        Box(Modifier.fillMaxWidth().height(54.dp).clip(RoundedCornerShape(20.dp)).background(if (g.left > 0) p.accent else Brush.linearGradient(listOf(Color.Gray, Color.DarkGray)))
                            .border(1.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(20.dp)).bouncy {
                                if (busy || g.left <= 0) return@bouncy
                                busy = true
                                scope.launch {
                                    try { done = Gifts.buy(g.id, to) } catch (e: Exception) { AppModel.say(e.message ?: "Ошибка"); busy = false }
                                }
                            }, contentAlignment = Alignment.Center) {
                            if (busy) androidx.compose.material3.CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.5.dp)
                            else Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(if (g.left <= 0) "Раскуплено" else if (to != null) "Подарить за " else "Купить за ", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                                if (g.left > 0) { if (owner) Text("0", color = Color.White, fontWeight = FontWeight.Black, fontSize = 17.sp) else Text("${g.price}", color = Color.White, fontWeight = FontWeight.Black, fontSize = 17.sp); Spacer(Modifier.width(5.dp)); LumenIcon(20.dp) }
                            }
                        }
                        Spacer(Modifier.height(6.dp))
                        Text(if (owner) "Вы владелец: подарки не списывают люмены" else "На вашем счёте: ${Lumens.balance} ${lumenWord(Lumens.balance)}", color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp)
                    }
                    Spacer(Modifier.height(4.dp))
                }
            }
        }
    }
}

/** Просмотр полученного подарка: нижняя шторка с данными */
@Composable
fun OwnedGiftDialog(o: OwnedGift, onClose: () -> Unit) {
    val p = P
    val price = Gifts.catalog.firstOrNull { it.id == o.giftId }?.price
    val date = remember(o.at) {
        runCatching {
            val d = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US).apply { timeZone = java.util.TimeZone.getTimeZone("UTC") }.parse(o.at!!.take(19))!!
            java.text.SimpleDateFormat("dd.MM.yyyy 'в' HH:mm", java.util.Locale("ru")).format(d)
        }.getOrDefault("—")
    }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.55f)).clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) { onClose() }, contentAlignment = Alignment.BottomCenter) {
            Column(Modifier.widthIn(max = 520.dp).fillMaxWidth().clip(RoundedCornerShape(topStart = 30.dp, topEnd = 30.dp)).background(p.panel)
                .clickable(remember { androidx.compose.foundation.interaction.MutableInteractionSource() }, null) {}.navigationBarsPadding().padding(18.dp),
                horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.fillMaxWidth()) {
                    Box(Modifier.size(42.dp).clip(CircleShape).background(p.panel2).bouncy { onClose() }, contentAlignment = Alignment.Center) {
                        androidx.compose.material3.Icon(androidx.compose.material.icons.Icons.Filled.Close, null, tint = p.text)
                    }
                }
                GiftAnimated(o.giftId, Modifier.size(230.dp))
                Spacer(Modifier.height(8.dp))
                Text(if (o.from != null) "Подарок Вам" else "Ваш подарок", color = p.text, fontSize = 24.sp, fontWeight = FontWeight.Black)
                Spacer(Modifier.height(6.dp))
                Text("${o.name} №${o.serial} из ${o.supply} · ${rarityName(o.rarity)}", color = rarityColor(o.rarity), fontSize = 15.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                Text("Подарок хранится в вашем профиле.", color = p.muted, fontSize = 14.sp)
                Spacer(Modifier.height(14.dp))
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).border(1.dp, p.line, RoundedCornerShape(18.dp))) {
                    SheetRow("От") {
                        if (o.from != null) {
                            val pr = AppModel.profiles[o.from]
                            Avatar(pr?.name ?: AppModel.displayName(o.from), pr?.avatarUrl, pr?.color ?: 0, 30.dp)
                            Spacer(Modifier.width(8.dp))
                            Text(AppModel.displayName(o.from), color = p.a1, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, maxLines = 1)
                        } else Text("Вы", color = p.text, fontSize = 16.sp)
                    }
                    Divider()
                    SheetRow("Дата") { Text(date, color = p.text, fontSize = 16.sp) }
                    Divider()
                    SheetRow("Стоимость") {
                        if (price != null) { Text("$price", color = p.text, fontSize = 16.sp); Spacer(Modifier.width(5.dp)); LumenIcon(18.dp); Spacer(Modifier.width(5.dp)); Text(lumenWord(price.toLong()), color = p.text, fontSize = 16.sp) }
                        else Text("—", color = p.text, fontSize = 16.sp)
                    }
                }
                Spacer(Modifier.height(14.dp))
                Box(Modifier.fillMaxWidth().height(54.dp).clip(RoundedCornerShape(20.dp)).background(p.accent).bouncy { onClose() }, contentAlignment = Alignment.Center) {
                    Text("OK", color = Color.White, fontWeight = FontWeight.Black, fontSize = 17.sp)
                }
            }
        }
    }
}

@Composable
private fun SheetRow(label: String, content: @Composable RowScope.() -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
        Box(Modifier.weight(0.34f).fillMaxHeight().background(p.panel2).padding(14.dp), contentAlignment = Alignment.CenterStart) { Text(label, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp) }
        Row(Modifier.weight(0.66f).padding(14.dp), verticalAlignment = Alignment.CenterVertically, content = content)
    }
}

@Composable
fun OwnedGrid(list: List<OwnedGift>, onTap: (OwnedGift) -> Unit) {
    val p = P
    list.chunked(3).forEach { row ->
        Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 5.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            row.forEach { o ->
                Column(Modifier.weight(1f).clip(RoundedCornerShape(20.dp)).background(p.panel).bouncy { onTap(o) }.padding(6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    GiftThumb(o.giftId, Modifier.fillMaxWidth().aspectRatio(1f))
                    Text("№${o.serial}", color = rarityColor(o.rarity), fontWeight = FontWeight.Bold, fontSize = 12.sp, modifier = Modifier.padding(top = 4.dp))
                }
            }
            repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
        }
    }
}

@Composable
private fun CatalogGrid(onPick: (Gift) -> Unit) {
    Gifts.catalog.toList().chunked(2).forEach { row ->
        Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            row.forEach { g -> GiftCard(g, Modifier.weight(1f)) { onPick(g) } }
            if (row.size == 1) Spacer(Modifier.weight(1f))
        }
    }
}

/** Раздел «Подарки»: каталог и мои подарки */
@Composable
fun GiftsScreen() {
    val p = P
    var pick by remember { mutableStateOf<Gift?>(null) }
    var view by remember { mutableStateOf<OwnedGift?>(null) }
    LaunchedEffect(Unit) { Gifts.load(); Lumens.load() }
    pick?.let { GiftDetailDialog(it, null) { pick = null } }
    view?.let { OwnedGiftDialog(it) { view = null } }
    Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState())) {
        TopBar("Подарки")
        Row(Modifier.padding(horizontal = 18.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            LumenIcon(22.dp); Spacer(Modifier.width(8.dp))
            Text("${Lumens.balance} ${lumenWord(Lumens.balance)}", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
        }
        Text("Редкие подарки с ограниченным тиражом. Купите себе или подарите другу из его профиля.", color = p.muted, fontSize = 14.sp, modifier = Modifier.padding(horizontal = 18.dp, vertical = 6.dp))
        CatalogGrid { pick = it }
        if (Gifts.mine.isNotEmpty()) {
            Text("МОИ ПОДАРКИ", color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 20.dp, top = 18.dp, bottom = 6.dp))
            OwnedGrid(Gifts.mine.toList()) { view = it }
        }
        Spacer(Modifier.height(30.dp))
    }
}

/** Выбор подарка для человека */
@Composable
fun GiftShopDialog(to: String, onClose: () -> Unit) {
    val p = P
    var pick by remember { mutableStateOf<Gift?>(null) }
    LaunchedEffect(Unit) { Gifts.load(); Lumens.load() }
    pick?.let { GiftDetailDialog(it, to) { pick = null; onClose() } }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Column(Modifier.fillMaxSize().background(p.bg).verticalScroll(rememberScrollState())) {
            TopBar("Подарок для ${AppModel.displayName(to)}")
            CatalogGrid { pick = it }
            Spacer(Modifier.height(30.dp))
        }
    }
}

/** Подарки человека на его профиле */
@Composable
fun ProfileGifts(userId: String) {
    val p = P
    var view by remember { mutableStateOf<OwnedGift?>(null) }
    LaunchedEffect(userId) { Gifts.loadUser(userId) }
    val l = Gifts.of[userId].orEmpty()
    view?.let { OwnedGiftDialog(it) { view = null } }
    if (l.isEmpty()) return
    Text("ПОДАРКИ · ${l.size}", color = p.muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 20.dp, top = 14.dp, bottom = 6.dp))
    OwnedGrid(l.take(6)) { view = it }
}

/** Подарок в переписке: плашка «кто отправил» и карточка с подарком */
@Composable
fun GiftMessageCard(m: Message, chat: ChatItem?) {
    val p = P
    var open by remember { mutableStateOf(false) }
    val mine = m.senderId == AppModel.myId
    val gid = m.meta.optString("gift_id")
    val name = m.meta.optString("name")
    val rarity = m.meta.optString("rarity")
    val serial = m.meta.optInt("serial")
    val supply = m.meta.optInt("supply")
    val price = m.meta.optInt("price")
    val c = rarityColor(rarity)
    val who = if (mine) "Вы отправили подарок: ${AppModel.displayName(chat?.peerId)}" else "${AppModel.displayName(m.senderId)} отправил(а) Вам подарок"
    if (open) OwnedGiftDialog(OwnedGift(0, gid, name, rarity, serial, supply, if (mine) null else m.senderId)) { open = false }
    Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("$who стоимостью $price ${lumenWord(price.toLong())}", color = p.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 24.dp).clip(RoundedCornerShape(16.dp)).background(p.panel.copy(alpha = 0.85f)).padding(horizontal = 14.dp, vertical = 6.dp))
        Spacer(Modifier.height(10.dp))
        Column(Modifier.width(250.dp).clip(RoundedCornerShape(28.dp))
            .background(Brush.verticalGradient(listOf(c.copy(alpha = 0.35f), p.panel)))
            .border(1.dp, c.copy(alpha = 0.45f), RoundedCornerShape(28.dp)).padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            GiftThumb(gid, Modifier.size(150.dp))
            Spacer(Modifier.height(10.dp))
            Text("Подарок", color = p.text, fontWeight = FontWeight.Black, fontSize = 18.sp)
            Text("$name №$serial из $supply", color = c, fontWeight = FontWeight.Bold, fontSize = 14.sp, textAlign = TextAlign.Center)
            Text(if (mine) "Подарок появится в профиле получателя." else "Подарок добавлен в ваш профиль.", color = p.muted, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 4.dp))
            Spacer(Modifier.height(12.dp))
            Box(Modifier.clip(RoundedCornerShape(18.dp)).background(c.copy(alpha = 0.3f)).bouncy { open = true }.padding(horizontal = 26.dp, vertical = 10.dp)) {
                Text("Посмотреть", color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
            }
        }
    }
}
