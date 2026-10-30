import SwiftUI

/// Альбом: несколько фото/видео в одном пузыре, сеткой (как в Telegram)
struct AlbumGrid: View {
    let items: [Message]
    var onImage: (URL) -> Void
    var onVideo: (URL) -> Void

    /// Сколько ячеек в каждом ряду
    static func rows(_ n: Int) -> [Int] {
        switch n {
        case 2: return [2]
        case 3: return [1, 2]
        case 4: return [2, 2]
        case 5: return [2, 3]
        case 6: return [3, 3]
        case 7: return [1, 3, 3]
        case 8: return [2, 3, 3]
        case 9: return [3, 3, 3]
        default: return [2, 2, 3, 3]
        }
    }

    var body: some View {
        let width: CGFloat = 250
        let gap: CGFloat = 2
        let shown = Array(items.prefix(10))
        let rs = Self.rows(shown.count)
        VStack(spacing: gap) {
            ForEach(0..<rs.count, id: \.self) { r in
                let start = rs[0..<r].reduce(0, +)
                let n = rs[r]
                let h: CGFloat = n == 1 ? 190 : (n == 2 ? 124 : 82)
                HStack(spacing: gap) {
                    ForEach(0..<n, id: \.self) { c in
                        if start + c < shown.count {
                            AlbumCell(m: shown[start + c], onImage: onImage, onVideo: onVideo)
                                .frame(width: (width - gap * CGFloat(n - 1)) / CGFloat(n), height: h)
                        }
                    }
                }
            }
        }
        .frame(width: width)
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}

struct AlbumCell: View {
    let m: Message
    var onImage: (URL) -> Void
    var onVideo: (URL) -> Void
    @State private var thumb: UIImage?

    private var url: URL? { m.mediaURL.flatMap(URL.init(string:)) }

    var body: some View {
        Color.clear
            .overlay {
                ZStack {
                    if let u = url {
                        if m.kind == "video" {
                            if let t = thumb { Image(uiImage: t).resizable().scaledToFill() } else { Color.white.opacity(0.08) }
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                .frame(width: 40, height: 40).background(Circle().fill(Color.black.opacity(0.45)))
                        } else {
                            CachedImage(url: u) { $0.resizable().scaledToFill() } placeholder: { Color.white.opacity(0.08) }
                        }
                    } else {
                        Color.white.opacity(0.08)
                        ProgressView()
                    }
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                guard let u = url else { return }
                if m.kind == "video" { onVideo(u) } else { onImage(u) }
            }
            .task(id: m.mediaURL) {
                if m.kind == "video", let u = url { thumb = await Media.thumbnail(u) }
            }
    }
}
