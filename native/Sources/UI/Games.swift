import SwiftUI
import WebKit

// MARK: - Мини-игры: броски в чате и игры вдвоём

enum LumoGames {
    static let titles = ["ttt": "Крестики-нолики", "checkers": "Шашки", "sea": "Морской бой", "chess": "Шахматы"]
    static let descs = ["ttt": "Три в ряд на поле 3×3", "checkers": "Русские шашки, взятие обязательно", "sea": "Флот 10 кораблей, поле 10×10",
                        "chess": "Классические шахматы по всем правилам"]
    static let throwsList: [(String, String)] = [("dice", "Кубик"), ("darts", "Дартс"), ("basket", "Баскетбол"), ("football", "Футбол"), ("coin", "Монетка")]
    static let colors: [String: [Color]] = [
        "ttt": [Color(hex: 0x22c1ff), Color(hex: 0x3a7bff)],
        "checkers": [Color(hex: 0xa7743f), Color(hex: 0x6b4426)],
        "sea": [Color(hex: 0x2bb3ff), Color(hex: 0x1460c8)],
        "chess": [Color(hex: 0x4a4f5c), Color(hex: 0x16181d)],
    ]
    static func label(_ k: String, _ v: Int) -> String {
        switch k {
        case "dice": return "Выпало \(v)"
        case "darts": return v == 6 ? "В яблочко!" : v == 1 ? "Мимо" : "Очков: \(v)"
        case "basket": return v >= 4 ? "Попал!" : "Мимо"
        case "football": return v >= 3 ? "Гол!" : "Мимо"
        default: return v == 1 ? "Орёл" : "Решка"
        }
    }

    static func call(_ body: [String: Any]) async throws -> JSON {
        let r = try await API.shared.raw("POST", "/functions/v1/lumo-games", body: body) as? JSON ?? [:]
        if let e = r.str("error") { throw APIError(message: e, status: 400) }
        return r
    }
}

/// Открытая игра — поверх всего приложения; можно свернуть в полоску внизу и вернуться
final class GameHost: ObservableObject {
    static let shared = GameHost()
    struct Open: Identifiable, Equatable { let id: String }
    @Published var open: Open?
    @Published var mini = false
    /// для полоски: название игры, чей ход, вид игры
    @Published var title = "Игра"
    @Published var status = ""
    @Published var kind = "chess"
    func show(_ id: String) {
        guard !id.isEmpty else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            if open?.id != id { open = Open(id: id) }
            mini = false
        }
    }
    func minimize() { withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { mini = true } }
    func expand() { UIImpactFeedbackGenerator(style: .light).impactOccurred(); withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { mini = false } }
    func close() { withAnimation(.easeInOut(duration: 0.3)) { open = nil; mini = false } }
}

struct GameHostModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay { GameOverlayView() }
    }
}

/// Игра на весь экран; свёрнутая — полоска над нижней панелью, страница игры продолжает жить
struct GameOverlayView: View {
    @ObservedObject var host = GameHost.shared
    var body: some View {
        GeometryReader { geo in
            if let o = host.open {
                let H = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                let barH: CGFloat = 64
                let bottomGap: CGFloat = geo.safeAreaInsets.bottom + 78
                ZStack(alignment: .top) {
                    GameScreen(gameId: o.id) { host.close() }
                        .frame(width: geo.size.width, height: H, alignment: .top)
                        .allowsHitTesting(!host.mini)
                    if host.mini {
                        Button { host.expand() } label: {
                            HStack(spacing: 12) {
                                GameIcon(kind: host.kind, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(host.title).font(.system(size: 15.5, weight: .bold)).foregroundColor(Theme.text)
                                    Text(host.status).font(.system(size: 13, weight: .medium)).foregroundColor(host.status.hasPrefix("Ваш ход") ? Theme.a1 : Theme.muted).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.up").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.muted)
                                    .frame(width: 34, height: 34).background(Circle().fill(Theme.text.opacity(0.07)))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: barH)
                            .frame(maxWidth: .infinity)
                            .background(Theme.panel)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .frame(width: geo.size.width - (host.mini ? 20 : 0), height: host.mini ? barH : H, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: host.mini ? 20 : 0, style: .continuous))
                .shadow(color: .black.opacity(host.mini ? 0.25 : 0), radius: 14, y: 6)
                .offset(x: host.mini ? 10 : 0, y: host.mini ? H - barH - bottomGap : 0)
                .ignoresSafeArea()
                .transition(.move(edge: .bottom))
                .gesture(host.mini ? DragGesture(minimumDistance: 12).onEnded { v in if v.translation.height < -30 { host.expand() } } : nil)
            }
        }
    }
}

// MARK: - Рисунки бросков

struct ThrowArt: View {
    let kind: String
    let v: Int

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack { art(s) }.frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder private func art(_ s: CGFloat) -> some View {
        switch kind {
        case "dice":
            let pips: [(CGFloat, CGFloat)] = [1: [(0.5, 0.5)], 2: [(0.3, 0.3), (0.7, 0.7)], 3: [(0.28, 0.28), (0.5, 0.5), (0.72, 0.72)],
                                              4: [(0.3, 0.3), (0.7, 0.3), (0.3, 0.7), (0.7, 0.7)],
                                              5: [(0.28, 0.28), (0.72, 0.28), (0.5, 0.5), (0.28, 0.72), (0.72, 0.72)],
                                              6: [(0.3, 0.26), (0.7, 0.26), (0.3, 0.5), (0.7, 0.5), (0.3, 0.74), (0.7, 0.74)]][v] ?? []
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.2, style: .continuous)
                    .fill(LinearGradient(colors: [.white, Color(hex: 0xdcd8f4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: s * 0.8, height: s * 0.8)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                ForEach(0..<pips.count, id: \.self) { i in
                    Circle().fill(v == 1 ? Color(hex: 0xe0284f) : Color(hex: 0x25264a))
                        .frame(width: s * 0.16, height: s * 0.16)
                        .position(x: s * pips[i].0, y: s * pips[i].1)
                }
            }
        case "darts":
            let p: (CGFloat, CGFloat) = [6: (0.5, 0.5), 5: (0.56, 0.42), 4: (0.38, 0.58), 3: (0.66, 0.64), 2: (0.3, 0.34), 1: (0.88, 0.14)][v] ?? (0.5, 0.5)
            ZStack {
                Circle().fill(Color(hex: 0x25264a)).frame(width: s * 0.84)
                Circle().fill(Color(hex: 0xf2efe4)).frame(width: s * 0.68)
                Circle().fill(Color(hex: 0xe0284f)).frame(width: s * 0.52)
                Circle().fill(Color(hex: 0xf2efe4)).frame(width: s * 0.36)
                Circle().fill(Color(hex: 0x2bb673)).frame(width: s * 0.2)
                Circle().fill(Color(hex: 0xe0284f)).frame(width: s * 0.08)
                ZStack(alignment: .bottom) {
                    Capsule().fill(Color(hex: 0x5a5d86)).frame(width: s * 0.035, height: s * 0.26)
                    Image(systemName: "triangle.fill").font(.system(size: s * 0.11)).foregroundColor(Theme.a1).offset(y: -s * 0.25)
                }
                .rotationEffect(.degrees(-35), anchor: .bottom)
                .position(x: s * p.0, y: s * p.1 - s * 0.13)
            }
        case "basket":
            let ok = v >= 4
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xf2efe4)).frame(width: s * 0.64, height: s * 0.4).position(x: s * 0.5, y: s * 0.28)
                Rectangle().stroke(Color(hex: 0xe0284f), lineWidth: 2.5).frame(width: s * 0.24, height: s * 0.16).position(x: s * 0.5, y: s * 0.3)
                Capsule().fill(Color(hex: 0xff6a2b)).frame(width: s * 0.4, height: s * 0.05).position(x: s * 0.5, y: s * 0.435)
                Image(systemName: "basketball.fill").font(.system(size: s * 0.24)).foregroundColor(Color(hex: 0xff8a3d))
                    .position(x: s * (ok ? 0.5 : 0.76), y: s * (ok ? 0.6 : 0.76))
            }
        case "football":
            let ok = v >= 3
            ZStack {
                Path { p in p.move(to: CGPoint(x: s * 0.1, y: s * 0.7)); p.addLine(to: CGPoint(x: s * 0.1, y: s * 0.24))
                    p.addLine(to: CGPoint(x: s * 0.9, y: s * 0.24)); p.addLine(to: CGPoint(x: s * 0.9, y: s * 0.7)) }
                    .stroke(Color(hex: 0xf2efe4), lineWidth: 4)
                Rectangle().fill(Color(hex: 0x2bb673).opacity(0.7)).frame(width: s, height: s * 0.2).position(x: s * 0.5, y: s * 0.9)
                Image(systemName: "soccerball").font(.system(size: s * 0.22, weight: .bold)).foregroundColor(.white)
                    .background(Circle().fill(Color(hex: 0x222222)).padding(2))
                    .position(x: s * (ok ? 0.4 : 0.88), y: s * (ok ? 0.48 : 0.2))
            }
        default:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: 0xffe7a1), Color(hex: 0xd79b22)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: s * 0.45))
                    .overlay(Circle().stroke(Color(hex: 0xb07a12), lineWidth: 3)).frame(width: s * 0.8)
                Circle().stroke(Color(hex: 0xb07a12), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3])).frame(width: s * 0.62)
                Text(v == 1 ? "О" : "Р").font(.system(size: s * 0.34, weight: .heavy, design: .serif)).foregroundColor(Color(hex: 0x8a5c08))
            }
        }
    }
}

/// Сообщение-бросок с анимацией для свежих сообщений
struct ThrowBubble: View {
    let m: Message
    let mine: Bool
    /// идёт анимация броска (только у свежих сообщений, один раз)
    @State private var playing = false
    private static var seen = Set<Int>()

    var body: some View {
        let k = m.meta.str("g") ?? "dice", v = m.meta.int("v") ?? 1
        VStack(spacing: 2) {
            ZStack {
                if playing {
                    ThrowPlayer(kind: k, v: v) { withAnimation(.easeOut(duration: 0.2)) { playing = false } }
                } else {
                    ThrowFinal(kind: k, v: v)
                }
            }
            .frame(width: 150, height: 150)
            Text(LumoGames.label(k, v)).font(.system(size: 15, weight: .heavy))
                .foregroundColor(mine ? .white : Theme.text)
                .opacity(playing ? 0 : 1)
            Text(Fmt.time(m.createdAt)).font(.system(size: 11)).foregroundColor(mine ? .white.opacity(0.7) : Theme.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 8).padding(.top, 6).padding(.bottom, 6)
        .frame(width: 170)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(mine ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel)))
        .onAppear {
            guard !ThrowBubble.seen.contains(m.id) else { return }
            ThrowBubble.seen.insert(m.id)
            if Date().timeIntervalSince(m.createdAt) < 6 { playing = true }
        }
    }
}

/// Финальный кадр броска (картинка из того же движка, что и анимация, — переход незаметен)
struct ThrowFinal: View {
    let kind: String
    let v: Int
    var body: some View {
        if let im = UIImage(named: "throw_\(kind)_\(v).png") ?? Bundle.main.path(forResource: "throw_\(kind)_\(v)", ofType: "png").flatMap(UIImage.init(contentsOfFile:)) {
            Image(uiImage: im).resizable().interpolation(.high).scaledToFit()
        } else {
            ThrowArt(kind: kind, v: v)
        }
    }
}

/// Живая анимация броска: страница throws.html (canvas) в прозрачном WebView
struct ThrowPlayer: UIViewRepresentable {
    let kind: String
    let v: Int
    let onEnd: () -> Void

    final class Coord: NSObject, WKScriptMessageHandler {
        var onEnd: () -> Void
        var ended = false
        init(onEnd: @escaping () -> Void) { self.onEnd = onEnd }
        func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
            let s = message.body as? String ?? ""
            if s == "hit" { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            if s == "end", !ended { ended = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.onEnd() } }
        }
    }
    func makeCoordinator() -> Coord { Coord(onEnd: onEnd) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(WeakHandler(context.coordinator), name: "lumo")
        let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 150, height: 150), configuration: cfg)
        w.isOpaque = false; w.backgroundColor = .clear; w.scrollView.backgroundColor = .clear
        w.scrollView.isScrollEnabled = false; w.isUserInteractionEnabled = false
        if let url = Bundle.main.url(forResource: "throws", withExtension: "html") {
            var c = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            c.fragment = "k=\(kind)&v=\(v)"
            w.loadFileURL(c.url ?? url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else { DispatchQueue.main.async { context.coordinator.onEnd() } }
        // страховка: если страница не ответила — показываем результат
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { if !context.coordinator.ended { context.coordinator.ended = true; context.coordinator.onEnd() } }
        return w
    }
    func updateUIView(_ w: WKWebView, context: Context) {}
    static func dismantleUIView(_ w: WKWebView, coordinator: Coord) { w.configuration.userContentController.removeScriptMessageHandler(forName: "lumo") }
}

/// Чтобы WebView не удерживал координатор (иначе утечка)
final class WeakHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ t: WKScriptMessageHandler) { target = t }
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) { target?.userContentController(c, didReceive: m) }
}

struct GameIcon: View {
    let kind: String
    var size: CGFloat = 46
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: LumoGames.colors[kind] ?? [Theme.a1, Theme.a2], startPoint: .topLeading, endPoint: .bottomTrailing))
            switch kind {
            case "ttt":
                HStack(spacing: size * 0.04) {
                    Image(systemName: "xmark").font(.system(size: size * 0.3, weight: .heavy))
                    Image(systemName: "circle").font(.system(size: size * 0.28, weight: .heavy))
                }.foregroundColor(.white)
            case "checkers":
                ZStack {
                    Circle().fill(Color(hex: 0x2a1a10)).frame(width: size * 0.6).offset(y: size * 0.06)
                    Circle().fill(Color(hex: 0xf4ead6)).frame(width: size * 0.6)
                    Circle().stroke(Color(hex: 0xc9a46a), lineWidth: 1.5).frame(width: size * 0.34)
                }
            case "chess":
                KnightShape().fill(LinearGradient(colors: [.white, Color(hex: 0xd9cfb8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.56, height: size * 0.62)
                    .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
            default:
                Image(systemName: "ferry.fill").font(.system(size: size * 0.42, weight: .bold)).foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Силуэт шахматного коня (значок игры «Шахматы»)
struct KnightShape: Shape {
    func path(in r: CGRect) -> Path {
        let sx = r.width / 15, sy = r.height / 19
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + (x - 4.2) * sx, y: r.minY + (y - 3) * sy) }
        var a = Path()
        a.move(to: p(7, 20))
        a.addCurve(to: p(11, 12), control1: p(7, 16), control2: p(8.5, 14))
        a.addCurve(to: p(7, 14), control1: p(9.4, 12), control2: p(8, 12.8))
        a.addLine(to: p(5, 12.4))
        a.addCurve(to: p(5, 10.2), control1: p(4.5, 11.7), control2: p(4.5, 10.9))
        a.addCurve(to: p(12.3, 4.4), control1: p(6.8, 7.4), control2: p(9.3, 5.2))
        a.addLine(to: p(13, 3))
        a.addLine(to: p(14.2, 5.3))
        a.addCurve(to: p(18.7, 14.3), control1: p(17, 6.9), control2: p(18.7, 10.1))
        a.addCurve(to: p(17.9, 20), control1: p(18.7, 16.3), control2: p(18.4, 17.9))
        a.closeSubpath()
        a.addRoundedRect(in: CGRect(origin: p(5, 20.3), size: CGSize(width: 14 * sx, height: 1.7 * sy)), cornerSize: CGSize(width: sx, height: sx))
        return a
    }
}

/// Карточка игры вдвоём в чате
struct GameBubble: View {
    @EnvironmentObject var model: AppModel
    let m: Message
    let mine: Bool

    var body: some View {
        let mt = m.meta, k = mt.str("g") ?? "ttt", st = mt.str("st") ?? "invite", me = model.myId
        let p1 = mt.str("p1"), p2 = mt.str("p2")
        let player = me != nil && (me == p1 || me == p2)
        let btn: String = st == "invite" ? (p1 != me && m.senderId != me ? "Принять" : "Открыть")
            : (st == "active" || st == "setup") ? (player ? "Играть" : "Смотреть") : "Посмотреть"
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 11) {
                GameIcon(kind: k)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LumoGames.titles[k] ?? "Игра").font(.system(size: 15.5, weight: .bold))
                    Text(status(mt, st, me)).font(.system(size: 13)).opacity(0.8)
                }
            }
            HStack(spacing: 6) {
                Text(mt.str("p1n") ?? model.displayName(m.senderId)).font(.system(size: 13.5, weight: .bold)).lineLimit(1)
                Text("VS").font(.system(size: 11, weight: .heavy)).opacity(0.6)
                Text(p2 == nil ? "ждём соперника" : (mt.str("p2n") ?? "")).font(.system(size: 13.5, weight: p2 == nil ? .regular : .bold)).opacity(p2 == nil ? 0.7 : 1).lineLimit(1)
                Spacer(minLength: 4)
                if let s = mt.int("stake"), s > 0 {
                    HStack(spacing: 3) { Image(systemName: "diamond.fill").font(.system(size: 11)); Text("\(s)").font(.system(size: 13.5, weight: .heavy)) }
                        .foregroundColor(Color(hex: 0xf5b942))
                }
            }
            Button { GameHost.shared.show(mt.str("game") ?? "") } label: {
                Text(btn).font(.system(size: 14.5, weight: .heavy))
                    .foregroundColor(mine || btn == "Посмотреть" ? (mine ? .white : Theme.text) : .white)
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(mine ? AnyShapeStyle(Color.white.opacity(0.18)) : btn == "Посмотреть" ? AnyShapeStyle(Theme.panel2) : AnyShapeStyle(Theme.accent)))
            }
            .buttonStyle(BouncyButtonStyle())
            Text(Fmt.time(m.createdAt)).font(.system(size: 11)).opacity(0.6).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundColor(mine ? .white : Theme.text)
        .padding(12)
        .frame(width: 270)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(mine ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel)))
    }

    private func status(_ mt: JSON, _ st: String, _ me: String?) -> String {
        switch st {
        case "invite": return mt.str("p1") == me ? "Ждём соперника" : "Приглашение сыграть"
        case "setup": return "Расстановка кораблей"
        case "active": return "Идёт игра"
        case "declined": return "Приглашение отклонено"
        case "canceled": return "Игра отменена"
        default:
            guard let w = mt.str("winner") else { return "Ничья" }
            return w == me ? "Вы победили" : "Победил(а) " + (mt.str("wn") ?? "")
        }
    }
}

// MARK: - Меню игр

struct GamesSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    @State private var game = "ttt"
    @State private var stake = 0
    /// таймер партии: минуты и добавка за ход (0 — без таймера)
    @State private var clock: (Int, Int) = (0, 0)
    private let clocks: [(Int, Int, String)] = [(0, 0, "Без таймера"), (1, 0, "1 мин"), (3, 2, "3 + 2"), (5, 0, "5 мин"), (10, 0, "10 мин"), (15, 10, "15 + 10"), (30, 0, "30 мин")]
    @State private var custom = ""
    @State private var busy = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Игры").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                            .frame(width: 36, height: 36).background(Theme.panel2, in: Circle())
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 6)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header("БРОСИТЬ В ЧАТ")
                    HStack(spacing: 8) {
                        ForEach(LumoGames.throwsList, id: \.0) { t in
                            Button { throwIt(t.0) } label: {
                                VStack(spacing: 6) {
                                    ThrowArt(kind: t.0, v: t.0 == "dice" ? 5 : t.0 == "coin" ? 1 : t.0 == "darts" ? 6 : 5).frame(width: 40, height: 40)
                                    Text(t.1).font(.system(size: 11.5, weight: .bold)).foregroundColor(Theme.text).lineLimit(1).minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(BouncyButtonStyle())
                        }
                    }
                    header("ИГРАТЬ ВДВОЁМ")
                    VStack(spacing: 8) {
                        ForEach(["chess", "ttt", "checkers", "sea"], id: \.self) { k in
                            Button { withAnimation(.easeOut(duration: 0.15)) { game = k } } label: {
                                HStack(spacing: 12) {
                                    GameIcon(kind: k, size: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(LumoGames.titles[k]!).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                        Text(LumoGames.descs[k]!).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                    if game == k { Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(Theme.accent) }
                                }
                                .padding(10)
                                .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(game == k ? Theme.a1 : .clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if game == "chess" || game == "checkers" {
                        header("ТАЙМЕР")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(clocks, id: \.2) { c in
                                    let on = clock.0 == c.0 && clock.1 == c.1
                                    Button { UISelectionFeedbackGenerator().selectionChanged(); clock = (c.0, c.1) } label: {
                                        HStack(spacing: 4) {
                                            if c.0 > 0 { Image(systemName: "timer").font(.system(size: 11, weight: .bold)) }
                                            Text(c.2).font(.system(size: 13.5, weight: .bold))
                                        }
                                        .foregroundColor(on ? .white : Theme.text)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(on ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel2)))
                                    }
                                }
                            }
                        }
                        Text(clock.0 > 0 ? "У каждого \(clock.0) мин на партию" + (clock.1 > 0 ? " и +\(clock.1) сек за каждый ход" : "") + ". Время вышло — поражение. Если соперник выйдет из игры, часы остановятся, а через 30 секунд победа достанется вам."
                             : "Без ограничения времени: соперник может думать над ходом до суток.")
                            .font(.system(size: 12.5)).foregroundColor(Theme.muted).padding(.top, 6)
                    }
                    header("СТАВКА ЛЮМЕНАМИ")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach([0, 10, 50, 100, 500], id: \.self) { v in
                                Button { stake = v; custom = "" } label: {
                                    HStack(spacing: 4) {
                                        if v > 0 { Image(systemName: "diamond.fill").font(.system(size: 11)) }
                                        Text(v == 0 ? "Без ставки" : "\(v)").font(.system(size: 13.5, weight: .bold))
                                    }
                                    .foregroundColor(stake == v && custom.isEmpty ? .white : Theme.text)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(stake == v && custom.isEmpty ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel2)))
                                }
                            }
                            TextField("Своя", text: $custom).keyboardType(.numberPad)
                                .font(.system(size: 13.5, weight: .bold)).foregroundColor(Theme.text)
                                .frame(width: 70).padding(.horizontal, 10).padding(.vertical, 8)
                                .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 12))
                                .onChange(of: custom) { v in
                                    let d = v.filter(\.isNumber)
                                    let n = min(Int(d) ?? 0, 1000)
                                    if d != v || (Int(d) ?? 0) > 1000 { custom = d.isEmpty ? "" : "\(n)" }
                                    if !custom.isEmpty { stake = n }
                                }
                        }
                    }
                    Text("Ставку вносят оба игрока, победитель забирает обе. При ничьей ставки возвращаются. Если соперник не примет приглашение, ставку можно вернуть отменой. Максимум — 1000 люменов.")
                        .font(.system(size: 12.5)).foregroundColor(Theme.muted).padding(.top, 8)
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            }
            Button { invite() } label: {
                Group {
                    if busy { ProgressView().tint(.white) } else {
                        HStack(spacing: 8) { Image(systemName: "paperplane.fill"); Text("Пригласить" + (stake > 0 ? " · ставка \(stake)" : "")) }
                    }
                }
                .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(busy)
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
    }

    private func header(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.muted).padding(.top, 16).padding(.bottom, 8)
    }

    private func throwIt(_ k: String) {
        dismiss()
        Task {
            do { _ = try await API.shared.rpc("lm_throw", ["p_chat": chatId, "p_kind": k]) }
            catch { model.say(error.localizedDescription) }
        }
    }

    private func invite() {
        busy = true
        Task {
            do {
                var body: [String: Any] = ["action": "new", "chat_id": chatId, "kind": game, "stake": stake]
                if (game == "chess" || game == "checkers") && clock.0 > 0 { body["clock_min"] = clock.0; body["clock_inc"] = clock.1 }
                let g = try await LumoGames.call(body)
                busy = false
                dismiss()
                model.say("Приглашение отправлено")
                if let id = g.str("id") { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { GameHost.shared.show(id) } }
            } catch {
                busy = false
                model.say((error as? APIError)?.message ?? error.localizedDescription)
            }
        }
    }
}

// MARK: - Экран игры (общая страница игр в WebView)

struct GameScreen: View {
    let gameId: String
    let onClose: () -> Void
    @State private var token: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if let t = token {
                GameWeb(gameId: gameId, token: t, dark: scheme == .dark, onClose: onClose).ignoresSafeArea()
            } else {
                ProgressView().tint(Theme.muted)
            }
        }
        .task { token = try? await API.shared.validToken(); if token == nil { onClose() } }
    }
}

struct GameWeb: UIViewRepresentable {
    let gameId: String
    let token: String
    let dark: Bool
    let onClose: () -> Void

    func makeCoordinator() -> Coord { Coord(onClose) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(context.coordinator, name: "lumo")
        let w = WKWebView(frame: .zero, configuration: cfg)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.scrollView.bounces = false
        w.scrollView.contentInsetAdjustmentBehavior = .never
        let conf: [String: Any] = ["api": Net.base + "/functions/v1/lumo-games", "apikey": Config.anonKey, "token": token,
                                   "gameId": gameId, "theme": dark ? "dark" : "light", "mini": true]
        let js = (try? JSONSerialization.data(withJSONObject: conf)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let html = (RemoteConfig.shared.gamesHTML() ?? gamesHTML).replacingOccurrences(of: "/*CFG*/", with: "window.LUMO_GAME=\(js);")
        w.loadHTMLString(html, baseURL: URL(string: "https://lumomess.ru/"))
        return w
    }

    func updateUIView(_ v: WKWebView, context: Context) {}

    static func dismantleUIView(_ v: WKWebView, coordinator: Coord) {
        v.configuration.userContentController.removeScriptMessageHandler(forName: "lumo")
    }

    final class Coord: NSObject, WKScriptMessageHandler {
        let onClose: () -> Void
        init(_ f: @escaping () -> Void) { onClose = f }
        func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
            let s = m.body as? String ?? ""
            DispatchQueue.main.async {
                if s == "close" { self.onClose() }
                else if s == "minimize" { GameHost.shared.minimize() }
                else if s.hasPrefix("info|") {
                    let p = s.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
                    if p.count >= 4 { GameHost.shared.title = p[1]; GameHost.shared.status = p[2]; GameHost.shared.kind = p[3] }
                }
            }
        }
    }
}
