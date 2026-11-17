package ru.volshebnymir.lumo.ui

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.UriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import ru.volshebnymir.lumo.core.AppModel

/** Встроенный браузер: ссылки открываются внутри Lumo, как в Telegram */
object Browser {
    var url by mutableStateOf<String?>(null)
    fun open(u: String) {
        val s = u.trim()
        if (s.startsWith("http://", true) || s.startsWith("https://", true)) url = s
        else runCatching { AppModel.ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(s)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
    /** Ссылки в сообщениях (LinkAnnotation.Url) идут сюда */
    val handler = object : UriHandler { override fun openUri(uri: String) = open(uri) }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun BrowserHost() {
    val start = Browser.url ?: return
    val p = P
    val ctx = LocalContext.current
    var web by remember { mutableStateOf<WebView?>(null) }
    var title by remember { mutableStateOf("") }
    var cur by remember { mutableStateOf(start) }
    var progress by remember { mutableIntStateOf(0) }
    var canBack by remember { mutableStateOf(false) }
    var canFwd by remember { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    fun close() { web?.destroy(); web = null; Browser.url = null }
    Dialog(onDismissRequest = { close() }, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        BackHandler { if (web?.canGoBack() == true) web?.goBack() else close() }
        Column(Modifier.fillMaxSize().background(p.bg).statusBarsPadding().navigationBarsPadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                RoundIcon(Icons.Filled.Close) { close() }
                Column(Modifier.weight(1f).padding(horizontal = 4.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(title.ifEmpty { "Загрузка…" }, color = p.text, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (cur.startsWith("https")) Icon(Icons.Filled.Lock, null, tint = p.muted, modifier = Modifier.size(11.dp))
                        Text(Uri.parse(cur).host ?: cur, color = p.muted, fontSize = 12.sp, maxLines = 1, modifier = Modifier.padding(start = 3.dp))
                    }
                }
                Box {
                    RoundIcon(Icons.Filled.MoreVert) { menu = true }
                    DropdownMenu(menu, { menu = false }) {
                        DropdownMenuItem(text = { Text("Поделиться") }, leadingIcon = { Icon(Icons.Filled.Share, null) }, onClick = {
                            menu = false
                            ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, cur), null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        })
                        DropdownMenuItem(text = { Text("Скопировать ссылку") }, leadingIcon = { Icon(Icons.Filled.ContentCopy, null) }, onClick = { menu = false; copy(ctx, cur) })
                        DropdownMenuItem(text = { Text("Обновить") }, leadingIcon = { Icon(Icons.Filled.Refresh, null) }, onClick = { menu = false; web?.reload() })
                        DropdownMenuItem(text = { Text("Открыть в браузере") }, leadingIcon = { Icon(Icons.Filled.OpenInBrowser, null) }, onClick = {
                            menu = false
                            runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(cur)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                        })
                    }
                }
            }
            val pr by animateFloatAsState(progress / 100f, tween(200), label = "wp")
            AnimatedVisibility(progress in 1..99, enter = fadeIn(), exit = fadeOut(tween(400))) {
                Box(Modifier.fillMaxWidth().height(2.dp)) { Box(Modifier.fillMaxWidth(pr).fillMaxHeight().background(p.a1)) }
            }
            AndroidView(factory = { c ->
                WebView(c).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    settings.loadWithOverviewMode = true
                    settings.useWideViewPort = true
                    settings.builtInZoomControls = true
                    settings.displayZoomControls = false
                    webViewClient = object : WebViewClient() {
                        override fun shouldOverrideUrlLoading(view: WebView, req: android.webkit.WebResourceRequest): Boolean {
                            val u = req.url.toString()
                            if (u.startsWith("http")) return false
                            runCatching { c.startActivity(Intent(Intent.ACTION_VIEW, req.url).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                            return true
                        }
                        override fun doUpdateVisitedHistory(view: WebView, url: String?, isReload: Boolean) {
                            cur = url ?: cur; canBack = view.canGoBack(); canFwd = view.canGoForward()
                        }
                    }
                    webChromeClient = object : WebChromeClient() {
                        override fun onProgressChanged(view: WebView, newProgress: Int) { progress = newProgress }
                        override fun onReceivedTitle(view: WebView, t: String?) { title = t ?: "" }
                    }
                    loadUrl(start)
                    web = this
                }
            }, modifier = Modifier.weight(1f).fillMaxWidth())
            Row(Modifier.fillMaxWidth().background(p.panel).padding(horizontal = 24.dp, vertical = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                RoundIcon(Icons.AutoMirrored.Filled.ArrowBack, tint = if (canBack) p.a1 else p.muted.copy(alpha = 0.4f)) { if (canBack) web?.goBack() }
                RoundIcon(Icons.AutoMirrored.Filled.ArrowForward, tint = if (canFwd) p.a1 else p.muted.copy(alpha = 0.4f)) { if (canFwd) web?.goForward() }
                RoundIcon(if (progress in 1..99) Icons.Filled.Close else Icons.Filled.Refresh, tint = p.a1) { if (progress in 1..99) web?.stopLoading() else web?.reload() }
                RoundIcon(Icons.Filled.Share, tint = p.a1) {
                    ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, cur), null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
            }
        }
    }
}
