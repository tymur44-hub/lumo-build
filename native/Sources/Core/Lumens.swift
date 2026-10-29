import Foundation
import SwiftUI

struct ChatCfg { var reactions: [String]?; var linked: String? }
struct LedgerRow: Identifiable { let id: Int; let delta: Int; let kind: String; let refUser: String?; let at: Date }

let allReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥", "🙏", "👏", "🎉", "🤔", "😍", "👎", "💯", "🤝", "😡", "🥰"]

func lumenWord(_ n: Int) -> String {
    let m = n % 100
    if (11...14).contains(m) { return "люменов" }
    switch n % 10 { case 1: return "люмен"; case 2, 3, 4: return "люмена"; default: return "люменов" }
}
func commentWord(_ n: Int) -> String {
    let m = n % 100
    if (11...14).contains(m) { return "комментариев" }
    switch n % 10 { case 1: return "комментарий"; case 2, 3, 4: return "комментария"; default: return "комментариев" }
}

/// Люмены — внутренняя валюта Lumo, а также настройки каналов (реакции, обсуждение) и счётчики комментариев
@MainActor
final class Lumens: ObservableObject {
    static let shared = Lumens()
    @Published var balance = 0
    @Published var streak = 0
    @Published var canClaim = false
    @Published var tips: [Int: Int] = [:]
    @Published var comments: [Int: Int] = [:]
    @Published var cfg: [String: ChatCfg] = [:]
    private var askedTips = Set<Int>(), askedComments = Set<Int>()
    private var pendTips = Set<Int>(), pendComments = Set<Int>()
    private var flushTask: Task<Void, Never>?

    func reset() {
        balance = 0; streak = 0; canClaim = false; tips = [:]; comments = [:]; cfg = [:]
        askedTips = []; askedComments = []; pendTips = []; pendComments = []
    }

    func load() async {
        guard let j = (try? await API.shared.rpc("lm_wallet_me")) as? JSON else { return }
        balance = j.int("balance") ?? 0; streak = j.int("streak") ?? 0; canClaim = j.bool("can_claim")
    }

    /// Ежедневный бонус: сколько люменов получено
    func claim() async throws -> Int {
        let j = try await API.shared.rpc("lm_wallet_daily") as? JSON
        await load()
        return j?.int("amount") ?? 0
    }

    func tip(_ msgId: Int, _ amount: Int) async throws {
        _ = try await API.shared.rpc("lm_wallet_tip", ["p_message": msgId, "p_amount": amount])
        await load()
        tips[msgId, default: 0] += amount
    }

    func send(_ user: String, _ amount: Int) async throws {
        _ = try await API.shared.rpc("lm_wallet_send", ["p_user": user, "p_amount": amount])
        await load()
    }

    func history() async -> [LedgerRow] {
        let a = ((try? await API.shared.rpc("lm_wallet_history", ["p_limit": 80])) as? [JSON]) ?? []
        return a.map { LedgerRow(id: $0.int("id") ?? 0, delta: $0.int("delta") ?? 0, kind: $0.str("kind") ?? "", refUser: $0.str("ref_user"), at: $0.date("created_at") ?? Date()) }
    }

    func loadCfg() async {
        guard let rows = try? await API.shared.select("lm_chats", ["select": "id,reactions,linked_chat_id", "type": "eq.channel"]) else { return }
        var out: [String: ChatCfg] = [:]
        for o in rows {
            guard let id = o.str("id") else { continue }
            out[id] = ChatCfg(reactions: o["reactions"] as? [String], linked: o.str("linked_chat_id"))
        }
        cfg = out
    }

    func allowed(_ chatId: String?) -> [String]? { chatId.flatMap { cfg[$0]?.reactions } }
    func linked(_ chatId: String?) -> String? { chatId.flatMap { cfg[$0]?.linked } }

    func setReactions(_ chatId: String, _ list: [String]?) async -> String? {
        do {
            _ = try await API.shared.rpc("lm_set_reactions", ["p_chat": chatId, "p_list": list as Any? ?? NSNull()])
            await loadCfg(); return nil
        } catch { return error.localizedDescription }
    }

    func link(_ channel: String, _ group: String?) async -> String? {
        do {
            _ = try await API.shared.rpc("lm_link_discussion", ["p_channel": channel, "p_group": group as Any? ?? NSNull()])
            await loadCfg(); return nil
        } catch { return error.localizedDescription }
    }

    /// Новая группа для обсуждения (без перехода в неё)
    func createDiscussion(title: String) async -> String? {
        do {
            let p: JSON = ["p_type": "group", "p_title": title, "p_members": [String](), "p_description": ""]
            return try await API.shared.rpc("lm_create_chat", p) as? String
        } catch { return nil }
    }

    /// Подгружаем суммы люменов и число комментариев пачкой
    func request(_ id: Int, withComments: Bool) {
        guard id > 0 else { return }
        if askedTips.insert(id).inserted { pendTips.insert(id) }
        if withComments, askedComments.insert(id).inserted { pendComments.insert(id) }
        if pendTips.isEmpty && pendComments.isEmpty { return }
        flushTask?.cancel()
        flushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            await self?.flush()
        }
    }

    func refreshComments(_ id: Int) { askedComments.remove(id); request(id, withComments: true) }

    private func flush() async {
        let t = Array(pendTips), c = Array(pendComments)
        pendTips = []; pendComments = []
        if !t.isEmpty, let a = (try? await API.shared.rpc("lm_tip_totals", ["p_ids": t])) as? [JSON] {
            for o in a { if let id = o.int("message_id") { tips[id] = o.int("total") ?? 0 } }
        }
        if !c.isEmpty {
            let a = ((try? await API.shared.rpc("lm_comment_counts", ["p_posts": c])) as? [JSON]) ?? []
            var got: [Int: Int] = [:]
            for o in a { if let p = o.int("post") { got[p] = o.int("n") ?? 0 } }
            for id in c { comments[id] = got[id] ?? 0 }
        }
    }
}

/// Значок люмена: огранённый кристалл с четырёхлучевой искрой. Нарисован вручную, без эмодзи
struct LumenGem: View {
    var size: CGFloat = 20
    var body: some View {
        Canvas { ctx, sz in
            let w = min(sz.width, sz.height)
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            var hex = Path()
            for i in 0..<6 {
                let a = Double(i) * .pi / 3 - .pi / 2
                let p = CGPoint(x: c.x + CGFloat(cos(a)) * w * 0.48, y: c.y + CGFloat(sin(a)) * w * 0.48)
                if i == 0 { hex.move(to: p) } else { hex.addLine(to: p) }
            }
            hex.closeSubpath()
            ctx.fill(hex, with: .linearGradient(Gradient(colors: [Color(hex: 0xffe08a), Color(hex: 0xff9a3d), Color(hex: 0xff5e8a)]),
                                                startPoint: .zero, endPoint: CGPoint(x: w, y: w)))
            ctx.stroke(hex, with: .color(.white.opacity(0.4)), style: StrokeStyle(lineWidth: w * 0.045, lineJoin: .round))
            var star = Path()
            for i in 0..<8 {
                let a = Double(i) * .pi / 4 - .pi / 2
                let r = i % 2 == 0 ? w * 0.29 : w * 0.075
                let p = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                if i == 0 { star.move(to: p) } else { star.addLine(to: p) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(.white))
        }
        .frame(width: size, height: size)
    }
}

struct WalletView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var lumens = Lumens.shared
    @State private var rows: [LedgerRow] = []
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    LumenGem(size: 72)
                    Text("\(lumens.balance)").font(.system(size: 46, weight: .black)).foregroundColor(.white)
                    Text(lumenWord(lumens.balance)).font(.system(size: 16)).foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity).padding(22)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 16).padding(.top, 8)
                VStack(alignment: .leading, spacing: 8) {
                    GradientButton(title: lumens.canClaim ? "Забрать ежедневный бонус" : "Бонус получен — загляните позже", loading: busy) { claim() }
                        .opacity(lumens.canClaim ? 1 : 0.5).disabled(!lumens.canClaim)
                    if lumens.streak > 0 {
                        Text("Серия: \(lumens.streak) дн. подряд. Чем длиннее серия, тем больше бонус — до 10 в день.")
                            .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 6)
                    }
                }
                .padding(.horizontal, 16)
                TGCard {
                    Button { model.say("Пополнение пока недоступно") } label: { TGIconRow(icon: "plus.circle.fill", color: Color(hex: 0x2bd67b), title: "Пополнить", value: "в разработке", chevron: false) }
                        .buttonStyle(.plain)
                    Divider().overlay(Theme.line).padding(.leading, 68)
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "info.circle.fill").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                            .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 9).fill(Theme.a1))
                        Text("Откройте профиль человека и нажмите «Отправить люмены», либо удерживайте его сообщение, либо выберите это в меню скрепки в личном чате.")
                            .font(.system(size: 14)).foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("ИСТОРИЯ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32)
                if rows.isEmpty { Text("Пока пусто").foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32) }
                else {
                    TGCard {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
                            if i > 0 { Divider().overlay(Theme.line).padding(.leading, 18) }
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title(r)).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                                    Text(r.at.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                }
                                Spacer()
                                Text((r.delta > 0 ? "+" : "") + "\(r.delta)").font(.system(size: 17, weight: .bold)).foregroundColor(r.delta > 0 ? Color(hex: 0x2bd67b) : Theme.text)
                                LumenGem(size: 18)
                            }
                            .padding(.horizontal, 18).padding(.vertical, 11)
                        }
                    }
                }
                Color.clear.frame(height: 24)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Люмены").navigationBarTitleDisplayMode(.inline)
        .task { await lumens.load(); await reload() }
    }

    private func title(_ r: LedgerRow) -> String {
        let who = r.refUser.map { model.displayName($0) } ?? ""
        switch r.kind {
        case "daily": return "Ежедневный бонус"
        case "tip_in": return "От " + who
        case "tip_out": return "Для " + who
        case "grant": return "Начисление"
        default: return "Операция"
        }
    }

    private func reload() async {
        rows = await lumens.history()
        await model.loadProfiles(rows.compactMap { $0.refUser })
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

struct LumenTarget: Identifiable { let id: String; var msg: Int? = nil }

/// Живая иконка люмена: свечение, покачивание и разлетающиеся искры
struct LumenLive: View {
    var size: CGFloat = 90
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let pulse = 1 + 0.07 * sin(t * 3.4)
            let sway = 9 * sin(t * 2.6)
            ZStack {
                Canvas { ctx, sz in
                    let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
                    let R = min(sz.width, sz.height) / 2
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - R * 0.9, y: c.y - R * 0.9, width: R * 1.8, height: R * 1.8)),
                             with: .radialGradient(Gradient(colors: [Color(hex: 0xffb347).opacity(0.5 * pulse), .clear]), center: c, startRadius: 0, endRadius: R * 0.9))
                    let cycle = (t / 3).truncatingRemainder(dividingBy: 1)
                    for i in 0..<12 {
                        let ph = (cycle + Double(i) / 12).truncatingRemainder(dividingBy: 1)
                        let ang = Double(i) * .pi / 6 + t * 0.4
                        let d = size * (0.5 + 0.62 * ph)
                        let a = 1 - ph
                        let x = c.x + CGFloat(cos(ang)) * d, y = c.y + CGFloat(sin(ang)) * d
                        let r = CGFloat(3.5 + 4 * (1 - ph))
                        let col = i % 2 == 0 ? Color(hex: 0xffe08a) : Color(hex: 0xff8fb5)
                        var p = Path()
                        p.move(to: CGPoint(x: x - r, y: y)); p.addLine(to: CGPoint(x: x + r, y: y))
                        p.move(to: CGPoint(x: x, y: y - r)); p.addLine(to: CGPoint(x: x, y: y + r))
                        ctx.stroke(p, with: .color(col.opacity(a)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    }
                }
                LumenGem(size: size).scaleEffect(pulse).rotationEffect(.degrees(sway))
            }
        }
        .frame(width: size * 2.2, height: size * 2.2)
    }
}

/// Отправка люменов в стиле «жидкого стекла»
struct SendLumensSheet: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var lumens = Lumens.shared
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var msgId: Int? = nil
    @State private var text = "5"
    @State private var busy = false
    @State private var done = false
    @FocusState private var focused: Bool

    private var amount: Int { Int(text) ?? 0 }
    private var owner: Bool { model.staffRole == "owner" }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1a1030), Color(hex: 0x0b0a18)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            Circle().fill(Color(hex: 0xff9a3d).opacity(0.5)).frame(width: 300).blur(radius: 70).offset(x: -110, y: -200)
            Circle().fill(Color(hex: 0x7c5cff).opacity(0.55)).frame(width: 340).blur(radius: 80).offset(x: 120, y: 240)
            VStack(spacing: 0) {
                Spacer()
                glass.padding(.horizontal, 20)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .task { await lumens.load() }
    }

    private var glass: some View {
        VStack(spacing: 14) {
            if done {
                LumenLive(size: 100)
                Text("Отправлено").font(.system(size: 26, weight: .black)).foregroundColor(.white)
                Text("\(amount) \(lumenWord(amount)) для \(model.displayName(userId))").foregroundColor(.white.opacity(0.8))
                Spacer().frame(height: 12)
            } else {
                LumenLive(size: 78).padding(.top, -10).padding(.bottom, -30)
                HStack(spacing: 10) {
                    AvatarView(name: model.displayName(userId), url: model.profiles[userId]?.avatarURL, color: model.profiles[userId]?.color ?? 0, size: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Получатель").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                        Text(model.displayName(userId)).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    }
                }
                HStack(spacing: 8) {
                    TextField("0", text: $text).keyboardType(.numberPad).focused($focused)
                        .multilineTextAlignment(.center).font(.system(size: 44, weight: .black)).foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .onChange(of: text) { t in
                            let f = String(t.filter { $0.isNumber }.prefix(owner ? 7 : 4))
                            if f != t { text = f }
                        }
                    LumenGem(size: 30)
                }
                .padding(.vertical, 10).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.3), lineWidth: 1))
                HStack(spacing: 8) {
                    ForEach([1, 5, 10, 50, 100, 500], id: \.self) { n in
                        Button { text = "\(n)" } label: {
                            Text("\(n)").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                .padding(.horizontal, 11).padding(.vertical, 8)
                                .background(Capsule().fill(.white.opacity(amount == n ? 0.32 : 0.1)))
                                .overlay(Capsule().stroke(.white.opacity(amount == n ? 0.7 : 0.25), lineWidth: 1))
                        }
                    }
                }
                Text(owner ? "Вы владелец: люмены начисляются без списания с вашего счёта" : "На вашем счёте: \(lumens.balance) \(lumenWord(lumens.balance))")
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.75)).multilineTextAlignment(.center)
                Button { send() } label: {
                    ZStack {
                        if busy { ProgressView().tint(.white) } else { Text("Отправить").font(.system(size: 17, weight: .bold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(amount > 0 ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color.white.opacity(0.15)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
                }
                .disabled(amount <= 0 || busy)
                Button("Закрыть") { dismiss() }.font(.system(size: 15)).foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous).fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).fill(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        )
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous)
            .stroke(LinearGradient(colors: [.white.opacity(0.65), .white.opacity(0.08), .white.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
    }

    private func send() {
        guard amount > 0, !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                if let m = msgId { try await lumens.tip(m, amount) } else { try await lumens.send(userId, amount) }
                withAnimation(.spring()) { done = true }
                try? await Task.sleep(nanoseconds: 1_700_000_000)
                dismiss()
            } catch { model.say(error.localizedDescription) }
        }
    }
}

/// Отправить люмены за сообщение
struct TipSheet: View {
    let message: Message
    var body: some View { SendLumensSheet(userId: message.senderId ?? "", msgId: message.id) }
}

/// Подарки за люмены: NFT в разработке
struct GiftsView: View {
    @State private var glow = false
    private let tones: [UInt32] = [0xff9a3d, 0x7c5cff, 0x2bd67b, 0xff5e8a, 0x22a6ff, 0xffd36b]
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                LumenLive(size: 70)
                Text("NFT-подарки").font(.system(size: 26, weight: .black)).foregroundColor(Theme.text)
                Text("Скоро за люмены можно будет покупать редкие подарки, дарить их друзьям и собирать коллекцию. Сейчас раздел в разработке: мы делаем каждый подарок отдельно и тщательно.")
                    .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 28)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(0..<6, id: \.self) { i in
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(RadialGradient(colors: [Color(hex: tones[i]).opacity(glow ? 0.5 : 0.2), .clear], center: .center, startRadius: 0, endRadius: 90))
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill").font(.system(size: 30)).foregroundColor(Theme.text.opacity(0.55))
                                Text("Скоро").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text.opacity(0.7))
                            }
                        }
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.line, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 14).padding(.top, 14)
            }
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Подарки").navigationBarTitleDisplayMode(.inline)
        .onAppear { withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { glow = true } }
    }
}

/// Сумма люменов под сообщением
struct TipPill: View {
    @ObservedObject private var lumens = Lumens.shared
    let id: Int
    var body: some View {
        if let n = lumens.tips[id], n > 0 {
            HStack(spacing: 4) {
                LumenGem(size: 15)
                Text("\(n)").font(.system(size: 12.5, weight: .bold)).foregroundColor(Theme.text)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Theme.panel2)).overlay(Capsule().stroke(Theme.line))
        }
    }
}

/// Комментарии к посту канала: сообщения привязанной группы
struct CommentsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    let postId: Int
    @State private var list: [Message] = []
    @State private var text = ""
    @State private var busy = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let p = model.findMessage(postId, in: chatId) {
                    Text(p.preview).font(.system(size: 14)).foregroundColor(Theme.muted).lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 14).padding(.top, 6)
                }
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if loaded && list.isEmpty {
                                Text("Комментариев пока нет. Напишите первый.").foregroundColor(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(40)
                            }
                            ForEach(list) { c in
                                HStack(alignment: .top, spacing: 10) {
                                    AvatarView(name: model.displayName(c.senderId), url: c.senderId.flatMap { model.profiles[$0]?.avatarURL },
                                               color: c.senderId.flatMap { model.profiles[$0]?.color } ?? 0, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.displayName(c.senderId)).font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Theme.nameColor(c.senderId.flatMap { model.profiles[$0]?.color } ?? 0))
                                        Text(c.body ?? "").font(.system(size: 16)).foregroundColor(Theme.text)
                                        Text(Fmt.clock(c.createdAt)).font(.system(size: 11)).foregroundColor(Theme.muted).frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Theme.bubble, in: RoundedRectangle(cornerRadius: 16))
                                }
                                .id(c.id)
                            }
                        }
                        .padding(14)
                    }
                    .onChange(of: list.count) { _ in if let l = list.last { withAnimation { proxy.scrollTo(l.id, anchor: .bottom) } } }
                }
                HStack(spacing: 8) {
                    TextField("Комментарий", text: $text, axis: .vertical).lineLimit(1...5).padding(.horizontal, 16).padding(.vertical, 11)
                        .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 22))
                    Button { send() } label: {
                        Image(systemName: "paperplane.fill").foregroundColor(.white).frame(width: 46, height: 46)
                            .background(Circle().fill(text.trimmingCharacters(in: .whitespaces).isEmpty ? AnyShapeStyle(Theme.panel2) : AnyShapeStyle(Theme.accent)))
                    }
                    .disabled(busy)
                }
                .padding(10)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(list.isEmpty ? "Комментарии" : "\(list.count) \(commentWord(list.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
        .task {
            while !Task.isCancelled { await reload(); try? await Task.sleep(nanoseconds: 4_000_000_000) }
        }
        .onDisappear { Lumens.shared.refreshComments(postId) }
    }

    private func reload() async {
        let a = ((try? await API.shared.rpc("lm_comments", ["p_post": postId])) as? [JSON]) ?? []
        list = a.map { Message(json: $0) }
        await model.loadProfiles(list.compactMap { $0.senderId })
        loaded = true
    }

    private func send() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do { _ = try await API.shared.rpc("lm_comment_add", ["p_post": postId, "p_body": t]); text = ""; await reload() }
            catch { model.say(error.localizedDescription) }
        }
    }
}
