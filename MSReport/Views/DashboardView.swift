import SwiftUI

struct DashboardView: View {
    @Binding var tab: AppTab
    @Environment(ReportStore.self) private var store
    @Environment(ProfileStore.self) private var profileStore
    @Environment(ImportFlow.self) private var flow
    @State private var path: [UUID] = []

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header.appear(0)

                    if let latest = store.latest {
                        latestCard(latest).appear(1)
                        kpis(latest).appear(2)
                        if let goal = goalCard(latest) { goal.appear(3) }
                        topInsights(latest).appear(4)
                    } else {
                        emptyHero.appear(1)
                    }

                    quickActions.appear(5)
                    tipOfDay.appear(6)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let r = store.reports.first(where: { $0.id == id }) {
                    ReportView(report: r)
                }
            }
        }
    }

    // MARK: Шапка

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting + (profileStore.profile.name.isEmpty ? "" : ","))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(profileStore.profile.name.isEmpty ? "M.S Отчёт" : profileStore.profile.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !profileStore.profile.shopName.isEmpty {
                    Label(profileStore.profile.shopName, systemImage: "cup.and.saucer.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.gold)
                }
            }
            Spacer()
            Button {
                Haptics.soft()
                withAnimation(Theme.snappy) { tab = .profile }
            } label: {
                AvatarView(initials: profileStore.profile.initials, size: 50)
            }
            .buttonStyle(PressableStyle(scale: 0.9))
        }
        .padding(.top, 6)
    }

    // MARK: Последний отчёт

    private func latestCard(_ r: SalesReport) -> some View {
        Button {
            Haptics.tap()
            path.append(r.id)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Последний отчёт", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.gold)
                    Spacer()
                    Text(r.periodTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Можно вернуть в месяц")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    CountingText(value: r.foundPerMonth)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.goldGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Sparkline(values: r.daily.map(\.revenue))
                    .frame(height: 64)
                HStack {
                    Text("\(r.insights.filter { ($0.amount ?? 0) > 0 }.count) находок")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Открыть отчёт")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.gold.opacity(0.24), Theme.card, Theme.card],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.gold.opacity(0.3)))
            .shadow(color: Theme.gold.opacity(0.12), radius: 24, y: 10)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private func kpis(_ r: SalesReport) -> some View {
        let prev = store.previous
        return HStack(spacing: 10) {
            kpi("Выручка", value: Fmt.compact(r.revenue) + " ₽", current: r.revenue / Double(max(r.dayCount, 1)),
                previous: prev.map { $0.revenue / Double(max($0.dayCount, 1)) }, icon: "banknote")
            kpi(r.checksEstimated ? "Ср. продажа" : "Ср. чек", value: Fmt.rub(r.avgCheck), current: r.avgCheck,
                previous: prev?.avgCheck, icon: "receipt")
            kpi(r.checksEstimated ? "Продаж" : "Чеков", value: Fmt.int(Double(r.checks)),
                current: Double(r.checks) / Double(max(r.dayCount, 1)),
                previous: prev.map { Double($0.checks) / Double(max($0.dayCount, 1)) }, icon: "person.2")
        }
    }

    private func kpi(_ title: String, value: String, current: Double, previous: Double?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 30, height: 30)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 4) {
                Text(title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Spacer(minLength: 0)
                DeltaBadge(current: current, previous: previous)
            }
        }
        .card(radius: 18, padding: 12)
    }

    private func goalCard(_ r: SalesReport) -> AnyView? {
        let goal = profileStore.profile.monthlyGoal
        guard goal > 0 else { return nil }
        let monthRevenue = r.revenue * r.monthFactor
        let progress = monthRevenue / goal
        return AnyView(
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: progress, lineWidth: 9)
                    Text(Fmt.pct(min(progress, 9.99)))
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                }
                .frame(width: 70, height: 70)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Цель на месяц").font(.caption).foregroundStyle(.secondary)
                    Text(Fmt.rub(goal)).font(.system(.headline, design: .rounded))
                    Text(progress >= 1
                         ? "Темп выше цели — отлично"
                         : "Не хватает \(Fmt.rub(goal - monthRevenue)). Находки закрывают \(Fmt.pct(min(r.foundPerMonth / max(goal - monthRevenue, 1), 1)))")
                        .font(.caption)
                        .foregroundStyle(progress >= 1 ? Theme.success : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .card(radius: 22, padding: 16)
        )
    }

    private func topInsights(_ r: SalesReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Главные находки", action: "Все") {
                Haptics.tap()
                path.append(r.id)
            }
            VStack(spacing: 10) {
                ForEach(Array(r.insights.prefix(3).enumerated()), id: \.element.id) { i, ins in
                    HStack(spacing: 12) {
                        Text("\(i + 1)")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 26, height: 26)
                            .background(Theme.goldGradient, in: Circle())
                        Text(ins.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        if let a = ins.amount, a > 0 {
                            Text("+" + Fmt.compact(a * r.monthFactor) + " ₽")
                                .font(.system(.footnote, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    .card(radius: 16, padding: 12)
                }
            }
        }
    }

    // MARK: Пусто

    private var emptyHero: some View {
        VStack(spacing: 18) {
            GrowthIllustration()
                .padding(.top, 10)
            VStack(spacing: 8) {
                Text("Найдём деньги, которые теряет ваша кофейня")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Загрузите выгрузку продаж из кассы — Excel или CSV. Нужны хотя бы дата и сумма.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                Button {
                    flow.startImport()
                } label: {
                    Label("Загрузить выгрузку", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(GoldButtonStyle())
                Button {
                    flow.showDemo()
                } label: {
                    Label("Посмотреть на примере", systemImage: "play.circle")
                }
                .buttonStyle(GhostButtonStyle())
            }
            Label("Файл обрабатывается на телефоне", systemImage: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Theme.gold.opacity(0.16), Theme.card], startPoint: .top, endPoint: .bottom))
        }
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.gold.opacity(0.22)))
    }

    // MARK: Быстрые действия

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Быстрые действия")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                action("Новый отчёт", "Excel или CSV", icon: "plus.viewfinder") { flow.startImport() }
                action("Пример", "Отчёт на демоданных", icon: "play.rectangle") { flow.showDemo() }
                action("Мои отчёты", "\(store.reports.count) сохранено", icon: "tray.full") {
                    Haptics.soft()
                    withAnimation(Theme.snappy) { tab = .reports }
                }
                action("Полный разбор", "План на неделю", icon: "paperplane") {
                    if let url = URL(string: "https://t.me/ms_sales_report_bot") { UIApplication.shared.open(url) }
                }
            }
        }
    }

    private func action(_ title: String, _ subtitle: String, icon: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .card(radius: 18, padding: 14)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Совет дня

    private var tipOfDay: some View {
        let tip = Tip.ofTheDay
        return Button {
            Haptics.soft()
            withAnimation(Theme.snappy) { tab = .tips }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: tip.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.gold)
                    .symbolEffect(.pulse, options: .repeating)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Совет дня").font(.caption.weight(.semibold)).textCase(.uppercase).foregroundStyle(Theme.gold)
                    Text(tip.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(tip.summary).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .card(radius: 20, padding: 16)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }
}
