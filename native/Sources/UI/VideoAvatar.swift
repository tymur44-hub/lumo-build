import SwiftUI
import AVFoundation
import PhotosUI
import UniformTypeIdentifiers

/// Видео-аватарки (Premium): видео до 10 секунд, зациклено и без звука играет вместо фото —
/// в списке чатов, в профиле и везде, где показывается аватар. Фото-обложка (первый кадр)
/// сохраняется как обычная аватарка, поэтому старые версии приложения видят хотя бы её.
@MainActor
final class VideoAvatars: ObservableObject {
    static let shared = VideoAvatars()
    /// адрес фото-аватарки → адрес видео
    @Published private(set) var byImage: [String: URL] = [:]
    private var asked = Set<String>()
    private let d = UserDefaults.standard

    private init() {
        if let m = d.dictionary(forKey: "lm_vavatars") as? [String: String] {
            byImage = m.compactMapValues { URL(string: $0) }
        }
    }

    func video(for image: String?) -> URL? { image.flatMap { byImage[$0] } }

    /// узнать видео-аватарки людей (один раз за запуск на человека)
    func load(_ ids: [String]) async {
        let need = Array(Set(ids.filter { !$0.isEmpty && !asked.contains($0) }))
        guard !need.isEmpty else { return }
        need.forEach { asked.insert($0) }
        guard let rows = (try? await API.shared.rpc("lm_avatar_videos", ["p_ids": need])) as? [JSON] else { return }
        var m = byImage
        for r in rows {
            if let img = r.str("avatar_url"), let v = r.str("video").flatMap(URL.init(string:)) { m[img] = v }
        }
        byImage = m
        d.set(m.mapValues { $0.absoluteString }, forKey: "lm_vavatars")
    }

    func remember(image: String, video: URL) {
        byImage[image] = video
        d.set(byImage.mapValues { $0.absoluteString }, forKey: "lm_vavatars")
    }
}

/// Зацикленное видео без звука (для аватарок)
struct LoopingVideo: View {
    let url: URL
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var visible = false

    var body: some View {
        ZStack {
            if let p = player { PlayerLayerView(player: p).allowsHitTesting(false).transition(.opacity) }
        }
        .task(id: url) {
            let f = MediaCache.shared.local(url) != nil ? MediaCache.shared.local(url)! : await MediaCache.shared.fetch(url)
            let q = AVQueuePlayer()
            q.isMuted = true
            q.preventsDisplaySleepDuringVideoPlayback = false
            let l = AVPlayerLooper(player: q, templateItem: AVPlayerItem(url: f))
            looper = l
            withAnimation(.easeOut(duration: 0.3)) { player = q }
            if visible { q.play() }
        }
        .onAppear { visible = true; player?.play() }
        .onDisappear { visible = false; player?.pause() }
    }
}

/// Видео из галереи как файл
struct PickedMovie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { r in
            let dst = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + (r.file.pathExtension.isEmpty ? "mov" : r.file.pathExtension))
            try? FileManager.default.removeItem(at: dst)
            try FileManager.default.copyItem(at: r.file, to: dst)
            return PickedMovie(url: dst)
        }
    }
}

/// Выбор отрезка до 10 секунд и загрузка видео-аватарки
struct VideoAvatarTrimSheet: View {
    let source: URL
    let done: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var duration: Double = 0
    @State private var start: Double = 0
    @State private var player = AVPlayer()
    @State private var busy = false
    @State private var observer: Any?
    private let maxLen: Double = 10

    private var length: Double { min(maxLen, duration) }

    var body: some View {
        VStack(spacing: 18) {
            Text("Видео-аватарка").font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text).padding(.top, 18)
            PlayerLayerView(player: player)
                .frame(width: 240, height: 240)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
            if duration > maxLen {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Выберите отрезок: \(Fmt.duration(start)) – \(Fmt.duration(start + length))")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    Slider(value: $start, in: 0...max(0.01, duration - length)) { editing in if !editing { seek() } }
                        .tint(Theme.a1)
                    Text("Видео длиннее 10 секунд — оставим только выбранный кусочек.")
                        .font(.footnote).foregroundColor(Theme.muted)
                }
                .padding(.horizontal, 24)
            } else if duration > 0 {
                Text("Длина \(Fmt.duration(duration)) — подходит целиком.").font(.footnote).foregroundColor(Theme.muted)
            }
            Spacer()
            Button { Task { await save() } } label: {
                HStack { if busy { ProgressView().tint(.white) }; Text(busy ? "Загрузка…" : "Установить") }
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(busy || duration == 0)
            .padding(.horizontal, 20)
            Button("Отмена") { done() }.foregroundColor(Theme.muted).padding(.bottom, 16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            let asset = AVURLAsset(url: source)
            duration = (try? await asset.load(.duration))?.seconds ?? 0
            player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
            player.isMuted = true
            seek()
            // крутим выбранный кусочек по кругу
            observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: .main) { t in
                Task { @MainActor in if t.seconds >= start + length - 0.05 { seek() } }
            }
            player.play()
        }
        .onDisappear { player.pause(); if let o = observer { player.removeTimeObserver(o) } }
    }

    private func seek() {
        player.seek(to: CMTime(seconds: start, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
    }

    private func save() async {
        busy = true
        defer { busy = false }
        guard let out = await export() else { model.say("Не удалось подготовить видео"); return }
        do {
            let data = try Data(contentsOf: out)
            // обложка — первый кадр отрезка
            let gen = AVAssetImageGenerator(asset: AVURLAsset(url: out))
            gen.appliesPreferredTrackTransform = true
            var coverURL: String?
            if let cg = try? gen.copyCGImage(at: .zero, actualTime: nil), let jpg = Media.squareJPEG(UIImage(cgImage: cg), side: 640) {
                coverURL = try await API.shared.upload(jpg, ext: "jpg", contentType: "image/jpeg")
            }
            let videoURL = try await API.shared.upload(data, ext: "mp4", contentType: "video/mp4")
            var p: JSON = ["p_video": videoURL]
            if let c = coverURL { p["p_cover"] = c }
            _ = try await API.shared.rpc("lm_set_avatar_video", p)
            if let c = coverURL, let v = URL(string: videoURL) {
                // своё видео сразу кладём в кэш, чтобы не скачивать заново
                let local = MediaCache.shared.local(v)
                if local == nil { _ = await MediaCache.shared.fetch(v) }
                VideoAvatars.shared.remember(image: c, video: v)
            }
            await model.loadMe()
            model.say("Видео-аватарка установлена")
            done()
        } catch { model.say(error.localizedDescription) }
    }

    /// квадрат 480×480, до 10 секунд, без звука
    private func export() async -> URL? {
        let asset = AVURLAsset(url: source)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first,
              let natural = try? await track.load(.naturalSize), let tf = try? await track.load(.preferredTransform) else { return nil }
        let r = CGRect(origin: .zero, size: natural).applying(tf)
        let w = abs(r.width), h = abs(r.height), side = min(w, h)
        let comp = AVMutableVideoComposition()
        comp.renderSize = CGSize(width: 480, height: 480)
        comp.frameDuration = CMTime(value: 1, timescale: 30)
        let ins = AVMutableVideoCompositionInstruction()
        let range = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), duration: CMTime(seconds: length, preferredTimescale: 600))
        ins.timeRange = CMTimeRange(start: .zero, duration: range.duration)
        let mix = AVMutableComposition()
        guard let ct = mix.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return nil }
        try? ct.insertTimeRange(range, of: track, at: .zero)
        let li = AVMutableVideoCompositionLayerInstruction(assetTrack: ct)
        let scale = 480 / side
        var t = tf.concatenating(CGAffineTransform(translationX: -r.minX, y: -r.minY))
        t = t.concatenating(CGAffineTransform(translationX: -(w - side) / 2, y: -(h - side) / 2))
        t = t.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        li.setTransform(t, at: .zero)
        ins.layerInstructions = [li]
        comp.instructions = [ins]
        guard let ex = AVAssetExportSession(asset: mix, presetName: AVAssetExportPresetMediumQuality) else { return nil }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        ex.outputURL = out
        ex.outputFileType = .mp4
        ex.videoComposition = comp
        ex.shouldOptimizeForNetworkUse = true
        await ex.export()
        return ex.status == .completed ? out : nil
    }
}
