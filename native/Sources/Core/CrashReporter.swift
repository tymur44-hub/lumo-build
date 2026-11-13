import Foundation
import UIKit

/// Падения приложения: при сбое коротко пишем, что случилось, в файл; при следующем запуске отправляем на сервер.
enum CrashReporter {
    private static var path: String = {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d.appendingPathComponent("lumo_crash.txt").path
    }()
    private static var fd: Int32 = -1

    static func install() {
        // след прошлого падения по сигналу переносим в основной файл, пока не затёрли
        if let sig = try? String(contentsOfFile: path + ".sig", encoding: .utf8), !sig.isEmpty,
           !FileManager.default.fileExists(atPath: path) {
            try? sig.write(toFile: path, atomically: true, encoding: .utf8)
        }
        // заранее открытый файл — в обработчике сигнала нельзя ничего выделять
        fd = open(path + ".sig", O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        NSSetUncaughtExceptionHandler { e in
            let text = "Исключение: \(e.name.rawValue): \(e.reason ?? "")\n" + e.callStackSymbols.prefix(60).joined(separator: "\n")
            try? text.write(toFile: CrashReporter.path, atomically: true, encoding: .utf8)
        }
        for s in [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE] {
            signal(s) { sig in
                if CrashReporter.fd >= 0 {
                    var head = "Сигнал \(sig)\n"
                    head.withUTF8 { _ = write(CrashReporter.fd, $0.baseAddress, $0.count) }
                    // адреса стека (без имён — их восстановим по версии)
                    var buf = [UnsafeMutableRawPointer?](repeating: nil, count: 64)
                    let n = backtrace(&buf, 64)
                    backtrace_symbols_fd(&buf, n, CrashReporter.fd)
                }
                signal(sig, SIG_DFL)
                raise(sig)
            }
        }
    }

    /// после входа: отправить отчёт о прошлом падении, если он есть
    static func flush() async {
        let text = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        guard !text.isEmpty else { return }
        let first = text.split(separator: "\n").first.map(String.init) ?? "Падение"
        let info = Bundle.main.infoDictionary
        let ver = "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
        var sys = utsname(); uname(&sys)
        let model = withUnsafePointer(to: &sys.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) } }
        let row: JSON = ["platform": "ios", "app_version": ver, "os_version": UIDevice.current.systemVersion, "device": model,
                         "message": String(first.prefix(500)), "stack": String(text.prefix(20000))]
        if (try? await API.shared.insert("lm_crash_reports", row)) != nil {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
