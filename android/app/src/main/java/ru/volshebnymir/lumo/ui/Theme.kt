package ru.volshebnymir.lumo.ui

import android.content.Context
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/** Оформление (как на сайте): тема, цвет, размер текста */
object Look {
    private lateinit var ctx: Context
    var theme by mutableStateOf("dark")
    var accent by mutableIntStateOf(0)
    var fontSize by mutableFloatStateOf(16f)

    val accents = listOf(
        0xFF7C5CFF to 0xFF22C1FF, 0xFFFF5B8A to 0xFFFF9A5B, 0xFF13B0A5 to 0xFF2EE6A6,
        0xFF3A7BFF to 0xFF22C1FF, 0xFFC44DFF to 0xFFFF5B7A, 0xFFFF8A3D to 0xFFFFC94A,
        // эксклюзивные, только для Premium
        0xFFFF3D6E to 0xFFFFB020, 0xFF00C6FF to 0xFF43E97B, 0xFFB066FF to 0xFF00E0C6,
        0xFFFFD34D to 0xFFFF5B8A, 0xFF5B6CFF to 0xFFFF5BD0, 0xFF12B886 to 0xFFB8E83D,
    )

    fun init(c: Context) {
        ctx = c.applicationContext
        val p = ctx.getSharedPreferences("lumo_look", Context.MODE_PRIVATE)
        theme = p.getString("theme", "dark") ?: "dark"
        accent = p.getInt("accent", 0)
        fontSize = p.getFloat("fs", 16f)
    }

    fun save() {
        ctx.getSharedPreferences("lumo_look", Context.MODE_PRIVATE).edit()
            .putString("theme", theme).putInt("accent", accent).putFloat("fs", fontSize).apply()
    }
}

class Palette(
    val dark: Boolean,
    val bg: Color, val panel: Color, val panel2: Color, val chatBg: Color, val bubble: Color,
    val text: Color, val muted: Color, val line: Color, val a1: Color, val a2: Color,
) {
    val accent: Brush get() = Brush.linearGradient(listOf(a1, a2))
    val out: Brush get() = if (Look.accent == 0) Brush.linearGradient(listOf(Color(0xFF6A4CF5), Color(0xFF3A7BFF))) else accent
    val danger = Color(0xFFFF5B7A)
    val ok = Color(0xFF3EE0A0)
    val names = listOf(0xFFFF7A6B, 0xFFA48BFF, 0xFF36B8FF, 0xFF25C99A, 0xFFF0A23A, 0xFFFF5B9A, 0xFF6AA8FF, 0xFF52C46E).map { Color(it) }
    fun nameColor(c: Int) = names[((c % 8) + 8) % 8]
    private val pairs = listOf(
        0xFFFF8A5B to 0xFFFF5B8A, 0xFF7C5CFF to 0xFFB05CFF, 0xFF22C1FF to 0xFF3A7BFF, 0xFF2EE6A6 to 0xFF13B0A5,
        0xFFFFC94A to 0xFFFF8A3D, 0xFFFF5B7A to 0xFFC44DFF, 0xFF5BD0FF to 0xFF7C5CFF, 0xFF9BE15D to 0xFF00C6A7,
    )
    fun avatar(c: Int): Brush { val p = pairs[((c % 8) + 8) % 8]; return Brush.linearGradient(listOf(Color(p.first), Color(p.second))) }
}

val LocalPalette = staticCompositionLocalOf { makePalette(true) }

fun makePalette(dark: Boolean): Palette {
    val (c1, c2) = Look.accents[Look.accent.coerceIn(0, Look.accents.size - 1)]
    return if (dark) Palette(true, Color(0xFF0C0D1A), Color(0xFF13142A), Color(0xFF1A1C36), Color(0xFF0E0F22), Color(0xFF1D1F3D),
        Color(0xFFEEF0FF), Color(0xFF8D90B8), Color(0x12FFFFFF), Color(c1), Color(c2))
    else Palette(false, Color(0xFFEEF0FB), Color(0xFFFFFFFF), Color(0xFFF4F5FD), Color(0xFFE7E9FB), Color(0xFFFFFFFF),
        Color(0xFF14163A), Color(0xFF7276A0), Color(0x1414163C), Color(c1), Color(c2))
}

val P: Palette @Composable get() = LocalPalette.current

@Composable
fun LumoTheme(content: @Composable () -> Unit) {
    val dark = when (Look.theme) { "light" -> false; "dark" -> true; else -> isSystemInDarkTheme() }
    val pal = makePalette(dark).also { Look.accent }
    val scheme = if (dark) darkColorScheme(primary = pal.a1, background = pal.bg, surface = pal.panel, onSurface = pal.text, onBackground = pal.text)
    else lightColorScheme(primary = pal.a1, background = pal.bg, surface = pal.panel, onSurface = pal.text, onBackground = pal.text)
    CompositionLocalProvider(LocalPalette provides pal) {
        MaterialTheme(colorScheme = scheme, content = content)
    }
}
