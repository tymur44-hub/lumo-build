import Foundation

/// Разбор чисел, дат и времени в форматах, которые встречаются в выгрузках касс.
enum ValueParser {

    // MARK: Числа

    /// "1 234,56", "1234.56", "1 234,56 ₽", "1,234.56", "-150" → Double
    static func number(_ raw: String) -> Double? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        if let d = Double(s) { return d }

        var t = ""
        for ch in s {
            if ch == "−" || ch == "–" {
                t.append("-")
            } else if (ch.isASCII && ch.isNumber) || ch == "." || ch == "," || ch == "-" {
                t.append(ch)
            }
        }
        while let last = t.last, last == "." || last == "," { t.removeLast() }
        if t.isEmpty || t == "-" { return nil }

        let lastComma = t.lastIndex(of: ",")
        let lastDot = t.lastIndex(of: ".")
        if let c = lastComma, let d = lastDot {
            if c > d {
                t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                t = t.replacingOccurrences(of: ",", with: "")
            }
        } else if lastComma != nil {
            let commas = t.filter { $0 == "," }.count
            t = commas == 1
                ? t.replacingOccurrences(of: ",", with: ".")
                : t.replacingOccurrences(of: ",", with: "")
        } else if lastDot != nil, t.filter({ $0 == "." }).count > 1 {
            t = t.replacingOccurrences(of: ".", with: "")
        }
        return Double(t)
    }

    // MARK: Даты

    private static let formats = [
        "d.M.yyyy H:mm:ss", "d.M.yyyy H:mm", "d.M.yyyy",
        "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd",
        "d/M/yyyy H:mm:ss", "d/M/yyyy H:mm", "d/M/yyyy",
        "d.M.yy H:mm:ss", "d.M.yy H:mm", "d.M.yy",
    ]

    private static let formatters: [DateFormatter] = formats.map { format in
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = format
        return f
    }

    private static let iso = ISO8601DateFormatter()

    /// Excel хранит даты как число дней от 30.12.1899.
    private static let excelEpoch: Date = {
        var c = DateComponents()
        c.year = 1899
        c.month = 12
        c.day = 30
        return Calendar.current.date(from: c) ?? Date(timeIntervalSince1970: -2_209_161_600)
    }()

    static func date(_ raw: String) -> Date? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        if let v = Double(s) {
            guard v > 20_000, v < 80_000 else { return nil }
            return excelDate(v)
        }
        for f in formatters {
            if let d = f.date(from: s) { return d }
        }
        if let d = iso.date(from: s) { return d }
        // "2026-11-01T08:15:00.000+03:00" и подобное — берём первые 19 символов
        if s.count > 19 {
            let head = String(s.prefix(19))
            for f in formatters {
                if let d = f.date(from: head) { return d }
            }
        }
        return nil
    }

    static func excelDate(_ v: Double) -> Date {
        let days = floor(v)
        let seconds = ((v - days) * 86_400).rounded()
        let base = Calendar.current.date(byAdding: .day, value: Int(days), to: excelEpoch) ?? excelEpoch
        return base.addingTimeInterval(seconds)
    }

    // MARK: Время

    /// "8:15", "08:15:00", 0.34375 (доля суток из Excel), "14" (час) → секунды от полуночи
    static func timeOfDay(_ raw: String) -> TimeInterval? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        if let v = Double(s) {
            if v >= 0 && v < 1 { return (v * 86_400).rounded() }
            if v > 20_000 && v < 80_000 { return ((v - floor(v)) * 86_400).rounded() }
            if v >= 0 && v < 24 && v == floor(v) { return v * 3_600 }
            return nil
        }

        let parts = s.split(separator: ":")
        if parts.count >= 2,
           let h = Int(parts[0].trimmingCharacters(in: .whitespaces)),
           let m = Int(parts[1].prefix(2)),
           (0..<24).contains(h), (0..<60).contains(m) {
            let sec = parts.count > 2 ? (Int(parts[2].prefix(2)) ?? 0) : 0
            return TimeInterval(h * 3_600 + m * 60 + sec)
        }

        if let d = date(s) { return secondsSinceMidnight(d) }
        return nil
    }

    static func secondsSinceMidnight(_ d: Date) -> TimeInterval {
        d.timeIntervalSince(Calendar.current.startOfDay(for: d))
    }
}
