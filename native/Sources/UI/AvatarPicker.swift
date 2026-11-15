import SwiftUI
import Photos

/// Выбор фото профиля: сетка галереи (как при отправке), выбор области, видео, удаление.
struct AvatarPickerSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gallery = GalleryModel()
    @State private var cropItem: CropItem?
    @State private var trimVideo: IdentifiedURL?
    @State private var confirmDelete = false

    private let cols = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        NavigationStack {
            content
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Фото профиля").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                if model.me?.avatarURL != nil {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Удалить фотографию", systemImage: "trash")
                            .font(.system(size: 16, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 50)
                            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.danger)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 8)
                }
            }
            .fullScreenCover(item: $cropItem) { it in
                NavigationStack {
                    AvatarCropView(asset: it.asset) { img in
                        Task { try? await model.setAvatar(img); dismiss() }
                    }
                }
            }
            .sheet(item: $trimVideo) { v in VideoAvatarTrimSheet(source: v.url) { trimVideo = nil; dismiss() }.environmentObject(model) }
            .confirmationDialog("Удалить фото профиля?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) { Task { try? await model.setAvatar(nil); dismiss() } }
            }
            .task { await gallery.load() }
        }
    }

    @ViewBuilder private var content: some View {
        if gallery.status == .authorized || gallery.status == .limited { grid } else { noAccess }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(gallery.assets, id: \.localIdentifier) { a in
                    cell(a)
                }
            }
            .padding(2)
        }
    }

    private func cell(_ a: PHAsset) -> some View {
        Button { pick(a) } label: {
            AvatarAssetThumb(asset: a)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottomTrailing) {
                    if a.mediaType == .video {
                        Image(systemName: "video.fill").font(.system(size: 11)).foregroundColor(.white).padding(4).shadow(radius: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var noAccess: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 44)).foregroundColor(Theme.muted)
            Text("Нет доступа к галерее").font(.headline)
            Button("Открыть настройки") { if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) } }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pick(_ a: PHAsset) {
        if a.mediaType == .video {
            let res = PHAssetResource.assetResources(for: a)
            guard let r = res.first(where: { $0.type == .fullSizeVideo }) ?? res.first(where: { $0.type == .video }) else { return }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            let opt = PHAssetResourceRequestOptions(); opt.isNetworkAccessAllowed = true
            Task {
                try? await PHAssetResourceManager.default().writeData(for: r, toFile: tmp, options: opt)
                await MainActor.run { trimVideo = IdentifiedURL(url: tmp) }
            }
        } else {
            cropItem = CropItem(asset: a)
        }
    }
}

/// Миниатюра ассета
struct AvatarAssetThumb: View {
    let asset: PHAsset
    @State private var img: UIImage?
    var body: some View {
        ZStack {
            Color.black.opacity(0.05)
            if let i = img { Image(uiImage: i).resizable().scaledToFill() }
        }
        .task {
            let o = PHImageRequestOptions(); o.deliveryMode = .opportunistic; o.isNetworkAccessAllowed = true; o.resizeMode = .fast
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: o) { i, _ in
                if let i = i { img = i }
            }
        }
    }
}

/// Выбор видимой области: двигаем и масштабируем, галочка — готово
struct AvatarCropView: View {
    let asset: PHAsset
    var onDone: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var full: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var busy = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) - 40
            ZStack {
                Color.black.ignoresSafeArea()
                if let img = full {
                    let base = max(side / img.size.width, side / img.size.height)
                    let ds = base * scale
                    Image(uiImage: img).resizable().scaledToFit()
                        .frame(width: img.size.width * ds, height: img.size.height * ds)
                        .offset(offset)
                        .frame(width: side, height: side)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { v in scale = max(1, min(4, lastScale * v)) }
                                    .onEnded { _ in lastScale = scale; clamp(img: img, side: side) },
                                DragGesture()
                                    .onChanged { v in offset = CGSize(width: lastOffset.width + v.translation.width, height: lastOffset.height + v.translation.height) }
                                    .onEnded { _ in clamp(img: img, side: side); lastOffset = offset }
                            )
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView().tint(.white)
                }
                VStack {
                    Spacer()
                    Text("Двигайте и масштабируйте").foregroundColor(.white.opacity(0.8)).font(.footnote).padding(.bottom, 8)
                }
            }
            .task { await loadFull() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(.white) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { confirm(side: side) } label: { Image(systemName: "checkmark").font(.system(size: 17, weight: .bold)) }
                        .disabled(full == nil || busy)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func clamp(img: UIImage, side: CGFloat) {
        let base = max(side / img.size.width, side / img.size.height)
        let ds = base * scale
        let w = img.size.width * ds, h = img.size.height * ds
        let maxX = max(0, (w - side) / 2), maxY = max(0, (h - side) / 2)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            offset.width = min(maxX, max(-maxX, offset.width))
            offset.height = min(maxY, max(-maxY, offset.height))
        }
    }

    private func confirm(side: CGFloat) {
        guard let img = normalized(full) else { return }
        busy = true
        let base = max(side / img.size.width, side / img.size.height)
        let ds = base * scale
        let w = img.size.width * ds, h = img.size.height * ds
        // верхний левый угол видимого квадрата в координатах картинки
        let originX = ((w - side) / 2 - offset.width) / ds
        let originY = ((h - side) / 2 - offset.height) / ds
        let cropSide = side / ds
        let rect = CGRect(x: max(0, originX), y: max(0, originY),
                          width: min(cropSide, img.size.width), height: min(cropSide, img.size.height))
        let px = rect.applying(CGAffineTransform(scaleX: img.scale, y: img.scale))
        if let cg = img.cgImage?.cropping(to: px) {
            onDone(UIImage(cgImage: cg, scale: img.scale, orientation: .up))
        } else {
            onDone(img)
        }
        dismiss()
    }

    /// Убираем ориентацию EXIF, чтобы математика обрезки была корректной
    private func normalized(_ image: UIImage?) -> UIImage? {
        guard let image = image else { return nil }
        if image.imageOrientation == .up { return image }
        let f = UIGraphicsImageRendererFormat(); f.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: f).image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }

    private func loadFull() async {
        let o = PHImageRequestOptions(); o.deliveryMode = .highQualityFormat; o.isNetworkAccessAllowed = true
        let img: UIImage? = await withCheckedContinuation { c in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 1600, height: 1600), contentMode: .aspectFit, options: o) { i, _ in c.resume(returning: i) }
        }
        await MainActor.run { full = img }
    }
}

struct CropItem: Identifiable, Hashable { let asset: PHAsset; var id: String { asset.localIdentifier }; static func == (a: CropItem, b: CropItem) -> Bool { a.id == b.id }; func hash(into h: inout Hasher) { h.combine(id) } }
