import SwiftUI
import Combine
import WebRTC

/// Видео собеседника или своё (WebRTC → Metal)
struct RTCVideoView: UIViewRepresentable {
    let track: RTCVideoTrack?
    var mirror = false

    final class Coordinator { var track: RTCVideoTrack? }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let v = RTCMTLVideoView(frame: .zero)
        v.videoContentMode = .scaleAspectFill
        v.clipsToBounds = true
        if mirror { v.transform = CGAffineTransform(scaleX: -1, y: 1) }
        return v
    }

    func updateUIView(_ v: RTCMTLVideoView, context: Context) {
        if context.coordinator.track !== track {
            context.coordinator.track?.remove(v)
            track?.add(v)
            context.coordinator.track = track
        }
    }

    static func dismantleUIView(_ v: RTCMTLVideoView, coordinator: Coordinator) {
        coordinator.track?.remove(v)
        coordinator.track = nil
    }
}

struct CallView: View {
    @EnvironmentObject var calls: CallManager
    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var showRemote: Bool { calls.video && calls.state == .active && calls.p2p && calls.remoteVideo != nil && !calls.peerCamOff }
    private var showRelay: Bool { calls.video && calls.state == .active && !calls.p2p && calls.relayImage != nil && !calls.peerCamOff }

    var body: some View {
        ZStack {
            AuroraBackground(intensity: calls.state == .active ? 0.8 : 1, speed: calls.state == .active ? 0.7 : 1.4)
            if showRemote {
                RTCVideoView(track: calls.remoteVideo).ignoresSafeArea()
            } else if showRelay, let im = calls.relayImage {
                Image(uiImage: im).resizable().scaledToFill().ignoresSafeArea()
            }
            VStack(spacing: 14) {
                if !showRemote && !showRelay {
                    Spacer().frame(height: 60)
                    ZStack {
                        if calls.state != .active { PulseRings(size: 130) }
                        AvatarView(name: calls.peerName, url: calls.peerAvatar, color: calls.peerColor, size: 130)
                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 2))
                            .shadow(color: Theme.a1.opacity(0.6), radius: 28)
                    }
                    .frame(height: 170)
                    Text(calls.peerName).font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                    Text(statusLine).font(.headline).foregroundColor(.white.opacity(0.75))
                } else {
                    HStack {
                        Text(calls.peerName + " · " + statusLine)
                            .font(.headline).foregroundColor(.white).shadow(radius: 6)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 10)
                }
                Spacer()
                controls.padding(.bottom, 30)
            }
            if calls.video, let lv = calls.localVideo, !calls.camOff, calls.state != .incoming {
                VStack {
                    HStack {
                        Spacer()
                        RTCVideoView(track: lv, mirror: true)
                            .frame(width: 112, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3)))
                            .padding(.trailing, 16).padding(.top, 50)
                    }
                    Spacer()
                }
            }
        }
        .onReceive(tick) { now = $0 }
        .statusBarHidden(showRemote || showRelay)
    }

    private var statusLine: String {
        if !calls.statusText.isEmpty { return calls.statusText }
        if let s = calls.startedAt { return Fmt.duration(now.timeIntervalSince(s)) }
        return ""
    }

    @ViewBuilder private var controls: some View {
        if calls.state == .incoming {
            HStack(spacing: 80) {
                RingingButton(icon: "phone.down.fill", color: Theme.danger, label: "Отклонить", answer: false) { calls.endTapped() }
                RingingButton(icon: calls.video ? "video.fill" : "phone.fill", color: Color(hex: 0x2ecc71), label: "Ответить", answer: true) { calls.answerTapped() }
            }
        } else {
            VStack(spacing: 22) {
                HStack(spacing: 22) {
                    roundButton(calls.muted ? "mic.slash.fill" : "mic.fill", color: calls.muted ? .white : Color.white.opacity(0.18),
                                fg: calls.muted ? .black : .white, label: "Микрофон") { calls.toggleMute() }
                    let camOn = calls.localVideo != nil && !calls.camOff
                    roundButton(camOn ? "video.fill" : "video.slash.fill", color: camOn ? Color.white.opacity(0.18) : .white,
                                fg: camOn ? .white : .black, label: "Камера") { calls.toggleCamera() }
                    if camOn {
                        roundButton("arrow.triangle.2.circlepath.camera.fill", color: Color.white.opacity(0.18), label: "Повернуть") { calls.flipCamera() }
                            .transition(.scale.combined(with: .opacity))
                    }
                    roundButton("speaker.wave.2.fill", color: calls.speaker ? .white : Color.white.opacity(0.18),
                                fg: calls.speaker ? .black : .white, label: "Динамик") { calls.toggleSpeaker() }
                }
                roundButton("phone.down.fill", color: Theme.danger, label: "Завершить") { calls.endTapped() }
            }
        }
    }

    private func roundButton(_ icon: String, color: Color, fg: Color = .white, label: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(fg)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(color))
                    .id(icon)
                    .transition(.scale.combined(with: .opacity))
            }
            .buttonStyle(BouncyButtonStyle())
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: icon)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.8))
        }
    }
}

/// Кнопка «пружинит» при нажатии
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Кнопки входящего звонка: «Ответить» подпрыгивает, трубка покачивается, вокруг расходятся волны
struct RingingButton: View {
    let icon: String
    let color: Color
    let label: String
    let answer: Bool
    let action: () -> Void
    @State private var t: Double = 0
    private let tick = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                ZStack {
                    if answer {
                        ForEach(0..<2, id: \.self) { i in
                            let p = (t / 1.6 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                            Circle().stroke(color, lineWidth: 3)
                                .frame(width: 68, height: 68)
                                .scaleEffect(1 + p * 0.8)
                                .opacity(0.7 * (1 - p))
                        }
                    }
                    Circle().fill(color).frame(width: 68, height: 68)
                        .shadow(color: color.opacity(0.6), radius: answer ? 10 + 6 * sin(t * 4) : 4)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(answer ? wiggle : 0))
                }
                .offset(y: answer ? -abs(sin(t * 2.4)) * 7 : 0)
                .scaleEffect(answer ? 1 : 1 + 0.04 * sin(t * 3))
            }
            .buttonStyle(BouncyButtonStyle())
            Text(label).font(.caption).foregroundColor(.white.opacity(0.85))
        }
        .onReceive(tick) { _ in t += 1 / 30 }
    }

    /// Трубка дрожит, как настоящий звонок: короткая серия покачиваний, потом пауза
    private var wiggle: Double {
        let phase = t.truncatingRemainder(dividingBy: 1.4)
        guard phase < 0.6 else { return 0 }
        return sin(phase * 40) * 16 * (1 - phase / 0.6)
    }
}
