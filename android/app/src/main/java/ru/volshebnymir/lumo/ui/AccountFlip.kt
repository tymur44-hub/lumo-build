package ru.volshebnymir.lumo.ui

import android.graphics.Bitmap
import android.view.View
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import java.lang.ref.WeakReference

/** Переключение аккаунтов «как страница книги»: снимок старого экрана переворачивается вокруг левого края */
object AccountFlip {
    var root: WeakReference<View>? = null
    var page by mutableStateOf<Bitmap?>(null)
    /** номер «поворота страницы»: меняется — запускается анимация */
    var turnTick by mutableIntStateOf(0)

    fun capture() {
        val v = root?.get() ?: return
        if (v.width <= 0 || v.height <= 0) return
        page = runCatching {
            Bitmap.createBitmap(v.width, v.height, Bitmap.Config.ARGB_8888).also { b -> v.draw(android.graphics.Canvas(b)) }
        }.getOrNull()
    }

    fun turn() { if (page != null) turnTick++ }

    @Composable
    fun Overlay() {
        val bm = page ?: return
        val angle = remember(bm) { Animatable(0f) }
        LaunchedEffect(bm, turnTick) {
            if (turnTick == 0) return@LaunchedEffect
            angle.animateTo(-100f, tween(750, easing = CubicBezierEasing(0.45f, 0.05f, 0.25f, 1f)))
            page = null
            turnTick = 0
        }
        val p = (kotlin.math.abs(angle.value) / 90f).coerceIn(0f, 1f)
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.35f * (1 - p)))) {
            Box(Modifier.fillMaxSize().graphicsLayer {
                rotationY = angle.value
                transformOrigin = TransformOrigin(0f, 0.5f)
                cameraDistance = 9f * density
            }) {
                Image(bm.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.FillBounds)
                Box(Modifier.fillMaxSize().background(Brush.horizontalGradient(listOf(
                    Color.Black.copy(alpha = 0.05f + 0.45f * p), Color.Black.copy(alpha = 0.25f * p), Color.White.copy(alpha = 0.12f * p)))))
            }
        }
    }
}
