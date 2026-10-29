import SwiftUI

// MARK: - Нарисованные анимированные значки статуса (не эмодзи)

private func C(_ h: UInt32) -> Color { Color(hex: h) }
private func vg(_ y0: CGFloat, _ y1: CGFloat, _ c: [UInt32]) -> GraphicsContext.Shading {
    .linearGradient(Gradient(colors: c.map { C($0) }), startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: 0, y: y1))
}
private func dg(_ c: [UInt32]) -> GraphicsContext.Shading {
    .linearGradient(Gradient(colors: c.map { C($0) }), startPoint: .zero, endPoint: CGPoint(x: 100, y: 100))
}
private func xf(_ c: GraphicsContext, rot: Double = 0, sx: CGFloat = 1, sy: CGFloat = 1, at: CGPoint = .zero, dx: CGFloat = 0, dy: CGFloat = 0) -> GraphicsContext {
    var g = c
    g.translateBy(x: dx + at.x, y: dy + at.y)
    g.rotate(by: .degrees(rot))
    g.scaleBy(x: sx, y: sy)
    g.translateBy(x: -at.x, y: -at.y)
    return g
}
private func P(_ f: (inout Path) -> Void) -> Path { var p = Path(); f(&p); return p }
private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

private func starPath(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ k: CGFloat = 0.5) -> Path {
    P { p in
        for i in 0..<10 {
            let rr = i % 2 == 0 ? r : r * k
            let a = -Double.pi / 2 + Double(i) * Double.pi / 5
            let q = pt(cx + rr * CGFloat(cos(a)), cy + rr * CGFloat(sin(a)))
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath()
    }
}

private func sparkle(_ c: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ alpha: Double) {
    if alpha <= 0.01 { return }
    let p = P { p in
        p.move(to: pt(cx, cy - r)); p.addQuadCurve(to: pt(cx + r, cy), control: pt(cx, cy))
        p.addQuadCurve(to: pt(cx, cy + r), control: pt(cx, cy)); p.addQuadCurve(to: pt(cx - r, cy), control: pt(cx, cy))
        p.addQuadCurve(to: pt(cx, cy - r), control: pt(cx, cy)); p.closeSubpath()
    }
    c.fill(p, with: .color(.white.opacity(min(1, alpha))))
}

private func drawIcon(_ c: GraphicsContext, _ k: String, _ t: Double) {
    let w = 2 * Double.pi * t
    let sn = CGFloat(sin(w)), cs = CGFloat(cos(w))
    switch k {
    case "fire":
        let g = xf(c, sx: 1 - 0.03 * sn, sy: 1 + 0.08 * sn, at: pt(50, 95))
        let outer = P { p in
            p.move(to: pt(50, 4)); p.addCurve(to: pt(82, 62), control1: pt(58, 24), control2: pt(82, 34))
            p.addCurve(to: pt(50, 95), control1: pt(82, 83), control2: pt(67, 95)); p.addCurve(to: pt(18, 62), control1: pt(33, 95), control2: pt(18, 83))
            p.addCurve(to: pt(33, 32), control1: pt(18, 48), control2: pt(26, 40)); p.addCurve(to: pt(44, 48), control1: pt(36, 44), control2: pt(40, 48))
            p.addCurve(to: pt(50, 4), control1: pt(40, 30), control2: pt(44, 14)); p.closeSubpath()
        }
        g.fill(outer, with: vg(4, 95, [0xFFC93C, 0xFF7A18, 0xE8321E]))
        let g2 = xf(g, sy: 1 + 0.1 * cs, at: pt(50, 95))
        let inner = P { p in
            p.move(to: pt(50, 44)); p.addCurve(to: pt(68, 76), control1: pt(56, 56), control2: pt(68, 62))
            p.addCurve(to: pt(50, 94), control1: pt(68, 87), control2: pt(60, 94)); p.addCurve(to: pt(32, 76), control1: pt(40, 94), control2: pt(32, 87))
            p.addCurve(to: pt(50, 44), control1: pt(32, 64), control2: pt(46, 58)); p.closeSubpath()
        }
        g2.fill(inner, with: vg(44, 94, [0xFFF3A0, 0xFFC93C]))
    case "heart":
        let s = 1 + 0.1 * max(0, sn) + 0.05 * max(0, CGFloat(sin(w * 2 + 1)))
        let g = xf(c, sx: s, sy: s, at: pt(50, 52))
        let h = P { p in
            p.move(to: pt(50, 90)); p.addCurve(to: pt(26, 18), control1: pt(8, 60), control2: pt(4, 30))
            p.addCurve(to: pt(50, 28), control1: pt(40, 11), control2: pt(48, 20)); p.addCurve(to: pt(74, 18), control1: pt(52, 20), control2: pt(60, 11))
            p.addCurve(to: pt(50, 90), control1: pt(96, 30), control2: pt(92, 60)); p.closeSubpath()
        }
        g.fill(h, with: dg([0xFF6B8B, 0xE0245E]))
        g.fill(Path(ellipseIn: CGRect(x: 22, y: 26, width: 14, height: 9)), with: .color(.white.opacity(0.55)))
    case "star":
        let s = 1 + 0.06 * cs
        let g = xf(c, rot: Double(14 * sn), sx: s, sy: s, at: pt(54, 54))
        g.fill(starPath(50, 54, 46, 0.48), with: vg(8, 98, [0xFFE066, 0xFFB020, 0xFF8A00]))
        g.stroke(starPath(50, 54, 46, 0.48), with: .color(.white.opacity(0.55)), lineWidth: 1.6)
        sparkle(c, 84, 18, 10, Double(max(0, cs))); sparkle(c, 16, 80, 7, Double(max(0, -cs)))
    case "rocket":
        let g = xf(c, rot: 35, at: pt(50, 50), dy: 3 * sn)
        let flame = P { p in
            p.move(to: pt(40, 72)); p.addCurve(to: pt(50, 96 + 6 * sn), control1: pt(40, 86), control2: pt(48, 90 + 6 * sn))
            p.addCurve(to: pt(60, 72), control1: pt(52, 90 + 6 * sn), control2: pt(60, 86)); p.closeSubpath()
        }
        g.fill(flame, with: vg(72, 100, [0xFFE066, 0xFF6A00]))
        g.fill(P { p in p.move(to: pt(34, 52)); p.addLine(to: pt(16, 78)); p.addLine(to: pt(36, 72)); p.closeSubpath() }, with: .color(C(0xE8321E)))
        g.fill(P { p in p.move(to: pt(66, 52)); p.addLine(to: pt(84, 78)); p.addLine(to: pt(64, 72)); p.closeSubpath() }, with: .color(C(0xE8321E)))
        let body = P { p in
            p.move(to: pt(50, 4)); p.addCurve(to: pt(66, 74), control1: pt(72, 22), control2: pt(74, 52)); p.addLine(to: pt(34, 74))
            p.addCurve(to: pt(50, 4), control1: pt(26, 52), control2: pt(28, 22)); p.closeSubpath()
        }
        g.fill(body, with: vg(4, 74, [0xFFFFFF, 0xD8E1F0]))
        let nose = P { p in
            p.move(to: pt(50, 4)); p.addCurve(to: pt(68, 28), control1: pt(60, 12), control2: pt(66, 20)); p.addLine(to: pt(32, 28))
            p.addCurve(to: pt(50, 4), control1: pt(34, 20), control2: pt(40, 12)); p.closeSubpath()
        }
        g.fill(nose, with: .color(C(0xE8321E)))
        g.fill(Path(ellipseIn: CGRect(x: 41, y: 37, width: 18, height: 18)), with: .color(C(0x3A86FF)))
        g.fill(Path(ellipseIn: CGRect(x: 44, y: 40, width: 6, height: 6)), with: .color(.white.opacity(0.6)))
        g.fill(Path(CGRect(x: 34, y: 70, width: 32, height: 6)), with: .color(C(0x8A94A6)))
    case "crown":
        let g = xf(c, dy: -3 * abs(sn))
        let cr = P { p in
            p.move(to: pt(10, 78)); p.addLine(to: pt(6, 28)); p.addLine(to: pt(30, 52)); p.addLine(to: pt(50, 16)); p.addLine(to: pt(70, 52))
            p.addLine(to: pt(94, 28)); p.addLine(to: pt(90, 78)); p.closeSubpath()
        }
        g.fill(cr, with: vg(16, 78, [0xFFE066, 0xFFB020]))
        g.fill(Path(roundedRect: CGRect(x: 10, y: 78, width: 80, height: 12), cornerRadius: 5), with: .linearGradient(Gradient(colors: [C(0xFFB020), C(0xFFE066), C(0xFFB020)]), startPoint: pt(10, 0), endPoint: pt(90, 0)))
        for (x, y, r, col) in [(50, 66, 5.5, 0xE8321E), (28, 68, 4.5, 0x3A86FF), (72, 68, 4.5, 0x2BD67B), (6, 26, 5.0, 0xFFE066), (94, 26, 5.0, 0xFFE066), (50, 14, 5.5, 0xFFE066)] as [(CGFloat, CGFloat, CGFloat, UInt32)] {
            g.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)), with: .color(C(col)))
        }
        let a = CGFloat(t)
        sparkle(c, 30 + 40 * a, 36, 8, sin(Double.pi * Double(a)))
    case "gem":
        let top = P { p in p.move(to: pt(28, 16)); p.addLine(to: pt(72, 16)); p.addLine(to: pt(94, 40)); p.addLine(to: pt(6, 40)); p.closeSubpath() }
        let bot = P { p in p.move(to: pt(6, 40)); p.addLine(to: pt(94, 40)); p.addLine(to: pt(50, 94)); p.closeSubpath() }
        c.fill(bot, with: vg(40, 94, [0x29B6F6, 0x1565C0])); c.fill(top, with: vg(16, 40, [0x9BE7FF, 0x4FC3F7]))
        let ln = GraphicsContext.Shading.color(.white.opacity(0.7))
        for (a, b) in [(pt(40, 16), pt(28, 40)), (pt(60, 16), pt(72, 40)), (pt(28, 40), pt(50, 94)), (pt(72, 40), pt(50, 94)), (pt(40, 16), pt(50, 40)), (pt(60, 16), pt(50, 40))] {
            c.stroke(P { p in p.move(to: a); p.addLine(to: b) }, with: ln, lineWidth: 1.8)
        }
        let a = CGFloat((t * 3).truncatingRemainder(dividingBy: 1))
        sparkle(c, 24 + 52 * a, 24 + 8 * a, 11, sin(Double.pi * Double(a)))
    case "bolt":
        let glow = 0.5 + 0.5 * Double(max(0, sn))
        c.fill(Path(ellipseIn: CGRect(x: 6, y: 6, width: 88, height: 88)), with: .color(C(0xFFE066).opacity(0.25 * glow)))
        let s = 1 + 0.04 * CGFloat(glow)
        let g = xf(c, sx: s, sy: s, at: pt(50, 50))
        let b = P { p in
            p.move(to: pt(60, 2)); p.addLine(to: pt(18, 56)); p.addLine(to: pt(44, 56)); p.addLine(to: pt(34, 98)); p.addLine(to: pt(82, 38))
            p.addLine(to: pt(54, 38)); p.addLine(to: pt(70, 2)); p.closeSubpath()
        }
        g.fill(b, with: vg(2, 98, [0xFFF176, 0xFFC107, 0xFF9800]))
    case "ghost":
        let g = xf(c, dy: 4 * sn)
        let gh = P { p in
            p.move(to: pt(16, 94)); p.addLine(to: pt(16, 46)); p.addCurve(to: pt(50, 6), control1: pt(16, 20), control2: pt(32, 6))
            p.addCurve(to: pt(84, 46), control1: pt(68, 6), control2: pt(84, 20)); p.addLine(to: pt(84, 94))
            p.addLine(to: pt(72, 84)); p.addLine(to: pt(61, 94)); p.addLine(to: pt(50, 84)); p.addLine(to: pt(39, 94)); p.addLine(to: pt(28, 84)); p.closeSubpath()
        }
        g.fill(gh, with: vg(6, 94, [0xFFFFFF, 0xC9D6F2]))
        g.fill(Path(ellipseIn: CGRect(x: 33, y: 36, width: 11, height: 15)), with: .color(C(0x2A2F4A)))
        g.fill(Path(ellipseIn: CGRect(x: 56, y: 36, width: 11, height: 15)), with: .color(C(0x2A2F4A)))
        g.fill(Path(ellipseIn: CGRect(x: 44, y: 60, width: 12, height: 9 + 3 * sn)), with: .color(C(0x2A2F4A)))
    case "sun":
        for i in 0..<8 {
            let g = xf(c, rot: 360 * t + Double(i) * 45, at: pt(50, 50))
            g.stroke(P { p in p.move(to: pt(50, 6)); p.addLine(to: pt(50, 20)) }, with: .color(C(0xFFB020)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
        let s = 1 + 0.05 * sn
        let g = xf(c, sx: s, sy: s, at: pt(50, 50))
        g.fill(Path(ellipseIn: CGRect(x: 23, y: 23, width: 54, height: 54)), with: .radialGradient(Gradient(colors: [C(0xFFF176), C(0xFFA000)]), center: pt(44, 44), startRadius: 0, endRadius: 34))
    case "moon":
        let g = xf(c, rot: Double(7 * sn), at: pt(50, 50))
        let m = P { p in
            p.move(to: pt(64, 6)); p.addCurve(to: pt(14, 62), control1: pt(32, 8), control2: pt(10, 34)); p.addCurve(to: pt(82, 84), control1: pt(18, 88), control2: pt(50, 100))
            p.addCurve(to: pt(64, 6), control1: pt(52, 78), control2: pt(40, 40)); p.closeSubpath()
        }
        g.fill(m, with: dg([0xFFF3B0, 0xFFC94D]))
        let tw = 0.5 + 0.5 * Double(sn)
        sparkle(c, 78, 26, CGFloat(6 + 6 * tw), 0.4 + 0.6 * tw); sparkle(c, 88, 60, CGFloat(4 + 3 * (1 - tw)), 0.3 + 0.6 * (1 - tw))
    case "clover":
        let g = xf(c, rot: Double(14 * sn), at: pt(50, 50))
        g.stroke(P { p in p.move(to: pt(50, 50)); p.addCurve(to: pt(70, 94), control1: pt(54, 72), control2: pt(60, 84)) }, with: .color(C(0x1E8E4E)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        let leaf = P { p in
            p.move(to: pt(50, 50)); p.addCurve(to: pt(37, 10), control1: pt(28, 36), control2: pt(24, 16)); p.addCurve(to: pt(50, 20), control1: pt(44, 7), control2: pt(49, 13))
            p.addCurve(to: pt(63, 10), control1: pt(51, 13), control2: pt(56, 7)); p.addCurve(to: pt(50, 50), control1: pt(76, 16), control2: pt(72, 36)); p.closeSubpath()
        }
        for i in 0..<4 { xf(g, rot: Double(i) * 90 + 45, at: pt(50, 50)).fill(leaf, with: vg(8, 50, [0x7BE495, 0x1FA85A])) }
    case "note":
        let s = 1 + 0.05 * abs(cs)
        let g = xf(c, rot: Double(9 * sn), sx: s, sy: s, at: pt(50, 80))
        let sh = dg([0xB66CFF, 0xFF5BB8])
        g.fill(P { p in
            p.move(to: pt(52, 14)); p.addCurve(to: pt(80, 58), control1: pt(60, 34), control2: pt(84, 34)); p.addCurve(to: pt(52, 40), control1: pt(72, 44), control2: pt(58, 46)); p.closeSubpath()
        }, with: sh)
        g.fill(Path(roundedRect: CGRect(x: 46, y: 14, width: 8, height: 64), cornerRadius: 3), with: sh)
        xf(g, rot: -20, at: pt(32, 78)).fill(Path(ellipseIn: CGRect(x: 14, y: 66, width: 36, height: 26)), with: sh)
    default:
        c.fill(starPath(50, 54, 46, 0.48), with: vg(8, 98, [0xFFE066, 0xFFB020]))
    }
}

struct DrawnStatusView: View {
    let key: String
    var size: CGFloat = 20
    var body: some View {
        TimelineView(.animation) { tl in
            let t = (tl.date.timeIntervalSinceReferenceDate / 2.4).truncatingRemainder(dividingBy: 1)
            Canvas { ctx, sz in
                var g = ctx
                let s = min(sz.width, sz.height) / 100
                g.scaleBy(x: s, y: s)
                drawIcon(g, key, t)
            }
        }
        .frame(width: size, height: size)
    }
}

private let star3D: [CGPoint] = {
    var pts: [CGPoint] = (0..<10).map { i in
        let r: CGFloat = i % 2 == 0 ? 1 : 0.58
        let a = -Double.pi / 2 + Double(i) * Double.pi / 5
        return CGPoint(x: r * CGFloat(cos(a)), y: r * CGFloat(sin(a)))
    }
    for _ in 0..<3 {
        var out: [CGPoint] = []
        for i in 0..<pts.count {
            let p0 = pts[i], p1 = pts[(i + 1) % pts.count]
            out.append(CGPoint(x: 0.75 * p0.x + 0.25 * p1.x, y: 0.75 * p0.y + 0.25 * p1.y))
            out.append(CGPoint(x: 0.25 * p0.x + 0.75 * p1.x, y: 0.25 * p0.y + 0.75 * p1.y))
        }
        pts = out
    }
    return pts
}()

private func lerp3(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> (Double, Double, Double) {
    (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
}

private func mixC(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> Color {
    Color(red: a.0 + (b.0 - a.0) * t, green: a.1 + (b.1 - a.1) * t, blue: a.2 + (b.2 - a.2) * t)
}

/// Объёмная звезда: призма с толщиной, боковые грани освещены, вращается вокруг вертикальной оси
private func draw3dStar(_ c: GraphicsContext, deg: Double, tiltDeg: Double, pulse: Double) {
    let th = deg * Double.pi / 180, cs = CGFloat(cos(th)), sn = CGFloat(sin(th))
    let tl = tiltDeg * Double.pi / 180, ct = CGFloat(cos(tl)), st = CGFloat(sin(tl))
    let R: CGFloat = 36 * CGFloat(0.97 + 0.03 * pulse)
    let D: CGFloat = 0.2
    func proj(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> (CGPoint, CGFloat) {
        let x1 = x * cs + z * sn
        let z1 = -x * sn + z * cs
        let y2 = y * ct - z1 * st
        let z2 = y * st + z1 * ct
        let k = 1 / (1 - z2 * 0.28)
        return (CGPoint(x: 50 + x1 * R * k, y: 53 + y2 * R * k), z2)
    }
    let pts = star3D, n = pts.count
    var area: CGFloat = 0
    for i in 0..<n { let a = pts[i], b = pts[(i + 1) % n]; area += a.x * b.y - b.x * a.y }
    let sgn: CGFloat = area > 0 ? 1 : -1
    c.fill(Path(ellipseIn: CGRect(x: 26, y: 90, width: 48, height: 6)), with: .color(C(0x6C4DFF).opacity(0.16)))
    let c1 = (0.357, 0.549, 1.0), c2 = (0.627, 0.4, 1.0), c3 = (1.0, 0.42, 0.796), dark = (0.169, 0.114, 0.478)
    var sides: [(Path, Color, CGFloat)] = []
    for i in 0..<n {
        let a = pts[i], b = pts[(i + 1) % n]
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(1e-5, (dx * dx + dy * dy).squareRoot())
        let nx = sgn * dy / len, ny = -sgn * dx / len
        let z1 = -nx * sn
        let nz = ny * st + z1 * ct
        if nz <= 0 { continue }
        let pa = proj(a.x, a.y, D), pb = proj(b.x, b.y, D), qa = proj(a.x, a.y, -D), qb = proj(b.x, b.y, -D)
        var path = Path()
        path.move(to: pa.0); path.addLine(to: pb.0); path.addLine(to: qb.0); path.addLine(to: qa.0); path.closeSubpath()
        let t = Double(i) / Double(n)
        let base = t < 0.5 ? lerp3(c2, c3, t * 2) : lerp3(c3, c1, (t - 0.5) * 2)
        let light = min(1, max(0, 0.45 + 0.55 * Double(nz)))
        sides.append((path, mixC(dark, base, light), (pa.1 + qa.1) / 2))
    }
    for sd in sides.sorted(by: { $0.2 < $1.2 }) {
        c.fill(sd.0, with: .color(sd.1))
        c.stroke(sd.0, with: .color(sd.1), lineWidth: 0.6)
    }
    let front = cs * ct > 0
    let zf: CGFloat = front ? D : -D
    var face = Path(), inner = Path()
    for i in 0..<n {
        let q = proj(pts[i].x, pts[i].y, zf).0
        let w = proj(pts[i].x * 0.7, pts[i].y * 0.7, zf + (front ? 0.05 : -0.05)).0
        if i == 0 { face.move(to: q); inner.move(to: w) } else { face.addLine(to: q); inner.addLine(to: w) }
    }
    face.closeSubpath(); inner.closeSubpath()
    let g1 = proj(-1, -1, zf).0, g2 = proj(1, 1, zf).0
    c.fill(face, with: .linearGradient(Gradient(colors: [C(0x5B8CFF), C(0xA066FF), C(0xFF6BCB)]), startPoint: g1, endPoint: g2))
    c.stroke(face, with: .color(.white.opacity(0.35)), lineWidth: 0.8)
    c.fill(inner, with: .linearGradient(Gradient(colors: [.white.opacity(0.32), .white.opacity(0.04)]), startPoint: g1, endPoint: g2))
    let hi = proj(-0.35 + 0.5 * sn, -0.45, zf).0
    c.fill(Path(ellipseIn: CGRect(x: hi.x - 15, y: hi.y - 15, width: 30, height: 30)),
           with: .radialGradient(Gradient(colors: [.white.opacity(0.55), .clear]), center: hi, startRadius: 0, endRadius: 15))
}

/// Вращающаяся объёмная звезда Premium
struct PremiumStarView: View {
    var size: CGFloat = 110
    var body: some View {
        TimelineView(.animation) { tl in
            let now = tl.date.timeIntervalSinceReferenceDate
            let ph = (now / 4.2).truncatingRemainder(dividingBy: 1)
            let eased = ph * ph * (3 - 2 * ph)
            let tilt = 14 * sin(now * 2 * Double.pi / 5.2)
            let pulse = 0.5 + 0.5 * sin(now * 3.5)
            Canvas { ctx, sz in
                var g = ctx
                let s = min(sz.width, sz.height) / 100
                g.scaleBy(x: s, y: s)
                draw3dStar(g, deg: eased * 360, tiltDeg: tilt, pulse: pulse)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Звезда Premium, от которой разлетаются маленькие звёздочки
struct StarEmitterView: View {
    var size: CGFloat = 110
    var body: some View {
        ZStack {
            TimelineView(.animation) { tl in
                let t = (tl.date.timeIntervalSinceReferenceDate / 3.6).truncatingRemainder(dividingBy: 1)
                Canvas { ctx, sz in
                    let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
                    let n = 16
                    for i in 0..<n {
                        let ph = (t + Double(i) / Double(n)).truncatingRemainder(dividingBy: 1)
                        let ang = Double(i) * 137.5 * .pi / 180
                        let dist = size * CGFloat(0.38 + 0.9 * ph) + CGFloat(i % 3) * 6
                        let x = c.x + CGFloat(cos(ang)) * dist
                        let y = c.y + CGFloat(sin(ang)) * dist - CGFloat(ph) * size * 0.1
                        let a = (1 - ph) * (ph < 0.08 ? ph / 0.08 : 1)
                        let r = CGFloat(4 + Double(i % 4) * 2.2) * CGFloat(1 - 0.5 * ph)
                        let col = i % 2 == 0 ? Color(hex: 0xffd36b) : Color(hex: 0xb69cff)
                        var path = Path()
                        for k in 0..<10 {
                            let rr = k % 2 == 0 ? r : r * 0.45
                            let aa = (Double(k) * 36 - 90) * .pi / 180 + ph * 3.8 + Double(i) * 0.35
                            let p = CGPoint(x: x + CGFloat(cos(aa)) * rr, y: y + CGFloat(sin(aa)) * rr)
                            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
                        }
                        path.closeSubpath()
                        ctx.fill(path, with: .color(col.opacity(max(0, a))))
                    }
                }
            }
            PremiumStarView(size: size)
        }
        .frame(width: size * 2.4, height: size * 1.4)
    }
}

/// Поле мерцающих искр в шапке Premium
struct SparkleFieldView: View {
    private let pts: [(CGFloat, CGFloat, CGFloat, Double)] = {
        var seed: UInt64 = 7
        func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double((seed >> 33) % 10000) / 10000 }
        return (0..<46).map { _ in (CGFloat(rnd()), CGFloat(rnd()), CGFloat(3 + rnd() * 6), rnd()) }
    }()
    var body: some View {
        TimelineView(.animation) { tl in
            let t = (tl.date.timeIntervalSinceReferenceDate / 3.2).truncatingRemainder(dividingBy: 1)
            Canvas { ctx, sz in
                for q in pts {
                    let ph = (t + q.3).truncatingRemainder(dividingBy: 1)
                    let a = min(1, 0.25 + 0.75 * sin(Double.pi * ph))
                    let x = q.0 * sz.width, y = q.1 * sz.height
                    let r = q.2 * CGFloat(0.7 + 0.5 * a)
                    let col = q.3 > 0.5 ? C(0x9B6BFF) : C(0x6C8CFF)
                    var p = Path()
                    p.move(to: pt(x - r, y)); p.addLine(to: pt(x + r, y)); p.move(to: pt(x, y - r)); p.addLine(to: pt(x, y + r))
                    ctx.stroke(p, with: .color(col.opacity(a * 0.8)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
