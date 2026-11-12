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
    var storyUid: String? = nil
    @ObservedObject private var videos = VideoAvatars.shared

    var body: some View {
        if let u = storyUid { StoryRingAvatar(uid: u, size: size) { base } } else { base }
    }

    private var base: some View {
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
                // видео-аватарка (Premium): зациклено и без звука поверх фото
                if size >= 28, let v = videos.video(for: u) {
                    LoopingVideo(url: v).frame(width: size, height: size).clipShape(Circle())
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) { OnlineDot(online: online, size: size) }
    }
}

/// Круг вокруг аватара, если у человека есть история: нажатие открывает её
struct StoryRingAvatar<Content: View>: View {
    let uid: String
    let size: CGFloat
    @ViewBuilder var content: () -> Content
    @ObservedObject private var m = AppModel.shared
    @State private var spin = false
    var body: some View {
        if let g = m.stories.first(where: { $0.userId == uid }) {
            let fresh = g.unseen
            let ring: AngularGradient = uid == m.myId
                ? AngularGradient(colors: [Theme.a1, Theme.a2, Theme.a1], center: .center)
                : (fresh ? AngularGradient(colors: [Color(hex: 0xFF9F1A), Color(hex: 0xFF3B8A), Theme.a1, Theme.a2, Color(hex: 0xFF9F1A)], center: .center)
                         : AngularGradient(colors: [Theme.line, Theme.line], center: .center))
            content()
                .scaleEffect((size - 11) / size)
                .frame(width: size, height: size)
                .overlay(Circle().stroke(ring, lineWidth: 2.5).rotationEffect(.degrees(spin && fresh ? 360 : 0)))
                .contentShape(Circle())
                .onTapGesture { m.storyOpen = uid }
                .onAppear { if fresh { withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { spin = true } } }
        } else { content() }
    }
}

/// Картинка из сети с кэшем в памяти
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    /// Картинки дублируются на диск — аватарки и фото видны без интернета
    private let dir: URL = {
        let u = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("lumo-img", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }()
    private func file(_ u: URL) -> URL {
        var h: UInt64 = 1469598103934665603
        for b in u.absoluteString.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return dir.appendingPathComponent(String(h, radix: 36))
    }
    func get(_ u: URL) -> UIImage? {
        if let i = cache.object(forKey: u as NSURL) { return i }
        guard let d = try? Data(contentsOf: file(u)), let i = UIImage(data: d) else { return nil }
        cache.setObject(i, forKey: u as NSURL)
        return i
    }
    func set(_ u: URL, _ i: UIImage) { cache.setObject(i, forKey: u as NSURL) }
    func purgeMemory() { cache.removeAllObjects() }
    /// стикеры лежат отдельно — так их видно в «Использовании памяти»
    private let stkDir: URL = DeviceStorage.ensure(.sticker)
    private func stkFile(_ u: URL) -> URL {
        var h: UInt64 = 1469598103934665603
        for b in u.absoluteString.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return stkDir.appendingPathComponent(String(h, radix: 36))
    }
    func has(_ u: URL) -> Bool { cache.object(forKey: u as NSURL) != nil || FileManager.default.fileExists(atPath: file(u).path) || FileManager.default.fileExists(atPath: stkFile(u).path) }
    /// картинка с телефона, а если её нет — из сети (и сразу на телефон)
    func load(_ u: URL, kind: DataKind = .photo) async -> UIImage? {
        if let i = get(u) { return i }
        if let d = try? Data(contentsOf: stkFile(u)), let i = UIImage(data: d) { cache.setObject(i, forKey: u as NSURL); return i }
        guard let res = try? await Net.session.data(from: u.px), let i = UIImage(data: res.0) else { return nil }
        NetStats.shared.add(kind, recv: res.0.count)
        cache.setObject(i, forKey: u as NSURL)
        let f = kind == .sticker ? stkFile(u) : file(u)
        DispatchQueue.global(qos: .utility).async { try? res.0.write(to: f, options: .atomic) }
        return i
    }
    func set(_ u: URL, _ i: UIImage, data: Data) {
        cache.setObject(i, forKey: u as NSURL)
        let f = file(u)
        DispatchQueue.global(qos: .utility).async { try? data.write(to: f, options: .atomic) }
    }
}

struct CachedImage<Content: View, Placeholder: View>: View {
    let url: URL
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    var kind: DataKind = .photo
    @State private var image: UIImage?

    init(url: URL, kind: DataKind = .photo, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.kind = kind
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
            if let i = await ImageCache.shared.load(url, kind: kind) { image = i }
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

/// Нижняя панель вкладок в стиле iOS 26 / Telegram: стеклянная капсула, выбранная вкладка — серая «пилюля».
/// Если зажать и вести пальцем, пилюля превращается в увеличительную каплю-линзу, которая
/// едет за пальцем и увеличивает значки под собой; отпустили — вкладка выбрана, линза «стекает» обратно.
struct FloatingTabBar: View {
    @Binding var tab: AppTab
    let chatsBadge: Int
    let settingsBadge: Int
    @EnvironmentObject var model: AppModel

    private let tabs: [AppTab] = [.contacts, .chats, .settings]
    @State private var width: CGFloat = 0
    @State private var lensX: CGFloat?          // центр линзы, пока палец на панели
    @State private var pressed = false
    @State private var pops: [AppTab: Int] = [:]
    private let pad: CGFloat = 5
    private let height: CGFloat = 62

    private var itemW: CGFloat { max(1, (width - pad * 2) / CGFloat(tabs.count)) }
    private func center(_ t: AppTab) -> CGFloat { pad + itemW * (CGFloat(tabs.firstIndex(of: t) ?? 0) + 0.5) }
    private func nearest(_ x: CGFloat) -> AppTab {
        let i = Int(((x - pad) / itemW).rounded(.down))
        return tabs[min(tabs.count - 1, max(0, i))]
    }
    /// где сейчас пилюля/линза
    private var indicatorX: CGFloat { lensX ?? center(tab) }
    /// вкладка, которая подсвечена (под линзой или выбранная)
    private var lit: AppTab { lensX.map(nearest) ?? tab }

    var body: some View {
        ZStack(alignment: .leading) {
            // обычная пилюля выбранной вкладки (пока не тянем)
            Capsule().fill(Theme.active)
                .frame(width: itemW, height: height - pad * 2)
                .offset(x: indicatorX - itemW / 2)
                .opacity(lensX == nil ? 1 : 0)
            items(scale: 1)
            if let x = lensX {
                lens(x)
            }
        }
        // панель всегда на всю ширину (иначе ширина считалась нулевой и всё сжималось в точку)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
        .background(GeometryReader { g in Color.clear.onAppear { width = g.size.width }.onChange(of: g.size.width) { width = $0 } })
        .lumoGlass(Capsule(), interactive: true)
        .shadow(color: .black.opacity(0.22), radius: 16, y: 10)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { v in
                    let x = min(max(v.location.x, pad + itemW / 2), width - pad - itemW / 2)
                    let moved = abs(v.translation.width) > 6
                    if lensX == nil {
                        if !pressed { pressed = true; UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                        // сначала линза «выдувается» из выбранной вкладки, потом едет к пальцу
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) { lensX = moved ? x : center(tab) + (x - center(tab)) * 0.35 }
                    } else {
                        let before = nearest(lensX!)
                        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.82)) { lensX = x }
                        if nearest(x) != before { UISelectionFeedbackGenerator().selectionChanged() }
                    }
                }
                .onEnded { v in
                    let x = min(max(v.location.x, pad), width - pad)
                    let t = nearest(x)
                    pressed = false
                    select(t)
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) { lensX = nil }
                }
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func select(_ t: AppTab) {
        if t == tab, t == .chats { NotificationCenter.default.post(name: .lumoChatsTop, object: nil) }
        if t != tab { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) { tab = t }
        pops[t, default: 0] += 1
    }

    /// ряд вкладок; scale — для увеличенной копии внутри линзы
    private func items(scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { t in
                TabBarItem(t: t, lit: lit == t, badge: badge(t), pop: pops[t] ?? 0)
                    .frame(width: itemW, height: height - pad * 2)
            }
        }
        .padding(.horizontal, pad)
        .frame(width: width, height: height, alignment: .leading)
        .scaleEffect(scale, anchor: UnitPoint(x: width > 0 ? indicatorX / width : 0.5, y: 0.5))
        .allowsHitTesting(false)
    }

    private func badge(_ t: AppTab) -> Int {
        switch t { case .chats: return chatsBadge; case .settings: return settingsBadge; case .contacts: return 0 }
    }

    /// капля-линза: прозрачное стекло с радужной кромкой, внутри — увеличенные значки
    private func lens(_ x: CGFloat) -> some View {
        let w = itemW + 14, h = height + 10
        let shape = Capsule()
        return ZStack {
            items(scale: 1.18)
                .frame(width: width, height: height)
                .offset(x: width / 2 - x)
                .frame(width: w, height: h)
                .clipShape(shape)
            shape.fill(LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.04), .white.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                .blendMode(.plusLighter)
            // радужная преломляющая кромка
            shape.strokeBorder(AngularGradient(colors: [.pink, .orange, .yellow, .mint, .cyan, .blue, .purple, .pink], center: .center), lineWidth: 2.2)
                .blur(radius: 1.6).opacity(0.75)
            shape.strokeBorder(.white.opacity(0.9), lineWidth: 0.8)
        }
        .frame(width: w, height: h)
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .position(x: x, y: height / 2)
        .transition(.scale(scale: 0.7).combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

/// Одна вкладка: значок + подпись; у «Настроек» — своя аватарка. При выборе значок оживает.
struct TabBarItem: View {
    let t: AppTab
    let lit: Bool
    let badge: Int
    let pop: Int
    @EnvironmentObject var model: AppModel
    @State private var bump = false
    @State private var spin: Double = 0
    @State private var tilt: Double = 0

    var body: some View {
        VStack(spacing: 2) {
            icon
                .frame(height: 28)
                .scaleEffect(bump ? 1.12 : 1)
                .offset(y: bump && t == .contacts ? -3 : 0)
                .rotationEffect(.degrees(t == .chats ? tilt : 0))
            Text(label).font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundColor(lit ? Theme.a1 : Theme.text)
        .animation(.easeInOut(duration: 0.15), value: lit)
        .overlay(alignment: .top) {
            if badge > 0 {
                Text(badge > 999 ? String(format: "%.1fK", Double(badge) / 1000) : "\(badge)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).frame(minWidth: 20, minHeight: 20)
                    .background(Capsule().fill(Theme.danger))
                    .offset(x: 20, y: -2)
            }
        }
        .onChange(of: pop) { _ in animate() }
    }

    @ViewBuilder private var icon: some View {
        switch t {
        case .settings:
            let me = model.me
            AvatarView(name: me?.name ?? "", url: me?.avatarURL, color: me?.color ?? 0, size: 28)
                .overlay(Circle().stroke(lit ? Theme.a1 : .clear, lineWidth: 2).padding(-2))
        case .chats:
            Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 22, weight: .semibold))
        case .contacts:
            Image(systemName: "person.crop.circle.fill").font(.system(size: 23, weight: .semibold))
        }
    }

    private var label: String {
        switch t { case .settings: return Lang.tr("Настройки"); case .chats: return Lang.tr("Чаты"); case .contacts: return Lang.tr("Контакты") }
    }

    private func animate() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { bump = true }
        if t == .chats {
            withAnimation(.easeInOut(duration: 0.18)) { tilt = -7 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { withAnimation(.easeInOut(duration: 0.22)) { tilt = 6 } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { tilt = 0 } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { bump = false }
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
            self.background {
                // мягкое затемнение снизу вместо сплошной панели: кнопки и поле ввода — отдельное «жидкое стекло»
                LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom).allowsHitTesting(false)
            }
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
    /// для плашки по нажатию на галочку: «профиль», «канал», «группа», «бот»
    var kind = "профиль"
    var body: some View {
        HStack(spacing: 4) {
            if verified {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 14)).foregroundColor(Theme.a2)
            }
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


/// Плашка сверху экрана (например, «Подтверждено администрацией Lumo» по нажатию на галочку)
@MainActor
final class Plaque: ObservableObject {
    static let shared = Plaque()
    @Published var item: (icon: String, title: String, text: String)?
    private var hideTask: Task<Void, Never>?
    func show(icon: String, title: String, text: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { item = (icon, title, text) }
        hideTask?.cancel()
        hideTask = Task { try? await Task.sleep(nanoseconds: 3_200_000_000); if !Task.isCancelled { self.hide() } }
    }
    func hide() { withAnimation(.easeIn(duration: 0.22)) { item = nil } }
    func verified(_ kind: String) {
        let who: String
        switch kind {
        case "канал": who = "Этот канал"
        case "группа": who = "Эта группа"
        case "бот": who = "Этот бот"
        default: who = "Этот профиль"
        }
        show(icon: "checkmark.seal.fill", title: "Подтверждено", text: who + " подтверждён администрацией Lumo.")
    }
}

struct PlaqueOverlay: View {
    @ObservedObject var p = Plaque.shared
    var body: some View {
        VStack {
            if let it = p.item {
                HStack(spacing: 12) {
                    Image(systemName: it.icon).font(.system(size: 24, weight: .semibold)).foregroundColor(Theme.a2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(it.title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                        Text(it.text).font(.system(size: 13.5)).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .lumoGlass(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
                .padding(.horizontal, 14).padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .top)))
                .onTapGesture { p.hide() }
                .gesture(DragGesture().onEnded { if $0.translation.height < -10 { p.hide() } })
            }
            Spacer()
        }
        .allowsHitTesting(p.item != nil)
    }
}


extension AnyTransition {
    /// смена строки статуса («печатает…», «записывает голосовое…», «в сети») — мягко, с лёгким сдвигом
    static var statusSwap: AnyTransition {
        .asymmetric(insertion: .opacity.combined(with: .offset(y: 5)), removal: .opacity.combined(with: .offset(y: -5)))
    }
}
