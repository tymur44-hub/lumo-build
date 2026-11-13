import SwiftUI
import Charts

/// Содержимое отчёта. Используется и на экране, и в PDF.
struct ReportContent: View {
    let report: SalesReport
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            FoundCard(report: report, palette: palette)
            kpis

            SectionCard("Главные находки", icon: "sparkle.magnifyingglass", palette: palette) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(report.insights.prefix(3).enumerated()), id: \.element.id) { i, insight in
                        InsightRow(number: i + 1, insight: insight, monthFactor: report.monthFactor, palette: palette)
                    }
                }
            }

            if report.insights.count > 3 {
                SectionCard("Ещё находки", icon: "list.bullet.rectangle", palette: palette) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(report.insights.dropFirst(3).enumerated()), id: \.element.id) { i, insight in
                            InsightRow(number: i + 4, insight: insight, monthFactor: report.monthFactor, palette: palette)
                        }
                    }
                }
            }

            if report.daily.count > 1 {
                SectionCard("Выручка по дням", icon: "chart.bar.fill", palette: palette) {
                    Chart(report.daily) { p in
                        BarMark(
                            x: .value("День", p.date, unit: .day),
                            y: .value("Выручка", p.revenue)
                        )
                        .foregroundStyle(Theme.gold)
                    }
                    .chartYAxis { moneyAxis }
                    .frame(height: 180)
                }
            }

            if !report.hourly.isEmpty {
                let med = ReportBuilder.median(report.hourly.map(\.avgRevenue))
                SectionCard("Выручка по часам", icon: "clock.fill", palette: palette) {
                    Chart(report.hourly) { p in
                        BarMark(
                            x: .value("Час", "\(p.hour)"),
                            y: .value("Выручка", p.avgRevenue)
                        )
                        .foregroundStyle(p.avgRevenue < med * 0.5 ? Theme.danger : Theme.gold)
                    }
                    .chartYAxis { moneyAxis }
                    .frame(height: 170)
                    Text("В среднем за рабочий день. Красным — часы, где выручка вдвое ниже обычной.")
                        .font(.caption)
                        .foregroundStyle(palette.secondary)
                }
            }

            if report.weekdays.count > 1 {
                let mean = report.weekdays.reduce(0) { $0 + $1.avgRevenue } / Double(report.weekdays.count)
                SectionCard("Дни недели", icon: "calendar", palette: palette) {
                    Chart(report.weekdays) { p in
                        BarMark(
                            x: .value("День", p.name),
                            y: .value("Выручка", p.avgRevenue)
                        )
                        .foregroundStyle(p.avgRevenue < mean * 0.8 ? Theme.danger : Theme.gold)
                    }
                    .chartYAxis { moneyAxis }
                    .frame(height: 160)
                }
            }

            if report.stores.count > 1 {
                SectionCard("Как продаёт сеть", icon: "building.2.fill", palette: palette) {
                    VStack(spacing: 14) {
                        ForEach(report.stores) { s in
                            GroupBar(
                                title: s.name,
                                value: "\(Fmt.rub(s.perDay)) в день",
                                caption: "Средний чек \(Fmt.rub(s.avgCheck)) · \(Fmt.pct(s.share)) выручки",
                                fraction: s.share / (report.stores.first?.share ?? 1),
                                palette: palette)
                        }
                    }
                }
            }

            if !report.items.isEmpty {
                SectionCard("Топ позиций", icon: "list.number", palette: palette) {
                    VStack(spacing: 10) {
                        ForEach(report.items.prefix(10)) { item in
                            ItemRow(item: item, palette: palette)
                        }
                    }
                    Text("A — 80% выручки, B — следующие 15%, C — последние 5%.")
                        .font(.caption)
                        .foregroundStyle(palette.secondary)
                }
            }

            if report.categories.count > 1 {
                SectionCard("Категории", icon: "square.grid.2x2.fill", palette: palette) {
                    VStack(spacing: 14) {
                        ForEach(report.categories) { c in
                            GroupBar(
                                title: c.name,
                                value: Fmt.rub(c.revenue),
                                caption: "\(Fmt.pct(c.share)) выручки",
                                fraction: c.share / (report.categories.first?.share ?? 1),
                                palette: palette)
                        }
                    }
                }
            }

            Text("Суммы находок — оценка того, сколько можно вернуть, если подтянуть слабые места. «В месяц» — пересчёт на 30 дней.")
                .font(.caption)
                .foregroundStyle(palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(palette.text)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.isDemo ? "Пример отчёта" : "Отчёт по продажам")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Theme.gold)
            Text(report.periodTitle)
                .font(.title2.bold())
            Text(report.fileName)
                .font(.footnote)
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
        }
    }

    private var kpis: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                KPI(title: "Выручка", value: Fmt.rub(report.revenue), palette: palette)
                KPI(title: report.checksEstimated ? "Продаж" : "Чеков", value: Fmt.num(Double(report.checks)), palette: palette)
            }
            GridRow {
                KPI(title: report.checksEstimated ? "Средняя продажа" : "Средний чек", value: Fmt.rub(report.avgCheck), palette: palette)
                if let gp = report.grossProfit {
                    KPI(title: "Валовая прибыль", value: Fmt.rub(gp), palette: palette)
                } else {
                    KPI(title: "Скидки", value: Fmt.rub(report.discountTotal), palette: palette)
                }
            }
        }
    }

    private var moneyAxis: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine()
            AxisValueLabel {
                if let d = value.as(Double.self) {
                    Text(Fmt.compact(d))
                }
            }
        }
    }
}

// MARK: - Блоки

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
                Image(systemName: icon).foregroundStyle(Theme.gold)
                Text(title).font(.headline).foregroundStyle(palette.text)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(palette.stroke))
    }
}

private struct FoundCard: View {
    let report: SalesReport
    let palette: Palette

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Можно вернуть в месяц")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondary)
                Text(Fmt.rub(report.foundPerMonth))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("За период файла — \(Fmt.rub(report.foundInPeriod))")
                    .font(.footnote)
                    .foregroundStyle(palette.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "rublesign.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.gold.opacity(0.85))
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.gold.opacity(0.22), palette.card],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.gold.opacity(0.35)))
    }
}

private struct KPI: View {
    let title: String
    let value: String
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(palette.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(palette.stroke))
    }
}

private struct InsightRow: View {
    let number: Int
    let insight: Insight
    let monthFactor: Double
    let palette: Palette

    private var color: Color {
        switch insight.level {
        case .high: return Theme.danger
        case .medium: return .orange
        case .low: return Theme.gold
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Находка \(number)")
                    .font(.caption)
                    .foregroundStyle(palette.secondary)
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(insight.detail)
                    .font(.footnote)
                    .foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let amount = insight.amount, amount > 0 {
                    Text("≈ \(Fmt.rub(amount * monthFactor)) в месяц")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }
}

private struct ItemRow: View {
    let item: ItemStat
    let palette: Palette

    private var badgeColor: Color {
        switch item.abc {
        case "A": return Theme.gold
        case "B": return .orange
        default: return palette.secondary
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(item.abc)
                .font(.caption.bold())
                .foregroundStyle(badgeColor)
                .frame(width: 24, height: 24)
                .background(badgeColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline).foregroundStyle(palette.text).lineLimit(1)
                Text(itemCaption).font(.caption).foregroundStyle(palette.secondary)
            }
            Spacer(minLength: 8)
            Text(Fmt.rub(item.revenue))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.text)
        }
    }

    private var itemCaption: String {
        var parts = ["\(Fmt.num(item.quantity)) шт", "\(Fmt.pct(item.share))"]
        if let m = item.margin { parts.append("маржа \(Fmt.pct(m))") }
        return parts.joined(separator: " · ")
    }
}

private struct GroupBar: View {
    let title: String
    let value: String
    let caption: String
    let fraction: Double
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(palette.text).lineLimit(1)
                Spacer()
                Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(palette.text)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.stroke)
                    Capsule().fill(Theme.gold)
                        .frame(width: max(4, geo.size.width * min(max(fraction, 0), 1)))
                }
            }
            .frame(height: 6)
            Text(caption).font(.caption).foregroundStyle(palette.secondary)
        }
    }
}
