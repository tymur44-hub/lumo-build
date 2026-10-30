import SwiftUI

/// Номер телефона: показ, смена
struct PhoneSettingsView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var store = PhoneStore.shared
    @State private var bind = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PhoneChangeArt().frame(width: 150, height: 150).padding(.top, 28)
                Text(store.phone.map { PhoneStore.pretty($0) } ?? "Номер не привязан")
                    .font(.system(size: 26, weight: .bold)).foregroundColor(Theme.text).padding(.top, 14)
                Text(store.phone == nil
                     ? "Привяжите номер для входа и защиты аккаунта. Ваши данные останутся на месте."
                     : "Здесь Вы можете сменить номер телефона. Ваш аккаунт и все данные (сообщения, медиа, контакты и т. д.) будут перенесены на новый номер.")
                    .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    .padding(.horizontal, 36).padding(.top, 10)
                TGCard {
                    Button { bind = true } label: {
                        Text(store.phone == nil ? "Привязать номер" : "Изменить номер").font(.system(size: 17, weight: .medium)).foregroundColor(Theme.a1)
                            .frame(maxWidth: .infinity).frame(height: 56).contentShape(Rectangle())
                    }
                    .buttonStyle(RowButtonStyle())
                }
                .padding(.top, 26)
                TGCard {
                    NavigationLink(value: SettingsPage.privacyKey("phone")) {
                        HStack {
                            Text("Кто видит мой номер").font(.system(size: 17)).foregroundColor(Theme.text)
                            Spacer()
                            Text(privLabel(model.me?.privacy["phone"] ?? "contacts")).font(.system(size: 17)).foregroundColor(Theme.muted)
                            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.6))
                        }
                        .padding(.horizontal, 20).frame(height: 58).contentShape(Rectangle())
                    }
                    .buttonStyle(RowButtonStyle())
                }
                .padding(.top, 12)
                TGHint(text: "Если выбрать «Никто», друзья не найдут вас по номеру в записной книжке.")
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Смена номера").navigationBarTitleDisplayMode(.inline)
        .task { await store.load() }
        .fullScreenCover(isPresented: $bind) { PhoneAuthView(mode: .bind) { bind = false } }
    }
}

/// Иллюстрация «смена номера»: телефон, SIM-карта и стрелка
struct PhoneChangeArt: View {
    @State private var on = false
    var body: some View {
        ZStack {
            Circle().fill(Theme.a1.opacity(0.14)).scaleEffect(on ? 1.04 : 0.96)
            RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [Color(hex: 0x3a7bff), Color(hex: 0x7a5cff)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 66, height: 112).rotationEffect(.degrees(-8)).offset(x: -14)
                .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.2)).frame(width: 52, height: 86).rotationEffect(.degrees(-8)).offset(x: -14))
            RoundedRectangle(cornerRadius: 8).fill(Color.white)
                .frame(width: 44, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xf5c542)).frame(width: 22, height: 18))
                .rotationEffect(.degrees(10)).offset(x: 34, y: 22).shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            Image(systemName: "arrow.left.arrow.right.circle.fill").font(.system(size: 30)).foregroundColor(Theme.a2)
                .background(Circle().fill(Theme.bg)).offset(x: 40, y: -40).rotationEffect(.degrees(on ? 8 : -8))
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { on = true } }
    }
}

/// Двухэтапная аутентификация: дополнительный пароль при входе по коду
struct TwoFAView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var store = PhoneStore.shared
    @State private var old = ""
    @State private var pwd = ""
    @State private var pwd2 = ""
    @State private var hint = ""
    @State private var busy = false
    @State private var msg: String?
    @State private var confirmOff = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: store.tfa ? "lock.shield.fill" : "lock.open.fill").font(.system(size: 38)).foregroundColor(.white)
                    .frame(width: 88, height: 88).background(Circle().fill(store.tfa ? Color(hex: 0x2bd67b) : Theme.a1)).padding(.top, 24)
                Text(store.tfa ? "Защита включена" : "Двухэтапная аутентификация")
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                Text(store.tfa ? "При входе на новом устройстве, кроме кода из SMS, нужно ввести ваш пароль."
                     : "Задайте дополнительный пароль. Тогда даже тот, кто получит код из SMS, не сможет войти в ваш аккаунт.")
                    .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 24)
                if store.phone == nil {
                    Text("Сначала привяжите номер телефона").font(.subheadline.weight(.semibold)).foregroundColor(Theme.danger)
                } else {
                    VStack(spacing: 10) {
                        if store.tfa { SecureField("Текущий пароль", text: $old).lumoField() }
                        SecureField(store.tfa ? "Новый пароль" : "Пароль (не меньше 4 символов)", text: $pwd).lumoField()
                        SecureField("Повторите пароль", text: $pwd2).lumoField()
                        TextField("Подсказка (необязательно)", text: $hint).lumoField()
                        GradientButton(title: store.tfa ? "Сменить пароль" : "Включить защиту", loading: busy) { save() }
                        if store.tfa {
                            Button("Отключить защиту") { confirmOff = true }.font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.danger).padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                }
                if let m = msg { Text(m).font(.subheadline).foregroundColor(m.hasPrefix("✓") ? Color(hex: 0x2bd67b) : Theme.danger).multilineTextAlignment(.center) }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Двухэтапная защита").navigationBarTitleDisplayMode(.inline)
        .task { await store.load() }
        .alert("Отключить защиту?", isPresented: $confirmOff) {
            SecureField("Пароль", text: $old)
            Button("Отключить", role: .destructive) { turnOff() }
            Button("Отмена", role: .cancel) {}
        }
    }

    private func save() {
        guard pwd.count >= 4 else { msg = "Пароль — не меньше 4 символов"; return }
        guard pwd == pwd2 else { msg = "Пароли не совпадают"; return }
        busy = true; msg = nil
        Task {
            defer { busy = false }
            do {
                _ = try await API.shared.rpc("lm_tfa_set", ["p_old": old, "p_new": pwd, "p_hint": hint])
                old = ""; pwd = ""; pwd2 = ""; hint = ""
                await store.load(); msg = "✓ Готово"
            } catch { msg = error.localizedDescription }
        }
    }

    private func turnOff() {
        let p = old; old = ""
        Task {
            do { _ = try await API.shared.rpc("lm_tfa_remove", ["p_pwd": p]); await store.load(); msg = "✓ Защита отключена" }
            catch { msg = error.localizedDescription }
        }
    }
}
