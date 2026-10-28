import UIKit
import AVFoundation
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var web: WebViewController?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // звук видео и голосовых слышен даже при беззвучном режиме; музыку других приложений не останавливаем
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        LumoNotifier.shared.setup()

        let vc = WebViewController()
        web = vc
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.backgroundColor = WebViewController.background
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        BackgroundKeeper.shared.stop()
        LumoNotifier.shared.setBadge(0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        web?.syncDevice()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        LumoNotifier.shared.markSeen()
        LumoNotifier.shared.scheduleRefresh()
        // свёрнутое приложение не засыпает и само проверяет новые сообщения
        if LumoNotifier.shared.isRegistered { BackgroundKeeper.shared.start() }
    }
}
