import SwiftUI
import AVFoundation
import Combine
import UIKit

/// Состояние плеера: время, длительность, буфер, скорость, звук
@MainActor
final class VideoPlayerModel: ObservableObject {
    let player: AVPlayer
    @Published var wantsPlay = false
    @Published var isBuffering = true
    @Published var time: Double = 0
    @Published var duration: Double = 0
    @Published var buffered: Double = 0
    @Published var ended = false
    @Published var failed = false
    @Published var rate: Float = 1
    @Published var muted = false
    var scrubbing = false

    private var timeObs: Any?
    private var endObs: NSObjectProtocol?
    private var bag = Set<AnyCancellable>()

    init(url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .pause

        timeObs = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main) { @Sendable [weak self] t in
            let s = t.seconds
            Task { @MainActor in
                guard let self, !self.scrubbing, s.isFinite else { return }
                self.time = s
            }
        }

        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self else { return }
                self.wantsPlay = s != .paused
                self.isBuffering = s == .waitingToPlayAtSpecifiedRate
            }
            .store(in: &bag)

        item.publisher(for: \.duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] d in
                let s = d.seconds
                if s.isFinite, s > 0 { self?.duration = s }
            }
            .store(in: &bag)

        item.publisher(for: \.loadedTimeRanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vals in
                guard let self else { return }
                let ranges = vals.map { $0.timeRangeValue }
                let cur = self.player.currentTime().seconds
                if let r = ranges.first(where: { $0.start.seconds <= cur + 0.5 && $0.end.seconds >= cur }) ?? ranges.last {
                    self.buffered = r.end.seconds
                }
            }
            .store(in: &bag)

        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] st in
                if st == .failed { self?.failed = true; self?.isBuffering = false }
            }
            .store(in: &bag)

        endObs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { @Sendable [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.ended = true
                self.wantsPlay = false
            }
        }
    }

    func play() {
        if ended { seek(to: 0) }
        ended = false
        player.playImmediately(atRate: rate)
    }

    func pause() { player.pause() }

    func toggle() {
        if wantsPlay && !ended { pause() } else { play() }
    }

    func seek(to t: Double) {
        let top = duration > 0 ? duration : max(t, 0)
        let c = min(max(0, t), top)
        time = c
        ended = false
        player.seek(to: CMTime(seconds: c, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func skip(_ d: Double) { seek(to: time + d) }

    func setRate(_ r: Float) {
        rate = r
        if wantsPlay && !ended { player.rate = r }
    }

    func toggleMute() {
        muted.toggle()
        player.isMuted = muted
    }

    func teardown() {
        if let o = timeObs { player.removeTimeObserver(o) }
        timeObs = nil
        if let e = endObs { NotificationCenter.default.removeObserver(e) }
        endObs = nil
        bag.removeAll()
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}

private func vpTime(_ s: Double) -> String {
    guard s.isFinite, s > 0 else { return "0:00" }
    let t = Int(s.rounded(.down))
    let h = t / 3600, m = (t % 3600) / 60, sec = t % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
}

private func vpRate(_ r: Float) -> String {
    (String(format: "%g", r) + "×").replacingOccurrences(of: ".", with: ",")
}

/// Полоса перемотки: буфер, ползунок, метка времени при перетаскивании
struct VPScrubber: View {
    let time: Double
    let duration: Double
    let buffered: Double
    var onScrub: (Double) -> Void
    var onEnd: (Double) -> Void
    @State private var dragging = false
    @State private var dragValue: Double = 0

    var body: some View {
        GeometryReader { g in
            let w = max(1, g.size.width)
            let shown = dragging ? dragValue : time
            let frac = duration > 0 ? min(1, max(0, shown / duration)) : 0
            let bfrac = duration > 0 ? min(1, max(0, buffered / duration)) : 0
            let h: CGFloat = dragging ? 8 : 4
            let knob: CGFloat = dragging ? 22 : 14
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.25)).frame(height: h)
                Capsule().fill(Color.white.opacity(0.38)).frame(width: w * CGFloat(bfrac), height: h)
                Capsule().fill(Color.white).frame(width: w * CGFloat(frac), height: h)
                Circle().fill(Color.white).frame(width: knob, height: knob)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                    .offset(x: w * CGFloat(frac) - knob / 2)
                if dragging {
                    Text(vpTime(shown))
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundColor(.white)
                        .frame(width: 60, height: 26)
                        .background(Capsule().fill(Color.black.opacity(0.65)))
                        .offset(x: min(max(0, w * CGFloat(frac) - 30), w - 60), y: -34)
                }
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let t = duration * Double(min(1, max(0, v.location.x / w)))
                        if !dragging { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                        dragging = true
                        dragValue = t
                        onScrub(t)
                    }
                    .onEnded { v in
                        let t = duration * Double(min(1, max(0, v.location.x / w)))
                        dragging = false
                        onEnd(t)
                    }
            )
            .animation(.easeOut(duration: 0.12), value: dragging)
        }
        .frame(height: 40)
    }
}

/// Собственный видеоплеер: перемотка, скорость, ±10 секунд двойным касанием, свайп вниз — закрыть
struct VideoScreen: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: VideoPlayerModel
    @State private var visible = true
    @State private var dragY: CGFloat = 0
    @State private var flash = 0
    @State private var hideTask: Task<Void, Never>?
    @State private var flashTask: Task<Void, Never>?

    init(url: URL) {
        self.url = url
        _vm = StateObject(wrappedValue: VideoPlayerModel(url: url.px))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                PlayerLayerView(player: vm.player, fill: false)
                    .ignoresSafeArea()
                    .offset(y: dragY)
                    .scaleEffect(1 - min(0.25, abs(dragY) / 1500))

                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(
                        ExclusiveGesture(SpatialTapGesture(count: 2), TapGesture(count: 1))
                            .onEnded { r in
                                switch r {
                                case .first(let v): doubleTap(x: v.location.x, width: geo.size.width)
                                case .second: toggleControls()
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 18)
                            .onChanged { v in
                                if abs(v.translation.height) > abs(v.translation.width) { dragY = max(0, v.translation.height) }
                            }
                            .onEnded { v in
                                if v.translation.height > 120 || v.predictedEndTranslation.height > 420 { dismiss() }
                                else { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragY = 0 } }
                            }
                    )

                if vm.isBuffering && !vm.failed && !visible {
                    ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(1.6)
                }

                if flash != 0 {
                    VStack(spacing: 4) {
                        Image(systemName: flash < 0 ? "gobackward.10" : "goforward.10").font(.system(size: 34, weight: .semibold))
                        Text("10 сек").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 104, height: 104)
                    .background(Circle().fill(Color.white.opacity(0.2)))
                    .frame(maxWidth: .infinity, alignment: flash < 0 ? .leading : .trailing)
                    .padding(.horizontal, 28)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                if vm.failed {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle").font(.system(size: 34)).foregroundColor(.white.opacity(0.8))
                        Text("Не удалось загрузить видео").foregroundColor(.white).font(.system(size: 16, weight: .semibold))
                    }
                }

                if visible { controls.transition(.opacity) }
            }
        }
        .statusBarHidden(!visible)
        .onAppear {
            AudioPlayer.shared.stop()
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.isIdleTimerDisabled = true
            vm.play()
            poke()
        }
        .onDisappear {
            hideTask?.cancel()
            flashTask?.cancel()
            vm.teardown()
            UIApplication.shared.isIdleTimerDisabled = false
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        }
    }

    // MARK: управление

    private var controls: some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.6), .clear, .clear, Color.black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
            if !vm.failed { centerButtons }
        }
    }

    private func circle(_ system: String, size: CGFloat = 40, action: @escaping () -> Void) -> some View {
        Button {
            action()
            poke()
        } label: {
            Image(systemName: system).font(.system(size: size * 0.42, weight: .semibold)).foregroundColor(.white)
                .frame(width: size, height: size).background(Circle().fill(Color.white.opacity(0.16)))
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            circle("xmark") { dismiss() }
            Spacer()
            Menu {
                ForEach([Float(0.5), 0.75, 1, 1.25, 1.5, 2], id: \.self) { r in
                    Button {
                        vm.setRate(r)
                        poke()
                    } label: {
                        if r == vm.rate { Label(vpRate(r), systemImage: "checkmark") } else { Text(vpRate(r)) }
                    }
                }
            } label: {
                Text(vpRate(vm.rate)).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 13).frame(height: 40)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
            }
            circle(vm.muted ? "speaker.slash.fill" : "speaker.wave.2.fill") { vm.toggleMute() }
            circle("arrow.down.to.line") { Task { await Gallery.saveVideo(url) } }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private var centerButtons: some View {
        HStack(spacing: 40) {
            circle("gobackward.10", size: 52) { vm.skip(-10) }
            Button {
                vm.toggle()
                poke()
            } label: {
                ZStack {
                    Circle().fill(Color.black.opacity(0.45))
                    if vm.isBuffering {
                        ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(1.4)
                    } else {
                        Image(systemName: vm.ended ? "arrow.counterclockwise" : (vm.wantsPlay ? "pause.fill" : "play.fill"))
                            .font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                    }
                }
                .frame(width: 76, height: 76)
            }
            circle("goforward.10", size: 52) { vm.skip(10) }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            VPScrubber(time: vm.time, duration: vm.duration, buffered: vm.buffered,
                       onScrub: { t in
                           vm.scrubbing = true
                           vm.time = t
                           hideTask?.cancel()
                       },
                       onEnd: { t in
                           vm.seek(to: t)
                           vm.scrubbing = false
                           poke()
                       })
            HStack {
                Text(vpTime(vm.time))
                Spacer()
                Text(vpTime(vm.duration))
            }
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundColor(.white.opacity(0.92))
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // MARK: жесты

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { visible.toggle() }
        if visible { poke() }
    }

    private func doubleTap(x: CGFloat, width: CGFloat) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if x < width / 3 { jump(-10, side: -1) }
        else if x > width * 2 / 3 { jump(10, side: 1) }
        else { vm.toggle() }
    }

    private func jump(_ d: Double, side: Int) {
        vm.skip(d)
        withAnimation(.easeOut(duration: 0.15)) { flash = side }
        flashTask?.cancel()
        flashTask = Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            if !Task.isCancelled { withAnimation(.easeIn(duration: 0.2)) { flash = 0 } }
        }
    }

    /// показать кнопки и спрятать их через несколько секунд, пока видео идёт
    private func poke() {
        if !visible { withAnimation(.easeInOut(duration: 0.2)) { visible = true } }
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if Task.isCancelled { return }
            if vm.wantsPlay && !vm.scrubbing && !vm.ended {
                withAnimation(.easeInOut(duration: 0.25)) { visible = false }
            }
        }
    }
}
