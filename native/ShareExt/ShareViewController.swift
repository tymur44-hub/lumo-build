import UIKit
import UniformTypeIdentifiers

/// «Поделиться → Lumo»: расширение кладёт фото, видео или файлы в общий буфер
/// и открывает Lumo, где выбирается, кому отправить.
/// (Без общей папки приложений: так расширение работает при любой подписи приложения.)
final class ShareViewController: UIViewController {
    static let marker = "ru.volshebnymir.lumo.share"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await collect() }
    }

    private func collect() async {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        var out: [[String: Any]] = []
        var meta: [[String: String]] = []
        var text = ""
        for item in items {
            for p in item.attachments ?? [] {
                if let r = await load(p) {
                    out.append([r.type: r.data])
                    meta.append(["type": r.type, "name": r.name])
                } else if p.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                          let u = try? await p.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL, !u.isFileURL {
                    text += (text.isEmpty ? "" : "\n") + u.absoluteString
                } else if p.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                          let s = try? await p.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                    text += (text.isEmpty ? "" : "\n") + s
                }
            }
        }
        let info: [String: Any] = ["files": meta, "text": text, "at": Date().timeIntervalSince1970]
        if let j = try? JSONSerialization.data(withJSONObject: info) {
            UIPasteboard.general.setItems([[Self.marker: j]] + out, options: [.expirationDate: Date().addingTimeInterval(600)])
        }
        openApp(URL(string: "lumo://share")!)
        try? await Task.sleep(nanoseconds: 300_000_000)
        extensionContext?.completeRequest(returningItems: nil)
    }

    private struct Loaded { let type: String; let data: Data; let name: String }

    private func load(_ p: NSItemProvider) async -> Loaded? {
        let kinds: [UTType] = [.movie, .image, .pdf, .data]
        for k in kinds where p.hasItemConformingToTypeIdentifier(k.identifier) {
            if k == .data, p.hasItemConformingToTypeIdentifier(UTType.url.identifier), !p.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) { return nil }
            let r: Loaded? = await withCheckedContinuation { c in
                _ = p.loadFileRepresentation(forTypeIdentifier: k.identifier) { url, _ in
                    guard let url = url, let d = try? Data(contentsOf: url) else { c.resume(returning: nil); return }
                    let t = UTType(filenameExtension: url.pathExtension)?.identifier ?? k.identifier
                    c.resume(returning: Loaded(type: t, data: d, name: url.lastPathComponent))
                }
            }
            if let r = r { return r }
            if k == .image, let img = try? await p.loadItem(forTypeIdentifier: k.identifier) as? UIImage, let d = img.jpegData(compressionQuality: 0.92) {
                return Loaded(type: UTType.jpeg.identifier, data: d, name: "photo.jpg")
            }
        }
        return nil
    }

    /// открыть Lumo из расширения: ищем по цепочке объект, который умеет открывать ссылки (UIApplication)
    private func openApp(_ url: URL) {
        typealias Open3 = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, AnyObject?) -> Void
        let sel3 = NSSelectorFromString("openURL:options:completionHandler:")
        var r: UIResponder? = self
        while let cur = r {
            if cur.responds(to: sel3), let m = class_getInstanceMethod(type(of: cur), sel3) {
                let f = unsafeBitCast(method_getImplementation(m), to: Open3.self)
                f(cur, sel3, url as NSURL, NSDictionary(), nil)
                return
            }
            r = cur.next
        }
        let sel1 = NSSelectorFromString("openURL:")
        r = self
        while let cur = r {
            if cur.responds(to: sel1) { _ = cur.perform(sel1, with: url); return }
            r = cur.next
        }
    }
}
