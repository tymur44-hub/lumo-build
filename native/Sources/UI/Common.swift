import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

/// Аватар: фото или инициалы на цветном фоне (те же цвета, что на сайте), с точкой «в сети»
struct AvatarView: View {
    let name: String
    let url: String?
    let color: Int
    var size: CGFloat = 48
    var online = false
    var icon: String?

    var body: some View {
        ZStack {
            Circle().fill(Theme.avatarGradient(color))
            if let i = icon {
                Image(systemName: i).font(.system(size: size * 0.4, weight: .bold)).foregroundColor(.white)
            } else {
                Text(Fmt.initials(name))
                    .font(.system(size: size * 0.36, weight: .heavy))
                    .foregroundColor(.white)
            }
            if let u = url, let link = URL(string: u) {
                CachedImage(url: link) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.clear }
                .clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if online {
                Circle().fill(Theme.ok)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay(Circle().stroke(Theme.bg, lineWidth: max(2, size * 0.05)))
                    .offset(x: -size * 0.01, y: -size * 0.01)
            }
        }
    }
}

/// Картинка из сети с кэшем в памяти
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    func get(_ u: URL) -> UIImage? { cache.object(forKey: u as NSURL) }
    func set(_ u: URL, _ i: UIImage) { cache.setObject(i, forKey: u as NSURL) }
}

struct CachedImage<Content: View, Placeholder: View>: View {
    let url: URL
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    @State private var image: UIImage?

    init(url: URL, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        _image = State(initialValue: ImageCache.shared.get(url))
    }

    var body: some View {
        Group {
            if let i = image { content(Image(uiImage: i)) } else { placeholder() }
        }
        .task(id: url) {
            if image != nil { return }
            if let c = ImageCache.shared.get(url) { image = c; return }
            guard let res = try? await Net.session.data(from: url.px), let i = UIImage(data: res.0) else { return }
            ImageCache.shared.set(url, i)
            image = i
        }
    }
}

struct GradientButton: View {
    let title: String
    var loading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if loading { ProgressView().tint(.white) } else { Text(Lang.tr(title)).font(.headline) }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
            .foregroundColor(.white)
        }
        .disabled(loading)
    }
}

struct FieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
    }
}

extension View {
    func lumoField() -> some View { modifier(FieldStyle()) }
}

/// Поле поиска как на сайте (скруглённое, на фоне panel2)
struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
            Group {
                if let f = focused {
                    TextField(Lang.tr(placeholder), text: $text).focused(f)
                } else {
                    TextField(Lang.tr(placeholder), text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted) }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .lumoGlass(RoundedRectangle(cornerRadius: 22))
    }
}

/// Строка настроек с цветным значком, как на сайте
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let color: Color
    let title: String
    var subtitle: String?
    var titleColor: Color = Theme.text
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [color.opacity(0.72), color], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .shadow(color: color.opacity(0.35), radius: 4, y: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(Lang.tr(title)).font(.system(size: 16, weight: .semibold)).foregroundColor(titleColor)
                if let s = subtitle { Text(Lang.tr(s)).font(.system(size: 12.5)).foregroundColor(Theme.muted).lineLimit(2) }
            }
            Spacer(minLength: 6)
            trailing()
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

extension SettingsRow where Trailing == AnyView {
    init(icon: String, color: Color, title: String, subtitle: String? = nil, titleColor: Color = Theme.text, chevron: Bool = true) {
        self.icon = icon
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.trailing = {
            AnyView(Group {
                if chevron { Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundColor(Theme.muted) }
            })
        }
    }
}

/// Группа строк на «карточке» (panel2, радиус 18)
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 14)
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(Lang.tr(text).uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 4)
    }
}

/// Плавающая нижняя панель вкладок (как на сайте)
struct FloatingTabBar: View {
    @Binding var tab: AppTab
    let chatsBadge: Int
    let settingsBadge: Int

    var body: some View {
        HStack(spacing: 2) {
            item(.contacts, "person.crop.circle.fill", "Контакты", 0)
            item(.chats, "bubble.left.and.bubble.right.fill", "Чаты", chatsBadge)
            item(.settings, "gearshape.fill", "Настройки", settingsBadge)
        }
        .padding(6)
        .lumoGlass(Capsule(), interactive: true)
        .shadow(color: .black.opacity(0.3), radius: 17, y: 12)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { }   // касание между кнопками не должно проваливаться в чат под панелью
    }

    private func item(_ t: AppTab, _ icon: String, _ label: String, _ badge: Int) -> some View {
        TabItemButton(tab: $tab, t: t, icon: icon, label: label, badge: badge)
    }
}

/// Кнопка нижней панели: при нажатии значок оживает (контакты подпрыгивают, чаты покачиваются, шестерёнка крутится)
struct TabItemButton: View {
    @Binding var tab: AppTab
    let t: AppTab
    let icon: String
    let label: String
    let badge: Int
    @State private var pop = false
    @State private var spin: Double = 0
    @State private var tilt: Double = 0

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { tab = t }
            animate()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 22, weight: .semibold)).frame(height: 28)
                    .scaleEffect(pop ? 1.1 : 1)
                    .offset(y: pop && t == .contacts ? -3 : 0)
                    .rotationEffect(.degrees(t == .settings ? spin : tilt))
                Text(label).font(.system(size: 11.5, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .foregroundColor(tab == t ? Theme.a1 : Theme.text)
            .modifier(TabPill(selected: tab == t))
            .overlay(alignment: .top) {
                if badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).frame(minWidth: 20, minHeight: 20)
                        .background(Capsule().fill(Theme.danger))
                        .offset(x: 18, y: 0)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func animate() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { pop = true }
        switch t {
        case .settings:
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) { spin += 120 }
        case .chats:
            withAnimation(.easeInOut(duration: 0.18)) { tilt = -7 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { withAnimation(.easeInOut(duration: 0.22)) { tilt = 6 } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { tilt = 0 } }
        case .contacts:
            break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { pop = false }
        }
    }
}

/// Пузырь с «хвостиком» (разные радиусы углов)
struct BubbleShape: Shape {
    var tl: CGFloat = 18, tr: CGFloat = 18, bl: CGFloat = 18, br: CGFloat = 18

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let tl = min(self.tl, h / 2, w / 2), tr = min(self.tr, h / 2, w / 2)
        let bl = min(self.bl, h / 2, w / 2), br = min(self.br, h / 2, w / 2)
        p.move(to: CGPoint(x: r.minX + tl, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - tr, y: r.minY))
        p.addArc(center: CGPoint(x: r.maxX - tr, y: r.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br))
        p.addArc(center: CGPoint(x: r.maxX - br, y: r.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX + bl, y: r.maxY))
        p.addArc(center: CGPoint(x: r.minX + bl, y: r.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + tl))
        p.addArc(center: CGPoint(x: r.minX + tl, y: r.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        _ = w
        return p
    }
}

/// Поделиться / сохранить файл
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

enum QRCode {
    static func image(_ text: String, size: CGFloat = 600) -> UIImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(text.utf8)
        f.correctionLevel = "M"
        guard let out = f.outputImage else { return nil }
        let k = size / out.extent.width
        let scaled = out.transformed(by: CGAffineTransform(scaleX: k, y: k))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// Простой «заголовок» экрана во вкладках
struct ScreenTitle: View {
    let text: String
    var body: some View {
        Text(Lang.tr(text)).font(.system(size: 30, weight: .heavy)).foregroundColor(Theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18).padding(.top, 6)
    }
}

/// Переливающийся цветной фон (звонок, вход): мягкие цветные пятна медленно плывут и смешиваются
struct AuroraBackground: View {
    var intensity: Double = 1
    var speed: Double = 1
    var base: Color = Color(hex: 0x0b0c1a)
    var dim: Double = 0.18

    private struct Blob { let color: Color; let size: CGFloat; let fx: Double; let fy: Double; let px: Double; let py: Double; let ax: CGFloat; let ay: CGFloat }

    private var blobs: [Blob] {
        let (c1, c2) = Appearance.shared.pair
        return [
            Blob(color: Color(hex: c1), size: 1.05, fx: 0.11, fy: 0.08, px: 0, py: 1.3, ax: 0.32, ay: 0.26),
            Blob(color: Color(hex: c2), size: 0.95, fx: 0.07, fy: 0.12, px: 2.1, py: 0.4, ax: 0.35, ay: 0.3),
            Blob(color: Color(hex: 0xff5b9a), size: 0.85, fx: 0.09, fy: 0.06, px: 4.0, py: 2.6, ax: 0.3, ay: 0.34),
            Blob(color: Color(hex: 0x7c5cff), size: 1.0, fx: 0.05, fy: 0.1, px: 1.2, py: 3.7, ax: 0.28, ay: 0.32),
            Blob(color: Color(hex: 0x2ee6a6), size: 0.7, fx: 0.13, fy: 0.09, px: 5.1, py: 5.0, ax: 0.34, ay: 0.28),
        ]
    }

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate * speed
                ZStack {
                    base
                    ForEach(Array(blobs.enumerated()), id: \.offset) { _, b in
                        let s = max(g.size.width, g.size.height) * 0.62 * b.size
                        Circle()
                            .fill(b.color)
                            .frame(width: s, height: s)
                            .position(x: g.size.width * (0.5 + b.ax * CGFloat(sin(t * b.fx * 2 * .pi / 3 + b.px))),
                                      y: g.size.height * (0.5 + b.ay * CGFloat(cos(t * b.fy * 2 * .pi / 3 + b.py))))
                            .opacity(0.55 * intensity)
                    }
                }
                .blur(radius: 70)
                .overlay(Color.black.opacity(dim))
                .drawingGroup()
            }
        }
        .ignoresSafeArea()
    }
}

/// Расходящиеся цветные кольца (вызов идёт)
struct PulseRings: View {
    var size: CGFloat
    @State private var go = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Theme.accent, lineWidth: 3)
                    .frame(width: size, height: size)
                    .scaleEffect(go ? 1.9 : 1)
                    .opacity(go ? 0 : 0.8)
                    .animation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(Double(i) * 0.8), value: go)
            }
        }
        .onAppear { go = true }
        .allowsHitTesting(false)
    }
}

/// Значок «БЕТА»
struct BetaBadge: View {
    var body: some View {
        Text("БЕТА")
            .font(.system(size: 11, weight: .heavy))
            .tracking(1)
            .foregroundColor(.white)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(Capsule().fill(Theme.accent))
    }
}


// MARK: - «Жидкое стекло» (iOS 26); на старых системах — матовое стекло, как раньше
extension View {
    @ViewBuilder
    func lumoGlass<S: Shape>(_ shape: S, interactive: Bool = false, tint: Color? = nil) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if let t = tint {
                if interactive { self.glassEffect(.regular.tint(t).interactive(), in: shape) }
                else { self.glassEffect(.regular.tint(t), in: shape) }
            } else if interactive { self.glassEffect(.regular.interactive(), in: shape) }
            else { self.glassEffect(.regular, in: shape) }
        } else {
            self.lumoMaterial(shape)
        }
        #else
        self.lumoMaterial(shape)
        #endif
    }

    func lumoMaterial<S: Shape>(_ shape: S) -> some View {
        self.background(.ultraThinMaterial, in: shape)
            .background(Theme.panel.opacity(0.6), in: shape)
            .overlay(shape.stroke(Theme.line))
    }

    /// Фон верхней панели: на iOS 26 — прозрачный (система рисует стекло), раньше — сплошной
    @ViewBuilder
    func lumoNavBar() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) { self } else {
            self.toolbarBackground(Theme.panel, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
        }
        #else
        self.toolbarBackground(Theme.panel, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
        #endif
    }

    /// Нижняя панель (поле ввода): стекло на iOS 26, иначе почти сплошной фон
    @ViewBuilder
    func lumoBarBackground() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.background { Color.clear.glassEffect(.regular, in: Rectangle()).ignoresSafeArea(edges: .bottom) }
        } else {
            self.background(Theme.panel.opacity(0.97).ignoresSafeArea(edges: .bottom))
        }
        #else
        self.background(Theme.panel.opacity(0.97).ignoresSafeArea(edges: .bottom))
        #endif
    }
}

/// Выбранная вкладка: на iOS 26 — стеклянная «капсула» с оттенком, раньше — цветная заливка
struct TabPill: ViewModifier {
    let selected: Bool
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if selected { content.glassEffect(.regular.tint(Theme.a1.opacity(0.35)).interactive(), in: Capsule()) }
            else { content }
        } else {
            content.background(Capsule().fill(selected ? Theme.active : Color.clear))
        }
        #else
        content.background(Capsule().fill(selected ? Theme.active : Color.clear))
        #endif
    }
}


/// Значки рядом с именем: «БОТ» у ботов, звезда у подписчиков Premium
struct NameBadges: View {
    var bot: Bool
    var premium: Bool
    var emoji: String? = nil
    var verified = false
    var body: some View {
        HStack(spacing: 4) {
            if verified { Image(systemName: "checkmark.seal.fill").font(.system(size: 14)).foregroundColor(Theme.a2) }
            badge
        }
    }
    @ViewBuilder private var badge: some View {
        if bot {
            Text("БОТ").font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.muted)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Theme.muted.opacity(0.16), in: RoundedRectangle(cornerRadius: 5))
        } else if premium, let e = emoji {
            StatusEmojiView(s: e, size: 13)
        } else if premium {
            Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(Color(hex: 0xffb020))
        }
    }
}
