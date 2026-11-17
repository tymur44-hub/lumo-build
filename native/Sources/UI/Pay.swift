import SwiftUI
import WebKit

// MARK: - Оплата внутри Lumo
// Окно оплаты открывается поверх любого экрана, без адресной строки и кнопок браузера — только крестик.
// После оплаты ЮMoney возвращает на lumomess.ru/?lumo_paid=1 — окно закрывается само,
// а статус заказа проверяется, пока люмены или Premium не будут зачислены.

let payReturnURL = "https://lumomess.ru/?lumo_paid=1"
let lumenRate = 1.7

func rub(_ v: Double) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal; f.locale = Locale(identifier: "ru_RU")
    f.maximumFractionDigits = v.rounded() == v ? 0 : 2; f.minimumFractionDigits = f.maximumFractionDigits
    return (f.string(from: NSNumber(value: v)) ?? "\(v)") + " ₽"
}

@MainActor
final class Pay {
    static let shared = Pay()
    private var watching = Set<String>()
    private weak var shown: UIViewController?

    /// Создаёт заказ (люмены или Premium) и открывает окно оплаты
    func buy(kind: String, qty: Int, to: String? = nil) async {
        do {
            var body: JSON = ["action": "create", "kind": kind, "qty": qty, "return_url": payReturnURL]
            if let t = to { body["to"] = t }
            let r = try await API.shared.function("-yoomoney", body: body) as? JSON
            guard let s = r?.str("url"), let u = URL(string: s) else {
                AppModel.shared.say(r?.str("error") ?? "Не удалось создать платёж"); return
            }
            open(u, order: r?.str("order_id"), to: to)
        } catch {
            AppModel.shared.say((error as? APIError)?.message ?? "Не удалось создать платёж, проверьте соединение")
        }
    }

    func open(_ url: URL, order: String?, to: String? = nil) {
        let host = UIHostingController(rootView: PaySheet(url: url) { [weak self] paid in self?.close(paid: paid) })
        host.modalPresentationStyle = .pageSheet
        if let sc = host.sheetPresentationController { sc.detents = [.large()]; sc.prefersGrabberVisible = false; sc.preferredCornerRadius = 22 }
        var top = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
        while let p = top?.presentedViewController, !p.isBeingDismissed { top = p }
        top?.present(host, animated: true)
        shown = host
        if let o = order { watch(o, to: to) }
    }

    /// Окно выбора срока Premium поверх любого экрана
    func showPlans(to: String? = nil, months: Int = 12) {
        let host = UIHostingController(rootView: PremiumPlansSheet(to: to, sel: months).environmentObject(AppModel.shared))
        host.modalPresentationStyle = .pageSheet
        var top = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
        while let p = top?.presentedViewController, !p.isBeingDismissed { top = p }
        top?.present(host, animated: true)
    }

    private func close(paid: Bool) {
        shown?.dismiss(animated: true)
        shown = nil
        if paid { AppModel.shared.say("Платёж принят. Зачисляем…") }
    }

    /// Проверяем заказ, пока он не оплачен (до 20 минут)
    private func watch(_ order: String, to: String?) {
        guard watching.insert(order).inserted else { return }
        Task { @MainActor in
            defer { watching.remove(order) }
            for _ in 0..<400 {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard let j = (try? await API.shared.rpc("lm_pay_status", ["p_order": order])) as? JSON else { continue }
                if j.str("status") == "paid" {
                    let qty = j.int("qty") ?? 0
                    if j.str("kind") == "prem" {
                        await AppModel.shared.loadMe()
                        AppModel.shared.say(to == nil ? "Оплата прошла. Lumo Premium активирован" : "Оплата прошла. Premium подарен")
                    } else {
                        AppModel.shared.say("Оплата прошла. Начислено \(qty) \(lumenWord(qty))")
                    }
                    await Lumens.shared.load()
                    NotificationCenter.default.post(name: .lumoPaid, object: nil)
                    return
                }
                if j.str("status") == "unknown" { return }
            }
        }
    }
}

extension Notification.Name { static let lumoPaid = Notification.Name("lumoPaid") }

// MARK: - Окно оплаты

private final class PayWebModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var progress: Double = 0.05
    @Published var loading = true
    var onPaid: (() -> Void)?
    let web: WKWebView

    override init() {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.websiteDataStore = .default()
        web = WKWebView(frame: .zero, configuration: cfg)
        super.init()
        web.navigationDelegate = self
        web.uiDelegate = self
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    deinit { web.removeObserver(self, forKeyPath: "estimatedProgress") }

    override func observeValue(forKeyPath k: String?, of o: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        progress = web.estimatedProgress
    }

    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let u = a.request.url else { decisionHandler(.allow); return }
        // возврат после оплаты — закрываем окно
        if (u.host ?? "").hasSuffix("lumomess.ru") && u.absoluteString.contains("lumo_paid") {
            decisionHandler(.cancel); onPaid?(); return
        }
        // приложения банков (СБП, SberPay и т.п.) — открываем их
        if let s = u.scheme?.lowercased(), s != "http", s != "https", s != "about", s != "data", s != "blob" {
            decisionHandler(.cancel)
            UIApplication.shared.open(u)
            return
        }
        decisionHandler(.allow)
    }
    // ссылки «в новом окне» открываем здесь же
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
        if a.targetFrame == nil, let u = a.request.url { w.load(URLRequest(url: u)) }
        return nil
    }
    func webView(_ w: WKWebView, didStartProvisionalNavigation n: WKNavigation!) { loading = true }
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { loading = false }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { loading = false }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { loading = false }
}

private struct PayWebRep: UIViewRepresentable {
    let m: PayWebModel
    func makeUIView(context: Context) -> WKWebView { m.web }
    func updateUIView(_ v: WKWebView, context: Context) {}
}

struct PaySheet: View {
    let url: URL
    let onClose: (Bool) -> Void
    @StateObject private var m = PayWebModel()
    @State private var started = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(spacing: 1) {
                    Text("Оплата").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                        Text("Банковская карта · ЮMoney").font(.system(size: 12))
                    }.foregroundColor(Theme.muted)
                }
                HStack {
                    Button { onClose(false) } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                            .frame(width: 36, height: 36).background(Circle().fill(Theme.panel2))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    Spacer()
                }
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)
            ZStack(alignment: .top) {
                PayWebRep(m: m).opacity(m.loading && m.progress < 0.3 ? 0 : 1)
                if m.loading && m.progress < 0.3 {
                    VStack(spacing: 14) {
                        LumenLive(size: 46)
                        Text("Открываем оплату…").font(.system(size: 15)).foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if m.loading {
                    GeometryReader { g in
                        Capsule().fill(Theme.accent).frame(width: g.size.width * max(0.05, m.progress), height: 2.5)
                            .animation(.easeOut(duration: 0.25), value: m.progress)
                    }.frame(height: 2.5)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            guard !started else { return }
            started = true
            m.onPaid = { onClose(true) }
            m.web.load(URLRequest(url: url))
        }
    }
}

// MARK: - Раздел «Люмены» (как «Звёзды» в Telegram)

struct WalletView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var lumens = Lumens.shared
    @State private var rows: [LedgerRow] = []
    @State private var tab = 0
    @State private var busy = false
    @State private var buy = false
    @State private var pickFriend = false
    @State private var sendTo: LumenTarget?
    @State private var loaded = false

    private var shown: [LedgerRow] { tab == 1 ? rows.filter { $0.delta > 0 } : tab == 2 ? rows.filter { $0.delta < 0 } : rows }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xffb347).opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 110))
                        .frame(width: 220, height: 220)
                    LumenLive(size: 66)
                }
                .frame(height: 150).padding(.top, 2)
                VStack(spacing: 6) {
                    Text("Люмены Lumo").font(.system(size: 27, weight: .heavy)).foregroundColor(Theme.text)
                    Text("Покупайте люмены, чтобы дарить подарки, поддерживать авторов и каналы и отправлять их друзьям.")
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 28)
                }
                balanceCard
                Button { pickFriend = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill").font(.system(size: 14, weight: .semibold))
                        Text("Подарить люмены друзьям").font(.system(size: 15.5, weight: .semibold))
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                    }.foregroundColor(Theme.a1)
                }
                .buttonStyle(BouncyButtonStyle()).padding(.vertical, 2)
                earnCard
                payInfo
                segmented.padding(.top, 6)
                history
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .task { await lumens.load(); await reload() }
        .onReceive(NotificationCenter.default.publisher(for: .lumoPaid)) { _ in Task { await reload() } }
        .sheet(isPresented: $buy) { BuyLumensSheet().environmentObject(model) }
        .sheet(isPresented: $pickFriend) {
            PeoplePicker(title: "Кому отправить люмены", buttonTitle: "Далее") { ids in
                guard let id = ids.first else { return }
                Task { try? await Task.sleep(nanoseconds: 450_000_000); sendTo = LumenTarget(id: id) }
            }
            .environmentObject(model)
        }
        .sheet(item: $sendTo, onDismiss: { Task { await reload() } }) { t in SendLumensSheet(userId: t.id).environmentObject(model) }
    }

    private var balanceCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                LumenGem(size: 34)
                Text("\(lumens.balance)").font(.system(size: 42, weight: .heavy)).foregroundColor(Theme.text)
                    .contentTransition(.numericText()).animation(.spring(), value: lumens.balance)
            }
            Text("Ваш баланс").font(.system(size: 15)).foregroundColor(Theme.muted).padding(.top, -6)
            HStack(spacing: 10) {
                Button { buy = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                        Text("Пополнить").font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 48)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(BouncyButtonStyle())
                Button { claim() } label: {
                    HStack(spacing: 6) {
                        if busy { ProgressView() } else {
                            Image(systemName: lumens.canClaim ? "sparkles" : "checkmark").font(.system(size: 15, weight: .bold))
                            Text(lumens.canClaim ? "Бонус дня" : "Бонус получен").font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(lumens.canClaim ? Theme.a1 : Theme.muted).frame(maxWidth: .infinity).frame(height: 48)
                    .background(Theme.a1.opacity(lumens.canClaim ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(BouncyButtonStyle()).disabled(!lumens.canClaim || busy)
            }
        }
        .padding(16).frame(maxWidth: .infinity)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var earnCard: some View {
        VStack(spacing: 0) {
            row(icon: "calendar", color: 0xff9a3d, title: "Ежедневный бонус",
                sub: lumens.streak > 0 ? "Серия \(lumens.streak) дн. подряд — завтра +\(min(3 + lumens.streak, 10))" : "Заходите каждый день — до 10 люменов в день")
            Divider().overlay(Theme.line).padding(.leading, 62)
            row(icon: "heart.fill", color: 0xff5e8a, title: "Поддержка от читателей", sub: "Люмены за ваши сообщения и посты в каналах")
            Divider().overlay(Theme.line).padding(.leading, 62)
            row(icon: "gamecontroller.fill", color: 0x7c5cff, title: "Игры с друзьями", sub: "Ставки и выигрыши в играх Lumo")
        }
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("ЗАРАБОТАТЬ ЛЮМЕНЫ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).offset(x: 14, y: -20)
        }
        .padding(.top, 18)
    }

    private var payInfo: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x2bd67b)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Оплата работает").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                Text("Банковской картой через ЮMoney. Люмены и Premium зачисляются автоматически, обычно за минуту.")
                    .font(.system(size: 13)).foregroundColor(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(14).background(Theme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func row(icon: String, color: UInt32, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: color)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15.5, weight: .semibold)).foregroundColor(Theme.text)
                Text(sub).font(.system(size: 13)).foregroundColor(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    private var segmented: some View {
        HStack(spacing: 4) {
            ForEach(Array(["Все операции", "Зачисления", "Списания"].enumerated()), id: \.offset) { i, t in
                Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { tab = i } } label: {
                    Text(t).font(.system(size: 14, weight: .semibold)).foregroundColor(tab == i ? Theme.text : Theme.muted)
                        .frame(maxWidth: .infinity).frame(height: 34)
                        .background { if tab == i { Capsule().fill(Theme.panel).shadow(color: .black.opacity(0.08), radius: 3, y: 1) } }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3).background(Capsule().fill(Theme.panel2))
    }

    @ViewBuilder private var history: some View {
        if shown.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath").font(.system(size: 28)).foregroundColor(Theme.muted.opacity(0.6))
                Text(loaded ? "Операций пока нет" : "Загрузка…").font(.system(size: 15)).foregroundColor(Theme.muted)
            }.frame(maxWidth: .infinity).padding(.vertical, 28)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, r in
                    if i > 0 { Divider().overlay(Theme.line).padding(.leading, 70) }
                    HStack(spacing: 12) {
                        icon(r)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title(r)).font(.system(size: 15.5, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                            if let s = sub(r) { Text(s).font(.system(size: 13)).foregroundColor(Theme.muted).lineLimit(1) }
                            Text(r.at.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                        }
                        Spacer(minLength: 4)
                        Text((r.delta > 0 ? "+" : "−") + "\(abs(r.delta))").font(.system(size: 16.5, weight: .bold))
                            .foregroundColor(r.delta > 0 ? Color(hex: 0x2bc46f) : Color(hex: 0xff4d6a))
                        LumenGem(size: 17)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .transition(.opacity)
                }
            }
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    @ViewBuilder private func icon(_ r: LedgerRow) -> some View {
        if let u = r.refUser {
            AvatarView(name: model.displayName(u), url: model.profiles[u]?.avatarURL, color: model.profiles[u]?.color ?? 0, size: 44)
        } else {
            let k = kindIcon(r.kind)
            Image(systemName: k.0).font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                .frame(width: 44, height: 44).background(Circle().fill(LinearGradient(colors: [Color(hex: k.1), Color(hex: k.2)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        }
    }

    private func kindIcon(_ k: String) -> (String, UInt32, UInt32) {
        switch k {
        case "buy": return ("creditcard.fill", 0x2bd67b, 0x18a957)
        case "daily": return ("calendar", 0xffb347, 0xff7a3d)
        case "gift_buy", "gift_sell": return ("gift.fill", 0xff7ab8, 0xc65cff)
        case "game_win", "game_stake", "game_refund": return ("gamecontroller.fill", 0x8a7bff, 0x5b5cff)
        default: return ("sparkles", 0x36b8ff, 0x3a7bff)
        }
    }

    private func title(_ r: LedgerRow) -> String {
        switch r.kind {
        case "tip_in", "tip_out": return r.refUser.map { model.displayName($0) } ?? "Пользователь"
        case "buy": return "Покупка люменов"
        case "daily": return "Ежедневный бонус"
        case "grant": return "Начисление от Lumo"
        case "gift_buy": return "Покупка подарка"
        case "gift_sell": return "Продажа подарка"
        case "game_win": return "Выигрыш в игре"
        case "game_stake": return "Ставка в игре"
        case "game_refund": return "Возврат ставки"
        default: return "Операция"
        }
    }

    private func sub(_ r: LedgerRow) -> String? {
        switch r.kind {
        case "tip_in": return "Отправил(а) вам люмены"
        case "tip_out": return "Вы отправили люмены"
        case "buy": return "Оплата картой"
        default: return nil
        }
    }

    private func reload() async {
        let a = await lumens.history()
        await model.loadProfiles(a.compactMap { $0.refUser })
        withAnimation { rows = a; loaded = true }
    }

    private func claim() {
        busy = true
        Task {
            defer { busy = false }
            do { let n = try await lumens.claim(); model.say("Получено: \(n) \(lumenWord(n))"); await reload() }
            catch { model.say(error.localizedDescription) }
        }
    }
}

/// Стопка кристаллов — чем больше пакет, тем больше кристаллов
struct GemStack: View {
    let n: Int
    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(0..<n, id: \.self) { i in LumenGem(size: 24).offset(x: CGFloat(i) * 7).zIndex(Double(n - i)) }
        }
        .frame(width: 24 + CGFloat(max(0, n - 1)) * 7, alignment: .leading)
    }
}

// MARK: - Покупка люменов

struct BuyLumensSheet: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var lumens = Lumens.shared
    @Environment(\.dismiss) private var dismiss
    @State private var more = false
    @State private var busy: Int?
    @State private var custom = ""
    @FocusState private var focus: Bool

    static let packs: [(Int, Int)] = [(50, 1), (100, 2), (250, 3), (500, 4), (1000, 5), (2500, 6)]
    static let extra: [(Int, Int)] = [(1500, 5), (5000, 7)]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                            .frame(width: 36, height: 36).background(Circle().fill(Theme.panel2))
                    }.buttonStyle(BouncyButtonStyle())
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Баланс").font(.system(size: 12)).foregroundColor(Theme.muted)
                        HStack(spacing: 4) { LumenGem(size: 15); Text("\(lumens.balance)").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text) }
                    }
                }
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xffb347).opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 90)).frame(width: 180, height: 180)
                    LumenLive(size: 54)
                }.frame(height: 120)
                Text("Купить люмены").font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.text)
                Text("Выберите нужное количество").font(.system(size: 15)).foregroundColor(Theme.muted).padding(.bottom, 6)
                VStack(spacing: 0) {
                    let list = more ? (Self.packs + Self.extra).sorted { $0.0 < $1.0 } : Self.packs
                    ForEach(Array(list.enumerated()), id: \.element.0) { i, p in
                        if i > 0 { Divider().overlay(Theme.line).padding(.leading, 16) }
                        packRow(p.0, gems: p.1)
                    }
                }
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                if !more {
                    Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { more = true } } label: {
                        HStack(spacing: 5) {
                            Text("Показать другие варианты").font(.system(size: 15, weight: .semibold))
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
                        }.foregroundColor(Theme.a1).padding(.vertical, 6)
                    }
                } else {
                    customRow.transition(.opacity.combined(with: .move(edge: .top)))
                }
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.shield.fill").foregroundColor(Color(hex: 0x2bd67b))
                    Text("Оплата банковской картой через ЮMoney прямо в Lumo. Люмены зачисляются автоматически, обычно за минуту. 1 люмен = 1,7 ₽.")
                        .font(.system(size: 13)).foregroundColor(Theme.muted)
                }
                .padding(.horizontal, 6).padding(.top, 6)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .task { await lumens.load() }
    }

    private func packRow(_ n: Int, gems: Int) -> some View {
        Button { pay(n) } label: {
            HStack(spacing: 12) {
                GemStack(n: gems).frame(width: 70, alignment: .leading)
                Text("\(n.formatted()) \(lumenWord(n))").font(.system(size: 16.5, weight: .semibold)).foregroundColor(Theme.text)
                Spacer()
                if busy == n { ProgressView() } else {
                    Text(rub(Double(n) * lumenRate)).font(.system(size: 15.5, weight: .medium)).foregroundColor(Theme.muted)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14).contentShape(Rectangle())
        }
        .buttonStyle(RowButtonStyle()).disabled(busy != nil)
    }

    private var customRow: some View {
        let n = Int(custom) ?? 0
        let ok = n >= 50 && Double(n) * lumenRate <= 10000
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                LumenGem(size: 24)
                TextField("Своё количество (от 50)", text: $custom).keyboardType(.numberPad).focused($focus)
                    .font(.system(size: 16.5, weight: .semibold))
                    .onChange(of: custom) { t in let f = String(t.filter { $0.isNumber }.prefix(4)); if f != t { custom = f } }
                if n > 0 { Text(rub(Double(n) * lumenRate)).font(.system(size: 15.5)).foregroundColor(Theme.muted) }
            }
            .padding(.horizontal, 16).frame(height: 52)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            if n > 0 {
                GradientButton(title: ok ? "Купить \(n) \(lumenWord(n)) за \(rub(Double(n) * lumenRate))" : (n < 50 ? "Минимум 50 люменов" : "Не больше 10 000 ₽ за раз"), loading: busy == n) { if ok { pay(n) } }
                    .opacity(ok ? 1 : 0.5)
            }
        }
    }

    private func pay(_ n: Int) {
        guard busy == nil else { return }
        busy = n; focus = false
        Task {
            await Pay.shared.buy(kind: "lum", qty: n)
            busy = nil
        }
    }
}

// MARK: - Оформление Premium

struct PremiumPlansSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var to: String? = nil
    @State var sel = 12
    @State private var busy = false
    static let plans: [(m: Int, price: Int, title: String, badge: String?)] = [
        (12, 2490, "Год", "−58%"), (6, 1490, "Полгода", "−38%"), (1, 199, "Месяц", nil),
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 36, height: 36).background(Circle().fill(Theme.panel2))
                }.buttonStyle(BouncyButtonStyle())
                Spacer()
            }
            PremiumStar(size: 74).frame(height: 96)
            Text(to != nil ? "Premium в подарок" : model.isPremium ? "Продлить Lumo Premium" : "Lumo Premium").font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.text)
            Text(to.map { "Для \(model.displayName($0)) · выберите срок" } ?? "Выберите срок подписки").font(.system(size: 15)).foregroundColor(Theme.muted)
            VStack(spacing: 0) {
                ForEach(Array(Self.plans.enumerated()), id: \.offset) { i, p in
                    if i > 0 { Divider().overlay(Theme.line).padding(.leading, 54) }
                    Button { withAnimation(.spring(response: 0.3)) { sel = p.m } } label: {
                        HStack(spacing: 14) {
                            Image(systemName: sel == p.m ? "checkmark.circle.fill" : "circle").font(.system(size: 22))
                                .foregroundColor(sel == p.m ? Theme.a1 : Theme.muted.opacity(0.6))
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 6) {
                                    Text(p.title).font(.system(size: 16.5, weight: .semibold)).foregroundColor(Theme.text)
                                    if let b = p.badge {
                                        Text(b).font(.system(size: 11.5, weight: .heavy)).foregroundColor(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.accent, in: RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                                if p.m > 1 { Text("\(rub(Double(p.price) / Double(p.m)))/мес").font(.system(size: 13)).foregroundColor(Theme.muted) }
                            }
                            Spacer()
                            Text(rub(Double(p.price))).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            Spacer(minLength: 4)
            let price = Self.plans.first { $0.m == sel }?.price ?? 0
            GradientButton(title: "Оплатить \(rub(Double(price)))", loading: busy) {
                busy = true
                Task { await Pay.shared.buy(kind: "prem", qty: sel, to: to); busy = false }
            }
            Text(to != nil ? "Оплата картой через ЮMoney прямо в Lumo. Premium включится у получателя сразу после оплаты, он получит уведомление." : "Оплата картой через ЮMoney прямо в Lumo. Premium включается автоматически сразу после оплаты.")
                .font(.system(size: 12.5)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
    }
}

/// Звезда Premium для заголовка окна оплаты
struct PremiumStar: View {
    var size: CGFloat = 70
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: 0xa48bff).opacity(0.45), .clear], center: .center, startRadius: 0, endRadius: size))
                    .frame(width: size * 2, height: size * 2).scaleEffect(1 + 0.06 * sin(t * 2.4))
                Image(systemName: "star.fill").font(.system(size: size * 0.8, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xc59bff), Color(hex: 0x6a7bff)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .rotationEffect(.degrees(6 * sin(t * 1.8)))
                    .shadow(color: Color(hex: 0x8a7bff).opacity(0.6), radius: 12)
            }
        }
    }
}
