import SwiftUI

/// Подробности функции Premium: свайп между функциями, как в Telegram
struct PremiumDetailSheet: View {
    let features: [Feat]
    @State var index: Int
    let owner: Bool
    let onBuy: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var count: Int { features.count + 1 }

    var body: some View {
        let accent = index < features.count ? Color(hex: features[index].color) : Theme.a1
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            LinearGradient(colors: [accent.opacity(0.55), accent.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 330).ignoresSafeArea(edges: .top)
                .animation(.easeInOut(duration: 0.35), value: index)
            SparkleFieldView().frame(height: 300).allowsHitTesting(false)
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { i, f in
                        page(f).tag(i)
                    }
                    listPage.tag(features.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 6) {
                    ForEach(0..<min(count, 12), id: \.self) { i in
                        let on = dot(i) == index
                        Capsule().fill(on ? accent : Theme.muted.opacity(0.35)).frame(width: on ? 18 : 6, height: 6)
                    }
                }
                .padding(.vertical, 12)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)
                ShimmerButton(title: owner ? "Открыть Premium" : "Подключить за 199 ₽ в месяц") { onBuy() }
                    .padding(.horizontal, 16).padding(.bottom, 14)
            }
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 34, height: 34).background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 14)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    /// Какую страницу выбирает точка (если страниц больше точек — равномерно)
    private func dot(_ i: Int) -> Int {
        count <= 12 ? i : Int((Double(i) / 11.0 * Double(count - 1)).rounded())
    }

    private func page(_ f: Feat) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 54)
            PhoneMock(feature: f).frame(height: 250)
            Text(f.title).font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.text)
                .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.top, 8)
            if f.soon {
                Text("в разработке").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.a1)
                    .padding(.horizontal, 8).padding(.vertical, 2).background(Theme.a1.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))
            }
            Text(f.desc).font(.system(size: 16)).foregroundColor(Theme.muted)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer(minLength: 0)
        }
    }

    /// Последняя страница — список основных возможностей со значками
    private var listPage: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 54)
            PremiumStarView(size: 96)
            Text("Lumo Premium").font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.text)
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features.prefix(5)) { f in
                    HStack(spacing: 14) {
                        Image(systemName: f.icon).font(.system(size: 18, weight: .semibold)).foregroundColor(Color(hex: f.color)).frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(f.title).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                            Text(f.desc).font(.system(size: 13.5)).foregroundColor(Theme.muted).lineLimit(2)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            Spacer(minLength: 0)
        }
    }
}

/// Рисованный телефон с «сценой» функции
struct PhoneMock: View {
    let feature: Feat
    @State private var on = false

    var body: some View {
        let c = Color(hex: feature.color)
        ZStack {
            RoundedRectangle(cornerRadius: 30).fill(Theme.panel)
                .frame(width: 150, height: 240)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Theme.text.opacity(0.18), lineWidth: 3))
                .shadow(color: c.opacity(0.35), radius: 24, y: 10)
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [c.opacity(0.30), c.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                .frame(width: 134, height: 224)
            Capsule().fill(Theme.text.opacity(0.25)).frame(width: 40, height: 6).offset(y: -104)
            scene(c).frame(width: 130, height: 200)
        }
        .scaleEffect(on ? 1 : 0.94)
        .onAppear { withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { on = true } }
    }

    private func bubble(_ w: CGFloat, mine: Bool, _ c: Color) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(mine ? AnyShapeStyle(LinearGradient(colors: [c, c.opacity(0.7)], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Theme.text.opacity(0.14)))
            .frame(width: w, height: 26)
    }

    @ViewBuilder private func scene(_ c: Color) -> some View {
        switch feature.icon {
        case "heart.circle.fill":
            VStack(alignment: .trailing, spacing: 8) {
                bubble(92, mine: false, c).frame(maxWidth: .infinity, alignment: .leading)
                bubble(80, mine: true, c)
                HStack(spacing: 4) { ForEach(["❤️", "🔥", "👍"], id: \.self) { Text($0).font(.system(size: 17)) } }
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(Theme.panel)).shadow(radius: 3)
                    .scaleEffect(on ? 1.06 : 0.96)
            }.padding(.horizontal, 6)
        case "face.smiling.inverse":
            VStack(spacing: 10) {
                Text("😍").font(.system(size: 56)).scaleEffect(on ? 1.18 : 0.92)
                HStack(spacing: 10) { Text("🔥").font(.system(size: 30)); Text("🎉").font(.system(size: 30)); Text("😂").font(.system(size: 30)) }
                    .offset(y: on ? -4 : 4)
            }
        case "photo.artframe":
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [Color(hex: 0x4d8bff), Color(hex: 0xb26bff), Color(hex: 0xff7ab6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(alignment: .trailing, spacing: 8) {
                    bubble(70, mine: false, .white).frame(maxWidth: .infinity, alignment: .leading)
                    bubble(84, mine: true, .white).opacity(0.9)
                    bubble(56, mine: false, .white).frame(maxWidth: .infinity, alignment: .leading)
                }.padding(10)
            }.frame(width: 126, height: 190)
        case "party.popper.fill":
            ZStack {
                ForEach(0..<14, id: \.self) { i in
                    Circle().fill([Color.yellow, .pink, .cyan, .orange, .green][i % 5]).frame(width: 7, height: 7)
                        .offset(x: CGFloat((i * 37) % 110) - 55, y: on ? CGFloat((i * 53) % 150) - 60 : CGFloat((i * 53) % 150) - 90)
                }
                Text("🎉").font(.system(size: 54)).scaleEffect(on ? 1.15 : 0.9)
            }
        default:
            ZStack {
                Circle().fill(c.opacity(0.25)).frame(width: on ? 118 : 96, height: on ? 118 : 96)
                Circle().fill(c).frame(width: 76, height: 76)
                Image(systemName: feature.icon).font(.system(size: 34, weight: .semibold)).foregroundColor(.white)
            }
        }
    }
}
