import Foundation
import AVFoundation

/// Видео скачивается один раз и дальше играет с телефона — экономит трафик хранилища
actor MediaCache {
    static let shared = MediaCache()
    private var inflight: [String: Task<URL?, Never>] = [:]
    private let dir: URL = {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("vcache", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()
    private static let limitBytes: Int64 = 600 * 1024 * 1024

    private func key(_ u: URL) -> String {
        let s = u.absoluteString
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        let ext = u.pathExtension.isEmpty ? "mp4" : u.pathExtension.lowercased()
        return String(h, radix: 36) + "." + ext
    }

    /// уже скачанный файл, если он есть
    nonisolated func local(_ u: URL) -> URL? {
        let s = u.absoluteString
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        let ext = u.pathExtension.isEmpty ? "mp4" : u.pathExtension.lowercased()
        let f = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vcache", isDirectory: true).appendingPathComponent(String(h, radix: 36) + "." + ext)
        if FileManager.default.fileExists(atPath: f.path) {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: f.path)
            return f
        }
        return nil
    }

    /// локальная копия видео (скачивает при первом обращении); если скачать не вышло — исходная ссылка
    func fetch(_ u: URL) async -> URL {
        if u.isFileURL { return u }
        if let l = local(u) { return l }
        let k = key(u)
        if let t = inflight[k] { return await t.value ?? u.px }
        let dst = dir.appendingPathComponent(k)
        let t = Task<URL?, Never> {
            do {
                let (tmp, resp) = try await Net.session.download(from: u.px)
                guard let r = resp as? HTTPURLResponse, (200..<300).contains(r.statusCode) else { return nil }
                NetStats.shared.add(.video, recv: (try? FileManager.default.attributesOfItem(atPath: tmp.path)[.size] as? Int) ?? 0)
                try? FileManager.default.removeItem(at: dst)
                try FileManager.default.moveItem(at: tmp, to: dst)
                return dst
            } catch { return nil }
        }
        inflight[k] = t
        let r = await t.value
        inflight[k] = nil
        if r != nil { trim() }
        return r ?? u.px
    }

    private func trim() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else { return }
        var items = files.compactMap { f -> (URL, Int64, Date)? in
            guard let v = try? f.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { return nil }
            return (f, Int64(v.fileSize ?? 0), v.contentModificationDate ?? .distantPast)
        }
        var total = items.reduce(Int64(0)) { $0 + $1.1 }
        guard total > MediaCache.limitBytes else { return }
        items.sort { $0.2 < $1.2 }
        for it in items where total > MediaCache.limitBytes { try? fm.removeItem(at: it.0); total -= it.1 }
    }
}

/// Сжатие видео перед отправкой: 720p H.264 в mp4 — обычно в 5–10 раз меньше исходника с камеры
enum VideoCompress {
    /// возвращает сжатые данные, только если они заметно меньше исходных
    static func compress(_ data: Data, ext: String) async -> Data? {
        let fm = FileManager.default
        let src = fm.temporaryDirectory.appendingPathComponent("vc-\(UUID().uuidString).\(ext.isEmpty ? "mov" : ext)")
        let dst = fm.temporaryDirectory.appendingPathComponent("vc-\(UUID().uuidString).mp4")
        defer { try? fm.removeItem(at: src); try? fm.removeItem(at: dst) }
        do { try data.write(to: src) } catch { return nil }
        let asset = AVURLAsset(url: src)
        // небольшие ролики не трогаем
        if data.count < 4 * 1024 * 1024 { return nil }
        let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let preset = presets.contains(AVAssetExportPreset1280x720) ? AVAssetExportPreset1280x720 : AVAssetExportPresetMediumQuality
        guard let ex = AVAssetExportSession(asset: asset, presetName: preset) else { return nil }
        ex.outputURL = dst
        ex.outputFileType = .mp4
        ex.shouldOptimizeForNetworkUse = true
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in ex.exportAsynchronously { c.resume() } }
        guard ex.status == .completed, let out = try? Data(contentsOf: dst), out.count > 0, Double(out.count) < Double(data.count) * 0.85 else { return nil }
        return out
    }
}
