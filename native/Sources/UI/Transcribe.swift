import Foundation
import Speech

/// Расшифровка голосовых и кружков средствами iOS (Speech). Звук обрабатывается на устройстве или в сервисе Apple
enum Transcriber {
    static func run(urlString: String, ext: String) async -> Result<String, Error> {
        guard let url = URL(string: urlString) else { return .failure(TErr.msg("Нет файла")) }
        let ok: Bool = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        guard ok else { return .failure(TErr.msg("Разрешите распознавание речи в настройках iPhone")) }
        guard let rec = SFSpeechRecognizer(locale: Locale(identifier: "ru_RU")), rec.isAvailable else { return .failure(TErr.msg("Распознавание речи сейчас недоступно")) }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("tr-\(UUID().uuidString).\(ext)")
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: file)
        } catch { return .failure(TErr.msg("Не удалось загрузить запись")) }
        defer { try? FileManager.default.removeItem(at: file) }
        let req = SFSpeechURLRecognitionRequest(url: file)
        req.shouldReportPartialResults = false
        return await withCheckedContinuation { (c: CheckedContinuation<Result<String, Error>, Never>) in
            var done = false
            rec.recognitionTask(with: req) { res, err in
                if done { return }
                if let r = res, r.isFinal {
                    done = true
                    let t = r.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                    c.resume(returning: t.isEmpty ? .failure(TErr.msg("Речь не распознана")) : .success(t))
                } else if err != nil {
                    done = true
                    c.resume(returning: .failure(TErr.msg("Речь не распознана")))
                }
            }
        }
    }
    enum TErr: Error, LocalizedError {
        case msg(String)
        var errorDescription: String? { if case .msg(let s) = self { return s }; return nil }
    }
}
