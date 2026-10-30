import SwiftUI
import AVKit
import PhotosUI

/// Кольцо вокруг аватара истории (цветное — есть новые)
struct StoryRing: View {
    let unseen: Bool
    let mine: Bool
    var body: some View {
        Circle().strokeBorder(
            unseen || mine
                ? AnyShapeStyle(AngularGradient(colors: mine ? [Theme.a1, Theme.a2, Theme.a1] : [Color(hex: 0xff9f1a), Color(hex: 0xff3b8a), Theme.a1, Theme.a2, Color(hex: 0xff9f1a)], center: .center))
                : AnyShapeStyle(Theme.line),
            lineWidth: 3)
    }
}

struct StoriesBar: View {
    @EnvironmentObject var model: AppModel
    let open: (String) -> Void
    let add: () -> Void

    var body: some View {
        let mine = model.stories.first { $0.userId == model.myId }
        let others = model.stories.filter { $0.userId != model.myId }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                VStack(spacing: 5) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(name: model.me?.name ?? "", url: model.me?.avatarURL, color: model.me?.color ?? 0, size: 56)
                            .padding(3)
                            .overlay(Group { if mine != nil { StoryRing(unseen: false, mine: true) } })
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .heavy)).foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Theme.a1))
                            .overlay(Circle().stroke(Theme.bg, lineWidth: 2.5))
                            .onTapGesture { add() }
                    }
                    Text("Моя история").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                }
                .frame(width: 70)
                .onTapGesture { if mine != nil { open(model.myId ?? "") } else { add() } }

                ForEach(others) { g in
                    VStack(spacing: 5) {
                        AvatarView(name: g.name, url: g.avatarURL, color: g.color, size: 56)
                            .padding(3)
                            .overlay(StoryRing(unseen: g.unseen, mine: false))
                        Text(g.name.split(separator: " ").first.map(String.init) ?? g.name)
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    }
                    .frame(width: 70)
                    .onTapGesture { open(g.userId) }
                }
            }
            .padding(.horizontal, 6).padding(.top, 4).padding(.bottom, 10)
        }
    }
}

/// Просмотр историй: полоски сверху, касание слева/справа — назад/вперёд, удержание — пауза, вниз — закрыть
struct StoryViewer: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let startUser: String

    @State private var gi = 0
    @State private var ii = 0
    @State private var progress: Double = 0
    @State private var paused = false
    @State private var reply = ""
    @State private var player: AVPlayer?
    @State private var loaded = false
    @State private var dragY: CGFloat = 0
    @State private var viewers: ViewersList?
    @State private var confirmDelete = false
    @FocusState private var replyFocused: Bool
    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var groups: [StoryGroup] { model.stories }
    private var group: StoryGroup? { groups.indices.contains(gi) ? groups[gi] : nil }
    private var item: StoryItem? { group.flatMap { $0.items.indices.contains(ii) ? $0.items[ii] : nil } }
    private var mine: Bool { group?.userId == model.myId }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let s = item {
                media(s)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            paused = true
                            if v.translation.height > 0 && v.translation.height > abs(v.translation.width) { dragY = v.translation.height }
                        }
                        .onEnded { v in
                            paused = false
                            if v.translation.height > 120 { dismiss(); return }
                            dragY = 0
                            if abs(v.translation.width) > 70 && abs(v.translation.width) > abs(v.translation.height) {
                                v.translation.width < 0 ? nextGroup() : prevGroup()
                            } else if abs(v.translation.width) < 12 && abs(v.translation.height) < 12 {
                                if v.location.x < UIScreen.main.bounds.width / 3 { prev() } else { next() }
                            }
                        })
                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        ForEach(Array((group?.items ?? []).enumerated()), id: \.offset) { k, _ in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.3))
                                    Capsule().fill(Color.white)
                                        .frame(width: geo.size.width * CGFloat(k < ii ? 1 : k == ii ? progress : 0))
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                    HStack(spacing: 10) {
                        AvatarView(name: group?.name ?? "", url: group?.avatarURL, color: group?.color ?? 0, size: 38)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(mine ? "Моя история" : (group?.name ?? "")).font(.subheadline.weight(.bold)).foregroundColor(.white)
                            Text(ago(s.createdAt)).font(.caption).foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                        if mine {
                            Button { paused = true; confirmDelete = true } label: {
                                Image(systemName: "trash").foregroundColor(.white).frame(width: 40, height: 40)
                            }
                        }
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.headline).foregroundColor(.white).frame(width: 40, height: 40)
                        }
                    }
                    Spacer()
                    if !s.caption.isEmpty {
                        Text(s.caption).font(.system(size: 16)).foregroundColor(.white).multilineTextAlignment(.center)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                    }
                    footer(s)
                }
                .padding(.horizontal, 10).padding(.top, 8)
            }
        }
        .offset(y: dragY)
        .scaleEffect(1 - min(0.15, dragY / 1500))
        .onAppear {
            gi = groups.firstIndex { $0.userId == startUser } ?? 0
            if let g = group, g.userId != model.myId { ii = g.items.firstIndex { !$0.seen } ?? 0 }
            show()
        }
        .onReceive(tick) { _ in step() }
        .onDisappear { player?.pause(); player = nil }
        .sheet(item: $viewers, onDismiss: { paused = false }) { v in
            ViewersSheet(rows: v.rows)
        }
        .confirmationDialog("Удалить эту историю?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                if let s = item { Task { await model.deleteStory(s); if model.stories.first(where: { $0.userId == model.myId }) == nil { dismiss() } else { ii = 0; show() } } }
            }
            Button("Отмена", role: .cancel) { paused = false }
        }
        .statusBarHidden(true)
    }

    @ViewBuilder private func media(_ s: StoryItem) -> some View {
        if s.kind == "video", let p = player {
            PlayerLayerView(player: p, fill: false)
        } else if let u = URL(string: s.mediaURL) {
            CachedImage(url: u) { img in img.resizable().scaledToFit() } placeholder: { ProgressView().tint(.white) }
        }
    }

    @ViewBuilder private func footer(_ s: StoryItem) -> some View {
        HStack(spacing: 8) {
            if mine {
                Button {
                    paused = true
                    Task { viewers = ViewersList(rows: await model.storyViewers(s)) }
                } label: {
                    Label("\(s.views) просмотров", systemImage: "eye").font(.subheadline.weight(.bold)).foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 10).background(Capsule().fill(Color.white.opacity(0.15)))
                }
                Spacer()
            } else {
                TextField("Ответить…", text: $reply)
                    .focused($replyFocused)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).frame(height: 44)
                    .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                    .onChange(of: replyFocused) { f in paused = f }
                    .onSubmit { sendReply(s) }
                Button { Task { await model.reactStory(s) } } label: {
                    Image(systemName: "heart.fill").font(.title3).foregroundColor(Color(hex: 0xff3b5c)).frame(width: 44, height: 44)
                }
                if !reply.isEmpty {
                    Button { sendReply(s) } label: {
                        Image(systemName: "arrow.up").font(.headline).foregroundColor(.white).frame(width: 44, height: 44)
                            .background(Circle().fill(Theme.accent))
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func sendReply(_ s: StoryItem) {
        let t = reply.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        reply = ""
        replyFocused = false
        Task { await model.replyStory(s, text: t) }
    }

    private func ago(_ d: Date) -> String {
        let m = Int(Date().timeIntervalSince(d) / 60)
        if m < 1 { return "только что" }
        if m < 60 { return "\(m) мин назад" }
        return "\(m / 60) ч назад"
    }

    private func show() {
        progress = 0
        loaded = false
        player?.pause()
        player = nil
        guard let s = item else { return }
        model.viewStory(s)
        if s.kind == "video", let u = URL(string: s.mediaURL) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            let p = AVPlayer(url: u.px)
            player = p
            p.play()
        }
        loaded = true
    }

    private func step() {
        guard loaded, !paused, let s = item else {
            if paused { player?.pause() }
            return
        }
        if s.kind == "video", let p = player {
            if p.timeControlStatus != .playing && p.currentItem?.status == .readyToPlay { p.play() }
            let d = p.currentItem?.duration.seconds ?? 0
            if d.isFinite && d > 0 {
                progress = min(1, p.currentTime().seconds / d)
                if progress >= 0.999 { next() }
            }
        } else {
            progress += 0.05 / 5
            if progress >= 1 { next() }
        }
    }

    private func next() {
        guard let g = group else { dismiss(); return }
        if ii < g.items.count - 1 { ii += 1; show() } else { nextGroup() }
    }

    private func prev() {
        if ii > 0 { ii -= 1; show() } else if gi > 0 { gi -= 1; ii = 0; show() } else { progress = 0; player?.seek(to: .zero) }
    }

    private func nextGroup() {
        if gi < groups.count - 1 {
            gi += 1
            let g = groups[gi]
            ii = g.userId == model.myId ? 0 : (g.items.firstIndex { !$0.seen } ?? 0)
            show()
        } else { dismiss() }
    }

    private func prevGroup() {
        if gi > 0 { gi -= 1; ii = 0; show() }
    }
}

struct ViewersList: Identifiable {
    let id = UUID()
    let rows: [JSON]
}

struct ViewersSheet: View {
    let rows: [JSON]
    var body: some View {
        NavigationStack {
            List {
                if rows.isEmpty {
                    Text("Пока никто не посмотрел").foregroundColor(Theme.muted)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, v in
                    HStack(spacing: 12) {
                        AvatarView(name: v.str("name") ?? "", url: v.str("avatar_url"), color: v.int("color") ?? 0, size: 40)
                        VStack(alignment: .leading) {
                            Text(v.str("name") ?? "").font(.headline)
                            Text(Fmt.clock(v.date("viewed_at"))).font(.caption).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        if let r = v.str("reaction") { Text(r).font(.title3) }
                    }
                    .listRowBackground(Theme.panel2)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Просмотры")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

/// Новая история: фото или видео до 60 секунд, подпись
struct AddStoryView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var pick: PhotosPickerItem?
    @State private var data: Data?
    @State private var image: UIImage?
    @State private var videoURL: URL?
    @State private var isVideo = false
    @State private var caption = ""
    @State private var hours = 24
    @State private var aud = "all"
    @State private var allow: Set<String> = []
    @State private var pickAud = false
    @State private var busy = false
    @State private var duration: Double = 0
    @StateObject private var cam = StoryCam()
    @State private var videoMode = false
    @State private var grid = false
    @State private var secs = 0

    var body: some View {
        Group {
            if data == nil { cameraView } else { editorView }
        }
        .onChange(of: pick) { item in
            guard let item = item else { return }
            Task { await load(item) }
        }
    }

    // MARK: камера (ФОТО / ВИДЕО, сетка, вспышка, галерея, переворот)

    private func circleBtn(_ icon: String, on: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(on ? .black : .white)
                .frame(width: 46, height: 46).background(Circle().fill(on ? Color.white : Color.black.opacity(0.35)))
        }
    }

    private var cameraView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(Color(white: 0.1))
                    CameraPreview(session: cam.session).clipShape(RoundedRectangle(cornerRadius: 28))
                    if grid {
                        Canvas { ctx, sz in
                            var p = Path()
                            for i in 1...2 {
                                let x = sz.width * CGFloat(i) / 3, y = sz.height * CGFloat(i) / 3
                                p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: sz.height))
                                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: sz.width, y: y))
                            }
                            ctx.stroke(p, with: .color(.white.opacity(0.45)), lineWidth: 1)
                        }
                        .allowsHitTesting(false)
                    }
                    VStack {
                        HStack(spacing: 10) {
                            if cam.recording {
                                Text(String(format: "%d:%02d", secs / 60, secs % 60)).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                                    .padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(Color.red))
                            }
                            Spacer()
                            circleBtn("grid", on: grid) { grid.toggle() }
                            circleBtn(cam.flash ? "bolt.fill" : "bolt.slash.fill", on: cam.flash) { cam.flash.toggle(); cam.applyTorch(video: videoMode) }
                            circleBtn("xmark") { cam.stop(); dismiss() }
                        }
                        .padding(12)
                        Spacer()
                    }
                }
                .padding(.top, 4)
                VStack(spacing: 14) {
                    Button { shoot() } label: {
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.55), lineWidth: 4).frame(width: 78, height: 78)
                            Circle().fill(videoMode ? Color.red : Color.white).frame(width: 64, height: 64)
                            if cam.recording { RoundedRectangle(cornerRadius: 5).fill(Color.white).frame(width: 24, height: 24) }
                        }
                    }
                    HStack {
                        PhotosPicker(selection: $pick, matching: .any(of: [.images, .videos])) {
                            Image(systemName: "photo.on.rectangle").font(.system(size: 22)).foregroundColor(.white)
                                .frame(width: 54, height: 54).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.18)))
                        }
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach([(true, "ВИДЕО"), (false, "ФОТО")], id: \.1) { m in
                                Text(m.1).font(.system(size: 15, weight: .bold)).foregroundColor(videoMode == m.0 ? Color(hex: 0xffd60a) : .white)
                                    .padding(.horizontal, 22).padding(.vertical, 12)
                                    .background(Capsule().fill(videoMode == m.0 ? Color.white.opacity(0.18) : Color.clear))
                                    .onTapGesture { if !cam.recording { videoMode = m.0; cam.applyTorch(video: m.0) } }
                            }
                        }
                        .padding(4).background(Capsule().fill(Color.white.opacity(0.16)))
                        Spacer()
                        Button { if !cam.recording { cam.flip() } } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera").font(.system(size: 22)).foregroundColor(.white)
                                .frame(width: 54, height: 54).background(Circle().fill(Color.white.opacity(0.18)))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
        }
        .task {
            cam.onPhoto = { d in
                if let img = UIImage(data: d), let res = Media.jpeg(img) { image = img; data = res.0; isVideo = false }
            }
            cam.onVideo = { u in Task { await ingestVideo(u) } }
            await cam.start()
        }
        .task(id: cam.recording) {
            secs = 0
            while cam.recording { try? await Task.sleep(nanoseconds: 1_000_000_000); if cam.recording { secs += 1 } }
        }
        .onDisappear { cam.stop() }
        .preferredColorScheme(.dark)
    }

    private func shoot() {
        if videoMode { cam.recording ? cam.stopRecording() : cam.startRecording() }
        else { cam.takePhoto() }
    }

    private func ingestVideo(_ u: URL) async {
        let asset = AVURLAsset(url: u.px)
        let dur = (try? await asset.load(.duration))?.seconds ?? 0
        guard let d = try? Data(contentsOf: u) else { model.say("Не удалось открыть видео"); return }
        if d.count > 60 * 1024 * 1024 { model.say("Видео слишком большое (до 60 МБ)"); return }
        isVideo = true; duration = dur; videoURL = u; data = d
    }

    // MARK: подготовка и публикация

    private var editorView: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Color.black)
                    if let i = image { Image(uiImage: i).resizable().scaledToFit() }
                    else if let v = videoURL { VideoPlayer(player: AVPlayer(url: v.px)) }
                    else {
                        PhotosPicker(selection: $pick, matching: .any(of: [.images, .videos])) {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled").font(.system(size: 40))
                                Text("Выбрать фото или видео").font(.headline)
                            }
                            .foregroundColor(Theme.text)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(maxHeight: 420)
                TextField("Подпись (необязательно)", text: $caption).lumoField()
                Picker("Срок", selection: $hours) {
                    Text("24 ч").tag(24); Text("48 ч ★").tag(48); Text("3 дня ★").tag(72); Text("7 дней ★").tag(168)
                }
                .pickerStyle(.segmented)
                .onChange(of: hours) { h in if h > 24 && !model.isPremium { hours = 24; model.say(premiumSoon) } }
                VStack(spacing: 6) {
                    Text("Кто увидит историю").font(.footnote).foregroundColor(Theme.muted)
                    Picker("Кто увидит", selection: $aud) {
                        Text("Все").tag("all"); Text("Контакты").tag("contacts"); Text("Выбранные").tag("only"); Text("Кроме…").tag("except")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: aud) { a in if a == "only" || a == "except" { pickAud = true } }
                    Text(audHint).font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                        .onTapGesture { if aud == "only" || aud == "except" { pickAud = true } }
                }
                .sheet(isPresented: $pickAud) { AudiencePicker(title: aud == "only" ? "Кто увидит" : "Скрыть от", sel: $allow).environmentObject(model) }
                GradientButton(title: "Опубликовать", loading: busy) { publish() }
                    .disabled(data == nil)
                    .opacity(data == nil ? 0.5 : 1)
                Spacer()
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Новая история")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Назад") { data = nil; image = nil; videoURL = nil; pick = nil; isVideo = false } } }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
        guard let d = try? await item.loadTransferable(type: Data.self) else { model.say("Не удалось открыть файл"); return }
        if isVideo {
            if d.count > 60 * 1024 * 1024 { model.say("Видео слишком большое (до 60 МБ)"); return }
            let u = FileManager.default.temporaryDirectory.appendingPathComponent("story-\(randomId()).mov")
            try? d.write(to: u)
            let asset = AVURLAsset(url: u.px)
            let dur = (try? await asset.load(.duration))?.seconds ?? 0
            if dur > 61 { model.say("Видео для истории — не длиннее 60 секунд"); return }
            duration = dur
            videoURL = u
            data = d
        } else if let img = UIImage(data: d), let res = Media.jpeg(img) {
            image = img
            data = res.0
        }
    }

    private var audHint: String {
        switch aud {
        case "contacts": return "Только люди из ваших контактов"
        case "only": return allow.isEmpty ? "Выберите, кто увидит историю" : "Увидят \(allow.count) чел. · нажмите, чтобы изменить"
        case "except": return allow.isEmpty ? "Выберите, от кого скрыть" : "Скрыто от \(allow.count) чел. · нажмите, чтобы изменить"
        default: return "Контакты и те, с кем у вас есть переписка"
        }
    }

    private func publish() {
        guard let d = data else { return }
        busy = true
        Task {
            let ok = await model.addStory(kind: isVideo ? "video" : "image", data: d, ext: isVideo ? "mov" : "jpg",
                                          contentType: isVideo ? "video/quicktime" : "image/jpeg",
                                          caption: caption, meta: isVideo ? ["dur": duration] : [:], hours: hours, aud: aud, allow: Array(allow))
            busy = false
            if ok { dismiss() }
        }
    }
}

/// Камера для историй: фото и видео, вспышка, переворот
final class StoryCam: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let photoOut = AVCapturePhotoOutput()
    private let movieOut = AVCaptureMovieFileOutput()
    private var position: AVCaptureDevice.Position = .back
    private var device: AVCaptureDevice?
    private var started = false
    @Published var flash = false
    @Published var recording = false
    var onPhoto: ((Data) -> Void)?
    var onVideo: ((URL) -> Void)?

    func start() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }
        _ = await AVCaptureDevice.requestAccess(for: .audio)
        configure()
        if !started {
            started = true
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        } else if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        }
    }

    func stop() {
        if recording { movieOut.stopRecording() }
        applyTorchOff()
        DispatchQueue.global(qos: .userInitiated).async { if self.session.isRunning { self.session.stopRunning() } }
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .high
        for i in session.inputs { session.removeInput(i) }
        if let d = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position), let inp = try? AVCaptureDeviceInput(device: d), session.canAddInput(inp) {
            session.addInput(inp); device = d
        }
        if let a = AVCaptureDevice.default(for: .audio), let inp = try? AVCaptureDeviceInput(device: a), session.canAddInput(inp) { session.addInput(inp) }
        if !session.outputs.contains(photoOut), session.canAddOutput(photoOut) { session.addOutput(photoOut) }
        if !session.outputs.contains(movieOut), session.canAddOutput(movieOut) {
            movieOut.maxRecordedDuration = CMTime(seconds: 60, preferredTimescale: 600)
            session.addOutput(movieOut)
        }
        session.commitConfiguration()
        for o in [photoOut as AVCaptureOutput, movieOut as AVCaptureOutput] {
            if let c = o.connection(with: .video), c.isVideoOrientationSupported { c.videoOrientation = .portrait }
            if let c = o.connection(with: .video), c.isVideoMirroringSupported { c.automaticallyAdjustsVideoMirroring = false; c.isVideoMirrored = position == .front }
        }
    }

    func flip() {
        position = position == .back ? .front : .back
        applyTorchOff()
        configure()
    }

    func applyTorch(video: Bool) {
        guard let d = device, d.hasTorch, position == .back else { return }
        try? d.lockForConfiguration()
        d.torchMode = (flash && video) ? .on : .off
        d.unlockForConfiguration()
    }
    private func applyTorchOff() {
        guard let d = device, d.hasTorch else { return }
        try? d.lockForConfiguration(); d.torchMode = .off; d.unlockForConfiguration()
    }

    func takePhoto() {
        let s = AVCapturePhotoSettings()
        if photoOut.supportedFlashModes.contains(flash ? .on : .off) { s.flashMode = flash ? .on : .off }
        photoOut.capturePhoto(with: s, delegate: self)
    }

    func startRecording() {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("story-cam-\(UUID().uuidString).mov")
        movieOut.startRecording(to: u, recordingDelegate: self)
        DispatchQueue.main.async { self.recording = true }
    }
    func stopRecording() { movieOut.stopRecording() }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let d = photo.fileDataRepresentation() else { return }
        DispatchQueue.main.async { self.onPhoto?(d) }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.recording = false
            self.applyTorchOff()
            self.onVideo?(outputFileURL)
        }
    }
}


/// Выбор людей из контактов для аудитории истории
struct AudiencePicker: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var sel: Set<String>
    var body: some View {
        NavigationStack {
            List {
                if model.contacts.isEmpty { Text("В контактах пока никого").foregroundColor(Theme.muted) }
                ForEach(model.contacts, id: \.self) { id in
                    Button {
                        if sel.contains(id) { sel.remove(id) } else { sel.insert(id) }
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: model.displayName(id), url: model.profiles[id]?.avatarURL, color: model.profiles[id]?.color ?? 0, size: 40)
                            Text(model.displayName(id)).foregroundColor(Theme.text)
                            Spacer()
                            Image(systemName: sel.contains(id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(sel.contains(id) ? Theme.a1 : Theme.muted)
                                .scaleEffect(sel.contains(id) ? 1.15 : 1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: sel)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
        }
    }
}
