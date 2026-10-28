package ru.volshebnymir.lumo.ui

import android.content.Context
import android.graphics.SurfaceTexture
import android.view.TextureView
import org.webrtc.EglBase
import org.webrtc.EglRenderer
import org.webrtc.GlRectDrawer
import org.webrtc.VideoFrame
import org.webrtc.VideoSink

/** Видео WebRTC в TextureView: в отличие от SurfaceView, не прячется под фоном и обрезается по форме */
class TextureRenderer(ctx: Context) : TextureView(ctx), TextureView.SurfaceTextureListener, VideoSink {
    private val egl = EglRenderer("lumo-tex")
    private var frameW = 0
    private var frameH = 0
    private var inited = false

    init { surfaceTextureListener = this }

    fun init(shared: EglBase.Context, mirror: Boolean) {
        if (inited) return
        inited = true
        egl.init(shared, EglBase.CONFIG_PLAIN, GlRectDrawer())
        egl.setMirror(mirror)
    }

    fun release() { if (inited) { inited = false; egl.release() } }

    override fun onFrame(frame: VideoFrame) {
        val w = frame.rotatedWidth; val h = frame.rotatedHeight
        if (w != frameW || h != frameH) { frameW = w; frameH = h; post { updateAspect() } }
        egl.onFrame(frame)
    }

    /** Заполнение без полос: обрезаем лишнее по краям */
    private fun updateAspect() {
        if (width > 0 && height > 0) egl.setLayoutAspectRatio(width.toFloat() / height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) { super.onLayout(changed, l, t, r, b); updateAspect() }

    override fun onSurfaceTextureAvailable(st: SurfaceTexture, w: Int, h: Int) { egl.createEglSurface(st); updateAspect() }
    override fun onSurfaceTextureSizeChanged(st: SurfaceTexture, w: Int, h: Int) { updateAspect() }
    override fun onSurfaceTextureDestroyed(st: SurfaceTexture): Boolean {
        val l = java.util.concurrent.CountDownLatch(1)
        egl.releaseEglSurface { l.countDown() }
        runCatching { l.await(500, java.util.concurrent.TimeUnit.MILLISECONDS) }
        return true
    }
    override fun onSurfaceTextureUpdated(st: SurfaceTexture) {}
}
