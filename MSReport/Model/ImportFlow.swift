import Foundation
import Observation

struct PendingImport: Identifiable {
    let id = UUID()
    let fileName: String
    let table: RawTable
    var mapping: [ColumnRole: Int]
}

/// Весь путь от выбора файла до готового отчёта.
@Observable
final class ImportFlow {
    enum Phase: Equatable {
        case idle
        case reading
        case analyzing
    }

    var phase: Phase = .idle
    var showPicker = false
    var pending: PendingImport?
    /// Готовый отчёт, открывается поверх всего.
    var presented: SalesReport?
    var error: String?

    func startImport() {
        Haptics.tap()
        showPicker = true
    }

    func showDemo() {
        Haptics.tap()
        phase = .analyzing
        let started = Date()
        Task.detached(priority: .userInitiated) {
            let report = DemoData.report()
            await ImportFlow.waitAtLeast(2.6, since: started)
            await MainActor.run {
                self.phase = .idle
                self.presented = report
                Haptics.success()
            }
        }
    }

    func handlePicked(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let e):
            error = e.localizedDescription
        case .success(let url):
            phase = .reading
            let started = Date()
            Task.detached(priority: .userInitiated) {
                do {
                    let table = try FileLoader.load(url: url)
                    let mapping = ColumnDetector.detect(headers: table.headers)
                    await ImportFlow.waitAtLeast(1.4, since: started)
                    await MainActor.run {
                        self.phase = .idle
                        self.pending = PendingImport(fileName: url.lastPathComponent, table: table, mapping: mapping)
                    }
                } catch {
                    await MainActor.run {
                        self.phase = .idle
                        self.error = error.localizedDescription
                        Haptics.warning()
                    }
                }
            }
        }
    }

    func build(_ pending: PendingImport, into store: ReportStore) {
        self.pending = nil
        phase = .analyzing
        let started = Date()
        Task.detached(priority: .userInitiated) {
            do {
                let report = try ReportBuilder.makeReport(table: pending.table, mapping: pending.mapping, fileName: pending.fileName)
                await ImportFlow.waitAtLeast(2.6, since: started)
                await MainActor.run {
                    store.add(report)
                    self.phase = .idle
                    self.presented = report
                    Haptics.success()
                }
            } catch {
                await MainActor.run {
                    self.phase = .idle
                    self.error = error.localizedDescription
                    Haptics.warning()
                }
            }
        }
    }

    /// Чтобы анимация анализа успела показаться целиком.
    private static func waitAtLeast(_ seconds: Double, since start: Date) async {
        let left = seconds - Date().timeIntervalSince(start)
        if left > 0 { try? await Task.sleep(nanoseconds: UInt64(left * 1_000_000_000)) }
    }
}
