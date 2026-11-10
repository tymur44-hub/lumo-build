import SwiftUI

// MARK: - Настоящие нарисованные стикеры на тему Хэллоуин (вместо обычных эмодзи)

let stickerIds = ["pumpkin", "ghost", "cat", "candy", "spider", "skull", "bat", "potion"]
let stickerNames: [String: String] = [
    "pumpkin": "Тыква", "ghost": "Привидение", "cat": "Чёрный кот", "candy": "Конфета",
    "spider": "Паук", "skull": "Череп", "bat": "Летучая мышь", "potion": "Зелье",
]

/// Префикс новых стикеров в теле сообщения (старые — просто эмодзи, остаются как есть)
let stickerArtPrefix = "art:"

private func sC(_ h: UInt32) -> Color { Color(hex: h) }
private func sP(_ f: (inout Path) -> Void) -> Path { var p = Path(); f(&p); return p }
private func sPt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

private func drawStickerArt(_ c: GraphicsContext, _ id: String) {
    switch id {
    case "pumpkin":
        c.fill(Path(ellipseIn: CGRect(x: 10, y: 16, width: 80, height: 78)), with: .linearGradient(Gradient(colors: [sC(0xFFA940), sC(0xFF7A00)]), startPoint: sPt(50, 16), endPoint: sPt(50, 94)))
        for x: CGFloat in [30, 50, 70] { c.stroke(sP { p in p.move(to: sPt(x, 22)); p.addLine(to: sPt(x, 86)) }, with: .color(sC(0xE8690A).opacity(0.55)), lineWidth: 2.2) }
        c.fill(sP { p in
            p.move(to: sPt(44, 2)); p.addCurve(to: sPt(51, 11), control1: sPt(54, -2), control2: sPt(58, 6))
            p.addCurve(to: sPt(41, 7), control1: sPt(48, 13), control2: sPt(42, 11)); p.addCurve(to: sPt(44, 2), control1: sPt(40, 4), control2: sPt(42, 2)); p.closeSubpath()
        }, with: .color(sC(0x3A7A3A)))
        c.fill(sP { p in p.move(to: sPt(30, 46)); p.addLine(to: sPt(42, 46)); p.addLine(to: sPt(36, 58)); p.closeSubpath() }, with: .color(sC(0x2A1A08)))
        c.fill(sP { p in p.move(to: sPt(58, 46)); p.addLine(to: sPt(70, 46)); p.addLine(to: sPt(64, 58)); p.closeSubpath() }, with: .color(sC(0x2A1A08)))
        c.fill(sP { p in
            p.move(to: sPt(26, 68)); p.addLine(to: sPt(74, 68)); p.addLine(to: sPt(66, 80)); p.addLine(to: sPt(58, 72)); p.addLine(to: sPt(50, 80))
            p.addLine(to: sPt(42, 72)); p.addLine(to: sPt(34, 80)); p.closeSubpath()
        }, with: .color(sC(0x2A1A08)))
    case "ghost":
        c.fill(sP { p in
            p.move(to: sPt(50, 10)); p.addCurve(to: sPt(14, 46), control1: sPt(28, 10), control2: sPt(14, 26)); p.addLine(to: sPt(14, 92))
            p.addLine(to: sPt(24, 84)); p.addLine(to: sPt(34, 92)); p.addLine(to: sPt(44, 84)); p.addLine(to: sPt(50, 92)); p.addLine(to: sPt(56, 84))
            p.addLine(to: sPt(66, 92)); p.addLine(to: sPt(76, 84)); p.addLine(to: sPt(86, 92)); p.addLine(to: sPt(86, 46)); p.addCurve(to: sPt(50, 10), control1: sPt(86, 26), control2: sPt(72, 10)); p.closeSubpath()
        }, with: .color(sC(0xF4F2FF)))
        c.fill(Path(ellipseIn: CGRect(x: 31, y: 36, width: 12, height: 12)), with: .color(sC(0x2A2240)))
        c.fill(Path(ellipseIn: CGRect(x: 57, y: 36, width: 12, height: 12)), with: .color(sC(0x2A2240)))
        c.fill(Path(ellipseIn: CGRect(x: 28, y: 54, width: 10, height: 12)), with: .color(sC(0xFFB3C6).opacity(0.6)))
        c.fill(Path(ellipseIn: CGRect(x: 62, y: 54, width: 10, height: 12)), with: .color(sC(0xFFB3C6).opacity(0.6)))
        c.stroke(sP { p in p.move(to: sPt(40, 58)); p.addQuadCurve(to: sPt(60, 58), control: sPt(50, 70)) }, with: .color(sC(0x2A2240)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
    case "cat":
        c.fill(sP { p in
            p.move(to: sPt(18, 90)); p.addCurve(to: sPt(30, 40), control1: sPt(18, 66), control2: sPt(24, 50)); p.addLine(to: sPt(22, 14)); p.addLine(to: sPt(42, 32))
            p.addCurve(to: sPt(58, 32), control1: sPt(48, 29), control2: sPt(52, 29)); p.addLine(to: sPt(78, 14)); p.addLine(to: sPt(70, 40))
            p.addCurve(to: sPt(82, 90), control1: sPt(76, 50), control2: sPt(82, 66)); p.closeSubpath()
        }, with: .color(sC(0x1A1A2E)))
        c.fill(Path(ellipseIn: CGRect(x: 33, y: 51, width: 11, height: 11)), with: .color(sC(0xFFD97A)))
        c.fill(Path(ellipseIn: CGRect(x: 57, y: 51, width: 11, height: 11)), with: .color(sC(0xFFD97A)))
        c.fill(sP { p in p.move(to: sPt(50, 62)); p.addLine(to: sPt(45, 70)); p.addLine(to: sPt(55, 70)); p.closeSubpath() }, with: .color(sC(0xFF8FAB)))
        for (a, b) in [(sPt(16, 56), sPt(2, 50)), (sPt(16, 64), sPt(0, 66)), (sPt(84, 56), sPt(98, 50)), (sPt(84, 64), sPt(100, 66))] {
            c.stroke(sP { p in p.move(to: a); p.addLine(to: b) }, with: .color(sC(0x1A1A2E)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
    case "candy":
        c.fill(sP { p in p.move(to: sPt(50, 10)); p.addCurve(to: sPt(74, 62), control1: sPt(66, 32), control2: sPt(74, 48)); p.addLine(to: sPt(26, 62)); p.addCurve(to: sPt(50, 10), control1: sPt(26, 48), control2: sPt(34, 32)); p.closeSubpath() }, with: .color(.white))
        c.fill(sP { p in p.move(to: sPt(26, 62)); p.addLine(to: sPt(74, 62)); p.addCurve(to: sPt(68, 84), control1: sPt(74, 76), control2: sPt(68, 84)); p.addLine(to: sPt(32, 84)); p.addCurve(to: sPt(26, 62), control1: sPt(32, 84), control2: sPt(26, 76)); p.closeSubpath() }, with: .color(sC(0xFFC83D)))
        c.fill(sP { p in p.move(to: sPt(32, 84)); p.addLine(to: sPt(68, 84)); p.addCurve(to: sPt(50, 98), control1: sPt(68, 94), control2: sPt(60, 98)); p.addCurve(to: sPt(32, 84), control1: sPt(40, 98), control2: sPt(32, 94)); p.closeSubpath() }, with: .color(sC(0xFF8A1E)))
        for x: CGFloat in [36, 50, 64] { c.stroke(sP { p in p.move(to: sPt(x, 14)); p.addLine(to: sPt(x, 56)) }, with: .color(sC(0xFFE08A)), style: StrokeStyle(lineWidth: 3, lineCap: .round)) }
    case "spider":
        for (a, b) in [(sPt(36, 38), sPt(6, 20)), (sPt(36, 48), sPt(0, 48)), (sPt(36, 58), sPt(6, 76)),
                       (sPt(64, 38), sPt(94, 20)), (sPt(64, 48), sPt(100, 48)), (sPt(64, 58), sPt(94, 76))] {
            c.stroke(sP { p in p.move(to: a); p.addLine(to: b) }, with: .color(sC(0x1A1A2E)), style: StrokeStyle(lineWidth: 4.2, lineCap: .round))
        }
        c.fill(Path(ellipseIn: CGRect(x: 26, y: 32, width: 48, height: 48)), with: .color(sC(0x1A1A2E)))
        c.fill(Path(ellipseIn: CGRect(x: 35, y: 15, width: 30, height: 30)), with: .color(sC(0x1A1A2E)))
        c.fill(Path(ellipseIn: CGRect(x: 40.8, y: 23.8, width: 6.4, height: 6.4)), with: .color(.white))
        c.fill(Path(ellipseIn: CGRect(x: 52.8, y: 23.8, width: 6.4, height: 6.4)), with: .color(.white))
        c.fill(sP { p in p.move(to: sPt(42, 14)); p.addLine(to: sPt(32, 4)); p.addLine(to: sPt(44, 8)); p.closeSubpath() }, with: .color(sC(0xFF5B7A)))
        c.fill(sP { p in p.move(to: sPt(58, 14)); p.addLine(to: sPt(68, 4)); p.addLine(to: sPt(56, 8)); p.closeSubpath() }, with: .color(sC(0xFF5B7A)))
    case "skull":
        c.fill(sP { p in
            p.move(to: sPt(50, 8)); p.addCurve(to: sPt(10, 48), control1: sPt(24, 8), control2: sPt(10, 28)); p.addCurve(to: sPt(22, 74), control1: sPt(10, 60), control2: sPt(16, 68))
            p.addLine(to: sPt(22, 88)); p.addLine(to: sPt(78, 88)); p.addLine(to: sPt(78, 74)); p.addCurve(to: sPt(90, 48), control1: sPt(84, 68), control2: sPt(90, 60))
            p.addCurve(to: sPt(50, 8), control1: sPt(90, 28), control2: sPt(76, 8)); p.closeSubpath()
        }, with: .color(sC(0xF4F2FF)))
        c.fill(Path(ellipseIn: CGRect(x: 25.5, y: 37.5, width: 17, height: 17)), with: .color(sC(0x2A2240)))
        c.fill(Path(ellipseIn: CGRect(x: 57.5, y: 37.5, width: 17, height: 17)), with: .color(sC(0x2A2240)))
        c.fill(sP { p in p.move(to: sPt(50, 52)); p.addLine(to: sPt(43, 64)); p.addLine(to: sPt(57, 64)); p.closeSubpath() }, with: .color(sC(0x2A2240)))
        c.stroke(sP { p in p.move(to: sPt(32, 76)); p.addLine(to: sPt(68, 76)) }, with: .color(sC(0x2A2240)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
    case "bat":
        c.fill(sP { p in
            p.move(to: sPt(46, 54)); p.addLine(to: sPt(14, 44)); p.addLine(to: sPt(24, 58)); p.addLine(to: sPt(6, 66)); p.addLine(to: sPt(24, 72))
            p.addLine(to: sPt(10, 86)); p.addLine(to: sPt(32, 82)); p.addLine(to: sPt(32, 92)); p.addLine(to: sPt(46, 72)); p.closeSubpath()
        }, with: .color(sC(0x2A2240)))
        c.fill(sP { p in
            p.move(to: sPt(54, 54)); p.addLine(to: sPt(86, 44)); p.addLine(to: sPt(76, 58)); p.addLine(to: sPt(94, 66)); p.addLine(to: sPt(76, 72))
            p.addLine(to: sPt(90, 86)); p.addLine(to: sPt(68, 82)); p.addLine(to: sPt(68, 92)); p.addLine(to: sPt(54, 72)); p.closeSubpath()
        }, with: .color(sC(0x2A2240)))
        c.fill(Path(ellipseIn: CGRect(x: 38, y: 50, width: 24, height: 30)), with: .color(sC(0x2A2240)))
        c.fill(Path(ellipseIn: CGRect(x: 42.4, y: 60.4, width: 6.4, height: 6.4)), with: .color(sC(0xFFD97A)))
        c.fill(Path(ellipseIn: CGRect(x: 54.4, y: 60.4, width: 6.4, height: 6.4)), with: .color(sC(0xFFD97A)))
    case "potion":
        c.fill(Path(roundedRect: CGRect(x: 42, y: 8, width: 16, height: 10), cornerRadius: 3), with: .color(sC(0x5A3FD6)))
        c.fill(sP { p in p.move(to: sPt(44, 18)); p.addLine(to: sPt(56, 18)); p.addLine(to: sPt(70, 50)); p.addCurve(to: sPt(50, 80), control1: sPt(70, 68), control2: sPt(58, 80)); p.addCurve(to: sPt(30, 50), control1: sPt(42, 80), control2: sPt(30, 68)); p.closeSubpath() }, with: .color(sC(0x7C5CFF)))
        c.fill(sP { p in p.move(to: sPt(28, 56)); p.addCurve(to: sPt(50, 90), control1: sPt(28, 76), control2: sPt(38, 90)); p.addCurve(to: sPt(72, 56), control1: sPt(62, 90), control2: sPt(72, 76)); p.closeSubpath() }, with: .color(sC(0x9B7BFF)))
        c.fill(Path(ellipseIn: CGRect(x: 45.6, y: 65.6, width: 8.8, height: 8.8)), with: .color(sC(0x2BD67B)))
        c.fill(Path(ellipseIn: CGRect(x: 37.8, y: 56.8, width: 6.4, height: 6.4)), with: .color(sC(0x2BD67B)))
        c.fill(Path(ellipseIn: CGRect(x: 55.4, y: 59.4, width: 7.2, height: 7.2)), with: .color(sC(0x2BD67B)))
    default: break
    }
}

/// Нарисованный стикер (не эмодзи)
struct StickerArtView: View {
    let id: String
    var size: CGFloat = 96
    var body: some View {
        Canvas { ctx, sz in
            var g = ctx
            let s = min(sz.width, sz.height) / 100
            g.scaleBy(x: s, y: s)
            drawStickerArt(g, id)
        }
        .frame(width: size, height: size)
    }
}

/// Тело стикера в сообщении: новые ('art:xxx') — настоящая картинка, старые (просто эмодзи) — как раньше, текстом
struct StickerBodyView: View {
    let body_: String?
    var size: CGFloat = 96
    var body: some View {
        if let b = body_, b.hasPrefix(stickerArtPrefix) {
            StickerArtView(id: String(b.dropFirst(stickerArtPrefix.count)), size: size)
        } else if let b = body_, b.hasPrefix(stickerImgPrefix), let u = URL(string: String(b.dropFirst(stickerImgPrefix.count))) {
            RemoteStickerView(url: u, size: size)
        } else {
            Text(body_ ?? "").font(.system(size: size * 0.66))
        }
    }
}
