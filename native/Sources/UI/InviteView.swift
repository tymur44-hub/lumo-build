import SwiftUI

/// Приглашение друзей: ссылка, сколько пришло по ней, и поле «Кто вас пригласил?» для новичков
struct InviteView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var invited = 0
    @State private var earned = 0
    @State private var invitedBy: String?
    @State private var canClaim = false
    @State private var who = ""
    @State private var busy = false
    @State private var shareOpen = false

    private var link: String { "https://lumomess.ru/#ref=" + (model.me?.username ?? "") }
    private var shareText: String { "Я в Lumo — переходи по ссылке и укажи меня как пригласившего, получим по 25 люменов: " + link }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [Color(hex: 0xff5b8a), Theme.a1], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 96, height: 96)
                        Image(systemName: "person.2.fill").font(.system(size: 40, weight: .semibold)).foregroundColor(.white)
                    }
                    .padding(.top, 10)
                    Text("Зовите друзей в Lumo").font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
                    Text("Друг укажет вас как пригласившего — и вы оба получите по 25 люменов.")
                        .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)

                    HStack(spacing: 10) {
                        stat("\(invited)", "пришло")
                        stat("\(earned)", "люменов")
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        Text(link).font(.system(size: 14, design: .monospaced)).foregroundColor(Theme.text)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 14).frame(maxWidth: .infinity).frame(height: 44)
                            .lumoGlass(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        HStack(spacing: 10) {
                            Button { UIPasteboard.general.string = link; model.say("Ссылка скопирована") } label: {
                                Label("Копировать", systemImage: "doc.on.doc").frame(maxWidth: .infinity).frame(height: 48)
                                    .foregroundColor(Theme.text).lumoGlass(RoundedRectangle(cornerRadius: 14, style: .continuous), interactive: true)
                            }
                            Button { shareOpen = true } label: {
                                Label("Поделиться", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).frame(height: 48)
                                    .foregroundColor(.white).background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .padding(.horizontal, 16)

                    if let b = invitedBy {
                        Label("Вас пригласил @\(b)", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 15, weight: .medium)).foregroundColor(Theme.a1).padding(.top, 6)
                    } else if canClaim {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Кто вас пригласил?").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                            Text("Укажите юзернейм друга — вы оба получите по 25 люменов. Можно в течение недели после регистрации.")
                                .font(.system(size: 13.5)).foregroundColor(Theme.muted)
                            HStack(spacing: 8) {
                                TextField("@юзернейм", text: $who)
                                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                                    .padding(.horizontal, 14).frame(height: 46)
                                    .lumoGlass(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Button { Task { await claim() } } label: {
                                    Group { if busy { ProgressView().tint(.white) } else { Text("Готово") } }
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                        .frame(width: 92, height: 46).background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .disabled(busy || who.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(16)
                        .lumoGlass(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Пригласить друзей").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
            .sheet(isPresented: $shareOpen) { ShareSheet(items: [shareText]) }
            .task { await load() }
        }
    }

    private func stat(_ v: String, _ t: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
            Text(t).font(.system(size: 13)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).frame(height: 74)
        .lumoGlass(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func load() async {
        guard let j = (try? await API.shared.rpc("lm_my_referrals")) as? JSON else { return }
        invited = (j["invited"] as? Int) ?? Int((j["invited"] as? Double) ?? 0)
        earned = (j["earned"] as? Int) ?? Int((j["earned"] as? Double) ?? 0)
        invitedBy = j["invited_by"] as? String
        canClaim = (j["can_claim"] as? Bool) ?? false
    }

    private func claim() async {
        busy = true
        defer { busy = false }
        do {
            let j = (try await API.shared.rpc("lm_claim_referral", ["p_username": who])) as? JSON ?? [:]
            if (j["ok"] as? Bool) == true {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                model.say("Готово! Вам начислено 25 люменов")
                await load()
            } else {
                model.say((j["error"] as? String) ?? "Не получилось")
            }
        } catch { model.say(error.localizedDescription) }
    }
}
