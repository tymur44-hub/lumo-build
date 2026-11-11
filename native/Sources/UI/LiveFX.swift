import SwiftUI
import UIKit

// MARK: - «Живые» мелочи, как в Telegram: капля «в сети», упругие реакции с разлетающимися эмодзи, счётчики

/// Зелёная точка «в сети»: появляется как упавшая капля (сплющивается и пружинит),
/// исчезает как капля, которая стекает вниз и тает.
struct OnlineDot: View {
    let online: Bool
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        let d = size * 0.26
        Circle().fill(Theme.ok)
            .frame(width: d, height: d)
            .overlay(Circle().stroke(Theme.bg, lineWidth: max(2, size * 0.05)))
            // по горизонтали и вертикали — разные пружины: капля «колышется»
            .scaleEffect(x: online ? 1 : 0.2, y: 1, anchor: .top)
            .animation(online ? .spring(response: 0.3, dampingFraction: 0.42) : .easeIn(duration: 0.26), value: online)
            .scaleEffect(x: 1, y: online ? 1 : 1.55, anchor: .top)
            .animation(online ? .spring(response: 0.44, dampingFraction: 0.5) : .easeIn(duration: 0.3), value: online)
            .offset(y: online ? 0 : d * 0.55)
            .opacity(online ? 1 : 0)
            .animation(online ? .easeOut(duration: 0.12) : .easeIn(duration: 0.32).delay(0.04), value: online)
            .offset(x: -size * 0.01, y: -size * 0.01)
            .allowsHitTesting(false)
            .transaction { if reduce { $0.animation = nil } }
    }
}

/// Какие реакции только что поставили (своя или пришла от собеседника) — для разлёта эмодзи.
/// Нужна, чтобы эффект играл один раз, а не при каждой прокрутке ленты.
final class ReactionFX {
    static let shared = ReactionFX()
    private var fresh: [String: Date] = [:]
    func mark(_ mid: Int, _ emoji: String) { fresh["\(mid)|\(emoji)"] = Date() }
    /// забрать отметку (true — эффект надо проиграть)
    func take(_ mid: Int, _ emoji: String) -> Bool {
        let k = "\(mid)|\(emoji)"
        guard let t = fresh[k] else { return false }
        fresh[k] = nil
        return Date().timeIntervalSince(t) < 2.5
    }
}

/// Плашка реакции под сообщением: появляется упруго, число меняется «перекатом»,
/// а при новой реакции из неё разлетаются такие же эмодзи.
struct ReactionChip: View {
    let mid: Int
    let emoji: String
    let count: Int
    let mine: Bool
    let action: () -> Void
    @State private var burst = 0
    @State private var pop = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Text(emoji).font(.system(size: 14))
                    .scaleEffect(pop ? 1.35 : 1)
                    .rotationEffect(.degrees(pop ? -12 : 0))
                Text("\(count)").font(.system(size: 12.5, weight: .bold)).foregroundColor(mine ? .white : Theme.text)
                    .monospacedDigit()
                    .id(count)
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(mine ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel2)))
            .overlay(Capsule().stroke(Theme.line))
        }
        .buttonStyle(BouncyButtonStyle())
        .overlay { if burst > 0 { EmojiBurst(emoji: emoji).id(burst).allowsHitTesting(false) } }
        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: count)
        .animation(.spring(response: 0.28, dampingFraction: 0.4), value: pop)
        .onAppear { if ReactionFX.shared.take(mid, emoji) { play() } }
        .onChange(of: count) { [count] new in
            if new > count, ReactionFX.shared.take(mid, emoji) { play() }
        }
    }

    private func play() {
        burst += 1
        pop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { pop = false }
        if mine { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8) }
    }
}

/// Разлёт эмодзи: одна крупная взмывает вверх, мелкие разлетаются по кругу и тают
struct EmojiBurst: View {
    let emoji: String
    @State private var go = false
    private let parts: [(angle: Double, dist: CGFloat, size: CGFloat, spin: Double, delay: Double)] = (0..<9).map { i in
        let a = Double(i) / 9 * 2 * .pi + Double.random(in: -0.25...0.25)
        return (a, CGFloat.random(in: 34...58), CGFloat.random(in: 11...17), Double.random(in: -50...50), Double.random(in: 0...0.06))
    }

    var body: some View {
        ZStack {
            // крупная — взлетает и растворяется
            Text(emoji).font(.system(size: 22))
                .scaleEffect(go ? 2.1 : 0.6)
                .offset(y: go ? -46 : 0)
                .opacity(go ? 0 : 1)
                .animation(.timingCurve(0.2, 0.9, 0.3, 1, duration: 0.85), value: go)
            ForEach(parts.indices, id: \.self) { i in
                let p = parts[i]
                Text(emoji).font(.system(size: p.size))
                    .scaleEffect(go ? 0.55 : 1.15)
                    .rotationEffect(.degrees(go ? p.spin : 0))
                    .offset(x: go ? cos(p.angle) * p.dist : 0,
                            y: go ? sin(p.angle) * p.dist - 14 : 0)   // чуть вверх, как в Telegram
                    .opacity(go ? 0 : 1)
                    .animation(.timingCurve(0.15, 0.85, 0.35, 1, duration: 0.75).delay(p.delay), value: go)
            }
        }
        .onAppear { DispatchQueue.main.async { go = true } }
    }
}

/// Значок с числом (непрочитанные): появляется с упругим «пыжком», число перекатывается
struct PopBadge<Content: View>: View {
    let value: Int
    @ViewBuilder var content: () -> Content
    @State private var bump = false
    var body: some View {
        content()
            .scaleEffect(bump ? 1.18 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.45), value: bump)
            .onChange(of: value) { [value] new in
                guard new > value else { return }
                bump = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { bump = false }
            }
    }
}
