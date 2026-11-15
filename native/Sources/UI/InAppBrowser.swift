import SwiftUI
import WebKit

/// Встроенный браузер (как в Telegram): ссылки открываются внутри Lumo, а не в Safari.
final class InAppBrowser: ObservableObject {
    static let shared = InAppBrowser()
    @Published var url: URL?
    func open(_ u: URL) { url = u }
}

private final class WebModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var progress: Double = 0
    @Published var title: String = ""
    @Published var host: String = ""
    @Published var canBack = false
    @Published var canForward = false
    @Published var loading = false
    let web: WKWebView

    override init() {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        web = WKWebView(frame: .zero, configuration: cfg)
        super.init()
        web.navigationDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        web.addObserver(self, forKeyPath: "title", options: .new, context: nil)
    }
    deinit { web.removeObserver(self, forKeyPath: "estimatedProgress"); web.removeObserver(self, forKeyPath: "title") }

    func load(_ u: URL) { web.load(URLRequest(url: u)); host = u.host ?? "" }

    override func observeValue(forKeyPath k: String?, of o: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if k == "estimatedProgress" { progress = web.estimatedProgress }
        if k == "title" { title = web.title ?? "" }
    }
    func syncNav() { canBack = web.canGoBack; canForward = web.canGoForward; host = web.url?.host ?? host }
    func webView(_ w: WKWebView, didStartProvisionalNavigation n: WKNavigation!) { loading = true; syncNav() }
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { loading = false; syncNav() }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { loading = false; syncNav() }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { loading = false; syncNav() }
}

private struct WebRepresentable: UIViewRepresentable {
    let model: WebModel
    func makeUIView(context: Context) -> WKWebView { model.web }
    func updateUIView(_ v: WKWebView, context: Context) {}
}

struct WebBrowserView: View {
    let initial: URL
    var onClose: () -> Void
    @StateObject private var m = WebModel()
    @State private var share: URL?
    @State private var started = false

    var body: some View {
        VStack(spacing: 0) {
            // шапка
            HStack(spacing: 12) {
                Button { onClose() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 34, height: 34).background(Theme.panel2, in: Circle())
                }
                .buttonStyle(BouncyButtonStyle())
                VStack(spacing: 1) {
                    Text(m.title.isEmpty ? m.host : m.title).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(m.host).font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                Menu {
                    Button { share = m.web.url ?? initial } label: { Label("Поделиться", systemImage: "square.and.arrow.up") }
                    Button { UIPasteboard.general.string = (m.web.url ?? initial).absoluteString; model_say("Ссылка скопирована") } label: { Label("Скопировать ссылку", systemImage: "doc.on.doc") }
                    Button { m.web.reload() } label: { Label("Обновить", systemImage: "arrow.clockwise") }
                    Button { UIApplication.shared.open(m.web.url ?? initial) } label: { Label("Открыть в Safari", systemImage: "safari") }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 34, height: 34).background(Theme.panel2, in: Circle())
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            // прогресс загрузки
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.line).frame(height: 2)
                GeometryReader { g in
                    Rectangle().fill(Theme.a1).frame(width: g.size.width * m.progress, height: 2)
                        .opacity(m.loading || m.progress < 1 ? 1 : 0)
                }
                .frame(height: 2)
            }
            WebRepresentable(model: m)
                .ignoresSafeArea(edges: .bottom)
            // нижняя панель навигации
            HStack(spacing: 40) {
                Button { m.web.goBack() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)) }
                    .disabled(!m.canBack).opacity(m.canBack ? 1 : 0.3)
                Button { m.web.goForward() } label: { Image(systemName: "chevron.right").font(.system(size: 20, weight: .semibold)) }
                    .disabled(!m.canForward).opacity(m.canForward ? 1 : 0.3)
                Spacer()
                Button { if m.loading { m.web.stopLoading() } else { m.web.reload() } } label: {
                    Image(systemName: m.loading ? "xmark" : "arrow.clockwise").font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(Theme.a1)
            .padding(.horizontal, 28).padding(.top, 8).padding(.bottom, 2)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(item: Binding(get: { share.map { ShareURL(url: $0) } }, set: { share = $0?.url })) { s in
            ShareSheet(items: [s.url])
        }
        .onAppear { if !started { started = true; m.load(initial) } }
    }
    private func model_say(_ s: String) { AppModel.shared.say(s) }
}

private struct ShareURL: Identifiable { let url: URL; var id: String { url.absoluteString } }
