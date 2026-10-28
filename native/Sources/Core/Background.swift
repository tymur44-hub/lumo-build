import UIKit
import AVFoundation
import UserNotifications

/// Системные уведомления iOS (баннер, звук, число на иконке)
enum Notifier {
    static func askPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            guard s.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    static func show(id: String, title: String, body: String, chatId: String) {
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        c.sound = .default
        c.threadIdentifier = chatId
        c.userInfo = ["chat": chatId]
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c, trigger: nil))
    }

    static func clear(chat: String? = nil) {
        let center = UNUserNotificationCenter.current()
        guard let chat = chat else { center.removeAllDeliveredNotifications(); return }
        center.getDeliveredNotifications { list in
            let ids = list.filter { ($0.request.content.userInfo["chat"] as? String) == chat }.map { $0.request.identifier }
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
    }

    static func setBadge(_ n: Int) {
        UNUserNotificationCenter.current().setBadgeCount(n) { _ in }
    }
}

/// Пока Lumo свёрнут, iOS не усыпляет его: играет беззвучный звук (как у музыкальных приложений).
/// Благодаря этому соединение с сервером остаётся живым — сообщения и звонки приходят сразу.
@MainActor
final class BackgroundKeeper {
    static let shared = BackgroundKeeper()

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var observing = false
    private var retries = 0
    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "lm_keep_alive") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "lm_keep_alive") }
    }
    var isRunning: Bool { engine != nil }

    func start(force: Bool = false) {
        guard enabled, engine == nil, force || CallManager.shared.state == .idle else { return }
        observe()
        let session = AVAudioSession.sharedInstance()
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
        if let ch = buf.floatChannelData {
            for c in 0..<Int(fmt.channelCount) { memset(ch[c], 0, Int(frames) * MemoryLayout<Float>.size) }
        }
        p.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
        do { try e.start() } catch {
            // звук был занят (например, только что закончился звонок) — пробуем ещё раз чуть позже
            if retries < 5 {
                retries += 1
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if UIApplication.shared.applicationState != .active { BackgroundKeeper.shared.start() }
                }
            }
            return
        }
        retries = 0
        p.play()
        engine = e
        player = p
    }

    func stop() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
    }

    private func observe() {
        guard !observing else { return }
        observing = true
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { n in
            guard let raw = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw), type == .ended else { return }
            Task { @MainActor in
                let k = BackgroundKeeper.shared
                if UIApplication.shared.applicationState == .background && CallManager.shared.state == .idle {
                    k.stop()
                    k.start()
                }
            }
        }
    }
}
