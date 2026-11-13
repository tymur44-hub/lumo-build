import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home, reports, tips, profile

    var title: String {
        switch self {
        case .home: return "Главная"
        case .reports: return "Отчёты"
        case .tips: return "Советы"
        case .profile: return "Кабинет"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .reports: return "chart.bar.doc.horizontal"
        case .tips: return "lightbulb"
        case .profile: return "person.crop.circle"
        }
    }

    var activeIcon: String {
        switch self {
        case .home: return "house.fill"
        case .reports: return "chart.bar.doc.horizontal.fill"
        case .tips: return "lightbulb.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct RootView: View {
    @Environment(ProfileStore.self) private var profile

    var body: some View {
        ZStack {
            if profile.onboarded {
                MainView()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.04)), removal: .opacity))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: profile.onboarded)
    }
}

struct MainView: View {
    @Environment(ReportStore.self) private var store
    @Environment(ImportFlow.self) private var flow
    @State private var tab: AppTab = .home

    var body: some View {
        @Bindable var flow = flow

        ZStack {
            AmbientBackground()

            ZStack {
                DashboardView(tab: $tab).tabContent(active: tab == .home)
                ReportsListView().tabContent(active: tab == .reports)
                TipsView().tabContent(active: tab == .tips)
                ProfileView(tab: $tab).tabContent(active: tab == .profile)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TabBar(tab: $tab) { flow.startImport() }
            }

            if flow.phase != .idle {
                AnalyzingView(phase: flow.phase)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: flow.phase)
        .fileImporter(isPresented: $flow.showPicker, allowedContentTypes: FileLoader.allowedTypes) { result in
            flow.handlePicked(result)
        }
        .sheet(item: $flow.pending) { p in
            MappingView(pending: p) { confirmed in
                flow.build(confirmed, into: store)
            }
        }
        .fullScreenCover(item: $flow.presented) { report in
            NavigationStack {
                ReportView(report: report, showsClose: true)
            }
        }
        .alert("Не получилось открыть файл",
               isPresented: Binding(get: { flow.error != nil }, set: { if !$0 { flow.error = nil } })) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(flow.error ?? "")
        }
    }
}

private extension View {
    func tabContent(active: Bool) -> some View {
        self
            .opacity(active ? 1 : 0)
            .scaleEffect(active ? 1 : 0.985)
            .allowsHitTesting(active)
            .accessibilityHidden(!active)
            .animation(.easeOut(duration: 0.22), value: active)
    }
}

// MARK: - Нижняя панель

private struct TabBar: View {
    @Binding var tab: AppTab
    let onUpload: () -> Void
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            item(.home)
            item(.reports)
            uploadButton
            item(.tips)
            item(.profile)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.card.opacity(0.55)))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.stroke))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }

    private func item(_ t: AppTab) -> some View {
        let active = tab == t
        return Button {
            guard tab != t else { return }
            Haptics.soft()
            withAnimation(Theme.snappy) { tab = t }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: active ? t.activeIcon : t.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .symbolEffect(.bounce, value: active)
                Text(t.title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(active ? Theme.gold : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.gold.opacity(0.12))
                        .matchedGeometryEffect(id: "tab", in: ns)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var uploadButton: some View {
        Button(action: onUpload) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 54, height: 54)
                .background(Theme.goldGradient, in: Circle())
                .shadow(color: Theme.gold.opacity(0.5), radius: 12, y: 4)
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .padding(.horizontal, 6)
        .accessibilityLabel("Загрузить выгрузку")
    }
}

// MARK: - Экран анализа

struct AnalyzingView: View {
    let phase: ImportFlow.Phase

    private var steps: [String] {
        phase == .reading
            ? ["Открываем файл", "Ищем строку заголовков", "Определяем столбцы"]
            : ["Считаем выручку и чеки", "Разбираем часы и дни недели", "Сравниваем точки и позиции", "Ищем, где теряются деньги"]
    }

    @State private var done = 0
    @State private var spin = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(Theme.stroke, lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: 0.28)
                            .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(spin ? 360 : 0))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spin)
                        Image(systemName: phase == .reading ? "doc.text" : "chart.bar.xaxis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                            .symbolEffect(.pulse)
                    }
                    .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase == .reading ? "Читаем файл" : "Анализируем продажи")
                            .font(.system(.headline, design: .rounded))
                        Text("Всё считается на телефоне")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(spacing: 10) {
                            ZStack {
                                if i < done {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.success)
                                        .transition(.scale.combined(with: .opacity))
                                } else if i == done {
                                    ProgressView().controlSize(.mini).tint(Theme.gold)
                                } else {
                                    Circle().stroke(Theme.stroke, lineWidth: 1.5).frame(width: 14, height: 14)
                                }
                            }
                            .frame(width: 18)
                            Text("> " + steps[i])
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(i <= done ? Color.white : Color.white.opacity(0.35))
                        }
                    }
                }
                .padding(14)
                .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Theme.gold.opacity(0.25)))
            .shadow(color: Theme.gold.opacity(0.15), radius: 30)
            .padding(24)
        }
        .onAppear { spin = true }
        .task(id: phase) {
            done = 0
            for i in 1...steps.count {
                try? await Task.sleep(nanoseconds: 550_000_000)
                withAnimation(Theme.snappy) { done = i }
                Haptics.soft()
            }
        }
    }
}
