import UIKit
import WebKit
import UserNotifications
import BackgroundTasks

/// Уведомления без серверов Apple: iOS время от времени будит приложение в фоне,
/// оно спрашивает у сервера Lumo новые сообщения и показывает их как обычные уведомления.
final class LumoNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LumoNotifier()
    static let refreshID = "ru.volshebnymir.lumo.refresh"
    // основной сервер и сервер-посредник в России (если основной недоступен)
    static let bases = ["https://foniukmpiukuwpcdvdhp.supabase.co", "https://api.volshebny-mir.ru"]
    static let anonKey = "sb_publishable_cE72E1dUPnfaVn8mPnc9sA_U2HO-mxN"
    static let sessionKey = "sb-foniukmpiukuwpcdvdhp-auth-token"

    var onOpenChat: ((String) -> Void)?
    var isRegistered: Bool { token != nil }
    var pendingChat: String?

    private let defaults = UserDefaults.standard
    private var registering = false

    private var token: String? {
        get { defaults.string(forKey: "lm_device_token") }
        set { defaults.set(newValue, forKey: "lm_device_token") }
    }
    private var tokenUser: String? {
        get { defaults.string(forKey: "lm_device_user") }
        set { defaults.set(newValue, forKey: "lm_device_user") }
    }

    // MARK: - запуск

    func setup() {
        UNUserNotificationCenter.current().delegate = self
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshID, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleRefresh(refresh)
        }
    }

    func scheduleRefresh() {
        guard token != nil else { return }
        let req = BGAppRefreshTaskRequest(identifier: Self.refreshID)
        req.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(req)
    }

    private func handleRefresh(_ task: BGAppRefreshTask) {
        scheduleRefresh()
        var finished = false
        let finish: (Bool) -> Void = { ok in
            DispatchQueue.main.async {
                if finished { return }
                finished = true
                task.setTaskCompleted(success: ok)
            }
        }
        task.expirationHandler = { finish(false) }
        check(done: finish)
    }

    // MARK: - связь страницы и устройства

    /// Читает вход пользователя со страницы и получает ключ устройства (или удаляет его после выхода).
    func sync(from webView: WKWebView) {
        let js = "localStorage.getItem('\(Self.sessionKey)')"
        webView.evaluateJavaScript(js) { result, error in
            if error != nil { return }
            let raw = result as? String
            var access: String?
            var uid: String?
            if let raw = raw, let data = raw.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                access = obj["access_token"] as? String
                uid = (obj["user"] as? [String: Any])?["id"] as? String
            }
            if let access = access, let uid = uid {
                self.register(access: access, uid: uid)
            } else if raw == nil, self.token != nil {
                self.drop()
            }
        }
    }

    private func register(access: String, uid: String) {
        if token != nil && tokenUser == uid {
            askPermission()
            return
        }
        guard !registering else { return }
        registering = true
        let old: Any = (tokenUser == uid ? token : nil) ?? NSNull()
        post("/rest/v1/rpc/lm_device_register", body: ["p_old": old],
             headers: ["apikey": Self.anonKey, "Authorization": "Bearer " + access]) { code, data in
            DispatchQueue.main.async {
                self.registering = false
                guard code == 200, let data = data,
                      let t = (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) as? String,
                      !t.isEmpty else { return }
                if let prev = self.token, prev != t { self.dropRemote(prev) }
                self.token = t
                self.tokenUser = uid
                self.askPermission()
                self.scheduleRefresh()
            }
        }
    }

    private func askPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            guard s.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    private func drop() {
        if let t = token { dropRemote(t) }
        token = nil
        tokenUser = nil
        setBadge(0)
    }

    private func dropRemote(_ t: String) {
        post("/functions/v1/lumo/device", body: ["token": t, "action": "drop"]) { _, _ in }
    }

    /// Приложение уходит в фон: всё, что пришло до этого момента, пользователь уже видел.
    func markSeen() {
        guard let t = token else { return }
        var bg = UIBackgroundTaskIdentifier.invalid
        bg = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(bg)
            bg = .invalid
        }
        post("/functions/v1/lumo/device", body: ["token": t, "action": "seen"]) { _, _ in
            DispatchQueue.main.async {
                if bg != .invalid { UIApplication.shared.endBackgroundTask(bg); bg = .invalid }
            }
        }
    }

    // MARK: - проверка новых сообщений

    func check(done: @escaping (Bool) -> Void) {
        guard let t = token else { return done(false) }
        post("/functions/v1/lumo/device", body: ["token": t]) { code, data in
            if code == 404 {
                DispatchQueue.main.async { self.token = nil; self.tokenUser = nil }
                return done(true)
            }
            guard code == 200, let data = data,
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return done(false) }
            let items = obj["items"] as? [[String: Any]] ?? []
            let badge = (obj["badge"] as? NSNumber)?.intValue ?? 0
            self.deliver(items, badge: badge)
            done(true)
        }
    }

    private func deliver(_ items: [[String: Any]], badge: Int) {
        let center = UNUserNotificationCenter.current()
        for it in items {
            let c = UNMutableNotificationContent()
            c.title = it["title"] as? String ?? "Lumo"
            c.body = it["body"] as? String ?? "Новое сообщение"
            c.sound = .default
            if let chat = it["chat"] as? String {
                c.threadIdentifier = chat
                c.userInfo = ["chat": chat]
            }
            let id = "lm-" + (it["id"] as? String ?? UUID().uuidString)
            center.add(UNNotificationRequest(identifier: id, content: c, trigger: nil))
        }
        DispatchQueue.main.async { self.setBadge(badge) }
    }

    func setBadge(_ n: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(n) { _ in }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = n
        }
    }

    // MARK: - сеть (основной сервер, при сбое — посредник)

    private func post(_ path: String, body: [String: Any], headers: [String: String] = [:],
                      baseIndex: Int = 0, done: @escaping (Int, Data?) -> Void) {
        guard baseIndex < Self.bases.count, let url = URL(string: Self.bases[baseIndex] + path) else {
            return done(0, nil)
        }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if err != nil || code == 0 || code >= 500 {
                self.post(path, body: body, headers: headers, baseIndex: baseIndex + 1, done: done)
            } else {
                done(code, data)
            }
        }.resume()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // приложение открыто — новые сообщения и так видны на экране
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let chat = response.notification.request.content.userInfo["chat"] as? String {
            DispatchQueue.main.async {
                if let open = self.onOpenChat { open(chat) } else { self.pendingChat = chat }
            }
        }
        completionHandler()
    }
}
