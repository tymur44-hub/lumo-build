package ru.volshebnymir.lumo.ui

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.HapticFeedbackConstants
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.launch
import org.json.JSONObject
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.MiniAppReq
import ru.volshebnymir.lumo.core.jsonOf
import ru.volshebnymir.lumo.core.str

private fun hex(c: Color) = String.format("#%06x", c.toArgb() and 0xFFFFFF)

private class Loaded(val title: String, val bridge: String, val html: String?, val url: String?)

/** Мини-приложение бота на весь экран (как Web Apps в Telegram) */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun MiniAppScreen(req: MiniAppReq, onClose: () -> Unit) {
    val p = P
    val ctx = LocalContext.current
    val view = LocalView.current
    val scope = rememberCoroutineScope()
    var loaded by remember { mutableStateOf<Loaded?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var backVisible by remember { mutableStateOf(false) }
    var web by remember { mutableStateOf<WebView?>(null) }
    val title = loaded?.title ?: AppModel.profiles[req.botId]?.name ?: "Мини-приложение"

    val theme = remember(p) {
        JSONObject().put("bg_color", hex(p.bg)).put("text_color", hex(p.text)).put("hint_color", hex(p.muted))
            .put("link_color", hex(p.a1)).put("button_color", hex(p.a1)).put("button_text_color", "#ffffff").put("secondary_bg_color", hex(p.panel))
    }

    LaunchedEffect(req) {
        try {
            val body = JSONObject().put("bot_id", req.botId).put("theme", theme).put("scheme", if (p.dark) "dark" else "light").put("platform", "android")
            req.url?.let { body.put("url", it) }
            val r = Api.botFunction("/webapp/init", body) as? JSONObject
            if (r == null || r.optBoolean("ok") != true) { error = r?.str("error") ?: "Не удалось открыть"; return@LaunchedEffect }
            loaded = Loaded(r.str("title") ?: "Мини-приложение", r.str("bridge") ?: "", r.str("html"), r.str("url"))
        } catch (e: Exception) { error = e.message ?: "Не удалось открыть" }
    }

    val handler = remember { Handler(Looper.getMainLooper()) }
    val bridge = remember {
        object {
            @JavascriptInterface
            fun postEvent(event: String, json: String) {
                val d = runCatching { JSONObject(json) }.getOrDefault(JSONObject())
                handler.post {
                    when (event) {
                        "close" -> onClose()
                        "sendData" -> scope.launch {
                            runCatching { Api.botFunction("/webapp/data", jsonOf("bot_id" to req.botId, "data" to (d.optString("data")))) }
                            onClose()
                        }
                        "openLink" -> d.str("url")?.let { AppModel.openUrl?.invoke(it) }
                        "copy" -> {
                            val cm = ctx.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            cm.setPrimaryClip(ClipData.newPlainText("Lumo", d.optString("text")))
                        }
                        "haptic" -> view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        "backButton" -> backVisible = d.optBoolean("visible")
                    }
                }
            }
        }
    }

    BackHandler {
        if (backVisible) web?.evaluateJavascript("window.__lumoBack&&window.__lumoBack()", null) else onClose()
    }
    DisposableEffect(Unit) { onDispose { web?.apply { stopLoading(); destroy() } } }

    Column(Modifier.fillMaxSize().background(p.bg).pointerInput(Unit) { awaitPointerEventScope { while (true) awaitPointerEvent().changes.forEach { it.consume() } } }.statusBarsPadding().navigationBarsPadding().imePadding()) {
        Row(Modifier.fillMaxWidth().background(p.panel).padding(horizontal = 6.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clickable { if (backVisible) web?.evaluateJavascript("window.__lumoBack&&window.__lumoBack()", null) else onClose() }, contentAlignment = Alignment.Center) {
                Icon(if (backVisible) Icons.AutoMirrored.Filled.ArrowBack else Icons.Filled.Close, null, tint = p.text)
            }
            Text(title, color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp, maxLines = 1, modifier = Modifier.weight(1f).padding(start = 4.dp))
        }
        Box(Modifier.weight(1f).fillMaxWidth()) {
            val l = loaded
            if (l != null) {
                AndroidView(factory = { c ->
                    WebView(c).apply {
                        setBackgroundColor(p.bg.toArgb())
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                        settings.allowFileAccess = false
                        settings.allowContentAccess = false
                        addJavascriptInterface(bridge, "LumoNative")
                        val pre = "window.__lumoPost=function(e,d){LumoNative.postEvent(e,JSON.stringify(d||{}))};"
                        webViewClient = object : WebViewClient() {
                            override fun onPageStarted(v: WebView, url: String?, f: android.graphics.Bitmap?) {
                                if (l.html == null) v.evaluateJavascript(pre + l.bridge, null)
                            }
                            override fun onPageCommitVisible(v: WebView, url: String?) {
                                if (l.html == null) v.evaluateJavascript(pre + l.bridge, null)
                            }
                        }
                        if (l.html != null) {
                            val inject = "<script>$pre${l.bridge.replace("</script", "<\\/script")}</script>"
                            val h = l.html
                            val i = h.indexOf("<head>", ignoreCase = true)
                            val doc = if (i >= 0) h.substring(0, i + 6) + inject + h.substring(i + 6) else inject + h
                            loadDataWithBaseURL("https://miniapp.lumo.local/", doc, "text/html", "utf-8", null)
                        } else loadUrl(l.url ?: "about:blank")
                        web = this
                    }
                }, modifier = Modifier.fillMaxSize())
            } else if (error != null) {
                Text(error!!, color = p.muted, textAlign = TextAlign.Center, modifier = Modifier.align(Alignment.Center).padding(30.dp))
            } else CircularProgressIndicator(color = p.a1, modifier = Modifier.align(Alignment.Center))
        }
    }
}
