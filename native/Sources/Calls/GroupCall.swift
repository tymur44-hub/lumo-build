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
    var chatId = ""
    var auth = ""
}

/// Приглашение в групповой звонок
struct GroupCallInvite: Identifiable, Equatable {
    let id = UUID()
    let chatId: String
    let title: String
    let avatar: String?
    let color: Int
    let from: String
    let names: [String]
    static func == (a: Self, b: Self) -> Bool { a.id == b.id }
}

/// Приглашения приходят по каналу lm-gc-<мой id>; окно звонка и входящее приглашение показываются поверх всего приложения
@MainActor
final class GroupCalls: ObservableObject {
    static let shared = GroupCalls()
    @Published var current: GroupCallInfo?
    @Published var invite: GroupCallInvite?
    private var uid: String?

    func attach(_ id: String) {
        guard uid != id else { return }
        if let o = uid { Realtime.shared.leave("lm-gc-" + o) }
        uid = id
        let ch = Realtime.shared.channel("lm-gc-" + id)
        ch.onBroadcast = { [weak self] event, p in
            // Premium выдали или продлили — обновляем профиль сразу, без перезапуска
            if event == "premium" {
                Task { @MainActor in
                    let was = AppModel.shared.isPremium
                    await AppModel.shared.loadMe()
                    if !was && AppModel.shared.isPremium { AppModel.shared.say("Lumo Premium активирован") }
                }
                return
            }
            guard event == "invite" else { return }
            Task { @MainActor in
                guard let self, self.current == nil, let chat = p.str("chat_id") else { return }
                self.invite = GroupCallInvite(chatId: chat, title: p.str("title") ?? "Группа", avatar: p.str("avatar"), color: p.int("color") ?? 0,
                                              from: p.str("from") ?? "Участник", names: (p["names"] as? [String]) ?? [])
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    func start(_ chatId: String, video: Bool, join: Bool = false) async {
        guard current == nil else { return }
        let ok = await AVAudioApplicationPermission.ask(video: video)
        guard ok, let info = await AppModel.shared.groupCall(chatId, video: video, join: join) else { return }
        current = info
    }
}

extension AppModel {
    func groupCall(_ chatId: String, video: Bool, join: Bool = false) async -> GroupCallInfo? {
        do {
            let r = try await API.shared.raw("POST", "/functions/v1/lumo-lk", body: ["chat_id": chatId, "action": join ? "join" : "start"]) as? JSON ?? [:]
            if let e = r.str("error") { say(e); return nil }
            guard let u = r.str("url"), let t = r.str("token") else { say("Не удалось начать звонок"); return nil }
            let auth = (try? await API.shared.validToken()) ?? ""
            return GroupCallInfo(url: u, token: t, title: chat(chatId)?.displayName ?? "Групповой звонок", video: video, chatId: chatId, auth: auth)
        } catch { say(error.localizedDescription); return nil }
    }

    /// режим звонков в группе: all / admins / off; второе значение — можно ли мне начать звонок, третье — я админ
    func groupCallMode(_ chatId: String) async -> (String, Bool, Bool) {
        let r = (try? await API.shared.raw("POST", "/functions/v1/lumo-lk", body: ["chat_id": chatId, "action": "status"])) as? JSON ?? [:]
        return (r.str("mode") ?? "all", r.bool("can_start") || r["can_start"] == nil, r.bool("admin"))
    }

    func setGroupCallMode(_ chatId: String, _ mode: String) async -> Bool {
        do { _ = try await API.shared.rpc("lm_set_group_calls", ["p_chat": chatId, "p_mode": mode]); return true }
        catch { say(error.localizedDescription); return false }
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
        let conf: [String: Any] = ["url": info.url, "token": info.token, "title": info.title, "video": info.video,
                                   "chat_id": info.chatId, "auth": info.auth, "apikey": Config.anonKey,
                                   "fn": Net.base + "/functions/v1/lumo-lk"]
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


/// Окно звонка и входящее приглашение поверх всего приложения
struct GroupCallHostModifier: ViewModifier {
    @ObservedObject private var gc = GroupCalls.shared
    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $gc.current) { GroupCallScreen(info: $0) }
            .overlay {
                if let inv = gc.invite {
                    IncomingGroupCallView(inv: inv)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(50)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.86), value: gc.invite)
    }
}

/// «Входящий групповой звонок»: кто приглашает, кто уже в звонке, «Отклонить» и «Присоединиться»
struct IncomingGroupCallView: View {
    let inv: GroupCallInvite
    @ObservedObject private var gc = GroupCalls.shared
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1b2a4a), Color(hex: 0x0b0b10)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 14) {
                Spacer()
                ZStack {
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 2).frame(width: 150, height: 150)
                        .scaleEffect(pulse ? 1.25 : 0.95).opacity(pulse ? 0 : 1)
                    AvatarView(name: inv.title, url: inv.avatar, color: inv.color, size: 120)
                }
                Text(inv.title).font(.system(size: 28, weight: .bold)).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 24)
                Text("Входящий групповой звонок").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
                Text("\(inv.from) приглашает вас").font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.9))
                if !inv.names.isEmpty {
                    VStack(spacing: 6) {
                        Text("УЖЕ В ЗВОНКЕ").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.55))
                        Text(inv.names.prefix(6).joined(separator: ", ") + (inv.names.count > 6 ? " и ещё \(inv.names.count - 6)" : ""))
                            .font(.system(size: 15)).foregroundColor(.white).multilineTextAlignment(.center)
                    }
                    .padding(14).frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
                    .padding(.horizontal, 28).padding(.top, 6)
                }
                Spacer()
                HStack(spacing: 70) {
                    VStack(spacing: 8) {
                        Button { gc.invite = nil } label: {
                            Image(systemName: "phone.down.fill").font(.system(size: 28)).foregroundColor(.white)
                                .frame(width: 74, height: 74).background(Circle().fill(Color(hex: 0xff3b30)))
                        }.buttonStyle(BouncyButtonStyle())
                        Text("Отклонить").font(.system(size: 14)).foregroundColor(.white.opacity(0.85))
                    }
                    VStack(spacing: 8) {
                        Button {
                            let c = inv.chatId
                            gc.invite = nil
                            Task { await gc.start(c, video: false, join: true) }
                        } label: {
                            Image(systemName: "phone.fill").font(.system(size: 28)).foregroundColor(.white)
                                .frame(width: 74, height: 74).background(Circle().fill(Color(hex: 0x34c759)))
                        }.buttonStyle(BouncyButtonStyle())
                        Text("Присоединиться").font(.system(size: 14)).foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
            let id = inv.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 45) { if gc.invite?.id == id { gc.invite = nil } }
        }
    }
}

/// Настройка «Кто может начинать групповые звонки» в группе
struct GroupCallModeSection: View {
    @EnvironmentObject var model: AppModel
    let chatId: String
    var showLoading = false
    @State private var mode = "all"
    @State private var admin = false
    @State private var loaded = false

    var body: some View {
        Group {
            if loaded && admin {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ГРУППОВЫЕ ЗВОНКИ").font(.system(size: 12.5, weight: .medium)).foregroundColor(Theme.muted).padding(.leading, 16)
                    VStack(spacing: 0) {
                        row("all", "Все могут начать звонок")
                        Divider().overlay(Theme.line).padding(.leading, 16)
                        row("admins", "Только администраторы начинают")
                        Divider().overlay(Theme.line).padding(.leading, 16)
                        row("off", "Звонки отключены")
                    }
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                    Text(mode == "admins" ? "Участники смогут присоединиться, когда звонок начнёт администратор." : mode == "off" ? "Никто не сможет звонить в этой группе." : "Любой участник может начать звонок.")
                        .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 16)
                }
                .padding(.horizontal, 14)
            } else if loaded {
                Text("Настройки звонков может менять только владелец или администратор группы.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 30)
            } else if showLoading {
                ProgressView().tint(Theme.muted).frame(maxWidth: .infinity).padding(.vertical, 20)
            }
        }
        .task {
            let r = await model.groupCallMode(chatId)
            mode = r.0; admin = r.2; loaded = true
        }
    }

    private func row(_ k: String, _ t: String) -> some View {
        Button {
            let old = mode
            withAnimation { mode = k }
            Task { if !(await model.setGroupCallMode(chatId, k)) { mode = old } }
        } label: {
            HStack {
                Text(t).foregroundColor(Theme.text)
                Spacer()
                if mode == k { Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.a1) }
            }
            .padding(.horizontal, 16).frame(height: 48).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


/// Отдельный экран «Групповые звонки» — открывается из профиля группы
struct GroupCallSettingsSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Групповые звонки").font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                            .frame(width: 40, height: 40).background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 14)
            ScrollView { GroupCallModeSection(chatId: chatId, showLoading: true).padding(.top, 6) }
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
