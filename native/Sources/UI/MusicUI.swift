import SwiftUI

/// Анимированный эквалайзер (три «пляшущие» полоски) — значок играющей музыки
struct EqualizerIcon: View {
    var color: Color = .white
    var animating: Bool = true
    @State private var phase = false
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                Capsule().fill(color)
                    .frame(width: 2.5, height: animating ? (phase ? [11, 6, 9][i] : [5, 10, 4][i]) : 7)
                    .animation(animating ? .easeInOut(duration: 0.42).repeatForever().delay(Double(i) * 0.12) : .default, value: phase)
            }
        }
        .frame(height: 14)
        .onAppear { phase = true }
    }
}

/// Плашка «играет музыка» — показывается сверху списка чатов и под именем в чате
struct MiniPlayerBar: View {
    @ObservedObject var audio = AudioManager.shared
    var compact = false
    @State private var showPlayer = false

    var body: some View {
        if let t = audio.track {
            Button { showPlayer = true } label: {
                HStack(spacing: 11) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(LinearGradient(colors: [Theme.a1, Theme.a2], startPoint: .topLeading, endPoint: .bottomTrailing))
                        EqualizerIcon(animating: audio.playing)
                    }
                    .frame(width: compact ? 30 : 36, height: compact ? 30 : 36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(t.title).font(.system(size: compact ? 13 : 14, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                        Text(audio.playing ? t.artist : "На паузе").font(.system(size: compact ? 11 : 12)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Button { audio.toggle() } label: {
                        Image(systemName: audio.playing ? "pause.fill" : "play.fill").font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.a1).frame(width: 34, height: 34).contentShape(Rectangle())
                    }
                    .buttonStyle(BouncyButtonStyle())
                    Button { audio.next() } label: {
                        Image(systemName: "forward.fill").font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.muted).frame(width: 30, height: 34).contentShape(Rectangle())
                    }
                    .buttonStyle(BouncyButtonStyle())
                    if !compact {
                        Button { audio.stop() } label: {
                            Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                                .frame(width: 28, height: 34).contentShape(Rectangle())
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 14).fill(Theme.panel)
                        GeometryReader { g in
                            RoundedRectangle(cornerRadius: 2).fill(Theme.a1.opacity(0.7))
                                .frame(width: g.size.width * audio.progress, height: 2.5)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 0.5))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPlayer) { PlayerSheet().presentationDetents([.large]) }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

/// Полноэкранный плеер
struct PlayerSheet: View {
    @ObservedObject var audio = AudioManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var scrub: Double?

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Theme.line).frame(width: 40, height: 5).padding(.top, 8)
            if let t = audio.track {
                Spacer(minLength: 10)
                // обложка
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [Theme.a1, Theme.a2], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Theme.a1.opacity(0.4), radius: 24, y: 12)
                    Image(systemName: "music.note").font(.system(size: 72, weight: .light)).foregroundColor(.white.opacity(0.9))
                    VStack { Spacer(); EqualizerIcon(color: .white, animating: audio.playing).scaleEffect(2).padding(.bottom, 28) }
                }
                .frame(width: 240, height: 240)
                .scaleEffect(audio.playing ? 1 : 0.92)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: audio.playing)

                Text(t.title).font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text).lineLimit(1).padding(.top, 28).padding(.horizontal, 30)
                Text(t.artist).font(.system(size: 15)).foregroundColor(Theme.muted).padding(.top, 2)

                // перемотка
                VStack(spacing: 4) {
                    Slider(value: Binding(
                        get: { scrub ?? audio.progress },
                        set: { scrub = $0 }
                    ), in: 0...1, onEditingChanged: { editing in
                        if !editing, let s = scrub { audio.seek(toFraction: s); scrub = nil }
                    })
                    .tint(Theme.a1)
                    HStack {
                        Text(fmt((scrub ?? audio.progress) * audio.duration)).font(.system(size: 12)).foregroundColor(Theme.muted)
                        Spacer()
                        Text(fmt(audio.duration)).font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 34).padding(.top, 24)

                // кнопки
                HStack(spacing: 40) {
                    Button { audio.prev() } label: { Image(systemName: "backward.fill").font(.system(size: 26)) }
                        .buttonStyle(BouncyButtonStyle())
                    Button { audio.toggle() } label: {
                        Image(systemName: audio.playing ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 68))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    Button { audio.next() } label: { Image(systemName: "forward.fill").font(.system(size: 26)) }
                        .buttonStyle(BouncyButtonStyle())
                }
                .foregroundColor(Theme.a1)
                .padding(.top, 18)

                // очередь из этого чата
                if audio.queue.count > 1 {
                    Text("Из этого чата").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).padding(.top, 20)
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(audio.queue) { q in
                                Button { audio.playTrack(q) } label: {
                                    HStack(spacing: 10) {
                                        if q.id == t.id { EqualizerIcon(color: Theme.a1, animating: audio.playing).frame(width: 20) }
                                        else { Image(systemName: "music.note").font(.system(size: 13)).foregroundColor(Theme.muted).frame(width: 20) }
                                        Text(q.title).font(.system(size: 14, weight: q.id == t.id ? .semibold : .regular)).foregroundColor(q.id == t.id ? Theme.a1 : Theme.text).lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24).padding(.vertical, 9).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else { Spacer() }
            } else {
                Spacer(); Text("Ничего не играет").foregroundColor(Theme.muted); Spacer()
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }
    private func fmt(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "0:00" }
        let t = Int(s); return String(format: "%d:%02d", t / 60, t % 60)
    }
}

/// Пузырь аудиофайла в чате — играет через общий плеер
struct AudioBubbleView: View {
    let m: Message
    let mine: Bool
    @ObservedObject private var audio = AudioManager.shared

    private var isCurrent: Bool { audio.track?.id == m.id }
    private var title: String { (m.fileName as NSString).deletingPathExtension }

    var body: some View {
        Button {
            if isCurrent { audio.toggle() }
            else { audio.play(m, in: AppModel.shared.messages[m.chatId] ?? [m]) }
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    Circle().fill(mine ? Color.white.opacity(0.22) : Theme.a1)
                    Image(systemName: (isCurrent && audio.playing) ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(mine ? .white : .white)
                        .offset(x: (isCurrent && audio.playing) ? 0 : 1)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .semibold)).lineLimit(1).foregroundColor(mine ? .white : Theme.text)
                    if isCurrent {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill((mine ? Color.white : Theme.a1).opacity(0.25)).frame(height: 3)
                                Capsule().fill(mine ? Color.white : Theme.a1).frame(width: g.size.width * audio.progress, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                    HStack(spacing: 6) {
                        if isCurrent { EqualizerIcon(color: mine ? .white : Theme.a1, animating: audio.playing).frame(width: 16) }
                        if let s = m.fileSize { Text(Fmt.size(s)).font(.caption).opacity(0.7).foregroundColor(mine ? .white : Theme.text) }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 180)
    }
}
