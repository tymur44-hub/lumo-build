import SwiftUI
import PhotosUI

/// Обои для этого чата: для себя или для себя и собеседника (как в Telegram)
struct ChatWallSheet: View {
    let chatId: String
    let peerName: String?
    let isPrivate: Bool
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var look: Appearance
    @Environment(\.dismiss) private var dismiss

    @State private var pick: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var preset: Int?
    @State private var preview = false
    @State private var blur = false
    @State private var dim = 0.0
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Group {
                if preview { previewView } else { gridView }
            }
            .navigationTitle(preview ? "Предпросмотр" : "Обои чата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(preview ? "Назад" : "Закрыть") { if preview { withAnimation(.easeInOut(duration: 0.3)) { preview = false } } else { dismiss() } }
                }
            }
        }
        .onChange(of: pick) { item in
            guard let item else { return }
            Task {
                if let d = try? await item.loadTransferable(type: Data.self), let im = UIImage(data: d) {
                    image = im; preset = nil
                    withAnimation(.easeInOut(duration: 0.3)) { preview = true }
                }
            }
        }
    }

    private var gridView: some View {
        ScrollView {
            VStack(spacing: 14) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(wallAll, id: \.self) { i in
                        ChatWallpaper(index: i)
                            .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(alignment: .topTrailing) { if wallIsPremium(i) { Image(systemName: "star.fill").font(.system(size: 13)).foregroundColor(Color(hex: 0xffc247)).padding(8) } }
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
                            .onTapGesture { preset = i; image = nil; withAnimation(.easeInOut(duration: 0.3)) { preview = true } }
                    }
                }
                PhotosPicker(selection: $pick, matching: .images) {
                    Label("Выбрать обои из фото", systemImage: "photo.on.rectangle").font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.a1)
                }
                if model.chatWalls[chatId] != nil {
                    Button(role: .destructive) { Task { await model.clearWall(chat: chatId); dismiss() } } label: {
                        Text("Сбросить обои этого чата").frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
    }

    private var previewView: some View {
        ZStack(alignment: .bottom) {
            WallPreview(image: image, preset: preset ?? 0, blur: blur, dim: dim).ignoresSafeArea(edges: .bottom)
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Привет! Так будут выглядеть обои").font(.system(size: 15)).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Theme.bubble, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.text)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("Отлично выглядит!").font(.system(size: 15)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Theme.out, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(14)
                Spacer()
                VStack(spacing: 10) {
                    if image != nil {
                        Toggle("Размытие", isOn: $blur.animation()).tint(Theme.a1)
                    }
                    HStack {
                        Image(systemName: "sun.max").foregroundColor(.white.opacity(0.8))
                        Slider(value: $dim, in: 0...80).tint(Theme.a1)
                        Image(systemName: "moon.fill").foregroundColor(.white.opacity(0.8))
                    }
                    Button { apply(both: false) } label: { label("Применить для этого чата") }
                    if isPrivate {
                        Button { apply(both: true) } label: { label("Применить для меня и \(peerName ?? "собеседника")", filled: false) }
                    }
                }
                .padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22)).padding(10)
                .foregroundColor(Theme.text)
            }
        }
        .disabled(busy)
    }

    private func label(_ t: String, filled: Bool = true) -> some View {
        Group {
            if busy { ProgressView().tint(.white) } else { Text(t).font(.system(size: 16, weight: .bold)) }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 13)
        .foregroundColor(filled ? .white : Theme.a1)
        .background(filled ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.a1.opacity(0.14)), in: RoundedRectangle(cornerRadius: 14))
    }

    private func apply(both: Bool) {
        busy = true
        Task {
            var url: String?
            if let im = image {
                let small = im.scaledDown(maxSide: 1600)
                guard let data = small.jpegData(compressionQuality: 0.8),
                      let u = try? await API.shared.upload(data, ext: "jpg", contentType: "image/jpeg") else {
                    model.say("Не удалось загрузить фото"); busy = false; return
                }
                url = u
            }
            let ok = await model.setWall(chat: chatId, preset: url == nil ? (preset ?? 0) : nil, url: url, blur: blur, dim: Int(dim), both: both)
            busy = false
            if ok { dismiss() }
        }
    }
}

private struct WallPreview: View {
    let image: UIImage?
    let preset: Int
    let blur: Bool
    let dim: Double

    var body: some View {
        ZStack {
            if let im = image {
                GeometryReader { g in
                    Image(uiImage: im).resizable().scaledToFill().frame(width: g.size.width, height: g.size.height).clipped()
                        .blur(radius: blur ? 14 : 0).clipped()
                }
            } else {
                ChatWallpaper(index: preset)
            }
            Color.black.opacity(dim / 100)
        }
    }
}

private extension UIImage {
    func scaledDown(maxSide: CGFloat) -> UIImage {
        let m = max(size.width, size.height)
        guard m > maxSide else { return self }
        let k = maxSide / m
        let ns = CGSize(width: size.width * k, height: size.height * k)
        return UIGraphicsImageRenderer(size: ns).image { _ in draw(in: CGRect(origin: .zero, size: ns)) }
    }
}
