import SwiftUI
import UIKit
import UserNotifications
import AVFoundation

@main
struct LumoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel.shared
    @StateObject private var calls = CallManager.shared
    @StateObject private var look = Appearance.shared
    @Environment(\.scenePhase) private var phase
    @AppStorage("lm_lang") private var lang = "ru"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(calls)
                .environmentObject(look)
                .preferredColorScheme(look.scheme)
                .environment(\.locale, Locale(identifier: lang))
                .tint(Theme.a1)
                .id("\(look.version)-\(lang)")
                .fullScreenCover(item: $model.miniApp) { MiniAppView(req: $0).environmentObject(model).environmentObject(look) }
                .onOpenURL { url in handle(url) }
                .overlay { LockOverlayView() }
        }
        .onChange(of: phase) { p in
            if p == .active { model.scenePhase(true); ExtraStore.shared.scene(active: true) }
            else if p == .background { model.scenePhase(false); ExtraStore.shared.scene(active: false) }
        }
    }

    private func handle(_ url: URL) {
        let s = url.absoluteString
        if let r = s.range(of: #"#@([a-zA-Z0-9_]{3,32})"#, options: .regularExpression) {
            let u = String(s[r].dropFirst(2))
            Task { await model.openByUsername(u) }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        _ = CallManager.shared
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: 0x13142a) : UIColor(hex: 0xffffff) }
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: 0xeef0ff) : UIColor(hex: 0x14163a) }]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        return true
    }

    // приложение открыто: в открытом чате уведомление не показываем, в остальных — баннер
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let chat = notification.request.content.userInfo["chat"] as? String
        Task { @MainActor in
            let open = AppModel.shared.openChatId
            // приложение открыто — короткий звук играет само приложение, баннер без системного звука
            let isCall = notification.request.identifier.hasPrefix("call-")
            completionHandler(chat != nil && chat == open && !isCall ? [] : isCall ? [.banner, .sound, .list] : [.banner, .list])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let chat = response.notification.request.content.userInfo["chat"] as? String
        Task { @MainActor in
            if let c = chat { AppModel.shared.open(c) }
            completionHandler()
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var calls: CallManager
    @ObservedObject private var phones = PhoneStore.shared
    @AppStorage("lm_perms_done") private var permsDone = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if model.loggedIn { MainView() } else { LoginView() }
            if model.loggedIn && phones.loaded && phones.status == "required" {
                PhoneAuthView(mode: .bind, required: true).transition(.opacity)
            }
            if !permsDone { PermissionsView { withAnimation { permsDone = true } }.transition(.opacity) }
            MiniNoteOverlay()
            if let t = model.toast {
                VStack {
                    Spacer()
                    Text(t)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .lumoGlass(Capsule())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.toast)
        .fullScreenCover(isPresented: $calls.showUI) { CallView().environmentObject(calls) }
        .modifier(E2ESheets())
        .sheet(isPresented: Binding(get: { model.loggedIn && phones.loaded && permsDone && !phones.reminderShown && (phones.status == "remind" || phones.status == "skipped") },
                                    set: { if !$0 { phones.reminderShown = true } })) { PhoneReminderSheet() }
        .task {
            if let d = ProcessInfo.processInfo.environment["LUMO_SNAPSHOT"] { model.loadDemo(d); return }
            await model.start()
        }
    }
}

/// iPad: правая часть — открытый чат или заглушка
struct ChatDetail: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack {
            if let id = model.path.last {
                ChatView(chatId: id).id(id)
            } else {
                ZStack {
                    Theme.chatBg.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 54)).foregroundColor(Theme.muted)
                        Text("Выберите чат, чтобы начать общение").font(.headline).foregroundColor(Theme.muted)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.horizontalSizeClass) private var hsc

    private var split: Bool { hsc == .regular && model.tab == .chats }

    private var tabBarVisible: Bool {
        switch model.tab {
        case .chats: return model.path.isEmpty
        case .contacts: return model.contactsPath.isEmpty
        case .settings: return model.settingsPath.isEmpty
        }
    }

    var body: some View {
        if split {
            HStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    ChatListView(sidebar: true)
                    FloatingTabBar(tab: $model.tab,
                                   chatsBadge: model.chats.filter { !$0.muted }.reduce(0) { $0 + $1.unread },
                                   settingsBadge: 0)
                        .padding(.bottom, 4)
                }
                .frame(width: 370)
                Rectangle().fill(Theme.line).frame(width: 1).ignoresSafeArea()
                ChatDetail()
            }
        } else {
            phoneBody
        }
    }

    private var phoneBody: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch model.tab {
                case .chats: ChatListView()
                case .contacts: ContactsView(path: $model.contactsPath)
                case .settings: SettingsView(path: $model.settingsPath)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if tabBarVisible {
                FloatingTabBar(tab: $model.tab,
                               chatsBadge: model.chats.filter { !$0.muted }.reduce(0) { $0 + $1.unread },
                               settingsBadge: 0)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: tabBarVisible)
    }
}
