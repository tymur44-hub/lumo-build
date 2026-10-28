import UIKit
import AVFoundation
import WebKit

enum Media {
    /// Фото для отправки: не больше 2560 px по длинной стороне, JPEG
    static func jpeg(_ img: UIImage, maxSide: CGFloat = 2560, quality: CGFloat = 0.86) -> (Data, Int, Int)? {
        let s = img.size
        let k = min(1, maxSide / max(s.width, s.height))
        let size = CGSize(width: (s.width * k).rounded(), height: (s.height * k).rounded())
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        let out = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
        guard let d = out.jpegData(compressionQuality: quality) else { return nil }
        return (d, Int(size.width), Int(size.height))
    }

    static func squareJPEG(_ img: UIImage, side: CGFloat) -> Data? {
        let s = img.size
        let q = min(s.width, s.height)
        let size = CGSize(width: side, height: side)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        let out = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            let k = side / q
            img.draw(in: CGRect(x: -(s.width - q) / 2 * k, y: -(s.height - q) / 2 * k, width: s.width * k, height: s.height * k))
        }
        return out.jpegData(compressionQuality: 0.88)
    }

    private static var thumbs = NSCache<NSString, UIImage>()

    static func thumbnail(_ url: URL) async -> UIImage? {
        if let c = thumbs.object(forKey: url.absoluteString as NSString) { return c }
        let gen = AVAssetImageGenerator(asset: AVURLAsset(url: url.px))
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 640, height: 640)
        let img: UIImage? = await withCheckedContinuation { cont in
            gen.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTime(seconds: 0.1, preferredTimescale: 600))]) { _, cg, _, _, _ in
                cont.resume(returning: cg.map { UIImage(cgImage: $0) })
            }
        }
        if let i = img { thumbs.setObject(i, forKey: url.absoluteString as NSString) }
        return img
    }
}

/// Запись голосового сообщения (AAC, .m4a — открывается везде, и на сайте тоже)
@MainActor
final class VoiceRecorder: ObservableObject {
    @Published var recording = false
    @Published var elapsed: Double = 0
    @Published var level: Float = 0
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var peaks: [Float] = []
    private var started = Date()
    private var url: URL?

    func start() async -> Bool {
        let ok: Bool = await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { @Sendable granted in cont.resume(returning: granted) }
        }
        guard ok else { return false }
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try? s.setActive(true)
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(randomId()).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        guard let r = try? AVAudioRecorder(url: u, settings: settings) else { return false }
        r.isMeteringEnabled = true
        guard r.record() else { return false }
        recorder = r
        url = u
        peaks = []
        started = Date()
        elapsed = 0
        recording = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { @Sendable [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        return true
    }

    private func tick() {
        guard let r = recorder else { return }
        r.updateMeters()
        let db = r.averagePower(forChannel: 0)
        let v = max(0, min(1, (db + 50) / 50))
        level = v
        peaks.append(v)
        elapsed = Date().timeIntervalSince(started)
        if elapsed >= 600 { _ = stop() }
    }

    /// Остановить запись. Возвращает файл, длительность и «волну» из 40 столбиков (0…31), как на сайте
    func stop() -> (URL, Double, [Int])? {
        timer?.invalidate()
        timer = nil
        guard let r = recorder, let u = url else { recording = false; return nil }
        let dur = r.currentTime > 0 ? r.currentTime : elapsed
        r.stop()
        recorder = nil
        recording = false
        restoreSession()
        let n = 40
        var wave: [Float] = []
        for i in 0..<n {
            let a = peaks.isEmpty ? [] : Array(peaks[(i * peaks.count / n)..<max(i * peaks.count / n, (i + 1) * peaks.count / n)])
            wave.append(a.max() ?? 0)
        }
        let mx = max(0.001, wave.max() ?? 0)
        return (u, dur, wave.map { Int(($0 / mx * 31).rounded()) })
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder?.deleteRecording()
        recorder = nil
        recording = false
        restoreSession()
    }

    private func restoreSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }
}

/// Проигрывание голосовых. Файлы с компьютера (.webm/.ogg) iOS сама не открывает — их играет встроенный движок Safari.
@MainActor
final class AudioPlayer: NSObject, ObservableObject, WKScriptMessageHandler {
    static let shared = AudioPlayer()

    @Published var currentId: Int?
    @Published var playing = false
    @Published var progress: Double = 0
    @Published var position: Double = 0

    private var player: AVPlayer?
    private var observer: Any?
    private var endObserver: NSObjectProtocol?
    private var web: WKWebView?

    func toggle(id: Int, url: String) {
        if currentId == id {
            if playing { pause() } else { resume() }
            return
        }
        stop()
        guard let u = URL(string: url) else { return }
        currentId = id
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let ext = u.pathExtension.lowercased()
        if ext == "webm" || ext == "ogg" || ext == "opus" { playWeb(u); return }
        let p = AVPlayer(url: u.px)
        player = p
        observer = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { @Sendable t in
            Task { @MainActor in
                let me = AudioPlayer.shared
                guard let item = me.player?.currentItem else { return }
                let d = item.duration.seconds
                me.position = t.seconds
                me.progress = d.isFinite && d > 0 ? t.seconds / d : 0
            }
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: .main) { @Sendable _ in
            Task { @MainActor in AudioPlayer.shared.stop() }
        }
        p.play()
        playing = true
    }

    func pause() {
        player?.pause()
        web?.evaluateJavaScript("a.pause()", completionHandler: nil)
        playing = false
    }

    func resume() {
        player?.play()
        web?.evaluateJavaScript("a.play()", completionHandler: nil)
        playing = true
    }

    func stop() {
        if let o = observer { player?.removeTimeObserver(o) }
        observer = nil
        if let e = endObserver { NotificationCenter.default.removeObserver(e) }
        endObserver = nil
        player?.pause()
        player = nil
        web?.evaluateJavaScript("a.pause()", completionHandler: nil)
        currentId = nil
        playing = false
        progress = 0
        position = 0
    }

    private func playWeb(_ u: URL) {
        if web == nil {
            let cfg = WKWebViewConfiguration()
            cfg.allowsInlineMediaPlayback = true
            cfg.mediaTypesRequiringUserActionForPlayback = []
            cfg.userContentController.add(self, name: "lm")
            let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: cfg)
            w.isHidden = true
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first }.first?.addSubview(w)
            web = w
        }
        let html = """
        <html><body><audio id="a" src="\(u.absoluteString)" autoplay playsinline></audio><script>
        var a=document.getElementById('a');
        a.ontimeupdate=function(){webkit.messageHandlers.lm.postMessage({t:a.currentTime,d:a.duration||0});};
        a.onended=function(){webkit.messageHandlers.lm.postMessage({end:1});};
        a.onerror=function(){webkit.messageHandlers.lm.postMessage({err:1});};
        a.play().catch(function(){});
        </script></body></html>
        """
        web?.loadHTMLString(html, baseURL: URL(string: "https://volshebny-mir.ru/"))
        playing = true
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let body = message.body as? [String: Any] ?? [:]
        if body["end"] != nil || body["err"] != nil {
            if body["err"] != nil { AppModel.shared.say("Не удалось воспроизвести голосовое") }
            stop()
            return
        }
        let t = (body["t"] as? NSNumber)?.doubleValue ?? 0
        let d = (body["d"] as? NSNumber)?.doubleValue ?? 0
        position = t
        progress = d.isFinite && d > 0 ? t / d : 0
    }
}
