package ru.volshebnymir.lumo

import android.app.Application
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.decode.VideoFrameDecoder
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel

class LumoApp : Application(), ImageLoaderFactory {
    override fun onCreate() {
        super.onCreate()
        ru.volshebnymir.lumo.ui.Look.init(this)
        ru.volshebnymir.lumo.ui.Lang.load(this)
        ru.volshebnymir.lumo.ui.Extra.init(this)
        AppModel.init(this)
        ru.volshebnymir.lumo.core.NetStats.init(this)
        ru.volshebnymir.lumo.core.AutoDownload.init(this)
        ru.volshebnymir.lumo.core.FileStore.init(this)
        Thread { runCatching { ru.volshebnymir.lumo.core.DeviceStorage.trim() } }.start()
        AppModel.scope.launch { ru.volshebnymir.lumo.core.Net.pick(force = true) }
    }

    override fun newImageLoader(): ImageLoader = ImageLoader.Builder(this)
        .okHttpClient { ru.volshebnymir.lumo.core.Api.http }
        .components { add(VideoFrameDecoder.Factory()) }
        .crossfade(true)
        // все картинки сохраняются на телефон и дальше берутся с него
        .diskCache { coil.disk.DiskCache.Builder().directory(cacheDir.resolve("image_cache")).maxSizePercent(0.15).build() }
        .respectCacheHeaders(false)
        .build()
}
