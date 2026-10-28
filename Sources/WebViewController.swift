import UIKit
import WebKit
import SafariServices
import ObjectiveC

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, WKScriptMessageHandler, UIScrollViewDelegate {

    // адрес мессенджера (страница на Тильде)
    static let startURL = URL(string: "https://volshebny-mir.ru/page322172009.html")!
    // адреса, которые открываются внутри приложения; всё остальное — во встроенном браузере / Telegram
    static let internalSuffixes = ["volshebny-mir.ru", "supabase.co", "tilda.ws", "tildacdn.com", "tilda.cc"]
    static let background = UIColor(red: 15 / 255, green: 16 / 255, blue: 32 / 255, alpha: 1)

    private var webView: WKWebView!
    private let errorView = UIView()
    private let errorLabel = UILabel()
    private var lastTopColor = ""
    private var downloads: [ObjectIdentifier: URL] = [:]
    private var statusStyle: UIStatusBarStyle = .lightContent
    private var loadedOnce = false
    private var syncTimer: Timer?
    private var bottomConstraint: NSLayoutConstraint?
    private var keyboardShown = false

    override var preferredStatusBarStyle: UIStatusBarStyle { statusStyle }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    // MARK: - создание

    override func loadView() {
        let root = UIView()
        root.backgroundColor = Self.background
        view = root

        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.allowsPictureInPictureMediaPlayback = true
        cfg.websiteDataStore = .default()
        cfg.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1 LumoApp/1.3"
        if #available(iOS 16.4, *) {
            cfg.preferences.isElementFullscreenEnabled = true
        }
        // странице сообщаем, что она открыта в приложении Lumo для iPhone
        let marker = WKUserScript(
            source: "window.LUMO_NATIVE={platform:'ios',version:'1.3'};",
            injectionTime: .atDocumentStart, forMainFrameOnly: true)
        cfg.userContentController.addUserScript(marker)
        // полоска под часами и «чёлкой» принимает цвет того, что сейчас вверху экрана (шапка чата, список, плеер…)
        let topColor = WKUserScript(source: Self.topColorJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        cfg.userContentController.addUserScript(topColor)
        cfg.userContentController.add(WeakMessageHandler(self), name: "lumoTop")

        let wv = WKWebView(frame: root.bounds, configuration: cfg)
        wv.translatesAutoresizingMaskIntoConstraints = false
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.allowsBackForwardNavigationGestures = false
        wv.allowsLinkPreview = false
        wv.isOpaque = false
        wv.backgroundColor = Self.background
        wv.scrollView.backgroundColor = Self.background
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        wv.scrollView.bounces = false
        if #available(iOS 16.4, *) {
            wv.isInspectable = true
        }
        root.addSubview(wv)
        // страница начинается под строкой состояния и «чёлкой» — кнопки в шапке всегда доступны;
        // снизу страница идёт до края экрана и сама отступает от полоски «домой»
        let bottom = wv.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        NSLayoutConstraint.activate([
            wv.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor),
            wv.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            bottom,
        ])
        bottomConstraint = bottom
        wv.scrollView.delegate = self
        webView = wv
        buildErrorView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardAccessoryBar()
        LumoNotifier.shared.onOpenChat = { [weak self] chat in self?.openChat(chat) }
        if let chat = LumoNotifier.shared.pendingChat {
            LumoNotifier.shared.pendingChat = nil
            openChat(chat)
        } else {
            webView.load(URLRequest(url: Self.startURL))
        }
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        // раз в минуту сверяем вход: после входа в аккаунт появится ключ для уведомлений, после выхода — удалится
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            if UIApplication.shared.applicationState == .active { self?.syncDevice() }
        }
    }

    // MARK: - клавиатура: окно сжимается до места над ней, страница не уезжает вверх

    @objc private func keyboardChange(_ n: Notification) {
        guard let info = n.userInfo,
              let end = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        var overlap: CGFloat = 0
        if n.name != UIResponder.keyboardWillHideNotification {
            let local = view.convert(end, from: nil)
            overlap = max(0, view.bounds.maxY - local.minY)
        }
        keyboardShown = overlap > 0
        guard bottomConstraint?.constant != -overlap else { return }
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        bottomConstraint?.constant = -overlap
        UIView.animate(withDuration: duration, delay: 0, options: [UIView.AnimationOptions(rawValue: curve << 16), .beginFromCurrentState]) {
            self.view.layoutIfNeeded()
        }
        webView.scrollView.setContentOffset(.zero, animated: false)
    }

    // iOS сам прокручивает страницу к полю ввода — при открытой клавиатуре не даём ей сдвигаться
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if keyboardShown && scrollView.contentOffset != .zero {
            scrollView.contentOffset = .zero
        }
    }

    // MARK: - уведомления

    func syncDevice() {
        guard loadedOnce, let host = webView.url?.host?.lowercased(), host.hasSuffix("volshebny-mir.ru") else { return }
        LumoNotifier.shared.sync(from: webView)
    }

    /// Нажали на уведомление — открываем нужный чат.
    func openChat(_ id: String) {
        let safe = String(id.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }.prefix(64))
        guard !safe.isEmpty else { return }
        guard loadedOnce else {
            var c = URLComponents(url: Self.startURL, resolvingAgainstBaseURL: false)
            c?.fragment = "c=" + safe
            webView.load(URLRequest(url: c?.url ?? Self.startURL))
            return
        }
        let js = "(function(){try{if(typeof openChat==='function'&&typeof S!=='undefined'&&S.me){if(typeof setTab==='function')setTab('chats');openChat('\(safe)');return true}}catch(e){}return false})()"
        webView.evaluateJavaScript(js) { [weak self] r, _ in
            if (r as? Bool) != true {
                self?.webView.evaluateJavaScript("location.hash='#c=\(safe)';location.reload();", completionHandler: nil)
            }
        }
    }

    // MARK: - внешний вид

    static let topColorJS = """
    (function(){
      var last='';
      function col(){
        try{
          var el=document.elementFromPoint(innerWidth/2,1);
          while(el){
            var c=getComputedStyle(el).backgroundColor||'';
            var m=c.match(/rgba?\\(([^)]+)\\)/);
            if(m){ var p=m[1].split(',').map(parseFloat); var a=p.length>3?p[3]:1;
              if(a>0.5) return Math.round(p[0])+','+Math.round(p[1])+','+Math.round(p[2]); }
            el=el.parentElement;
          }
        }catch(e){}
        return '';
      }
      function tick(){ var c=col(); if(c&&c!==last){ last=c; try{ webkit.messageHandlers.lumoTop.postMessage(c); }catch(e){} } }
      setInterval(tick,300);
      document.addEventListener('visibilitychange',tick);
      addEventListener('resize',tick);
      tick();
    })();
    """

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "lumoTop", let s = message.body as? String, s != lastTopColor else { return }
        let parts = s.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 3 else { return }
        lastTopColor = s
        let color = UIColor(red: CGFloat(parts[0] / 255), green: CGFloat(parts[1] / 255), blue: CGFloat(parts[2] / 255), alpha: 1)
        applyTheme(color)
    }

    private func applyTheme(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
        let light = (0.299 * r + 0.587 * g + 0.114 * b) > 0.6
        statusStyle = light ? .darkContent : .lightContent
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = color
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    // убираем серую полоску «‹ › Готово» над клавиатурой
    private func hideKeyboardAccessoryBar() {
        guard let target = webView.scrollView.subviews.first(where: {
            String(describing: type(of: $0)).hasPrefix("WKContent")
        }) else { return }
        let name = "\(type(of: target))_LumoNoAccessory"
        var newClass: AnyClass? = NSClassFromString(name)
        if newClass == nil, let base = object_getClass(target) {
            newClass = name.withCString { objc_allocateClassPair(base, $0, 0) }
            if let cls = newClass {
                let block: @convention(block) (AnyObject) -> UIView? = { _ in nil }
                class_addMethod(cls, #selector(getter: UIResponder.inputAccessoryView),
                                imp_implementationWithBlock(block), "@@:")
                objc_registerClassPair(cls)
            }
        }
        if let cls = newClass {
            object_setClass(target, cls)
        }
    }

    private func buildErrorView() {
        errorView.frame = view.bounds
        errorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        errorView.backgroundColor = Self.background
        errorView.isHidden = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(named: "LaunchLogo"))
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 88).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let title = UILabel()
        title.text = "Нет соединения"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .white

        errorLabel.text = "Проверьте интернет и попробуйте ещё раз"
        errorLabel.font = .systemFont(ofSize: 15)
        errorLabel.textColor = UIColor(white: 1, alpha: 0.65)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center

        let button = UIButton(type: .system)
        button.setTitle("Повторить", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 124 / 255, green: 92 / 255, blue: 1, alpha: 1)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 28, bottom: 12, right: 28)
        button.addTarget(self, action: #selector(retry), for: .touchUpInside)

        [icon, title, errorLabel, button].forEach { stack.addArrangedSubview($0) }
        errorView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: errorView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: errorView.trailingAnchor, constant: -32),
        ])
        view.addSubview(errorView)
    }

    @objc private func retry() {
        errorView.isHidden = true
        if loadedOnce, webView.url != nil {
            webView.reload()
        } else {
            webView.load(URLRequest(url: Self.startURL))
        }
    }

    private func showError(_ error: Error) {
        let ns = error as NSError
        // отмена загрузки и «переход отменён политикой» — это не ошибки
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
        if ns.domain == "WebKitErrorDomain" && (ns.code == 102 || ns.code == 204) { return }
        errorLabel.text = "Проверьте интернет и попробуйте ещё раз"
        errorView.isHidden = false
    }

    // MARK: - ссылки

    private func isInternal(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return true }
        return Self.internalSuffixes.contains { host == $0 || host.hasSuffix("." + $0) }
    }

    private func openExternal(_ url: URL) {
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""
        let isTelegram = host == "t.me" || host.hasSuffix(".t.me") || host == "telegram.me"
        if (scheme == "http" || scheme == "https") && !isTelegram {
            let safari = SFSafariViewController(url: url)
            topController().present(safari, animated: true)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func topController() -> UIViewController {
        var top: UIViewController = self
        while let next = top.presentedViewController { top = next }
        return top
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
        if navigationAction.shouldPerformDownload { return decisionHandler(.download) }
        let scheme = url.scheme?.lowercased() ?? ""
        if ["about", "blob", "data", "javascript"].contains(scheme) { return decisionHandler(.allow) }
        if scheme == "http" || scheme == "https" {
            // новое окно — решает createWebViewWith; вложенные фреймы не трогаем
            guard let frame = navigationAction.targetFrame, frame.isMainFrame else { return decisionHandler(.allow) }
            if isInternal(url) { return decisionHandler(.allow) }
            openExternal(url)
            return decisionHandler(.cancel)
        }
        // tel:, mailto:, tg: и прочее — системе
        openExternal(url)
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadedOnce = true
        errorView.isHidden = true
        // даём странице пару секунд восстановить вход и сверяем ключ для уведомлений
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.syncDevice() }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !loadedOnce { showError(error) }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "blob" || scheme == "data" {
                webView.load(navigationAction.request)
            } else {
                openExternal(url)
            }
        }
        return nil
    }

    // разрешение на камеру и микрофон для звонков и видеосообщений (системный запрос iOS всё равно покажется один раз)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        topController().present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        topController().present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        topController().present(alert, animated: true)
    }

    // MARK: - скачивание файлов → меню «Поделиться» (там же «Сохранить в Фото» / «Сохранить в Файлы»)

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = suggestedFilename.isEmpty ? "file" : suggestedFilename
        let dest = dir.appendingPathComponent(name)
        downloads[ObjectIdentifier(download)] = dest
        completionHandler(dest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let url = downloads.removeValue(forKey: ObjectIdentifier(download)) else { return }
        let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = view
        share.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        topController().present(share, animated: true)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeValue(forKey: ObjectIdentifier(download))
        let alert = UIAlertController(title: "Не удалось скачать файл", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topController().present(alert, animated: true)
    }
}

// посредник, чтобы обработчик сообщений со страницы не держал контроллер в памяти вечно
final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
