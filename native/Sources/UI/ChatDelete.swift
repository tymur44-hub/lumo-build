import SwiftUI

extension ChatItem {
    /// Подпись пункта «удалить» в меню чата
    var deleteTitle: String {
        if isPrivate { return "Удалить чат" }
        if role == "owner" { return isChannel ? "Удалить канал" : "Удалить группу" }
        return isChannel ? "Отписаться" : "Покинуть группу"
    }

    var deleteIcon: String { isPrivate || role == "owner" ? "trash" : "rectangle.portrait.and.arrow.right" }
}

/// Удаление чата: «у себя» или «у всех». Владельцу канала/группы перед удалением у всех показывается предупреждение
struct ChatDeleteModifier: ViewModifier {
    @EnvironmentObject var model: AppModel
    @Binding var chat: ChatItem?
    /// закрыть экран чата после удаления
    var onDone: () -> Void = {}
    @State private var warn: ChatItem?

    private var dialogShown: Binding<Bool> {
        Binding(get: { chat != nil }, set: { if !$0 { chat = nil } })
    }

    private var warnShown: Binding<Bool> {
        Binding(get: { warn != nil }, set: { if !$0 { warn = nil } })
    }

    private func name(_ c: ChatItem) -> String { c.displayName }

    func body(content: Content) -> some View {
        content
            .confirmationDialog(dialogTitle, isPresented: dialogShown, titleVisibility: .visible, presenting: chat) { c in
                if c.isPrivate {
                    Button("Удалить у меня", role: .destructive) { run(c, everyone: false) }
                    Button("Удалить у меня и у \(name(c))", role: .destructive) { ask(c) }
                } else if c.role == "owner" {
                    Button(c.isChannel ? "Удалить канал у всех" : "Удалить группу у всех", role: .destructive) { ask(c) }
                    Button(c.isChannel ? "Отписаться" : "Покинуть группу", role: .destructive) { run(c, everyone: false) }
                } else {
                    Button(c.isChannel ? "Отписаться" : "Покинуть группу", role: .destructive) { run(c, everyone: false) }
                }
                Button("Отмена", role: .cancel) {}
            }
            .alert("Внимание!", isPresented: warnShown, presenting: warn) { c in
                Button("Удалить всё", role: .destructive) { run(c, everyone: true) }
                Button("Отмена", role: .cancel) {}
            } message: { c in
                Text(warnText(c))
            }
    }

    private var dialogTitle: String {
        guard let c = chat else { return "" }
        if c.isPrivate { return "Удалить чат с «\(name(c))»?" }
        return "«\(name(c))»"
    }

    private func warnText(_ c: ChatItem) -> String {
        if c.isPrivate { return "Если удалить этот чат у обоих, вся переписка будет потеряна у вас и у собеседника. Вы точно хотите его удалить?" }
        if c.isChannel { return "Если удалить этот канал, все подписчики и сообщения будут потеряны. Вы точно хотите его удалить?" }
        return "Если удалить эту группу, все участники и сообщения будут потеряны. Вы точно хотите её удалить?"
    }

    private func run(_ c: ChatItem, everyone: Bool) {
        chat = nil
        Task { await model.deleteChat(c.id, everyone: everyone); onDone() }
    }

    private func ask(_ c: ChatItem) {
        chat = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { warn = c }
    }
}

extension View {
    func chatDeletion(_ chat: Binding<ChatItem?>, onDone: @escaping () -> Void = {}) -> some View {
        modifier(ChatDeleteModifier(chat: chat, onDone: onDone))
    }
}
