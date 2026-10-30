import SwiftUI
import WebKit

struct Gift: Identifiable { let id: String; let name: String; let rarity: String; let price: Int; let supply: Int; let sold: Int
    var left: Int { max(0, supply - sold) } }
struct OwnedGift: Identifiable { let id: Int; let giftId: String; let name: String; let rarity: String; let serial: Int; let supply: Int; let from: String?; var at: String? = nil; var to: String? = nil }
struct GiftTarget: Identifiable { let id: String }

func rarityName(_ r: String) -> String {
    switch r { case "rare": return "Редкий"; case "epic": return "Эпический"; case "legendary": return "Легендарный"; case "mythic": return "Мифический"; default: return r }
}
func rarityColor(_ r: String) -> Color {
    switch r { case "rare": return Color(hex: 0x22c7e0); case "epic": return Color(hex: 0xff8a3d); case "legendary": return Color(hex: 0xb069ff); case "mythic": return Color(hex: 0xffc247); default: return .gray }
}

@MainActor
final class GiftStore: ObservableObject {
    static let shared = GiftStore()
    @Published var catalog: [Gift] = []
    @Published var mine: [OwnedGift] = []
    @Published var of: [String: [OwnedGift]] = [:]

    private func parse(_ a: [JSON], owner: String?) -> [OwnedGift] {
        a.map { OwnedGift(id: $0.int("id") ?? 0, giftId: $0.str("gift_id") ?? "", name: $0.str("name") ?? "", rarity: $0.str("rarity") ?? "",
                          serial: $0.int("serial") ?? 0, supply: $0.int("supply") ?? 0, from: $0.str("from_user"), at: $0.str("at"), to: owner) }
    }

    func load() async {
        guard let a = (try? await API.shared.rpc("lm_gift_list")) as? [JSON] else { return }
        catalog = a.map { Gift(id: $0.str("id") ?? "", name: $0.str("name") ?? "", rarity: $0.str("rarity") ?? "", price: $0.int("price") ?? 0, supply: $0.int("supply") ?? 0, sold: $0.int("sold") ?? 0) }
        await loadUser(nil)
    }

    func loadUser(_ user: String?) async {
        let params: JSON = user.map { ["p_user": $0] } ?? [:]
        guard let a = (try? await API.shared.rpc("lm_gift_mine", params)) as? [JSON] else { return }
        let l = parse(a, owner: user ?? AppModel.shared.myId)
        if user == nil { mine = l }
        of[user ?? ""] = l
    }

    func buy(_ id: String, to: String?) async throws -> Int {
        var params: JSON = ["p_gift": id]
        if let t = to { params["p_to"] = t }
        let r = try await API.shared.rpc("lm_gift_buy", params) as? JSON
        await Lumens.shared.load()
        await load()
        if let t = to { await loadUser(t) }
        return r?.int("serial") ?? 0
    }
}

struct GiftThumb: View {
    let id: String
    var body: some View {
        Group {
            if let u = Bundle.main.url(forResource: "gift_" + id, withExtension: "png"), let img = UIImage(contentsOfFile: u.path) {
                Image(uiImage: img).resizable().scaledToFill()
            } else { Color.gray.opacity(0.3) }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct GiftWebView: UIViewRepresentable {
    let id: String
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView(frame: .zero)
        w.isOpaque = false; w.backgroundColor = .clear; w.scrollView.backgroundColor = .clear
        w.scrollView.isScrollEnabled = false; w.isUserInteractionEnabled = false
        var svg = ""
        if let u = Bundle.main.url(forResource: "gift_" + id, withExtension: "svg"), let s = try? String(contentsOf: u, encoding: .utf8) { svg = s }
        let html = "<html><head><meta name='viewport' content='width=device-width,initial-scale=1'><style>html,body{margin:0;height:100%;background:transparent;overflow:hidden}svg{width:100%;height:100%;display:block}</style></head><body>\(svg)</body></html>"
        w.loadHTMLString(html, baseURL: nil)
        return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct GiftAnimated: View {
    let id: String
    var body: some View {
        GiftWebView(id: id).aspectRatio(1, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

struct RarityBadge: View {
    let r: String
    var body: some View {
        Text(rarityName(r).uppercased()).font(.system(size: 10.5, weight: .bold)).foregroundColor(rarityColor(r))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 10).fill(rarityColor(r).opacity(0.18)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(rarityColor(r).opacity(0.6), lineWidth: 1))
    }
}

private func giftGlassBG() -> some View {
    ZStack {
        LinearGradient(colors: [Color(hex: 0x1a1030), Color(hex: 0x0b0a18)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        Circle().fill(Color(hex: 0xff9a3d).opacity(0.45)).frame(width: 300).blur(radius: 70).offset(x: -110, y: -220)
        Circle().fill(Color(hex: 0x7c5cff).opacity(0.5)).frame(width: 340).blur(radius: 80).offset(x: 120, y: 260)
    }
}

struct GiftDetailSheet: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var lumens = Lumens.shared
    @ObservedObject private var store = GiftStore.shared
    @Environment(\.dismiss) private var dismiss
    let gift: Gift
    var to: String? = nil
    var onDone: (() -> Void)? = nil
    @State private var busy = false
    @State private var done: Int?
    private var owner: Bool { model.staffRole == "owner" }
    private var cur: Gift { store.catalog.first { $0.id == gift.id } ?? gift }

    var body: some View {
        ZStack {
            giftGlassBG()
            ScrollView {
                VStack(spacing: 12) {
                    GiftAnimated(id: gift.id).padding(.top, 20)
                    if let n = done {
                        Text("Готово!").font(.system(size: 26, weight: .black)).foregroundColor(.white)
                        Text(to != nil ? "\(gift.name) №\(n) подарен: \(model.displayName(to))" : "\(gift.name) №\(n) теперь у вас")
                            .foregroundColor(.white.opacity(0.85)).multilineTextAlignment(.center)
                    } else {
                        Text(gift.name).font(.system(size: 24, weight: .black)).foregroundColor(.white)
                        RarityBadge(r: gift.rarity)
                        Text("Осталось \(cur.left) из \(cur.supply)").font(.system(size: 13)).foregroundColor(.white.opacity(0.75))
                        if let t = to { Text("Получатель: \(model.displayName(t))").font(.system(size: 13)).foregroundColor(.white.opacity(0.75)) }
                        Button { buy() } label: {
                            ZStack {
                                if busy { ProgressView().tint(.white) }
                                else if cur.left <= 0 { Text("Раскуплено").font(.system(size: 17, weight: .bold)).foregroundColor(.white) }
                                else {
                                    HStack(spacing: 6) {
                                        Text(to != nil ? "Подарить за" : "Купить за").font(.system(size: 17, weight: .bold))
                                        Text(owner ? "0" : "\(gift.price)").font(.system(size: 17, weight: .black))
                                        LumenGem(size: 20)
                                    }.foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(cur.left > 0 ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color.gray.opacity(0.4)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
                        }
                        .disabled(busy || cur.left <= 0)
                        Text(owner ? "Вы владелец: подарки не списывают люмены" : "На вашем счёте: \(lumens.balance) \(lumenWord(lumens.balance))")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                        Button("Закрыть") { dismiss() }.font(.system(size: 15)).foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(20)
            }
            .opacity(done == nil ? 1 : 0)
        }
        .overlay {
            if let n = done {
                GiftCelebration(giftId: gift.id, to: to, name: gift.name, serial: n, supply: gift.supply) { dismiss(); onDone?() }
                    .environmentObject(model).transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .task { await lumens.load() }
    }

    private func buy() {
        guard !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                let n = try await store.buy(gift.id, to: to)
                withAnimation(.easeIn(duration: 0.25)) { done = n }
            } catch { model.say(error.localizedDescription) }
        }
    }
}

struct OwnedGiftSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let o: OwnedGift
    @ObservedObject private var store = GiftStore.shared
    private var price: Int? { store.catalog.first { $0.id == o.giftId }?.price }
    private var toId: String? { o.to ?? model.myId }
    private var fromId: String? { o.from ?? toId }
    private var isMine: Bool { toId == model.myId }
    private var titleText: String { isMine ? (fromId == model.myId ? "Ваш подарок" : "Подарок Вам") : "Подарок для " + model.displayName(toId) }
    private var dateText: String {
        guard let s = o.at else { return "—" }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "UTC"); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let d = f.date(from: String(s.prefix(19))) else { return "—" }
        let o = DateFormatter(); o.locale = Locale(identifier: "ru_RU"); o.dateFormat = "dd.MM.yyyy 'в' HH:mm"
        return o.string(from: d)
    }
    private func row(_ label: String, @ViewBuilder _ content: () -> some View) -> some View {
        HStack(spacing: 0) {
            Text(label).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                .frame(width: 120).background(Theme.panel2)
            HStack(spacing: 6) { content() }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
        }
    }
    var body: some View {
        VStack(spacing: 8) {
            Color.clear.frame(height: 0).task { if store.catalog.isEmpty { await store.load() } }
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 42, height: 42).background(Theme.panel2, in: Circle())
                }
                Spacer()
            }
            GiftAnimated(id: o.giftId).frame(width: 220, height: 220)
            Text(titleText).font(.system(size: 24, weight: .black)).foregroundColor(Theme.text)
            Text("\(o.name) №\(o.serial) из \(o.supply) · \(rarityName(o.rarity))").font(.system(size: 15, weight: .semibold))
                .foregroundColor(rarityColor(o.rarity)).multilineTextAlignment(.center)
            Text(isMine ? "Подарок хранится в вашем профиле." : "Подарок хранится в профиле получателя.").font(.system(size: 14)).foregroundColor(Theme.muted)
            VStack(spacing: 0) {
                row("От") {
                    if let f = fromId, f != model.myId {
                        let pr = model.profiles[f]
                        AvatarView(name: pr?.name ?? model.displayName(f), url: pr?.avatarURL, color: pr?.color ?? 0, size: 30)
                        Text(model.displayName(f)).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.a1).lineLimit(1)
                    } else { Text("Вы").font(.system(size: 16)).foregroundColor(Theme.text) }
                }
                Divider().overlay(Theme.line)
                row("Дата") { Text(dateText).font(.system(size: 16)).foregroundColor(Theme.text) }
                Divider().overlay(Theme.line)
                row("Стоимость") {
                    if let p = price { Text("\(p)").font(.system(size: 16)).foregroundColor(Theme.text); LumenGem(size: 18); Text(lumenWord(p)).font(.system(size: 16)).foregroundColor(Theme.text) }
                    else { Text("—").foregroundColor(Theme.text) }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
            .padding(.top, 6)
            Button { dismiss() } label: {
                Text("OK").font(.system(size: 17, weight: .black)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.top, 6)
        }
        .padding(18)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.panel.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct OwnedGrid: View {
    let list: [OwnedGift]
    let onTap: (OwnedGift) -> Void
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(list) { o in
                Button { onTap(o) } label: {
                    VStack(spacing: 4) {
                        GiftThumb(id: o.giftId)
                        Text("№\(o.serial)").font(.system(size: 12, weight: .bold)).foregroundColor(rarityColor(o.rarity))
                    }
                    .padding(6).background(Theme.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }.buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(.horizontal, 14)
    }
}

private struct CatalogGrid: View {
    @ObservedObject var store = GiftStore.shared
    var onlyRare = false
    let onPick: (Gift) -> Void
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(store.catalog.filter { !onlyRare || $0.rarity != "common" }) { g in
                Button { onPick(g) } label: {
                    VStack(spacing: 6) {
                        GiftThumb(id: g.id)
                        Text(g.name).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                        RarityBadge(r: g.rarity)
                        HStack(spacing: 4) {
                            LumenGem(size: 16)
                            Text(g.left > 0 ? "\(g.price)" : "Раскуплено").font(.system(size: 15, weight: .black)).foregroundColor(Theme.text)
                        }
                        Text("\(g.left) из \(g.supply)").font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                    .padding(10).frame(maxWidth: .infinity)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }.buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(.horizontal, 14)
    }
}

/// Раздел «Подарки»: каталог и мои подарки
struct GiftsView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var store = GiftStore.shared
    @ObservedObject private var lumens = Lumens.shared
    @State private var pick: Gift?
    @State private var view: OwnedGift?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    LumenGem(size: 22)
                    Text("\(lumens.balance) \(lumenWord(lumens.balance))").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                }.padding(.horizontal, 18)
                Text("Редкие подарки с ограниченным тиражом. Купите себе или подарите другу из его профиля.")
                    .font(.system(size: 14)).foregroundColor(Theme.muted).padding(.horizontal, 18)
                CatalogGrid { pick = $0 }
                if !store.mine.isEmpty {
                    Text("МОИ ПОДАРКИ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).padding(.horizontal, 20).padding(.top, 10)
                    OwnedGrid(list: store.mine) { view = $0 }
                }
            }
            .padding(.vertical, 10).padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Подарки").navigationBarTitleDisplayMode(.inline)
        .task { await store.load(); await lumens.load() }
        .sheet(item: $pick) { g in GiftDetailSheet(gift: g).environmentObject(model) }
        .sheet(item: $view) { o in OwnedGiftSheet(o: o).environmentObject(model) }
    }
}

/// Выбор подарка для человека: Premium в подарок и каталог подарков
struct GiftShopSheet: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var lumens = Lumens.shared
    @Environment(\.dismiss) private var dismiss
    let user: String
    @State private var pick: Gift?
    @State private var info = false
    @State private var rare = false
    var body: some View {
        let name = model.displayName(user)
        let pr = model.profiles[user]
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    ZStack { StarSparkles().frame(width: 300, height: 170)
                        AvatarView(name: name, url: pr?.avatarURL, color: pr?.color ?? 0, size: 104) }
                        .padding(.top, 50)
                    Text("Подарить Premium").font(.system(size: 28, weight: .black)).foregroundColor(Theme.text)
                    Text("Подарите \(name) доступ к дополнительным функциям Lumo.")
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 28)
                    HStack(spacing: 10) {
                        ForEach(Array([("3 месяца", Color(hex: 0x4CAF50), ""), ("6 месяцев", Color(hex: 0x22A6FF), "-35%"), ("1 год", Color(hex: 0xFF5B5B), "-40%")].enumerated()), id: \.offset) { _, t in
                            Button { model.say("Подарок Premium в разработке") } label: {
                                VStack(spacing: 4) {
                                    Text("🎁").font(.system(size: 36)).frame(width: 64, height: 64)
                                        .background(t.1.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    Text(t.0).font(.system(size: 15, weight: .black)).foregroundColor(Theme.text).padding(.top, 4)
                                    Text("Premium").font(.system(size: 13)).foregroundColor(Theme.muted)
                                    Text("Скоро").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.a1)
                                        .padding(.horizontal, 12).padding(.vertical, 5).background(Theme.a1.opacity(0.15), in: Capsule()).padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    if !t.2.isEmpty {
                                        Text(t.2).font(.system(size: 10.5, weight: .black)).foregroundColor(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(LinearGradient(colors: [Theme.a1, Color(hex: 0xB069FF)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 8))
                                            .padding(6)
                                    }
                                }
                            }.buttonStyle(BouncyButtonStyle())
                        }
                    }
                    .padding(.horizontal, 14).padding(.top, 6)
                    Text("Оплата Premium ещё в разработке: как только она заработает, подарок можно будет отправить прямо отсюда.")
                        .font(.system(size: 12)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 24)
                    Text("Отправить подарок").font(.system(size: 26, weight: .black)).foregroundColor(Theme.text).padding(.top, 22)
                    Text("Дарите \(name) подарки, которые можно хранить в профиле.")
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 28)
                    Button { info = true } label: { Text("Подробнее о люменах ›").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.a1) }
                    HStack(spacing: 8) {
                        chip("Все", !rare) { rare = false }
                        chip("Коллекционные", rare) { rare = true }
                    }
                    CatalogGrid(onlyRare: rare) { pick = $0 }.padding(.bottom, 30)
                }
            }
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 44, height: 44).background(Theme.panel, in: Circle())
                }.buttonStyle(BouncyButtonStyle())
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Баланс").font(.system(size: 13)).foregroundColor(Theme.muted)
                    HStack(spacing: 4) { LumenGem(size: 18); Text("\(lumens.balance)").font(.system(size: 16, weight: .black)).foregroundColor(Theme.text) }
                }
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .task { await GiftStore.shared.load(); await Lumens.shared.load() }
        .sheet(item: $pick) { g in GiftDetailSheet(gift: g, to: user, onDone: { dismiss() }).environmentObject(model) }
        .sheet(isPresented: $info) { LumenInfoSheet().presentationDetents([.large]) }
    }

    private func chip(_ t: String, _ on: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.system(size: 15, weight: .semibold)).foregroundColor(on ? Theme.text : Theme.muted)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(on ? Theme.line : Color.clear, in: Capsule())
        }.buttonStyle(BouncyButtonStyle()).animation(.spring(response: 0.3, dampingFraction: 0.7), value: on)
    }
}

/// Мерцающие звёздочки за аватаром
struct StarSparkles: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let ph = tl.date.timeIntervalSinceReferenceDate / 2.6
            Canvas { ctx, size in
                var g = SeededGen(seed: 7)
                for i in 0..<34 {
                    let x = g.next() * size.width, y = g.next() * size.height, s = 3 + g.next() * 7
                    let a = (sin((ph + Double(i) * 0.13) * 6.283) + 1) / 2 * 0.8 + 0.1
                    var p = Path(); p.move(to: CGPoint(x: x - s, y: y)); p.addLine(to: CGPoint(x: x + s, y: y)); p.move(to: CGPoint(x: x, y: y - s)); p.addLine(to: CGPoint(x: x, y: y + s))
                    ctx.stroke(p, with: .color(Color(hex: 0xFFB020).opacity(a)), lineWidth: 1.6)
                }
            }
        }
    }
}
private struct SeededGen {
    var s: UInt64
    init(seed: UInt64) { s = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> CGFloat { s = s &* 6364136223846793005 &+ 1442695040888963407; return CGFloat((s >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF) }
}

/// «Для чего нужны люмены?»
struct LumenInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 10) {
            ZStack { StarSparkles().frame(width: 280, height: 140); LumenGem(size: 84) }.padding(.top, 10)
            Text("Для чего нужны люмены?").font(.system(size: 22, weight: .black)).foregroundColor(Theme.text)
            Text("Возможности люменов Lumo:").font(.system(size: 14)).foregroundColor(Theme.muted)
            VStack(alignment: .leading, spacing: 16) {
                row("gift", "Подарки друзьям", "Дарите друзьям подарки, которые они смогут добавить в профиль.")
                row("paperplane", "Переводы в чате", "Отправляйте люмены другу прямо в переписке.")
                row("lock", "Платные сообщения", "Установите цену, и незнакомцы смогут написать вам только за люмены.")
                row("star", "Ежедневный бонус", "Заходите каждый день и получайте люмены, серия увеличивает награду.")
            }
            .padding(.horizontal, 22).padding(.top, 10)
            Spacer()
            Button { dismiss() } label: {
                Text("OK").font(.system(size: 17, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [Theme.a1, Theme.a2], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }.buttonStyle(BouncyButtonStyle()).padding(.horizontal, 20).padding(.bottom, 14)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
    private func row(_ icon: String, _ t: String, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(Theme.a1).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(t).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                Text(d).font(.system(size: 14)).foregroundColor(Theme.muted)
            }
        }
    }
}

/// Подарки человека в его профиле
struct ProfileGiftsRow: View {
    @ObservedObject private var store = GiftStore.shared
    @EnvironmentObject var model: AppModel
    let userId: String
    @State private var view: OwnedGift?
    var body: some View {
        Group {
            let l = store.of[userId] ?? []
            if !l.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ПОДАРКИ · \(l.count)").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).padding(.horizontal, 6)
                    OwnedGrid(list: Array(l.prefix(6))) { view = $0 }.padding(.horizontal, -14)
                }
            }
        }
        .task { await store.loadUser(userId) }
        .sheet(item: $view) { o in OwnedGiftSheet(o: o).environmentObject(model) }
    }
}

/// Подарок в переписке: плашка «кто отправил» и карточка с подарком
struct GiftMessageCard: View {
    @EnvironmentObject var model: AppModel
    let m: Message
    let chat: ChatItem?
    @State private var open: OwnedGift?
    private var mine: Bool { m.senderId == model.myId }
    var body: some View {
        let gid = m.meta.str("gift_id") ?? ""
        let name = m.meta.str("name") ?? ""
        let rarity = m.meta.str("rarity") ?? ""
        let serial = m.meta.int("serial") ?? 0
        let supply = m.meta.int("supply") ?? 0
        let price = m.meta.int("price") ?? 0
        let c = rarityColor(rarity)
        let who = mine ? "Вы отправили подарок: \(model.displayName(chat?.peerId))" : "\(model.displayName(m.senderId)) отправил(а) Вам подарок"
        VStack(spacing: 10) {
            Text("\(who) стоимостью \(price) \(lumenWord(price))")
                .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                .padding(.horizontal, 14).padding(.vertical, 6).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            VStack(spacing: 6) {
                GiftThumb(id: gid).frame(width: 150, height: 150)
                Text("Подарок").font(.system(size: 18, weight: .black)).foregroundColor(Theme.text).padding(.top, 4)
                Text("\(name) №\(serial) из \(supply)").font(.system(size: 14, weight: .bold)).foregroundColor(c).multilineTextAlignment(.center)
                Text(mine ? "Подарок появится в профиле получателя." : "Подарок добавлен в ваш профиль.")
                    .font(.system(size: 13)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                Button { open = OwnedGift(id: 0, giftId: gid, name: name, rarity: rarity, serial: serial, supply: supply, from: m.senderId, to: mine ? chat?.peerId : model.myId) } label: {
                    Text("Посмотреть").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .padding(.horizontal, 26).padding(.vertical, 10).background(Capsule().fill(c.opacity(0.3)))
                }.padding(.top, 6)
            }
            .padding(16).frame(width: 250)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(LinearGradient(colors: [c.opacity(0.35), Theme.panel], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(c.opacity(0.45), lineWidth: 1))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .sheet(item: $open) { o in OwnedGiftSheet(o: o).environmentObject(model) }
    }
}
