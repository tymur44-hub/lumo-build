import SwiftUI
import AVKit
import UniformTypeIdentifiers

// MARK: - Палитра тёмных экранов историй (как в Telegram)

enum StoryUI {
    static let bg = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let panel = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let line = Color.white.opacity(0.08)
    static let sub = Color.white.opacity(0.55)
    static let blue = Color(hex: 0x2f8cff)
}

/// Кадр из видео для превью публикации
enum StoryThumb {
    static func make(_ url: URL) async -> Data? {
        let g = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        g.appliesPreferredTrackTransform = true
        g.maximumSize = CGSize(width: 540, height: 960)
        let t = CMTime(seconds: 0.1, preferredTimescale: 600)
        guard let cg = try? g.copyCGImage(at: t, actualTime: nil) else { return nil }
        return UIImage(cgImage: cg).jpegData(compressionQuality: 0.72)
    }
}

// MARK: - «Поделиться историей»: кто видит, снимки экрана, публикация в профиле

struct StoryShareSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    /// all / contacts / close / only
    @Binding var choice: String
    @Binding var excl: Set<String>
    @Binding var sel: Set<String>
    @Binding var pinned: Bool
    @Binding var shots: Bool
    @Binding var hours: Int
    let busy: Bool
    let publish: () -> Void

    private enum Pick: String, Identifiable { case excl, only, close; var id: String { rawValue } }
    @State private var pick: Pick?
    @State private var close: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // аккаунт
                    HStack(spacing: 12) {
                        AvatarView(name: model.me?.name ?? "", url: model.me?.avatarURL, color: model.me?.color ?? 0, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Text(model.me?.name ?? "").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                if model.me?.premium == true {
                                    if let e = model.me?.emojiStatus, !e.isEmpty { StatusEmojiView(s: e, size: 16) }
                                    else { Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(StoryUI.blue) }
                                }
                            }
                            Text("личный аккаунт").font(.system(size: 13)).foregroundColor(StoryUI.sub)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(StoryUI.panel, in: RoundedRectangle(cornerRadius: 14))

                    Text("КТО ВИДИТ ЭТУ ИСТОРИЮ").font(.system(size: 12.5, weight: .medium)).foregroundColor(StoryUI.sub).padding(.leading, 14).padding(.top, 6)
                    VStack(spacing: 0) {
                        row("all", "megaphone.fill", Color(hex: 0x2f8cff), "Все", excl.isEmpty || choice != "all" ? "добавить исключения" : "кроме \(excl.count) чел.") { pick = .excl }
                        Divider().overlay(StoryUI.line).padding(.leading, 96)
                        row("contacts", "person.fill", Color(hex: 0x9b5cff), "Мои контакты", excl.isEmpty || choice != "contacts" ? "добавить исключения" : "кроме \(excl.count) чел.") { pick = .excl }
                        Divider().overlay(StoryUI.line).padding(.leading, 96)
                        row("close", "star.fill", Color(hex: 0x34c759), "Близкие друзья", close.isEmpty ? "выбрать" : "\(close.count) чел. · изменить") { pick = .close }
                        Divider().overlay(StoryUI.line).padding(.leading, 96)
                        row("only", "person.2.fill", Color(hex: 0xff9500), "Выбранные пользователи", sel.isEmpty ? "выбрать" : "\(sel.count) чел. · изменить") { pick = .only }
                    }
                    .background(StoryUI.panel, in: RoundedRectangle(cornerRadius: 14))
                    Text("Выберите пользователей, которые не будут видеть Вашу историю.")
                        .font(.system(size: 12.5)).foregroundColor(StoryUI.sub).padding(.horizontal, 14)

                    VStack(spacing: 0) {
                        Toggle(isOn: $shots) { Text("Разрешить снимки экрана").foregroundColor(.white) }
                            .padding(.horizontal, 14).frame(height: 50)
                        Divider().overlay(StoryUI.line).padding(.leading, 14)
                        Toggle(isOn: $pinned) { Text("Опубликовать в моём профиле").foregroundColor(.white) }
                            .padding(.horizontal, 14).frame(height: 50)
                    }
                    .tint(Color(hex: 0x34c759))
                    .background(StoryUI.panel, in: RoundedRectangle(cornerRadius: 14))
                    Text("История в профиле останется после 24 часов. Её смогут увидеть только те, кого Вы выбрали выше.")
                        .font(.system(size: 12.5)).foregroundColor(StoryUI.sub).padding(.horizontal, 14)

                    HStack {
                        Text("Срок").foregroundColor(.white)
                        Spacer()
                        Menu {
                            Button("24 часа") { hours = 24 }
                            Button("48 часов · Premium") { setHours(48) }
                            Button("3 дня · Premium") { setHours(72) }
                            Button("7 дней · Premium") { setHours(168) }
                        } label: {
                            HStack(spacing: 4) {
                                Text(hoursText).foregroundColor(StoryUI.blue)
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(StoryUI.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 14).frame(height: 50)
                    .background(StoryUI.panel, in: RoundedRectangle(cornerRadius: 14))
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16).padding(.top, 6)
            }
            .background(StoryUI.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    publish()
                } label: {
                    StoryPublishBar(busy: busy, progress: model.storyUpload)
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(busy || (choice == "only" && sel.isEmpty))
                .opacity(choice == "only" && sel.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 16).padding(.bottom, 8).padding(.top, 8)
                .background(StoryUI.bg.opacity(0.96).ignoresSafeArea())
            }
            .navigationTitle("Поделиться историей")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            .frame(width: 34, height: 34).background(Circle().fill(Color.white.opacity(0.12)))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { close = await model.closeFriends() }
        .sheet(item: $pick, onDismiss: {}) { p in
            switch p {
            case .excl: AudiencePicker(title: "Скрыть от", sel: $excl).environmentObject(model)
            case .only: AudiencePicker(title: "Кто увидит", sel: $sel).environmentObject(model)
            case .close:
                AudiencePicker(title: "Близкие друзья", sel: $close).environmentObject(model)
                    .onDisappear { let c = close; Task { await model.setCloseFriends(c) } }
            }
        }
    }

    private var hoursText: String {
        switch hours { case 48: return "48 часов"; case 72: return "3 дня"; case 168: return "7 дней"; default: return "24 часа" }
    }

    private func setHours(_ h: Int) {
        if model.isPremium { hours = h } else { model.say(premiumSoon) }
    }

    private func row(_ key: String, _ icon: String, _ tint: Color, _ title: String, _ sub: String, _ subTap: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: choice == key ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22)).foregroundColor(choice == key ? StoryUI.blue : Color.white.opacity(0.3))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: choice)
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                .frame(width: 38, height: 38).background(Circle().fill(tint))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(.white)
                Button(action: subTap) {
                    HStack(spacing: 2) {
                        Text(sub).font(.system(size: 13))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(StoryUI.blue)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation { choice = key }
            if key == "only" && sel.isEmpty { pick = .only }
            if key == "close" && close.isEmpty { pick = .close }
        }
    }
}

// MARK: - Архив историй / опубликованные в профиле

struct StoryArchiveView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    /// true — только закреплённые в профиле
    let postsOnly: Bool
    @State private var items: [ProfilePost] = []
    @State private var loaded = false
    @State private var open: ProfilePost?

    var body: some View {
        NavigationStack {
            ScrollView {
                if loaded && items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: postsOnly ? "square.grid.3x3" : "archivebox").font(.system(size: 42)).foregroundColor(Theme.muted)
                        Text(postsOnly ? "Нет опубликованных историй" : "Архив пуст").font(.headline).foregroundColor(Theme.text)
                        Text(postsOnly ? "Включите «Опубликовать в моём профиле» при публикации — история останется в профиле." : "Здесь хранятся все ваши истории, даже после 24 часов. Их видите только вы.")
                            .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
                    }
                    .padding(.top, 80)
                } else if !loaded {
                    ProgressView().padding(60)
                } else {
                    PostsGrid(items: items, showPin: !postsOnly) { open = $0 }
                        .padding(.horizontal, 2)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(postsOnly ? "Опубликованные истории" : "Архив историй")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .task { await reload() }
            .fullScreenCover(item: $open, onDismiss: { Task { await reload() } }) { p in
                PostViewer(post: p, mine: true).environmentObject(model)
            }
        }
    }

    private func reload() async {
        items = postsOnly ? await model.profilePosts(model.myId ?? "") : await model.storyArchive()
        loaded = true
    }
}

/// Сетка публикаций 3 в ряд, вертикальные карточки
struct PostsGrid: View {
    let items: [ProfilePost]
    var showPin = false
    let tap: (ProfilePost) -> Void
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
            ForEach(items) { p in
                Button { tap(p) } label: {
                    Color.black
                        .aspectRatio(9 / 16, contentMode: .fit)
                        .overlay {
                            if let s = p.preview, let u = URL(string: s) {
                                CachedImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color(white: 0.15) }
                            } else {
                                Image(systemName: "play.rectangle").font(.system(size: 26)).foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .clipped()
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: 4) {
                                if p.kind == "video" { Image(systemName: "play.fill") }
                                if p.views > 0 { Image(systemName: "eye"); Text("\(p.views)") }
                            }
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            .shadow(radius: 2).padding(6)
                        }
                        .overlay(alignment: .topTrailing) {
                            if showPin && p.pinned {
                                Image(systemName: "pin.fill").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                    .padding(5).background(Circle().fill(Color.black.opacity(0.45))).padding(5)
                            }
                        }
                }
                .buttonStyle(RowButtonStyle())
            }
        }
    }
}

/// Просмотр одной публикации из профиля или архива
struct PostViewer: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let post: ProfilePost
    let mine: Bool
    @State private var player: AVPlayer?
    @State private var pinned = false
    @State private var dragY: CGFloat = 0
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Group {
                if post.kind == "video", let p = player { PlayerLayerView(player: p, fill: false) }
                else if let u = URL(string: post.mediaURL) {
                    CachedImage(url: u) { img in img.resizable().scaledToFit() } placeholder: { ProgressView().tint(.white) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                HStack {
                    Text(Fmt.clock(post.createdAt)).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    Spacer()
                    if mine {
                        Menu {
                            Button { Task { await model.setStoryPinned(post.id, !pinned); pinned.toggle() } } label: {
                                Label(pinned ? "Убрать из профиля" : "Опубликовать в профиле", systemImage: pinned ? "pin.slash" : "pin")
                            }
                            Button(role: .destructive) { confirmDelete = true } label: { Label("Удалить", systemImage: "trash") }
                        } label: {
                            Image(systemName: "ellipsis").font(.headline).foregroundColor(.white).frame(width: 40, height: 40)
                        }
                    }
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).foregroundColor(.white).frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 10).padding(.top, 8)
                Spacer()
                if !post.caption.isEmpty {
                    Text(post.caption).font(.system(size: 16)).foregroundColor(.white).multilineTextAlignment(.center)
                        .padding(16).frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                }
            }
        }
        .offset(y: dragY)
        .gesture(DragGesture().onChanged { v in dragY = max(0, v.translation.height) }
            .onEnded { v in
                if v.translation.height > 90 || v.predictedEndTranslation.height > 260 { dismiss() }
                else { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { dragY = 0 } }
            })
        .onAppear {
            pinned = post.pinned
            if post.kind == "video", let u = URL(string: post.mediaURL) {
                let p = AVPlayer(url: u.px); player = p; p.play()
            }
        }
        .onDisappear { player?.pause() }
        .confirmationDialog("Удалить эту историю навсегда?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                Task { _ = try? await API.shared.rpc("lm_story_delete", ["p_id": post.id]); await model.loadStories(); await model.loadMe(); dismiss() }
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Вкладки профиля «Публикации / Подарки»

struct ProfileTabs: View {
    @EnvironmentObject var model: AppModel
    let userId: String
    var gifts = true
    @State private var tab = 0
    @State private var posts: [ProfilePost] = []
    @State private var loaded = false
    @State private var open: ProfilePost?
    @Namespace private var ns

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 2) {
                tabButton(0, "Публикации")
                if gifts { tabButton(1, "Подарки") }
            }
            .padding(4)
            .background(Capsule().fill(Theme.panel2))
            .padding(.horizontal, 14)
            Group {
                if tab == 0 {
                    if !loaded {
                        ProgressView().frame(height: 120)
                    } else if posts.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "square.grid.3x3").font(.system(size: 30)).foregroundColor(Theme.muted)
                            Text(userId == model.myId ? "Опубликуйте историю в профиле — она останется здесь" : "Пока нет публикаций")
                                .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 26)
                    } else {
                        PostsGrid(items: posts) { open = $0 }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 14)
                    }
                } else {
                    ProfileGiftsRow(userId: userId).padding(.horizontal, 14)
                }
            }
            .transition(.opacity)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: tab)
        .task(id: userId) { posts = await model.profilePosts(userId); loaded = true }
        .fullScreenCover(item: $open, onDismiss: { Task { posts = await model.profilePosts(userId) } }) { p in
            PostViewer(post: p, mine: userId == model.myId).environmentObject(model)
        }
    }

    private func tabButton(_ i: Int, _ t: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { tab = i }
        } label: {
            Text(t).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                .frame(maxWidth: .infinity).frame(height: 36)
                .background { if tab == i { Capsule().fill(Theme.panel).shadow(color: .black.opacity(0.08), radius: 3, y: 1).matchedGeometryEffect(id: "ptab", in: ns) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Музыка профиля

final class ProfileMusicPlayer: ObservableObject {
    static let shared = ProfileMusicPlayer()
    @Published var playing: String?
    private var player: AVPlayer?
    private var obs: Any?

    func toggle(_ url: String) {
        if playing == url { player?.pause(); playing = nil; return }
        guard let u = URL(string: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        let p = AVPlayer(url: u.px)
        if let o = obs { NotificationCenter.default.removeObserver(o) }
        obs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: .main) { [weak self] _ in self?.playing = nil }
        player?.pause()
        player = p
        p.play()
        playing = url
    }

    func stop() { player?.pause(); playing = nil }
}

struct ProfileMusicRow: View {
    let url: String
    let title: String
    let artist: String
    var light = false
    @ObservedObject private var mp = ProfileMusicPlayer.shared
    @State private var wave = false

    var body: some View {
        let on = mp.playing == url
        Button { mp.toggle(url) } label: {
            HStack(spacing: 10) {
                Image(systemName: on ? "pause.fill" : "play.fill").font(.system(size: 14, weight: .bold))
                    .foregroundColor(light ? .black : .white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(light ? Color.white : Theme.a1))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title.isEmpty ? "Без названия" : title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    if !artist.isEmpty { Text(artist).font(.system(size: 13)).opacity(0.75).lineLimit(1) }
                }
                .foregroundColor(light ? .white : Theme.text)
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule().frame(width: 3, height: on && wave ? CGFloat([14, 8, 16, 10][i]) : 5)
                            .animation(on ? .easeInOut(duration: 0.4 + Double(i) * 0.08).repeatForever(autoreverses: true) : .default, value: wave)
                    }
                }
                .foregroundColor(light ? .white.opacity(0.85) : Theme.a1)
                .frame(height: 18)
                Image(systemName: "music.note").font(.system(size: 13, weight: .semibold))
                    .foregroundColor(light ? .white.opacity(0.7) : Theme.muted)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 16).fill(light ? Color.white.opacity(0.18) : Theme.panel))
        }
        .buttonStyle(BouncyButtonStyle())
        .onChange(of: on) { v in wave = v }
        .onAppear { wave = on }
    }
}

/// Строка в редактировании профиля: выбрать трек для профиля
struct ProfileMusicEditRow: View {
    @EnvironmentObject var model: AppModel
    @State private var importing = false
    @State private var busy = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                .frame(width: 30, height: 30).background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xff2d55)))
            VStack(alignment: .leading, spacing: 1) {
                Text("Музыка профиля").foregroundColor(Theme.text)
                Text(model.me?.musicURL == nil ? "Не выбрана" : (model.me?.musicTitle ?? "")).font(.footnote).foregroundColor(Theme.muted).lineLimit(1)
            }
            Spacer()
            if busy { ProgressView() }
            else if model.me?.musicURL != nil {
                Button { Task { busy = true; _ = await model.setProfileMusic(data: nil); busy = false } } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { importing = true }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.audio, .mp3, .mpeg4Audio]) { r in
            guard case .success(let u) = r else { return }
            Task { await upload(u) }
        }
    }

    private func upload(_ u: URL) async {
        let ok = u.startAccessingSecurityScopedResource()
        defer { if ok { u.stopAccessingSecurityScopedResource() } }
        guard let d = try? Data(contentsOf: u) else { model.say("Не удалось открыть файл"); return }
        if d.count > 15 * 1024 * 1024 { model.say("Файл больше 15 МБ"); return }
        busy = true
        let asset = AVURLAsset(url: u)
        var title = u.deletingPathExtension().lastPathComponent
        var artist = ""
        if let meta = try? await asset.load(.commonMetadata) {
            for m in meta {
                if m.commonKey == .commonKeyTitle, let v = try? await m.load(.stringValue), !v.isEmpty { title = v }
                if m.commonKey == .commonKeyArtist, let v = try? await m.load(.stringValue), !v.isEmpty { artist = v }
            }
        }
        let dur = (try? await asset.load(.duration))?.seconds ?? 0
        let ext = u.pathExtension.lowercased()
        _ = await model.setProfileMusic(data: d, ext: ["m4a", "wav", "mp3"].contains(ext) ? ext : "mp3", title: title, artist: artist, dur: dur.isFinite ? dur : 0)
        busy = false
    }
}


/// Кнопка публикации: во время загрузки заливается слева направо, показывает проценты и сколько осталось
struct StoryPublishBar: View {
    let busy: Bool
    let progress: Double?
    @State private var shimmer = false

    var body: some View {
        let p = min(1, max(0, progress ?? (busy ? 1 : 0)))
        let done = busy && (progress == nil || p >= 0.95)
        ZStack(alignment: .leading) {
            Capsule().fill(busy ? StoryUI.blue.opacity(0.35) : StoryUI.blue)
            if busy {
                GeometryReader { g in
                    Capsule().fill(StoryUI.blue)
                        .frame(width: max(52, g.size.width * p))
                        .overlay(
                            LinearGradient(colors: [.clear, .white.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 80).offset(x: shimmer ? g.size.width : -80)
                                .mask(Capsule())
                        )
                        .clipShape(Capsule())
                        .animation(.easeOut(duration: 0.25), value: p)
                }
            }
            HStack(spacing: 8) {
                if busy {
                    if done { ProgressView().tint(.white).scaleEffect(0.85) }
                    Text(done ? "Публикуем…" : "Загрузка \(Int(p * 100 / 0.95))%")
                        .font(.system(size: 17, weight: .semibold)).monospacedDigit()
                } else {
                    Text("Опубликовать историю").font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 52)
        .clipShape(Capsule())
        .onAppear { withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { shimmer = true } }
    }
}
