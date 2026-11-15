import SwiftUI
import AVFoundation
import MediaPlayer
import Combine

/// Трек — аудиофайл из чата
struct AudioTrack: Identifiable, Equatable {
    let id: Int          // id сообщения
    let chatId: String
    let title: String
    let artist: String
    let url: URL
    let fileName: String
    static func == (a: AudioTrack, b: AudioTrack) -> Bool { a.id == b.id }
}

/// Глобальный музыкальный плеер: играет в фоне, переживает выход из чата, показывается плашкой сверху.
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var track: AudioTrack?
    @Published var playing = false
    @Published var time: Double = 0
    @Published var duration: Double = 0
    @Published private(set) var queue: [AudioTrack] = []

    private var player: AVPlayer?
    private var timeObs: Any?
    private var endObs: Any?

    static let audioExt: Set<String> = ["mp3", "m4a", "wav", "flac", "aac", "opus", "ogg", "aiff", "alac"]
    static func isAudio(_ name: String) -> Bool { audioExt.contains((name as NSString).pathExtension.lowercased()) }

    var progress: Double { duration > 0 ? time / duration : 0 }

    private init() {
        endObs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            self?.next()
        }
    }

    /// Собрать очередь из всех аудио чата и начать с выбранного
    func play(_ m: Message, in messages: [Message]) {
        guard let url = m.mediaURL.flatMap(URL.init(string:)) else { return }
        let q: [AudioTrack] = messages.compactMap { msg in
            guard msg.kind == "file", Self.isAudio(msg.fileName), let u = msg.mediaURL.flatMap(URL.init(string:)) else { return nil }
            return track(for: msg, url: u)
        }
        queue = q
        start(track(for: m, url: url))
    }

    private func track(for m: Message, url: URL) -> AudioTrack {
        let base = (m.fileName as NSString).deletingPathExtension
        // «Исполнитель — Название», если так названо
        let parts = base.components(separatedBy: " - ")
        let title = parts.count > 1 ? parts.dropFirst().joined(separator: " - ") : base
        let artist = parts.count > 1 ? parts[0] : "Lumo"
        return AudioTrack(id: m.id, chatId: m.chatId, title: title, artist: artist, url: url, fileName: m.fileName)
    }

    func toggle() { playing ? pause() : resume() }

    /// Выбрать трек из очереди (список в плеере)
    func playTrack(_ t: AudioTrack) { start(t) }

    private func start(_ t: AudioTrack) {
        if track?.id == t.id, player != nil { resume(); return }
        teardown()
        track = t
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        let local = FileStore.shared.local(t.url, .file)
        let p = AVPlayer(url: local ?? t.url.px)
        player = p
        duration = 0; time = 0
        timeObs = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.4, preferredTimescale: 600), queue: .main) { [weak self] tm in
            guard let self = self else { return }
            self.time = tm.seconds
            if let d = p.currentItem?.duration.seconds, d.isFinite, d > 0 { self.duration = d }
            self.updateNowPlaying()
        }
        p.play(); playing = true
        setupRemote()
        updateNowPlaying()
        // если файла нет локально — докачаем и подменим, чтобы играло стабильно
        if local == nil {
            Task { if let l = await FileStore.shared.fetch(t.url, .file), self.track?.id == t.id {
                let at = p.currentTime()
                let np = AVPlayer(url: l); self.swap(np, seek: at)
            } }
        }
    }

    private func swap(_ np: AVPlayer, seek: CMTime) {
        let wasPlaying = playing
        if let o = timeObs { player?.removeTimeObserver(o); timeObs = nil }
        player = np
        np.seek(to: seek)
        timeObs = np.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.4, preferredTimescale: 600), queue: .main) { [weak self] tm in
            guard let self = self else { return }
            self.time = tm.seconds
            if let d = np.currentItem?.duration.seconds, d.isFinite, d > 0 { self.duration = d }
            self.updateNowPlaying()
        }
        if wasPlaying { np.play() }
    }

    func resume() { player?.play(); playing = true; updateNowPlaying() }
    func pause() { player?.pause(); playing = false; updateNowPlaying() }

    func seek(toFraction f: Double) {
        guard duration > 0 else { return }
        let t = max(0, min(duration, f * duration))
        player?.seek(to: CMTime(seconds: t, preferredTimescale: 600))
        time = t
    }
    func seek(seconds t: Double) {
        player?.seek(to: CMTime(seconds: max(0, t), preferredTimescale: 600)); time = t
    }

    func next() {
        guard let cur = track, let i = queue.firstIndex(of: cur) else { stop(); return }
        if i + 1 < queue.count { start(queue[i + 1]) } else { pause(); seek(seconds: 0) }
    }
    func prev() {
        guard let cur = track, let i = queue.firstIndex(of: cur) else { return }
        if time > 3 { seek(seconds: 0); return }
        if i - 1 >= 0 { start(queue[i - 1]) } else { seek(seconds: 0) }
    }

    func stop() {
        teardown()
        track = nil; playing = false; time = 0; duration = 0; queue = []
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func teardown() {
        if let o = timeObs { player?.removeTimeObserver(o); timeObs = nil }
        player?.pause(); player = nil
    }

    // MARK: управление с экрана блокировки
    private var remoteSet = false
    private func setupRemote() {
        guard !remoteSet else { return }; remoteSet = true
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.resume(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.prev(); return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] e in
            if let e = e as? MPChangePlaybackPositionCommandEvent { self?.seek(seconds: e.positionTime) }
            return .success
        }
    }
    private func updateNowPlaying() {
        guard let t = track else { return }
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = t.title
        info[MPMediaItemPropertyArtist] = t.artist
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        info[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
