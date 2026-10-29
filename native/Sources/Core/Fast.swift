import Foundation
import CryptoKit
import LibXray

/// Локальный ускоритель соединения. Запускается только когда и прямой адрес,
/// и зеркало недоступны (сильное замедление у провайдера). Поднимает локальную
/// точку 127.0.0.1 (SOCKS \(Fast.SOCKS) / HTTP \(Fast.HTTP)), через которую
/// клиент ходит к серверу. Параметры узла зашифрованы и собираются только в памяти.
enum Fast {
    static let SOCKS = 10808
    static let HTTP = 10809
    private static let lock = NSLock()
    private static var _running = false
    static var lastMsg = "не запускался"
    private static var apiV = 3
    static var isRunning: Bool { lock.lock(); defer { lock.unlock() }; return _running }

    private static let kp = ["PmzgX3NcfQc=", "baNpVP/AMZ0=", "C1LiEt4/KtI=", "eid1yAdow/g="]
    private static let km: [UInt8] = [196, 178, 77, 83]
    private static let bd = [
        "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"
    ].joined()

    private static let bd0 = [
        "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"
    ].joined()

    private static func key() -> Data {
        var out = Data(count: 32)
        for i in 0..<4 {
            let d = Data(base64Encoded: kp[i]) ?? Data()
            for j in 0..<d.count { out[i * 8 + j] = d[j] ^ km[i] }
        }
        return out
    }

    private static func conf(_ b: String) -> String? {
        guard let raw = Data(base64Encoded: b), raw.count > 28 else { return nil }
        let iv = raw.prefix(12)
        let rest = raw.dropFirst(12)
        let ct = rest.prefix(rest.count - 16)
        let tag = rest.suffix(16)
        guard let nonce = try? AES.GCM.Nonce(data: iv),
              let box = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: ct, tag: tag),
              let dec = try? AES.GCM.open(box, using: SymmetricKey(data: key())) else { return nil }
        return String(data: dec, encoding: .utf8)
    }

    private static func call(_ request: String) -> String {
        guard let cin = strdup(request) else { return "" }
        defer { free(cin) }
        guard let out = CGoInvoke(cin) else { return "" }
        defer { CGoFree(out) }
        return String(cString: out)
    }

    @discardableResult
    static func ensure() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if _running { return true }
        var ok = false
        // сначала новый набор параметров, при неудаче — прежний
        for b in [bd, bd0] {
            guard let cfg = conf(b),
                  let payload = try? JSONSerialization.data(withJSONObject: ["configJSON": cfg]),
                  let pStr = String(data: payload, encoding: .utf8) else { lastMsg = "конфиг не расшифрован"; continue }
            // версия интерфейса ядра зависит от сборки — подбираем
            for v in [1, 2, 3, 4, 5, 6] {
                let req = "{\"apiVersion\":\(v),\"method\":\"runXrayFromJson\",\"payload\":" + pStr + "}"
                let resp = call(req)
                lastMsg = "v\(v) " + String(resp.prefix(400))
                let obj = (try? JSONSerialization.jsonObject(with: Data(resp.utf8))) as? [String: Any]
                if (obj?["success"] as? Bool) == true { ok = true; apiV = v; break }
                if !resp.contains("unsupported apiVersion") { break }
            }
            if ok { break }
        }
        _running = ok
        return _running
    }

    static func stop() {
        lock.lock(); defer { lock.unlock() }
        if !_running { return }
        _ = call("{\"apiVersion\":\(apiV),\"method\":\"stopXray\"}")
        _running = false
    }
}
