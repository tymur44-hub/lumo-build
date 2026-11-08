import Foundation
import MetricKit
import UIKit

/// Отчёты о вылетах: системные отчёты MetricKit + собственный перехват.
/// Отчёт сохраняется на устройстве и отправляется на сервер при следующем запуске.
final class CrashReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = CrashReporter()
    private static var path: String = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("lumo-crash.txt").path
    }()
    private static var cpath: [CChar] = Array(path.utf8CString)

    func start() {
        MXMetricManager.shared.add(self)
        NSSetUncaughtExceptionHandler { e in
            let s = "exception \(e.name.rawValue): \(e.reason ?? "")\n" + e.callStackSymbols.joined(separator: "\n")
            try? s.write(toFile: CrashReporter.path, atomically: true, encoding: .utf8)
        }
        for sig in [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE] {
            signal(sig) { code in
                // в обработчике сигнала — только простые вызовы
                let fd = open(CrashReporter.cpath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
                if fd >= 0 {
                    var head = "signal \(code)\n"
                    head.withUTF8 { _ = write(fd, $0.baseAddress, $0.count) }
                    let syms = Thread.callStackSymbols.joined(separator: "\n")
                    var s = syms
                    s.withUTF8 { _ = write(fd, $0.baseAddress, $0.count) }
                    close(fd)
                }
                signal(code, SIG_DFL)
                raise(code)
            }
        }
    }

    /// после входа: отправить сохранённые отчёты
    func flush() {
        guard API.shared.userId != nil else { return }
        if let s = try? String(contentsOfFile: CrashReporter.path, encoding: .utf8), !s.isEmpty {
            try? FileManager.default.removeItem(atPath: CrashReporter.path)
            send("own", s)
        }
        for p in MXMetricManager.shared.pastDiagnosticPayloads { handle(p) }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) { payloads.forEach(handle) }

    private func handle(_ p: MXDiagnosticPayload) {
        guard let c = p.crashDiagnostics, !c.isEmpty else { return }
        let key = "lm_crash_sent_" + String(Int(p.timeStampEnd.timeIntervalSince1970))
        if UserDefaults.standard.bool(forKey: key) { return }
        UserDefaults.standard.set(true, forKey: key)
        let txt = String(data: p.jsonRepresentation(), encoding: .utf8) ?? ""
        send("metrickit", String(txt.prefix(190_000)))
    }

    private func send(_ kind: String, _ payload: String) {
        let v = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + ")"
        let body: [String: Any] = ["platform": "ios-" + kind, "app_version": v, "os": UIDevice.current.systemVersion + " " + UIDevice.current.model,
                                   "payload": String(payload.prefix(190_000))]
        Task { _ = try? await API.shared.raw("POST", "/rest/v1/lm_crash_reports", body: body, headers: ["Prefer": "return=minimal"]) }
    }
}
