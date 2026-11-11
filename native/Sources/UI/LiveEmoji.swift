import SwiftUI

/// «Живые» эмодзи с мимикой: лица нарисованы в коде (Canvas) и анимированы по кадрам —
/// моргают, смеются со слезами, краснеют от злости, сияют глазами-сердечками и т.д.
/// Для эмодзи без своей анимации — `nil` (тогда используется обычное покачивание).
enum LiveEmoji {
    static let faces: Set<String> = ["😂", "🤣", "😍", "🥰", "😎", "🤩", "😜", "🥳", "😱", "😭", "😡", "🤯", "😊", "😀", "😁", "😢", "😮", "😘", "🤔", "😏"]
    static let hearts: Set<String> = ["❤️", "💖", "💗", "💓", "❤", "🧡", "💛", "💚", "💙", "💜"]
    static func supports(_ e: String) -> Bool { faces.contains(e) || hearts.contains(e) || e == "🔥" }
}

struct LiveEmojiView: View {
    let emoji: String
    let size: CGFloat
    /// момент нажатия: после него анимация на секунду становится сильнее
    var tapAt: Date = .distantPast
    var fps: Double = 60

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / fps)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let boost = max(0, 1 - tl.date.timeIntervalSince(tapAt) / 0.9)
            Canvas { ctx, sz in
                let s = min(sz.width, sz.height)
                ctx.translateBy(x: sz.width / 2, y: sz.height / 2)
                ctx.scaleBy(x: s / 100, y: s / 100)
                if LiveEmoji.hearts.contains(emoji) { Painter.heart(&ctx, t, emoji, boost) }
                else if emoji == "🔥" { Painter.fire(&ctx, t, boost) }
                else { Painter.face(&ctx, t, emoji, boost) }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - рисование (система координат: центр 0,0; лицо радиусом ~40)

private enum Painter {
    static let yellow = Gradient(colors: [Color(hex: 0xFFE873), Color(hex: 0xFFC93C), Color(hex: 0xF29A1F)])
    static let brown = Color(hex: 0x5B3A1A)
    static let mouthDark = Color(hex: 0x6E2A12)
    static let tongue = Color(hex: 0xFF5A6E)
    static let tear = Color(hex: 0x5AC8FA)

    static func ease(_ x: Double) -> Double { x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2 }
    static func blink(_ t: Double, period: Double = 3.4, offset: Double = 0) -> Double {
        let p = (t + offset).truncatingRemainder(dividingBy: period)
        return p < 0.14 ? 1 - sin(p / 0.14 * .pi) : 1   // 1 — открыт, 0 — закрыт
    }

    // MARK: лицо

    static func face(_ c: inout GraphicsContext, _ t: Double, _ e: String, _ boost: Double) {
        let k = 1 + boost
        // общее движение тела
        var dx = 0.0, dy = 0.0, rot = 0.0, sx = 1.0, sy = 1.0
        switch e {
        case "😂":
            let p = t.truncatingRemainder(dividingBy: 1.4)
            let laugh = p < 0.9 ? 1.0 : 0.35
            dy = -abs(sin(t * 14)) * 3 * laugh * k
            rot = sin(t * 7) * 6 * laugh * k
            sy = 1 - 0.04 * abs(sin(t * 14)) * laugh
        case "🤣":
            rot = -22 + sin(t * 2.2) * 26 * k
            dy = -abs(sin(t * 12)) * 2 * k
        case "😡":
            dx = sin(t * 38) * 1.4 * k
        case "😱", "🤯":
            let p = t.truncatingRemainder(dividingBy: 2.2)
            if p < 0.6 { dx = sin(p * 60) * 1.6 * k }
            sy = 1 + 0.04 * sin(t * 3)
        case "🥳":
            rot = sin(t * 4) * 10 * k
            dy = -abs(sin(t * 4)) * 4 * k
        case "😍", "🥰", "😘":
            rot = sin(t * 1.6) * 5
            dy = sin(t * 2.4) * 1.5
        case "😜":
            rot = -10 + sin(t * 3) * 6
        case "🤔":
            rot = 8 + sin(t * 1.2) * 4
        default:
            dy = sin(t * 2) * 1.5
            sy = 1 + 0.015 * sin(t * 4)
        }
        c.translateBy(x: dx, y: dy)
        c.rotate(by: .degrees(rot))
        c.scaleBy(x: sx, y: sy)

        // шапка/взрыв позади
        if e == "🤯" { explosion(&c, t, k) }
        // голова
        var headColors = yellow
        if e == "😡" {
            let r = 0.75 + 0.25 * sin(t * 3)
            headColors = Gradient(colors: [Color(hex: 0xFF8A65), Color(red: 0.95, green: 0.25 * (1 - r) + 0.18, blue: 0.12), Color(hex: 0xB3261E)])
        }
        let head = Path(ellipseIn: CGRect(x: -40, y: -40, width: 80, height: 80))
        c.fill(head, with: .radialGradient(headColors, center: CGPoint(x: -12, y: -16), startRadius: 2, endRadius: 62))
        c.stroke(head, with: .color(Color(hex: 0xE08A12).opacity(e == "😡" ? 0 : 0.5)), lineWidth: 1)
        // блик
        c.fill(Path(ellipseIn: CGRect(x: -26, y: -34, width: 26, height: 14)), with: .color(.white.opacity(0.35)))

        switch e {
        case "😂": laughing(&c, t, tears: true, k)
        case "🤣": laughing(&c, t, tears: true, k)
        case "😁", "😀": eyesOpen(&c, t, wide: false); grin(&c, t, open: e == "😀")
        case "😊": eyesHappy(&c); smile(&c, 1); blush(&c, 0.5)
        case "😍": heartEyes(&c, t, k); smile(&c, 1.1, open: true)
        case "🥰": eyesHappy(&c); smile(&c, 1); blush(&c, 0.7); orbitHearts(&c, t)
        case "😘": eyesHappy(&c, wink: true); kiss(&c, t)
        case "😎": sunglasses(&c, t); smile(&c, 0.8, smirk: true)
        case "🤩": starEyes(&c, t, k); smile(&c, 1.2, open: true)
        case "😜": winkTongue(&c, t)
        case "🥳": eyesHappy(&c); smile(&c, 1.1, open: true); blush(&c, 0.5); partyHat(&c, t); horn(&c, t); confetti(&c, t)
        case "😱": scream(&c, t, k)
        case "🤯": eyesWide(&c, t); mouthO(&c, t, 7)
        case "😭": crying(&c, t)
        case "😢": sad(&c, t)
        case "😮": eyesWide(&c, t); mouthO(&c, t, 6)
        case "😡": angry(&c, t, k)
        case "🤔": thinking(&c, t)
        case "😏": smirk(&c, t)
        default: eyesOpen(&c, t, wide: false); smile(&c, 1)
        }
    }

    // глаза
    static func eye(_ c: inout GraphicsContext, _ x: Double, _ y: Double, w: Double = 8, h: Double = 12, open: Double = 1, look: CGPoint = .zero) {
        let hh = max(1.4, h * open)
        let r = CGRect(x: x - w / 2 + look.x, y: y - hh / 2 + look.y, width: w, height: hh)
        c.fill(Path(ellipseIn: r), with: .color(brown))
        if open > 0.5 { c.fill(Path(ellipseIn: CGRect(x: x - 1 + look.x, y: y - hh / 2 + 2 + look.y, width: 3, height: 3)), with: .color(.white.opacity(0.85))) }
    }
    static func eyesOpen(_ c: inout GraphicsContext, _ t: Double, wide: Bool) {
        let o = blink(t)
        let look = CGPoint(x: sin(t * 0.7) * 1.5, y: 0)
        eye(&c, -14, -8, open: o, look: look); eye(&c, 14, -8, open: o, look: look)
    }
    static func eyesHappy(_ c: inout GraphicsContext, wink: Bool = false) {
        var p = Path()
        p.move(to: CGPoint(x: -21, y: -6)); p.addQuadCurve(to: CGPoint(x: -7, y: -6), control: CGPoint(x: -14, y: -16))
        if !wink { p.move(to: CGPoint(x: 7, y: -6)); p.addQuadCurve(to: CGPoint(x: 21, y: -6), control: CGPoint(x: 14, y: -16)) }
        c.stroke(p, with: .color(brown), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        if wink { eye(&c, 14, -8, w: 7, h: 11) }
    }
    static func eyesWide(_ c: inout GraphicsContext, _ t: Double) {
        for x in [-14.0, 14.0] {
            c.fill(Path(ellipseIn: CGRect(x: x - 8, y: -18, width: 16, height: 19)), with: .color(.white))
            let j = sin(t * 23) * 0.8
            c.fill(Path(ellipseIn: CGRect(x: x - 3.6 + j, y: -12, width: 7.2, height: 8)), with: .color(brown))
        }
    }
    static func blush(_ c: inout GraphicsContext, _ a: Double) {
        for x in [-24.0, 24.0] {
            c.fill(Path(ellipseIn: CGRect(x: x - 7, y: 3, width: 14, height: 7)), with: .color(Color(hex: 0xFF6F7D).opacity(a)))
        }
    }

    // рты
    static func smile(_ c: inout GraphicsContext, _ w: Double, open: Bool = false, smirk: Bool = false) {
        if open {
            var p = Path()
            p.move(to: CGPoint(x: -17 * w, y: 9)); p.addQuadCurve(to: CGPoint(x: 17 * w, y: 9), control: CGPoint(x: 0, y: 9))
            p.addQuadCurve(to: CGPoint(x: -17 * w, y: 9), control: CGPoint(x: 0, y: 34))
            c.fill(p, with: .color(mouthDark))
            c.fill(Path(ellipseIn: CGRect(x: -8, y: 18, width: 16, height: 8)), with: .color(tongue))
            var teeth = Path(); teeth.move(to: CGPoint(x: -14 * w, y: 10)); teeth.addLine(to: CGPoint(x: 14 * w, y: 10)); teeth.addLine(to: CGPoint(x: 12 * w, y: 14)); teeth.addLine(to: CGPoint(x: -12 * w, y: 14)); teeth.closeSubpath()
            c.fill(teeth, with: .color(.white))
        } else {
            var p = Path()
            p.move(to: CGPoint(x: -15 * w, y: 10)); p.addQuadCurve(to: CGPoint(x: 15 * w, y: smirk ? 6 : 10), control: CGPoint(x: smirk ? 4 : 0, y: 24))
            c.stroke(p, with: .color(brown), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        }
    }
    static func grin(_ c: inout GraphicsContext, _ t: Double, open: Bool) {
        smile(&c, 1.15, open: true)
    }
    static func mouthO(_ c: inout GraphicsContext, _ t: Double, _ r: Double) {
        let s = 1 + 0.15 * sin(t * 5)
        c.fill(Path(ellipseIn: CGRect(x: -r * s, y: 12, width: 2 * r * s, height: 2.4 * r * s)), with: .color(mouthDark))
    }

    // смех со слезами
    static func laughing(_ c: inout GraphicsContext, _ t: Double, tears: Bool, _ k: Double) {
        var eyes = Path()
        for x in [-14.0, 14.0] {
            eyes.move(to: CGPoint(x: x - 8, y: -12)); eyes.addLine(to: CGPoint(x: x + (x < 0 ? 6 : -6), y: -7)); eyes.addLine(to: CGPoint(x: x - 8 + 16 * (x < 0 ? 0 : 1), y: -2))
        }
        var l = Path()
        l.move(to: CGPoint(x: -22, y: -13)); l.addLine(to: CGPoint(x: -8, y: -7)); l.addLine(to: CGPoint(x: -22, y: -1))
        l.move(to: CGPoint(x: 22, y: -13)); l.addLine(to: CGPoint(x: 8, y: -7)); l.addLine(to: CGPoint(x: 22, y: -1))
        c.stroke(l, with: .color(brown), style: StrokeStyle(lineWidth: 3.6, lineCap: .round, lineJoin: .round))
        // рот — широкий, «ходит» от смеха
        let o = 0.8 + 0.2 * abs(sin(t * 14))
        var m = Path()
        m.move(to: CGPoint(x: -22, y: 6)); m.addQuadCurve(to: CGPoint(x: 22, y: 6), control: CGPoint(x: 0, y: 4))
        m.addQuadCurve(to: CGPoint(x: -22, y: 6), control: CGPoint(x: 0, y: 6 + 32 * o))
        c.fill(m, with: .color(mouthDark))
        var teeth = Path(); teeth.move(to: CGPoint(x: -19, y: 7)); teeth.addLine(to: CGPoint(x: 19, y: 7)); teeth.addLine(to: CGPoint(x: 16, y: 12)); teeth.addLine(to: CGPoint(x: -16, y: 12)); teeth.closeSubpath()
        c.fill(teeth, with: .color(.white))
        c.fill(Path(ellipseIn: CGRect(x: -9, y: 13 + 12 * o, width: 18, height: 8)), with: .color(tongue))
        guard tears else { return }
        // слёзы-брызги: струйки из уголков глаз
        for side in [-1.0, 1.0] {
            for i in 0..<3 {
                let p = (t * 1.6 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let x = side * (24 + p * 22 * k), y = -6 + p * p * 30 - p * 14
                let r = 4.2 * (1 - p * 0.5)
                var d = Path()
                d.addEllipse(in: CGRect(x: x - r, y: y - r * 1.2, width: 2 * r, height: 2.4 * r))
                c.fill(d, with: .color(tear.opacity(1 - p * 0.6)))
            }
        }
    }

    static func heartPath(_ cx: Double, _ cy: Double, _ s: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy + 6 * s))
        p.addCurve(to: CGPoint(x: cx - 8 * s, y: cy - 2 * s), control1: CGPoint(x: cx - 3 * s, y: cy + 3 * s), control2: CGPoint(x: cx - 8 * s, y: cy + 1 * s))
        p.addArc(center: CGPoint(x: cx - 4 * s, y: cy - 2.5 * s), radius: 4 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: cx + 4 * s, y: cy - 2.5 * s), radius: 4 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: cx, y: cy + 6 * s), control1: CGPoint(x: cx + 8 * s, y: cy + 1 * s), control2: CGPoint(x: cx + 3 * s, y: cy + 3 * s))
        return p
    }
    static func heartEyes(_ c: inout GraphicsContext, _ t: Double, _ k: Double) {
        let b = 1 + 0.18 * max(0, sin(t * 6)) * k
        for x in [-14.0, 14.0] {
            c.fill(heartPath(x, -9, 1.25 * b), with: .linearGradient(Gradient(colors: [Color(hex: 0xFF6B81), Color(hex: 0xE0143C)]), startPoint: CGPoint(x: x, y: -18), endPoint: CGPoint(x: x, y: 0)))
        }
    }
    static func starPath(_ cx: Double, _ cy: Double, _ r: Double, _ rot: Double) -> Path {
        var p = Path()
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2 + rot
            let rr = i % 2 == 0 ? r : r * 0.45
            let pt = CGPoint(x: cx + cos(a) * rr, y: cy + sin(a) * rr)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
    static func starEyes(_ c: inout GraphicsContext, _ t: Double, _ k: Double) {
        for (i, x) in [-14.0, 14.0].enumerated() {
            let s = 1 + 0.15 * sin(t * 5 + Double(i)) * k
            c.fill(starPath(x, -9, 10 * s, sin(t * 2) * 0.3), with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF3A0), Color(hex: 0xFFB300)]), startPoint: CGPoint(x: x, y: -20), endPoint: CGPoint(x: x, y: 2)))
            c.stroke(starPath(x, -9, 10 * s, sin(t * 2) * 0.3), with: .color(Color(hex: 0xC77800)), lineWidth: 1)
        }
    }
    static func sunglasses(_ c: inout GraphicsContext, _ t: Double) {
        var g = Path()
        g.addRoundedRect(in: CGRect(x: -30, y: -17, width: 26, height: 17), cornerSize: CGSize(width: 7, height: 7))
        g.addRoundedRect(in: CGRect(x: 4, y: -17, width: 26, height: 17), cornerSize: CGSize(width: 7, height: 7))
        g.addRect(CGRect(x: -6, y: -14, width: 12, height: 3))
        g.addRect(CGRect(x: -40, y: -14, width: 11, height: 3)); g.addRect(CGRect(x: 29, y: -14, width: 11, height: 3))
        c.fill(g, with: .linearGradient(Gradient(colors: [Color(hex: 0x2B2B33), .black]), startPoint: CGPoint(x: 0, y: -17), endPoint: CGPoint(x: 0, y: 0)))
        // проходящий блик
        let p = (t * 0.45).truncatingRemainder(dividingBy: 1)
        var clip = c
        clip.clip(to: g)
        let x = -50 + p * 120
        var sh = Path(); sh.move(to: CGPoint(x: x, y: -20)); sh.addLine(to: CGPoint(x: x + 8, y: -20)); sh.addLine(to: CGPoint(x: x - 2, y: 3)); sh.addLine(to: CGPoint(x: x - 10, y: 3)); sh.closeSubpath()
        clip.fill(sh, with: .color(.white.opacity(0.5)))
    }
    static func winkTongue(_ c: inout GraphicsContext, _ t: Double) {
        eye(&c, -14, -8, w: 9, h: 14)
        var w = Path(); w.move(to: CGPoint(x: 6, y: -8)); w.addQuadCurve(to: CGPoint(x: 22, y: -8), control: CGPoint(x: 14, y: -2))
        c.stroke(w, with: .color(brown), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        var m = Path(); m.move(to: CGPoint(x: -16, y: 8)); m.addQuadCurve(to: CGPoint(x: 16, y: 8), control: CGPoint(x: 0, y: 22))
        c.fill(m, with: .color(mouthDark))
        let wag = sin(t * 9) * 4
        var tg = Path(); tg.addRoundedRect(in: CGRect(x: -2 + wag * 0.3, y: 12, width: 15, height: 18 + abs(wag)), cornerSize: CGSize(width: 7.5, height: 7.5))
        c.fill(tg, with: .color(tongue))
        c.stroke(Path { $0.move(to: CGPoint(x: 5.5 + wag * 0.3, y: 15)); $0.addLine(to: CGPoint(x: 5.5 + wag * 0.3, y: 25)) }, with: .color(Color(hex: 0xD63A4E)), lineWidth: 1.4)
    }
    static func kiss(_ c: inout GraphicsContext, _ t: Double) {
        var m = Path()
        m.move(to: CGPoint(x: -2, y: 8)); m.addQuadCurve(to: CGPoint(x: -2, y: 16), control: CGPoint(x: 6, y: 12))
        m.move(to: CGPoint(x: -2, y: 16)); m.addQuadCurve(to: CGPoint(x: -2, y: 24), control: CGPoint(x: 6, y: 20))
        c.stroke(m, with: .color(brown), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        blush(&c, 0.6)
        let p = (t * 0.6).truncatingRemainder(dividingBy: 1)
        let s = 0.5 + p * 0.9
        c.fill(heartPath(14 + p * 26, 12 - p * 30, s), with: .color(Color(hex: 0xFF3B5C).opacity(1 - p)))
    }
    static func orbitHearts(_ c: inout GraphicsContext, _ t: Double) {
        for i in 0..<3 {
            let a = t * 1.4 + Double(i) * 2.1
            let x = cos(a) * 46, y = sin(a) * 14 - 30
            c.fill(heartPath(x, y, 0.9), with: .color(Color(hex: i == 1 ? 0xFF8FB0 : 0xFF3B5C).opacity(sin(a) > -0.2 ? 1 : 0.55)))
        }
    }
    static func partyHat(_ c: inout GraphicsContext, _ t: Double) {
        var h = Path(); h.move(to: CGPoint(x: -14, y: -34)); h.addLine(to: CGPoint(x: 10, y: -38)); h.addLine(to: CGPoint(x: 4, y: -68)); h.closeSubpath()
        c.fill(h, with: .linearGradient(Gradient(colors: [Color(hex: 0x7C5CFF), Color(hex: 0xFF4FD8)]), startPoint: CGPoint(x: -14, y: -36), endPoint: CGPoint(x: 4, y: -68)))
        let b = 1 + 0.2 * sin(t * 8)
        c.fill(Path(ellipseIn: CGRect(x: 4 - 4.5 * b, y: -72 - 4.5 * b, width: 9 * b, height: 9 * b)), with: .color(Color(hex: 0xFFD84F)))
    }
    static func horn(_ c: inout GraphicsContext, _ t: Double) {
        let p = (t * 1.2).truncatingRemainder(dividingBy: 1)
        let len = 6 + 20 * ease(p < 0.5 ? p * 2 : (1 - p) * 2)
        var r = Path(); r.addRoundedRect(in: CGRect(x: 4, y: 14, width: len, height: 5), cornerSize: CGSize(width: 2.5, height: 2.5))
        c.fill(r, with: .color(Color(hex: 0x3FD0FF)))
    }
    static func confetti(_ c: inout GraphicsContext, _ t: Double) {
        let cols: [UInt32] = [0xFF4FD8, 0x3FD0FF, 0xFFD84F, 0x7BD88F, 0xFF8A3D]
        for i in 0..<10 {
            let p = (t * 0.5 + Double(i) * 0.1).truncatingRemainder(dividingBy: 1)
            let x = -46 + Double((i * 37) % 92), y = -50 + p * 100
            var r = Path(); r.addRect(CGRect(x: -2, y: -1, width: 4, height: 2.4))
            var cc = c
            cc.translateBy(x: x + sin(t * 3 + Double(i)) * 4, y: y)
            cc.rotate(by: .radians(t * 4 + Double(i)))
            cc.fill(r, with: .color(Color(hex: cols[i % cols.count]).opacity(p < 0.85 ? 1 : (1 - p) / 0.15)))
        }
    }
    static func scream(_ c: inout GraphicsContext, _ t: Double, _ k: Double) {
        // бледно-голубой лоб
        var top = c
        top.clip(to: Path(ellipseIn: CGRect(x: -40, y: -40, width: 80, height: 80)))
        top.fill(Path(CGRect(x: -40, y: -40, width: 80, height: 34)), with: .linearGradient(Gradient(colors: [Color(hex: 0x8FB8FF).opacity(0.85), .clear]), startPoint: CGPoint(x: 0, y: -40), endPoint: CGPoint(x: 0, y: -6)))
        eyesWide(&c, t)
        let s = 1 + 0.12 * abs(sin(t * 6)) * k
        var m = Path(); m.addEllipse(in: CGRect(x: -7 * s, y: 6, width: 14 * s, height: 26 * s))
        c.fill(m, with: .color(mouthDark))
        // ладони у щёк
        for side in [-1.0, 1.0] {
            var h = Path(); h.addRoundedRect(in: CGRect(x: side < 0 ? -46 : 30, y: 4, width: 16, height: 30), cornerSize: CGSize(width: 8, height: 8))
            c.fill(h, with: .color(Color(hex: 0xFFC93C)))
            c.stroke(h, with: .color(Color(hex: 0xE08A12)), lineWidth: 1.2)
        }
    }
    static func explosion(_ c: inout GraphicsContext, _ t: Double, _ k: Double) {
        let p = (t * 0.7).truncatingRemainder(dividingBy: 1)
        for i in 0..<7 {
            let a = -Double.pi / 2 + (Double(i) - 3) * 0.32
            let r = 34 + p * 30 * k
            let rr = 8 + 10 * p
            c.fill(Path(ellipseIn: CGRect(x: cos(a) * r - rr, y: sin(a) * r - rr, width: 2 * rr, height: 2 * rr)),
                   with: .color((i % 2 == 0 ? Color(hex: 0xFF8A3D) : Color(hex: 0xC8C8D0)).opacity(1 - p)))
        }
    }
    static func crying(_ c: inout GraphicsContext, _ t: Double) {
        var e = Path()
        e.move(to: CGPoint(x: -22, y: -10)); e.addQuadCurve(to: CGPoint(x: -6, y: -10), control: CGPoint(x: -14, y: -4))
        e.move(to: CGPoint(x: 6, y: -10)); e.addQuadCurve(to: CGPoint(x: 22, y: -10), control: CGPoint(x: 14, y: -4))
        c.stroke(e, with: .color(brown), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        // ручьи слёз
        for x in [-14.0, 14.0] {
            var r = Path(); r.addRoundedRect(in: CGRect(x: x - 5, y: -6, width: 10, height: 46), cornerSize: CGSize(width: 5, height: 5))
            c.fill(r, with: .linearGradient(Gradient(colors: [tear, tear.opacity(0.6)]), startPoint: CGPoint(x: x, y: -6), endPoint: CGPoint(x: x, y: 40)))
            for i in 0..<3 {
                let p = (t * 1.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                c.fill(Path(ellipseIn: CGRect(x: x - 3, y: -4 + p * 40, width: 6, height: 8)), with: .color(.white.opacity(0.55 * (1 - p))))
            }
        }
        let o = 0.7 + 0.3 * abs(sin(t * 9))
        var m = Path(); m.addEllipse(in: CGRect(x: -12, y: 10, width: 24, height: 14 * o))
        c.fill(m, with: .color(mouthDark))
    }
    static func sad(_ c: inout GraphicsContext, _ t: Double) {
        eye(&c, -14, -6, open: blink(t)); eye(&c, 14, -6, open: blink(t))
        var b = Path()
        b.move(to: CGPoint(x: -22, y: -18)); b.addLine(to: CGPoint(x: -8, y: -22))
        b.move(to: CGPoint(x: 22, y: -18)); b.addLine(to: CGPoint(x: 8, y: -22))
        c.stroke(b, with: .color(brown), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        var m = Path(); m.move(to: CGPoint(x: -12, y: 22)); m.addQuadCurve(to: CGPoint(x: 12, y: 22), control: CGPoint(x: 0, y: 12))
        c.stroke(m, with: .color(brown), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        let p = (t * 0.6).truncatingRemainder(dividingBy: 1)
        c.fill(Path(ellipseIn: CGRect(x: 16, y: 0 + p * 26, width: 7, height: 10)), with: .color(tear.opacity(1 - p)))
    }
    static func angry(_ c: inout GraphicsContext, _ t: Double, _ k: Double) {
        var b = Path()
        b.move(to: CGPoint(x: -24, y: -20)); b.addLine(to: CGPoint(x: -6, y: -12))
        b.move(to: CGPoint(x: 24, y: -20)); b.addLine(to: CGPoint(x: 6, y: -12))
        c.stroke(b, with: .color(Color(hex: 0x3A1206)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        eye(&c, -14, -5, w: 8, h: 9, open: 1); eye(&c, 14, -5, w: 8, h: 9, open: 1)
        var m = Path(); m.move(to: CGPoint(x: -14, y: 22)); m.addQuadCurve(to: CGPoint(x: 14, y: 22), control: CGPoint(x: 0, y: 10))
        c.stroke(m, with: .color(Color(hex: 0x3A1206)), style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        // пар из ушей
        for side in [-1.0, 1.0] {
            for i in 0..<2 {
                let p = (t * 1.3 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                let r = 4 + p * 8
                c.fill(Path(ellipseIn: CGRect(x: side * (40 + p * 12) - r, y: -30 - p * 18 - r, width: 2 * r, height: 2 * r)), with: .color(.white.opacity(0.7 * (1 - p) * k)))
            }
        }
    }
    static func thinking(_ c: inout GraphicsContext, _ t: Double) {
        eye(&c, -14, -8, open: blink(t), look: CGPoint(x: 3, y: -2)); eye(&c, 14, -8, open: blink(t), look: CGPoint(x: 3, y: -2))
        var b = Path(); b.move(to: CGPoint(x: 8, y: -22)); b.addQuadCurve(to: CGPoint(x: 22, y: -20), control: CGPoint(x: 15, y: -27))
        c.stroke(b, with: .color(brown), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        var m = Path(); m.move(to: CGPoint(x: -10, y: 16)); m.addLine(to: CGPoint(x: 10, y: 13))
        c.stroke(m, with: .color(brown), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        // рука у подбородка постукивает пальцем
        let tap = sin(t * 5) * 2
        var h = Path(); h.addRoundedRect(in: CGRect(x: -16, y: 22, width: 26, height: 14), cornerSize: CGSize(width: 7, height: 7))
        h.addRoundedRect(in: CGRect(x: -2, y: 8 + tap, width: 7, height: 18), cornerSize: CGSize(width: 3.5, height: 3.5))
        c.fill(h, with: .color(Color(hex: 0xFFB82E)))
        c.stroke(h, with: .color(Color(hex: 0xE08A12)), lineWidth: 1.2)
    }
    static func smirk(_ c: inout GraphicsContext, _ t: Double) {
        let o = blink(t, period: 4)
        eye(&c, -14, -7, w: 9, h: 7 * o + 1, open: 1, look: CGPoint(x: 3, y: 0)); eye(&c, 14, -7, w: 9, h: 7 * o + 1, open: 1, look: CGPoint(x: 3, y: 0))
        var m = Path(); m.move(to: CGPoint(x: -8, y: 16)); m.addQuadCurve(to: CGPoint(x: 16, y: 8), control: CGPoint(x: 8, y: 18))
        c.stroke(m, with: .color(brown), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
    }

    // MARK: сердце и огонь

    static func heart(_ c: inout GraphicsContext, _ t: Double, _ e: String, _ boost: Double) {
        let col: (UInt32, UInt32)
        switch e {
        case "🧡": col = (0xFFB066, 0xF57C00)
        case "💛": col = (0xFFE873, 0xF2B705)
        case "💚": col = (0x8BE38F, 0x2E9E5B)
        case "💙": col = (0x74C0FC, 0x1E6FE0)
        case "💜": col = (0xC9A0FF, 0x7B2CBF)
        case "💖", "💗": col = (0xFF9AC9, 0xE0307A)
        default: col = (0xFF6B81, 0xD9143A)
        }
        // двойной удар сердца
        let p = t.truncatingRemainder(dividingBy: 1.05) / 1.05
        let beat = p < 0.12 ? p / 0.12 : p < 0.26 ? 1 - (p - 0.12) / 0.14 : p < 0.36 ? 0.6 * (p - 0.26) / 0.1 : p < 0.5 ? 0.6 - 0.6 * (p - 0.36) / 0.14 : 0
        let s = 1 + 0.16 * beat * (1 + boost)
        // свечение
        c.fill(Path(ellipseIn: CGRect(x: -46 * s, y: -46 * s, width: 92 * s, height: 92 * s)),
               with: .radialGradient(Gradient(colors: [Color(hex: col.0).opacity(0.35 * beat), .clear]), center: .zero, startRadius: 4, endRadius: 50 * s))
        c.scaleBy(x: s, y: s)
        let h = heartPath(0, 0, 5.2)
        c.fill(h, with: .linearGradient(Gradient(colors: [Color(hex: col.0), Color(hex: col.1)]), startPoint: CGPoint(x: -20, y: -36), endPoint: CGPoint(x: 20, y: 30)))
        c.fill(Path(ellipseIn: CGRect(x: -30, y: -26, width: 14, height: 9)), with: .color(.white.opacity(0.45)))
        if e == "💖" || e == "💗" {
            for i in 0..<4 {
                let a = t * 2 + Double(i) * .pi / 2
                c.fill(starPath(cos(a) * 34, sin(a) * 30, 5 + 2 * sin(t * 6 + Double(i)), 0), with: .color(.white.opacity(0.85)))
            }
        }
    }

    static func fire(_ c: inout GraphicsContext, _ t: Double, _ boost: Double) {
        let k = 1 + boost
        func flame(_ w: Double, _ h: Double, _ ph: Double, _ g: Gradient) {
            let sway = sin(t * 7 + ph) * 5 * k, lick = sin(t * 11 + ph) * 3
            var p = Path()
            p.move(to: CGPoint(x: 0, y: 38))
            p.addCurve(to: CGPoint(x: -w, y: 8), control1: CGPoint(x: -w * 0.9, y: 38), control2: CGPoint(x: -w * 1.05, y: 22))
            p.addCurve(to: CGPoint(x: sway, y: -h + lick), control1: CGPoint(x: -w * 0.9, y: -6), control2: CGPoint(x: -w * 0.2 + sway, y: -h * 0.5))
            p.addCurve(to: CGPoint(x: w, y: 8), control1: CGPoint(x: w * 0.3 + sway, y: -h * 0.45), control2: CGPoint(x: w * 0.95, y: -6))
            p.addCurve(to: CGPoint(x: 0, y: 38), control1: CGPoint(x: w * 1.05, y: 22), control2: CGPoint(x: w * 0.9, y: 38))
            c.fill(p, with: .linearGradient(g, startPoint: CGPoint(x: 0, y: -h), endPoint: CGPoint(x: 0, y: 38)))
        }
        flame(34, 46 + 4 * sin(t * 5), 0, Gradient(colors: [Color(hex: 0xFF5A1F), Color(hex: 0xE5341B)]))
        flame(24, 30 + 4 * sin(t * 6 + 1), 1.3, Gradient(colors: [Color(hex: 0xFFB020), Color(hex: 0xFF7A1A)]))
        flame(13, 12 + 3 * sin(t * 8 + 2), 2.1, Gradient(colors: [Color(hex: 0xFFF3A0), Color(hex: 0xFFD84F)]))
        // искры
        for i in 0..<5 {
            let p = (t * 0.9 + Double(i) * 0.2).truncatingRemainder(dividingBy: 1)
            let x = sin(Double(i) * 2.3 + t) * 22, y = 10 - p * 70
            c.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)), with: .color(Color(hex: 0xFFC93C).opacity(1 - p)))
        }
    }
}
