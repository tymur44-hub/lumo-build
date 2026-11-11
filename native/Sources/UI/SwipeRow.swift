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
        attachSwipe(ZStack {
            if x > 0 { actions(leading, leadingSide: true).frame(maxWidth: .infinity, alignment: .leading) }
            if x < 0 { actions(trailing, leadingSide: false).frame(maxWidth: .infinity, alignment: .trailing) }
            content()
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Theme.panel2)
                        .opacity(Double(min(CGFloat(1), abs(x) / CGFloat(24))))
                )
                // открытая строка: нажатие по самой строке закрывает её (а не открывает чат);
                // слой едет вместе со строкой, поэтому не перекрывает кнопки свайпа
                .overlay {
                    if x != 0 && tracking != true {
                        Color.clear.contentShape(Rectangle()).onTapGesture { close() }
                    }
                }
                .offset(x: x)
        })
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

    // MARK: жест

    private func began() {
        start = x
        openId = id
    }

    private func changed(_ tx: CGFloat) {
        var nx = start + tx
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

    private func ended(_ vx: CGFloat) {
        if full {
            let a = x > 0 ? leading.first : trailing.last
            close()
            a?.run()
            return
        }
        withAnimation(spring) {
            if x > lw * 0.5 || (x > 24 && vx > 400) { x = lw }
            else if x < -rw * 0.5 || (x < -24 && vx < -400) { x = -rw }
            else { x = 0 }
        }
        if x == 0 && openId == id { openId = nil }
    }

    /// iOS 18+: системный жест, который начинается только при горизонтальном движении —
    /// не мешает прокрутке списка и отменяет нажатие по строке (чат после свайпа не открывается)
    @ViewBuilder private func attachSwipe<V: View>(_ v: V) -> some View {
        if #available(iOS 18.0, *) {
            // кнопки появляются только при свайпе от самого края экрана (или если строка уже открыта);
            // свайп из середины переключает папки «Все / Частный / Группы / Каналы»
            v.gesture(HorizontalPan(allow: { sx in x != 0 || SwipeEdge.isEdge(sx) },
                                    began: { tracking = true; began() },
                                    changed: { changed($0) },
                                    ended: { vx in tracking = nil; ended(vx) }))
        } else {
            v.simultaneousGesture(
                DragGesture(minimumDistance: 14, coordinateSpace: .global)
                    .onChanged { g in
                        if tracking == nil {
                            tracking = abs(g.translation.width) > abs(g.translation.height) * 1.3 && (x != 0 || SwipeEdge.isEdge(g.startLocation.x))
                            if tracking == true { began() }
                        }
                        if tracking == true { changed(g.translation.width) }
                    }
                    .onEnded { g in
                        let was = tracking
                        tracking = nil
                        if was == true { ended((g.predictedEndTranslation.width - g.translation.width) * 4) }
                    }
            )
        }
    }
}


/// Горизонтальный свайп через UIKit (iOS 18+): начинается, только если движение явно горизонтальное
@available(iOS 18.0, *)
struct HorizontalPan: UIGestureRecognizerRepresentable {
    /// можно ли начать свайп из этой точки (координата X в окне)
    var allow: (CGFloat) -> Bool = { _ in true }
    var began: () -> Void
    var changed: (CGFloat) -> Void
    var ended: (CGFloat) -> Void

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var allow: (CGFloat) -> Bool = { _ in true }
        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let p = g as? UIPanGestureRecognizer else { return false }
            let v = p.velocity(in: p.view)
            // точка начала: текущее положение минус пройденный путь
            let start = p.location(in: nil).x - p.translation(in: nil).x
            return abs(v.x) > abs(v.y) * 1.2 && allow(start)
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let g = UIPanGestureRecognizer()
        context.coordinator.allow = allow
        g.delegate = context.coordinator
        g.cancelsTouchesInView = true
        return g
    }

    func updateUIGestureRecognizer(_ g: UIPanGestureRecognizer, context: Context) { context.coordinator.allow = allow }

    func handleUIGestureRecognizerAction(_ g: UIPanGestureRecognizer, context: Context) {
        let tx = g.translation(in: g.view).x
        switch g.state {
        case .began: began(); changed(tx)
        case .changed: changed(tx)
        case .ended, .cancelled, .failed: ended(g.velocity(in: g.view).x)
        default: break
        }
    }
}


/// Свайп по строке чата открывает кнопки, только если начат у самого края экрана
enum SwipeEdge {
    static let zone: CGFloat = 34
    static func isEdge(_ x: CGFloat) -> Bool { x < zone || x > UIScreen.main.bounds.width - zone }
}
