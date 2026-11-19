import SwiftUI

/// Временная тема «Vice Nights» (до 1 декабря): закат над океаном, неон, пальмы.
/// Основные формы и «жидкое стекло» Lumo остаются — тема только добавляет краски.
/// Включает и выключает сервер (look.event), пользователь может отключить её в «Оформлении».
enum Vice {
    static let pink = Color(hex: 0xff4f8b), orange = Color(hex: 0xff8a3d), sun = Color(hex: 0xffd36b)
    static let teal = Color(hex: 0x2fd6d0), night = Color(hex: 0x140a2e), violet = Color(hex: 0x7b3ff2)
    static let outGrad = LinearGradient(colors: [Color(hex: 0xff4f8b), Color(hex: 0xff8a3d)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let offKey = "vice_off"

    /// тема идёт на сервере (срок не вышел)
    static var available: Bool { RemoteConfig.shared.eventTheme == "vice" }
    static var on: Bool { available && !UserDefaults.standard.bool(forKey: offKey) }
}

/// Наблюдатель для перерисовки при включении/выключении темы
final class ViceState: ObservableObject {
    static let shared = ViceState()
    @Published var off: Bool = UserDefaults.standard.bool(forKey: Vice.offKey) { didSet { UserDefaults.standard.set(off, forKey: Vice.offKey) } }
    @MainActor var on: Bool { Vice.available && !off }
}

/// Небо на закате за шапкой списка чатов: градиент, солнце, город и пальмы, плавно уходит в фон
struct ViceSky: View {
    var height: CGFloat = 250
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { tl in
            Canvas { ctx, size in ViceSky.draw(&ctx, size, tl.date.timeIntervalSinceReferenceDate) }
        }
        .frame(height: height)
        .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.7), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func draw(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
                let w = size.width, h = size.height
                // небо
                ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .linearGradient(
                    Gradient(stops: [.init(color: Color(hex: 0x2a0f52), location: 0), .init(color: Color(hex: 0x8a2c8f), location: 0.38),
                                     .init(color: Color(hex: 0xff4f8b), location: 0.66), .init(color: Color(hex: 0xff9a3d), location: 0.86),
                                     .init(color: Color(hex: 0xffd36b), location: 1)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
                // солнце с полосами, медленно «дышит»
                let r: CGFloat = w * 0.2 * (1 + 0.015 * CGFloat(sin(t * 0.8)))
                let cx: CGFloat = w / 2, cy: CGFloat = h * 0.78
                var sunCtx = ctx
                sunCtx.clip(to: Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)))
                sunCtx.fill(Path(CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .linearGradient(
                    Gradient(colors: [Color(hex: 0xffe58a), Color(hex: 0xff8a3d)]), startPoint: CGPoint(x: cx, y: cy - r), endPoint: CGPoint(x: cx, y: cy + r)))
                for i in 0..<5 {
                    let y = cy + r * (0.15 + CGFloat(i) * 0.18)
                    sunCtx.fill(Path(CGRect(x: cx - r, y: y, width: r * 2, height: 2 + CGFloat(i))), with: .color(Color(hex: 0xff4f8b).opacity(0.85)))
                }
                // город
                var city = Path()
                city.move(to: CGPoint(x: 0, y: h))
                let blocks: [(CGFloat, CGFloat)] = [(0, 0.16), (0.07, 0.24), (0.12, 0.13), (0.18, 0.34), (0.22, 0.18), (0.3, 0.12), (0.62, 0.15), (0.66, 0.32), (0.69, 0.4), (0.72, 0.28), (0.78, 0.14), (0.85, 0.22), (0.9, 0.11), (1, 0.11)]
                for (i, b) in blocks.enumerated() {
                    let x = w * b.0, top = h - h * b.1
                    city.addLine(to: CGPoint(x: x, y: i == 0 ? top : city.currentPoint!.y))
                    city.addLine(to: CGPoint(x: x, y: top))
                }
                city.addLine(to: CGPoint(x: w, y: h)); city.closeSubpath()
                ctx.fill(city, with: .color(Color(hex: 0x1a0b33)))
                // пальмы, листья чуть покачиваются
                func palm(_ x: CGFloat, _ base: CGFloat, _ top: CGFloat, _ lean: CGFloat, _ ph: Double) {
                    var trunk = Path()
                    trunk.move(to: CGPoint(x: x, y: base))
                    let tip = CGPoint(x: x + lean, y: top)
                    trunk.addQuadCurve(to: tip, control: CGPoint(x: x + lean * 0.2, y: (base + top) / 2))
                    ctx.stroke(trunk, with: .color(Color(hex: 0x120826)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    let sway = CGFloat(sin(t * 1.3 + ph)) * 3
                    for a: CGFloat in [-160, -125, -95, -60, -25, 10] {
                        let rad: CGFloat = a * .pi / 180, len: CGFloat = 40
                        let end = CGPoint(x: tip.x + cos(rad) * len + sway, y: tip.y + sin(rad) * len * 0.55 + 14)
                        var leaf = Path(); leaf.move(to: tip)
                        leaf.addQuadCurve(to: end, control: CGPoint(x: tip.x + cos(rad) * len * 0.6 + sway, y: tip.y + sin(rad) * len * 0.6 - 6))
                        ctx.stroke(leaf, with: .color(Color(hex: 0x120826)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                    }
                }
                palm(w * 0.1, h, h * 0.36, 10, 0)
                palm(w * 0.88, h, h * 0.46, -12, 1.7)
    }
}

/// Ночная сцена для фона переписки: градиент, неоновая сетка и пальма
struct ViceNightWall: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x1a0b3a), Color(hex: 0x2b0f4f), Color(hex: 0x4a1559), Color(hex: 0x6b1d55)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            // перспективная сетка внизу
            let horizon = h * 0.62
            for i in 0..<9 {
                let k = CGFloat(i) / 8, y = horizon + (h - horizon) * k * k
                var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: w, y: y))
                ctx.stroke(l, with: .color(Color(hex: 0x2fd6d0).opacity(0.18)), lineWidth: 1)
            }
            for i in -6...6 {
                var l = Path(); l.move(to: CGPoint(x: w / 2 + CGFloat(i) * 14, y: horizon)); l.addLine(to: CGPoint(x: w / 2 + CGFloat(i) * w * 0.28, y: h))
                ctx.stroke(l, with: .color(Color(hex: 0xff4f8b).opacity(0.16)), lineWidth: 1)
            }
            // пальма
            let x = w * 0.78, base = horizon, top = h * 0.3
            var trunk = Path(); trunk.move(to: CGPoint(x: x, y: base)); trunk.addQuadCurve(to: CGPoint(x: x - 14, y: top), control: CGPoint(x: x, y: (base + top) / 2))
            ctx.stroke(trunk, with: .color(Color(hex: 0xff9a3d).opacity(0.18)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            for a: CGFloat in [-165, -130, -95, -60, -20, 15] {
                let rad: CGFloat = a * .pi / 180, tip = CGPoint(x: x - 14, y: top)
                var leaf = Path(); leaf.move(to: tip)
                leaf.addQuadCurve(to: CGPoint(x: tip.x + cos(rad) * 70, y: tip.y + sin(rad) * 38 + 22), control: CGPoint(x: tip.x + cos(rad) * 42, y: tip.y + sin(rad) * 42 - 8))
                ctx.stroke(leaf, with: .color(Color(hex: 0xff9a3d).opacity(0.18)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

extension Text {
    /// Заголовок в стиле темы: узкий жирный капслок с неоновым свечением
    func viceTitle(_ size: CGFloat) -> some View {
        self.font(.system(size: size, weight: .black).width(.condensed))
            .foregroundColor(.white)
            .shadow(color: Color(hex: 0xff4f8b).opacity(0.8), radius: 8)
            .shadow(color: Color(hex: 0x2a0f52), radius: 0, x: 0, y: 2)
    }
}

/// Плашка-«стикер» как на загрузочных экранах: жёлтая, с чёрной обводкой и тенью, чуть наклонена
struct VicePlaque: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12.5, weight: .black).width(.condensed)).tracking(0.8)
            .foregroundColor(Color(hex: 0x140a2e))
            .padding(.horizontal, 11).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color(hex: 0x0c0620)).offset(x: 2.5, y: 2.5))
            .background(RoundedRectangle(cornerRadius: 7).fill(Vice.sun))
            .rotationEffect(.degrees(-2))
    }
}

// MARK: - Вступление при запуске: комикс-панели, LUMO и плашка VICE NIGHTS

struct ViceIntro: View {
    var onDone: () -> Void
    @State private var p1 = false, p2 = false, p3 = false, logo = false, stamp = false, flash = false, out = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Color(hex: 0x140a2e)
                panel { ViceSky(height: h * 0.46).frame(maxHeight: .infinity, alignment: .bottom) }
                    .frame(width: w * 0.68, height: h * 0.46)
                    .rotationEffect(.degrees(p1 ? -4 : -12))
                    .offset(x: p1 ? -w * 0.2 : -w * 0.6, y: p1 ? -h * 0.28 : -h * 0.4)
                    .opacity(p1 ? 1 : 0)
                panel { VicePalmArt() }
                    .frame(width: w * 0.56, height: h * 0.44)
                    .rotationEffect(.degrees(p2 ? 5 : 14))
                    .offset(x: p2 ? w * 0.26 : w * 0.8, y: p2 ? -h * 0.02 : 0)
                    .opacity(p2 ? 1 : 0)
                panel { ViceNightWall() }
                    .frame(width: w * 0.76, height: h * 0.4)
                    .rotationEffect(.degrees(p3 ? 3 : -6))
                    .offset(x: p3 ? -w * 0.16 : -w * 0.4, y: p3 ? h * 0.33 : h * 0.6)
                    .opacity(p3 ? 1 : 0)
                VStack(spacing: 14) {
                    Text("LUMO")
                        .font(.system(size: min(w * 0.3, 150), weight: .black).width(.condensed))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: 0xffe58a), Color(hex: 0xffb347), Color(hex: 0xff4f8b)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: Color(hex: 0x140a2e), radius: 0, x: 3, y: 3)
                        .shadow(color: Color(hex: 0x140a2e), radius: 0, x: 7, y: 7)
                        .shadow(color: Color(hex: 0xff4f8b).opacity(0.6), radius: 24)
                        .rotationEffect(.degrees(logo ? -4 : -10))
                        .scaleEffect(logo ? 1 : 2.6)
                        .opacity(logo ? 1 : 0)
                    VicePlaque(text: "Vice Nights")
                        .scaleEffect(stamp ? 1.5 : 2.4)
                        .rotationEffect(.degrees(stamp ? 5 : 12))
                        .opacity(stamp ? 1 : 0)
                }
                Color.white.opacity(flash ? 0.85 : 0).allowsHitTesting(false)
            }
            .frame(width: w, height: h)
            .mask(Rectangle().offset(x: out ? w * 1.1 : 0))
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.05)) { p1 = true }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.2)) { p2 = true }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.35)) { p3 = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                flash = true
                withAnimation(.easeOut(duration: 0.35)) { flash = false }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { logo = true }
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(1.0)) { stamp = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) { finish() }
        }
    }

    private func finish() {
        guard !out else { return }
        withAnimation(.easeInOut(duration: 0.5)) { out = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { onDone() }
    }

    private func panel<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c().clipped()
            .overlay(Rectangle().stroke(Color(hex: 0x0c0620), lineWidth: 4))
            .padding(5).background(Color.white)
            .shadow(color: .black.opacity(0.35), radius: 0, x: 10, y: 10)
    }
}

/// Неоновые пальмы для вступления
struct VicePalmArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x0f0828)))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.12, width: w * 0.36, height: w * 0.36)), with: .color(Color(hex: 0xff4f8b).opacity(0.18)))
            func palm(_ x: CGFloat, _ top: CGFloat, _ c: Color, _ lw: CGFloat, _ len: CGFloat) {
                var t = Path(); t.move(to: CGPoint(x: x, y: h)); t.addQuadCurve(to: CGPoint(x: x + 22, y: top), control: CGPoint(x: x + 4, y: (h + top) / 2))
                ctx.stroke(t, with: .color(c), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                let tip = CGPoint(x: x + 22, y: top)
                for a: CGFloat in [-160, -125, -95, -60, -25, 10] {
                    let r: CGFloat = a * .pi / 180
                    var l = Path(); l.move(to: tip)
                    l.addQuadCurve(to: CGPoint(x: tip.x + cos(r) * len, y: tip.y + sin(r) * len * 0.55 + len * 0.3),
                                   control: CGPoint(x: tip.x + cos(r) * len * 0.6, y: tip.y + sin(r) * len * 0.6 - 8))
                    ctx.stroke(l, with: .color(c), style: StrokeStyle(lineWidth: lw * 0.85, lineCap: .round))
                }
            }
            palm(w * 0.5, h * 0.36, Color(hex: 0xff4f8b), 6, w * 0.3)
            palm(w * 0.2, h * 0.62, Color(hex: 0x2fd6d0).opacity(0.85), 5, w * 0.2)
        }
    }
}

/// Звёзды «уровня розыска» — сколько чатов с непрочитанными (до пяти)
struct ViceStars: View {
    let n: Int
    @State private var pulse = false
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "star.fill").font(.system(size: 11, weight: .bold))
                    .foregroundColor(i < n ? Vice.sun : Color.white.opacity(0.3))
                    .shadow(color: i < n ? Vice.sun.opacity(0.9) : .clear, radius: 3)
                    .scaleEffect(i < n && pulse ? 1.15 : 1)
                    .animation(.easeInOut(duration: 0.7).repeatForever().delay(Double(i) * 0.12), value: pulse)
            }
        }
        .onAppear { pulse = true }
        .accessibilityLabel("Чатов с непрочитанными: \(n)")
    }
}

/// Закат с океаном для входящего звонка
struct ViceCallSunset: View {
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .top) {
                ViceNightWall()
                ViceSky(height: g.size.height * 0.82)
            }
        }
        .ignoresSafeArea()
    }
}
