import SwiftUI
import Charts

/// Содержимое отчёта. На экране — с анимациями, в PDF — сразу в конечном виде.
struct ReportContent: View {
    let report: SalesReport
    let palette: Palette

    private var animated: Bool { palette.animated }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header.appear(0, enabled: animated)
            FoundCard(report: report, palette: palette).appear(1, enabled: animated)
            kpis.appear(2, enabled: animated)

            insightsSection.appear(3, enabled: animated)

            if animated {
                DynamicsCard(report: report, palette: palette).appear(4)
            } else {
                printCharts
            }

            if report.stores.count > 1 {
                SectionCard("Как продаёт сеть", icon: "building.2.fill", palette: palette) {
                    VStack(spacing: 14) {
                        ForEach(Array(report.stores.enumerated()), id: \.element.id) { i, s in
                            GroupBar(
                                title: s.name,
                                value: "\(Fmt.rub(s.perDay)) в день",
                                caption: "Средний чек \(Fmt.rub(s.avgCheck)) · \(Fmt.pct(s.share)) выручки",
                                fraction: s.share / max(report.stores.first?.share ?? 1, 0.0001),
                                palette: palette,
                                delay: Double(i) * 0.08)
                        }
                    }
                }
                .appear(5, enabled: animated)
            }

            if !report.items.isEmpty {
                ItemsCard(report: report, palette: palette).appear(6, enabled: animated)
            }

            if report.categories.count > 1 {
                SectionCard("Категории", icon: "square.grid.2x2.fill", palette: palette) {
                    VStack(spacing: 14) {
                        ForEach(Array(report.categories.enumerated()), id: \.element.id) { i, c in
                            GroupBar(
                                title: c.name,
                                value: Fmt.rub(c.revenue),
                                caption: "\(Fmt.pct(c.share)) выручки",
                                fraction: c.share / max(report.categories.first?.share ?? 1, 0.0001),
                                palette: palette,
                                delay: Double(i) * 0.06)
                        }
                    }
                }
                .appear(7, enabled: animated)
            }

            Text("Суммы находок — оценка того, сколько можно вернуть, если подтянуть слабые места. «В месяц» — пересчёт на 30 дней.")
                .font(.caption)
                .foregroundStyle(palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .foregroundStyle(palette.text)
    }

    // MARK: Шапка

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: report.isDemo ? "play.circle.fill" : "checkmark.seal.fill")
                Text(report.isDemo ? "Пример отчёта" : "Отчёт по продажам")
            }
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(Theme.gold)
            Text(report.periodTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            HStack(spacing: 6) {
                Image(systemName: "doc")
                Text(report.fileName).lineLimit(1)
                Text("·")
                Text("\(report.dayCount) дн.")
            }
            .font(.footnote)
            .foregroundStyle(palette.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var kpis: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                KPI(title: "Выручка", value: report.revenue, format: Fmt.rub, icon: "banknote", palette: palette)
                KPI(title: report.checksEstimated ? "Продаж" : "Чеков", value: Double(report.checks), format: Fmt.int, icon: "person.2", palette: palette)
            }
            GridRow {
                KPI(title: report.checksEstimated ? "Средняя продажа" : "Средний чек", value: report.avgCheck, format: Fmt.rub, icon: "receipt", palette: palette)
                if let gp = report.grossProfit {
                    KPI(title: "Валовая прибыль", value: gp, format: Fmt.rub, icon: "chart.line.uptrend.xyaxis", palette: palette)
                } else {
                    KPI(title: "Скидки", value: report.discountTotal, format: Fmt.rub, icon: "tag", palette: palette)
                }
            }
        }
    }

    // MARK: Находки

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Находки")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Spacer()
                Text("\(report.insights.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.goldGradient, in: Capsule())
            }
            .padding(.horizontal, 4)
            InsightsList(report: report, palette: palette)
        }
    }

    // MARK: Графики для PDF

    @ViewBuilder
    private var printCharts: some View {
        if report.daily.count > 1 {
            SectionCard("Выручка по дням", icon: "chart.bar.fill", palette: palette) {
                RevenueChart(kind: .days, report: report, palette: palette).frame(height: 170)
            }
        }
        if !report.hourly.isEmpty {
            SectionCard("Выручка по часам", icon: "clock.fill", palette: palette) {
                RevenueChart(kind: .hours, report: report, palette: palette).frame(height: 160)
            }
        }
        if report.weekdays.count > 1 {
            SectionCard("Дни недели", icon: "calendar", palette: palette) {
                RevenueChart(kind: .weekdays, report: report, palette: palette).frame(height: 150)
            }
        }
    }
}

// MARK: - Карточка «Можно вернуть»

private struct FoundCard: View {
    let report: SalesReport
    let palette: Palette
    @State private var glow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Можно вернуть в месяц")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondary)
                    CountingText(value: report.foundPerMonth, animated: palette.animated)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.goldGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Spacer(minLength: 8)
                Image(systemName: "rublesign.circle.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.goldLight, Theme.goldDeep)
                    .shadow(color: Theme.gold.opacity(glow ? 0.7 : 0.2), radius: glow ? 18 : 6)
                    .scaleEffect(glow ? 1.05 : 1)
            }
            let share = report.revenue > 0 ? report.foundInPeriod / report.revenue : 0
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("За период файла: \(Fmt.rub(report.foundInPeriod))")
                    Spacer()
                    Text("\(Fmt.pct(share)) выручки")
                }
                .font(.caption)
                .foregroundStyle(palette.secondary)
                GroupBarTrack(fraction: min(share * 4, 1), palette: palette, delay: 0.4)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [Theme.gold.opacity(0.24), palette.card, palette.card],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Theme.gold.opacity(0.35)))
        .onAppear {
            guard palette.animated else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

private struct KPI: View {
    let title: String
    let value: Double
    let format: (Double) -> String
    let icon: String
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                Spacer()
            }
            CountingText(value: value, animated: palette.animated, format: format)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title).font(.caption).foregroundStyle(palette.secondary)
        }
        .card(palette, radius: 18, padding: 14)
    }
}

// MARK: - Находки

private struct InsightsList: View {
    let report: SalesReport
    let palette: Palette
    @State private var expanded: Set<UUID> = []
    @State private var didInit = false

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(report.insights.enumerated()), id: \.element.id) { i, insight in
                InsightCard(
                    number: i + 1,
                    insight: insight,
                    monthFactor: report.monthFactor,
                    palette: palette,
                    expanded: !palette.animated || expanded.contains(insight.id)
                ) {
                    Haptics.soft()
                    withAnimation(Theme.spring) {
                        if expanded.contains(insight.id) { expanded.remove(insight.id) } else { expanded.insert(insight.id) }
                    }
                }
            }
        }
        .onAppear {
            guard !didInit, let first = report.insights.first else { return }
            didInit = true
            expanded = [first.id]
        }
    }
}

private struct InsightCard: View {
    let number: Int
    let insight: Insight
    let monthFactor: Double
    let palette: Palette
    let expanded: Bool
    let onTap: () -> Void

    private var color: Color {
        switch insight.level {
        case .high: return Theme.danger
        case .medium: return .orange
        case .low: return Theme.gold
        }
    }

    private var levelText: String {
        switch insight.level {
        case .high: return "Важно"
        case .medium: return "Стоит проверить"
        case .low: return "На заметку"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 42, height: 42)
                        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Находка \(number)")
                            Circle().fill(color).frame(width: 4, height: 4)
                            Text(levelText).foregroundStyle(color)
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(palette.secondary)
                        Text(insight.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.text)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 6) {
                        if let a = insight.amount, a > 0 {
                            Text("+" + Fmt.compact(a * monthFactor) + " ₽")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.gold)
                            Text("в месяц").font(.caption2).foregroundStyle(palette.secondary)
                        }
                        if palette.animated {
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(palette.secondary)
                                .rotationEffect(.degrees(expanded ? 180 : 0))
                        }
                    }
                }
                if expanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle().fill(palette.stroke).frame(height: 1)
                        Label {
                            Text(insight.detail)
                                .font(.footnote)
                                .foregroundStyle(palette.text.opacity(0.85))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "lightbulb.fill").foregroundStyle(Theme.gold)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .card(palette, radius: 18, padding: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(color.opacity(expanded && palette.animated ? 0.35 : 0), lineWidth: 1))
        }
        .buttonStyle(PressableStyle(scale: 0.985))
        .disabled(!palette.animated)
    }
}

// MARK: - Динамика (переключаемые графики)

enum ChartKind: Hashable { case days, hours, weekdays }

private struct DynamicsCard: View {
    let report: SalesReport
    let palette: Palette
    @State private var kind: ChartKind = .days

    private var kinds: [(ChartKind, String)] {
        var k: [(ChartKind, String)] = []
        if report.daily.count > 1 { k.append((.days, "Дни")) }
        if !report.hourly.isEmpty { k.append((.hours, "Часы")) }
        if report.weekdays.count > 1 { k.append((.weekdays, "Неделя")) }
        return k
    }

    private var caption: String {
        switch kind {
        case .days: return "Выручка за каждый день периода."
        case .hours: return "В среднем за рабочий день. Красным — часы, где выручка вдвое ниже обычной."
        case .weekdays: return "Средняя выручка по дням недели. Красным — дни на 20% ниже среднего."
        }
    }

    var body: some View {
        if !kinds.isEmpty {
            SectionCard("Динамика", icon: "chart.xyaxis.line", palette: palette) {
                if kinds.count > 1 {
                    SegmentedTabs(items: kinds, selection: $kind)
                }
                RevenueChart(kind: kind, report: report, palette: palette)
                    .id(kind)
                    .frame(height: 190)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)), removal: .opacity))
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(palette.secondary)
                    .contentTransition(.opacity)
            }
            .animation(Theme.spring, value: kind)
            .onAppear {
                if let first = kinds.first?.0, !kinds.contains(where: { $0.0 == kind }) { kind = first }
            }
        }
    }
}

struct RevenueChart: View {
    let kind: ChartKind
    let report: SalesReport
    let palette: Palette
    @State private var progress: Double = 0

    private var p: Double { palette.animated ? progress : 1 }

    var body: some View {
        chart
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(palette.stroke)
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(Fmt.compact(d)).foregroundStyle(palette.secondary)
                        }
                    }
                }
            }
            .onAppear {
                guard palette.animated else { return }
                progress = 0
                withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1)) { progress = 1 }
            }
    }

    @ViewBuilder
    private var chart: some View {
        switch kind {
        case .days:
            let maxV = report.daily.map(\.revenue).max() ?? 1
            Chart(report.daily) { d in
                BarMark(x: .value("День", d.date, unit: .day), y: .value("Выручка", d.revenue * p))
                    .foregroundStyle(Theme.goldGradient)
                    .cornerRadius(3)
            }
            .chartYScale(domain: 0...(maxV * 1.08))
        case .hours:
            let med = ReportBuilder.median(report.hourly.map(\.avgRevenue))
            let maxV = report.hourly.map(\.avgRevenue).max() ?? 1
            Chart(report.hourly) { h in
                BarMark(x: .value("Час", "\(h.hour)"), y: .value("Выручка", h.avgRevenue * p))
                    .foregroundStyle(h.avgRevenue < med * 0.5 ? AnyShapeStyle(Theme.danger) : AnyShapeStyle(Theme.goldGradient))
                    .cornerRadius(4)
            }
            .chartYScale(domain: 0...(maxV * 1.08))
        case .weekdays:
            let mean = report.weekdays.reduce(0) { $0 + $1.avgRevenue } / Double(max(report.weekdays.count, 1))
            let maxV = report.weekdays.map(\.avgRevenue).max() ?? 1
            Chart(report.weekdays) { w in
                BarMark(x: .value("День", w.name), y: .value("Выручка", w.avgRevenue * p))
                    .foregroundStyle(w.avgRevenue < mean * 0.8 ? AnyShapeStyle(Theme.danger) : AnyShapeStyle(Theme.goldGradient))
                    .cornerRadius(6)
                RuleMark(y: .value("Среднее", mean))
                    .foregroundStyle(palette.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYScale(domain: 0...(maxV * 1.08))
        }
    }
}

// MARK: - Позиции

private struct ItemsCard: View {
    let report: SalesReport
    let palette: Palette
    @State private var showAll = false

    private var visible: [ItemStat] {
        let limit = palette.animated ? (showAll ? 30 : 7) : 10
        return Array(report.items.prefix(limit))
    }

    var body: some View {
        SectionCard("Топ позиций", icon: "list.number", palette: palette) {
            VStack(spacing: 12) {
                ForEach(Array(visible.enumerated()), id: \.element.id) { i, item in
                    ItemRow(rank: i + 1, item: item, maxShare: report.items.first?.share ?? 1, palette: palette)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            if palette.animated && report.items.count > 7 {
                Button {
                    Haptics.soft()
                    withAnimation(Theme.spring) { showAll.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Text(showAll ? "Свернуть" : "Показать все (\(min(report.items.count, 30)))")
                        Image(systemName: "chevron.down").rotationEffect(.degrees(showAll ? 180 : 0))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressableStyle())
            }
            Text("A — 80% выручки, B — следующие 15%, C — последние 5%.")
                .font(.caption)
                .foregroundStyle(palette.secondary)
        }
    }
}

private struct ItemRow: View {
    let rank: Int
    let item: ItemStat
    let maxShare: Double
    let palette: Palette

    private var badgeColor: Color {
        switch item.abc {
        case "A": return Theme.gold
        case "B": return .orange
        default: return palette.secondary
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Text(item.abc)
                    .font(.caption.bold())
                    .foregroundStyle(badgeColor)
                    .frame(width: 24, height: 24)
                    .background(badgeColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.subheadline.weight(.medium)).foregroundStyle(palette.text).lineLimit(1)
                    Text(caption).font(.caption2).foregroundStyle(palette.secondary)
                }
                Spacer(minLength: 8)
                Text(Fmt.rub(item.revenue))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.text)
            }
            GroupBarTrack(fraction: item.share / max(maxShare, 0.0001), palette: palette, delay: Double(rank) * 0.04, height: 4)
                .padding(.leading, 34)
        }
    }

    private var caption: String {
        var parts = ["\(Fmt.num(item.quantity)) шт", Fmt.pct(item.share)]
        if let m = item.margin { parts.append("маржа \(Fmt.pct(m))") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Общие блоки

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let palette: Palette
    let content: Content

    init(_ title: String, icon: String, palette: Palette, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.palette = palette
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 28, height: 28)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title).font(.system(.headline, design: .rounded)).foregroundStyle(palette.text)
            }
            content
        }
        .card(palette, radius: 22, padding: 16)
    }
}

private struct GroupBar: View {
    let title: String
    let value: String
    let caption: String
    let fraction: Double
    let palette: Palette
    var delay: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(palette.text).lineLimit(1)
                Spacer()
                Text(value).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(palette.text)
            }
            GroupBarTrack(fraction: fraction, palette: palette, delay: delay)
            Text(caption).font(.caption).foregroundStyle(palette.secondary)
        }
    }
}

private struct GroupBarTrack: View {
    let fraction: Double
    let palette: Palette
    var delay: Double = 0
    var height: CGFloat = 7
    @State private var shown: Double = 0

    var body: some View {
        let f = min(max(palette.animated ? shown : fraction, 0), 1)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.stroke)
                Capsule().fill(Theme.goldGradient)
                    .frame(width: max(height, geo.size.width * f))
            }
        }
        .frame(height: height)
        .onAppear {
            guard palette.animated else { return }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.2 + delay)) { shown = fraction.isFinite ? fraction : 0 }
        }
    }
}
