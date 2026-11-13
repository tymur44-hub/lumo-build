package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

/** Политика конфиденциальности (assets/privacy.md) в оформлении приложения */
@Composable
fun PolicyDialog(onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val lines = remember { runCatching { ctx.assets.open("privacy.md").bufferedReader().use { it.readText() } }.getOrDefault("Политика доступна на lumomess.ru/?privacy").lines() }
    Dialog(onClose, DialogProperties(usePlatformDefaultWidth = false)) {
        Column(Modifier.fillMaxSize().background(p.bg).statusBarsPadding().navigationBarsPadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("Политика конфиденциальности", color = p.text, fontWeight = FontWeight.Bold, fontSize = 19.sp, modifier = Modifier.weight(1f))
                Box(Modifier.size(36.dp).clip(CircleShape).background(p.panel2).clickable { onClose() }, contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Close, null, tint = p.text, modifier = Modifier.size(18.dp))
                }
            }
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                lines.forEach { raw ->
                    val l = raw.trimEnd()
                    when {
                        l.isEmpty() || l.startsWith("# ") -> {}
                        l.startsWith("## ") -> Text(l.removePrefix("## "), color = p.text, fontWeight = FontWeight.Bold, fontSize = 16.sp, modifier = Modifier.padding(top = 8.dp))
                        l.startsWith("- ") -> Row {
                            Text("•", color = p.a1, fontSize = 15.sp, modifier = Modifier.padding(end = 8.dp))
                            Text(md(l.removePrefix("- ")), color = p.text, fontSize = 14.5.sp, lineHeight = 20.sp)
                        }
                        else -> Text(md(l), color = p.text, fontSize = 14.5.sp, lineHeight = 20.sp)
                    }
                }
                Spacer(Modifier.height(30.dp))
            }
        }
    }
}

private fun md(s: String) = buildAnnotatedString {
    var i = 0
    while (i < s.length) {
        val a = s.indexOf("**", i)
        if (a < 0) { append(s.substring(i)); break }
        val b = s.indexOf("**", a + 2)
        if (b < 0) { append(s.substring(i)); break }
        append(s.substring(i, a))
        withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(s.substring(a + 2, b)) }
        i = b + 2
    }
}

/** Согласие на обработку персональных данных (152-ФЗ) */
@Composable
fun ConsentRow(checked: Boolean, onChange: (Boolean) -> Unit, onPolicy: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Checkbox(checked, onChange, colors = CheckboxDefaults.colors(checkedColor = p.a1, uncheckedColor = p.muted))
        Column(Modifier.weight(1f)) {
            Text(buildAnnotatedString {
                append("Принимаю ")
                withStyle(SpanStyle(color = p.a1, fontWeight = FontWeight.SemiBold)) { append("Политику конфиденциальности") }
                append(" и даю согласие на обработку моих персональных данных")
            }, color = p.muted, fontSize = 13.sp, lineHeight = 17.sp, modifier = Modifier.clickable { onPolicy() })
        }
    }
}
