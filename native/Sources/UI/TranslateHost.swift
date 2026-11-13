import SwiftUI
#if canImport(Translation)
import Translation
#endif

/// Перевод сообщения системным переводчиком iPhone (iOS 17.4+): работает на устройстве, без нашего сервера
struct TranslateHost: ViewModifier {
    @Binding var text: String?

    static var available: Bool {
        if #available(iOS 17.4, *) { return true }
        return false
    }

    func body(content: Content) -> some View {
        #if canImport(Translation)
        if #available(iOS 17.4, *) {
            content.translationPresentation(isPresented: Binding(get: { text != nil }, set: { if !$0 { text = nil } }),
                                            text: text ?? "")
        } else { content }
        #else
        content
        #endif
    }
}
