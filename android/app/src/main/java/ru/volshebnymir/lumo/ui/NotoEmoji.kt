package ru.volshebnymir.lumo.ui

import android.graphics.ImageDecoder
import android.graphics.drawable.AnimatedImageDrawable
import android.os.Build
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Request
import ru.volshebnymir.lumo.core.Api
import ru.volshebnymir.lumo.core.AppModel
import java.io.File

/** Анимированные эмодзи Google Noto (как в Telegram и на сайте Lumo): сообщение из одних эмодзи «оживает». */
object NotoEmoji {
    private val missing = HashSet<String>()

    fun graphemes(s: String): List<String> {
        val it = java.text.BreakIterator.getCharacterInstance()
        val t = s.trim(); it.setText(t)
        val out = ArrayList<String>(); var a = it.first(); var b = it.next()
        while (b != java.text.BreakIterator.DONE) { val g = t.substring(a, b); if (g.isNotBlank()) out += g; a = b; b = it.next() }
        return out
    }

    /** сообщение из 1–6 эмодзи без букв и цифр */
    fun isOnly(s: String?): Boolean {
        val t = s?.trim() ?: return false
        if (t.isEmpty() || t.length > 40 || t.any { it.isLetterOrDigit() }) return false
        val g = graphemes(t)
        return g.size in 1..6 && g.all { e -> e.codePoints().anyMatch { it >= 0x2190 } }
    }

    private fun code(g: String, strip: Boolean): String {
        val cps = g.codePoints().toArray().filter { !(strip && it == 0xFE0F) }
        return cps.joinToString("_") { Integer.toHexString(it) }
    }

    /** файл анимации (скачивается один раз), null — анимации для этого эмодзи нет */
    suspend fun file(g: String): File? = withContext(Dispatchers.IO) {
        val dir = File(AppModel.ctx.cacheDir, "noto").apply { mkdirs() }
        for (strip in listOf(false, true)) {
            val c = code(g, strip)
            if (strip && c == code(g, false)) break
            val f = File(dir, "$c.webp")
            if (f.exists() && f.length() > 0) return@withContext f
            if (c in missing) continue
            val ok = runCatching {
                Api.http.newCall(Request.Builder().url("https://fonts.gstatic.com/s/e/notoemoji/latest/$c/512.webp").build()).execute().use { r ->
                    if (!r.isSuccessful) false else {
                        val tmp = File(dir, "$c.part")
                        r.body!!.byteStream().use { inp -> tmp.outputStream().use { inp.copyTo(it) } }
                        tmp.renameTo(f)
                    }
                }
            }.getOrDefault(false)
            if (ok) return@withContext f
            missing += c
        }
        null
    }
}

/** Одно эмодзи: пока грузится или если анимации нет — наше нарисованное «живое» эмодзи */
@Composable
fun NotoEmojiView(e: String, size: Dp) {
    var f by remember(e) { mutableStateOf<File?>(null) }
    var tried by remember(e) { mutableStateOf(false) }
    LaunchedEffect(e) { if (Build.VERSION.SDK_INT >= 28) f = NotoEmoji.file(e); tried = true }
    Box(Modifier.size(size), contentAlignment = Alignment.Center) {
        val file = f
        if (file != null && Build.VERSION.SDK_INT >= 28) {
            AndroidView(factory = { c ->
                android.widget.ImageView(c).apply {
                    scaleType = android.widget.ImageView.ScaleType.FIT_CENTER
                    val px = (size.value * c.resources.displayMetrics.density).toInt().coerceAtMost(512)
                    val d = runCatching {
                        ImageDecoder.decodeDrawable(ImageDecoder.createSource(file)) { dec, _, _ -> dec.setTargetSize(px, px) }
                    }.getOrNull()
                    if (d is AnimatedImageDrawable) { d.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE; d.start() }
                    setImageDrawable(d)
                }
            }, modifier = Modifier.size(size))
        } else {
            AnimatedEmoji(e, size * 0.82f)
        }
    }
}

/** Сообщение из одних эмодзи — крупно и анимированно */
@Composable
fun NotoEmojiRow(text: String) {
    val g = remember(text) { NotoEmoji.graphemes(text) }
    val sz = when (g.size) { 1 -> 120.dp; 2 -> 96.dp; 3 -> 80.dp; else -> 60.dp }
    Row(verticalAlignment = Alignment.CenterVertically) { g.forEach { NotoEmojiView(it, sz) } }
}
