import SwiftUI
import UIKit

struct IdentifiedURL: Identifiable {
    let id = UUID()
    let url: URL
}

/// Текст со ссылками, @упоминаниями и простым **жирным** / *курсивом* (как на сайте)
func richText(_ s: String, cmds: Bool = false) -> AttributedString {
    var a = (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    let plain = String(a.characters)
    let ns = plain as NSString
    if let det = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
        for m in det.matches(in: plain, range: NSRange(location: 0, length: ns.length)) {
            guard let url = m.url, let r = Range<AttributedString.Index>(m.range, in: a) else { continue }
            a[r].link = url
            a[r].underlineStyle = .single
        }
    }
    if let re = try? NSRegularExpression(pattern: "(?<![\\w@])@([a-zA-Z0-9_]{3,32})") {
        for m in re.matches(in: plain, range: NSRange(location: 0, length: ns.length)) {
            let name = ns.substring(with: m.range(at: 1))
            guard let r = Range<AttributedString.Index>(m.range, in: a), let u = URL(string: "lumo://user/" + name) else { continue }
            a[r].link = u
            a[r].inlinePresentationIntent = .stronglyEmphasized
        }
    }
    if cmds, let re = try? NSRegularExpression(pattern: "(?<![\\w/])/([A-Za-z][A-Za-z0-9_]{1,31})") {
        for m in re.matches(in: plain, range: NSRange(location: 0, length: ns.length)) {
            let name = ns.substring(with: m.range(at: 1))
            guard let r = Range<AttributedString.Index>(m.range, in: a), let u = URL(string: "lumo://cmd/" + name) else { continue }
            a[r].link = u
            a[r].underlineStyle = nil
            a[r].inlinePresentationIntent = .stronglyEmphasized
        }
    }
    return a
}

func isOnlyEmoji(_ t: String?) -> Bool {
    guard let s = t?.trimmingCharacters(in: .whitespaces), !s.isEmpty, s.count <= 6 else { return false }
    return s.unicodeScalars.allSatisfy { $0.properties.isEmojiPresentation || $0.properties.isEmoji && $0.value > 0x238C || $0.value == 0x200D || $0.value == 0xFE0F || $0 == " " }
}

struct DayLabel: View {
    let date: Date
    var body: some View {
        Text(Fmt.day(date))
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
}

/// Одна строка ленты: сообщение с учётом группировки (как на сайте: «хвостик» у последнего, аватар в группах)
struct MessageRow: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var look: Appearance
    @ObservedObject private var ex = ExtraStore.shared
    let m: Message
    let chat: ChatItem?
    let first: Bool
    let last: Bool
    var onReply: (Message) -> Void
    var onEdit: (Message) -> Void
    var onForward: (Message) -> Void
    var onImage: (URL) -> Void
    var onVideo: (URL) -> Void
    var onReport: (Message) -> Void
    var onMenu: (Message) -> Void = { _ in }
    var swipeEnabled = true
    /// Режим выбора нескольких сообщений
    var selecting = false
    var isSelected = false
    var onToggle: (Message) -> Void = { _ in }
    @State private var swipe: CGFloat = 0
    @State private var swipeHit = false
    @State private var swipeActive = false
    @State private var noteText: String?

    private var mine: Bool { m.senderId == model.myId }
    private var isGroup: Bool { chat?.type == "group" }
    private var senderName: String { model.displayName(m.senderId) }
    private var senderColor: Color { Theme.nameColor(m.senderId.flatMap { model.profiles[$0]?.color } ?? 0) }
    static let quick = ["❤️", "👍", "😂", "😮", "😢", "🔥", "👏", "🎉"]

    var body: some View {
        if m.kind == "system" {
            Text(m.body ?? "")
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundColor(Theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        } else {
            HStack(alignment: .bottom, spacing: 6) {
                if selecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 23))
                        .foregroundStyle(isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.muted))
                        .frame(width: 28)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                if mine { Spacer(minLength: 44) }
                if isGroup && !mine {
                    if last {
                        AvatarView(name: senderName, url: m.senderId.flatMap { model.profiles[$0]?.avatarURL },
                                   color: m.senderId.flatMap { model.profiles[$0]?.color } ?? 0, size: 34)
                    } else {
                        Color.clear.frame(width: 34, height: 1)
                    }
                }
                VStack(alignment: mine ? .trailing : .leading, spacing: 3) {
                    content
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { Task { await model.react(m, "❤️") } }
                        .onLongPressGesture(minimumDuration: 0.35) {
                            guard !selecting, !m.deleted, m.id > 0 else { return }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onMenu(m)
                        }
                    reactionsRow
                    botButtons
                }
                if !mine { Spacer(minLength: 44) }
            }
            .offset(x: swipe)
            .overlay(alignment: .trailing) {
                if swipe < 0 {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(swipeHit ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color.black.opacity(0.3))))
                        .scaleEffect(min(1, -swipe / 60))
                        .opacity(min(1, -swipe / 40))
                        .padding(.trailing, 4)
                }
            }
            .simultaneousGesture(swipeGesture)
            .overlay {
                // в режиме выбора нажатие по строке отмечает сообщение
                if selecting {
                    Color.clear.contentShape(Rectangle())
                        .onTapGesture { if !m.deleted && m.id > 0 { onToggle(m) } }
                }
            }
            .background(isSelected ? Theme.a1.opacity(0.12) : Color.clear)
            .animation(.easeOut(duration: 0.18), value: selecting)
            .padding(.top, first ? 6 : 0)
        }
    }

    /// Свайп влево по сообщению — ответить
    private var canSwipe: Bool { swipeEnabled && !selecting && !m.deleted && m.id > 0 && (chat?.canPost ?? true) }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { v in
                guard canSwipe else { return }
                let dx = v.translation.width, dy = v.translation.height
                if !swipeActive {
                    // начинаем только при явно горизонтальном движении влево, чтобы не мешать прокрутке
                    guard dx < -12, abs(dx) > abs(dy) * 1.6 else { return }
                    swipeActive = true
                }
                let raw = min(0, dx)
                let shown = raw > -70 ? raw : -70 + (raw + 70) * 0.25
                swipe = shown
                let hit = raw <= -60
                if hit != swipeHit {
                    swipeHit = hit
                    if hit { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                }
            }
            .onEnded { _ in
                guard swipeActive else { return }
                if swipeHit { onReply(m) }
                swipeActive = false
                swipeHit = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { swipe = 0 }
            }
    }

    // MARK: реакции под сообщением

    @ViewBuilder private var botButtons: some View {
        let rows = m.buttons
        if !rows.isEmpty && !m.deleted {
            VStack(spacing: 5) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 5) {
                        ForEach(row, id: \.self) { b in
                            Button { model.botPress(m, b) } label: {
                                Text(b.text).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                                    .foregroundColor(Theme.a1).frame(maxWidth: .infinity).padding(.vertical, 9).padding(.horizontal, 8)
                                    .background(Theme.muted.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(minWidth: 220)
        }
    }

    @ViewBuilder private var reactionsRow: some View {
        let list = model.reactions[m.id] ?? []
        if !list.isEmpty {
            let groups = Dictionary(grouping: list, by: { $0.emoji }).sorted { $0.value.count > $1.value.count }
            HStack(spacing: 4) {
                ForEach(groups, id: \.key) { e, rs in
                    let meIn = rs.contains { $0.userId == model.myId }
                    Button { Task { await model.react(m, e) } } label: {
                        HStack(spacing: 3) {
                            Text(e).font(.system(size: 14))
                            Text("\(rs.count)").font(.system(size: 12.5, weight: .bold)).foregroundColor(meIn ? .white : Theme.text)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(meIn ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.panel2)))
                        .overlay(Capsule().stroke(Theme.line))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: содержимое

    @ViewBuilder private var content: some View {
        if m.deleted {
            bubble {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("Сообщение удалено").italic().foregroundColor(Theme.muted)
                    timeLine(onMedia: false).offset(y: 2)
                }
            }
        } else if m.kind == "sticker" || (m.kind == "text" && isOnlyEmoji(m.body) && m.replyTo == nil && m.forwardedFrom == nil) {
            VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
                if m.kind == "sticker", m.meta["anim"] != nil { AnimatedEmoji(emoji: m.body ?? "", size: 96, tappable: true) }
                else { Text(m.body ?? "").font(.system(size: m.kind == "sticker" ? 84 : 52)) }
                timeLine(onMedia: true)
            }
        } else if m.kind == "video_note" {
            VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 8) {
                    if let u = m.mediaURL.flatMap(URL.init(string:)) { VideoNoteView(url: u) }
                    else { ZStack { Circle().fill(Theme.panel2); ProgressView() }.frame(width: 210, height: 210) }
                    TranscribeButton(m: m, mine: false, ext: "mp4", text: $noteText)
                }
                if let t = noteText {
                    Text(t).font(.system(size: 15)).foregroundColor(Theme.text).padding(10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.panel2)).frame(maxWidth: 260, alignment: .leading)
                }
                timeLine(onMedia: true)
            }
        } else {
            bubble {
                VStack(alignment: .leading, spacing: 4) {
                    if first && !mine && isGroup {
                        Text(senderName).font(.system(size: 13.5, weight: .heavy)).foregroundColor(senderColor)
                    }
                    if let f = m.forwardedFrom, !f.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "arrowshape.turn.up.right.fill").font(.caption2)
                            Text("Переслано от " + f).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(mine ? .white.opacity(0.8) : Theme.a2)
                    }
                    if let st = m.meta["story"] as? JSON, let u = st.str("url"), let url = URL(string: u) {
                        HStack(spacing: 8) {
                            if st.str("kind") == "video" { Image(systemName: "play.rectangle.fill").font(.title2) }
                            else {
                                CachedImage(url: url) { $0.resizable().scaledToFill() } placeholder: { Color.white.opacity(0.1) }
                                    .frame(width: 36, height: 52).clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            Text("История").font(.caption.weight(.bold))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }
                    if let r = m.replyTo { replyQuote(r) }
                    if let b = m.body, !b.isEmpty, m.kind != "call" {
                        media
                        // время — в одной строке с концом текста (как на сайте), без лишней строки снизу
                        (Text(richText(b, cmds: !mine && (m.senderId.flatMap { model.profiles[$0]?.isBot } ?? false))).foregroundColor(mine ? .white : Theme.text)
                         + Text(timeReserve).font(.system(size: 11.5)).foregroundColor(.clear))
                            .font(.system(size: look.fontSize))
                            .tint(mine ? .white : Theme.a2)
                            .fixedSize(horizontal: false, vertical: true)
                            .overlay(alignment: .bottomTrailing) { timeLine(onMedia: false).offset(y: 2) }
                    } else if m.kind == "image" || m.kind == "video" {
                        media.overlay(alignment: .bottomTrailing) {
                            timeLine(onMedia: false)
                                .foregroundColor(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                                .padding(6)
                        }
                    } else if m.kind == "voice" {
                        // у голосового время на отдельной строке справа, чтобы не налезало на кнопку расшифровки
                        VStack(alignment: .trailing, spacing: 0) {
                            media
                            timeLine(onMedia: false).padding(.top, -6)
                        }
                    } else {
                        HStack(alignment: .bottom, spacing: 8) {
                            media
                            timeLine(onMedia: false).offset(y: 2)
                        }
                    }
                }
            }
        }
    }

    private func bubble<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        let big: CGFloat = 18, small: CGFloat = 8, tail: CGFloat = 6
        let shape: BubbleShape = mine
            ? BubbleShape(tl: big, tr: first ? big : small, bl: big, br: last ? tail : small)
            : BubbleShape(tl: first ? big : small, tr: big, bl: last ? tail : small, br: big)
        return c()
            .padding(.horizontal, 11).padding(.top, 6).padding(.bottom, 6)
            .background(
                Group {
                    if mine { shape.fill(ex.bubFill(m.chatId)) } else { shape.fill(Theme.bubble) }
                }
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
            )
            .opacity(m.pending ? 0.7 : 1)
            .frame(maxWidth: min(UIScreen.main.bounds.width * 0.78, 560), alignment: mine ? .trailing : .leading)
    }

    /// Невидимый «запас» под время в конце текста
    private var timeReserve: String {
        "\u{2002}" + (m.editedAt != nil ? "изм. " : "") + Fmt.clock(m.createdAt) + (mine ? "\u{2002}\u{2002}" : "")
    }

    private func timeLine(onMedia: Bool) -> some View {
        HStack(spacing: 3) {
            if m.editedAt != nil { Text("изм.").font(.system(size: 11)) }
            Text(Fmt.clock(m.createdAt)).font(.system(size: 11.5))
            if mine {
                if m.pending { Image(systemName: "clock").font(.system(size: 10)) }
                else {
                    let read = (chat?.othersReadAt ?? .distantPast) >= m.createdAt
                    Image(systemName: read ? "checkmark.circle.fill" : "checkmark").font(.system(size: 10.5, weight: .bold))
                }
            }
        }
        .foregroundColor(onMedia ? Theme.muted : (mine ? .white.opacity(0.72) : Theme.muted))
        .padding(onMedia ? .horizontal : [], 6)
    }

    @ViewBuilder private func replyQuote(_ id: Int) -> some View {
        let r = model.findMessage(id, in: m.chatId)
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(mine ? Color.white : Theme.a2).frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(r.map { model.displayName($0.senderId) } ?? "Сообщение")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(mine ? .white : Theme.a2)
                Text(r?.preview ?? "Сообщение недоступно").font(.system(size: 13)).lineLimit(1)
                    .foregroundColor(mine ? .white.opacity(0.8) : Theme.muted)
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(mine ? Color.white.opacity(0.14) : Theme.a2.opacity(0.1)))
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var media: some View {
        switch m.kind {
        case "image":
            if let u = m.mediaURL.flatMap(URL.init(string:)) {
                let w: CGFloat = 250
                let ratio = (m.width ?? 1) > 0 ? CGFloat((m.height ?? 1) / (m.width ?? 1)) : 1
                let h = min(340, max(120, w * ratio))
                CachedImage(url: u) { img in img.resizable().scaledToFill() } placeholder: {
                    ZStack { Color.white.opacity(0.06); ProgressView() }
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .onTapGesture { onImage(u) }
            } else {
                ZStack { Color.white.opacity(0.06); ProgressView() }.frame(width: 250, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
        case "video":
            if let u = m.mediaURL.flatMap(URL.init(string:)) {
                VideoThumb(url: u).onTapGesture { onVideo(u) }
            } else {
                ZStack { Color.white.opacity(0.06); ProgressView() }.frame(width: 250, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
        case "voice":
            VoiceView(m: m, mine: mine)
        case "file":
            Button {
                if let u = m.mediaURL.flatMap(URL.init(string:)) { UIApplication.shared.open(u) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.fill").font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(mine ? Color.white.opacity(0.2) : Theme.a1))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.fileName).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                        if let s = m.fileSize { Text(Fmt.size(s)).font(.caption).opacity(0.7) }
                    }
                    .foregroundColor(mine ? .white : Theme.text)
                }
            }
            .disabled(m.mediaURL == nil)
        case "call":
            let st = m.metaStatus ?? ""
            let missed = st == "missed" || st == "rejected"
            HStack(spacing: 10) {
                Image(systemName: m.isVideoCall ? "video.fill" : "phone.fill")
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(missed ? Theme.danger.opacity(0.85) : (mine ? Color.white.opacity(0.2) : Theme.a1)))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(callTitle(st)).font(.system(size: 15, weight: .semibold))
                    if st == "ended" { Text(Fmt.duration(m.duration)).font(.caption).opacity(0.75) }
                }
                .foregroundColor(mine ? .white : Theme.text)
            }
        default:
            EmptyView()
        }
    }

    private func callTitle(_ st: String) -> String {
        let v = m.isVideoCall ? " видеозвонок" : " звонок"
        if mine { return (st == "ended" ? "Исходящий" : st == "rejected" ? "Отклонённый" : "Отменённый") + v }
        return (st == "ended" ? "Входящий" : st == "rejected" ? "Отклонённый" : "Пропущенный") + v
    }
}
