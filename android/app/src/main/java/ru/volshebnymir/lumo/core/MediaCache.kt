package ru.volshebnymir.lumo.core

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.effect.Presentation
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import java.util.UUID
import kotlin.coroutines.resume

/** Плеер с кэшем на диске: видео скачивается один раз, повторные просмотры идут с телефона */
@OptIn(UnstableApi::class)
object LumoPlayer {
    @Volatile private var cache: SimpleCache? = null

    private fun cache(ctx: Context): SimpleCache = cache ?: synchronized(this) {
        cache ?: SimpleCache(File(ctx.applicationContext.cacheDir, "vcache"), LeastRecentlyUsedCacheEvictor(600L * 1024 * 1024),
            StandaloneDatabaseProvider(ctx.applicationContext)).also { cache = it }
    }

    /** очистить скачанные видео */
    fun clear(ctx: Context) { runCatching { val c = cache(ctx); c.keys.toList().forEach { c.removeResource(it) } } }

    fun build(ctx: Context): ExoPlayer {
        // всё, что видео тянет из сети, попадает в «Использование трафика»
        val counter = object : androidx.media3.datasource.TransferListener {
            override fun onTransferInitializing(source: androidx.media3.datasource.DataSource, dataSpec: androidx.media3.datasource.DataSpec, isNetwork: Boolean) {}
            override fun onTransferStart(source: androidx.media3.datasource.DataSource, dataSpec: androidx.media3.datasource.DataSpec, isNetwork: Boolean) {}
            override fun onBytesTransferred(source: androidx.media3.datasource.DataSource, dataSpec: androidx.media3.datasource.DataSpec, isNetwork: Boolean, bytesTransferred: Int) {
                if (isNetwork) NetStats.add(DataKind.Video, recvBytes = bytesTransferred.toLong())
            }
            override fun onTransferEnd(source: androidx.media3.datasource.DataSource, dataSpec: androidx.media3.datasource.DataSpec, isNetwork: Boolean) {}
        }
        val up = DefaultDataSource.Factory(ctx, DefaultHttpDataSource.Factory().setAllowCrossProtocolRedirects(true).setTransferListener(counter))
        val cached = CacheDataSource.Factory().setCache(cache(ctx)).setUpstreamDataSourceFactory(up)
            .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
        return ExoPlayer.Builder(ctx).setMediaSourceFactory(DefaultMediaSourceFactory(ctx).setDataSourceFactory(cached)).build()
    }
}

/** Сжатие видео перед отправкой: 720p H.264 ~2,5 Мбит/с — обычно в несколько раз меньше исходника с камеры */
@OptIn(UnstableApi::class)
object VideoCompress {
    suspend fun compress(ctx: Context, data: ByteArray, ext: String): ByteArray? {
        if (data.size < 4 * 1024 * 1024) return null
        val dir = ctx.cacheDir
        val src = File(dir, "vc-${UUID.randomUUID()}.${ext.ifEmpty { "mp4" }}")
        val dst = File(dir, "vc-${UUID.randomUUID()}.mp4")
        return try {
            src.writeBytes(data)
            val ok = run(ctx, src, dst)
            if (ok && dst.length() > 0 && dst.length() < data.size * 0.85) dst.readBytes() else null
        } catch (_: Throwable) { null } finally { src.delete(); dst.delete() }
    }

    private suspend fun run(ctx: Context, src: File, dst: File): Boolean = suspendCancellableCoroutine { cont ->
        Handler(Looper.getMainLooper()).post {
            try {
                val enc = DefaultEncoderFactory.Builder(ctx.applicationContext)
                    .setRequestedVideoEncoderSettings(VideoEncoderSettings.Builder().setBitrate(2_500_000).build()).build()
                val t = Transformer.Builder(ctx.applicationContext)
                    .setVideoMimeType(MimeTypes.VIDEO_H264)
                    .setAudioMimeType(MimeTypes.AUDIO_AAC)
                    .setEncoderFactory(enc)
                    .addListener(object : Transformer.Listener {
                        override fun onCompleted(composition: Composition, exportResult: ExportResult) { if (cont.isActive) cont.resume(true) }
                        override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) { if (cont.isActive) cont.resume(false) }
                    }).build()
                val item = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(src)))
                    .setEffects(Effects(emptyList(), listOf(Presentation.createForHeight(720)))).build()
                t.start(item, dst.absolutePath)
                cont.invokeOnCancellation { Handler(Looper.getMainLooper()).post { t.cancel() } }
            } catch (_: Throwable) { if (cont.isActive) cont.resume(false) }
        }
    }
}
