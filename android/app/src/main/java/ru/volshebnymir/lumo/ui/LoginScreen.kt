package ru.volshebnymir.lumo.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import java.util.UUID

@Composable
fun LoginScreen() {
    val p = P
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var reg by remember { mutableStateOf(false) }
    var user by remember { mutableStateOf("") }
    var pass by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var err by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(false) }
    var tgKey by remember { mutableStateOf<String?>(null) }

    fun openBot() {
        val bot = AppModel.botName ?: return; val k = tgKey ?: return
        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/$bot?start=l_$k")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }

    LaunchedEffect(tgKey) {
        val k = tgKey ?: return@LaunchedEffect
        repeat(300) {
            delay(2000)
            if (tgKey != k) return@LaunchedEffect
            try { if (AppModel.telegramCheck(k)) { tgKey = null; return@LaunchedEffect } }
            catch (e: Exception) { err = e.message; tgKey = null; return@LaunchedEffect }
        }
        tgKey = null
    }

    Box(Modifier.fillMaxSize().background(p.bg)) {
        Column(
            Modifier.fillMaxSize().statusBarsPadding().imePadding().verticalScroll(rememberScrollState()).padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Spacer(Modifier.height(50.dp))
            Box(Modifier.size(92.dp).clip(RoundedCornerShape(28.dp)).background(p.accent), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.ChatBubble, null, tint = Color.White, modifier = Modifier.size(46.dp))
            }
            Text("Lumo", fontSize = 34.sp, fontWeight = FontWeight.Black, color = p.text)
            Text("Бета-версия 1.6", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = p.muted)
            Text(if (reg) "Создайте аккаунт" else "Войдите в свой аккаунт", color = p.muted)
            if (reg) LumoField(name, { name = it }, "Имя")
            LumoField(user, { user = it.trim() }, "Юзернейм")
            LumoField(pass, { pass = it }, "Пароль", password = true)
            err?.let { Text(it, color = p.danger, fontSize = 14.sp, textAlign = TextAlign.Center) }
            GradientButton(if (reg) "Зарегистрироваться" else "Войти", loading) {
                val u = user.lowercase().removePrefix("@")
                when {
                    !Regex("^[a-z0-9_]{3,32}$").matches(u) -> err = "Юзернейм: 3–32 символа, латиница, цифры и _"
                    pass.isEmpty() -> err = "Введите пароль"
                    reg && pass.length < 6 -> err = "Пароль — не короче 6 символов"
                    reg && name.isBlank() -> err = "Введите имя"
                    else -> {
                        loading = true; err = null
                        scope.launch {
                            try { if (reg) AppModel.register(u, pass, name.trim()) else AppModel.login(u, pass) }
                            catch (e: Exception) { err = e.message }
                            loading = false
                        }
                    }
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.weight(1f).height(1.dp).background(p.line))
                Text("или", color = p.muted, fontSize = 13.sp)
                Box(Modifier.weight(1f).height(1.dp).background(p.line))
            }
            Row(
                Modifier.fillMaxWidth().height(50.dp).clip(RoundedCornerShape(14.dp)).background(Color(0xFF2AABEE)).bouncy {
                    err = null
                    if (tgKey != null) { openBot(); return@bouncy }
                    scope.launch {
                        if (AppModel.telegramBot() == null) { err = "Вход через Telegram сейчас недоступен"; return@launch }
                        tgKey = UUID.randomUUID().toString().replace("-", "")
                        openBot()
                    }
                },
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center,
            ) {
                if (tgKey != null) CircularProgressIndicator(Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
                else Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White, modifier = Modifier.size(19.dp))
                Spacer(Modifier.size(10.dp))
                Text(if (tgKey != null) "Ждём подтверждения в Telegram…" else if (reg) "Создать аккаунт через Telegram" else "Войти через Telegram",
                    color = Color.White, fontWeight = FontWeight.Bold)
            }
            if (tgKey != null) Text("В Telegram нажмите кнопку в боте и вернитесь сюда — вход произойдёт сам.", color = p.muted, fontSize = 13.sp, textAlign = TextAlign.Center)
            Text(if (reg) "Уже есть аккаунт? Войти" else "Нет аккаунта? Зарегистрироваться", color = p.a1, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(top = 4.dp).bouncy { reg = !reg; err = null })
            Spacer(Modifier.height(40.dp))
        }
    }
}
