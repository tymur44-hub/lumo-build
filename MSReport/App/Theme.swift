import SwiftUI

enum Theme {
    static let gold = Color(red: 0.84, green: 0.66, blue: 0.30)
    static let background = Color(red: 0.055, green: 0.050, blue: 0.043)
    static let card = Color(red: 0.105, green: 0.097, blue: 0.083)
    static let danger = Color(red: 0.93, green: 0.40, blue: 0.34)
}

/// Цвета отчёта: тёмные для экрана, светлые для PDF.
struct Palette {
    let background: Color
    let card: Color
    let text: Color
    let secondary: Color
    let stroke: Color

    static let app = Palette(
        background: Theme.background,
        card: Theme.card,
        text: .white,
        secondary: Color.white.opacity(0.6),
        stroke: Color.white.opacity(0.08)
    )

    static let print = Palette(
        background: .white,
        card: Color(white: 0.96),
        text: .black,
        secondary: Color(white: 0.4),
        stroke: Color(white: 0.88)
    )
}

enum Fmt {
    static let ru = Locale(identifier: "ru_RU")

    private static let money: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = ru
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f
    }()

    private static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = ru
        f.groupingSeparator = " "
        f.maximumFractionDigits = 1
        return f
    }()

    private static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = ru
        f.dateFormat = "d MMM"
        return f
    }()

    private static let dayMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = ru
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    static func rub(_ v: Double) -> String {
        (money.string(from: NSNumber(value: v.rounded())) ?? "0") + " ₽"
    }

    static func num(_ v: Double) -> String {
        decimal.string(from: NSNumber(value: v)) ?? "0"
    }

    static func pct(_ v: Double) -> String {
        "\(Int((v * 100).rounded()))%"
    }

    static func compact(_ v: Double) -> String {
        let a = abs(v)
        if a >= 1_000_000 { return num(v / 1_000_000) + " млн" }
        if a >= 1_000 { return num((v / 1_000).rounded()) + " тыс" }
        return num(v.rounded())
    }

    static func day(_ d: Date) -> String { dayMonth.string(from: d) }

    static func period(_ a: Date, _ b: Date) -> String {
        if Calendar.current.isDate(a, inSameDayAs: b) { return dayMonthYear.string(from: a) }
        return "\(dayMonth.string(from: a)) – \(dayMonthYear.string(from: b))"
    }
}
