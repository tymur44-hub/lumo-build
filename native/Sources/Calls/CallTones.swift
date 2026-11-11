import AVFoundation

/// Звуки исходящего звонка (синтезируются в приложении, без файлов):
/// «Звонок…» — мягкие двойные «пип-пип» (вызов ещё идёт до собеседника);
/// «Вызов…» — длинный гудок 425 Гц: секунда звука, четыре секунды тишины (у собеседника звонит телефон).
@MainActor
final class CallTones {
    static let shared = CallTones()
    enum Kind { case connecting, ringback }
    private var player: AVAudioPlayer?
    private var kind: Kind?
    private lazy var connectingData = CallTones.connectingWAV()
    private lazy var ringbackData = CallTones.ringbackWAV()

    private var retry: Timer?
    private var tries = 0

    func play(_ k: Kind) {
        guard kind != k else { return }
        stop()
        kind = k
        guard let p = try? AVAudioPlayer(data: k == .connecting ? connectingData : ringbackData) else { return }
        p.numberOfLoops = -1
        p.volume = 1
        p.prepareToPlay()
        player = p
        tries = 0
        start()
    }

    /// Звук включается, только когда система активировала звук звонка; до этого — повторяем попытку
    private func start() {
        guard let p = player else { return }
        if !p.isPlaying { p.play() }
        retry?.invalidate()
        guard !p.isPlaying || tries == 0 else { return }
        retry = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self = self, let p = self.player else { t.invalidate(); return }
                self.tries += 1
                if p.isPlaying && self.tries > 2 { t.invalidate(); return }
                if !p.isPlaying {
                    // через 1,5 с без системного звука звонка (звонок без экрана iOS) — включаем звук сами
                    if self.tries == 4 {
                        let s = AVAudioSession.sharedInstance()
                        try? s.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
                        try? s.setActive(true)
                    }
                    p.play()
                }
                if self.tries > 25 { t.invalidate() }
            }
        }
    }

    /// система включила звук звонка (CallKit) — продолжаем гудки
    func resume() {
        guard let p = player, kind != nil else { return }
        p.play()
    }

    func stop() {
        retry?.invalidate(); retry = nil
        player?.stop()
        player = nil
        kind = nil
    }

    // MARK: синтез

    private static let rate = 24_000

    /// двойной «пип» 880/1175 Гц, повтор каждые 1,6 с
    private static func connectingWAV() -> Data {
        var s = [Float](repeating: 0, count: rate * 16 / 10)
        tone(&s, at: 0.00, dur: 0.09, f: 880, amp: 0.32)
        tone(&s, at: 0.17, dur: 0.11, f: 1175, amp: 0.32)
        return wav(s)
    }

    /// гудок 425 Гц (как в обычной телефонной сети), 1 с звука и 4 с тишины
    private static func ringbackWAV() -> Data {
        var s = [Float](repeating: 0, count: rate * 5)
        tone(&s, at: 0, dur: 1.0, f: 425, amp: 0.34, harmonic: 0.12)
        return wav(s)
    }

    private static func tone(_ s: inout [Float], at: Double, dur: Double, f: Double, amp: Float, harmonic: Float = 0.08) {
        let a = Int(at * Double(rate)), n = Int(dur * Double(rate)), fade = Int(0.018 * Double(rate))
        for i in 0..<n where a + i < s.count {
            let t = Double(i) / Double(rate)
            var env: Float = 1
            if i < fade { env = Float(i) / Float(fade) } else if i > n - fade { env = Float(n - i) / Float(fade) }
            let v = sin(2 * .pi * f * t) + Double(harmonic) * sin(4 * .pi * f * t)
            s[a + i] += Float(v) * amp * env
        }
    }

    private static func wav(_ s: [Float]) -> Data {
        var d = Data()
        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
        let bytes = UInt32(s.count * 2)
        d.append("RIFF".data(using: .ascii)!); u32(36 + bytes); d.append("WAVE".data(using: .ascii)!)
        d.append("fmt ".data(using: .ascii)!); u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        d.append("data".data(using: .ascii)!); u32(bytes)
        for v in s { u16(UInt16(bitPattern: Int16(max(-1, min(1, v)) * 32767))) }
        return d
    }
}
