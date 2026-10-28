import UIKit
import AVFoundation

/// Пока Lumo свёрнут, iOS не усыпляет его: играет беззвучный звук (как у музыкальных приложений),
/// а приложение каждые 20 секунд само проверяет новые сообщения и показывает уведомления.
final class BackgroundKeeper {
    static let shared = BackgroundKeeper()
    static let interval: TimeInterval = 20

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var timer: Timer?
    private var observing = false

    var isRunning: Bool { engine != nil }

    func start() {
        guard engine == nil else { return }
        observe()
        let session = AVAudioSession.sharedInstance()
        // идёт звонок в Lumo (микрофон включён) — звук не трогаем, приложение и так не уснёт
        if session.category == .playAndRecord { return }
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let e = AVAudioEngine()
        let p = AVAudioPlayerNode()
        e.attach(p)
        let fmt = e.mainMixerNode.outputFormat(forBus: 0)
        guard fmt.sampleRate > 0, fmt.channelCount > 0 else { return }
        e.connect(p, to: e.mainMixerNode, format: fmt)
        let frames = AVAudioFrameCount(fmt.sampleRate)
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames) else { return }
        buf.frameLength = frames
        // тишина: заполняем буфер нулями
        if let ch = buf.floatChannelData {
            for c in 0..<Int(fmt.channelCount) { memset(ch[c], 0, Int(frames) * MemoryLayout<Float>.size) }
        }
        p.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
        do { try e.start() } catch { return }
        p.play()
        engine = e
        player = p

        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { _ in
            LumoNotifier.shared.check { _ in }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
    }

    private func observe() {
        guard !observing else { return }
        observing = true
        // звонок по телефону, будильник и т.п. прерывают звук — после них запускаемся снова
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            guard let self = self,
                  let raw = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            if type == .ended && UIApplication.shared.applicationState == .background {
                self.stop()
                self.start()
            }
        }
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, self.isRunning, UIApplication.shared.applicationState == .background else { return }
            self.stop()
            self.start()
        }
    }
}
