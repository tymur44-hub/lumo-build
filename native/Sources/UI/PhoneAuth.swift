import SwiftUI

extension AppModel {
    /// Войти по одноразовому токену, который выдал сервер после проверки кода
    func phoneLogin(_ tokenHash: String, created: Bool) async throws {
        try await API.shared.verifyMagic(tokenHash)
        loggedIn = true
        await start()
        if created {
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                say("Аккаунт создан — имя и юзернейм можно поменять в настройках")
            }
        }
    }
}

enum PhoneMode { case login, bind }

/// Номер → код → (имя) → (пароль двухэтапной защиты) → анимация успеха
struct PhoneAuthView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var store = PhoneStore.shared
    let mode: PhoneMode
    var required = false
    var onClose: (() -> Void)?

    private enum Step { case phone, code, name, tfa, done }
    @State private var step: Step = .phone
    @State private var digits = ""          // 10 цифр после +7
    @State private var code = ""
    @State private var name = ""
    @State private var tfaPwd = ""
    @State private var tfaHint = ""
    @State private var error: String?
    @State private var busy = false
    @State private var resend = 0
    @State private var isNew = false
    @State private var resetNote: String?
    @FocusState private var focus: Bool

    private var full: String { "7" + digits }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.4, speed: 0.6, base: Theme.bg, dim: 0).ignoresSafeArea()
            if step == .done {
                SuccessBurst(title: mode == .bind ? "Номер привязан" : "Готово")
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        if step != .phone || !required {
                            Button { back() } label: {
                                Image(systemName: step == .phone ? "xmark" : "chevron.left").font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.text).frame(width: 40, height: 40).background(.ultraThinMaterial, in: Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.top, 10)
                    ScrollView {
                        VStack(spacing: 14) {
                            Image(systemName: icon).font(.system(size: 34, weight: .semibold)).foregroundColor(.white)
                                .frame(width: 84, height: 84).background(Circle().fill(Theme.accent))
                                .shadow(color: Theme.a1.opacity(0.4), radius: 14, y: 6).padding(.top, 30)
                            Text(title).font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                            Text(subtitle).font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 20)
                            content.padding(.top, 8)
                            if let e = error { Text(e).font(.subheadline).foregroundColor(Theme.danger).multilineTextAlignment(.center) }
                            if let r = resetNote { Text(r).font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center) }
                        }
                        .padding(.horizontal, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .onAppear { focus = true }
        .task(id: resend) {
            guard resend > 0 else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if resend > 0 { resend -= 1 }
        }
    }

    private var icon: String {
        switch step { case .phone: return "phone.fill"; case .code: return "message.fill"; case .name: return "person.fill"; case .tfa: return "lock.fill"; case .done: return "checkmark" }
    }
    private var title: String {
        switch step {
        case .phone: return mode == .bind ? "Привяжите номер телефона" : "Ваш номер телефона"
        case .code: return "Введите код"
        case .name: return "Как вас зовут?"
        case .tfa: return "Пароль защиты"
        case .done: return ""
        }
    }
    private var subtitle: String {
        switch step {
        case .phone: return mode == .bind ? "Номер нужен для входа и защиты аккаунта. Видеть его можно ограничить в настройках." : "Мы отправим SMS с кодом. Если аккаунта ещё нет — он создастся."
        case .code: return "Код отправлен на " + PhoneStore.pretty(full)
        case .name: return "Это имя увидят ваши контакты. Его можно поменять позже."
        case .tfa: return "Для аккаунта включена двухэтапная аутентификация. Введите пароль." + (tfaHint.isEmpty ? "" : "\nПодсказка: " + tfaHint)
        case .done: return ""
        }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .phone:
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Text("🇷🇺 +7").font(.system(size: 20, weight: .semibold)).foregroundColor(Theme.text)
                    TextField("900 123-45-67", text: Binding(get: { format(digits) }, set: { v in
                        var d = v.filter { $0.isNumber }
                        if d.hasPrefix("7") && d.count > 10 { d.removeFirst() }
                        if d.hasPrefix("8") && d.count > 10 { d.removeFirst() }
                        digits = String(d.prefix(10)); error = nil
                    }))
                    .keyboardType(.numberPad).font(.system(size: 20, weight: .semibold)).focused($focus).textContentType(.telephoneNumber)
                }
                .padding(.horizontal, 16).frame(height: 56)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                GradientButton(title: "Получить код", loading: busy) { sendCode() }
                    .opacity(digits.count == 10 ? 1 : 0.5).disabled(digits.count != 10)
                if mode == .bind && !required {
                    // отсрочка доступна только один раз
                    EmptyView()
                }
            }
        case .code:
            VStack(spacing: 18) {
                ZStack {
                    TextField("", text: Binding(get: { code }, set: { v in
                        code = String(v.filter { $0.isNumber }.prefix(5)); error = nil
                        if code.count == 5 { verify() }
                    }))
                    .keyboardType(.numberPad).textContentType(.oneTimeCode).focused($focus).opacity(0.01).frame(width: 1, height: 1)
                    HStack(spacing: 10) {
                        ForEach(0..<5, id: \.self) { i in
                            let ch = i < code.count ? String(Array(code)[i]) : ""
                            Text(ch).font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.text)
                                .frame(width: 54, height: 66)
                                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(i == code.count ? Theme.a1 : (error != nil ? Theme.danger.opacity(0.6) : .clear), lineWidth: 2))
                                .scaleEffect(i == code.count - 1 ? 1.06 : 1)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: code.count)
                        }
                    }
                    .contentShape(Rectangle()).onTapGesture { focus = true }
                }
                if busy { ProgressView() }
                Button { if resend == 0 { sendCode() } } label: {
                    Text(resend > 0 ? "Отправить ещё раз через \(resend) с" : "Отправить код ещё раз").font(.system(size: 15, weight: .semibold))
                        .foregroundColor(resend > 0 ? Theme.muted : Theme.a1)
                }
                Button("Изменить номер") { code = ""; error = nil; step = .phone }.font(.footnote.weight(.semibold))
            }
        case .name:
            VStack(spacing: 14) {
                TextField("Имя", text: $name).textContentType(.name).lumoField().focused($focus)
                GradientButton(title: "Продолжить", loading: busy) { verify() }
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        case .tfa:
            VStack(spacing: 14) {
                SecureField("Пароль", text: $tfaPwd).lumoField().focused($focus)
                GradientButton(title: "Войти", loading: busy) { verify() }
                    .opacity(tfaPwd.isEmpty ? 0.5 : 1).disabled(tfaPwd.isEmpty)
                Button("Забыли пароль?") { verify(reset: true) }.font(.footnote.weight(.semibold))
            }
        case .done: EmptyView()
        }
    }

    private func format(_ d: String) -> String {
        let a = Array(d); var s = ""
        for (i, c) in a.enumerated() {
            if i == 3 || i == 6 { s += (i == 3 ? " " : "-") }
            if i == 8 { s += "-" }
            s.append(c)
        }
        return s
    }

    private func back() {
        error = nil; resetNote = nil
        switch step {
        case .phone: onClose?()
        case .code: code = ""; step = .phone
        case .name, .tfa: code = ""; tfaPwd = ""; step = .code
        case .done: break
        }
    }

    private func fail(_ j: JSON) {
        let c = j.str("error") ?? ""
        error = PhoneStore.message(c, j)
        if c == "bad_code" || c == "expired" || c == "locked" { UINotificationFeedbackGenerator().notificationOccurred(.error); code = "" }
        if c == "bad_tfa" { UINotificationFeedbackGenerator().notificationOccurred(.error); tfaPwd = "" }
    }

    private func sendCode() {
        guard digits.count == 10, !busy else { return }
        busy = true; error = nil
        Task {
            defer { busy = false }
            do {
                let j = try await store.call("send", ["phone": full, "purpose": mode == .bind ? "bind" : "auth"], auth: mode == .bind)
                if j.str("error") != nil { fail(j); return }
                code = ""; resend = 45; step = .code; focus = true
            } catch { self.error = "Нет соединения. Попробуйте ещё раз" }
        }
    }

    private func verify(reset: Bool = false) {
        guard !busy else { return }
        busy = true; error = nil
        Task {
            defer { busy = false }
            var body: JSON = ["phone": full, "code": code, "purpose": mode == .bind ? "bind" : "auth"]
            if !name.trimmingCharacters(in: .whitespaces).isEmpty { body["name"] = name.trimmingCharacters(in: .whitespaces) }
            if !tfaPwd.isEmpty { body["tfa"] = tfaPwd }
            if reset { body["reset_tfa"] = true }
            do {
                let j = try await store.call("verify", body, auth: mode == .bind)
                if j.str("error") != nil { fail(j); if j.str("error") == "expired" || j.str("error") == "locked" { step = .code }; return }
                if (j["need_name"] as? Bool) == true { step = .name; return }
                if (j["need_tfa"] as? Bool) == true { tfaHint = j.str("hint") ?? ""; step = .tfa; return }
                if (j["reset_pending"] as? Bool) == true {
                    resetNote = "Запрос на сброс пароля принят. Сбросить его можно через 7 дней: повторите вход и нажмите «Забыли пароль?»."
                    return
                }
                if mode == .bind {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation { step = .done }
                    await store.load()
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    onClose?()
                } else if let th = j.str("token_hash") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    isNew = (j["created"] as? Bool) ?? false
                    withAnimation { step = .done }
                    try? await Task.sleep(nanoseconds: 1_600_000_000)
                    try await model.phoneLogin(th, created: isNew)
                    onClose?()
                }
            } catch { self.error = "Нет соединения. Попробуйте ещё раз" }
        }
    }
}

/// Красивая анимация после верного кода: круг рисуется, галочка, волны и искры
struct SuccessBurst: View {
    let title: String
    @State private var ring: CGFloat = 0
    @State private var fill = false
    @State private var check: CGFloat = 0
    @State private var wave = false
    @State private var spark = false

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle().stroke(Theme.a1.opacity(wave ? 0 : 0.5), lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .scaleEffect(wave ? 2.4 + CGFloat(i) * 0.5 : 1)
                        .animation(.easeOut(duration: 1.3).delay(0.45 + Double(i) * 0.18), value: wave)
                }
                ForEach(0..<14, id: \.self) { i in
                    let a = Double(i) / 14 * 2 * .pi
                    Circle().fill([Theme.a1, Theme.a2, Color.yellow, Color.pink][i % 4])
                        .frame(width: i % 2 == 0 ? 9 : 6, height: i % 2 == 0 ? 9 : 6)
                        .offset(x: spark ? CGFloat(cos(a)) * 110 : 0, y: spark ? CGFloat(sin(a)) * 110 : 0)
                        .scaleEffect(spark ? 0.2 : 1).opacity(spark ? 0 : 1)
                        .animation(.easeOut(duration: 0.9).delay(0.5), value: spark)
                }
                Circle().trim(from: 0, to: ring).stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 112, height: 112)
                Circle().fill(Theme.accent).frame(width: 112, height: 112).scaleEffect(fill ? 1 : 0.2).opacity(fill ? 1 : 0)
                CheckShape().trim(from: 0, to: check).stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .frame(width: 50, height: 38)
            }
            .frame(height: 260)
            Text(title).font(.system(size: 28, weight: .heavy)).foregroundColor(Theme.text).opacity(fill ? 1 : 0).offset(y: fill ? 0 : 12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) { ring = 1 }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.4)) { fill = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.65)) { check = 1 }
            wave = true; spark = true
        }
    }
}

struct CheckShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + 2))
        p.addLine(to: CGPoint(x: r.width * 0.36, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        return p
    }
}

/// Напоминание «привяжите номер»: отсрочка на 7 дней один раз, потом привязка обязательна
struct PhoneReminderSheet: View {
    @ObservedObject private var store = PhoneStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var bind = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.badge.checkmark").font(.system(size: 40)).foregroundColor(.white)
                .frame(width: 88, height: 88).background(Circle().fill(Theme.accent)).padding(.top, 30)
            Text("Привяжите номер телефона").font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.text).multilineTextAlignment(.center)
            Text(store.status == "remind"
                 ? "Теперь в Lumo можно входить по номеру и защитить аккаунт кодом. Привязать номер нужно в течение 7 дней."
                 : "Привязать номер нужно до " + (store.skipText) + ". После этого пользоваться Lumo без номера будет нельзя.")
                .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 24)
            Spacer()
            GradientButton(title: "Привязать номер") { bind = true }.padding(.horizontal, 24)
            Button(store.status == "remind" ? "Напомнить через 7 дней" : "Позже") {
                Task { if store.status == "remind" { await store.skip() }; store.reminderShown = true; dismiss() }
            }.font(.system(size: 16, weight: .semibold)).padding(.bottom, 20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .fullScreenCover(isPresented: $bind) { PhoneAuthView(mode: .bind) { bind = false; if store.phone != nil { dismiss() } } }
        .presentationDetents([.large])
    }
}

