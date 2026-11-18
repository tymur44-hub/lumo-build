import UIKit
import AVFoundation
import UserNotifications
import Intents

/// Системные уведомления iOS (баннер, звук, число на иконке)
enum Notifier {
    static func askPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            guard s.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Уведомление с фото профиля: как в Telegram — фото отправителя вместо значка приложения
    /// (уведомление о сообщении iOS), а запасной вариант — фото справа в уведомлении.
    static func show(id: String, title: String, body: String, chatId: String, urgent: Bool = false,
                     sender: (id: String, name: String, avatar: String?, color: Int)? = nil,
                     group: (name: String, avatar: String?, color: Int)? = nil) {
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        c.sound = .default
        // срочное — «важное» уведомление: iOS показывает его заметнее и, если разрешено, даже в режиме фокусирования
        if urgent { c.interruptionLevel = .timeSensitive; c.relevanceScore = 1 }
        c.threadIdentifier = chatId
        c.userInfo = ["chat": chatId]
        guard let sender else {
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c, trigger: nil)); return
        }
        Task.detached {
            var content: UNNotificationContent = c
            let face = await avatarPNG(url: sender.avatar, name: sender.name, color: sender.color, key: sender.id)
            let gface = group != nil ? await avatarPNG(url: group!.avatar, name: group!.name, color: group!.color, key: chatId) : nil
            // запасной вариант: фото справа в уведомлении
            if let f = gface ?? face, let tmp = copyTemp(f, id: id),
               let att = try? UNNotificationAttachment(identifier: "avatar", url: tmp, options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]) {
                c.attachments = [att]
            }
            // уведомление о сообщении: фото отправителя (или группы) вместо значка Lumo
            let person = INPerson(personHandle: INPersonHandle(value: sender.id, type: .unknown), nameComponents: nil,
                                  displayName: sender.name, image: face.flatMap { try? Data(contentsOf: $0) }.map { INImage(imageData: $0) },
                                  contactIdentifier: nil, customIdentifier: sender.id)
            let me = INPerson(personHandle: INPersonHandle(value: "me", type: .unknown), nameComponents: nil, displayName: nil,
                              image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: true)
            let intent = INSendMessageIntent(recipients: group != nil ? [me, person] : [me], outgoingMessageType: .outgoingMessageText,
                                             content: body, speakableGroupName: group.map { INSpeakableString(spokenPhrase: $0.name) },
                                             conversationIdentifier: chatId, serviceName: nil, sender: person, attachments: nil)
            if let g = gface, let d = try? Data(contentsOf: g) { intent.setImage(INImage(imageData: d), forParameterNamed: \.speakableGroupName) }
            let ix = INInteraction(intent: intent, response: nil)
            ix.direction = .incoming
            try? await ix.donate()
            // в уведомлении-сообщении имя отправителя iOS показывает сама, поэтому в тексте — только сообщение
            let c2 = (c.mutableCopy() as? UNMutableNotificationContent) ?? c
            if group != nil, body.hasPrefix(sender.name + ": ") { c2.body = String(body.dropFirst(sender.name.count + 2)) }
            if let upd = try? c2.updating(from: intent) { content = upd }
            try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
        }
    }

    private static func copyTemp(_ src: URL, id: String) -> URL? {
        let dst = FileManager.default.temporaryDirectory.appendingPathComponent("ntf-\(id).png")
        try? FileManager.default.removeItem(at: dst)
        return (try? FileManager.default.copyItem(at: src, to: dst)) != nil ? dst : nil
    }

    /// Круглое фото 256×256 (из кэша, или скачанное, или буква на цветном круге)
    private static func avatarPNG(url: String?, name: String, color: Int, key: String) async -> URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ntf-avatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let tag = String((url ?? "letter-\(name)-\(color)").hashValue, radix: 36).replacingOccurrences(of: "-", with: "m")
        let file = dir.appendingPathComponent("\(key)-\(tag).png")
        if FileManager.default.fileExists(atPath: file.path) { return file }
        var img: UIImage?
        if let s = url, let u = URL(string: s) {
            var req = URLRequest(url: u); req.timeoutInterval = 6
            if let (d, _) = try? await URLSession.shared.data(for: req) { img = UIImage(data: d) }
        }
        let side: CGFloat = 256
        let r = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let out = r.pngData { ctx in
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            UIBezierPath(ovalIn: rect).addClip()
            if let img {
                let sc = max(side / img.size.width, side / img.size.height)
                let w = img.size.width * sc, h = img.size.height * sc
                img.draw(in: CGRect(x: (side - w) / 2, y: (side - h) / 2, width: w, height: h))
            } else {
                let pal: [UInt32] = [0xff7a6b, 0xa48bff, 0x36b8ff, 0x25c99a, 0xffb347, 0xff6bb5, 0x5bc0ff, 0x9ccc65]
                let v = pal[((color % 8) + 8) % 8]
                UIColor(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1).setFill()
                ctx.fill(rect)
                let t = String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased() as NSString
                let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 110, weight: .bold), .foregroundColor: UIColor.white]
                let sz = t.size(withAttributes: attr)
                t.draw(at: CGPoint(x: (side - sz.width) / 2, y: (side - sz.height) / 2), withAttributes: attr)
            }
        }
        try? out.write(to: file)
        return file
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
