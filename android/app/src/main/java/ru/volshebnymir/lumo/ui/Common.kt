package ru.volshebnymir.lumo.ui

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.text.KeyboardOptions
import coil.compose.AsyncImage
import ru.volshebnymir.lumo.core.Fmt

@Composable
fun Avatar(name: String, url: String?, color: Int, size: Dp, online: Boolean = false, modifier: Modifier = Modifier) {
    val p = P
    Box(modifier.size(size)) {
        Box(Modifier.size(size).clip(CircleShape).background(p.avatar(color)), contentAlignment = Alignment.Center) {
            Text(Fmt.initials(name), color = Color.White, fontWeight = FontWeight.Bold, fontSize = (size.value * 0.36f).sp)
            if (!url.isNullOrEmpty()) AsyncImage(url, null, Modifier.size(size).clip(CircleShape), contentScale = ContentScale.Crop)
        }
        if (online) Box(
            Modifier.align(Alignment.BottomEnd).size(size * 0.28f).clip(CircleShape).background(p.bg).padding(2.dp)
                .clip(CircleShape).background(p.ok)
        )
    }
}

/** Пружинящее нажатие */
@Composable
fun Modifier.bouncy(onClick: () -> Unit): Modifier {
    val src = remember { MutableInteractionSource() }
    val pressed by src.collectIsPressedAsState()
    val s by animateFloatAsState(if (pressed) 0.88f else 1f, spring(dampingRatio = 0.5f, stiffness = Spring.StiffnessMedium), label = "b")
    return this.scale(s).clickable(src, null, onClick = onClick)
}

@Composable
fun GradientButton(title: String, loading: Boolean = false, enabled: Boolean = true, onClick: () -> Unit) {
    val p = P
    Box(
        Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(16.dp)).background(if (enabled) p.accent else SolidColor(p.panel2))
            .bouncy { if (enabled && !loading) onClick() },
        contentAlignment = Alignment.Center,
    ) {
        if (loading) CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.5.dp)
        else Text(title, color = if (enabled) Color.White else p.muted, fontWeight = FontWeight.Bold, fontSize = 16.sp)
    }
}

@Composable
fun LumoField(value: String, onChange: (String) -> Unit, hint: String, password: Boolean = false, singleLine: Boolean = true, modifier: Modifier = Modifier, keyboard: KeyboardType = KeyboardType.Text) {
    val p = P
    Box(modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(p.panel2).padding(horizontal = 16.dp, vertical = 14.dp)) {
        if (value.isEmpty()) Text(hint, color = p.muted, fontSize = 16.sp)
        BasicTextField(
            value, onChange, singleLine = singleLine, modifier = Modifier.fillMaxWidth(),
            textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1),
            visualTransformation = if (password) PasswordVisualTransformation() else VisualTransformation.None,
            keyboardOptions = KeyboardOptions(keyboardType = if (password) KeyboardType.Password else keyboard),
        )
    }
}

@Composable
fun Card(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val p = P
    Column(modifier.padding(horizontal = 14.dp).fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(p.panel).padding(horizontal = 16.dp, vertical = 4.dp)) { content() }
}

@Composable
fun SettingsRow(icon: ImageVector, color: Color, title: String, subtitle: String? = null, titleColor: Color? = null, lead: (@Composable () -> Unit)? = null, onClick: () -> Unit) {
    val p = P
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)).background(color), contentAlignment = Alignment.Center) {
            if (lead != null) lead() else Icon(icon, null, tint = Color.White, modifier = Modifier.size(19.dp))
        }
        Column(Modifier.weight(1f)) {
            Text(title, color = titleColor ?: p.text, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            if (subtitle != null) Text(subtitle, color = p.muted, fontSize = 12.5.sp, maxLines = 2)
        }
    }
}

@Composable
fun Divider() { val p = P; Box(Modifier.fillMaxWidth().height(1.dp).background(p.line)) }

@Composable
fun RoundIcon(icon: ImageVector, size: Dp = 44.dp, tint: Color? = null, bg: Color? = null, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val p = P
    Box(modifier.size(size).clip(CircleShape).background(bg ?: Color.Transparent).bouncy(onClick), contentAlignment = Alignment.Center) {
        Icon(icon, null, tint = tint ?: p.text, modifier = Modifier.size(size * 0.5f))
    }
}

@Composable
fun BetaBadge() {
    val p = P
    Box(Modifier.clip(RoundedCornerShape(12.dp)).background(p.accent).padding(horizontal = 9.dp, vertical = 3.dp)) {
        Text("БЕТА", color = Color.White, fontWeight = FontWeight.Black, fontSize = 11.sp, letterSpacing = 1.sp)
    }
}

@Composable
fun Pill(text: String, on: Boolean, onClick: () -> Unit) {
    val p = P
    Box(Modifier.clip(RoundedCornerShape(20.dp)).background(if (on) p.panel2 else Color.Transparent).border(1.dp, if (on) Color.Transparent else p.line, RoundedCornerShape(20.dp))
        .clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 8.dp)) {
        Text(text, color = if (on) p.text else p.muted, fontWeight = FontWeight.SemiBold, fontSize = 14.5.sp, maxLines = 1, softWrap = false)
    }
}


/** Плавное появление: лёгкий «пружинистый» рост из маленького размера */
@Composable
fun Modifier.popIn(from: Float = 0.6f): Modifier {
    val a = remember { androidx.compose.animation.core.Animatable(from) }
    androidx.compose.runtime.LaunchedEffect(Unit) { a.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 420f)) }
    return this.graphicsLayer { scaleX = a.value; scaleY = a.value; alpha = ((a.value - from) / (1f - from)).coerceIn(0f, 1f) }
}
