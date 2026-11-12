import SwiftUI
import ImageIO
import UIKit

/// Анимированные эмодзи Google Noto (как в Telegram и на сайте Lumo): сообщение из одних эмодзи «оживает».
enum NotoEmoji {
    @MainActor private static var missing = Set<String>()

    static func graphemes(_ s: String) -> [String] {
        s.trimmingCharacters(in: .whitespaces).filter { !$0.isWhitespace }.map(String.init)
    }

    private static func code(_ g: String, strip: Bool) -> String {
        g.unicodeScalars.filter { !(strip && $0.value == 0xFE0F) }.map { String($0.value, radix: 16) }.joined(separator: "_")
    }

    private static let dir: URL = {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("noto", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    /// файл анимации (скачивается один раз), nil — анимации для этого эмодзи нет
    static func file(_ g: String) async -> URL? {
        for strip in [false, true] {
            let c = code(g, strip: strip)
            if strip && c == code(g, strip: false) { break }
            let f = dir.appendingPathComponent(c + ".webp")
            if FileManager.default.fileExists(atPath: f.path) { return f }
            if await MainActor.run(body: { missing.contains(c) }) { continue }
            guard let u = URL(string: "https://fonts.gstatic.com/s/e/notoemoji/latest/\(c)/512.webp") else { continue }
            if let res = try? await URLSession.shared.download(from: u),
               let r = res.1 as? HTTPURLResponse, (200..<300).contains(r.statusCode) {
                let tmp = res.0
                try? FileManager.default.removeItem(at: f)
                if (try? FileManager.default.moveItem(at: tmp, to: f)) != nil { return f }
            }
            await MainActor.run { _ = missing.insert(c) }
        }
        return nil
    }
}

/// Проигрыватель анимированного WebP: кадры декодируются по ходу (мало памяти)
struct AnimatedWebPView: UIViewRepresentable {
    let url: URL

    final class Coordinator { var stop = false; var started: URL? }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIImageView {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        start(v, context.coordinator)
        return v
    }

    func updateUIView(_ v: UIImageView, context: Context) {
        if context.coordinator.started != url { start(v, context.coordinator) }
    }

    static func dismantleUIView(_ v: UIImageView, coordinator: Coordinator) { coordinator.stop = true }

    private func start(_ v: UIImageView, _ co: Coordinator) {
        co.started = url
        let me = url
        CGAnimateImageAtURLWithBlock(url as CFURL, nil) { [weak v] _, img, stop in
            if co.stop || v == nil || co.started != me { stop.pointee = true; return }
            v?.image = UIImage(cgImage: img)
        }
    }
}

/// Одно эмодзи: пока грузится или если анимации нет — наше нарисованное «живое» эмодзи
struct NotoEmojiView: View {
    let emoji: String
    let size: CGFloat
    @State private var file: URL?
    @State private var pop = false

    var body: some View {
        ZStack {
            if let f = file {
                AnimatedWebPView(url: f).transition(.opacity)
            } else {
                AnimatedEmoji(emoji: emoji, size: size * 0.8, tappable: false)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(pop ? 1.18 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { pop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { pop = false } }
        }
        .task(id: emoji) {
            let f = await NotoEmoji.file(emoji)
            withAnimation(.easeOut(duration: 0.2)) { file = f }
        }
    }
}

/// Сообщение из одних эмодзи — крупно и анимированно
struct NotoEmojiRow: View {
    let text: String
    var body: some View {
        let g = NotoEmoji.graphemes(text)
        let sz: CGFloat = g.count == 1 ? 120 : g.count == 2 ? 96 : g.count == 3 ? 80 : 60
        HStack(spacing: 0) { ForEach(Array(g.enumerated()), id: \.offset) { NotoEmojiView(emoji: $0.element, size: sz) } }
    }
}
