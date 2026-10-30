import SwiftUI

/// Номера обоев те же, что на Android: 0 — без обоев, 1–5 и 10–17 — для всех, 6–9 и 20–27 — Premium
let wallFree = [0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16, 17]
let wallPremium = [6, 7, 8, 9, 20, 21, 22, 23, 24, 25, 26, 27]
let wallAll = wallFree + wallPremium
func wallIsPremium(_ i: Int) -> Bool { (6...9).contains(i) || i >= 20 }

private struct SeededRNG {
    var s: UInt64
    init(_ seed: UInt64) { s = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat {
        s = s &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((s >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
}

struct WallArtView: View {
    let index: Int
    var body: some View {
        Canvas { ctx, size in WallArtView.draw(ctx, size, index) }
    }

    private static let purple = Color(hex: 0x7c5cff), teal = Color(hex: 0x13b0a5), pink = Color(hex: 0xff5b8a), blue = Color(hex: 0x22a6ff)

    private static func star4(_ g: inout GraphicsContext, _ c: CGPoint, _ s: CGFloat, _ col: Color) {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - s))
        p.addQuadCurve(to: CGPoint(x: c.x + s, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + s), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x - s, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - s), control: c)
        g.fill(p, with: .color(col))
    }
    private static func scatter(_ g: inout GraphicsContext, _ size: CGSize, _ n: Int, _ seed: UInt64, _ col: Color, _ maxR: CGFloat, _ baseA: Double) {
        var r = SeededRNG(seed)
        for _ in 0..<n {
            let c = CGPoint(x: r.next() * size.width, y: r.next() * size.height)
            let s = (0.4 + r.next()) * maxR
            star4(&g, c, s, col.opacity(baseA * Double(0.4 + 0.6 * r.next())))
        }
    }
    private static func blob(_ g: inout GraphicsContext, _ c: CGPoint, _ rad: CGFloat, _ col: Color) {
        g.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)),
               with: .radialGradient(Gradient(colors: [col, col.opacity(0)]), center: c, startRadius: 0, endRadius: rad))
    }
    private static func lineStyle(_ w: CGFloat = 1.4) -> StrokeStyle { StrokeStyle(lineWidth: w) }

    static func draw(_ ctx: GraphicsContext, _ size: CGSize, _ i: Int) {
        var g = ctx
        let w = size.width, h = size.height
        let full = CGRect(origin: .zero, size: size)
        switch i {
        case 10:
            let st: CGFloat = 26; var y: CGFloat = 0; var row = 0
            while y < h + st { var x: CGFloat = row % 2 == 0 ? 0 : st / 2; while x < w + st { g.fill(Path(ellipseIn: CGRect(x: x - 2.8, y: y - 2.8, width: 5.6, height: 5.6)), with: .color(purple.opacity(0.22))); x += st }; y += st * 0.8; row += 1 }
        case 11:
            let r: CGFloat = 26, dx = sqrt(3) * r, dy = 1.5 * r; var row = 0; var y: CGFloat = 0
            while y < h + r {
                var x: CGFloat = row % 2 == 0 ? 0 : dx / 2
                while x < w + r {
                    var p = Path()
                    for k in 0..<6 { let a = CGFloat(60 * k - 30) * .pi / 180; let pt = CGPoint(x: x + r * cos(a), y: y + r * sin(a)); if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) } }
                    p.closeSubpath(); g.stroke(p, with: .color(teal.opacity(0.2)), style: lineStyle()); x += dx
                }
                y += dy; row += 1
            }
        case 12:
            var y: CGFloat = 20; var k = 0
            while y < h + 20 {
                var p = Path(); p.move(to: CGPoint(x: 0, y: y)); var x: CGFloat = 0
                while x <= w { p.addLine(to: CGPoint(x: x, y: y + sin(x / 40 + CGFloat(k)) * 8)); x += 6 }
                g.stroke(p, with: .color((k % 2 == 0 ? pink : purple).opacity(0.2)), style: lineStyle()); y += 30; k += 1
            }
        case 13:
            var x = -h; var p = Path()
            while x < w + h { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x + h, y: h)); p.move(to: CGPoint(x: x + h, y: 0)); p.addLine(to: CGPoint(x: x, y: h)); x += 42 }
            g.stroke(p, with: .color(blue.opacity(0.18)), style: lineStyle(1.2))
        case 14:
            scatter(&g, size, 70, 14, purple, 7, 0.42); scatter(&g, size, 40, 15, pink, 4, 0.35)
        case 15:
            for c in [CGPoint.zero, CGPoint(x: w, y: h)] { var r: CGFloat = 30; while r < max(w, h) * 1.3 { g.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(teal.opacity(0.18)), style: lineStyle()); r += 30 } }
        case 16:
            var y: CGFloat = 18; var k = 0
            while y < h + 20 {
                var p = Path(); p.move(to: CGPoint(x: 0, y: y)); var x: CGFloat = 0; var up = true
                while x <= w + 14 { x += 14; p.addLine(to: CGPoint(x: x, y: y + (up ? -7 : 7))); up.toggle() }
                g.stroke(p, with: .color((k % 2 == 0 ? purple : teal).opacity(0.2)), style: lineStyle()); y += 26; k += 1
            }
        case 17:
            let st: CGFloat = 38; var y = st / 2; var row = 0; var p = Path()
            while y < h + st { var x: CGFloat = row % 2 == 0 ? st / 2 : st; while x < w + st { p.move(to: CGPoint(x: x - 5, y: y)); p.addLine(to: CGPoint(x: x + 5, y: y)); p.move(to: CGPoint(x: x, y: y - 5)); p.addLine(to: CGPoint(x: x, y: y + 5)); x += st }; y += st / 2; row += 1 }
            g.stroke(p, with: .color(pink.opacity(0.26)), style: lineStyle(1.6))
        case 20:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x071a2e), Color(hex: 0x1a0b3a)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            blob(&g, CGPoint(x: w * 0.2, y: h * 0.22), w * 0.8, Color(hex: 0x2ee6a6).opacity(0.34))
            blob(&g, CGPoint(x: w * 0.85, y: h * 0.35), w * 0.75, Color(hex: 0x22c1ff).opacity(0.30))
            blob(&g, CGPoint(x: w * 0.4, y: h * 0.7), w * 0.9, Color(hex: 0xb069ff).opacity(0.30))
            scatter(&g, size, 60, 20, .white, 3, 0.6)
        case 21:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x0d0221), Color(hex: 0x2a0a4a)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            let hy = h * 0.62, sr = w * 0.22
            g.fill(Path(ellipseIn: CGRect(x: w / 2 - sr, y: hy - w * 0.04 - sr, width: sr * 2, height: sr * 2)),
                   with: .linearGradient(Gradient(colors: [Color(hex: 0xffd24a), Color(hex: 0xff3d8a)]), startPoint: CGPoint(x: 0, y: hy - sr * 2), endPoint: CGPoint(x: 0, y: hy)))
            g.fill(Path(CGRect(x: 0, y: hy, width: w, height: h - hy)), with: .color(Color(hex: 0x0d0221)))
            var vp = Path(); for k in -12...12 { vp.move(to: CGPoint(x: w / 2, y: hy)); vp.addLine(to: CGPoint(x: w / 2 + CGFloat(k) * w * 0.18, y: h)) }
            g.stroke(vp, with: .color(Color(hex: 0xff2bd6).opacity(0.45)), style: lineStyle(1.2))
            var hp = Path(); var t: CGFloat = 0; while t < 1 { let y = hy + (h - hy) * t * t; hp.move(to: CGPoint(x: 0, y: y)); hp.addLine(to: CGPoint(x: w, y: y)); t += 0.09 }
            g.stroke(hp, with: .color(Color(hex: 0x22e6ff).opacity(0.4)), style: lineStyle(1.2))
            var hl = Path(); hl.move(to: CGPoint(x: 0, y: hy)); hl.addLine(to: CGPoint(x: w, y: hy)); g.stroke(hl, with: .color(Color(hex: 0xff2bd6)), style: lineStyle(1.6))
        case 22:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x04050e), Color(hex: 0x150c32)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            blob(&g, CGPoint(x: w * 0.3, y: h * 0.3), w * 0.9, Color(hex: 0x7c3dff).opacity(0.30))
            blob(&g, CGPoint(x: w * 0.8, y: h * 0.6), w * 0.8, Color(hex: 0xff4da6).opacity(0.22))
            blob(&g, CGPoint(x: w * 0.2, y: h * 0.85), w * 0.7, Color(hex: 0x2e7bff).opacity(0.24))
            var r = SeededRNG(22)
            for _ in 0..<160 { let rad = 0.6 + r.next() * 1.2; let c = CGPoint(x: r.next() * w, y: r.next() * h); g.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)), with: .color(.white.opacity(Double(0.3 + 0.6 * r.next())))) }
            scatter(&g, size, 14, 23, .white, 7, 0.85)
        case 23:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x14110a), Color(hex: 0x2b2210)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            let gold = Color(hex: 0xe8c26a); let r: CGFloat = 24; var y: CGFloat = 0; var row = 0
            while y < h + r {
                var x: CGFloat = row % 2 == 0 ? 0 : r
                while x < w + r * 2 {
                    for k in 1...3 { let rr = r * CGFloat(k) / 3; var p = Path(); p.addArc(center: CGPoint(x: x, y: y), radius: rr, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                        g.stroke(p, with: .color(gold.opacity(0.34 - Double(k) * 0.07)), style: lineStyle(1.1)) }
                    x += r * 2
                }
                y += r * 0.9; row += 1
            }
        case 24:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x042b40), Color(hex: 0x0b6a85)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            for k in 0..<6 {
                let y0 = h * (0.25 + 0.13 * CGFloat(k)); var top = Path(); var x: CGFloat = 0; top.move(to: CGPoint(x: 0, y: y0))
                while x <= w { top.addLine(to: CGPoint(x: x, y: y0 + sin(x / 50 + CGFloat(k) * 1.3) * 10)); x += 6 }
                var fill = top; fill.addLine(to: CGPoint(x: w, y: h)); fill.addLine(to: CGPoint(x: 0, y: h)); fill.closeSubpath()
                g.fill(fill, with: .color(Color(hex: 0x9bf0ff).opacity(0.07)))
                g.stroke(top, with: .color(Color(hex: 0xbdf7ff).opacity(0.22)), style: lineStyle(1.2))
            }
            var r = SeededRNG(24)
            for _ in 0..<22 { let rad = 2 + r.next() * 5; let c = CGPoint(x: r.next() * w, y: r.next() * h); g.stroke(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)), with: .color(.white.opacity(0.18)), style: lineStyle(1)) }
        case 25:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x2a0f24), Color(hex: 0x5e2146)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            blob(&g, CGPoint(x: w * 0.8, y: h * 0.15), w * 0.8, Color(hex: 0xff8fb8).opacity(0.22))
            var r = SeededRNG(25)
            for _ in 0..<46 {
                let c = CGPoint(x: r.next() * w, y: r.next() * h); let s = 5 + r.next() * 6; let a = r.next() * 180
                var gg = g; gg.translateBy(x: c.x, y: c.y); gg.rotate(by: .degrees(Double(a)))
                gg.fill(Path(ellipseIn: CGRect(x: -s, y: -s * 0.55, width: s * 2, height: s * 1.1)), with: .color(Color(hex: 0xffb3d1).opacity(Double(0.25 + 0.4 * r.next()))))
            }
        case 26:
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x0e2b25), Color(hex: 0x15483a)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            for (ci, c) in [CGPoint(x: w * 0.25, y: h * 0.3), CGPoint(x: w * 0.8, y: h * 0.75)].enumerated() {
                for k in 1...16 {
                    var p = Path(); var t: CGFloat = 0; let base = 16 * CGFloat(k)
                    while t <= 6.3 { let rr = base * (1 + 0.1 * sin(3 * t + CGFloat(k) * 0.4 + CGFloat(ci)) + 0.05 * sin(5 * t - CGFloat(k) * 0.3)); let pt = CGPoint(x: c.x + rr * cos(t), y: c.y + rr * sin(t)); if t == 0 { p.move(to: pt) } else { p.addLine(to: pt) }; t += 0.1 }
                    p.closeSubpath(); g.stroke(p, with: .color(Color(hex: 0x7dffd0).opacity(0.2)), style: lineStyle(1.1))
                }
            }
        case 27:
            g.fill(Path(full), with: .color(Color(hex: 0x12101f)))
            g.fill(Path(full), with: .linearGradient(Gradient(colors: [Color(hex: 0x7af0ff).opacity(0.5), Color(hex: 0xff9be8).opacity(0.5), Color(hex: 0xb59bff).opacity(0.5), Color(hex: 0x9bffd6).opacity(0.5)]), startPoint: .zero, endPoint: CGPoint(x: w, y: h)))
            var p = Path(); var x = -h; while x < w + h { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x + h, y: h)); x += 18 }
            g.stroke(p, with: .color(.white.opacity(0.09)), style: lineStyle(5))
            blob(&g, CGPoint(x: w * 0.7, y: h * 0.2), w * 0.7, Color.white.opacity(0.22))
        default: break
        }
    }
}
