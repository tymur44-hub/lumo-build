import Foundation

/// Очередь отправки: сообщения, которые не ушли из-за сети, ждут на устройстве (с часиками)
/// и отправляются сами, как только связь вернётся — даже после перезапуска приложения.
@MainActor
final class Outbox {
    static let shared = Outbox()
    struct Item: Codable {
        var pid: Int
        let chatId: String
        let kind: String
        let body: String?
        let media: String?
        let meta: Data
        let replyTo: Int?
        let forwardedFrom: String?
    }
    private var items: [Item] = []
    private var timer: Timer?
    private var busy = false
    private var key: String { "lm_outbox_" + (AppModel.shared.myId ?? "") }

    func add(_ i: Item) {
        if let k = items.firstIndex(where: { $0.pid == i.pid }) { items[k] = i } else { items.append(i) }
        save(); arm()
    }
    func remove(_ pid: Int) {
        guard items.contains(where: { $0.pid == pid }) else { return }
        items.removeAll { $0.pid == pid }; save()
    }

    /// после входа: поднять неотправленное с прошлого раза и показать в чатах с часиками
    func restore() {
        guard let d = UserDefaults.standard.data(forKey: key), let list = try? JSONDecoder().decode([Item].self, from: d), !list.isEmpty else { return }
        let m = AppModel.shared
        guard let me = m.myId else { return }
        items = list.map { it in
            var it = it
            let meta = (try? JSONSerialization.jsonObject(with: it.meta)) as? JSON ?? [:]
            let t = Message(pendingIn: it.chatId, sender: me, kind: it.kind, body: it.body, meta: meta, replyTo: it.replyTo)
            it.pid = t.id
            m.messages[it.chatId, default: []].append(t)
            return it
        }
        save(); arm()
    }

    private func save() {
        if let d = try? JSONEncoder().encode(items) { UserDefaults.standard.set(d, forKey: key) }
    }

    private func arm() {
        guard timer == nil, !items.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in Task { @MainActor in await Outbox.shared.flush() } }
    }

    func flush() async {
        guard !busy else { return }
        if items.isEmpty { timer?.invalidate(); timer = nil; return }
        busy = true
        defer { busy = false }
        for it in items {
            let meta = (try? JSONSerialization.jsonObject(with: it.meta)) as? JSON ?? [:]
            let ok = await AppModel.shared.send(chatId: it.chatId, kind: it.kind, body: it.body, media: it.media, meta: meta,
                                                replyTo: it.replyTo, forwardedFrom: it.forwardedFrom, pendingId: it.pid)
            if !ok, items.contains(where: { $0.pid == it.pid }) { break }   // сети всё ещё нет — подождём
        }
    }
}
