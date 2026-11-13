import Foundation
import Observation

/// Хранит отчёты в файле на телефоне. Никуда не отправляет.
@Observable
final class ReportStore {
    private(set) var reports: [SalesReport] = []

    private let fileURL: URL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("reports.json")

    init() {
        load()
    }

    func add(_ report: SalesReport) {
        reports.insert(report, at: 0)
        save()
    }

    func delete(_ id: UUID) {
        reports.removeAll { $0.id == id }
        save()
    }

    func deleteAll() {
        reports.removeAll()
        save()
    }

    var latest: SalesReport? { reports.first }
    var previous: SalesReport? { reports.count > 1 ? reports[1] : nil }
    var totalFoundPerMonth: Double { reports.first?.foundPerMonth ?? 0 }
    var totalFoundAllTime: Double { reports.reduce(0) { $0 + $1.foundInPeriod } }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        reports = (try? JSONDecoder().decode([SalesReport].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
