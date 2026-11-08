import SwiftUI
import QuickLook

/// Большие файлы (до 100 МБ, с Premium до 200 МБ).
/// Хранилище принимает не больше 50 МБ за раз, поэтому файл режется на части по 45 МБ,
/// а у получателя части скачиваются и склеиваются обратно в один файл.
enum BigFile {
    static let chunk = 45 * 1024 * 1024
    static func limit(premium: Bool) -> Int { (premium ? 200 : 100) * 1024 * 1024 }
    static func limitText(premium: Bool) -> String { premium ? "200 МБ" : "100 МБ (с Premium — 200 МБ)" }
}

@MainActor
final class BigFiles: ObservableObject {
    static let shared = BigFiles()
    @Published var progress: [Int: Double] = [:]

    private func dir() -> URL {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("bigfiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    func localURL(_ m: Message) -> URL {
        let name = m.fileName.replacingOccurrences(of: "/", with: "_")
        return dir().appendingPathComponent("\(m.id)-\(name)")
    }

    func isReady(_ m: Message) -> Bool { FileManager.default.fileExists(atPath: localURL(m).path) }

    /// Скачать все части и склеить; возвращает путь к готовому файлу
    func fetch(_ m: Message) async -> URL? {
        let out = localURL(m)
        if FileManager.default.fileExists(atPath: out.path) { return out }
        if progress[m.id] != nil { return nil }
        let parts = m.parts
        guard !parts.isEmpty else { return nil }
        progress[m.id] = 0
        defer { progress[m.id] = nil }
        let tmp = out.appendingPathExtension("part")
        try? FileManager.default.removeItem(at: tmp)
        FileManager.default.createFile(atPath: tmp.path, contents: nil)
        guard let fh = try? FileHandle(forWritingTo: tmp) else { return nil }
        for (i, p) in parts.enumerated() {
            guard let u = URL(string: p)?.px,
                  let (file, resp) = try? await URLSession.shared.download(from: u),
                  (resp as? HTTPURLResponse)?.statusCode ?? 200 < 300,
                  let d = try? Data(contentsOf: file, options: .mappedIfSafe) else {
                try? fh.close(); try? FileManager.default.removeItem(at: tmp)
                AppModel.shared.say("Не удалось скачать файл")
                return nil
            }
            fh.seekToEndOfFile(); fh.write(d)
            try? FileManager.default.removeItem(at: file)
            progress[m.id] = Double(i + 1) / Double(parts.count)
        }
        try? fh.close()
        try? FileManager.default.moveItem(at: tmp, to: out)
        return out
    }
}

/// Пузырь большого файла или большого видео: имя, размер, скачивание с прогрессом, открытие
struct BigFileBubble: View {
    let m: Message
    let mine: Bool
    let onVideo: (URL) -> Void
    @ObservedObject private var bf = BigFiles.shared
    @State private var preview: IdentifiedURL?
    @State private var ready = false

    var body: some View {
        let p = bf.progress[m.id]
        Button { Task { await open() } } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(mine ? Color.white.opacity(0.2) : Theme.a1)
                    if let p {
                        Circle().trim(from: 0, to: max(0.04, p)).stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90)).padding(3)
                            .animation(.easeInOut(duration: 0.3), value: p)
                        Text("\(Int(p * 100))").font(.system(size: 11, weight: .bold))
                    } else {
                        Image(systemName: ready ? (m.kind == "video" ? "play.fill" : "doc.fill") : "arrow.down").font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.fileName).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                    HStack(spacing: 4) {
                        if m.kind == "video" { Image(systemName: "video.fill").font(.system(size: 10)) }
                        if let s = m.fileSize {
                            Text(p.map { "\(Fmt.size(Int(Double(s) * $0))) из \(Fmt.size(s))" } ?? Fmt.size(s))
                        }
                    }
                    .font(.caption).opacity(0.7)
                }
                .foregroundColor(mine ? .white : Theme.text)
            }
        }
        .buttonStyle(.plain)
        .onAppear { ready = bf.isReady(m) }
        .sheet(item: $preview) { it in
            QuickLookView(url: it.url).ignoresSafeArea()
        }
    }

    private func open() async {
        guard let u = await bf.fetch(m) else { return }
        ready = true
        if m.kind == "video" { onVideo(u) } else { preview = IdentifiedURL(url: u) }
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL
    func makeCoordinator() -> Coord { Coord(url) }
    func makeUIViewController(context: Context) -> UINavigationController {
        let q = QLPreviewController()
        q.dataSource = context.coordinator
        return UINavigationController(rootViewController: q)
    }
    func updateUIViewController(_ vc: UINavigationController, context: Context) {}
    final class Coord: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(_ u: URL) { url = u }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as NSURL }
    }
}
