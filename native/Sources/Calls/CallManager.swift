import Foundation
import AVFoundation
import CallKit
import AudioToolbox
import UserNotifications
import UIKit
import WebRTC

/// Звонки Lumo: тот же протокол, что у сайта (сигналы через канал lm-call-<id>), звук и видео — WebRTC,
/// входящий звонок показывается системным экраном iOS (CallKit), в том числе на заблокированном экране.
@MainActor
final class CallManager: NSObject, ObservableObject, RTCPeerConnectionDelegate, CXProviderDelegate {
    static let shared = CallManager()

    enum State { case idle, calling, incoming, connecting, active }

    @Published var state: State = .idle { didSet { updateProximity() } }
    @Published var video = false { didSet { updateProximity() } }
    @Published var muted = false
    @Published var speaker = false { didSet { updateProximity() } }
    @Published var camOff = false
    @Published var peerCamOff = false
    @Published var startedAt: Date?
    @Published var peerName = ""
    @Published var peerAvatar: String?
    @Published var peerColor = 0
    @Published var remoteVideo: RTCVideoTrack?
    @Published var localVideo: RTCVideoTrack?
    @Published var showUI = false
    @Published var statusText = ""
    /// Кадр собеседника через резервный канал (когда прямого соединения нет)
    @Published var relayImage: UIImage?
    @Published var p2p = false

    private(set) var peerId: String?
    private var callId: String?
    private var role = ""
    private var chatId: String?
    private var secChat: String?
    private var secTask: Task<Void, Never>?
    private var uuid: UUID?
    private var myId: String?
    private var myChannel: Realtime.Channel?
    private var outChannels: [String: Realtime.Channel] = [:]
    private var doneCalls = Set<String>()
    private var pc: RTCPeerConnection?
    private var pendingOffer: JSON?
    private var iceQueue: [RTCIceCandidate] = []
    private var audioTrack: RTCAudioTrack?
    private var capturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?
    private var front = true
    private var reRing: Timer?
    private var timeout: Timer?
    private var heartbeat: Timer?
    private var restarts = 0
    /// Когда сняли трубку — в первые секунды после этого системный экран звонка иногда сам «сбрасывает» вызов
    private var answeredAt: Date?
    /// Последний сигнал от собеседника — если связи нет долго, завершаем звонок у себя
    private var lastPeer = Date()
    private var watchdog: Timer?
    private var manualUsed = false
    private let relay = CallRelay()
    private var relayTimer: Timer?
    private var relaySeq = 0
    private var relayRSeq = -1
    private var pendingJPEG: String?
    private var audioActive = false
    /// На некоторых iPhone системный экран звонка (CallKit) недоступен — сразу сбрасывается.
    /// Тогда звоним без него: своё окно звонка, свой звонок-мелодия и уведомление.
    private var callKitBroken: Bool {
        get { Date().timeIntervalSince1970 - UserDefaults.standard.double(forKey: "lm_ck_broken_at") < 3 * 86400 }
        set { UserDefaults.standard.set(newValue ? Date().timeIntervalSince1970 : 0, forKey: "lm_ck_broken_at") }
    }
    private var ringTimer: Timer?
    private var iceServers: [RTCIceServer]?
    private let provider: CXProvider
    private let controller = CXCallController()

    private static let factory: RTCPeerConnectionFactory = {
        _ = RTCInitializeSSL()
        return RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(),
                                        decoderFactory: RTCDefaultVideoDecoderFactory())
    }()

    private override init() {
        let cfg = CXProviderConfiguration()
        cfg.supportsVideo = true
        cfg.maximumCallsPerCallGroup = 1
        cfg.maximumCallGroups = 1
        cfg.supportedHandleTypes = [.generic]
        cfg.includesCallsInRecents = false
        provider = CXProvider(configuration: cfg)
        super.init()
        provider.setDelegate(self, queue: nil)
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
    }

    // MARK: - каналы сигналов

    func attach(myId id: String) {
        guard myId != id else { return }
        myId = id
        let ch = Realtime.shared.channel("lm-call-" + id)
        ch.onBroadcast = { [weak self] event, payload in
            guard event == "sig" else { return }
            self?.onSig(payload)
        }
        myChannel = ch
    }

    func detach() {
        if state != .idle { hangup() }
        if let id = myId { Realtime.shared.leave("lm-call-" + id) }
        for k in outChannels.keys { Realtime.shared.leave("lm-call-" + k) }
        outChannels = [:]
        myChannel = nil
        myId = nil
    }

    private func outChannel(_ to: String) -> Realtime.Channel {
        if let c = outChannels[to] { return c }
        let c = Realtime.shared.channel("lm-call-" + to)
        outChannels[to] = c
        return c
    }

    /// Защита звонка: ключ личного чата. Если он есть у обоих, данные соединения подписываются, а запасной канал шифруется.
    private func secInit(_ peer: String) {
        secChat = nil
        secTask?.cancel()
        secTask = Task { @MainActor in
            guard let c = AppModel.shared.chats.first(where: { $0.isPrivate && $0.peerId == peer }) else { return }
            await E2E.shared.prepare(c.id, peer: c.peerId)
            if E2E.shared.active(c.id) { secChat = c.id }
        }
    }

    nonisolated private static func sdpFp(_ s: String) -> String {
        guard let re = try? NSRegularExpression(pattern: #"a=fingerprint:(\S+) (\S+)"#, options: [.caseInsensitive]) else { return "" }
        let ns = s as NSString
        var set = Set<String>()
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            set.insert(ns.substring(with: m.range(at: 1)).lowercased() + " " + ns.substring(with: m.range(at: 2)).uppercased())
        }
        return set.sorted().joined(separator: ",")
    }

    private func signed(_ j: JSON, _ typ: String, _ sdp: String) -> JSON {
        var r = j
        if let c = secChat, let a = E2E.shared.encrypt(c, "lumo-call1|\(callId ?? "")|\(typ)|\(CallManager.sdpFp(sdp))") { r["auth"] = a }
        return r
    }

    private func sdpOk(_ msg: JSON, _ typ: String) -> Bool {
        guard let c = secChat else { return true }
        guard let a = msg.str("auth"), E2E.isEnc(a) else { return false }
        return E2E.shared.decrypt(c, a) == "lumo-call1|\(callId ?? "")|\(typ)|\(CallManager.sdpFp(msg.dict("sdp").str("sdp") ?? ""))"
    }

    private func tampered() {
        if let p = peerId { sig(p, ["t": "hangup"]) }
        end("ended", why: "tampered")
        AppModel.shared.say("Звонок остановлен: данные соединения подменены")
    }

    private func sig(_ to: String, _ data: JSON) {
        guard let me = myId, !to.isEmpty else { return }
        var p = data
        p["from"] = me
        if p["callId"] == nil { p["callId"] = callId ?? "" }
        let payload = p
        let ch: Realtime.Channel? = to == me ? myChannel : outChannel(to)
        guard let channel = ch else { return }
        Task { @MainActor in
            await Realtime.shared.waitJoined(channel)
            Realtime.shared.broadcast(channel, event: "sig", payload: payload)
        }
    }

    // MARK: - исходящий звонок

    func startCall(chat: ChatItem, video v: Bool) {
        guard state == .idle else { AppModel.shared.say("Вы уже в звонке"); return }
        guard let peer = chat.peerId, let me = AppModel.shared.me, peer != me.id else { return }
        Task {
            guard await permissions(video: v) else { AppModel.shared.say("Нет доступа к микрофону"); return }
            callId = randomId()
            role = "caller"
            peerId = peer
            chatId = chat.id
            secInit(peer)
            video = v && AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            speaker = video
            muted = false
            camOff = false
            peerCamOff = false
            peerName = chat.displayName
            peerAvatar = chat.displayAvatar
            peerColor = chat.displayColor
            state = .calling
            statusText = "Звонок…"
            log("start", ["to": peer, "video": video])
            showUI = true
            BackgroundKeeper.shared.stop()
            lastPeer = Date()
            manualUsed = false
            if callKitBroken {
                uuid = nil
                manualAudio()
            } else {
                let u = UUID()
                uuid = u
                let action = CXStartCallAction(call: u, handle: CXHandle(type: .generic, value: peerName))
                action.isVideo = video
                controller.request(CXTransaction(action: action)) { @Sendable err in
                    if err != nil { Task { @MainActor in CallManager.shared.uuid = nil; CallManager.shared.manualAudio() } }
                }
            }
            _ = outChannel(peer)
            prepareLocalMedia()
            Task { _ = try? await API.shared.function("/call", body: ["peer_id": peer, "video": video]) }
            let ring: JSON = ["t": "ring", "video": video, "name": me.name, "avatar": me.avatarURL ?? NSNull(),
                              "color": me.color, "chatId": chat.id, "rc": ["a": 0, "v": [String]()]]
            sig(peer, ring)
            let cid = callId
            // «Звонок…» — пока не достучались до собеседника; «Вызов…» — у него уже звонит
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                self.markRinging(cid)
            }
            reRing = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] t in
                Task { @MainActor in
                    guard let self = self, self.state == .calling, self.callId == cid else { t.invalidate(); return }
                    self.sig(peer, ring)
                    self.markRinging(cid)
                }
            }
            timeout = Timer.scheduledTimer(withTimeInterval: 45, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, self.state == .calling, self.callId == cid else { return }
                    self.sig(peer, ["t": "cancel"])
                    self.end("missed", why: "timeout_out")
                }
            }
        }
    }

    /// Собеседник в сети (значит, звонок до него дошёл) или его телефон подтвердил вызов
    private func markRinging(_ cid: String?, confirmed: Bool = false) {
        guard state == .calling, callId == cid, statusText == "Звонок…" else { return }
        if confirmed || AppModel.shared.isOnline(peerId) { statusText = "Вызов…" }
    }

    private func permissions(video: Bool) async -> Bool {
        let mic: Bool = await withCheckedContinuation { c in
            AVAudioSession.sharedInstance().requestRecordPermission { @Sendable granted in c.resume(returning: granted) }
        }
        if !mic { return false }
        if video && AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        return true
    }

    // MARK: - сигналы собеседника

    private func onSig(_ p: JSON) {
        let t = p.str("t") ?? ""
        let from = p.str("from") ?? ""
        let cid = p.str("callId") ?? ""
        if t == "kf" { return }
        if t == "rm" { onRelay(p, from: from, cid: cid); return }
        if t == "ring" {
            if doneCalls.contains(cid) { return }
            if cid != callId { log("ring_in", ["cid": cid, "from": from, "cur": callId ?? ""]) }
            if state != .idle {
                if cid != callId { sig(from, ["t": "busy", "callId": cid]); log("reply_busy", ["cid": cid]) }
                else if state == .incoming { sig(from, ["t": "ringing"]) }
                return
            }
            let cf = AppModel.shared.me?.priv("calls") ?? "all"
            if cf == "none" || (cf == "contacts" && !AppModel.shared.isContact(from)) {
                doneCalls.insert(cid)
                sig(from, ["t": "nocall", "callId": cid])
                return
            }
            callId = cid
            role = "callee"
            peerId = from
            chatId = p.str("chatId")
            secInit(from)
            video = p.bool("video")
            speaker = video
            muted = false
            camOff = false
            peerCamOff = false
            peerName = p.str("name") ?? "Lumo"
            peerAvatar = p.str("avatar")
            peerColor = p.int("color") ?? 0
            state = .incoming
            statusText = video ? "Входящий видеозвонок" : "Входящий звонок"
            showUI = true
            sig(from, ["t": "ringing"])
            reportIncoming()
            timeout = Timer.scheduledTimer(withTimeInterval: 50, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, self.state == .incoming, self.callId == cid else { return }
                    self.end("missed", remote: true, why: "timeout_in")
                }
            }
            return
        }
        if t == "taken" {
            if state == .incoming && cid == callId { end("elsewhere", remote: true, why: "taken") }
            return
        }
        guard state != .idle, cid == callId, from == peerId else { return }
        if t != "ice" && t != "hb" { log("sig_" + t) }
        if state == .incoming && (t == "offer" || t == "ice" || t == "hb") { end("elsewhere", remote: true, why: "elsewhere_sig"); return }
        lastPeer = Date()
        switch t {
        case "ringing":
            markRinging(cid, confirmed: true)
        case "accept":
            guard state == .calling else { return }
            reRing?.invalidate()
            timeout?.invalidate()
            state = .connecting
            statusText = "Соединение…"
            startWatchdog()
            startRelay()
            Task {
                await makePC()
                createOffer()
            }
        case "offer":
            if pc == nil { pendingOffer = p; return }
            handleOffer(p)
        case "answer":
            guard let pc = pc, let s = p.dict("sdp").str("sdp") else { return }
            let id = callId
            Task { @MainActor in
                await self.secTask?.value
                guard self.callId == id, self.pc === pc else { return }
                guard self.sdpOk(p, "answer") else { self.tampered(); return }
                pc.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: s)) { @Sendable _ in
                    Task { @MainActor in CallManager.shared.flushIce() }
                }
            }
        case "ice":
            let c = p.dict("c")
            guard let s = c.str("candidate"), !s.isEmpty else { return }
            let cand = RTCIceCandidate(sdp: s, sdpMLineIndex: Int32(c.int("sdpMLineIndex") ?? 0), sdpMid: c.str("sdpMid"))
            if let pc = pc, pc.remoteDescription != nil { pc.add(cand) { @Sendable _ in } } else { iceQueue.append(cand) }
        case "reject":
            end("rejected", why: "peer_reject")
            AppModel.shared.say("Звонок отклонён")
        case "busy":
            end("missed", why: "peer_busy")
            AppModel.shared.say("Абонент занят")
        case "nocall":
            end("missed", why: "peer_nocall")
            AppModel.shared.say("Пользователь ограничил входящие звонки")
        case "cancel":
            end("missed", remote: true, why: "peer_cancel")
        case "hangup":
            end(startedAt != nil ? "ended" : "missed", remote: true, why: "peer_hangup")
        case "media":
            peerCamOff = p.bool("camOff")
            if p.bool("video") && !video {
                // собеседник включил камеру — показываем его видео и включаем громкую связь
                video = true
                speaker = true
                applySpeaker()
            }
        case "restart":
            if role == "caller" { createOffer(restart: true) }
        default:
            break
        }
    }

    /// Журнал звонка на сервере (для поиска ошибок в бета-версии)
    private func log(_ ev: String, _ info: JSON = [:]) {
        var i = info
        i["state"] = "\(state)"
        let st = UIApplication.shared.applicationState
        i["app"] = st == .active ? "fg" : st == .background ? "bg" : "inactive"
        i["v"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        i["ios"] = UIDevice.current.systemVersion
        i["role"] = role
        let row: JSON = ["call_id": callId ?? (info["cid"] as? String ?? ""), "ev": ev, "info": i]
        Task { _ = try? await API.shared.raw("POST", "/rest/v1/lm_call_log", body: row, headers: ["Prefer": "return=minimal"]) }
    }

    /// Только для скриншотов: показать входящий звонок
    func demoIncoming(name: String) {
        peerName = name
        peerColor = 0
        video = false
        state = .incoming
        statusText = "Входящий звонок"
        showUI = true
    }

    /// Аудиозвонок у уха — экран гаснет (датчик приближения)
    private func updateProximity() {
        let on = (state == .calling || state == .connecting || state == .active) && !video && !speaker
        if UIDevice.current.isProximityMonitoringEnabled != on { UIDevice.current.isProximityMonitoringEnabled = on }
    }

    /// Пока звонят, а Lumo свёрнут — уведомление «вам звонят» каждые 5 секунд
    private var callNotifyTimer: Timer?
    private var callNotifyCount = 0

    private func startCallNotifications() {
        callNotifyTimer?.invalidate()
        callNotifyCount = 0
        postCallNotification()
        callNotifyTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { t in
            Task { @MainActor in
                let cm = CallManager.shared
                guard cm.state == .incoming else { t.invalidate(); return }
                cm.postCallNotification()
            }
        }
    }

    private func postCallNotification() {
        guard state == .incoming, UIApplication.shared.applicationState != .active, let c = chatId ?? peerId else { return }
        let base = "call-" + (callId ?? "")
        let center = UNUserNotificationCenter.current()
        if callNotifyCount > 0 { center.removeDeliveredNotifications(withIdentifiers: [base + "-\(callNotifyCount - 1)"]) }
        Notifier.show(id: base + "-\(callNotifyCount)", title: peerName,
                      body: video ? "Вам звонят по видео — нажмите, чтобы ответить" : "Вам звонят — нажмите, чтобы ответить",
                      chatId: c)
        callNotifyCount += 1
    }

    private func stopCallNotifications() {
        callNotifyTimer?.invalidate()
        callNotifyTimer = nil
        let base = "call-" + (callId ?? "")
        let ids = (0...max(0, callNotifyCount)).map { base + "-\($0)" }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        callNotifyCount = 0
    }

    /// Свой сигнал входящего звонка (если CallKit недоступен)
    private func startOwnRing() {
        ringTimer?.invalidate()
        let ring = {
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
        ring()
        // приложение свёрнуто — не даём iOS его усыпить, пока звонит
        if UIApplication.shared.applicationState != .active { BackgroundKeeper.shared.start(force: true) }
        ringTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { t in
            Task { @MainActor in
                guard CallManager.shared.state == .incoming else { t.invalidate(); return }
                AudioServicesPlayAlertSound(SystemSoundID(1005))
            }
        }
        log("own_ring")
    }

    private func stopOwnRing() {
        ringTimer?.invalidate()
        ringTimer = nil
        stopCallNotifications()
    }

    private func reportIncoming() {
        startCallNotifications()
        if callKitBroken {
            uuid = nil
            startOwnRing()
            return
        }
        let u = UUID()
        uuid = u
        let up = CXCallUpdate()
        up.remoteHandle = CXHandle(type: .generic, value: peerName)
        up.localizedCallerName = peerName
        up.hasVideo = video
        up.supportsHolding = false
        up.supportsGrouping = false
        up.supportsUngrouping = false
        up.supportsDTMF = false
        // свёрнуто — не даём iOS усыпить Lumo, пока звонят (чтобы приходили уведомления и можно было ответить)
        if UIApplication.shared.applicationState == .active { BackgroundKeeper.shared.stop() } else { BackgroundKeeper.shared.start(force: true) }
        provider.reportNewIncomingCall(with: u, update: up) { @Sendable err in
            let e = err.map { "\($0)" }
            Task { @MainActor in
                let cm = CallManager.shared
                cm.log(e == nil ? "report_ok" : "report_err", ["err": e ?? ""])
                if e != nil {
                    // системный экран звонка не показался — звоним своим окном, звуком и уведомлениями
                    cm.uuid = nil
                    cm.callKitBroken = true
                    if cm.state == .incoming { cm.startOwnRing() }
                }
            }
        }
    }

    // MARK: - действия на экране звонка

    func answerTapped() {
        guard state == .incoming else { return }
        if let u = uuid {
            controller.request(CXTransaction(action: CXAnswerCallAction(call: u))) { @Sendable err in
                if err != nil { Task { @MainActor in CallManager.shared.manualAudio(); await CallManager.shared.acceptCall() } }
            }
        } else {
            manualAudio()
            Task { await acceptCall() }
        }
    }

    func endTapped() {
        if state == .incoming { reject() } else { hangup() }
    }

    func toggleMute() {
        muted.toggle()
        audioTrack?.isEnabled = !muted
        relay.muted = muted
    }

    func toggleSpeaker() {
        speaker.toggle()
        applySpeaker()
    }

    func toggleCamera() {
        // аудиозвонок — включаем камеру прямо во время разговора
        if localVideo == nil { enableVideo(); return }
        camOff.toggle()
        if !camOff && !speaker { speaker = true; applySpeaker() }
        localVideo?.isEnabled = !camOff
        if let p = peerId { sig(p, ["t": "media", "camOff": camOff]) }
    }

    /// Включить камеру во время аудиозвонка: добавляем видео в соединение и договариваемся заново; включаем громкую связь
    func enableVideo() {
        guard state == .active || state == .connecting else { return }
        Task {
            if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
                guard await AVCaptureDevice.requestAccess(for: .video) else {
                    AppModel.shared.say("Нет доступа к камере — разрешите его в Настройках iPhone")
                    return
                }
            }
            guard state == .active || state == .connecting, localVideo == nil else { return }
            video = true
            camOff = false
            prepareLocalMedia()
            if let p = pc, let v = localVideo {
                _ = p.add(v, streamIds: ["lm"])
                createOffer()
            }
            speaker = true
            configureAudio()
            applySpeaker()
            if let peer = peerId { sig(peer, ["t": "media", "camOff": false, "video": true]) }
            log("video_on")
        }
    }

    func flipCamera() {
        guard let cap = capturer else { return }
        front.toggle()
        cap.stopCapture { @Sendable in
            Task { @MainActor in CallManager.shared.startCapture() }
        }
    }

    private func acceptCall() async {
        guard state == .incoming else { return }
        log("accept_call")
        stopOwnRing()
        BackgroundKeeper.shared.stop()
        timeout?.invalidate()
        answeredAt = Date()
        lastPeer = Date()
        state = .connecting
        startWatchdog()
        statusText = "Соединение…"
        let id = callId
        guard await permissions(video: video) else { reject(); return }
        if video && AVCaptureDevice.authorizationStatus(for: .video) != .authorized { video = false }
        guard callId == id, state == .connecting, let peer = peerId else { return }
        prepareLocalMedia()
        sig(peer, ["t": "accept", "rc": ["a": 0, "v": [String]()]])
        startRelay()
        if let me = myId { sig(me, ["t": "taken"]) }
        await makePC()
        guard callId == id, pc != nil else { return }
        if let po = pendingOffer {
            pendingOffer = nil
            handleOffer(po)
        }
    }

    private func reject() {
        guard state == .incoming, let p = peerId else { return }
        sig(p, ["t": "reject"])
        if let me = myId { sig(me, ["t": "taken"]) }
        end("rejected", why: "self_reject")
    }

    func hangup() {
        guard state != .idle, let p = peerId else { return }
        sig(p, ["t": state == .calling ? "cancel" : "hangup"])
        end(startedAt != nil ? "ended" : "missed", why: "self_hangup")
    }

    func end(_ status: String, remote: Bool = false, why: String = "") {
        guard state != .idle else { return }
        log("end", ["status": status, "remote": remote, "why": why])
        stopOwnRing()
        let wasCaller = role == "caller"
        let dur = startedAt.map { Int(Date().timeIntervalSince($0).rounded()) } ?? 0
        let cid = chatId
        let wasVideo = video
        if let id = callId { doneCalls.insert(id) }
        reRing?.invalidate()
        timeout?.invalidate()
        heartbeat?.invalidate()
        watchdog?.invalidate()
        watchdog = nil
        answeredAt = nil
        capturer?.stopCapture()
        capturer = nil
        pc?.close()
        pc = nil
        audioTrack = nil
        localVideo?.remove(relay)
        localVideo = nil
        relayTimer?.invalidate()
        relayTimer = nil
        relay.stopAudio()
        relayImage = nil
        pendingJPEG = nil
        p2p = false
        audioActive = false
        remoteVideo = nil
        videoSource = nil
        pendingOffer = nil
        iceQueue = []
        secTask?.cancel(); secChat = nil
        if let u = uuid {
            if remote {
                let reason: CXCallEndedReason = status == "missed" ? .unanswered : status == "elsewhere" ? .answeredElsewhere : .remoteEnded
                provider.reportCall(with: u, endedAt: nil, reason: reason)
            } else {
                controller.request(CXTransaction(action: CXEndCallAction(call: u))) { @Sendable _ in }
            }
        }
        uuid = nil
        state = .idle
        startedAt = nil
        callId = nil
        peerId = nil
        role = ""
        showUI = false
        muted = false
        camOff = false
        peerCamOff = false
        statusText = ""
        let rs = RTCAudioSession.sharedInstance()
        rs.isAudioEnabled = false
        if manualUsed {
            // звук включали сами — сами и выключаем, чтобы фон (и входящие звонки при свёрнутом приложении) работал как раньше
            rs.lockForConfiguration()
            try? rs.setActive(false)
            rs.unlockForConfiguration()
            manualUsed = false
        }
        if wasCaller, let c = cid {
            Task { await AppModel.shared.send(chatId: c, kind: "call", meta: ["status": dur > 0 ? "ended" : status, "duration": dur, "video": wasVideo]) }
        }
        if status == "ended" && remote { AppModel.shared.say("Звонок завершён") }
        if UIApplication.shared.applicationState == .background { BackgroundKeeper.shared.start() }
    }

    // MARK: - звук

    private func configureAudio() {
        let s = RTCAudioSession.sharedInstance()
        s.lockForConfiguration()
        try? s.setCategory(.playAndRecord, mode: video ? .videoChat : .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
        s.unlockForConfiguration()
    }

    /// Если системный экран звонка недоступен — включаем звук сами
    func manualAudio() {
        manualUsed = true
        BackgroundKeeper.shared.stop()
        configureAudio()
        let s = RTCAudioSession.sharedInstance()
        s.lockForConfiguration()
        try? s.setActive(true)
        s.unlockForConfiguration()
        audioActive = true
        updateAudio()
        applySpeaker()
    }

    private func applySpeaker() {
        let s = RTCAudioSession.sharedInstance()
        s.lockForConfiguration()
        try? s.overrideOutputAudioPort(speaker ? .speaker : .none)
        s.unlockForConfiguration()
    }

    // MARK: - WebRTC

    private func prepareLocalMedia() {
        let f = Self.factory
        if audioTrack == nil {
            let src = f.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
            let a = f.audioTrack(with: src, trackId: "a0")
            a.isEnabled = !muted
            audioTrack = a
        }
        if video && localVideo == nil {
            let vs = f.videoSource()
            videoSource = vs
            capturer = RTCCameraVideoCapturer(delegate: vs)
            localVideo = f.videoTrack(with: vs, trackId: "v0")
            localVideo?.add(relay)
            front = true
            startCapture()
        }
    }

    private func startCapture() {
        guard let cap = capturer else { return }
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let dev = devices.first(where: { $0.position == (front ? .front : .back) }) ?? devices.first else { return }
        let formats = RTCCameraVideoCapturer.supportedFormats(for: dev)
        func area(_ f: AVCaptureDevice.Format) -> Int {
            let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
            return Int(d.width) * Int(d.height)
        }
        let fit = formats.filter {
            let d = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
            return d.width <= 1280 && d.height <= 720
        }
        guard let fmt = fit.max(by: { area($0) < area($1) }) ?? formats.first else { return }
        let maxFps = fmt.videoSupportedFrameRateRanges.map { $0.maxFrameRate }.max() ?? 30
        cap.startCapture(with: dev, format: fmt, fps: Int(min(30, maxFps)))
    }

    private func loadIce() async -> [RTCIceServer] {
        if let s = iceServers { return s }
        var list: [RTCIceServer] = []
        if let j = (try? await API.shared.function("/ice")) as? JSON, let arr = j["iceServers"] as? [JSON] {
            for s in arr {
                var urls: [String] = []
                if let u = s["urls"] as? [String] { urls = u } else if let u = s["urls"] as? String { urls = [u] }
                if urls.isEmpty { continue }
                list.append(RTCIceServer(urlStrings: urls, username: s.str("username"), credential: s.str("credential")))
            }
        }
        if list.isEmpty { list = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302", "stun:stun.cloudflare.com:3478"])] }
        iceServers = list
        return list
    }

    private func makePC() async {
        if pc != nil { return }
        let servers = await loadIce()
        guard state != .idle else { return }
        let cfg = RTCConfiguration()
        cfg.iceServers = servers
        cfg.sdpSemantics = .unifiedPlan
        cfg.continualGatheringPolicy = .gatherContinually
        cfg.iceCandidatePoolSize = 4
        let cons = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        guard let p = Self.factory.peerConnection(with: cfg, constraints: cons, delegate: self) else { return }
        pc = p
        restarts = 0
        if let a = audioTrack { _ = p.add(a, streamIds: ["lm"]) }
        if let v = localVideo { _ = p.add(v, streamIds: ["lm"]) }
    }

    private func createOffer(restart: Bool = false) {
        guard let p = pc else { return }
        var mand = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": video ? "true" : "false"]
        if restart { mand["IceRestart"] = "true" }
        p.offer(for: RTCMediaConstraints(mandatoryConstraints: mand, optionalConstraints: nil)) { @Sendable sdp, _ in
            guard let sdp = sdp else { return }
            let tuned = RTCSessionDescription(type: sdp.type, sdp: CallManager.opusTune(sdp.sdp))
            Task { @MainActor in
                let cm = CallManager.shared
                guard cm.pc === p else { return }
                p.setLocalDescription(tuned) { @Sendable _ in }
                await cm.secTask?.value
                guard cm.pc === p else { return }
                cm.sig(cm.peerId ?? "", cm.signed(["t": "offer", "sdp": ["type": "offer", "sdp": tuned.sdp]], "offer", tuned.sdp))
            }
        }
    }

    private func handleOffer(_ msg: JSON) {
        guard let p = pc, let s = msg.dict("sdp").str("sdp") else { return }
        let id = callId
        Task { @MainActor in
            await self.secTask?.value
            guard self.callId == id, self.pc === p else { return }
            guard self.sdpOk(msg, "offer") else { self.tampered(); return }
            self.applyOffer(p, s)
        }
    }

    private func applyOffer(_ p: RTCPeerConnection, _ s: String) {
        p.setRemoteDescription(RTCSessionDescription(type: .offer, sdp: s)) { @Sendable err in
            guard err == nil else { return }
            Task { @MainActor in
                let cm = CallManager.shared
                guard cm.pc === p else { return }
                cm.flushIce()
                let cons = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)
                p.answer(for: cons) { @Sendable sdp, _ in
                    guard let sdp = sdp else { return }
                    let tuned = RTCSessionDescription(type: sdp.type, sdp: CallManager.opusTune(sdp.sdp))
                    Task { @MainActor in
                        let cm2 = CallManager.shared
                        guard cm2.pc === p else { return }
                        p.setLocalDescription(tuned) { @Sendable _ in }
                        await cm2.secTask?.value
                        guard cm2.pc === p else { return }
                        cm2.sig(cm2.peerId ?? "", cm2.signed(["t": "answer", "sdp": ["type": "answer", "sdp": tuned.sdp]], "answer", tuned.sdp))
                    }
                }
            }
        }
    }

    private func flushIce() {
        guard let p = pc else { return }
        for c in iceQueue { p.add(c) { @Sendable _ in } }
        iceQueue = []
    }

    /// Устойчивый звук Opus (как на сайте): коррекция потерь и битрейт 48 кбит/с
    nonisolated static func opusTune(_ sdp: String) -> String {
        guard let r = sdp.range(of: #"a=rtpmap:(\d+) opus/48000"#, options: [.regularExpression, .caseInsensitive]) else { return sdp }
        let line = String(sdp[r])
        guard let pt = line.split(separator: ":").last?.split(separator: " ").first else { return sdp }
        var out: [String] = []
        for l in sdp.components(separatedBy: "\r\n") {
            if l.hasPrefix("a=fmtp:\(pt) ") {
                var q = l
                if !q.contains("useinbandfec") { q += ";useinbandfec=1" }
                if !q.contains("maxaveragebitrate") { q += ";maxaveragebitrate=48000" }
                out.append(q)
            } else { out.append(l) }
        }
        return out.joined(separator: "\r\n")
    }

    private func connectionChanged(_ p: RTCPeerConnection, _ s: RTCPeerConnectionState) {
        guard pc === p else { return }
        log("pc", ["s": s.rawValue])
        switch s {
        case .connected:
            restarts = 0
            statusText = ""
            becomeActive()
            p2p = true
            relayImage = nil
            updateAudio()
            applySpeaker()
        case .failed, .disconnected:
            p2p = false
            updateAudio()
            let delay: UInt64 = s == .failed ? 500_000_000 : 4_000_000_000
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: delay)
                guard self.pc === p, p.connectionState != .connected, p.connectionState != .closed, self.restarts < 3 else { return }
                self.restarts += 1
                if self.role == "caller" { self.createOffer(restart: true) } else { self.sig(self.peerId ?? "", ["t": "restart"]) }
            }
        default:
            break
        }
    }

    /// Разговор начался (прямое соединение или резервный канал)
    private func becomeActive() {
        guard startedAt == nil, state == .connecting else { return }
        startedAt = Date()
        state = .active
        statusText = ""
        if role == "caller", let u = uuid { provider.reportOutgoingCall(with: u, connectedAt: nil) }
        heartbeat?.invalidate()
        heartbeat = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.state == .active, let peer = self.peerId else { return }
                self.sig(peer, ["t": "hb"])
            }
        }
        lastPeer = Date()
    }

    // MARK: - резервный канал (как на сайте)

    private func startRelay() {
        relaySeq = 0
        relayRSeq = -1
        pendingJPEG = nil
        relay.muted = muted
        relayTimer?.invalidate()
        relayTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            Task { @MainActor in CallManager.shared.relayTick() }
        }
        updateAudio()
    }

    /// Звук: при прямом соединении — WebRTC, без него — свой (резервный канал)
    private func updateAudio() {
        let inCall = state == .connecting || state == .active
        let direct = pc?.connectionState == .connected
        RTCAudioSession.sharedInstance().isAudioEnabled = audioActive && (!inCall || direct)
        if inCall && !direct && audioActive {
            if !relay.running && relay.startAudio() { applySpeaker() }
        } else if relay.running {
            relay.stopAudio()
        }
    }

    private func relayTick() {
        guard state == .connecting || state == .active, let peer = peerId else { return }
        let direct = pc?.connectionState == .connected
        if p2p != direct { p2p = direct }
        if direct { pendingJPEG = nil; return }
        if audioActive && !relay.running { updateAudio() }
        guard let sc = secChat else { pendingJPEG = nil; return }
        var med: JSON = [:]
        var has = false
        if let a = relay.takeAudio() { med["a"] = a; has = true }
        if let v = pendingJPEG { med["v"] = v; pendingJPEG = nil; has = true }
        if video && !camOff {
            relay.takeJPEG { @Sendable j in
                guard let j = j else { return }
                Task { @MainActor in CallManager.shared.pendingJPEG = j }
            }
        }
        guard has, let js = try? JSONSerialization.data(withJSONObject: med), let txt = String(data: js, encoding: .utf8),
              let e = E2E.shared.encrypt(sc, txt) else { return }
        let pl: JSON = ["t": "rm", "s": relaySeq, "e": e]
        relaySeq += 1
        sig(peer, pl)
    }

    private func onRelay(_ p: JSON, from: String, cid: String) {
        guard state == .connecting || state == .active, cid == callId, from == peerId else { return }
        let s = p.int("s") ?? 0
        if s <= relayRSeq && s != 0 { return }
        relayRSeq = s
        lastPeer = Date()
        if state == .connecting { becomeActive() }
        if pc?.connectionState == .connected { return }
        guard let sc = secChat, let enc = p.str("e"), E2E.isEnc(enc), let txt = E2E.shared.decrypt(sc, enc),
              let data = txt.data(using: .utf8), let med = (try? JSONSerialization.jsonObject(with: data)) as? JSON else { return }
        if let a = med.str("a") { relay.play(a) }
        if let v = med.str("v"), let d = Data(base64Encoded: v), let im = UIImage(data: d) { relayImage = im }
    }

    private func startWatchdog() {
        connectingSince = Date()
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            Task { @MainActor in CallManager.shared.checkPeerAlive() }
        }
    }

    private var connectingSince = Date()

    /// Звонок не должен «зависать»: не соединились за 30 секунд или собеседник пропал — завершаем
    private func checkPeerAlive() {
        if state == .connecting {
            if Date().timeIntervalSince(connectingSince) > 30 {
                if let p = peerId { sig(p, ["t": "hangup"]) }
                end("missed", why: "connect_timeout")
                AppModel.shared.say("Не удалось соединиться")
            }
            return
        }
        guard state == .active else { return }
        let connected = pc?.connectionState == .connected
        let silent = Date().timeIntervalSince(lastPeer)
        if (!connected && silent > 15) || silent > 40 {
            if let p = peerId { sig(p, ["t": "hangup"]) }
            end("ended", why: "peer_lost")
            AppModel.shared.say("Связь с собеседником потеряна")
        }
    }

    // MARK: - RTCPeerConnectionDelegate

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        guard let v = stream.videoTracks.first else { return }
        Task { @MainActor in self.remoteVideo = v }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let c: JSON = ["candidate": candidate.sdp, "sdpMid": candidate.sdpMid ?? NSNull(), "sdpMLineIndex": candidate.sdpMLineIndex]
        Task { @MainActor in
            guard self.pc === peerConnection, let peer = self.peerId else { return }
            self.sig(peer, ["t": "ice", "c": c])
        }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        Task { @MainActor in self.connectionChanged(peerConnection, newState) }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        guard let v = rtpReceiver.track as? RTCVideoTrack else { return }
        Task { @MainActor in
            self.remoteVideo = v
            if !self.video && self.state == .active { self.video = true; self.speaker = true; self.applySpeaker() }
        }
    }

    // MARK: - CXProviderDelegate (системный экран звонка)

    nonisolated func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in
            self.log("cx_reset")
            // сброс системного экрана звонка (даже без звонка, при запуске) — на этом iPhone CallKit не работает
            self.uuid = nil
            self.callKitBroken = true
            if self.state == .incoming {
                // системный экран звонка не работает на этом iPhone — звоним своим окном
                self.startOwnRing()
                return
            }
            // уже разговариваем — продолжаем без системного экрана
            if self.state == .connecting || self.state == .active || self.state == .calling { self.manualAudio() }
            else { self.end("missed", remote: true, why: "cx_reset") }
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Task { @MainActor in
            self.configureAudio()
            provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Task { @MainActor in
            self.log("cx_answer")
            BackgroundKeeper.shared.stop()
            self.configureAudio()
            action.fulfill()
            await self.acceptCall()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task { @MainActor in
            self.log("cx_end", ["mine": self.uuid == action.callUUID, "ago": self.answeredAt.map { Date().timeIntervalSince($0) } ?? -1])
            if self.uuid == action.callUUID {
                self.uuid = nil
                if self.state == .incoming { self.reject() }
                else if let a = self.answeredAt, Date().timeIntervalSince(a) < 5,
                        UIApplication.shared.applicationState == .active {
                    // система сбросила вызов сама сразу после ответа — звонок не рвём, звук включаем сами
                    self.manualAudio()
                } else if self.state != .idle { self.hangup() }
            }
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        Task { @MainActor in
            self.muted = action.isMuted
            self.audioTrack?.isEnabled = !action.isMuted
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
        Task { @MainActor in
            self.audioActive = true
            self.updateAudio()
            self.applySpeaker()
        }
    }

    nonisolated func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        Task { @MainActor in
            let cm = CallManager.shared
            cm.audioActive = false
            cm.relay.stopAudio()
            // системный звонок закрылся, а разговор продолжается — возвращаем звук
            guard cm.uuid == nil, cm.state == .connecting || cm.state == .active else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if cm.state == .connecting || cm.state == .active { cm.manualAudio() }
        }
    }
}
