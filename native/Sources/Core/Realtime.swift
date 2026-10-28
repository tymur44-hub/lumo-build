import Foundation

/// Живое соединение с сервером (Supabase Realtime, протокол Phoenix):
/// новые сообщения приходят мгновенно, через него же идут сигналы звонков, «печатает…» и «в сети».
@MainActor
final class Realtime: NSObject, URLSessionWebSocketDelegate {
    static let shared = Realtime()

    final class Channel {
        let topic: String
        let changes: [JSON]
        let presenceKey: String
        var joinRef = ""
        var joined = false
        var waiters: [Int: CheckedContinuation<Void, Never>] = [:]
        var trackPayload: JSON?
        var onBroadcast: ((String, JSON) -> Void)?
        var onChange: ((JSON) -> Void)?
        var onPresenceState: ((JSON) -> Void)?
        var onPresenceDiff: ((JSON, JSON) -> Void)?
        init(topic: String, changes: [JSON], presenceKey: String) {
            self.topic = topic
            self.changes = changes
            self.presenceKey = presenceKey
        }
    }

    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    private var ref = 0
    private var waiterSeq = 0
    private var channels: [String: Channel] = [:]
    private var heartbeat: Timer?
    private var reconnectTask: Task<Void, Never>?
    private var backoff: Double = 1
    private(set) var isOpen = false
    private var wanted = false
    var onReconnect: (() -> Void)?
    /// true — соединение есть, false — пропало
    var onState: ((Bool) -> Void)?

    private override init() {
        super.init()
        rebuildSession()
    }

    /// Пересобрать сессию под текущий путь (в режиме туннеля — через локальную точку)
    private func rebuildSession() {
        let cfg = Net.mode == .tunnel ? Net.proxyConfig() : URLSessionConfiguration.default
        session?.invalidateAndCancel()
        session = URLSession(configuration: cfg, delegate: self, delegateQueue: OperationQueue.main)
    }

    private func nextRef() -> String { ref += 1; return String(ref) }

    // MARK: - соединение

    func connect() {
        wanted = true
        guard task == nil else { return }
        rebuildSession()
        let t = session.webSocketTask(with: Config.realtimeURL)
        task = t
        t.resume()
        receive(t)
    }

    func disconnect() {
        wanted = false
        reconnectTask?.cancel()
        heartbeat?.invalidate()
        heartbeat = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isOpen = false
        for c in channels.values { c.joined = false; resumeAll(c) }
        channels.removeAll()
    }

    /// Проверка, что соединение живо (после возврата из фона)
    func ensureConnected() {
        if !wanted { return }
        guard let t = task else { connect(); return }
        t.sendPing { @Sendable err in
            guard err != nil else { return }
            Task { @MainActor in Realtime.shared.droppedIfCurrent(t) }
        }
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in Realtime.shared.opened(webSocketTask) }
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                                didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in Realtime.shared.droppedIfCurrent(webSocketTask) }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let ws = task as? URLSessionWebSocketTask else { return }
        Task { @MainActor in Realtime.shared.droppedIfCurrent(ws) }
    }

    private func opened(_ t: URLSessionWebSocketTask) {
        guard t === task else { return }
        isOpen = true
        backoff = 1
        heartbeat?.invalidate()
        heartbeat = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { @Sendable _ in
            Task { @MainActor in Realtime.shared.push(topic: "phoenix", event: "heartbeat", payload: [:]) }
        }
        for c in channels.values { join(c) }
        onState?(true)
        onReconnect?()
    }

    private func droppedIfCurrent(_ t: URLSessionWebSocketTask) {
        guard t === task else { return }
        dropped()
    }

    private func dropped() {
        heartbeat?.invalidate()
        heartbeat = nil
        task?.cancel()
        task = nil
        isOpen = false
        for c in channels.values { c.joined = false }
        guard wanted else { return }
        onState?(false)
        reconnectTask?.cancel()
        let delay = backoff
        backoff = min(backoff * 2, 20)
        reconnectTask = Task { @MainActor in
            await Net.pick()
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if Task.isCancelled { return }
            Realtime.shared.connect()
        }
    }

    private func receive(_ t: URLSessionWebSocketTask) {
        t.receive { @Sendable result in
            var text: String?
            var failed = false
            switch result {
            case .failure: failed = true
            case .success(let msg):
                switch msg {
                case .string(let s): text = s
                case .data(let d): text = String(data: d, encoding: .utf8)
                @unknown default: text = nil
                }
            }
            Task { @MainActor in
                let rt = Realtime.shared
                guard t === rt.task else { return }
                if failed { rt.dropped(); return }
                if let s = text, let d = s.data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? JSON {
                    rt.handle(j)
                }
                rt.receive(t)
            }
        }
    }

    private func push(topic: String, event: String, payload: JSON, joinRef: String? = nil, ref r: String? = nil) {
        guard let t = task, isOpen else { return }
        var msg: JSON = ["topic": topic, "event": event, "payload": payload, "ref": r ?? nextRef()]
        if let jr = joinRef { msg["join_ref"] = jr }
        guard let d = try? JSONSerialization.data(withJSONObject: msg), let s = String(data: d, encoding: .utf8) else { return }
        t.send(.string(s)) { @Sendable _ in }
    }

    // MARK: - каналы

    @discardableResult
    func channel(_ name: String, changes: [JSON] = [], presenceKey: String = "") -> Channel {
        let topic = "realtime:" + name
        if let c = channels[topic] { return c }
        let c = Channel(topic: topic, changes: changes, presenceKey: presenceKey)
        channels[topic] = c
        if isOpen { join(c) } else { connect() }
        return c
    }

    func leave(_ name: String) {
        let topic = "realtime:" + name
        guard let c = channels.removeValue(forKey: topic) else { return }
        resumeAll(c)
        if c.joined { push(topic: topic, event: "phx_leave", payload: [:], joinRef: c.joinRef) }
    }

    private func join(_ c: Channel) {
        Task { @MainActor in
            let token = try? await API.shared.validToken()
            let rt = Realtime.shared
            guard rt.channels[c.topic] === c, rt.isOpen else { return }
            c.joinRef = rt.nextRef()
            var payload: JSON = ["config": [
                "broadcast": ["self": false, "ack": false] as JSON,
                "presence": ["key": c.presenceKey] as JSON,
                "postgres_changes": c.changes,
                "private": false,
            ] as JSON]
            if let t = token { payload["access_token"] = t }
            rt.push(topic: c.topic, event: "phx_join", payload: payload, joinRef: c.joinRef, ref: c.joinRef)
        }
    }

    private func resumeAll(_ c: Channel) {
        let ws = c.waiters.values
        c.waiters.removeAll()
        ws.forEach { $0.resume() }
    }

    /// Дождаться подключения к каналу (не дольше timeout секунд)
    func waitJoined(_ c: Channel, timeout: Double = 6) async {
        if c.joined { return }
        waiterSeq += 1
        let id = waiterSeq
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            c.waiters[id] = cont
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if let w = c.waiters.removeValue(forKey: id) { w.resume() }
            }
        }
    }

    func broadcast(_ c: Channel, event: String, payload: JSON) {
        push(topic: c.topic, event: "broadcast", payload: ["type": "broadcast", "event": event, "payload": payload], joinRef: c.joinRef)
    }

    /// Отметиться в канале присутствия («в сети»)
    func track(_ c: Channel, _ payload: JSON) {
        c.trackPayload = payload
        if c.joined { push(topic: c.topic, event: "presence", payload: ["type": "presence", "event": "track", "payload": payload], joinRef: c.joinRef) }
    }

    func untrack(_ c: Channel) {
        c.trackPayload = nil
        if c.joined { push(topic: c.topic, event: "presence", payload: ["type": "presence", "event": "untrack"], joinRef: c.joinRef) }
    }

    /// Новый ключ доступа (после обновления) — передаём во все каналы
    func updateToken(_ token: String) {
        for c in channels.values where c.joined {
            push(topic: c.topic, event: "access_token", payload: ["access_token": token], joinRef: c.joinRef)
        }
    }

    private func handle(_ j: JSON) {
        let topic = j.str("topic") ?? ""
        let event = j.str("event") ?? ""
        let payload = j.dict("payload")
        guard let c = channels[topic] else { return }
        switch event {
        case "phx_reply":
            guard j.str("ref") == c.joinRef else { return }
            if payload.str("status") == "ok" {
                c.joined = true
                resumeAll(c)
                if let tp = c.trackPayload { track(c, tp) }
            } else {
                retryJoin(c, after: 3)
            }
        case "broadcast":
            c.onBroadcast?(payload.str("event") ?? "", payload.dict("payload"))
        case "postgres_changes":
            c.onChange?(payload.dict("data"))
        case "presence_state":
            c.onPresenceState?(payload)
        case "presence_diff":
            c.onPresenceDiff?(payload.dict("joins"), payload.dict("leaves"))
        case "phx_error", "phx_close":
            c.joined = false
            retryJoin(c, after: 2)
        default:
            break
        }
    }

    private func retryJoin(_ c: Channel, after s: Double) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(s * 1_000_000_000))
            let rt = Realtime.shared
            if rt.channels[c.topic] === c, rt.isOpen, !c.joined { rt.join(c) }
        }
    }
}
