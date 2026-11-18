import SwiftUI

/// Точка «не прослушано» у голосовых и кружков.
/// Входящее: горит, пока вы его не включили. Исходящее: горит, пока собеседник не прослушал.
/// Отметка хранится на сервере в meta.lb (кто прослушал) и приходит всем через обновление сообщения.
@MainActor
enum Listened {
    private static var local = Set<Int>()
    private static var sent = Set<Int>()

    static func unheard(_ m: Message, mine: Bool) -> Bool {
        guard m.kind == "voice" || m.kind == "video_note", m.id > 0 else { return false }
        let model = AppModel.shared
        let lb = (m.meta["lb"] as? [Any])?.compactMap { $0 as? String } ?? []
        if mine {
            if let c = model.chats.first(where: { $0.id == m.chatId }), c.isPrivate, c.peerId == model.myId { return false }
            return lb.isEmpty
        }
        if local.contains(m.id) { return false }
        guard let me = model.myId else { return false }
        return !lb.contains(me)
    }

    /// Вызывается при начале воспроизведения входящего голосового или кружка
    static func mark(_ m: Message, mine: Bool) {
        guard !mine, m.id > 0, unheard(m, mine: false) else { return }
        local.insert(m.id)
        AppModel.shared.objectWillChange.send()
        guard sent.insert(m.id).inserted else { return }
        Task { _ = try? await API.shared.rpc("lm_voice_listen", ["p_msg": m.id]) }
    }
}

/// Сама точка
struct UnheardDot: View {
    var mine: Bool
    var body: some View {
        Circle().fill(mine ? Color.white : Theme.a1).frame(width: 7, height: 7)
            .transition(.scale.combined(with: .opacity))
    }
}
