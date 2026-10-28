import SwiftUI
import UIKit
import AVFoundation

// MARK: - запись кружка (как на сайте): зажал — сразу пишет; камеру можно перевернуть и приблизить во время съёмки

/// Захват и запись: кадры с камеры и звук пишутся в квадратный .mp4 480×480 (его откроет и сайт)
final class NoteEngine: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,
                        AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    let q = DispatchQueue(label: "lumo.videonote")
    private let vOut = AVCaptureVideoDataOutput()
    private let aOut = AVCaptureAudioDataOutput()
    private var vIn: AVCaptureDeviceInput?
    private var front = true
    private var writer: AVAssetWriter?
    private var wv: AVAssetWriterInput?
    private var wa: AVAssetWriterInput?
    private var startPTS: CMTime?
    private var lastPTS: CMTime = .zero
    private var recording = false
    private var failed = false
    private var url: URL?
    private var baseZoom: CGFloat = 1
    private var torchOn = false
    var isFront: Bool { front }
    var onTick: (@Sendable (Double) -> Void)?

    /// Вызывать на очереди q
    func configure(mic: Bool) {
        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
        addCamera()
        if mic, let a = AVCaptureDevice.default(for: .audio), let i = try? AVCaptureDeviceInput(device: a), session.canAddInput(i) {
            session.addInput(i)
        }
        vOut.alwaysDiscardsLateVideoFrames = true
        vOut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        vOut.setSampleBufferDelegate(self, queue: q)
        if session.canAddOutput(vOut) { session.addOutput(vOut) }
        if mic {
            aOut.setSampleBufferDelegate(self, queue: q)
            if session.canAddOutput(aOut) { session.addOutput(aOut) }
        }
        fixConnection()
        session.commitConfiguration()
        session.startRunning()
    }

    private func addCamera() {
        if let old = vIn { session.removeInput(old); vIn = nil }
        let pos: AVCaptureDevice.Position = front ? .front : .back
        guard let d = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
              let i = try? AVCaptureDeviceInput(device: d), session.canAddInput(i) else { return }
        session.addInput(i)
        vIn = i
    }

    private func fixConnection() {
        guard let c = vOut.connection(with: .video) else { return }
        if c.isVideoOrientationSupported { c.videoOrientation = .portrait }
        if c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring = false
            c.isVideoMirrored = front
        }
    }

    /// Перевернуть камеру — можно и во время записи, файл продолжает писаться
    func flip() {
        q.async {
            self.front.toggle()
            self.session.beginConfiguration()
            self.addCamera()
            self.fixConnection()
            self.session.commitConfiguration()
            self.baseZoom = 1
            self.applyTorch()
        }
    }

    /// Фонарик (у задней камеры)
    func setTorch(_ on: Bool) { q.async { self.torchOn = on; self.applyTorch() } }

    private func applyTorch() {
        guard let d = vIn?.device, d.hasTorch, (try? d.lockForConfiguration()) != nil else { return }
        d.torchMode = torchOn ? .on : .off
        d.unlockForConfiguration()
    }

    func zoomBegin() {
        q.async {
            guard let d = self.vIn?.device else { return }
            self.baseZoom = d.videoZoomFactor
        }
    }

    func zoom(_ scale: CGFloat) {
        q.async {
            guard let d = self.vIn?.device, (try? d.lockForConfiguration()) != nil else { return }
            let maxZ = min(d.activeFormat.videoMaxZoomFactor, 8)
            if d.isRampingVideoZoom { d.cancelVideoZoomRamp() }
            d.videoZoomFactor = max(1, min(maxZ, self.baseZoom * scale))
            d.unlockForConfiguration()
        }
    }

    /// Отпустили пальцы — плавно вернуть приближение обратно
    func zoomEnd() {
        q.async {
            guard let d = self.vIn?.device, (try? d.lockForConfiguration()) != nil else { return }
            d.ramp(toVideoZoomFactor: 1, withRate: 5)
            d.unlockForConfiguration()
            self.baseZoom = 1
        }
    }

    /// Вызывать на очереди q
    func startWriting() {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("note-\(randomId()).mp4")
        guard let w = try? AVAssetWriter(outputURL: u, fileType: .mp4) else { failed = true; return }
        let v = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 480,
            AVVideoHeightKey: 480,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1_200_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ],
        ])
        v.expectsMediaDataInRealTime = true
        let a = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000,
        ])
        a.expectsMediaDataInRealTime = true
        if w.canAdd(v) { w.add(v) }
        if w.canAdd(a) { w.add(a) }
        w.shouldOptimizeForNetworkUse = true
        writer = w
        wv = v
        wa = a
        url = u
        startPTS = nil
        recording = true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard recording, let w = writer else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(sb)
        if output === vOut {
            if startPTS == nil {
                guard w.startWriting() else { failed = true; recording = false; return }
                w.startSession(atSourceTime: pts)
                startPTS = pts
            }
            guard w.status == .writing else { return }
            if let v = wv, v.isReadyForMoreMediaData { v.append(sb) }
            lastPTS = pts
            if let s = startPTS { onTick?(CMTimeGetSeconds(CMTimeSubtract(pts, s))) }
        } else if output === aOut, let s = startPTS, w.status == .writing, CMTimeCompare(pts, s) >= 0 {
            if let a = wa, a.isReadyForMoreMediaData { a.append(sb) }
        }
    }

    /// Закончить запись: файл и длительность
    func finish(_ done: @escaping @Sendable (URL?, Double) -> Void) {
        q.async {
            self.recording = false
            guard let w = self.writer, let s = self.startPTS, w.status == .writing, !self.failed else {
                self.writer?.cancelWriting()
                self.writer = nil
                done(nil, 0)
                return
            }
            let dur = CMTimeGetSeconds(CMTimeSubtract(self.lastPTS, s))
            self.wv?.markAsFinished()
            self.wa?.markAsFinished()
            let u = self.url
            w.finishWriting { @Sendable in
                done(w.status == .completed ? u : nil, dur)
            }
            self.writer = nil
        }
    }

    func cancel() {
        q.async {
            self.recording = false
            if let w = self.writer, w.status == .writing { w.cancelWriting() }
            self.writer = nil
            if let u = self.url { try? FileManager.default.removeItem(at: u) }
        }
    }

    func shutdown() {
        q.async { if self.session.isRunning { self.session.stopRunning() } }
    }
}

/// Состояние записи кружка для интерфейса
@MainActor
final class NoteRec: ObservableObject {
    static let shared = NoteRec()

    @Published var active = false
    @Published var recording = false
    @Published var elapsed: Double = 0
    @Published var locked = false
    @Published var dragX: CGFloat = 0
    @Published var finishing = false
    @Published var flash = false
    @Published var front = true
    @Published private(set) var session: AVCaptureSession?
    private var savedBrightness: CGFloat?

    private(set) var engine: NoteEngine?
    private var chatId = ""
    private var replyTo: Int?
    private var ending = false

    /// Начать запись. locked — запись без удержания (с кнопками «Отправить» и «Удалить»)
    func begin(chatId: String, replyTo: Int?, locked: Bool) async {
        guard !active else { return }
        guard CallManager.shared.state == .idle else { AppModel.shared.say("Нельзя записать кружок во время звонка"); return }
        self.chatId = chatId
        self.replyTo = replyTo
        active = true
        self.locked = locked
        recording = false
        finishing = false
        ending = false
        elapsed = 0
        dragX = 0
        front = true

        var asked = false
        var cam = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            asked = true
            cam = await AVCaptureDevice.requestAccess(for: .video)
        }
        var mic = AVAudioSession.sharedInstance().recordPermission == .granted
        if AVAudioSession.sharedInstance().recordPermission == .undetermined {
            asked = true
            mic = await withCheckedContinuation { c in
                AVAudioSession.sharedInstance().requestRecordPermission { @Sendable g in c.resume(returning: g) }
            }
        }
        guard active else { return }
        guard cam else {
            close()
            AppModel.shared.say("Нет доступа к камере — разрешите его в Настройках iPhone")
            return
        }
        // пока показывался запрос доступа, палец уже отпущен — дальше запись с кнопками
        if asked { self.locked = true }

        BackgroundKeeper.shared.stop()
        AudioPlayer.shared.stop()
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
        try? s.setActive(true)

        let e = NoteEngine()
        e.onTick = { @Sendable t in Task { @MainActor in NoteRec.shared.tick(t) } }
        engine = e
        session = e.session
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let withMic = mic
        e.q.async {
            e.configure(mic: withMic)
            e.startWriting()
        }
    }

    private func tick(_ t: Double) {
        guard active, !ending else { return }
        if !recording { recording = true }
        elapsed = t
        if t >= 60 { finish() }
    }

    func lock() {
        guard active, !locked else { return }
        locked = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func flip() {
        engine?.flip()
        front.toggle()
        applyFlash()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Вспышка: у задней камеры — фонарик, у передней — экран светится белым на полной яркости
    func toggleFlash() {
        flash.toggle()
        applyFlash()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func applyFlash() {
        engine?.setTorch(flash && !front)
        if flash && front {
            if savedBrightness == nil { savedBrightness = UIScreen.main.brightness }
            UIScreen.main.brightness = 1
        } else if let b = savedBrightness {
            UIScreen.main.brightness = b
            savedBrightness = nil
        }
    }

    /// Отпустили кнопку / нажали «Отправить»
    func finish() {
        guard active, !ending else { return }
        guard let e = engine else { close(); return }
        ending = true
        finishing = true
        let chat = chatId, reply = replyTo
        e.finish { @Sendable url, dur in
            Task { @MainActor in NoteRec.shared.done(url, dur, chat, reply) }
        }
    }

    private func done(_ url: URL?, _ dur: Double, _ chat: String, _ reply: Int?) {
        close()
        guard let u = url, dur >= 1, let d = try? Data(contentsOf: u) else {
            if url != nil || dur < 1 { AppModel.shared.say("Удерживайте кнопку, чтобы записать кружок") }
            return
        }
        AppModel.shared.sendMedia(chatId: chat, kind: "video_note", data: d, ext: "mp4", contentType: "video/mp4",
                                  meta: ["dur": max(1, Int(dur.rounded()))], replyTo: reply)
    }

    func cancel() {
        guard active else { return }
        engine?.cancel()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        close()
    }

    private func close() {
        if flash { flash = false; applyFlash() }
        engine?.shutdown()
        engine = nil
        session = nil
        active = false
        recording = false
        locked = false
        finishing = false
        ending = false
        dragX = 0
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }
}

/// Приближение двумя пальцами (после отпускания плавно возвращается) и двойной тап — перевернуть камеру
struct NoteGestureCatcher: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.isMultipleTouchEnabled = true
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pinch(_:)))
        pinch.delegate = context.coordinator
        v.addGestureRecognizer(pinch)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap))
        tap.numberOfTapsRequired = 2
        tap.delegate = context.coordinator
        v.addGestureRecognizer(tap)
        return v
    }

    func updateUIView(_ v: UIView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func pinch(_ g: UIPinchGestureRecognizer) {
            guard let e = NoteRec.shared.engine else { return }
            switch g.state {
            case .began: e.zoomBegin()
            case .changed: e.zoom(g.scale)
            case .ended, .cancelled, .failed: e.zoomEnd()
            default: break
            }
        }

        @objc func doubleTap() { NoteRec.shared.flip() }

        nonisolated func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

/// Экран записи поверх чата
struct VideoNoteOverlay: View {
    @ObservedObject private var note = NoteRec.shared
    @State private var shown = false

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.4).ignoresSafeArea()
            // вспышка передней камеры — белый экран вокруг кружка
            Color.white.opacity(note.flash && note.front ? 1 : 0).ignoresSafeArea()
                .animation(.easeInOut(duration: 0.25), value: note.flash)
            NoteGestureCatcher().ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    if let s = note.session {
                        CameraPreview(session: s).frame(width: 280, height: 280).clipShape(Circle())
                    } else {
                        Circle().fill(Color.black).frame(width: 280, height: 280)
                    }
                    if !note.recording || note.finishing { ProgressView().tint(.white).scaleEffect(1.4) }
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 5).frame(width: 298, height: 298)
                    Circle().trim(from: 0, to: min(1, note.elapsed / 60))
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 298, height: 298)
                        .animation(.linear(duration: 0.15), value: note.elapsed)
                }
                .scaleEffect(shown ? 1 : 0.35)
                .opacity(shown ? 1 : 0)
                .allowsHitTesting(false)
                HStack(spacing: 8) {
                    Circle().fill(Theme.danger).frame(width: 9, height: 9)
                        .opacity(Int(note.elapsed * 2) % 2 == 0 ? 1 : 0.3)
                    Text(Fmt.duration(note.elapsed) + " / 1:00").font(.headline.monospacedDigit())
                }
                .foregroundColor(note.flash && note.front ? .black : .white)
                .allowsHitTesting(false)
                HStack(spacing: 18) {
                    Button { note.toggleFlash() } label: {
                        Image(systemName: note.flash ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 19, weight: .semibold)).foregroundColor(note.flash ? .black : .white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(note.flash ? Color.yellow : Color.white.opacity(0.18)))
                    }
                    Button { note.flip() } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 19, weight: .semibold)).foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.white.opacity(0.18)))
                    }
                }
                Text("Двумя пальцами — приблизить").font(.caption).foregroundColor(note.flash && note.front ? .black.opacity(0.6) : .white.opacity(0.6))
                    .allowsHitTesting(false)
                Spacer()
                if note.locked {
                    HStack {
                        Button { note.cancel() } label: {
                            Image(systemName: "trash").font(.system(size: 20, weight: .semibold)).foregroundColor(Theme.danger)
                                .frame(width: 54, height: 54).background(Circle().fill(Color.white.opacity(0.15)))
                        }
                        Spacer()
                        Button { note.finish() } label: {
                            Image(systemName: "arrow.up").font(.system(size: 21, weight: .heavy)).foregroundColor(.white)
                                .frame(width: 60, height: 60).background(Circle().fill(Theme.accent))
                        }
                        .disabled(note.finishing)
                    }
                    .padding(.horizontal, 30).padding(.bottom, 24)
                } else {
                    VStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Image(systemName: "lock.fill").font(.system(size: 14))
                            Image(systemName: "chevron.up").font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.75))
                        Text(note.dragX < -80 ? "Отпустите для отмены" : "Влево — отмена, вверх — без удержания")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(note.dragX < -80 ? Theme.danger : .white.opacity(0.8))
                            .offset(x: max(-60, min(0, note.dragX / 2)))
                    }
                    .allowsHitTesting(false)
                    .padding(.bottom, 96)
                }
            }
        }
        .transition(.opacity)
        .onAppear {
            // кружок плавно «вырастает» при включении записи
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { shown = true }
        }
    }
}
