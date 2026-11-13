import Foundation

/// Пример: две кофейни за 30 дней. Нужен для кнопки «Посмотреть на примере».
enum DemoData {
    static func report() -> SalesReport {
        var r = ReportBuilder.build(lines: lines(), fileName: "Пример: 2 кофейни, 30 дней")
        r.isDemo = true
        return r
    }

    private struct SeededRNG: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private struct MenuItem {
        let name: String
        let category: String
        let price: Double
        let cost: Double
    }

    private static let menu: [MenuItem] = [
        MenuItem(name: "Капучино", category: "Кофе", price: 220, cost: 55),
        MenuItem(name: "Латте", category: "Кофе", price: 240, cost: 60),
        MenuItem(name: "Американо", category: "Кофе", price: 170, cost: 30),
        MenuItem(name: "Раф", category: "Кофе", price: 280, cost: 80),
        MenuItem(name: "Флэт уайт", category: "Кофе", price: 250, cost: 60),
        MenuItem(name: "Матча латте", category: "Кофе", price: 300, cost: 165),
        MenuItem(name: "Эспрессо", category: "Кофе", price: 140, cost: 25),
        MenuItem(name: "Какао", category: "Напитки", price: 210, cost: 50),
        MenuItem(name: "Чай", category: "Напитки", price: 150, cost: 20),
        MenuItem(name: "Морс", category: "Напитки", price: 160, cost: 40),
        MenuItem(name: "Круассан", category: "Выпечка", price: 190, cost: 85),
        MenuItem(name: "Сырники", category: "Еда", price: 290, cost: 160),
        MenuItem(name: "Сэндвич", category: "Еда", price: 320, cost: 150),
        MenuItem(name: "Чизкейк", category: "Десерты", price: 290, cost: 120),
        MenuItem(name: "Брауни", category: "Десерты", price: 200, cost: 70),
        MenuItem(name: "Печенье", category: "Десерты", price: 90, cost: 30),
    ]

    // Чеков в час в обычный день
    private static let hourProfile: [(Int, Double)] = [
        (8, 9), (9, 12), (10, 8), (11, 6), (12, 9), (13, 10), (14, 7),
        (15, 2), (16, 2), (17, 3), (18, 7), (19, 6), (20, 4), (21, 3),
    ]

    private static let stores: [(String, Double)] = [
        ("Кофейня на Тверской", 1.0),
        ("Кофейня у метро", 0.6),
    ]

    static func lines() -> [SaleLine] {
        var rng = SeededRNG(state: 42)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [SaleLine] = []
        var checkNo = 1000

        for dayOffset in stride(from: 30, through: 1, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let wd = cal.component(.weekday, from: day)
            let wdFactor: Double
            switch wd {
            case 2: wdFactor = 0.6     // понедельник
            case 3: wdFactor = 0.75    // вторник
            case 1, 7: wdFactor = 1.15 // выходные
            default: wdFactor = 1.0
            }
            let secondHalf = dayOffset <= 15

            for (store, storeFactor) in stores {
                for (hour, base) in hourProfile {
                    let n = Int((base * storeFactor * wdFactor * Double.random(in: 0.75...1.25, using: &rng)).rounded())
                    guard n > 0 else { continue }
                    for _ in 0..<n {
                        checkNo += 1
                        let minute = Int.random(in: 0..<60, using: &rng)
                        let time = day.addingTimeInterval(Double(hour * 3_600 + minute * 60))
                        let positions = Double.random(in: 0..<1, using: &rng) < 0.6 ? 1 : Int.random(in: 2...3, using: &rng)
                        let discounted = Double.random(in: 0..<1, using: &rng) < 0.18
                        for _ in 0..<positions {
                            var m = menu[Int.random(in: 0..<menu.count, using: &rng)]
                            // Раф стал продаваться хуже во второй половине месяца
                            if m.name == "Раф" && secondHalf && Double.random(in: 0..<1, using: &rng) < 0.6 {
                                m = menu[2]
                            }
                            let discount = discounted ? (m.price * 0.15).rounded() : 0
                            result.append(SaleLine(
                                date: time, item: m.name, category: m.category, store: store,
                                check: "\(checkNo)", quantity: 1, amount: m.price - discount,
                                discount: discount, cost: m.cost))
                        }
                    }
                }
            }
        }

        // Несколько возвратов
        let count = result.count
        if count > 0 {
            for i in 0..<9 {
                var r = result[(i * 977) % count]
                r.amount = -r.amount
                r.quantity = -1
                r.discount = 0
                r.check = "R\(i)"
                result.append(r)
            }
        }
        return result
    }
}
