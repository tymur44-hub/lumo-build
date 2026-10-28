import SwiftUI
import WebKit

private func hexStr(_ v: UInt32) -> String { String(format: "#%06x", v & 0xffffff) }

/// Мини-приложение бота на весь экран (как Web Apps в Telegram)
struct MiniAppView: View {
    let req: MiniAppReq
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var title = ""
    @State private var html: String?
    @State private var url: URL?
    @State private var bridge = ""
    @State private var error: String?
    @State private var backVisible = false
    @StateObject private var ref = WebRef()

    private var dark: Bool { scheme == .dark }
    private var theme: [String: String] {
        [
            "bg_color": hexStr(dark ? 0x0c0d1a : 0xeef0fb), "text_color": hexStr(dark ? 0xeef0ff : 0x14163a),
            "hint_color": hexStr(dark ? 0x8d90b8 : 0x7276a0), "link_color": hexStr(Appearance.shared.pair.0),
            "button_color": hexStr(Appearance.shared.pair.0), "button_text_color": "#ffffff",
            "secondary_bg_color": hexStr(dark ? 0x13142a : 0xffffff),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Button {
                    if backVisible { ref.web?.evaluateJavaScript("window.__lumoBack&&window.__lumoBack()") } else { dismiss() }
                } label: {
                    Image(systemName: backVisible ? "chevron.left" : "xmark").font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.text).frame(width: 44, height: 44)
                }
                Text(title.isEmpty ? (model.profiles[req.botId]?.name ?? "Мини-приложение") : title)
                    .font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(Theme.panel)
            ZStack {
                Theme.bg
                if html != nil || url != nil {
                    MiniWeb(ref: ref, html: html, url: url, bridge: bridge, bg: dark ? UIColor(red: 0.047, green: 0.051, blue: 0.102, alpha: 1) : UIColor(red: 0.933, green: 0.941, blue: 0.984, alpha: 1)) { ev, d in handle(ev, d) }
                } else if let e = error {
                    Text(e).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(30)
                } else { ProgressView() }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .task { await load() }
    }

    private func load() async {
        var body: [String: Any] = ["bot_id": req.botId, "theme": theme, "scheme": dark ? "dark" : "light", "platform": "ios"]
        if let u = req.url { body["url"] = u }
        do {
            guard let r = try await API.shared.botFunction("/webapp/init", body: body) as? [String: Any], (r["ok"] as? Bool) == true else {
                error = "Не удалось открыть"; return
            }
            title = r["title"] as? String ?? "Мини-приложение"
            bridge = r["bridge"] as? String ?? ""
            if let h = r["html"] as? String { html = h }
            else if let u = r["url"] as? String, let uu = URL(string: u) { url = uu }
            else { error = "Не удалось открыть" }
        } catch { self.error = error.localizedDescription }
    }

    private func handle(_ ev: String, _ d: [String: Any]) {
        switch ev {
        case "close": dismiss()
        case "sendData":
            let data = d["data"] as? String ?? ""
            Task {
                _ = try? await API.shared.botFunction("/webapp/data", body: ["bot_id": req.botId, "data": data])
                dismiss()
            }
        case "openLink":
            if let u = d["url"] as? String, let uu = URL(string: u), uu.scheme == "https" || uu.scheme == "http" { UIApplication.shared.open(uu) }
        case "copy": UIPasteboard.general.string = d["text"] as? String ?? ""
        case "haptic":
            let s = d["style"] as? String ?? "light"
            if s == "error" || s == "success" || s == "warning" {
                UINotificationFeedbackGenerator().notificationOccurred(s == "error" ? .error : s == "warning" ? .warning : .success)
            } else { UIImpactFeedbackGenerator(style: s == "heavy" ? .heavy : s == "medium" ? .medium : .light).impactOccurred() }
        case "backButton": backVisible = d["visible"] as? Bool ?? false
        default: break
        }
    }
}

final class WebRef: ObservableObject { weak var web: WKWebView? }

private struct MiniWeb: UIViewRepresentable {
    let ref: WebRef
    let html: String?
    let url: URL?
    let bridge: String
    let bg: UIColor
    let onEvent: (String, [String: Any]) -> Void

    func makeCoordinator() -> Coord { Coord(onEvent) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let pre = "window.__lumoPost=function(e,d){window.webkit.messageHandlers.lumo.postMessage({e:e,d:d||{}})};"
        cfg.userContentController.addUserScript(WKUserScript(source: pre + bridge, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        cfg.userContentController.add(context.coordinator, name: "lumo")
        let w = WKWebView(frame: .zero, configuration: cfg)
        w.isOpaque = false
        w.backgroundColor = bg
        w.scrollView.backgroundColor = bg
        w.scrollView.contentInsetAdjustmentBehavior = .never
        ref.web = w
        if let h = html { w.loadHTMLString(h, baseURL: URL(string: "https://miniapp.lumo.local/")) }
        else if let u = url { w.load(URLRequest(url: u)) }
        return w
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coord) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "lumo")
        uiView.stopLoading()
    }

    final class Coord: NSObject, WKScriptMessageHandler {
        let onEvent: (String, [String: Any]) -> Void
        init(_ f: @escaping (String, [String: Any]) -> Void) { onEvent = f }
        func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
            guard let b = m.body as? [String: Any], let e = b["e"] as? String else { return }
            let d = b["d"] as? [String: Any] ?? [:]
            DispatchQueue.main.async { self.onEvent(e, d) }
        }
    }
}
