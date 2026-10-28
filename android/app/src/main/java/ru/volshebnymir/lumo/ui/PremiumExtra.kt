package ru.volshebnymir.lumo.ui

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.PREMIUM_SOON
import ru.volshebnymir.lumo.core.isPremium
import ru.volshebnymir.lumo.core.jsonOf
import java.security.MessageDigest

/** Локальные настройки Premium: цвет сообщений в чатах, фон чатов, блокировка приложения */
object Extra {
    private lateinit var ctx: Context
    val bub = mutableStateMapOf<String, Int>()
    var wall by mutableStateOf(0)
    var hasLock by mutableStateOf(false)
    var locked by mutableStateOf(false)
    var lastStop = 0L

    val BUBS: List<Pair<Long, Long>?> = listOf(
        null, 0xFFFF3D6EL to 0xFFFF8A5BL, 0xFF00C6FFL to 0xFF0072FFL, 0xFF43E97BL to 0xFF12B886L, 0xFFF7971EL to 0xFFFFB020L,
        0xFFFA709AL to 0xFFB66CFFL, 0xFF667EEAL to 0xFF764BA2L, 0xFF475569L to 0xFF1E293BL,
    )
    val WALLS: List<Pair<Long, Long>?> = listOf(
        null, 0xFF1B2A49L to 0xFF3B1F4AL, 0xFF0F3D3EL to 0xFF1B6B4AL, 0xFF4A1F2EL to 0xFF7A3B1FL, 0xFF1F2A4AL to 0xFF2E6BA8L,
    )

    private fun prefs() = ctx.getSharedPreferences("lumo_extra", Context.MODE_PRIVATE)

    fun init(c: Context) {
        ctx = c.applicationContext
        val p = prefs()
        wall = p.getInt("wall", 0)
        hasLock = !p.getString("lock", null).isNullOrEmpty()
        locked = hasLock
        p.all.forEach { (k, v) -> if (k.startsWith("bub_") && v is Int) bub[k.removePrefix("bub_")] = v }
    }

    fun chooseWall(i: Int) { wall = i; prefs().edit().putInt("wall", i).apply() }
    fun setBub(chat: String, i: Int) {
        if (i == 0) { bub.remove(chat); prefs().edit().remove("bub_$chat").apply() } else { bub[chat] = i; prefs().edit().putInt("bub_$chat", i).apply() }
    }

    fun bubBrush(chat: String): Brush? {
        if (!AppModel.isPremium) return null
        val i = bub[chat] ?: return null
        val c = BUBS.getOrNull(i) ?: return null
        return Brush.linearGradient(listOf(Color(c.first), Color(c.second)))
    }

    fun wallBrush(): Brush? {
        if (!AppModel.isPremium) return null
        val c = WALLS.getOrNull(wall) ?: return null
        return Brush.verticalGradient(listOf(Color(c.first), Color(c.second)))
    }

    private fun hash(pin: String): String =
        MessageDigest.getInstance("SHA-256").digest(("lumo-lock:$pin").toByteArray()).joinToString("") { "%02x".format(it) }

    fun setPin(pin: String?) {
        if (pin == null) { prefs().edit().remove("lock").apply(); hasLock = false; locked = false }
        else { prefs().edit().putString("lock", hash(pin)).apply(); hasLock = true }
    }

    fun check(pin: String): Boolean = prefs().getString("lock", null) == hash(pin)
}

// ---------------- цвет сообщений в чате ----------------

@Composable
fun BubbleColorDialog(chatId: String, onClose: () -> Unit) {
    val p = P
    val cur = Extra.bub[chatId] ?: 0
    AlertDialog(onDismissRequest = onClose, title = { Text("Цвет ваших сообщений") }, text = {
        Column {
            Text("Только для этого чата, на этом устройстве.", color = p.muted, fontSize = 14.sp)
            Spacer(Modifier.height(10.dp))
            Extra.BUBS.chunked(4).forEachIndexed { r, row ->
                Row(Modifier.fillMaxWidth().padding(vertical = 5.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEachIndexed { k, c ->
                        val i = r * 4 + k
                        Box(Modifier.size(46.dp).clip(CircleShape)
                            .background(if (c == null) Brush.linearGradient(listOf(p.panel2, p.panel2)) else Brush.linearGradient(listOf(Color(c.first), Color(c.second))))
                            .border(3.dp, if (cur == i) p.text else Color.Transparent, CircleShape)
                            .clickable { Extra.setBub(chatId, i); onClose() })
                    }
                }
            }
        }
    }, confirmButton = { TextButton(onClose) { Text("Закрыть") } })
}

// ---------------- расширенный профиль: ссылки ----------------

@Composable
fun ProfileExtraDialog(onClose: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    val titles = remember { mutableStateMapOf<Int, String>() }
    val urls = remember { mutableStateMapOf<Int, String>() }
    var cover by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(Unit) {
        val id = AppModel.myId ?: return@LaunchedEffect
        val r = runCatching { Api.rpc("lm_profile_extra", jsonOf("p_id" to id)) }.getOrNull()
        val o = (r as? JSONObject) ?: (r as? JSONArray)?.optJSONObject(0)
        cover = o?.optString("cover")?.takeIf { it.isNotEmpty() && it != "null" }
        val l = o?.optJSONArray("links")
        if (l != null) for (i in 0 until minOf(3, l.length())) { val x = l.optJSONObject(i) ?: continue; titles[i] = x.optString("title"); urls[i] = x.optString("url") }
    }
    AlertDialog(onDismissRequest = onClose, title = { Text("Расширенный профиль") }, text = {
        Column {
            Text("До 3 ссылок в вашем профиле.", color = p.muted, fontSize = 14.sp)
            for (i in 0 until 3) {
                Spacer(Modifier.height(8.dp))
                LumoField(titles[i] ?: "", { titles[i] = it.take(30) }, "Название")
                Spacer(Modifier.height(4.dp))
                LumoField(urls[i] ?: "", { urls[i] = it.take(200) }, "https://…")
            }
        }
    }, confirmButton = {
        TextButton({
            val arr = JSONArray()
            for (i in 0 until 3) {
                val t = (titles[i] ?: "").trim(); val u = (urls[i] ?: "").trim()
                if (t.isNotEmpty() && Regex("^https?://", RegexOption.IGNORE_CASE).containsMatchIn(u)) arr.put(jsonOf("title" to t, "url" to u))
            }
            scope.launch {
                try { Api.rpc("lm_set_profile_extra", jsonOf("p_cover" to cover, "p_links" to arr)); AppModel.say("Профиль обновлён"); onClose() }
                catch (e: Exception) { AppModel.say(e.message ?: "Не удалось сохранить") }
            }
        }) { Text("Сохранить") }
    }, dismissButton = { TextButton(onClose) { Text("Отмена") } })
}

/** Ссылки в чужом профиле (у пользователей Premium) */
@Composable
fun ProfileLinks(userId: String) {
    val p = P
    val ctx = LocalContext.current
    var links by remember(userId) { mutableStateOf<List<Pair<String, String>>>(emptyList()) }
    LaunchedEffect(userId) {
        val r = runCatching { Api.rpc("lm_profile_extra", jsonOf("p_id" to userId)) }.getOrNull()
        val o = (r as? JSONObject) ?: (r as? JSONArray)?.optJSONObject(0)
        val l = o?.optJSONArray("links")
        links = if (l == null) emptyList() else (0 until l.length()).mapNotNull { i -> l.optJSONObject(i)?.let { it.optString("title") to it.optString("url") } }.filter { it.second.startsWith("http") }
    }
    if (links.isEmpty()) return
    Card {
        Column(Modifier.padding(vertical = 8.dp)) {
            Text("Ссылки", color = p.muted, fontSize = 13.sp)
            links.forEach { (t, u) ->
                Text(t, color = p.a2, fontWeight = FontWeight.SemiBold, fontSize = 16.sp,
                    modifier = Modifier.fillMaxWidth().clickable { runCatching { ctx.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(u)).addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)) } }.padding(vertical = 6.dp))
            }
        }
    }
    Spacer(Modifier.height(14.dp))
}

// ---------------- блокировка приложения ----------------

@Composable
private fun PinPad(title: String, error: String?, onDone: (String) -> Unit) {
    val p = P
    var pin by remember(title) { mutableStateOf("") }
    LaunchedEffect(error) { if (error != null) pin = "" }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp, textAlign = TextAlign.Center)
        Spacer(Modifier.height(14.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            for (i in 0 until 4) Box(Modifier.size(14.dp).clip(CircleShape).background(if (i < pin.length) p.a1 else p.muted.copy(alpha = 0.3f)))
        }
        Text(error ?: " ", color = p.danger, fontSize = 13.sp, modifier = Modifier.padding(top = 8.dp, bottom = 8.dp))
        val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫")
        keys.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.padding(vertical = 5.dp)) {
                row.forEach { k ->
                    if (k.isEmpty()) Spacer(Modifier.size(64.dp))
                    else Box(Modifier.size(64.dp).clip(CircleShape).background(p.panel2).clickable {
                        if (k == "⌫") { if (pin.isNotEmpty()) pin = pin.dropLast(1) }
                        else if (pin.length < 4) { pin += k; if (pin.length == 4) onDone(pin) }
                    }, contentAlignment = Alignment.Center) { Text(k, color = p.text, fontSize = 24.sp, fontWeight = FontWeight.Medium) }
                }
            }
        }
    }
}

/** Экран блокировки поверх приложения */
@Composable
fun LockOverlay() {
    val p = P
    val ctx = LocalContext.current
    DisposableEffect(ctx) {
        val owner = ctx as? LifecycleOwner
        val obs = LifecycleEventObserver { _, e ->
            if (e == Lifecycle.Event.ON_STOP) Extra.lastStop = System.currentTimeMillis()
            if (e == Lifecycle.Event.ON_START && Extra.hasLock && Extra.lastStop > 0 && System.currentTimeMillis() - Extra.lastStop > 60_000) Extra.locked = true
        }
        owner?.lifecycle?.addObserver(obs)
        onDispose { owner?.lifecycle?.removeObserver(obs) }
    }
    if (!(Extra.hasLock && Extra.locked)) return
    var err by remember { mutableStateOf<String?>(null) }
    Box(Modifier.fillMaxSize().background(p.bg).clickable(indication = null, interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() }) {}, contentAlignment = Alignment.Center) {
        PinPad("Введите код доступа", err) { pin ->
            if (Extra.check(pin)) { err = null; Extra.locked = false } else err = "Неверный код"
        }
    }
}

/** Включение, смена и отключение кода */
@Composable
fun LockSettingsDialog(onClose: () -> Unit) {
    val p = P
    var step by remember { mutableStateOf(if (Extra.hasLock) "menu" else "new") }
    var first by remember { mutableStateOf("") }
    var err by remember { mutableStateOf<String?>(null) }
    Dialog(onDismissRequest = onClose) {
        Column(Modifier.clip(RoundedCornerShape(26.dp)).background(p.panel).padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            when (step) {
                "menu" -> {
                    Text("Блокировка включена", color = p.text, fontWeight = FontWeight.Black, fontSize = 20.sp)
                    Text("Код спрашивается при входе и после сворачивания больше чем на минуту.", color = p.muted, fontSize = 14.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(vertical = 10.dp))
                    Text("Сменить код", color = p.a1, fontWeight = FontWeight.Bold, fontSize = 16.sp, modifier = Modifier.fillMaxWidth().clickable { step = "old-change" }.padding(10.dp), textAlign = TextAlign.Center)
                    Text("Выключить", color = p.danger, fontWeight = FontWeight.Bold, fontSize = 16.sp, modifier = Modifier.fillMaxWidth().clickable { step = "old-off" }.padding(10.dp), textAlign = TextAlign.Center)
                    Text("Закрыть", color = p.muted, fontSize = 15.sp, modifier = Modifier.clickable { onClose() }.padding(10.dp))
                }
                "old-change", "old-off" -> PinPad("Введите текущий код", err) { pin ->
                    if (Extra.check(pin)) { err = null; if (step == "old-off") { Extra.setPin(null); AppModel.say("Блокировка выключена"); onClose() } else step = "new" } else err = "Неверный код"
                }
                "new" -> PinPad("Придумайте код из 4 цифр", null) { pin -> first = pin; err = null; step = "again" }
                else -> PinPad("Повторите код", err) { pin ->
                    if (pin == first) { Extra.setPin(pin); AppModel.say("Блокировка включена"); onClose() } else { err = "Коды не совпали"; step = "new" }
                }
            }
        }
    }
}

// ---------------- выбор длительности истории ----------------

@Composable
fun StoryHoursPicker(hours: Int, onPick: (Int) -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        listOf(24 to "24 ч", 48 to "48 ч ★", 72 to "3 дня ★", 168 to "7 дней ★").forEach { (h, t) ->
            Pill(t, hours == h) { if (h > 24 && !AppModel.isPremium) AppModel.say(PREMIUM_SOON) else onPick(h) }
        }
    }
    Text("Сколько будет жить история", color = p.muted, fontSize = 12.5.sp, modifier = Modifier.padding(top = 4.dp))
}
