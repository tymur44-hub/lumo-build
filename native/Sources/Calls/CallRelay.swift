import Foundation
import AVFoundation
import CoreImage
import UIKit
import WebRTC

/// Резервный канал звонка (как на сайте): если прямое соединение между устройствами не установилось,
/// звук (μ-law 16 кГц) и кадры видео (JPEG) идут через сервер в сигналах «rm».
final class CallRelay: NSObject, RTCVideoRenderer, @unchecked Sendable {
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var converter: AVAudioConverter?
    private let fmt16 = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    private let lock = NSLock()
    private var captured: [Float] = []
    private var queued = 0
    private var latestFrame: CVPixelBuffer?
    private var latestRotation: RTCVideoRotation = ._0
    private let ci = CIContext(options: [.useSoftwareRenderer: false])
    private let videoQ = DispatchQueue(label: "lumo.relay.video")
    private var jpegBusy = false
    private(set) var running = false
    var muted = false

    // MARK: звук

    /// Запустить свой звук (микрофон + динамик). false — пока нельзя (сессия звука ещё не активна)
    @discardableResult
    func startAudio() -> Bool {
        if running { return true }
        let e = AVAudioEngine()
        let input = e.inputNode
        try? input.setVoiceProcessingEnabled(true)
        let inFmt = input.outputFormat(forBus: 0)
        guard inFmt.sampleRate > 0, inFmt.channelCount > 0 else { return false }
        converter = AVAudioConverter(from: inFmt, to: fmt16)
        let p = AVAudioPlayerNode()
        e.attach(p)
        e.connect(p, to: e.mainMixerNode, format: fmt16)
        input.installTap(onBus: 0, bufferSize: 1024, format: inFmt) { [weak self] buf, _ in
            self?.capture(buf)
        }
        e.prepare()
        do { try e.start() } catch {
            input.removeTap(onBus: 0)
            return false
        }
        p.play()
        engine = e
        player = p
        lock.lock(); captured = []; queued = 0; lock.unlock()
        running = true
        return true
    }

    func stopAudio() {
        guard running else { return }
        running = false
        engine?.inputNode.removeTap(onBus: 0)
        player?.stop()
        engine?.stop()
        engine = nil
        player = nil
        converter = nil
        lock.lock(); captured = []; queued = 0; lock.unlock()
    }

    private func capture(_ buf: AVAudioPCMBuffer) {
        guard let conv = converter, !muted else { return }
        let ratio = 16000 / buf.format.sampleRate
        let cap = AVAudioFrameCount(Double(buf.frameLength) * ratio + 32)
        guard let out = AVAudioPCMBuffer(pcmFormat: fmt16, frameCapacity: cap) else { return }
        var given = false
        var err: NSError?
        conv.convert(to: out, error: &err) { _, status in
            if given { status.pointee = .noDataNow; return nil }
            given = true
            status.pointee = .haveData
            return buf
        }
        guard err == nil, let ch = out.floatChannelData else { return }
        let n = Int(out.frameLength)
        lock.lock()
        captured.append(contentsOf: UnsafeBufferPointer(start: ch[0], count: n))
        if captured.count > 16000 { captured.removeFirst(captured.count - 8000) }
        lock.unlock()
    }

    /// Накопленный звук в μ-law (base64) для отправки
    func takeAudio() -> String? {
        lock.lock()
        let s = captured
        captured = []
        lock.unlock()
        if s.isEmpty || muted { return nil }
        var u = [UInt8](repeating: 0, count: s.count)
        for i in 0..<s.count { u[i] = CallRelay.muEnc(s[i]) }
        return Data(u).base64EncodedString()
    }

    /// Проиграть звук собеседника
    func play(_ b64: String) {
        guard running, let p = player, let d = Data(base64Encoded: b64), !d.isEmpty else { return }
        lock.lock()
        let q = queued
        lock.unlock()
        if q > 6 { return } // слишком большая задержка — пропускаем, чтобы не отставать
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt16, frameCapacity: AVAudioFrameCount(d.count)),
              let ch = buf.floatChannelData else { return }
        buf.frameLength = AVAudioFrameCount(d.count)
        d.withUnsafeBytes { raw in
            let b = raw.bindMemory(to: UInt8.self)
            for i in 0..<d.count { ch[0][i] = CallRelay.mud[Int(b[i])] }
        }
        lock.lock(); queued += 1; lock.unlock()
        p.scheduleBuffer(buf) { [weak self] in
            guard let self = self else { return }
            self.lock.lock(); self.queued = max(0, self.queued - 1); self.lock.unlock()
        }
        if !p.isPlaying { p.play() }
    }

    // MARK: видео

    func setSize(_ size: CGSize) {}

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let f = frame, let b = f.buffer as? RTCCVPixelBuffer else { return }
        lock.lock()
        latestFrame = b.pixelBuffer
        latestRotation = f.rotation
        lock.unlock()
    }

    /// Последний кадр с камеры в JPEG (base64), ширина 320 — как на сайте
    func takeJPEG(_ done: @escaping @Sendable (String?) -> Void) {
        lock.lock()
        let pb = latestFrame
        let rot = latestRotation
        latestFrame = nil
        let busy = jpegBusy
        if pb != nil && !busy { jpegBusy = true }
        lock.unlock()
        guard let pixel = pb, !busy else { done(nil); return }
        let ctx = ci
        videoQ.async { [weak self] in
            var img = CIImage(cvPixelBuffer: pixel)
            switch rot {
            case ._90: img = img.oriented(.right)
            case ._180: img = img.oriented(.down)
            case ._270: img = img.oriented(.left)
            default: break
            }
            let w = img.extent.width
            if w > 0 {
                let s = 320 / w
                img = img.transformed(by: CGAffineTransform(scaleX: s, y: s))
            }
            var out: String?
            if let cg = ctx.createCGImage(img, from: img.extent),
               let data = UIImage(cgImage: cg).jpegData(compressionQuality: 0.6) {
                out = data.base64EncodedString()
            }
            if let self = self { self.lock.lock(); self.jpegBusy = false; self.lock.unlock() }
            done(out)
        }
    }

    // MARK: μ-law

    static let mud: [Float] = (0..<256).map { i -> Float in
        let u = ~UInt8(i)
        let sg = u & 0x80, ex = Int((u >> 4) & 7), mn = Int(u & 0x0F)
        var x = ((mn << 3) + 0x84) << ex
        x -= 0x84
        return Float(sg != 0 ? -x : x) / 32768
    }

    static func muEnc(_ f: Float) -> UInt8 {
        var x = Int((max(-1, min(1, f)) * 32767).rounded())
        let sg = x < 0 ? 0x80 : 0
        if sg != 0 { x = -x }
        if x > 32635 { x = 32635 }
        x += 0x84
        var ex = 7
        var m = 0x4000
        while (x & m) == 0 && ex > 0 { ex -= 1; m >>= 1 }
        let mn = (x >> (ex + 3)) & 0x0F
        return UInt8(truncatingIfNeeded: ~(sg | (ex << 4) | mn))
    }
}
