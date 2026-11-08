import SwiftUI

/// Состояние блокировки моего аккаунта (lm_my_ban)
struct BanInfo: Equatable {
    var reason: String?
    var appealStatus: String?      // pending / accepted / rejected
    var appealReply: String?
    var appealAt: Date?

    init?(_ j: JSON) {
        guard j.bool("banned") else { return nil }
        reason = j.str("reason")
        let a = j.dict("appeal")
        appealStatus = a.str("status")
        appealReply = a.str("reply")
        appealAt = a.date("created_at")
    }
}

extension AppModel {
    func checkBan() async {
        guard loggedIn, let j = (try? await API.shared.rpc("lm_my_ban")) as? JSON else { return }
        let b = BanInfo(j)
        if b != myBan { withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { myBan = b } }
    }

    func submitAppeal(_ text: String) async -> String? {
        do {
            let r = try await API.shared.rpc("lm_appeal_submit", ["p_text": text])
            if let j = r as? JSON { myBan = BanInfo(j) }
            return nil
        } catch { return error.localizedDescription }
    }
}

/// Кирпичная стена, которая выкладывается ряд за рядом
struct BrickWall: View {
    var rows = 6, perRow = 5
    @State private var built = false

    var body: some View {
        GeometryReader { g in
            let gap: CGFloat = 4
            let bw = (g.size.width - gap * CGFloat(perRow - 1)) / CGFloat(perRow)
            let bh = (g.size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)
            ZStack(alignment: .topLeading) {
                ForEach(0..<rows, id: \.self) { r in
                    let shift = r % 2 == 1 ? -bw / 2 : 0
                    let count = r % 2 == 1 ? perRow + 1 : perRow
                    ForEach(0..<count, id: \.self) { i in
                        let order = (rows - 1 - r) * (perRow + 1) + i
                        brick(r, i)
                            .frame(width: bw, height: bh)
                            .offset(x: shift + CGFloat(i) * (bw + gap), y: CGFloat(r) * (bh + gap))
                            .offset(y: built ? 0 : -g.size.height * 0.6)
                            .opacity(built ? 1 : 0)
                            .animation(.spring(response: 0.45, dampingFraction: 0.62).delay(Double(order) * 0.028), value: built)
                    }
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
            .clipped()
        }
        .onAppear { built = true }
    }

    private func brick(_ r: Int, _ i: Int) -> some View {
        let tones: [UInt32] = [0xc8553d, 0xb4472f, 0xd76a4c, 0xa63f2b, 0xbf5a3f]
        let base = Color(hex: tones[(r * 3 + i * 7) % tones.count])
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(LinearGradient(colors: [base.opacity(1), base.opacity(0.78)], startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.white.opacity(0.18)).frame(height: 2).padding(.horizontal, 3).padding(.top, 2)
            }
            .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1.5)
    }
}

/// Окно «Ваш аккаунт заблокирован» — поверх всего приложения, без выхода из аккаунта
struct BannedScreen: View {
    @EnvironmentObject var model: AppModel
    let ban: BanInfo
    @State private var appeal = false
    @State private var lockIn = false
    @State private var confirmOut = false

    private var pending: Bool { ban.appealStatus == "pending" }
    private var subtitle: String {
        let un = model.me?.username ?? ""
        let who = un.isEmpty ? "" : " @" + un
        return "Администрация Lumo ограничила доступ к аккаунту" + who + ". Пока блокировка действует, нельзя писать сообщения и пользоваться Lumo."
    }
    private var reasonText: String {
        let r = ban.reason ?? ""
        return r.isEmpty ? "Причина не указана" : r
    }
    private var buttonTitle: String {
        if pending { return "Апелляция на рассмотрении" }
        return ban.appealStatus == "rejected" ? "Подать апелляцию ещё раз" : "Подать апелляцию"
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            RadialGradient(colors: [Color(hex: 0xff5b5b).opacity(0.28), .clear], center: .top, startRadius: 10, endRadius: 420).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        BrickWall().frame(width: 250, height: 150)
                            .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35)))
                        ZStack {
                            Circle().fill(LinearGradient(colors: [Color(hex: 0xff6a5b), Color(hex: 0xe0284f)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 78, height: 78)
                                .shadow(color: Color(hex: 0xe0284f).opacity(0.55), radius: 18, y: 8)
                            Circle().stroke(Theme.bg, lineWidth: 5).frame(width: 82, height: 82)
                            Image(systemName: "lock.fill").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                        }
                        .scaleEffect(lockIn ? 1 : 0.2).opacity(lockIn ? 1 : 0)
                        .offset(y: 38)
                    }
                    .padding(.top, 54)
                    .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.75)) { lockIn = true } }

                    Text("Ваш аккаунт заблокирован")
                        .font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text)
                        .multilineTextAlignment(.center).padding(.top, 58)
                    Text(subtitle)
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                        .padding(.horizontal, 28).padding(.top, 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("ПРИЧИНА", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold)).foregroundColor(Color(hex: 0xff6a5b))
                        Text(reasonText)
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(hex: 0xff6a5b).opacity(0.35), lineWidth: 1))
                    .padding(.horizontal, 20).padding(.top, 22)

                    if let st = ban.appealStatus, st != "accepted" { appealCard(st) }

                    Button { appeal = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: pending ? "clock.fill" : "envelope.open.fill")
                            Text(buttonTitle)
                        }
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .opacity(pending ? 0.5 : 1)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(pending)
                    .padding(.horizontal, 20).padding(.top, 22)

                    Button { confirmOut = true } label: {
                        Text("Выйти из аккаунта").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).frame(height: 44)
                    }
                    .padding(.top, 6)
                    .confirmationDialog("Выйти из аккаунта?", isPresented: $confirmOut, titleVisibility: .visible) {
                        Button("Выйти", role: .destructive) { Task { await model.logout() } }
                        Button("Отмена", role: .cancel) {}
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $appeal) { AppealSheet().environmentObject(model) }
        .task { while !Task.isCancelled { try? await Task.sleep(nanoseconds: 20_000_000_000); await model.checkBan() } }
    }

    private func appealCard(_ st: String) -> some View {
        let rej = st == "rejected"
        let icon: String = rej ? "xmark.circle.fill" : "hourglass"
        let tint: Color = rej ? Theme.danger : Color(hex: 0xf0a23a)
        let title: String = rej ? "Апелляция отклонена" : "Апелляция отправлена"
        var msg: String
        if rej {
            let reply = ban.appealReply ?? ""
            msg = reply.isEmpty ? "Модераторы оставили блокировку в силе." : "Ответ модератора: " + reply
        } else {
            msg = "Модераторы рассмотрят её и снимут блокировку, если согласятся. Это окно обновится само."
            if let at = ban.appealAt { msg += "\nОтправлена " + DateParser.time(at) }
        }
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold)).foregroundColor(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                Text(msg)
                    .font(.system(size: 13.5)).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20).padding(.top, 12)
    }
}

/// Окно апелляции: пользователь объясняет, за что его могли заблокировать
struct AppealSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var busy = false
    @State private var error: String?
    @State private var sent = false
    @FocusState private var focus: Bool
    private let limit = 2000

    private var ok: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 40, height: 40).background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                Text("Апелляция").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 14).padding(.top, 12)

            if sent {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 64)).foregroundStyle(Theme.accent)
                    Text("Апелляция отправлена").font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
                    Text("Модераторы прочитают ваше обращение. Если блокировку снимут, Lumo откроется сам.")
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                .transition(.scale.combined(with: .opacity))
                Spacer()
                Button { dismiss() } label: {
                    Text("Готово").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54).background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "text.bubble.fill").font(.system(size: 22)).foregroundColor(.white)
                                .frame(width: 48, height: 48).background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Расскажите, что случилось").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                                Text("За что вас могли заблокировать и почему блокировку стоит снять").font(.system(size: 13.5)).foregroundColor(Theme.muted)
                            }
                        }
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Например: я отправил много одинаковых сообщений, потому что…").foregroundColor(Theme.muted.opacity(0.7))
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            TextEditor(text: $text).focused($focus).scrollContentBackground(.hidden)
                                .padding(.horizontal, 11).padding(.vertical, 6)
                                .frame(minHeight: 200)
                                .onChange(of: text) { v in if v.count > limit { text = String(v.prefix(limit)) } }
                        }
                        .font(.system(size: 16)).foregroundColor(Theme.text)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        HStack {
                            Text("Пишите честно и спокойно — так апелляцию рассмотрят быстрее.").font(.system(size: 12.5)).foregroundColor(Theme.muted)
                            Spacer()
                            Text("\(text.count)/\(limit)").font(.system(size: 12.5, weight: .medium)).monospacedDigit().foregroundColor(Theme.muted)
                        }
                        if let e = error { Text(e).font(.subheadline).foregroundColor(Theme.danger) }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                Button { send() } label: {
                    Group {
                        if busy { ProgressView().tint(.white) } else {
                            HStack(spacing: 8) { Image(systemName: "paperplane.fill"); Text("Отправить апелляцию") }
                        }
                    }
                    .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .opacity(ok ? 1 : 0.45)
                }
                .disabled(!ok || busy)
                .padding(.horizontal, 20).padding(.bottom, 14)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { focus = true }
    }

    private func send() {
        busy = true; error = nil
        Task {
            let e = await model.submitAppeal(text.trimmingCharacters(in: .whitespacesAndNewlines))
            busy = false
            if let e = e { error = e } else { withAnimation(.spring()) { sent = true } }
        }
    }
}
