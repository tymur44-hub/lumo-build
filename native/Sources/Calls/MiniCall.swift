import SwiftUI
import WebRTC

extension CallManager {
    /// Свернуть экран звонка внутри приложения: разговор продолжается, сверху — плашка или окошко с видео
    func minimize() {
        guard state != .idle, state != .incoming else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showUI = false
    }
    func expand() {
        guard state != .idle else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showUI = true
    }
}

/// Свёрнутый звонок: аудио — плашка сверху, видео — плавающее окошко (можно перетаскивать к любому углу)
struct MiniCallOverlay: View {
    @EnvironmentObject var calls: CallManager
    @State private var now = Date()
    @State private var corner: Int = 1          // 0 — слева сверху, 1 — справа сверху, 2 — слева снизу, 3 — справа снизу
    @State private var drag: CGSize = .zero
    @State private var pressed = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var visible: Bool { calls.state != .idle && calls.state != .incoming && !calls.showUI }
    private var line: String {
        if !calls.statusText.isEmpty { return calls.statusText }
        if let s = calls.startedAt { return Fmt.duration(now.timeIntervalSince(s)) }
        return "Соединение…"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if visible {
                    if calls.video { videoWindow(geo) } else { audioBar.frame(maxHeight: .infinity, alignment: .top) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: visible)
        .onReceive(tick) { now = $0 }
    }

    // MARK: аудио — плашка сверху

    private var audioBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.22)).frame(width: 34, height: 34)
                Image(systemName: "phone.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(calls.peerName).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                Text(line).font(.system(size: 12, weight: .semibold).monospacedDigit()).foregroundColor(.white.opacity(0.85))
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 6)
            Button { calls.toggleMute() } label: {
                Image(systemName: calls.muted ? "mic.slash.fill" : "mic.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(width: 34, height: 34).background(Circle().fill(Color.white.opacity(calls.muted ? 0.4 : 0.18)))
            }.buttonStyle(BouncyButtonStyle())
            Button { calls.endTapped() } label: {
                Image(systemName: "phone.down.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(width: 34, height: 34).background(Circle().fill(Theme.danger))
            }.buttonStyle(BouncyButtonStyle())
        }
        .padding(.leading, 8).padding(.trailing, 6).padding(.vertical, 6)
        .background(LinearGradient(colors: [Color(hex: 0x22c55e), Color(hex: 0x16a34a)], startPoint: .leading, endPoint: .trailing), in: Capsule())
        .shadow(color: Color(hex: 0x16a34a).opacity(0.45), radius: 14, y: 6)
        .scaleEffect(pressed ? 0.96 : 1)
        .padding(.horizontal, 14).padding(.top, 4)
        .contentShape(Capsule())
        .onTapGesture { grow() }
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.6, anchor: .top)),
                                removal: .scale(scale: 1.4, anchor: .top).combined(with: .opacity)))
    }

    // MARK: видео — окошко

    private func videoWindow(_ geo: GeometryProxy) -> some View {
        let w: CGFloat = 118, h: CGFloat = 170, m: CGFloat = 12
        let left = corner % 2 == 0, top = corner < 2
        let x = left ? m + w / 2 : geo.size.width - m - w / 2
        let y = top ? geo.safeAreaInsets.top + 60 + h / 2 : geo.size.height - geo.safeAreaInsets.bottom - 100 - h / 2
        return ZStack(alignment: .bottom) {
            Color.black
            if let t = calls.remoteVideo, !calls.peerCamOff, calls.p2p || calls.reconnecting {
                RTCVideoView(track: t, fill: true)
            } else if let im = calls.relayImage, !calls.peerCamOff {
                Image(uiImage: im).resizable().scaledToFill()
            } else {
                AvatarView(name: calls.peerName, url: calls.peerAvatar, color: calls.peerColor, size: 64)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            PiPAnchor().frame(width: 2, height: 2).opacity(0.01).allowsHitTesting(false)
            Text(line).font(.system(size: 11, weight: .bold).monospacedDigit()).foregroundColor(.white)
                .padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(Color.black.opacity(0.45)))
                .padding(.bottom, 6)
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
        .scaleEffect(pressed ? 0.95 : 1)
        .position(x: x + drag.width, y: y + drag.height)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { drag = $0.translation }
                .onEnded { v in
                    let px = x + v.predictedEndTranslation.width, py = y + v.predictedEndTranslation.height
                    let l = px < geo.size.width / 2, t = py < geo.size.height / 2
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        corner = (t ? 0 : 2) + (l ? 0 : 1)
                        drag = .zero
                    }
                }
        )
        .onTapGesture { grow() }
        .onAppear { CallPiP.shared.setTrack(calls.remoteVideo) }
        .transition(.asymmetric(insertion: .scale(scale: 0.3, anchor: corner % 2 == 0 ? .topLeading : .topTrailing).combined(with: .opacity),
                                removal: .scale(scale: 2.2).combined(with: .opacity)))
    }

    /// нажали на свёрнутый звонок — окошко слегка «вдавливается» и плавно разворачивается в полный экран
    private func grow() {
        withAnimation(.easeOut(duration: 0.12)) { pressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { pressed = false }
            calls.expand()
        }
    }
}
