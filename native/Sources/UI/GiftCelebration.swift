import SwiftUI

private func giftGlow(_ id: String) -> Color {
    switch id {
    case "pearl": return Color(hex: 0x35d6e8); case "comet": return Color(hex: 0xff8a3d); case "crystal": return Color(hex: 0x7d8dff)
    case "key": return Color(hex: 0xffc247); case "flower": return Color(hex: 0xc066ff); default: return Color(hex: 0xb069ff)
    }
}

private struct Spark { let a: Double; let r: Double; let s: Double; let d: Double }
private struct Conf { let x: Double; let v: Double; let w: Double; let ph: Double; let c: Int; let sz: Double }

/// Магическая анимация после покупки/подарка: сбор света → вспышка → лучи, конфетти, искры, название и плашка
struct GiftCelebration: View {
    let giftId: String
    let to: String?
    let name: String
    let serial: Int
    let supply: Int
    let onClose: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var start = Date()
    private let sparks: [Spark] = (0..<70).map { _ in Spark(a: .random(in: 0..<6.283), r: .random(in: 0.55...1.05), s: .random(in: 1.5...5), d: .random(in: 0...1)) }
    private let conf: [Conf] = (0..<60).map { _ in Conf(x: .random(in: 0...1), v: .random(in: 0.25...0.75), w: .random(in: 0.4...1.4), ph: .random(in: 0..<6.28), c: .random(in: 0..<4), sz: .random(in: 5...12)) }
    private var gifting: Bool { to != nil }
    private var total: Double { gifting ? 6.2 : 5.6 }
    private let reveal = 1.4
    private var fly: Double { gifting ? 3.0 : 99 }
    private var glow: Color { giftGlow(giftId) }

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                let c = CGPoint(x: w / 2, y: h * 0.40)
                ZStack {
                    Color(hex: 0x05060f).ignoresSafeArea()
                    RadialGradient(colors: [glow.opacity(0.28), Color(hex: 0x05060f).opacity(0.96)], center: .center, startRadius: 0, endRadius: max(w, h) * 0.8).ignoresSafeArea()
                    Canvas { g, size in draw(g, size, c, t) }.allowsHitTesting(false)
                    if t >= reveal * 0.7 { giftView(t, w) .position(x: c.x, y: 150 + 130) }
                    if t >= reveal + 0.5 { caption(t).position(x: w / 2, y: min(h - 120, 150 + 260 + 80)) }
                }
                .frame(width: w, height: h)
            }
            .onChange(of: t > total) { if $0 { onClose() } }
        }
        .background(Color.black.opacity(0.01))
        .ignoresSafeArea()
        .onTapGesture { onClose() }
        .onAppear { start = Date() }
    }

    private func giftView(_ t: Double, _ w: CGFloat) -> some View {
        let a = t - reveal * 0.7
        let appear = min(1, max(0, a / 1.1))
        let fk = gifting ? min(1, max(0, (t - fly) / 0.9)) : 0
        let ease = fk * fk
        let sc = (0.2 + 0.8 * (1 - pow(1 - appear, 3))) * (1 - 0.8 * ease)
        return GiftAnimated(id: giftId)
            .frame(width: 250, height: 250)
            .scaleEffect(sc)
            .rotation3DEffect(.degrees((1 - appear) * 540), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .offset(y: -ease * 520)
            .opacity(appear * (fk >= 1 ? 0 : 1))
            .allowsHitTesting(false)
    }

    private func caption(_ t: Double) -> some View {
        let a = t - reveal - 0.5
        let outA = gifting && t > fly + 2.4 ? min(1, max(0, 1 - (t - fly - 2.4) / 0.5)) : 1
        let pk = min(1, max(0, (a - 0.6) / 0.5))
        let chars = Array(name)
        return VStack(spacing: 8) {
            Text(gifting ? "Подарок отправлен" : "Ваш подарок").font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.75))
            HStack(spacing: 0) {
                ForEach(Array(chars.enumerated()), id: \.offset) { i, ch in
                    let k = min(1, max(0, (a - Double(i) * 0.06) / 0.5))
                    Text(String(ch)).font(.system(size: 32, weight: .black)).foregroundColor(.white)
                        .opacity(k).blur(radius: (1 - k) * 8).offset(y: (1 - k) * 18)
                }
            }
            Text("№\(serial) из \(supply)").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                .padding(.horizontal, 18).padding(.vertical, 8)
                .background(glow.opacity(0.28), in: Capsule())
                .scaleEffect(0.8 + 0.2 * pk).opacity(pk)
            if let to = to {
                Text("Получатель: \(model.displayName(to))").font(.system(size: 15)).foregroundColor(.white.opacity(0.8 * pk))
            }
        }
        .opacity(outA)
        .allowsHitTesting(false)
    }

    private func draw(_ g: GraphicsContext, _ size: CGSize, _ c: CGPoint, _ t: Double) {
        var g = g
        let m = min(size.width, size.height)
        func dot(_ p: CGPoint, _ r: CGFloat, _ col: Color) { g.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(col)) }
        if t < reveal {
            let k = t / reveal
            for s in sparks {
                let rr = m * 0.55 * s.r * pow(1 - k, 1.6)
                let ang = s.a + k * 5 * (1 + s.d)
                dot(CGPoint(x: c.x + cos(ang) * rr, y: c.y + sin(ang) * rr), s.s, glow.opacity(min(1, 0.2 + 0.8 * k)))
            }
            dot(c, m * 0.2 * (0.3 + 0.7 * k), glow.opacity(0.5 * k))
            dot(c, m * 0.06 * (0.3 + 0.7 * k), .white.opacity(k))
            return
        }
        let a = t - reveal
        let fl = max(0, 1 - a / 0.6)
        if fl > 0 { g.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(fl * 0.85))) }
        for i in 0..<2 {
            let w = min(1, max(0, (a - Double(i) * 0.18) / 1.3))
            if w > 0.001 && w < 0.999 {
                let r = m * (0.1 + 0.85 * w)
                g.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(glow.opacity((1 - w) * 0.8)), lineWidth: 6 * (1 - w) + 1)
            }
        }
        var ra = min(1, a / 0.8)
        if t > fly + 0.8 { ra *= max(0, 1 - (t - fly - 0.8) / 1.2) }
        for i in 0..<14 {
            let ang = Double(i) * 2 * .pi / 14 + a * 0.3
            let len = m * (0.55 + 0.1 * sin(a * 2 + Double(i)))
            var p = Path(); p.move(to: c); p.addLine(to: CGPoint(x: c.x + cos(ang) * len, y: c.y + sin(ang) * len))
            g.stroke(p, with: .linearGradient(Gradient(colors: [glow.opacity(0.35 * ra), .clear]), startPoint: c, endPoint: CGPoint(x: c.x + cos(ang) * len, y: c.y + sin(ang) * len)), lineWidth: CGFloat(5 + 2 * (i % 3)))
        }
        for (i, s) in sparks.enumerated() where i % 2 == 0 {
            let ang = s.a + a * (0.8 + s.d)
            let rr = m * (0.22 + 0.2 * s.r)
            let al = (0.4 + 0.6 * abs(sin(a * 4 + s.d * 9))) * ra
            let p = CGPoint(x: c.x + cos(ang) * rr, y: c.y + sin(ang) * rr * 0.8)
            dot(p, s.s * 2.2, glow.opacity(al * 0.4)); dot(p, s.s * 0.8, .white.opacity(al))
        }
        if a > 0.15 {
            let cols: [Color] = [glow, .white, Color(hex: 0xffc247), Color(hex: 0xff6fb5)]
            let ca = a - 0.15
            for f in conf {
                let y = c.y - m * 0.15 + ca * f.v * m * 0.55 - 0.18 * m * (1 - min(1, ca * 2))
                if y > size.height + 20 { continue }
                let x = f.x * size.width + sin(ca * 3 * f.w + f.ph) * 28
                var gg = g
                gg.translateBy(x: x, y: y); gg.rotate(by: .degrees(ca * 200 * f.w + f.ph * 50))
                gg.fill(Path(CGRect(x: 0, y: 0, width: f.sz * 0.6, height: f.sz)), with: .color(cols[f.c].opacity(max(0, min(1, 1 - ca / 4.5)))))
            }
        }
        if gifting && t > fly {
            let b = (t - fly - 0.55) / 1.1
            if b >= 0 && b <= 1 {
                for i in 0..<40 {
                    let sp = sparks[i % sparks.count]
                    let ang = Double(i) * 0.157 + sp.d
                    let rr = m * 0.5 * b * (0.5 + sp.d)
                    dot(CGPoint(x: size.width / 2 + cos(ang) * rr, y: size.height * 0.08 + sin(ang) * rr), 4 * (1 - b) + 1, glow.opacity(1 - b))
                }
            }
        }
    }
}
