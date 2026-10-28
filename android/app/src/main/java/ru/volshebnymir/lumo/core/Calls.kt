package ru.volshebnymir.lumo.core

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Base64
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import org.webrtc.AudioTrack as RtcAudioTrack
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraVideoCapturer
import org.webrtc.DataChannel
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.DefaultVideoEncoderFactory
import org.webrtc.EglBase
import org.webrtc.IceCandidate
import org.webrtc.MediaConstraints
import org.webrtc.MediaStream
import org.webrtc.PeerConnection
import org.webrtc.PeerConnectionFactory
import org.webrtc.RtpReceiver
import org.webrtc.RtpTransceiver
import org.webrtc.SdpObserver
import org.webrtc.SessionDescription
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import org.webrtc.audio.JavaAudioDeviceModule
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/**
 * Звонки Lumo — тот же протокол, что у сайта и iPhone: сигналы в канале lm-call-<id>,
 * звук и видео через WebRTC, а если прямого соединения нет — резервный канал («rm»: μ-law 16 кГц + JPEG).
 */
@SuppressLint("StaticFieldLeak")
object Calls {
    enum class State { Idle, Calling, Incoming, Connecting, Active }

    var state by mutableStateOf(State.Idle)
    var video by mutableStateOf(false)
    var muted by mutableStateOf(false)
    var speaker by mutableStateOf(false)
    var camOff by mutableStateOf(false)
    var peerCamOff by mutableStateOf(false)
    var startedAt by mutableStateOf<Long?>(null)
    var peerName by mutableStateOf("")
    var peerAvatar by mutableStateOf<String?>(null)
    var peerColor by mutableStateOf(0)
    var remoteVideo by mutableStateOf<VideoTrack?>(null)
    var localVideo by mutableStateOf<VideoTrack?>(null)
    var statusText by mutableStateOf("")
    var relayImage by mutableStateOf<Bitmap?>(null)
    var p2p by mutableStateOf(false)

    val eglBase: EglBase by lazy { EglBase.create() }

    private lateinit var ctx: Context
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val bg = Executors.newSingleThreadExecutor()

    var peerId: String? = null; private set
    private var callId: String? = null
    private var role = ""
    private var chatId: String? = null
    private var secChat: String? = null
    private var secJob: Job? = null

    /** Защита звонка: ключ личного чата. Если он есть у обоих, данные соединения подписываются, а запасной канал шифруется. */
    private fun secInit(peer: String) {
        secChat = null
        secJob?.cancel()
        secJob = scope.launch {
            val c = AppModel.chats.firstOrNull { it.isPrivate && it.peerId == peer } ?: return@launch
            E2E.prepare(c.id, c.peerId)
            if (E2E.active(c.id)) secChat = c.id
        }
    }
    private fun sdpFp(s: String): String =
        Regex("a=fingerprint:(\\S+) (\\S+)", RegexOption.IGNORE_CASE).findAll(s).map { it.groupValues[1].lowercase() + " " + it.groupValues[2].uppercase() }.toSet().sorted().joinToString(",")
    private fun signed(j: JSONObject, typ: String, sdp: String): JSONObject {
        secChat?.let { c -> E2E.encrypt(c, "lumo-call1|$callId|$typ|${sdpFp(sdp)}")?.let { j.put("auth", it) } }
        return j
    }
    private fun sdpOk(msg: JSONObject, typ: String): Boolean {
        val c = secChat ?: return true
        val a = msg.str("auth") ?: return false
        if (!E2E.isEnc(a)) return false
        return E2E.decrypt(c, a) == "lumo-call1|$callId|$typ|${sdpFp(msg.obj("sdp").str("sdp") ?: "")}"
    }
    private fun tampered() {
        peerId?.let { sig(it, jsonOf("t" to "hangup")) }
        end("ended", why = "tampered"); AppModel.say("Звонок остановлен: данные соединения подменены")
    }
    private var myId: String? = null
    private var myChannel: Realtime.Channel? = null
    private val outChannels = mutableMapOf<String, Realtime.Channel>()
    private val doneCalls = mutableSetOf<String>()
    private var factory: PeerConnectionFactory? = null
    private var adm: JavaAudioDeviceModule? = null
    private var pc: PeerConnection? = null
    private var pendingOffer: JSONObject? = null
    private val iceQueue = mutableListOf<IceCandidate>()
    private var audioTrack: RtcAudioTrack? = null
    private var capturer: CameraVideoCapturer? = null
    private var videoSource: VideoSource? = null
    private var texHelper: SurfaceTextureHelper? = null
    private var reRing: Job? = null
    private var timeout: Job? = null
    private var heartbeat: Job? = null
    private var watchdog: Job? = null
    private var relayJob: Job? = null
    private var restarts = 0
    private var lastPeer = 0L
    private var connectingSince = 0L
    private var relaySeq = 0
    private var relayRSeq = -1
    private var pendingJPEG: String? = null
    private var iceServers: List<PeerConnection.IceServer>? = null
    private var ringtone: Ringtone? = null
    private var proximity: PowerManager.WakeLock? = null
    private var savedMode = AudioManager.MODE_NORMAL

    fun init(c: Context) {
        if (::ctx.isInitialized) return
        ctx = c.applicationContext
        CallsBridge.onAttach = { attach(it) }
        CallsBridge.onDetach = { detach() }
    }

    private fun factory(): PeerConnectionFactory {
        factory?.let { return it }
        PeerConnectionFactory.initialize(PeerConnectionFactory.InitializationOptions.builder(ctx).createInitializationOptions())
        val a = JavaAudioDeviceModule.builder(ctx)
            .setUseHardwareAcousticEchoCanceler(true)
            .setUseHardwareNoiseSuppressor(true)
            .setSamplesReadyCallback { s -> Relay.fromAdm(s.data, s.sampleRate, s.channelCount) }
            .createAudioDeviceModule()
        adm = a
        val f = PeerConnectionFactory.builder()
            .setAudioDeviceModule(a)
            .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
            .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
            .createPeerConnectionFactory()
        factory = f
        return f
    }

    // ---------- каналы сигналов ----------

    fun attach(id: String) {
        if (myId == id) return
        myId = id
        val ch = Realtime.channel("lm-call-$id")
        ch.onBroadcast = { ev, p -> if (ev == "sig") onSig(p) }
        myChannel = ch
    }

    fun detach() {
        if (state != State.Idle) hangup()
        myId?.let { Realtime.leave("lm-call-$it") }
        outChannels.keys.forEach { Realtime.leave("lm-call-$it") }
        outChannels.clear(); myChannel = null; myId = null
    }

    private fun outChannel(to: String) = outChannels.getOrPut(to) { Realtime.channel("lm-call-$to") }

    private fun sig(to: String, data: JSONObject) {
        val me = myId ?: return
        if (to.isEmpty()) return
        data.put("from", me)
        if (!data.has("callId")) data.put("callId", callId ?: "")
        val ch = (if (to == me) myChannel else outChannel(to)) ?: return
        scope.launch { Realtime.waitJoined(ch); Realtime.broadcast(ch, "sig", data) }
    }

    private fun randomId(n: Int = 8): String { val a = "abcdefghijklmnopqrstuvwxyz0123456789"; return (1..n).map { a.random() }.joinToString("") }

    fun has(perm: String) = ContextCompat.checkSelfPermission(ctx, perm) == PackageManager.PERMISSION_GRANTED
    private val micOk get() = has(android.Manifest.permission.RECORD_AUDIO)
    private val camOk get() = has(android.Manifest.permission.CAMERA)

    // ---------- исходящий ----------

    /** Разрешения (микрофон, камера) запрашивает экран перед вызовом */
    fun startCall(chat: ChatItem, v: Boolean) {
        if (state != State.Idle) { AppModel.say("Вы уже в звонке"); return }
        val peer = chat.peerId ?: return
        val me = AppModel.me ?: return
        if (peer == me.id) return
        if (!micOk) { AppModel.say("Нет доступа к микрофону"); return }
        callId = randomId(); role = "caller"; peerId = peer; chatId = chat.id
        secInit(peer)
        video = v && camOk; speaker = video; muted = false; camOff = false; peerCamOff = false
        peerName = chat.displayName; peerAvatar = chat.displayAvatar; peerColor = chat.displayColor
        state = State.Calling; statusText = "Звонок…"
        log("start", jsonOf("to" to peer, "video" to video))
        lastPeer = now()
        audioOn()
        LumoService.callMode(ctx, true, video)
        outChannel(peer)
        prepareLocalMedia()
        scope.launch { runCatching { Api.function("/call", jsonOf("peer_id" to peer, "video" to video)) } }
        val cid = callId
        fun ring() = jsonOf("t" to "ring", "video" to video, "name" to me.name, "avatar" to me.avatarUrl, "color" to me.color,
            "chatId" to chat.id, "rc" to jsonOf("a" to 0, "v" to JSONArray()))
        sig(peer, ring())
        reRing = scope.launch {
            delay(700); markRinging(cid)
            while (state == State.Calling && callId == cid) { delay(3000); if (state == State.Calling && callId == cid) { sig(peer, ring()); markRinging(cid) } }
        }
        timeout = scope.launch {
            delay(45_000)
            if (state == State.Calling && callId == cid) { sig(peer, jsonOf("t" to "cancel")); end("missed", why = "timeout_out") }
        }
    }

    private fun markRinging(cid: String?, confirmed: Boolean = false) {
        if (state != State.Calling || callId != cid || statusText != "Звонок…") return
        if (confirmed || AppModel.isOnline(peerId)) statusText = "Вызов…"
    }

    // ---------- сигналы ----------

    private fun onSig(p: JSONObject) {
        val t = p.str("t") ?: ""
        val from = p.str("from") ?: ""
        val cid = p.str("callId") ?: ""
        if (t == "kf") return
        if (t == "rm") { onRelay(p, from, cid); return }
        if (t == "ring") {
            if (cid in doneCalls) return
            if (state != State.Idle) {
                if (cid != callId) sig(from, jsonOf("t" to "busy", "callId" to cid))
                else if (state == State.Incoming) sig(from, jsonOf("t" to "ringing"))
                return
            }
            val cf = AppModel.me?.priv("calls") ?: "all"
            if (cf == "none" || (cf == "contacts" && !AppModel.isContact(from))) { doneCalls.add(cid); sig(from, jsonOf("t" to "nocall", "callId" to cid)); return }
            callId = cid; role = "callee"; peerId = from; chatId = p.str("chatId")
            secInit(from)
            video = p.bool("video"); speaker = video; muted = false; camOff = false; peerCamOff = false
            peerName = p.str("name") ?: "Lumo"; peerAvatar = p.str("avatar"); peerColor = p.int("color") ?: 0
            state = State.Incoming
            statusText = if (video) "Входящий видеозвонок" else "Входящий звонок"
            log("ring_in", jsonOf("from" to from))
            sig(from, jsonOf("t" to "ringing"))
            startRinging()
            timeout = scope.launch { delay(50_000); if (state == State.Incoming && callId == cid) end("missed", remote = true, why = "timeout_in") }
            return
        }
        if (t == "taken") { if (state == State.Incoming && cid == callId) end("elsewhere", remote = true, why = "taken"); return }
        if (state == State.Idle || cid != callId || from != peerId) return
        if (t != "ice" && t != "hb") log("sig_$t")
        if (state == State.Incoming && (t == "offer" || t == "ice" || t == "hb")) { end("elsewhere", remote = true, why = "elsewhere_sig"); return }
        lastPeer = now()
        when (t) {
            "ringing" -> markRinging(cid, true)
            "accept" -> {
                if (state != State.Calling) return
                reRing?.cancel(); timeout?.cancel()
                state = State.Connecting; statusText = "Соединение…"
                startWatchdog(); startRelay()
                scope.launch { makePC(); createOffer() }
            }
            "offer" -> if (pc == null) pendingOffer = p else handleOffer(p)
            "answer" -> {
                val s = p.obj("sdp").str("sdp") ?: return
                val c = pc ?: return
                val id = callId
                scope.launch {
                    secJob?.join()
                    if (callId != id || pc !== c) return@launch
                    if (!sdpOk(p, "answer")) { tampered(); return@launch }
                    c.setRemoteDescription(Sdp { scope.launch { flushIce() } }, SessionDescription(SessionDescription.Type.ANSWER, s))
                }
            }
            "ice" -> {
                val c = p.obj("c")
                val s = c.str("candidate") ?: return
                val cand = IceCandidate(c.str("sdpMid") ?: "0", c.int("sdpMLineIndex") ?: 0, s)
                val x = pc
                if (x != null && x.remoteDescription != null) x.addIceCandidate(cand) else iceQueue.add(cand)
            }
            "reject" -> { end("rejected", why = "peer_reject"); AppModel.say("Звонок отклонён") }
            "busy" -> { end("missed", why = "peer_busy"); AppModel.say("Абонент занят") }
            "nocall" -> { end("missed", why = "peer_nocall"); AppModel.say("Пользователь ограничил входящие звонки") }
            "cancel" -> end("missed", remote = true, why = "peer_cancel")
            "hangup" -> end(if (startedAt != null) "ended" else "missed", remote = true, why = "peer_hangup")
            "media" -> {
                peerCamOff = p.bool("camOff")
                if (p.bool("video") && !video) { video = true; speaker = true; applySpeaker() }
            }
            "restart" -> if (role == "caller") createOffer(true)
        }
    }

    private fun log(ev: String, info: JSONObject = JSONObject()) {
        info.put("state", state.name).put("app", if (AppModel.isActive) "fg" else "bg").put("v", "android-1.6").put("os", "android ${Build.VERSION.RELEASE}").put("role", role)
        val row = jsonOf("call_id" to (callId ?: ""), "ev" to ev, "info" to info)
        scope.launch { runCatching { Api.insertQuiet("lm_call_log", row) } }
    }

    // ---------- звонит ----------

    private fun startRinging() {
        runCatching {
            val r = RingtoneManager.getRingtone(ctx, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE))
            if (Build.VERSION.SDK_INT >= 28) r.isLooping = true
            r.audioAttributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
            r.play(); ringtone = r
        }
        runCatching {
            val v = ctx.getSystemService(Vibrator::class.java)
            v.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 700, 900), 0))
        }
        Notifier.incomingCall(ctx, peerName, video, chatId ?: peerId ?: "")
        // Lumo свёрнут или телефон заблокирован — сразу открываем экран звонка поверх всего
        if (!AppModel.isActive) runCatching {
            ctx.startActivity(android.content.Intent(ctx, ru.volshebnymir.lumo.MainActivity::class.java)
                .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP).putExtra("call", true))
        }
        scope.launch {
            // для повтора звонка, если рингтон без зацикливания закончился
            while (state == State.Incoming) { delay(3000); if (state == State.Incoming && ringtone?.isPlaying == false) runCatching { ringtone?.play() } }
        }
    }

    private fun stopRinging() {
        runCatching { ringtone?.stop() }; ringtone = null
        runCatching { ctx.getSystemService(Vibrator::class.java).cancel() }
        Notifier.cancelCall(ctx)
    }

    // ---------- кнопки ----------

    fun answer() {
        if (state != State.Incoming) return
        if (!micOk) { AppModel.say("Нужен доступ к микрофону"); return }
        log("accept_call")
        stopRinging(); timeout?.cancel()
        lastPeer = now(); state = State.Connecting; statusText = "Соединение…"
        startWatchdog()
        if (video && !camOk) video = false
        val peer = peerId ?: return
        audioOn()
        LumoService.callMode(ctx, true, video)
        prepareLocalMedia()
        sig(peer, jsonOf("t" to "accept", "rc" to jsonOf("a" to 0, "v" to JSONArray())))
        startRelay()
        myId?.let { sig(it, jsonOf("t" to "taken")) }
        val id = callId
        scope.launch {
            makePC()
            if (callId != id || pc == null) return@launch
            pendingOffer?.let { pendingOffer = null; handleOffer(it) }
        }
    }

    fun endTapped() { if (state == State.Incoming) reject() else hangup() }

    private fun reject() {
        val p = peerId ?: return
        if (state != State.Incoming) return
        sig(p, jsonOf("t" to "reject"))
        myId?.let { sig(it, jsonOf("t" to "taken")) }
        end("rejected", why = "self_reject")
    }

    fun hangup() {
        val p = peerId ?: return
        if (state == State.Idle) return
        sig(p, jsonOf("t" to if (state == State.Calling) "cancel" else "hangup"))
        end(if (startedAt != null) "ended" else "missed", why = "self_hangup")
    }

    fun toggleMute() { muted = !muted; audioTrack?.setEnabled(!muted); Relay.muted = muted }

    fun toggleSpeaker() { speaker = !speaker; applySpeaker() }

    fun toggleCamera() {
        if (localVideo == null) { enableVideo(); return }
        camOff = !camOff
        if (!camOff && !speaker) { speaker = true; applySpeaker() }
        localVideo?.setEnabled(!camOff)
        if (camOff) runCatching { capturer?.stopCapture() } else runCatching { capturer?.startCapture(1280, 720, 30) }
        peerId?.let { sig(it, jsonOf("t" to "media", "camOff" to camOff)) }
        updateProximity()
    }

    /** Камера во время аудиозвонка: добавляем видео и договариваемся заново */
    fun enableVideo() {
        if (state != State.Active && state != State.Connecting) return
        if (!camOk) { AppModel.say("Нет доступа к камере"); return }
        if (localVideo != null) return
        video = true; camOff = false
        prepareLocalMedia()
        val p = pc; val v = localVideo
        if (p != null && v != null) { p.addTrack(v, listOf("lm")); createOffer() }
        speaker = true; applySpeaker()
        LumoService.callMode(ctx, true, true)
        peerId?.let { sig(it, jsonOf("t" to "media", "camOff" to false, "video" to true)) }
        log("video_on")
    }

    fun flipCamera() { capturer?.switchCamera(null) }

    // ---------- конец ----------

    fun end(status: String, remote: Boolean = false, why: String = "") {
        if (state == State.Idle) return
        log("end", jsonOf("status" to status, "remote" to remote, "why" to why))
        stopRinging()
        val wasCaller = role == "caller"
        val dur = startedAt?.let { ((now() - it) / 1000.0).roundToInt() } ?: 0
        val cid = chatId
        val wasVideo = video
        callId?.let { doneCalls.add(it) }
        reRing?.cancel(); timeout?.cancel(); heartbeat?.cancel(); watchdog?.cancel(); relayJob?.cancel()
        runCatching { capturer?.stopCapture() }; runCatching { capturer?.dispose() }; capturer = null
        runCatching { texHelper?.dispose() }; texHelper = null
        localVideo?.removeSink(Relay.sink)
        runCatching { pc?.close() }; runCatching { pc?.dispose() }; pc = null
        runCatching { localVideo?.dispose() }; localVideo = null
        runCatching { videoSource?.dispose() }; videoSource = null
        runCatching { audioTrack?.dispose() }; audioTrack = null
        remoteVideo = null
        Relay.stop()
        relayImage = null; pendingJPEG = null; p2p = false
        pendingOffer = null; iceQueue.clear()
        secJob?.cancel(); secChat = null
        state = State.Idle; startedAt = null; callId = null; peerId = null; role = ""
        muted = false; camOff = false; peerCamOff = false; statusText = ""; video = false; speaker = false
        audioOff()
        updateProximity()
        LumoService.callMode(ctx, false, false)
        if (wasCaller && cid != null) scope.launch {
            AppModel.send(cid, "call", meta = jsonOf("status" to (if (dur > 0) "ended" else status), "duration" to dur, "video" to wasVideo))
        }
        if (status == "ended" && remote) AppModel.say("Звонок завершён")
    }

    // ---------- звук ----------

    private fun am() = ctx.getSystemService(AudioManager::class.java)

    private fun audioOn() {
        val a = am()
        savedMode = a.mode
        a.mode = AudioManager.MODE_IN_COMMUNICATION
        applySpeaker()
    }

    private fun audioOff() {
        val a = am()
        if (Build.VERSION.SDK_INT >= 31) runCatching { a.clearCommunicationDevice() } else @Suppress("DEPRECATION") { a.isSpeakerphoneOn = false }
        a.mode = AudioManager.MODE_NORMAL
    }

    private fun applySpeaker() {
        val a = am()
        if (Build.VERSION.SDK_INT >= 31) {
            val devs = a.availableCommunicationDevices
            val want = if (speaker) devs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            else devs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO || it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET || it.type == AudioDeviceInfo.TYPE_USB_HEADSET }
                ?: devs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
            if (want != null) runCatching { a.setCommunicationDevice(want) }
        } else @Suppress("DEPRECATION") { a.isSpeakerphoneOn = speaker }
        updateProximity()
    }

    /** Аудиозвонок у уха — экран гаснет */
    private fun updateProximity() {
        val on = (state == State.Calling || state == State.Connecting || state == State.Active) && !(video && !camOff) && !speaker
        val pm = ctx.getSystemService(PowerManager::class.java)
        if (on && proximity == null && pm.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
            proximity = pm.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "lumo:call").also { it.acquire(3 * 3600_000L) }
        } else if (!on && proximity != null) {
            runCatching { proximity?.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY) }; proximity = null
        }
    }

    // ---------- WebRTC ----------

    private fun prepareLocalMedia() {
        val f = factory()
        if (audioTrack == null) {
            val src = f.createAudioSource(MediaConstraints())
            audioTrack = f.createAudioTrack("a0", src).also { it.setEnabled(!muted) }
        }
        if (video && localVideo == null && camOk) {
            val en = Camera2Enumerator(ctx)
            val name = en.deviceNames.firstOrNull { en.isFrontFacing(it) } ?: en.deviceNames.firstOrNull() ?: return
            val cap = en.createCapturer(name, null) ?: return
            val vs = f.createVideoSource(false)
            val th = SurfaceTextureHelper.create("lumo-cam", eglBase.eglBaseContext)
            cap.initialize(th, ctx, vs.capturerObserver)
            cap.startCapture(1280, 720, 30)
            capturer = cap; videoSource = vs; texHelper = th
            localVideo = f.createVideoTrack("v0", vs).also { it.addSink(Relay.sink) }
        }
        updateProximity()
    }

    private suspend fun loadIce(): List<PeerConnection.IceServer> {
        iceServers?.let { return it }
        val list = mutableListOf<PeerConnection.IceServer>()
        val j = runCatching { Api.function("/ice") }.getOrNull() as? JSONObject
        j?.optJSONArray("iceServers").objects().forEach { s ->
            val urls = s.optJSONArray("urls")?.let { a -> (0 until a.length()).map { a.optString(it) } } ?: listOfNotNull(s.str("urls"))
            if (urls.isEmpty()) return@forEach
            val b = PeerConnection.IceServer.builder(urls)
            s.str("username")?.let { b.setUsername(it) }; s.str("credential")?.let { b.setPassword(it) }
            list.add(b.createIceServer())
        }
        if (list.isEmpty()) list.add(PeerConnection.IceServer.builder(listOf("stun:stun.l.google.com:19302", "stun:stun.cloudflare.com:3478")).createIceServer())
        iceServers = list
        return list
    }

    private suspend fun makePC() {
        if (pc != null) return
        val servers = loadIce()
        if (state == State.Idle) return
        val cfg = PeerConnection.RTCConfiguration(servers).apply {
            sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
            continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
            iceCandidatePoolSize = 4
        }
        val p = factory().createPeerConnection(cfg, Observer) ?: return
        pc = p; restarts = 0
        audioTrack?.let { p.addTrack(it, listOf("lm")) }
        localVideo?.let { p.addTrack(it, listOf("lm")) }
    }

    private fun createOffer(restart: Boolean = false) {
        val p = pc ?: return
        val c = MediaConstraints().apply {
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveVideo", if (video) "true" else "false"))
            if (restart) mandatory.add(MediaConstraints.KeyValuePair("IceRestart", "true"))
        }
        p.createOffer(Sdp(onCreate = { sdp ->
            val tuned = SessionDescription(sdp.type, opusTune(sdp.description))
            scope.launch {
                if (pc !== p) return@launch
                p.setLocalDescription(Sdp(), tuned)
                secJob?.join()
                sig(peerId ?: "", signed(jsonOf("t" to "offer", "sdp" to jsonOf("type" to "offer", "sdp" to tuned.description)), "offer", tuned.description))
            }
        }), c)
    }

    private fun handleOffer(msg: JSONObject) {
        val p = pc ?: return
        val s = msg.obj("sdp").str("sdp") ?: return
        val id = callId
        scope.launch {
            secJob?.join()
            if (callId != id || pc !== p) return@launch
            if (!sdpOk(msg, "offer")) { tampered(); return@launch }
            applyOffer(p, s)
        }
    }

    private fun applyOffer(p: PeerConnection, s: String) {
        p.setRemoteDescription(Sdp(onSet = {
            scope.launch {
                if (pc !== p) return@launch
                flushIce()
                val c = MediaConstraints().apply {
                    mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
                    mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"))
                }
                p.createAnswer(Sdp(onCreate = { sdp ->
                    val tuned = SessionDescription(sdp.type, opusTune(sdp.description))
                    scope.launch {
                        if (pc !== p) return@launch
                        p.setLocalDescription(Sdp(), tuned)
                        secJob?.join()
                        sig(peerId ?: "", signed(jsonOf("t" to "answer", "sdp" to jsonOf("type" to "answer", "sdp" to tuned.description)), "answer", tuned.description))
                    }
                }), c)
            }
        }), SessionDescription(SessionDescription.Type.OFFER, s))
    }

    private fun flushIce() {
        val p = pc ?: return
        iceQueue.forEach { p.addIceCandidate(it) }
        iceQueue.clear()
    }

    /** Устойчивый звук Opus, как на сайте */
    fun opusTune(sdp: String): String {
        val m = Regex("a=rtpmap:(\\d+) opus/48000", RegexOption.IGNORE_CASE).find(sdp) ?: return sdp
        val pt = m.groupValues[1]
        return sdp.split("\r\n").joinToString("\r\n") { l ->
            if (l.startsWith("a=fmtp:$pt ")) {
                var q = l
                if (!q.contains("useinbandfec")) q += ";useinbandfec=1"
                if (!q.contains("maxaveragebitrate")) q += ";maxaveragebitrate=48000"
                q
            } else l
        }
    }

    private fun connectionChanged(p: PeerConnection, s: PeerConnection.PeerConnectionState) {
        if (pc !== p) return
        log("pc", jsonOf("s" to s.name))
        when (s) {
            PeerConnection.PeerConnectionState.CONNECTED -> {
                restarts = 0; statusText = ""
                becomeActive()
                p2p = true; relayImage = null
                Relay.stopAudio()
                applySpeaker()
            }
            PeerConnection.PeerConnectionState.FAILED, PeerConnection.PeerConnectionState.DISCONNECTED -> {
                p2p = false
                scope.launch {
                    delay(if (s == PeerConnection.PeerConnectionState.FAILED) 500 else 4000)
                    if (pc !== p || p.connectionState() == PeerConnection.PeerConnectionState.CONNECTED || restarts >= 3) return@launch
                    restarts++
                    if (role == "caller") createOffer(true) else sig(peerId ?: "", jsonOf("t" to "restart"))
                }
            }
            else -> {}
        }
    }

    private fun becomeActive() {
        if (startedAt != null || state != State.Connecting) return
        startedAt = now(); state = State.Active; statusText = ""
        heartbeat?.cancel()
        heartbeat = scope.launch { while (state == State.Active) { delay(4000); peerId?.let { sig(it, jsonOf("t" to "hb")) } } }
        lastPeer = now()
    }

    private fun direct() = runCatching { pc?.connectionState() == PeerConnection.PeerConnectionState.CONNECTED }.getOrDefault(false)

    // ---------- резервный канал ----------

    private fun startRelay() {
        relaySeq = 0; relayRSeq = -1; pendingJPEG = null
        Relay.muted = muted
        relayJob?.cancel()
        relayJob = scope.launch { while (true) { delay(200); relayTick() } }
    }

    private fun relayTick() {
        if (state != State.Connecting && state != State.Active) return
        val peer = peerId ?: return
        val d = direct()
        if (p2p != d) p2p = d
        if (d) { pendingJPEG = null; Relay.stopAudio(); return }
        val sc = secChat
        if (sc == null) { pendingJPEG = null; Relay.stopAudio(); return }
        Relay.startAudio()
        val med = JSONObject()
        var has = false
        Relay.takeAudio()?.let { med.put("a", it); has = true }
        pendingJPEG?.let { med.put("v", it); pendingJPEG = null; has = true }
        if (video && !camOff) Relay.takeJPEG(bg) { j -> scope.launch { pendingJPEG = j } }
        if (!has) return
        val e = E2E.encrypt(sc, med.toString()) ?: return
        val pl = jsonOf("t" to "rm", "s" to relaySeq, "e" to e)
        relaySeq++
        sig(peer, pl)
    }

    private fun onRelay(p: JSONObject, from: String, cid: String) {
        if ((state != State.Connecting && state != State.Active) || cid != callId || from != peerId) return
        val s = p.int("s") ?: 0
        if (s <= relayRSeq && s != 0) return
        relayRSeq = s
        lastPeer = now()
        if (state == State.Connecting) becomeActive()
        if (direct()) return
        val sc = secChat ?: return
        val enc = p.str("e") ?: return
        if (!E2E.isEnc(enc)) return
        val med = runCatching { JSONObject(E2E.decrypt(sc, enc) ?: return) }.getOrNull() ?: return
        med.str("a")?.let { Relay.play(it) }
        med.str("v")?.let { v ->
            bg.execute {
                val b = runCatching { Base64.decode(v, Base64.DEFAULT) }.getOrNull() ?: return@execute
                val bm = BitmapFactory.decodeByteArray(b, 0, b.size) ?: return@execute
                scope.launch { relayImage = bm }
            }
        }
    }

    private fun startWatchdog() {
        connectingSince = now()
        watchdog?.cancel()
        watchdog = scope.launch { while (true) { delay(3000); checkPeerAlive() } }
    }

    private fun checkPeerAlive() {
        if (state == State.Connecting) {
            if (now() - connectingSince > 30_000) {
                peerId?.let { sig(it, jsonOf("t" to "hangup")) }
                end("missed", why = "connect_timeout"); AppModel.say("Не удалось соединиться")
            }
            return
        }
        if (state != State.Active) return
        val silent = now() - lastPeer
        if ((!direct() && silent > 15_000) || silent > 40_000) {
            peerId?.let { sig(it, jsonOf("t" to "hangup")) }
            end("ended", why = "peer_lost"); AppModel.say("Связь с собеседником потеряна")
        }
    }

    private fun now() = System.currentTimeMillis()

    // ---------- наблюдатели WebRTC ----------

    private object Observer : PeerConnection.Observer {
        override fun onSignalingChange(s: PeerConnection.SignalingState?) {}
        override fun onIceConnectionChange(s: PeerConnection.IceConnectionState?) {}
        override fun onIceConnectionReceivingChange(b: Boolean) {}
        override fun onIceGatheringChange(s: PeerConnection.IceGatheringState?) {}
        override fun onIceCandidate(c: IceCandidate) {
            scope.launch {
                val peer = peerId ?: return@launch
                if (pc == null) return@launch
                sig(peer, jsonOf("t" to "ice", "c" to jsonOf("candidate" to c.sdp, "sdpMid" to c.sdpMid, "sdpMLineIndex" to c.sdpMLineIndex)))
            }
        }
        override fun onIceCandidatesRemoved(c: Array<out IceCandidate>?) {}
        override fun onAddStream(s: MediaStream?) {}
        override fun onRemoveStream(s: MediaStream?) {}
        override fun onDataChannel(d: DataChannel?) {}
        override fun onRenegotiationNeeded() {}
        override fun onAddTrack(r: RtpReceiver?, streams: Array<out MediaStream>?) {}
        override fun onTrack(t: RtpTransceiver) {
            val track = t.receiver.track() as? VideoTrack ?: return
            scope.launch {
                remoteVideo = track
                if (!video && state == State.Active) { video = true; speaker = true; applySpeaker() }
            }
        }
        override fun onConnectionChange(s: PeerConnection.PeerConnectionState) {
            scope.launch { pc?.let { connectionChanged(it, s) } }
        }
    }

    private class Sdp(val onCreate: ((SessionDescription) -> Unit)? = null, val onSet: (() -> Unit)? = null) : SdpObserver {
        override fun onCreateSuccess(s: SessionDescription) { onCreate?.invoke(s) }
        override fun onSetSuccess() { onSet?.invoke() }
        override fun onCreateFailure(e: String?) {}
        override fun onSetFailure(e: String?) {}
    }


    /** Проверка WebRTC на устройстве: два соединения внутри телефона договариваются и соединяются */
    fun selfTest() {
        scope.launch {
            try {
                val f = factory()
                val cfg = PeerConnection.RTCConfiguration(emptyList()).apply { sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN }
                var b: PeerConnection? = null
                var a: PeerConnection? = null
                fun obs(other: () -> PeerConnection?, name: String) = object : PeerConnection.Observer by Observer {
                    override fun onIceCandidate(c: IceCandidate) { scope.launch { other()?.addIceCandidate(c) } }
                    override fun onConnectionChange(s: PeerConnection.PeerConnectionState) { android.util.Log.i("LUMO_SELFTEST", "$name $s") }
                    override fun onTrack(t: RtpTransceiver) {}
                }
                a = f.createPeerConnection(cfg, obs({ b }, "A"))!!
                b = f.createPeerConnection(cfg, obs({ a }, "B"))!!
                val at = f.createAudioTrack("t0", f.createAudioSource(MediaConstraints()))
                a.addTrack(at, listOf("s"))
                a.createOffer(Sdp(onCreate = { o ->
                    scope.launch {
                        a.setLocalDescription(Sdp(), o)
                        b.setRemoteDescription(Sdp(onSet = {
                            scope.launch {
                                b.createAnswer(Sdp(onCreate = { ans ->
                                    scope.launch { b.setLocalDescription(Sdp(), ans); a.setRemoteDescription(Sdp(), ans) }
                                }), MediaConstraints())
                            }
                        }), o)
                    }
                }), MediaConstraints())
                android.util.Log.i("LUMO_SELFTEST", "started; opus=" + (Relay.javaClass.name))
            } catch (e: Throwable) { android.util.Log.e("LUMO_SELFTEST", "FAIL $e") }
        }
    }
    /** Проверка экрана входящего звонка на заблокированном телефоне (через 8 секунд) */
    fun demoRing(name: String) {
        scope.launch {
            delay(8000)
            peerName = name; peerColor = 0; video = false; callId = "demo"; peerId = "u1"; role = "callee"
            state = State.Incoming; statusText = "Входящий звонок"
            startRinging()
        }
    }

    /** Для скриншотов */
    fun demoIncoming(name: String) { peerName = name; peerColor = 0; video = false; state = State.Incoming; statusText = "Входящий звонок" }
}

/** Резервный канал: звук μ-law 16 кГц и кадры JPEG шириной 320 */
object Relay {
    @Volatile var muted = false
    private val lock = Any()
    private var captured = ShortArray(0)
    private var capturedN = 0
    @Volatile private var admAt = 0L
    @Volatile private var running = false
    private var rec: AudioRecord? = null
    private var recThread: Thread? = null
    private var out: AudioTrack? = null
    /** Маленькая копия кадра (320 px) для резервного канала. Сам кадр камеры не удерживаем — иначе камера «замирает» */
    @Volatile private var latest: Pair<VideoFrame.I420Buffer, Int>? = null
    @Volatile private var want = false
    @Volatile private var jpegBusy = false

    val sink = VideoSink { f ->
        if (!want) return@VideoSink
        want = false
        try {
            val b = f.buffer
            val w = b.width; val h = b.height
            val tw = 320; val th = (h * 320.0 / w).toInt() and -2
            val scaled = b.cropAndScale(0, 0, w, h, tw, th)
            val i420 = scaled.toI420()
            scaled.release()
            if (i420 != null) { val old = latest; latest = i420 to f.rotation; old?.first?.release() }
        } catch (_: Throwable) {}
    }

    private fun append(s: ShortArray, n: Int) {
        if (muted || !running) return
        synchronized(lock) {
            if (captured.size < capturedN + n) captured = captured.copyOf(maxOf(capturedN + n, captured.size * 2, 4096))
            System.arraycopy(s, 0, captured, capturedN, n)
            capturedN += n
            if (capturedN > 16000) { System.arraycopy(captured, capturedN - 8000, captured, 0, 8000); capturedN = 8000 }
        }
    }

    /** Звук микрофона из WebRTC (если он уже пишет) — переводим в 16 кГц моно */
    fun fromAdm(data: ByteArray, rate: Int, channels: Int) {
        if (!running) return
        admAt = System.currentTimeMillis()
        val frames = data.size / 2 / channels
        val step = rate / 16000.0
        val n = (frames / step).toInt()
        val o = ShortArray(n)
        for (i in 0 until n) {
            val fi = (i * step).toInt() * channels
            val lo = data[fi * 2].toInt() and 0xff; val hi = data[fi * 2 + 1].toInt()
            o[i] = ((hi shl 8) or lo).toShort()
        }
        append(o, n)
    }

    @SuppressLint("MissingPermission")
    fun startAudio() {
        if (running) return
        running = true
        synchronized(lock) { capturedN = 0 }
        val ob = AudioTrack.getMinBufferSize(16000, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        out = runCatching {
            AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                .setAudioFormat(AudioFormat.Builder().setSampleRate(16000).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).setEncoding(AudioFormat.ENCODING_PCM_16BIT).build())
                .setBufferSizeInBytes(maxOf(ob, 16000)).setTransferMode(AudioTrack.MODE_STREAM).build().also { it.play() }
        }.getOrNull()
        // свой микрофон — пока WebRTC сам не пишет звук
        recThread = Thread {
            val ib = maxOf(AudioRecord.getMinBufferSize(16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT), 3200)
            val buf = ShortArray(800)
            while (running) {
                val admLive = System.currentTimeMillis() - admAt < 600
                if (admLive) { stopRec(); Thread.sleep(100); continue }
                if (rec == null) {
                    rec = runCatching {
                        AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, 16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, ib).also { it.startRecording() }
                    }.getOrNull()
                    if (rec == null) { Thread.sleep(300); continue }
                }
                val n = rec?.read(buf, 0, buf.size) ?: 0
                if (n > 0) append(buf, n) else Thread.sleep(20)
            }
            stopRec()
        }.also { it.start() }
    }

    private fun stopRec() { runCatching { rec?.stop() }; runCatching { rec?.release() }; rec = null }

    fun stopAudio() {
        if (!running) return
        running = false
        recThread = null
        runCatching { out?.stop() }; runCatching { out?.release() }; out = null
        synchronized(lock) { capturedN = 0 }
    }

    fun stop() {
        stopAudio()
        latest?.first?.release(); latest = null; want = false
    }

    fun takeAudio(): String? {
        val s: ShortArray
        synchronized(lock) { if (capturedN == 0) return null; s = captured.copyOf(capturedN); capturedN = 0 }
        if (muted) return null
        val u = ByteArray(s.size) { muEnc(s[it].toInt()) }
        return Base64.encodeToString(u, Base64.NO_WRAP)
    }

    fun play(b64: String) {
        val t = out ?: return
        val d = runCatching { Base64.decode(b64, Base64.DEFAULT) }.getOrNull() ?: return
        val pcm = ShortArray(d.size) { MUD[d[it].toInt() and 0xff] }
        runCatching { t.write(pcm, 0, pcm.size, AudioTrack.WRITE_NON_BLOCKING) }
    }

    fun takeJPEG(ex: java.util.concurrent.Executor, done: (String) -> Unit) {
        want = true
        if (jpegBusy) return
        val (i420, rot) = latest ?: return
        latest = null
        jpegBusy = true
        ex.execute {
            try {
                val tw = i420.width; val th = i420.height
                val nv21 = ByteArray(tw * th * 3 / 2)
                val y = i420.dataY; val u = i420.dataU; val v = i420.dataV
                for (r in 0 until th) { y.position(r * i420.strideY); y.get(nv21, r * tw, tw) }
                var o = tw * th
                for (r in 0 until th / 2) for (c in 0 until tw / 2) {
                    nv21[o++] = v.get(r * i420.strideV + c); nv21[o++] = u.get(r * i420.strideU + c)
                }
                val bos = ByteArrayOutputStream()
                YuvImage(nv21, android.graphics.ImageFormat.NV21, tw, th, null).compressToJpeg(Rect(0, 0, tw, th), 60, bos)
                var bytes = bos.toByteArray()
                if (rot != 0) {
                    val bm = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                    val rb = Bitmap.createBitmap(bm, 0, 0, bm.width, bm.height, Matrix().apply { postRotate(rot.toFloat()) }, true)
                    val b2 = ByteArrayOutputStream(); rb.compress(Bitmap.CompressFormat.JPEG, 60, b2); bytes = b2.toByteArray()
                }
                done(Base64.encodeToString(bytes, Base64.NO_WRAP))
            } catch (_: Throwable) {
            } finally { i420.release(); jpegBusy = false }
        }
    }

    private val MUD = ShortArray(256) { i ->
        val u = i.inv() and 0xff
        val sg = u and 0x80; val ex = (u shr 4) and 7; val mn = u and 0x0f
        var x = ((mn shl 3) + 0x84) shl ex
        x -= 0x84
        (if (sg != 0) -x else x).toShort()
    }

    private fun muEnc(v: Int): Byte {
        var x = v
        val sg = if (x < 0) 0x80 else 0
        if (sg != 0) x = -x
        if (x > 32635) x = 32635
        x += 0x84
        var ex = 7; var m = 0x4000
        while ((x and m) == 0 && ex > 0) { ex--; m = m shr 1 }
        val mn = (x shr (ex + 3)) and 0x0f
        return (sg or (ex shl 4) or mn).inv().toByte()
    }
}
