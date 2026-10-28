import SwiftUI

enum E2EScreen: Identifiable {
    case restore, backup
    var id: Int { self == .restore ? 0 : 1 }
}

/// Окна сквозного шифрования: восстановление ключей на новом устройстве и пароль резервной копии
struct E2ESheets: ViewModifier {
    @ObservedObject var e2e = E2E.shared
    @EnvironmentObject var model: AppModel

    func body(content: Content) -> some View {
        content.sheet(item: Binding<E2EScreen?>(
            get: { e2e.status == .needRestore ? .restore : (e2e.promptBackup && e2e.status == .ready ? .backup : nil) },
            set: { if $0 == nil, e2e.status == .ready, e2e.promptBackup { e2e.skipBackup() } })) { s in
            switch s {
            case .restore: E2ERestoreView().environmentObject(model).interactiveDismissDisabled()
            case .backup: E2EBackupView().environmentObject(model)
            }
        }
    }
}

struct E2ERestoreView: View {
    @ObservedObject var e2e = E2E.shared
    @EnvironmentObject var model: AppModel
    @State private var pw = ""
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill").font(.system(size: 46)).foregroundStyle(Theme.accent).padding(.top, 34)
                Text("Расшифровка переписок").font(.title3.bold()).foregroundColor(Theme.text)
                Text("Личные чаты защищены сквозным шифрованием. Введите пароль резервной копии, который вы задали на другом устройстве.")
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                SecureField("Пароль резервной копии", text: $pw)
                    .padding(.horizontal, 16).frame(minHeight: 52).background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(Theme.text)
                GradientButton(title: "Расшифровать", loading: e2e.busy) {
                    guard !pw.isEmpty else { return }
                    Task {
                        if await e2e.restore(pw) { model.say("Переписки расшифрованы"); await model.loadChats() }
                        else { model.say("Неверный пароль") }
                    }
                }
                Button("Забыл пароль") { confirmReset = true }.foregroundColor(Theme.danger).padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .alert("Сбросить ключи?", isPresented: $confirmReset) {
            Button("Сбросить", role: .destructive) {
                Task { if await e2e.reset() { model.say("Ключи созданы заново"); await model.loadChats() } else { model.say("Не удалось, попробуйте ещё раз") } }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Будут созданы новые ключи. Старые личные переписки останутся зашифрованными и прочитать их будет нельзя. Новые сообщения будут работать как обычно.")
        }
    }
}

struct E2EBackupView: View {
    @ObservedObject var e2e = E2E.shared
    @EnvironmentObject var model: AppModel
    @State private var pw = ""
    @State private var pw2 = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "key.fill").font(.system(size: 42)).foregroundStyle(Theme.accent).padding(.top, 34)
                Text(e2e.backedUp ? "Новый пароль копии" : "Сохраните ключи").font(.title3.bold()).foregroundColor(Theme.text)
                Text("Ключи шифрования хранятся только на вашем устройстве. Придумайте пароль резервной копии — с ним переписки можно будет прочитать на новом телефоне. Если пароль забыть, старые сообщения восстановить будет нельзя: мы их прочитать не можем.")
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                SecureField("Пароль (не меньше 8 символов)", text: $pw)
                    .padding(.horizontal, 16).frame(minHeight: 52).background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.text)
                SecureField("Повторите пароль", text: $pw2)
                    .padding(.horizontal, 16).frame(minHeight: 52).background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.text)
                GradientButton(title: "Сохранить", loading: e2e.busy) {
                    if pw.count < 8 { model.say("Пароль слишком короткий"); return }
                    if pw != pw2 { model.say("Пароли не совпадают"); return }
                    Task { model.say(await e2e.createBackup(pw) ? "Резервная копия сохранена" : "Не удалось сохранить, попробуйте ещё раз") }
                }
                Button("Позже") { e2e.skipBackup() }.foregroundColor(Theme.muted).padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

/// Код безопасности чата: совпадает у обоих собеседников, если между вами нет подмены ключей
struct SafetyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var e2e = E2E.shared
    let peerId: String

    var body: some View {
        let code = e2e.safety(peerId)
        VStack(spacing: 16) {
            Image(systemName: "lock.fill").font(.system(size: 40)).foregroundStyle(Theme.accent).padding(.top, 34)
            Text("Код безопасности").font(.title3.bold()).foregroundColor(Theme.text)
            if let c = code {
                Text(c).font(.system(size: 22, weight: .semibold, design: .monospaced)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                Text("Сравните этот код с кодом у собеседника при встрече или по звонку. Если коды совпадают — переписка защищена от подмены."
                     + (e2e.changed.contains(peerId) ? "\n\n⚠️ Ключ собеседника изменился с прошлого раза (например, он сменил телефон или сбросил ключи)." : ""))
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            } else {
                Text("У собеседника пока нет ключа шифрования — сообщения ему идут без сквозного шифрования.")
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center)
            }
            Spacer()
            GradientButton(title: "Закрыть") { dismiss() }
        }
        .padding(24)
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.medium])
        .task { await E2E.shared.prefetch([peerId]) }
    }
}
