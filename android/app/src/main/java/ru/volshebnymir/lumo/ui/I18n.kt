package ru.volshebnymir.lumo.ui

import android.content.Context
import androidx.compose.foundation.text.InlineTextContent
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.LocalTextStyle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit

/** Язык приложения: ru / en / tt */
object Lang {
    val all = listOf(Triple("ru", "Русский", "Русский"), Triple("en", "English", "Английский"), Triple("tt", "Татарча", "Татарский"))
    var code by mutableStateOf("ru")
        private set

    fun load(ctx: Context) {
        code = ctx.getSharedPreferences("lumo_prefs", Context.MODE_PRIVATE).getString("lang", "ru") ?: "ru"
    }

    fun set(ctx: Context, c: String) {
        ctx.getSharedPreferences("lumo_prefs", Context.MODE_PRIVATE).edit().putString("lang", c).apply()
        code = c
    }

    /** Перевод русского текста; неизвестные строки остаются как есть */
    fun tr(s: String): String {
        val c = code
        if (c == "ru" || s.isEmpty()) return s
        val m = if (c == "en") I18nData.en else I18nData.tt
        if (s.contains(" · ") && m[s] == null) return s.split(" · ").joinToString(" · ") { tr(it) }
        return m[s] ?: m[s.trim()]?.let { s.substring(0, s.length - s.trimStart().length) + it + s.substring(s.trimEnd().length) } ?: s
    }
}

/** Обёртка над material3.Text: переводит строки по словарю */
@Composable
fun Text(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    fontSize: TextUnit = TextUnit.Unspecified,
    fontStyle: FontStyle? = null,
    fontWeight: FontWeight? = null,
    fontFamily: FontFamily? = null,
    letterSpacing: TextUnit = TextUnit.Unspecified,
    textDecoration: TextDecoration? = null,
    textAlign: TextAlign? = null,
    lineHeight: TextUnit = TextUnit.Unspecified,
    overflow: TextOverflow = TextOverflow.Clip,
    softWrap: Boolean = true,
    maxLines: Int = Int.MAX_VALUE,
    minLines: Int = 1,
    onTextLayout: ((TextLayoutResult) -> Unit)? = null,
    style: TextStyle = LocalTextStyle.current
) {
    androidx.compose.material3.Text(
        Lang.tr(text), modifier, color, fontSize, fontStyle, fontWeight, fontFamily, letterSpacing,
        textDecoration, textAlign, lineHeight, overflow, softWrap, maxLines, minLines, onTextLayout, style
    )
}

@Composable
fun Text(
    text: AnnotatedString,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    fontSize: TextUnit = TextUnit.Unspecified,
    fontStyle: FontStyle? = null,
    fontWeight: FontWeight? = null,
    fontFamily: FontFamily? = null,
    letterSpacing: TextUnit = TextUnit.Unspecified,
    textDecoration: TextDecoration? = null,
    textAlign: TextAlign? = null,
    lineHeight: TextUnit = TextUnit.Unspecified,
    overflow: TextOverflow = TextOverflow.Clip,
    softWrap: Boolean = true,
    maxLines: Int = Int.MAX_VALUE,
    minLines: Int = 1,
    inlineContent: Map<String, InlineTextContent> = mapOf(),
    onTextLayout: (TextLayoutResult) -> Unit = {},
    style: TextStyle = LocalTextStyle.current
) {
    androidx.compose.material3.Text(
        text, modifier, color, fontSize, fontStyle, fontWeight, fontFamily, letterSpacing,
        textDecoration, textAlign, lineHeight, overflow, softWrap, maxLines, minLines, inlineContent, onTextLayout, style
    )
}
