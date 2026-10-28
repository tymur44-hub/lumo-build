import SwiftUI

/// Оживающее эмодзи: у каждого вида своё движение; по нажатию — всплеск
struct AnimatedEmoji: View {
    let emoji: String
    let size: CGFloat
    var tappable = true
    @State private var burst: [Int] = []
    @State private var tapAt: Date = .distantPast

    private enum Kind { case beat, flicker, shake, party, spin, wave, bounce }
    private var kind: Kind {
        switch emoji {
        case "❤️", "💖", "💗", "💓", "💯": return .beat
        case "🔥": return .flicker
        case "😂", "🤣", "😡", "😱", "🤯": return .shake
        case "🎉", "🥳", "🤩": return .party
        case "⭐️", "✨", "🌟": return .spin
        case "👋", "🙏": return .wave
        default: return .bounce
        }
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let k = max(0, 1 - tl.date.timeIntervalSince(tapAt) / 0.7) // затухающий всплеск после нажатия
            let amp = 1 + k * 1.2
            let f = frame(t, amp)
            Text(emoji).font(.system(size: size))
                .scaleEffect(f.scale, anchor: f.anchor)
                .rotationEffect(.degrees(f.rot), anchor: f.anchor)
                .offset(y: f.y)
                .frame(width: size * 1.25, height: size * 1.25)
        }
        .overlay {
            ForEach(burst, id: \.self) { i in BurstParticle(emoji: emoji, size: size * 0.4, seed: i) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard tappable else { return }
            tapAt = Date()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let base = Int(Date().timeIntervalSince1970 * 10) % 100000
            burst = (0..<7).map { base + $0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { burst = [] }
        }
    }

    private func frame(_ t: TimeInterval, _ a: Double) -> (scale: CGFloat, rot: Double, y: CGFloat, anchor: UnitPoint) {
        switch kind {
        case .beat:
            let p = t.truncatingRemainder(dividingBy: 1.1) / 1.1
            let s = p < 0.15 ? 1 + 0.2 * (p / 0.15) : p < 0.3 ? 1.2 - 0.2 * ((p - 0.15) / 0.15) : p < 0.42 ? 1 + 0.12 * ((p - 0.3) / 0.12) : p < 0.58 ? 1.12 - 0.12 * ((p - 0.42) / 0.16) : 1
            return (CGFloat(1 + (s - 1) * a), 0, 0, .center)
        case .flicker:
            let s = 1 + 0.06 * a * sin(t * 9) + 0.04 * sin(t * 13)
            return (CGFloat(s), 5 * a * sin(t * 7), CGFloat(-2 * abs(sin(t * 5))), .bottom)
        case .shake:
            let p = t.truncatingRemainder(dividingBy: 1.6)
            let on = p < 0.7
            return (CGFloat(1 + (on ? 0.06 : 0)), on ? 11 * a * sin(p * 30) : 0, 0, .center)
        case .party:
            let p = t.truncatingRemainder(dividingBy: 1.2) / 1.2
            return (CGFloat(1 + 0.08 * a * sin(p * .pi)), 14 * a * sin(p * .pi * 4), CGFloat(-size * 0.12 * a * abs(sin(p * .pi * 2))), .bottom)
        case .spin:
            let p = t.truncatingRemainder(dividingBy: 2.4) / 2.4
            return (CGFloat(1 + 0.15 * a * sin(p * .pi * 2)), 360 * p * (a > 1.05 ? 2 : 1), 0, .center)
        case .wave:
            return (1, 22 * a * sin(t * 6) * (sin(t * 1.3) > -0.3 ? 1 : 0.15), 0, .bottomTrailing)
        case .bounce:
            let p = t.truncatingRemainder(dividingBy: 1.3) / 1.3
            let h = abs(sin(p * .pi)) * size * 0.14 * a
            let sq = 1 - 0.07 * (1 - abs(sin(p * .pi)))
            return (CGFloat(sq), 0, CGFloat(-h), .bottom)
        }
    }
}

private struct BurstParticle: View {
    let emoji: String
    let size: CGFloat
    let seed: Int
    @State private var go = false

    var body: some View {
        let ang = Double((seed * 53) % 360) * .pi / 180
        let dist = 50 + Double((seed * 17) % 40)
        Text(emoji).font(.system(size: size))
            .offset(x: go ? CGFloat(cos(ang) * dist) : 0, y: go ? CGFloat(sin(ang) * dist - 20) : 0)
            .scaleEffect(go ? 0.3 : 1)
            .opacity(go ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { go = true } }
    }
}
