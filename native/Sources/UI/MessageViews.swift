import SwiftUI
import Combine
import AVKit
import AVFoundation

struct VoiceView: View {
    let m: Message
    let mine: Bool
    @ObservedObject private var player = AudioPlayer.shared
    @State private var text: String?

    private var isCurrent: Bool { player.currentId == m.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    if let u = m.mediaURL { player.toggle(id: m.id, url: u) }
                } label: {
                    Image(systemName: isCurrent && player.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(mine ? Color.white.opacity(0.25) : Theme.a1))
                }
                .disabled(m.mediaURL == nil)
                VStack(alignment: .leading, spacing: 5) {
                    WaveBars(wave: m.wave, progress: isCurrent ? player.progress : 0, mine: mine)
                    Text(isCurrent && player.position > 0 ? Fmt.duration(player.position) : Fmt.duration(m.duration))
                        .font(.caption).foregroundColor(mine ? .white.opacity(0.75) : Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TranscribeButton(m: m, mine: mine, ext: "m4a", text: $text)
            }
            if let t = text {
                Text(t).font(.system(size: 15)).foregroundColor(mine ? .white : Theme.text).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 252, alignment: .leading)
    }
}

/// Кнопка расшифровки справа от голосового или кружка; со значком замка, пока нет Premium
struct TranscribeButton: View {
    let m: Message
    let mine: Bool
    let ext: String
    @Binding var text: String?
    @EnvironmentObject var model: AppModel
    @State private var busy = false

    var body: some View {
        Button {
            if !model.isPremium { model.say(premiumSoon); return }
            if text != nil { text = nil; return }
            guard let u = m.mediaURL, !busy else { return }
            busy = true
            Task {
                switch await Transcriber.run(urlString: u, ext: ext) {
                case .success(let t): text = t
                case .failure(let e): model.say(e.localizedDescription)
                }
                busy = false
            }
        } label: {
            ZStack {
                if busy { ProgressView().tint(mine ? .white : Theme.a1) }
                else {
                    HStack(spacing: 1) {
                        Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
                        Text("A").font(.system(size: 15, weight: .heavy))
                    }
                }
            }
            .foregroundColor(mine ? .white : Theme.a1)
            .frame(width: 38, height: 32)
            .background(RoundedRectangle(cornerRadius: 11).fill(mine ? Color.white.opacity(0.2) : Theme.a1.opacity(0.14)))
            .overlay(alignment: .bottomTrailing) {
                if !model.isPremium { Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold)).foregroundColor(mine ? .white : Theme.a1).padding(.trailing, 4).padding(.bottom, 3) }
            }
        }
        .buttonStyle(.plain)
    }
}

struct WaveBars: View {
    let wave: [Int]
    let progress: Double
    let mine: Bool

    var body: some View {
        let src = wave.isEmpty ? Array(repeating: 6, count: 40) : wave
        GeometryReader { g in
            let n = max(8, Int(g.size.width / 4.5))
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<n, id: \.self) { i in
                    let v = src[min(src.count - 1, i * src.count / n)]
                    let done = Double(i) / Double(n) < progress
                    Capsule()
                        .fill(mine ? (done ? Color.white : Color.white.opacity(0.45)) : (done ? Theme.a1 : Theme.muted.opacity(0.45)))
                        .frame(width: 2.5, height: 4 + CGFloat(min(31, max(0, v))) / 31 * 20)
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .leading)
        }
        .frame(height: 24)
    }
}

struct VideoThumb: View {
    let url: URL
    @State private var thumb: UIImage?

    var body: some View {
        ZStack {
            if let t = thumb { Image(uiImage: t).resizable().scaledToFill() } else { Color.white.opacity(0.06) }
            Image(systemName: "play.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(Circle().fill(Color.black.opacity(0.45)))
        }
        .frame(width: 240, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task { thumb = await Media.thumbnail(url) }
    }
}

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    var fill = true

    final class V: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> V {
        let v = V()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = fill ? .resizeAspectFill : .resizeAspect
        return v
    }

    func updateUIView(_ v: V, context: Context) { v.playerLayer.player = player }
}

/// Видеосообщение-кружок: нажали — играет прямо в чате
struct VideoNoteView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var thumb: UIImage?
    @State private var big = false
    @State private var progress: Double = 0
    @State private var paused = false
    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var side: CGFloat { big ? min(UIScreen.main.bounds.width - 70, 310) : 210 }

    private func setBig(_ b: Bool) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { big = b }
    }

    var body: some View {
        ZStack {
            if let p = player { PlayerLayerView(player: p) }
            else if let t = thumb { Image(uiImage: t).resizable().scaledToFill() }
            else { Theme.panel }
            if player == nil || paused {
                Image(systemName: "play.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.accent, lineWidth: 3).opacity(big ? 0.35 : 1))
        .overlay(
            Circle().trim(from: 0, to: progress)
                .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(1.5)
                .opacity(player == nil ? 0 : 1)
        )
        .contentShape(Circle())
        .onTapGesture {
            if let p = player {
                if p.timeControlStatus == .playing { p.pause(); paused = true }
                else { p.play(); paused = false }
            } else {
                AudioPlayer.shared.stop()
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                let p = AVPlayer(url: url.px)
                player = p
                paused = false
                progress = 0
                p.play()
                setBig(true)
            }
        }
        .onReceive(tick) { _ in
            guard let p = player, let item = p.currentItem else { return }
            let d = item.duration.seconds
            if d.isFinite, d > 0 { progress = min(1, max(0, p.currentTime().seconds / d)) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { n in
            if let item = n.object as? AVPlayerItem, item === player?.currentItem {
                player = nil
                paused = false
                progress = 0
                setBig(false)
            }
        }
        .onDisappear { player?.pause(); player = nil; big = false; paused = false; progress = 0 }
        .task { thumb = await Media.thumbnail(url) }
    }
}

struct VideoScreen: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let p = player { VideoPlayer(player: p).ignoresSafeArea() }
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline).foregroundColor(.white)
                    .frame(width: 42, height: 42).background(Circle().fill(Color.white.opacity(0.15)))
            }
            .padding(16)
        }
        .onAppear {
            AudioPlayer.shared.stop()
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            let p = AVPlayer(url: url.px)
            player = p
            p.play()
        }
        .onDisappear {
            player?.pause()
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        }
    }
}

struct ImageScreen: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var last: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var share = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            CachedImage(url: url) { img in img.resizable().scaledToFit() } placeholder: { ProgressView().tint(.white) }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(MagnificationGesture()
                    .onChanged { v in scale = max(1, min(5, last * v)) }
                    .onEnded { _ in last = scale; if scale <= 1 { withAnimation { offset = .zero } } })
                .simultaneousGesture(DragGesture()
                    .onChanged { v in offset = v.translation }
                    .onEnded { v in
                        if scale <= 1 && v.translation.height > 120 { dismiss() }
                        else if scale <= 1 { withAnimation { offset = .zero } }
                    })
                .onTapGesture(count: 2) { withAnimation { scale = scale > 1 ? 1 : 2.5; last = scale; offset = .zero } }
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.headline).foregroundColor(.white)
                        .frame(width: 42, height: 42).background(Circle().fill(Color.white.opacity(0.15)))
                }
                Spacer()
                Button { share = true } label: {
                    Image(systemName: "square.and.arrow.up").font(.headline).foregroundColor(.white)
                        .frame(width: 42, height: 42).background(Circle().fill(Color.white.opacity(0.15)))
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $share) {
            if let i = ImageCache.shared.get(url) { ShareSheet(items: [i]) } else { ShareSheet(items: [url]) }
        }
    }
}

/// Кружок в маленьком окошке справа сверху (как в Telegram) — проигрывается поверх приложения
@MainActor
final class MiniNotePlayer: ObservableObject {
    static let shared = MiniNotePlayer()
    @Published var player: AVPlayer?
    @Published var progress: Double = 0
    @Published var paused = false
    private var observer: Any?
    private var endObs: NSObjectProtocol?

    func play(_ url: URL) {
        stop()
        AudioPlayer.shared.stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        let p = AVPlayer(url: url.px)
        observer = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { @Sendable t in
            Task { @MainActor in
                let mp = MiniNotePlayer.shared
                guard let d = mp.player?.currentItem?.duration.seconds, d.isFinite, d > 0 else { return }
                mp.progress = min(1, t.seconds / d)
            }
        }
        endObs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: .main) { @Sendable _ in
            Task { @MainActor in MiniNotePlayer.shared.stop() }
        }
        paused = false
        progress = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { player = p }
        p.play()
    }

    func toggle() {
        guard let p = player else { return }
        if p.timeControlStatus == .playing { p.pause(); paused = true } else { p.play(); paused = false }
    }

    func stop() {
        if let o = observer { player?.removeTimeObserver(o) }
        observer = nil
        if let e = endObs { NotificationCenter.default.removeObserver(e) }
        endObs = nil
        player?.pause()
        withAnimation(.easeOut(duration: 0.2)) { player = nil }
        progress = 0
    }
}

struct MiniNoteOverlay: View {
    @ObservedObject private var mp = MiniNotePlayer.shared

    var body: some View {
        if let p = mp.player {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    PlayerLayerView(player: p)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                    Circle().trim(from: 0, to: mp.progress)
                        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 146, height: 146)
                    if mp.paused {
                        Image(systemName: "play.fill").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                            .frame(width: 54, height: 54).background(Circle().fill(Color.black.opacity(0.4)))
                    }
                }
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                .onTapGesture { mp.toggle() }
                Button { mp.stop() } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .frame(width: 26, height: 26).background(Circle().fill(Color.black.opacity(0.6)))
                }
                .offset(x: 4, y: -4)
            }
            .padding(.top, 54).padding(.trailing, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .transition(.scale(scale: 0.3, anchor: .topTrailing).combined(with: .opacity))
        }
    }
}
