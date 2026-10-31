import SwiftUI
import Photos
import UniformTypeIdentifiers

/// Загрузка последних фото и видео из галереи
@MainActor
final class GalleryModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    func load() async {
        var s = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if s == .notDetermined { s = await PHPhotoLibrary.requestAuthorization(for: .readWrite) }
        status = s
        guard s == .authorized || s == .limited else { return }
        let o = PHFetchOptions()
        o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        o.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d",
                                  PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        o.fetchLimit = 500
        let r = PHAsset.fetchAssets(with: o)
        var list: [PHAsset] = []
        r.enumerateObjects { a, _, _ in list.append(a) }
        assets = list
    }
}

enum AttachLoader {
    /// Достаёт данные выбранных фото/видео (в порядке выбора) и готовит части альбома
    static func parts(_ list: [PHAsset], say: @escaping (String) -> Void) async -> [AppModel.AlbumPart] {
        var out: [AppModel.AlbumPart] = []
        for a in list {
            if a.mediaType == .video {
                let res = PHAssetResource.assetResources(for: a)
                guard let r = res.first(where: { $0.type == .fullSizeVideo }) ?? res.first(where: { $0.type == .video }) else { continue }
                var ext = URL(fileURLWithPath: r.originalFilename).pathExtension.lowercased()
                if ext.isEmpty { ext = "mov" }
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + ext)
                let opt = PHAssetResourceRequestOptions()
                opt.isNetworkAccessAllowed = true
                do {
                    try await PHAssetResourceManager.default().writeData(for: r, toFile: tmp, options: opt)
                    let d = try Data(contentsOf: tmp)
                    try? FileManager.default.removeItem(at: tmp)
                    if d.count > 50 * 1024 * 1024 { say("Видео больше 50 МБ пропущено"); continue }
                    let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "video/quicktime"
                    out.append(.init(kind: "video", data: d, ext: ext, mime: mime, meta: ["name": "video." + ext, "size": d.count]))
                } catch { say("Не удалось открыть видео") }
            } else {
                let data: Data? = await withCheckedContinuation { c in
                    let o = PHImageRequestOptions()
                    o.isNetworkAccessAllowed = true
                    o.deliveryMode = .highQualityFormat
                    PHImageManager.default().requestImageDataAndOrientation(for: a, options: o) { d, _, _, _ in c.resume(returning: d) }
                }
                guard let d = data, let img = UIImage(data: d), let res = Media.jpeg(img) else { say("Не удалось открыть фото"); continue }
                out.append(.init(kind: "image", data: res.0, ext: "jpg", mime: "image/jpeg", meta: ["w": res.1, "h": res.2]))
            }
        }
        return out
    }
}

private struct AssetThumb: View {
    let asset: PHAsset
    @State private var img: UIImage?

    var body: some View {
        Color.clear
            .overlay {
                if let i = img { Image(uiImage: i).resizable().scaledToFill() } else { Theme.panel2 }
            }
            .clipped()
            .onAppear {
                guard img == nil else { return }
                let o = PHImageRequestOptions()
                o.deliveryMode = .opportunistic
                o.resizeMode = .fast
                o.isNetworkAccessAllowed = true
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 320, height: 320), contentMode: .aspectFill, options: o) { i, _ in
                    if let i = i { DispatchQueue.main.async { img = i } }
                }
            }
    }
}

/// Шторка «скрепки»: галерея с выбором нескольких фото, подпись и вкладки внизу (как в Telegram)
struct AttachSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let canLumens: Bool
    var onSend: ([AppModel.AlbumPart], String?) -> Void
    var onFile: (URL) -> Void
    /// "camera" · "note" · "lumens"
    var onAction: (String) -> Void
    /// отправка готового сообщения: (вид, текст, ссылка на файл, meta)
    var onPost: (String, String?, String?, JSON) -> Void = { _, _, _, _ in }
    var onData: (Data, String, String) -> Void = { _, _, _ in }

    @StateObject private var gal = GalleryModel()
    @State private var picked: [String] = []
    @State private var caption = ""
    @State private var sending = false
    @State private var importFile = false
    @State private var importAudio = false
    @State private var tab = "Галерея"
    @State private var scanning = false
    @FocusState private var capFocus: Bool

    private let maxPick = 10

    private var tabs: [(String, String)] {
        var t = [("Галерея", "photo.on.rectangle.fill"), ("Файл", "doc.fill"), ("Геопозиция", "location.fill"),
                 ("Опрос", "chart.bar.fill"), ("Звук", "play.circle.fill"), ("Контакт", "person.crop.circle.fill"),
                 ("Камера", "camera.fill"), ("Кружок", "video.circle.fill")]
        if canLumens { t.append(("Люмены", "sparkle")) }
        return t
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(picked.isEmpty ? (tab == "Галерея" ? "Недавние" : tab == "Контакт" ? "Контакты" : tab) : "Выбрано: \(picked.count)").font(.system(size: 19, weight: .bold)).foregroundColor(Theme.text)
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                            .frame(width: 46, height: 46).lumoGlass(Circle(), interactive: true)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            if tab == "Файл" {
                FilesPanel(audio: false, onGallery: { tab = "Галерея" }, onPickFile: { importFile = true }, onScan: { scanning = true },
                           onResend: { resend($0) })
            } else if tab == "Звук" {
                FilesPanel(audio: true, onGallery: { tab = "Галерея" }, onPickFile: { importAudio = true }, onScan: {},
                           onResend: { resend($0) })
            } else if tab == "Геопозиция" {
                LocationPanel(onPick: { t, la, lo in
                    onPost("text", SpecialMsg.locationBody(title: t, lat: la, lng: lo), nil, [:]); dismiss()
                }, onSoon: { model.say($0 + ": в разработке") })
            } else if tab == "Контакт" {
                ContactsPanel(onPick: { p in
                    onPost("text", SpecialMsg.contactBody(name: model.aliases[p.id] ?? p.name, id: p.id), nil, [:]); dismiss()
                })
            } else if gal.status == .denied || gal.status == .restricted {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled").font(.system(size: 44)).foregroundColor(Theme.muted)
                    Text("Нет доступа к фото").font(.headline)
                    Text("Разрешите доступ к галерее в настройках iPhone, чтобы выбирать фото и видео").font(.subheadline)
                        .foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
                    Button("Открыть настройки") { if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) } }
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                        ForEach(gal.assets, id: \.localIdentifier) { a in cell(a) }
                    }
                    Color.clear.frame(height: 120)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .overlay(alignment: .bottom) { bottomBar }
        .task { await gal.load() }
        .presentationDetents([.fraction(0.72), .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $scanning) {
            DocScanner { d in
                scanning = false
                if let d { onData(d, "pdf", "Скан \(Fmt.day(Date())).pdf"); dismiss() }
            }.ignoresSafeArea()
        }
        .fileImporter(isPresented: $importFile, allowedContentTypes: [.item], allowsMultipleSelection: false) { r in
            if case .success(let urls) = r, let u = urls.first { onFile(u); dismiss() }
        }
        .fileImporter(isPresented: $importAudio, allowedContentTypes: [.audio], allowsMultipleSelection: false) { r in
            if case .success(let urls) = r, let u = urls.first { onFile(u); dismiss() }
        }
    }

    private func cell(_ a: PHAsset) -> some View {
        let idx = picked.firstIndex(of: a.localIdentifier)
        return Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { AssetThumb(asset: a) }
            .overlay(alignment: .bottomLeading) {
                if a.mediaType == .video {
                    Text(Fmt.duration(a.duration)).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.45))).padding(6)
                }
            }
            .overlay(alignment: .topTrailing) {
                ZStack {
                    if let i = idx {
                        Circle().fill(Theme.a1)
                        Text("\(i + 1)").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    } else {
                        Circle().fill(Color.black.opacity(0.12))
                    }
                    Circle().stroke(Color.white, lineWidth: 2)
                }
                .frame(width: 28, height: 28).padding(7)
                .shadow(color: .black.opacity(0.25), radius: 2)
            }
            .overlay { if idx != nil { Color.black.opacity(0.18).allowsHitTesting(false) } }
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    if let i = picked.firstIndex(of: a.localIdentifier) { picked.remove(at: i) }
                    else if picked.count >= maxPick { model.say("Можно выбрать до \(maxPick) файлов") }
                    else { picked.append(a.localIdentifier) }
                }
            }
    }

    // MARK: низ: вкладки или подпись + отправка

    @ViewBuilder private var bottomBar: some View {
        if picked.isEmpty || tab != "Галерея" {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs, id: \.0) { t in
                        Button { tap(t.0) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: t.1).font(.system(size: 26)).frame(height: 32)
                                Text(t.0).font(.system(size: 13, weight: .medium)).lineLimit(1)
                            }
                            .foregroundColor(t.0 == tab ? Theme.a1 : Theme.text)
                            .frame(width: 84, height: 62)
                            .background(Capsule().fill(t.0 == tab ? Theme.a1.opacity(0.14) : Color.clear))
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
            }
            .lumoGlass(Capsule())
            .padding(.horizontal, 10).padding(.bottom, 8)
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Добавьте подпись…", text: $caption, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($capFocus)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .lumoGlass(RoundedRectangle(cornerRadius: 24))
                Button { send() } label: {
                    ZStack {
                        if sending { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.up").font(.system(size: 18, weight: .heavy)).foregroundColor(.white) }
                    }
                    .frame(width: 48, height: 48).background(Circle().fill(Theme.accent))
                    .overlay(alignment: .topTrailing) {
                        Text("\(picked.count)").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 5).frame(minWidth: 18, minHeight: 18)
                            .background(Capsule().fill(Theme.a1)).overlay(Capsule().stroke(Theme.bg, lineWidth: 2))
                            .offset(x: 4, y: -4)
                    }
                }
                .disabled(sending)
            }
            .padding(.horizontal, 10).padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func tap(_ t: String) {
        switch t {
        case "Галерея", "Файл", "Звук", "Геопозиция", "Контакт": picked = []; tab = t
        case "Опрос": model.say("Опрос: в разработке")
        case "Камера": close(); after { onAction("camera") }
        case "Кружок": close(); after { onAction("note") }
        case "Люмены": close(); after { onAction("lumens") }
        default: break
        }
    }

    private func resend(_ m: Message) {
        onPost("file", nil, m.mediaURL, m.meta); dismiss()
    }

    private func close() { dismiss() }
    private func after(_ f: @escaping () -> Void) { DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: f) }

    private func send() {
        let chosen = picked.compactMap { id in gal.assets.first { $0.localIdentifier == id } }
        let cap = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        sending = true
        Task {
            let parts = await AttachLoader.parts(chosen) { model.say($0) }
            sending = false
            guard !parts.isEmpty else { return }
            onSend(parts, cap.isEmpty ? nil : cap)
            dismiss()
        }
    }
}
