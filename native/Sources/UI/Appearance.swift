import SwiftUI

/// Фон чата (те же варианты, что на сайте)
struct ChatWallpaper: View {
    let index: Int
    var custom: ChatWall? = nil

    private static let premWalls: [(UInt32, UInt32)] = [(0x1b2a49, 0x3b1f4a), (0x0f3d3e, 0x1b6b4a), (0x4a1f2e, 0x7a3b1f), (0x1f2a4a, 0x2e6ba8)]

    var body: some View {
        let idx = custom?.preset ?? index
        ZStack {
            Theme.chatBg
            if let c = custom, let u = c.url.flatMap(URL.init(string:)) {
                GeometryReader { g in
                    AsyncImage(url: u) { ph in
                        if let im = ph.image { im.resizable().scaledToFill().frame(width: g.size.width, height: g.size.height).clipped() }
                    }
                    .blur(radius: c.blur ? 14 : 0)
                    .clipped()
                }
                Color.black.opacity(Double(c.dim) / 100)
            }
            switch custom?.url != nil ? -1 : ((wallIsPremium(idx) && custom == nil && !AppModel.shared.isPremium) ? 0 : idx) {
            case 10...17, 20...27:
                WallArtView(index: idx)
            case 6...9:
                LinearGradient(colors: [Color(hex: ChatWallpaper.premWalls[idx - 6].0), Color(hex: ChatWallpaper.premWalls[idx - 6].1)], startPoint: .top, endPoint: .bottom)
            case 1:
                LinearGradient(colors: [Color(hex: 0x7c5cff).opacity(0.13), Color(hex: 0x22c1ff).opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 2:
                GeometryReader { g in
                    ZStack {
                        RadialGradient(colors: [Color(hex: 0xff5b8a).opacity(0.16), .clear], center: UnitPoint(x: 0.18, y: 0.22), startRadius: 0, endRadius: g.size.width * 0.7)
                        RadialGradient(colors: [Color(hex: 0x7c5cff).opacity(0.16), .clear], center: UnitPoint(x: 0.82, y: 0.72), startRadius: 0, endRadius: g.size.width * 0.7)
                    }
                }
            case 3:
                Canvas { ctx, size in
                    let step: CGFloat = 18
                    var y: CGFloat = 0
                    while y < size.height {
                        var x: CGFloat = 0
                        while x < size.width {
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.4, height: 2.4)), with: .color(Color(hex: 0x8080aa).opacity(0.22)))
                            x += step
                        }
                        y += step
                    }
                }
            case 4:
                LinearGradient(colors: [Color(hex: 0x13b0a5).opacity(0.16), Color(hex: 0x2ee6a6).opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case 5:
                Canvas { ctx, size in
                    var p = Path()
                    var x: CGFloat = -size.height
                    while x < size.width {
                        p.move(to: CGPoint(x: x, y: size.height))
                        p.addLine(to: CGPoint(x: x + size.height, y: 0))
                        x += 14
                    }
                    ctx.stroke(p, with: .color(Color(hex: 0x8080aa).opacity(0.07)), lineWidth: 2)
                }
            default:
                EmptyView()
            }
        }
    }
}

struct AppearanceView: View {
    @EnvironmentObject var look: Appearance
    @EnvironmentObject var model: AppModel
    @State private var showIcons = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ZStack {
                    ChatWallpaper(index: look.wall)
                    VStack(spacing: 8) {
                        Text("Привет! Как тебе новый Lumo?")
                            .font(.system(size: look.fontSize)).foregroundColor(Theme.text)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(BubbleShape(tl: 18, tr: 18, bl: 6, br: 18).fill(Theme.bubble))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Очень красиво")
                            .font(.system(size: look.fontSize)).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(BubbleShape(tl: 18, tr: 18, bl: 18, br: 6).fill(Theme.out))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(14)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 14)

                SectionTitle(text: "Тема")
                HStack(spacing: 6) {
                    themeButton("light", "Светлая", "sun.max.fill")
                    themeButton("dark", "Тёмная", "moon.fill")
                    themeButton("auto", "Как в системе", "gearshape.fill")
                }
                .padding(4)
                .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 14)

                SectionTitle(text: "Иконка приложения")
                SettingsGroup {
                    Button { showIcons = true } label: {
                        SettingsRow(icon: "square.grid.2x2.fill", color: Color(hex: 0x5b6cff), title: "Иконка приложения", subtitle: "Шесть оформлений, часть — с премиум-значком")
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
                .sheet(isPresented: $showIcons) { AppIconSheet().environmentObject(model) }

                SectionTitle(text: "Цвет")
                SettingsGroup {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 14), count: 6), spacing: 14) {
                        ForEach(0..<Appearance.accents.count, id: \.self) { i in
                            let p = Appearance.accents[i]
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: p.0), Color(hex: p.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 40, height: 40)
                                .overlay(Circle().stroke(Theme.text, lineWidth: look.accent == i ? 3 : 0).padding(-4))
                                .onTapGesture { if i >= 6 && !model.isPremium { model.say(premiumSoon) } else { look.accent = i } }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                SectionTitle(text: "Размер текста · \(Int(look.fontSize))")
                SettingsGroup {
                    HStack(spacing: 12) {
                        Text("A").font(.system(size: 13))
                        Slider(value: $look.fontSize, in: 13...20, step: 1)
                        Text("A").font(.system(size: 20))
                    }
                    .padding(.vertical, 8).padding(.horizontal, 4)
                }

                SectionTitle(text: "Фон чата")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(wallAll, id: \.self) { i in
                        ChatWallpaper(index: i)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(look.wall == i ? Theme.a1 : Theme.line, lineWidth: look.wall == i ? 3 : 1))
                            .overlay { if i == 0 { Text("Без фона").font(.caption.weight(.bold)).foregroundColor(Theme.muted) } }
                            .overlay(alignment: .topTrailing) { if wallIsPremium(i) { Image(systemName: "star.fill").font(.system(size: 13)).foregroundColor(Color(hex: 0xffc247)).padding(8) } }
                            .onTapGesture { if wallIsPremium(i) && !model.isPremium { model.say(premiumSoon) } else { look.wall = i } }
                    }
                }
                .padding(.horizontal, 14)
                Color.clear.frame(height: 30)
            }
            .padding(.top, 10)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Оформление")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeButton(_ v: String, _ title: String, _ icon: String) -> some View {
        Button { look.theme = v } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(.system(size: 12.5, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .foregroundColor(look.theme == v ? .white : Theme.text)
            .background(RoundedRectangle(cornerRadius: 14).fill(look.theme == v ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color.clear)))
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
