import SwiftUI

struct ProfileView: View {
    @Binding var tab: AppTab
    @Environment(ProfileStore.self) private var profileStore
    @Environment(ReportStore.self) private var store
    @Environment(ImportFlow.self) private var flow
    @State private var editing = false
    @State private var confirmDeleteAll = false
    @State private var confirmReset = false

    private var profile: UserProfile { profileStore.profile }

    var body: some View {
        @Bindable var profileStore = profileStore

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header.appear(0)
                    stats.appear(1)
                    goal.appear(2)

                    settingsGroup("Отчёты") {
                        row("Новый отчёт", icon: "plus.viewfinder") { flow.startImport() }
                        divider
                        row("Пример отчёта", icon: "play.rectangle") { flow.showDemo() }
                        divider
                        row("Все отчёты", icon: "tray.full", value: "\(store.reports.count)") {
                            withAnimation(Theme.snappy) { tab = .reports }
                        }
                    }
                    .appear(3)

                    settingsGroup("Настройки") {
                        HStack(spacing: 12) {
                            icon("hand.tap")
                            Toggle("Тактильный отклик", isOn: $profileStore.haptics)
                                .tint(Theme.gold)
                        }
                        .padding(.vertical, 10)
                        divider
                        row("Изменить профиль", icon: "pencil") { editing = true }
                    }
                    .appear(4)

                    settingsGroup("Помощь") {
                        row("Полный разбор от M.S", icon: "paperplane") {
                            open("https://t.me/ms_sales_report_bot")
                        }
                        divider
                        row("Какие кассы подходят", icon: "questionmark.circle") {
                            withAnimation(Theme.snappy) { tab = .tips }
                        }
                    }
                    .appear(5)

                    settingsGroup("Данные") {
                        row("Удалить все отчёты", icon: "trash", destructive: true) { confirmDeleteAll = true }
                        divider
                        row("Выйти и сбросить профиль", icon: "rectangle.portrait.and.arrow.right", destructive: true) { confirmReset = true }
                    }
                    .appear(6)

                    VStack(spacing: 4) {
                        Text("M.S Отчёт \(Bundle.main.appVersion)")
                        Label("Данные хранятся только на этом телефоне", systemImage: "lock.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $editing) {
                EditProfileView(profile: profile) { updated in
                    withAnimation(Theme.spring) { profileStore.profile = updated }
                    Haptics.success()
                }
            }
            .confirmationDialog("Удалить все отчёты?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Удалить \(store.reports.count)", role: .destructive) {
                    withAnimation(Theme.spring) { store.deleteAll() }
                    Haptics.warning()
                }
            } message: {
                Text("Это действие нельзя отменить.")
            }
            .confirmationDialog("Сбросить профиль?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) {
                    Haptics.warning()
                    profileStore.reset()
                }
            } message: {
                Text("Отчёты останутся, а профиль и приветственные экраны начнутся заново.")
            }
        }
    }

    // MARK: Шапка

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Theme.goldGradient, lineWidth: 2)
                    .frame(width: 104, height: 104)
                    .opacity(0.6)
                AvatarView(initials: profile.initials, size: 88)
            }
            VStack(spacing: 4) {
                Text(profile.displayName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                let line = [profile.shopName, profile.city].filter { !$0.isEmpty }.joined(separator: " · ")
                if !line.isEmpty {
                    Text(line).font(.subheadline).foregroundStyle(.secondary)
                }
                Text("В M.S \(Fmt.ago(profile.createdAt).replacingOccurrences(of: " назад", with: ""))")
                    .font(.caption)
                    .foregroundStyle(Theme.gold)
            }
            Button {
                Haptics.tap()
                editing = true
            } label: {
                Label("Редактировать", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.cardRaised, in: Capsule())
                    .overlay(Capsule().stroke(Theme.stroke))
            }
            .buttonStyle(PressableStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Theme.gold.opacity(0.18), Theme.card], startPoint: .top, endPoint: .bottom))
        }
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.gold.opacity(0.22)))
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statTile("Отчётов", value: Double(store.reports.count), format: Fmt.int, icon: "doc.on.doc")
            statTile("Найдено", value: store.totalFoundPerMonth, format: { Fmt.compact($0) + " ₽" }, icon: "rublesign.circle", caption: "в месяц")
            statTile("Точек", value: Double(profile.points), format: Fmt.int, icon: "building.2")
        }
    }

    private func statTile(_ title: String, value: Double, format: @escaping (Double) -> String, icon: String, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.gold)
            CountingText(value: value, format: format)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption.map { "\(title) \($0)" } ?? title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .card(radius: 18, padding: 12)
    }

    private var goal: some View {
        let goal = profile.monthlyGoal
        let monthRevenue = store.latest.map { $0.revenue * $0.monthFactor } ?? 0
        let progress = goal > 0 ? monthRevenue / goal : 0
        return HStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 8)
                Image(systemName: "target")
                    .font(.title3)
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 62, height: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text("Цель по выручке").font(.caption).foregroundStyle(.secondary)
                if goal > 0 {
                    Text(Fmt.rub(goal) + " в месяц").font(.system(.headline, design: .rounded))
                    Text(store.latest == nil ? "Загрузите отчёт, чтобы увидеть прогресс" : "Темп по последнему отчёту: \(Fmt.pct(progress))")
                        .font(.caption)
                        .foregroundStyle(progress >= 1 ? Theme.success : Color.secondary)
                } else {
                    Text("Не задана").font(.headline)
                    Text("Задайте цель, чтобы следить за темпом").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Button {
                Haptics.tap()
                editing = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Theme.gold)
                    .frame(width: 36, height: 36)
                    .background(Theme.gold.opacity(0.12), in: Circle())
            }
            .buttonStyle(PressableStyle(scale: 0.9))
        }
        .card(radius: 22, padding: 16)
    }

    // MARK: Группы настроек

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 6)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.stroke))
        }
    }

    private var divider: some View {
        Rectangle().fill(Theme.stroke).frame(height: 1).padding(.leading, 44)
    }

    private func icon(_ name: String, destructive: Bool = false) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(destructive ? Theme.danger : Theme.gold)
            .frame(width: 32, height: 32)
            .background((destructive ? Theme.danger : Theme.gold).opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func row(_ title: String, icon name: String, value: String? = nil, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                icon(name, destructive: destructive)
                Text(title)
                    .foregroundStyle(destructive ? Theme.danger : .white)
                Spacer()
                if let value {
                    Text(value).foregroundStyle(.secondary)
                }
                if !destructive {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private func open(_ s: String) {
        if let url = URL(string: s) { UIApplication.shared.open(url) }
    }
}

extension Bundle {
    var appVersion: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// MARK: - Редактирование профиля

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfile
    let onSave: (UserProfile) -> Void

    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        _draft = State(initialValue: profile)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        AvatarView(initials: draft.initials, size: 76)
                            .animation(Theme.snappy, value: draft.initials)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section("О вас") {
                    TextField("Имя", text: $draft.name)
                    TextField("Кофейня или сеть", text: $draft.shopName)
                    TextField("Город", text: $draft.city)
                }
                Section {
                    Stepper("Точек: \(draft.points)", value: $draft.points, in: 1...50)
                    HStack {
                        Text("Цель в месяц")
                        Spacer()
                        TextField("0", value: $draft.monthlyGoal, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("₽").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Бизнес")
                } footer: {
                    Text("Цель сравнивается с темпом выручки из последнего отчёта.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}
