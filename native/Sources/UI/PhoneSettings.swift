import SwiftUI

/// Номер телефона: показ, смена
struct PhoneSettingsView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var store = PhoneStore.shared
    @State private var bind = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TGCard {
                    HStack {
                        Text("Номер").font(.system(size: 17)).foregroundColor(Theme.text)
                        Spacer()
                        Text(store.phone.map { PhoneStore.pretty($0) } ?? "Не привязан").font(.system(size: 17)).foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 20).frame(height: 58)
                }
                .padding(.top, 12)
                TGCard {
                    Button { bind = true } label: {
                        HStack {
                            Text(store.phone == nil ? "Привязать номер" : "Изменить номер").font(.system(size: 17)).foregroundColor(Theme.a1)
                            Spacer()
                        }
                        .padding(.horizontal, 20).frame(height: 56).contentShape(Rectangle())
                    }
                    .buttonStyle(RowButtonStyle())
                }
                .padding(.top, 12)
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
                TGHint(text: "Номер нужен для входа и сверки контактов. Если выбрать «Никто», друзья не найдут вас по номеру в записной книжке.")
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Номер телефона").navigationBarTitleDisplayMode(.inline)
        .task { await store.load() }
        .fullScreenCover(isPresented: $bind) { PhoneAuthView(mode: .bind) { bind = false } }
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
