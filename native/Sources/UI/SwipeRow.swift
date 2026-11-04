import SwiftUI

/// Действие свайпа по чату в списке
struct SwipeAction {
    let icon: String
    let title: String
    let color: Color
    let run: () -> Void
}

/// Чаты, вручную отмеченные непрочитанными (хранится на устройстве; снимается при открытии чата)
@MainActor
final class UnreadMarks: ObservableObject {
    static let shared = UnreadMarks()
    @Published private(set) var ids: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "lm_unread_marks") ?? [])
    func has(_ id: String) -> Bool { ids.contains(id) }
    func set(_ id: String, _ on: Bool) {
        guard on != ids.contains(id) else { return }
        if on { ids.insert(id) } else { ids.remove(id) }
        UserDefaults.standard.set(Array(ids), forKey: "lm_unread_marks")
    }
}

/// Строка списка чатов со свайпами как в Telegram:
/// строка отрывается в скруглённую плашку, из-под неё выезжают круглые кнопки с подписями;
/// при длинном свайпе крайняя кнопка вытягивается в длинную капсулу и срабатывает.
struct SwipeChatRow<Content: View>: View {
    let id: String
    @Binding var openId: String?
    /// кнопки слева (свайп вправо), первая — крайняя
    let leading: [SwipeAction]
    /// кнопки справа (свайп влево), последняя — крайняя
    let trailing: [SwipeAction]
    @ViewBuilder let content: () -> Content

    @State private var x: CGFloat = 0
    @State private var start: CGFloat = 0
    @State private var tracking: Bool?
    @State private var full = false

    private let slot: CGFloat = 70
    private var lw: CGFloat { CGFloat(leading.count) * slot + 10 }
    private var rw: CGFloat { CGFloat(trailing.count) * slot + 10 }
    private var fullAt: CGFloat { UIScreen.main.bounds.width * 0.58 }
    private let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)

    var body: some View {
        ZStack {
            if x > 0 { actions(leading, leadingSide: true).frame(maxWidth: .infinity, alignment: .leading) }
            if x < 0 { actions(trailing, leadingSide: false).frame(maxWidth: .infinity, alignment: .trailing) }
            content()
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Theme.panel2)
                        .opacity(min(1, abs(x) / 24))
                )
                .offset(x: x)
                .overlay {
                    // открытая строка: нажатие закрывает её, а не открывает чат
                    if x != 0 && tracking != true {
                        Color.clear.contentShape(Rectangle()).onTapGesture { close() }
                    }
                }
        }
        .simultaneousGesture(drag)
        .onChange(of: openId) { v in
            if v != id && x != 0 { withAnimation(spring) { x = 0 }; full = false }
        }
    }

    private func close() {
        withAnimation(spring) { x = 0 }
        full = false
        if openId == id { openId = nil }
    }

    @ViewBuilder private func actions(_ list: [SwipeAction], leadingSide: Bool) -> some View {
        let reveal = abs(x)
        let room = max(0, reveal - 10)
        HStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.offset) { i, a in
                let outer = leadingSide ? i == 0 : i == list.count - 1
                let w: CGFloat = full ? (outer ? room : 0) : room / CGFloat(max(1, list.count))
                let capW: CGFloat = full && outer ? max(0, w - 8) : max(0, min(56, w - 10))
                VStack(spacing: 5) {
                    Capsule()
                        .fill(a.color)
                        .frame(width: capW, height: 42)
                        .overlay(
                            Image(systemName: a.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(capW > 30 ? 1 : 0)
                        )
                    Text(a.title)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                        .fixedSize()
                        .opacity(capW > 44 ? 1 : 0)
                }
                .frame(width: w)
                .opacity(full && !outer ? 0 : 1)
                .contentShape(Rectangle())
                .onTapGesture { close(); a.run() }
            }
        }
        .padding(.horizontal, 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: full)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onChanged { v in
                if tracking == nil {
                    tracking = abs(v.translation.width) > abs(v.translation.height) * 1.3
                    if tracking == true { start = x; openId = id }
                }
                guard tracking == true else { return }
                var nx = start + v.translation.width
                if leading.isEmpty { nx = min(nx, 0) }
                if trailing.isEmpty { nx = max(nx, 0) }
                // за пределом крайней позиции строка идёт туже
                let edge = UIScreen.main.bounds.width * 0.9
                if abs(nx) > edge { nx = (nx > 0 ? 1 : -1) * (edge + (abs(nx) - edge) * 0.3) }
                x = nx
                let f = abs(nx) > fullAt
                if f != full {
                    full = f
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            .onEnded { v in
                defer { tracking = nil }
                guard tracking == true else { return }
                if full {
                    let a = x > 0 ? leading.first : trailing.last
                    close()
                    a?.run()
                    return
                }
                let vx = v.predictedEndTranslation.width - v.translation.width
                withAnimation(spring) {
                    if x > lw * 0.5 || (x > 24 && vx > 160) { x = lw }
                    else if x < -rw * 0.5 || (x < -24 && vx < -160) { x = -rw }
                    else { x = 0 }
                }
                if x == 0 && openId == id { openId = nil }
            }
    }
}
