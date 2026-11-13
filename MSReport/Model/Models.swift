import Foundation

/// Что лежит в столбце выгрузки.
enum ColumnRole: String, CaseIterable, Identifiable, Hashable {
    case date, time, amount, price, quantity, item, category, store, check, discount, cost

    var id: String { rawValue }

    var title: String {
        switch self {
        case .date: return "Дата"
        case .time: return "Время"
        case .amount: return "Сумма"
        case .price: return "Цена"
        case .quantity: return "Количество"
        case .item: return "Товар"
        case .category: return "Категория"
        case .store: return "Точка"
        case .check: return "Номер чека"
        case .discount: return "Скидка"
        case .cost: return "Себестоимость"
        }
    }

    var note: String? {
        switch self {
        case .date: return "обязательно"
        case .amount: return "обязательно, или цена"
        default: return nil
        }
    }
}

/// Таблица из файла: заголовки и строки как текст.
struct RawTable: Sendable {
    var headers: [String]
    var rows: [[String]]
}

/// Одна строка продаж после разбора.
struct SaleLine {
    var date: Date
    var item: String?
    var category: String?
    var store: String?
    var check: String?
    var quantity: Double
    var amount: Double
    var discount: Double
    var cost: Double?
}

enum InsightLevel: String, Codable {
    case high, medium, low
}

/// Находка: где кофейня теряет деньги.
struct Insight: Codable, Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var detail: String
    /// Оценка суммы за период файла (в отчёте пересчитывается на месяц).
    var amount: Double?
    var level: InsightLevel
}

struct DayPoint: Codable, Identifiable {
    var date: Date
    var revenue: Double
    var id: Date { date }
}

struct HourPoint: Codable, Identifiable {
    var hour: Int
    var avgRevenue: Double
    var id: Int { hour }
}

struct WeekdayPoint: Codable, Identifiable {
    var index: Int
    var name: String
    var avgRevenue: Double
    var id: Int { index }
}

struct ItemStat: Codable, Identifiable {
    var name: String
    var quantity: Double
    var revenue: Double
    var share: Double
    var abc: String
    var margin: Double?
    var id: String { name }
}

struct GroupStat: Codable, Identifiable {
    var name: String
    var revenue: Double
    var perDay: Double
    var checks: Int
    var avgCheck: Double
    var share: Double
    var id: String { name }
}

struct SalesReport: Codable, Identifiable {
    var id = UUID()
    var createdAt = Date()
    var fileName: String
    var isDemo = false
    var periodStart: Date
    var periodEnd: Date
    /// Длина периода в календарных днях.
    var dayCount: Int
    var revenue: Double
    var checks: Int
    var checksEstimated: Bool
    var avgCheck: Double
    var itemsSold: Double
    var discountTotal: Double
    var refundTotal: Double
    var grossProfit: Double?
    var daily: [DayPoint]
    var hourly: [HourPoint]
    var weekdays: [WeekdayPoint]
    var items: [ItemStat]
    var categories: [GroupStat]
    var stores: [GroupStat]
    var insights: [Insight]
}

extension SalesReport {
    var monthFactor: Double { 30.0 / Double(max(dayCount, 1)) }
    var foundInPeriod: Double { insights.compactMap(\.amount).reduce(0, +) }
    var foundPerMonth: Double { foundInPeriod * monthFactor }
    var periodTitle: String { Fmt.period(periodStart, periodEnd) }
}
