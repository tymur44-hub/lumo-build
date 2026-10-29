import SwiftUI

struct LoginView: View {
    @EnvironmentObject var model: AppModel
    @State private var register = false
    @State private var username = ""
    @State private var password = ""
    @State private var name = ""
    @State private var error: String?
    @State private var loading = false
    @State private var tgKey: String?
    @State private var tgWaiting = false
    @State private var tgBusy = false
    @State private var tgTask: Task<Void, Never>?
    @State private var phoneAuth = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image("LaunchLogo")
                    .resizable().scaledToFit()
                    .frame(width: 96, height: 96)
                    .padding(.top, 60)
                Text("Lumo").font(.system(size: 34, weight: .heavy))
                Text(Config.versionLabel).font(.caption.weight(.bold)).foregroundColor(Theme.muted)
                Text(register ? "Создайте аккаунт" : "Войдите в свой аккаунт")
                    .foregroundColor(Theme.muted)
                    .padding(.bottom, 12)

                if register {
                    TextField("Имя", text: $name)
                        .textContentType(.name)
                        .lumoField()
                }
                TextField("Юзернейм", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .lumoField()
                SecureField("Пароль", text: $password)
                    .textContentType(register ? .newPassword : .password)
                    .lumoField()

                if let e = error {
                    Text(e).foregroundColor(Theme.danger).font(.subheadline).multilineTextAlignment(.center)
                }

                GradientButton(title: register ? "Зарегистрироваться" : "Войти", loading: loading) { submit() }
                    .padding(.top, 6)

                HStack(spacing: 10) {
                    Rectangle().fill(Theme.line).frame(height: 1)
                    Text("или").font(.footnote).foregroundColor(Theme.muted)
                    Rectangle().fill(Theme.line).frame(height: 1)
                }
                .padding(.vertical, 2)

                Button { phoneAuth = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill").font(.system(size: 17, weight: .semibold))
                        Text(register ? "Зарегистрироваться по номеру" : "Войти по номеру телефона").font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x2bd67b)))
                }

                Button { telegram() } label: {
                    HStack(spacing: 10) {
                        if tgWaiting { ProgressView().tint(.white) }
                        else { Image(systemName: "paperplane.fill").font(.system(size: 17, weight: .semibold)) }
                        Text(tgWaiting ? "Ждём подтверждения в Telegram…" : (register ? "Создать аккаунт через Telegram" : "Войти через Telegram"))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x2aabee)))
                }
                if tgWaiting {
                    Text("В Telegram нажмите кнопку в боте и вернитесь сюда — вход произойдёт сам.")
                        .font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    Button("Открыть Telegram ещё раз") { openBot() }.font(.footnote.weight(.semibold))
                }

                Button(register ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться") {
                    withAnimation { register.toggle(); error = nil }
                }
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AuroraBackground(intensity: 0.4, speed: 0.6, base: Theme.bg, dim: 0))
        .onChange(of: phase) { p in if p == .active && tgWaiting { Task { await tgCheck() } } }
        .onDisappear { tgTask?.cancel() }
        .fullScreenCover(isPresented: $phoneAuth) { PhoneAuthView(mode: .login) { phoneAuth = false } }
    }

    private func telegram() {
        error = nil
        if tgWaiting { openBot(); return }
        Task {
            guard await model.telegramBot() != nil else { error = "Вход через Telegram сейчас недоступен"; return }
            tgKey = randomId(32)
            openBot()
            tgWaiting = true
            tgTask?.cancel()
            tgTask = Task {
                for _ in 0..<300 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if Task.isCancelled || !tgWaiting { return }
                    await tgCheck()
                }
                tgWaiting = false
            }
        }
    }

    private func openBot() {
        guard let bot = model.botName, let k = tgKey, let u = URL(string: "https://t.me/\(bot)?start=l_\(k)") else { return }
        UIApplication.shared.open(u)
    }

    private func tgCheck() async {
        guard let k = tgKey, tgWaiting, !tgBusy else { return }
        tgBusy = true
        defer { tgBusy = false }
        do {
            if try await model.telegramCheck(key: k) { tgWaiting = false; tgTask?.cancel() }
        } catch {
            tgWaiting = false
            tgTask?.cancel()
            self.error = error.localizedDescription
        }
    }

    private func submit() {
        let u = username.trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: "@", with: "")
        guard u.range(of: "^[a-z0-9_]{3,32}$", options: .regularExpression) != nil else {
            error = "Юзернейм: 3–32 символа, латиница, цифры и _"
            return
        }
        guard !password.isEmpty else { error = "Введите пароль"; return }
        if register && password.count < 6 { error = "Пароль — не короче 6 символов"; return }
        if register && name.trimmingCharacters(in: .whitespaces).isEmpty { error = "Введите имя"; return }
        loading = true
        error = nil
        Task {
            do {
                if register { try await model.register(username: u, password: password, name: name.trimmingCharacters(in: .whitespaces)) }
                else { try await model.login(username: u, password: password) }
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}
