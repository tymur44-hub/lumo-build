import SwiftUI
import WebKit
import AVFoundation

/// Групповой звонок через LiveKit: доступ выдаёт сервер (функция lumo-lk), сам звонок — встроенная страница
struct GroupCallInfo: Identifiable {
    let id = UUID()
    let url: String
    let token: String
    let title: String
    let video: Bool
}

extension AppModel {
    func groupCall(_ chatId: String, video: Bool) async -> GroupCallInfo? {
        do {
            let r = try await API.shared.raw("POST", "/functions/v1/lumo-lk", body: ["chat_id": chatId, "action": "start"]) as? JSON ?? [:]
            if let e = r.str("error") { say(e); return nil }
            guard let u = r.str("url"), let t = r.str("token") else { say("Не удалось начать звонок"); return nil }
            return GroupCallInfo(url: u, token: t, title: chat(chatId)?.displayName ?? "Групповой звонок", video: video)
        } catch { say(error.localizedDescription); return nil }
    }

    /// сколько человек сейчас в групповом звонке
    func groupCallCount(_ chatId: String) async -> Int {
        let r = (try? await API.shared.raw("POST", "/functions/v1/lumo-lk", body: ["chat_id": chatId, "action": "status"])) as? JSON
        return r?.int("count") ?? 0
    }
}

/// Плашка «Идёт групповой звонок» над перепиской
struct GroupCallBanner: View {
    let count: Int
    let join: () -> Void
    var body: some View {
        Button(action: join) {
            HStack(spacing: 10) {
                Image(systemName: "phone.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(width: 30, height: 30).background(Circle().fill(Color(hex: 0x34c759)))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Групповой звонок").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    Text("\(count) \(count == 1 ? "участник" : (2...4).contains(count % 10) && !(12...14).contains(count % 100) ? "участника" : "участников")")
                        .font(.system(size: 13)).foregroundColor(Theme.muted)
                }
                Spacer()
                Text("Войти").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 7).background(Capsule().fill(Color(hex: 0x34c759)))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.panel)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

/// Экран группового звонка
struct GroupCallScreen: View {
    let info: GroupCallInfo
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        GroupCallWeb(info: info) { dismiss() }
            .ignoresSafeArea()
            .background(Color(hex: 0x0b0b10).ignoresSafeArea())
            .statusBarHidden(false)
            .preferredColorScheme(.dark)
            .onAppear {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                try? AVAudioSession.sharedInstance().setActive(true)
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

struct GroupCallWeb: UIViewRepresentable {
    let info: GroupCallInfo
    let onLeave: () -> Void

    func makeCoordinator() -> Coord { Coord(onLeave) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.userContentController.add(context.coordinator, name: "lumo")
        let w = WKWebView(frame: .zero, configuration: cfg)
        w.uiDelegate = context.coordinator
        w.isOpaque = false
        w.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        w.scrollView.isScrollEnabled = false
        let conf: [String: Any] = ["url": info.url, "token": info.token, "title": info.title, "video": info.video]
        let js = (try? JSONSerialization.data(withJSONObject: conf)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let html = gcallHTML.replacingOccurrences(of: "/*CFG*/", with: "window.LUMO_CALL=\(js);")
        w.loadHTMLString(html, baseURL: URL(string: "https://lumomess.ru/"))
        return w
    }

    func updateUIView(_ v: WKWebView, context: Context) {}

    static func dismantleUIView(_ v: WKWebView, coordinator: Coord) {
        v.evaluateJavaScript("window.GCall&&GCall.leave&&GCall.leave()")
        v.configuration.userContentController.removeScriptMessageHandler(forName: "lumo")
    }

    final class Coord: NSObject, WKScriptMessageHandler, WKUIDelegate {
        let onLeave: () -> Void
        init(_ f: @escaping () -> Void) { onLeave = f }
        func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
            if (m.body as? String) == "leave" { DispatchQueue.main.async { self.onLeave() } }
        }
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
}

/// Спросить доступ к микрофону (и камере для видео) до входа в звонок
enum AVAudioApplicationPermission {
    static func ask(video: Bool) async -> Bool {
        let mic = await withCheckedContinuation { c in AVAudioSession.sharedInstance().requestRecordPermission { c.resume(returning: $0) } }
        if !mic { await MainActor.run { AppModel.shared.say("Разрешите доступ к микрофону в Настройках") }; return false }
        if video { _ = await AVCaptureDevice.requestAccess(for: .video) }
        return true
    }
}
