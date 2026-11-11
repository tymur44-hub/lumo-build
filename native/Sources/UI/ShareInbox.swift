import SwiftUI
import UniformTypeIdentifiers

/// То, чем поделились из другого приложения через «Поделиться → Lumo»:
/// расширение кладёт файлы в буфер и открывает Lumo, здесь выбираем, кому отправить.
@MainActor
final class ShareInbox: ObservableObject {
    static let shared = ShareInbox()
    struct File: Identifiable { let id = UUID(); let data: Data; let type: String; let name: String }
    struct Bundle_: Identifiable { let id = UUID(); let files: [File]; let text: String }
    @Published var pending: Bundle_?

    func load() {
        let pb = UIPasteboard.general
        let marker = "ru.volshebnymir.lumo.share"
        guard pb.contains(pasteboardTypes: [marker]) else { return }
        let items = pb.items
        guard let first = items.first, let j = first[marker] as? Data,
              let info = (try? JSONSerialization.jsonObject(with: j)) as? [String: Any] else { return }
        let meta = (info["files"] as? [[String: String]]) ?? []
        var files: [File] = []
        for (i, m) in meta.enumerated() where i + 1 < items.count {
            let t = m["type"] ?? UTType.data.identifier
            if let d = items[i + 1][t] as? Data { files.append(File(data: d, type: t, name: m["name"] ?? "file")) }
            else if let img = items[i + 1][t] as? UIImage, let d = img.jpegData(compressionQuality: 0.92) { files.append(File(data: d, type: UTType.jpeg.identifier, name: m["name"] ?? "photo.jpg")) }
        }
        pb.items = []   // забрали — чистим буфер
        let text = (info["text"] as? String) ?? ""
        guard !files.isEmpty || !text.isEmpty else { return }
        pending = Bundle_(files: files, text: text)
    }

    func send(_ b: Bundle_, to chatId: String, model: AppModel) {
        for f in b.files {
            let ut = UTType(f.type) ?? .data
            let ext = ut.preferredFilenameExtension ?? (f.name as NSString).pathExtension
            if ut.conforms(to: .image), let img = UIImage(data: f.data), let jpg = img.jpegData(compressionQuality: 0.88) {
                model.sendMedia(chatId: chatId, kind: "image", data: jpg, ext: "jpg", contentType: "image/jpeg",
                                meta: ["w": Int(img.size.width), "h": Int(img.size.height), "size": jpg.count])
            } else if ut.conforms(to: .movie) {
                model.sendMedia(chatId: chatId, kind: "video", data: f.data, ext: ext.isEmpty ? "mp4" : ext,
                                contentType: ut.preferredMIMEType ?? "video/mp4", meta: ["size": f.data.count])
            } else {
                model.sendMedia(chatId: chatId, kind: "file", data: f.data, ext: ext.isEmpty ? "bin" : ext,
                                contentType: ut.preferredMIMEType ?? "application/octet-stream", meta: ["name": f.name, "size": f.data.count])
            }
        }
        if !b.text.isEmpty { Task { _ = await model.send(chatId: chatId, kind: "text", body: b.text) } }
        pending = nil
        model.open(chatId)
    }
}

/// Окно «Отправить в…»: поиск и список чатов
struct ShareTargetSheet: View {
    let bundle: ShareInbox.Bundle_
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var q = ""

    private var list: [ChatItem] {
        let all = model.chats.filter { !($0.isChannel && !$0.canPost) }
        guard !q.isEmpty else { return all }
        let s = q.lowercased()
        return all.filter { $0.displayName.lowercased().contains(s) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: bundle.files.first.map { UTType($0.type)?.conforms(to: .movie) == true ? "video.fill" : (UTType($0.type)?.conforms(to: .image) == true ? "photo.fill" : "doc.fill") } ?? "text.alignleft")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                        .frame(width: 40, height: 40).background(Theme.accent, in: RoundedRectangle(cornerRadius: 11))
                    Text(summary).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(2)
                    Spacer()
                }
                .padding(14)
                TextField("Поиск", text: $q)
                    .padding(.horizontal, 14).frame(height: 40)
                    .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 14).padding(.bottom, 8)
                List(list) { c in
                    Button { ShareInbox.shared.send(bundle, to: c.id, model: model); dismiss() } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 44)
                            Text(c.displayName).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                            Spacer()
                        }
                    }
                    .listRowBackground(Theme.bg)
                }
                .listStyle(.plain)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Отправить в…").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { ShareInbox.shared.pending = nil; dismiss() } } }
        }
    }

    private var summary: String {
        let n = bundle.files.count
        if n == 0 { return bundle.text }
        let f = bundle.files.first!
        let ut = UTType(f.type)
        if n == 1 { return ut?.conforms(to: .image) == true ? "Фото" : ut?.conforms(to: .movie) == true ? "Видео" : f.name }
        return "Файлов: \(n)"
    }
}
