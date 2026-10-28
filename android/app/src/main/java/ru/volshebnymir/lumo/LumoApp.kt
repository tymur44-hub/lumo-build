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
        ru.volshebnymir.lumo.ui.Extra.init(this)
        AppModel.init(this)
        AppModel.scope.launch { ru.volshebnymir.lumo.core.Net.pick(force = true) }
    }

    override fun newImageLoader(): ImageLoader = ImageLoader.Builder(this)
        .okHttpClient { ru.volshebnymir.lumo.core.Api.http }
        .components { add(VideoFrameDecoder.Factory()) }
        .crossfade(true)
        .build()
}
