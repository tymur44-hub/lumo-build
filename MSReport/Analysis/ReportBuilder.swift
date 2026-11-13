import Foundation

struct BuildError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Считает отчёт и ищет, где кофейня теряет деньги.
/// Суммы находок — оценка того, сколько можно вернуть, если подтянуть слабые места.
enum ReportBuilder {

    static func makeReport(table: RawTable, mapping: [ColumnRole: Int], fileName: String) throws -> SalesReport {
        let lines = parse(table: table, mapping: mapping)
        guard !lines.isEmpty else {
            throw BuildError(message: "Не нашлось ни одной строки с датой и суммой. Проверьте, что столбцы выбраны верно.")
        }
        return build(lines: lines, fileName: fileName)
    }

    // MARK: - Разбор строк

    static func parse(table: RawTable, mapping: [ColumnRole: Int]) -> [SaleLine] {
        let cal = Calendar.current
        let discountIsPercent = mapping[.discount].map { table.headers[$0].contains("%") } ?? false
        let costPerUnit = mapping[.cost].map { i -> Bool in
            let h = table.headers[i].lowercased()
            return h.contains("за ед") || h.contains("за шт") || h.contains("ед.")
        } ?? false

        var result: [SaleLine] = []
        result.reserveCapacity(table.rows.count)

        for row in table.rows {
            func cell(_ role: ColumnRole) -> String? {
                guard let i = mapping[role], i < row.count else { return nil }
                let s = row[i].trimmingCharacters(in: .whitespacesAndNewlines)
                return s.isEmpty ? nil : s
            }

            let item = cell(.item)
            if let low = item?.lowercased(), low.hasPrefix("итог") || low.hasPrefix("всего") || low == "total" {
                continue
            }
            guard let dateText = cell(.date), var date = ValueParser.date(dateText) else { continue }
            if let t = cell(.time), let secs = ValueParser.timeOfDay(t) {
                date = cal.startOfDay(for: date).addingTimeInterval(secs)
            }

            let qty = cell(.quantity).flatMap(ValueParser.number) ?? 1
            var amount: Double
            if let a = cell(.amount).flatMap(ValueParser.number) {
                amount = a
            } else if let p = cell(.price).flatMap(ValueParser.number) {
                amount = p * qty
            } else {
                continue
            }
            if qty < 0 && amount > 0 { amount = -amount }

            var discount = abs(cell(.discount).flatMap(ValueParser.number) ?? 0)
            if discountIsPercent && discount > 0 && discount < 100 {
                discount = abs(amount) / (1 - discount / 100) - abs(amount)
            }

            var cost = cell(.cost).flatMap(ValueParser.number).map { abs($0) }
            if costPerUnit, let c = cost { cost = c * abs(qty) }

            result.append(SaleLine(
                date: date,
                item: item,
                category: cell(.category),
                store: cell(.store),
                check: cell(.check),
                quantity: qty,
                amount: amount,
                discount: discount,
                cost: cost
            ))
        }
        return result
    }

    // MARK: - Отчёт

    static func build(lines: [SaleLine], fileName: String) -> SalesReport {
        let cal = Calendar.current
        let sales = lines.filter { $0.amount > 0 }
        let refunds = lines.filter { $0.amount < 0 }

        let salesRevenue = sales.reduce(0) { $0 + $1.amount }
        let refundTotal = refunds.reduce(0) { $0 - $1.amount }
        let discountTotal = sales.reduce(0) { $0 + $1.discount }
        let revenue = salesRevenue - refundTotal
        let itemsSold = sales.reduce(0) { $0 + $1.quantity }

        let hasTime = lines.contains { ValueParser.secondsSinceMidnight($0.date) > 0 }
        let hasCheck = sales.contains { $0.check != nil }
        let hasItems = sales.contains { $0.item != nil }
        let hasCost = sales.contains { $0.cost != nil }

        let start = lines.map(\.date).min() ?? Date()
        let end = lines.map(\.date).max() ?? start
        let spanDays = (cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: end)).day ?? 0) + 1

        // Чеки: по номеру; если его нет — по точному времени продажи; иначе каждая строка — отдельная продажа
        var checkLines: [String: [SaleLine]] = [:]
        for (n, l) in sales.enumerated() {
            let key: String
            if let c = l.check {
                key = (l.store ?? "") + "|" + c
            } else if hasTime {
                key = (l.store ?? "") + "|" + String(l.date.timeIntervalSince1970)
            } else {
                key = "row\(n)"
            }
            checkLines[key, default: []].append(l)
        }
        let checks = max(checkLines.count, 1)
        let avgCheck = salesRevenue / Double(checks)

        // По дням
        var dayRevenue: [Date: Double] = [:]
        for l in lines { dayRevenue[cal.startOfDay(for: l.date), default: 0] += l.amount }
        let daily = dayRevenue.keys.sorted().map { DayPoint(date: $0, revenue: dayRevenue[$0] ?? 0) }
        let openDays = max(daily.count, 1)

        // По часам (в среднем за рабочий день)
        var hourly: [HourPoint] = []
        if hasTime {
            var byHour: [Int: Double] = [:]
            for l in sales { byHour[cal.component(.hour, from: l.date), default: 0] += l.amount }
            hourly = byHour.keys.sorted().map { HourPoint(hour: $0, avgRevenue: (byHour[$0] ?? 0) / Double(openDays)) }
        }

        // По дням недели (Пн = 0)
        let weekdayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        var wdSum = [Double](repeating: 0, count: 7)
        var wdCount = [Int](repeating: 0, count: 7)
        for d in daily {
            let i = (cal.component(.weekday, from: d.date) + 5) % 7
            wdSum[i] += d.revenue
            wdCount[i] += 1
        }
        let weekdays = (0..<7).filter { wdCount[$0] > 0 }.map {
            WeekdayPoint(index: $0, name: weekdayNames[$0], avgRevenue: wdSum[$0] / Double(wdCount[$0]))
        }

        // Товары + ABC
        var items: [ItemStat] = []
        if hasItems {
            var acc: [String: (q: Double, r: Double, c: Double, hasCost: Bool)] = [:]
            for l in sales {
                let key = l.item ?? "Без названия"
                var a = acc[key] ?? (q: 0, r: 0, c: 0, hasCost: false)
                a.q += l.quantity
                a.r += l.amount
                if let c = l.cost { a.c += c; a.hasCost = true }
                acc[key] = a
            }
            var cumulative = 0.0
            for (name, a) in acc.sorted(by: { $0.value.r > $1.value.r }) {
                let share = salesRevenue > 0 ? a.r / salesRevenue : 0
                let abc = cumulative < 0.8 ? "A" : (cumulative < 0.95 ? "B" : "C")
                cumulative += share
                let margin: Double? = (a.hasCost && a.r > 0) ? (a.r - a.c) / a.r : nil
                items.append(ItemStat(name: name, quantity: a.q, revenue: a.r, share: share, abc: abc, margin: margin))
            }
        }

        func groups(_ key: (SaleLine) -> String?) -> [GroupStat] {
            var rev: [String: Double] = [:]
            var chk: [String: Set<String>] = [:]
            var days: [String: Set<Date>] = [:]
            for (checkKey, ls) in checkLines {
                for l in ls {
                    guard let k = key(l) else { continue }
                    rev[k, default: 0] += l.amount
                    chk[k, default: []].insert(checkKey)
                    days[k, default: []].insert(cal.startOfDay(for: l.date))
                }
            }
            return rev.keys.map { k -> GroupStat in
                let r = rev[k] ?? 0
                let c = max(chk[k]?.count ?? 1, 1)
                let d = max(days[k]?.count ?? 1, 1)
                return GroupStat(name: k, revenue: r, perDay: r / Double(d), checks: c,
                                 avgCheck: r / Double(c), share: salesRevenue > 0 ? r / salesRevenue : 0)
            }
            .sorted { $0.revenue > $1.revenue }
        }
        let categories = groups { $0.category }
        let stores = groups { $0.store }

        var grossProfit: Double?
        if hasCost {
            var gp = 0.0
            for l in sales { if let c = l.cost { gp += l.amount - c } }
            grossProfit = gp
        }

        // MARK: Находки

        var insights: [Insight] = []

        // 1. Пустые часы
        if hourly.count >= 6 {
            let med = median(hourly.map(\.avgRevenue))
            let weak = hourly.filter { $0.avgRevenue >= med * 0.1 && $0.avgRevenue < med * 0.5 }
            if !weak.isEmpty {
                let loss = weak.reduce(0) { $0 + max(0, med * 0.6 - $1.avgRevenue) } * Double(openDays)
                let avgWeak = weak.reduce(0) { $0 + $1.avgRevenue } / Double(weak.count)
                insights.append(Insight(
                    icon: "clock.badge.exclamationmark",
                    title: "Пустые часы: \(hourRanges(weak.map(\.hour)))",
                    detail: "В эти часы выручка в среднем \(Fmt.rub(avgWeak)) в час против \(Fmt.rub(med)) в обычный час. Запустите «счастливые часы» или комбо «кофе + десерт», либо сократите смену на это время.",
                    amount: loss, level: .high))
            }
        }

        // 2. Слабые дни недели
        if openDays >= 14 && weekdays.count >= 5 {
            let mean = weekdays.reduce(0) { $0 + $1.avgRevenue } / Double(weekdays.count)
            let weak = weekdays.filter { $0.avgRevenue < mean * 0.8 }
            if !weak.isEmpty {
                let loss = weak.reduce(0) { $0 + max(0, mean * 0.9 - $1.avgRevenue) * Double(wdCount[$1.index]) }
                let gap = 1 - (weak.reduce(0) { $0 + $1.avgRevenue } / Double(weak.count)) / mean
                insights.append(Insight(
                    icon: "calendar.badge.exclamationmark",
                    title: "Слабые дни: \(weak.map(\.name).joined(separator: ", "))",
                    detail: "В эти дни выручка на \(Fmt.pct(gap)) ниже средней. Подойдёт акция дня, бонусы по карте лояльности или предзаказ для офисов рядом.",
                    amount: loss, level: .medium))
            }
        }

        // 3. Отстающие точки
        if stores.count >= 2 {
            let med = median(stores.map(\.perDay))
            let leader = stores.max { $0.perDay < $1.perDay }
            let weak = stores.filter { $0.perDay < med * 0.75 }
            if !weak.isEmpty, let leader {
                let loss = weak.reduce(0) { $0 + max(0, med * 0.85 - $1.perDay) } * Double(openDays) * 0.5
                let names = weak.map(\.name).joined(separator: ", ")
                let w = weak[0]
                insights.append(Insight(
                    icon: "building.2",
                    title: "Отстаёт точка: \(names)",
                    detail: "Выручка в день \(Fmt.rub(w.perDay)) против \(Fmt.rub(leader.perDay)) у точки «\(leader.name)», средний чек \(Fmt.rub(w.avgCheck)) против \(Fmt.rub(leader.avgCheck)). Сравните ассортимент, часы работы и допродажи с лидером.",
                    amount: loss, level: .medium))
            }
        }

        // 4. Падение выручки и среднего чека
        if openDays >= 14 {
            let mid = start.addingTimeInterval(end.timeIntervalSince(start) / 2)
            let firstDays = daily.filter { $0.date < mid }
            let secondDays = daily.filter { $0.date >= mid }
            if firstDays.count >= 5 && secondDays.count >= 5 {
                let r1 = firstDays.reduce(0) { $0 + $1.revenue } / Double(firstDays.count)
                let r2 = secondDays.reduce(0) { $0 + $1.revenue } / Double(secondDays.count)

                var checkTrendAdded = false
                if hasCheck {
                    var c1 = (sum: 0.0, n: 0), c2 = (sum: 0.0, n: 0)
                    for ls in checkLines.values {
                        guard let first = ls.first else { continue }
                        let total = ls.reduce(0) { $0 + $1.amount }
                        if first.date < mid { c1.sum += total; c1.n += 1 } else { c2.sum += total; c2.n += 1 }
                    }
                    if c1.n > 0 && c2.n > 0 {
                        let a1 = c1.sum / Double(c1.n), a2 = c2.sum / Double(c2.n)
                        if a2 < a1 * 0.92 {
                            insights.append(Insight(
                                icon: "chart.line.downtrend.xyaxis",
                                title: "Средний чек упал на \(Fmt.pct(1 - a2 / a1))",
                                detail: "Было \(Fmt.rub(a1)), стало \(Fmt.rub(a2)) во второй половине периода. Проверьте, не пропали ли допродажи и не стало ли больше скидок.",
                                amount: (a1 - a2) * Double(c2.n), level: .high))
                            checkTrendAdded = true
                        }
                    }
                }
                if !checkTrendAdded && r2 < r1 * 0.9 {
                    insights.append(Insight(
                        icon: "chart.line.downtrend.xyaxis",
                        title: "Выручка снижается на \(Fmt.pct(1 - r2 / r1))",
                        detail: "В среднем \(Fmt.rub(r1)) в день в начале периода и \(Fmt.rub(r2)) в конце. Посмотрите, что изменилось: меню, цены, персонал, конкуренты рядом.",
                        amount: (r1 - r2) * Double(secondDays.count), level: .high))
                }

                // Позиции, которые стали продаваться хуже
                if hasItems {
                    var rev1: [String: Double] = [:], rev2: [String: Double] = [:]
                    for l in sales {
                        let k = l.item ?? "Без названия"
                        if l.date < mid { rev1[k, default: 0] += l.amount } else { rev2[k, default: 0] += l.amount }
                    }
                    var falling: [(String, Double)] = []
                    var loss = 0.0
                    for item in items.prefix(20) where item.share > 0.01 {
                        let a = (rev1[item.name] ?? 0) / Double(firstDays.count)
                        let b = (rev2[item.name] ?? 0) / Double(secondDays.count)
                        if a > 0 && b < a * 0.7 {
                            falling.append((item.name, 1 - b / a))
                            loss += (a - b) * Double(secondDays.count)
                        }
                    }
                    if !falling.isEmpty {
                        let list = falling.prefix(4).map { "\($0.0) −\(Fmt.pct($0.1))" }.joined(separator: ", ")
                        insights.append(Insight(
                            icon: "arrow.down.right.circle",
                            title: "Падают продажи: \(falling.prefix(3).map { $0.0 }.joined(separator: ", "))",
                            detail: "Во второй половине периода: \(list). Проверьте качество, наличие и цену этих позиций.",
                            amount: loss, level: .medium))
                    }
                }
            }
        }

        // 5. Чеки из одной позиции — недобор допродаж
        if hasCheck && hasItems && checkLines.count >= 30 {
            let single = checkLines.values.filter { ls in ls.reduce(0) { $0 + $1.quantity } <= 1 }.count
            let share = Double(single) / Double(checks)
            if share >= 0.4 {
                let unitPrices = items.filter { $0.quantity > 0 }.map { $0.revenue / $0.quantity }.sorted()
                let addon = unitPrices.isEmpty ? avgCheck * 0.5 : unitPrices[unitPrices.count / 4]
                let loss = Double(single) * 0.15 * addon
                insights.append(Insight(
                    icon: "cart.badge.plus",
                    title: "\(Fmt.pct(share)) чеков — из одной позиции",
                    detail: "Предлагайте к напитку десерт, сироп или выпечку. Если согласится хотя бы каждый седьмой гость, это около \(Fmt.rub(loss)) за период файла.",
                    amount: loss, level: .medium))
            }
        }

        // 6. Скидки
        let gross = salesRevenue + discountTotal
        if discountTotal > 0 && gross > 0 {
            let share = discountTotal / gross
            let loss = max(0, discountTotal - gross * 0.03)
            insights.append(Insight(
                icon: "tag",
                title: "Скидки — \(Fmt.pct(share)) выручки",
                detail: share > 0.05
                    ? "Это много для кофейни: ориентир — до 3%. Проверьте, кто и за что даёт скидки, и ограничьте ручные скидки на кассе."
                    : "Уровень скидок в норме. Следите, чтобы он не рос.",
                amount: loss > 0 ? loss : nil, level: share > 0.05 ? .high : .low))
        }

        // 7. Возвраты
        if refundTotal > 0 {
            let share = salesRevenue > 0 ? refundTotal / salesRevenue : 0
            insights.append(Insight(
                icon: "arrow.uturn.backward",
                title: "Возвраты: \(refunds.count) на \(Fmt.rub(refundTotal))",
                detail: "Каждый возврат — потерянный продукт и время бариста. Посмотрите, по каким позициям и в какие смены их больше всего.",
                amount: refundTotal, level: share > 0.01 ? .high : .medium))
        }

        // 8. Низкая маржа
        if hasCost {
            let low = items.filter { ($0.margin ?? 1) < 0.5 && $0.share > 0.02 }
            if !low.isEmpty {
                let loss = low.reduce(0) { $0 + $1.revenue * max(0, 0.6 - ($1.margin ?? 0.6)) }
                let list = low.prefix(4).map { "\($0.name) \(Fmt.pct($0.margin ?? 0))" }.joined(separator: ", ")
                insights.append(Insight(
                    icon: "percent",
                    title: "Низкая маржа: \(low.prefix(3).map(\.name).joined(separator: ", "))",
                    detail: "Ориентир для кофейни — от 60%. Сейчас: \(list). Пересмотрите цену или техкарту.",
                    amount: loss, level: .medium))
            }
        }

        // 9. Лишние позиции в меню
        if items.count >= 15 {
            let c = items.filter { $0.abc == "C" }
            if Double(c.count) / Double(items.count) >= 0.35 {
                let share = c.reduce(0) { $0 + $1.share }
                insights.append(Insight(
                    icon: "square.stack.3d.down.right",
                    title: "\(c.count) позиций дают всего \(Fmt.pct(share)) выручки",
                    detail: "Они занимают место в меню и на витрине и увеличивают закупки и списания. Уберите часть из них — гостю будет проще выбрать.",
                    amount: nil, level: .low))
            }
        }

        insights.sort { ($0.amount ?? -1) > ($1.amount ?? -1) }
        if insights.isEmpty {
            insights.append(Insight(
                icon: "checkmark.seal",
                title: "Явных потерь не нашли",
                detail: "Загрузите выгрузку за период от двух недель, со временем продажи и номером чека, — тогда анализ будет точнее.",
                amount: nil, level: .low))
        }

        return SalesReport(
            fileName: fileName,
            periodStart: start,
            periodEnd: end,
            dayCount: max(spanDays, 1),
            revenue: revenue,
            checks: checks,
            checksEstimated: !hasCheck,
            avgCheck: avgCheck,
            itemsSold: itemsSold,
            discountTotal: discountTotal,
            refundTotal: refundTotal,
            grossProfit: grossProfit,
            daily: daily,
            hourly: hourly,
            weekdays: weekdays,
            items: items,
            categories: categories,
            stores: stores,
            insights: insights
        )
    }

    // MARK: - Помощники

    static func median(_ values: [Double]) -> Double {
        let s = values.sorted()
        guard !s.isEmpty else { return 0 }
        return s.count % 2 == 1 ? s[s.count / 2] : (s[s.count / 2 - 1] + s[s.count / 2]) / 2
    }

    /// [15, 16, 20] → "15:00–17:00, 20:00–21:00"
    static func hourRanges(_ hours: [Int]) -> String {
        let sorted = hours.sorted()
        var ranges: [(Int, Int)] = []
        for h in sorted {
            if let last = ranges.last, last.1 == h - 1 {
                ranges[ranges.count - 1].1 = h
            } else {
                ranges.append((h, h))
            }
        }
        return ranges.map { "\($0.0):00–\($0.1 + 1):00" }.joined(separator: ", ")
    }
}
