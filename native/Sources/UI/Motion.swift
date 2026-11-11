import SwiftUI
import UIKit

/// «Живые» движения как в Telegram: быстрые пружины вместо медленных плавных анимаций
enum Motion {
    /// основная: быстро и с лёгкой упругостью
    static let snappy = Animation.spring(response: 0.26, dampingFraction: 0.82)
    /// для появления элементов — чуть заметнее пружинит
    static let bouncy = Animation.spring(response: 0.32, dampingFraction: 0.7)
}

/// Свайп «назад» с любого места экрана (как в Telegram), а не только от края.
/// Работает и на экранах со спрятанной панелью навигации.
final class FullSwipeBack: NSObject, UIGestureRecognizerDelegate {
    static let shared = FullSwipeBack()
    private var installed = Set<ObjectIdentifier>()

    func install(on nav: UINavigationController) {
        let key = ObjectIdentifier(nav)
        guard let edge = nav.interactivePopGestureRecognizer else { return }
        // SwiftUI при скрытой верхней панели сам выключает свайп назад и меняет делегата — каждый раз возвращаем
        edge.isEnabled = true
        edge.delegate = self
        guard !installed.contains(key), let targets = edge.value(forKey: "targets") as? NSArray else { return }
        installed.insert(key)
        let pan = UIPanGestureRecognizer()
        pan.setValue(targets, forKey: "targets")
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        nav.view.addGestureRecognizer(pan)
    }

    func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        guard let nav = navController(of: g.view), nav.viewControllers.count > 1, nav.transitionCoordinator == nil else { return false }
        if let pan = g as? UIPanGestureRecognizer, !(g is UIScreenEdgePanGestureRecognizer) {
            let v = pan.velocity(in: pan.view), t = pan.translation(in: pan.view)
            // только движение вправо и явно горизонтальное — прокрутка и свайп «ответить» не мешают
            guard v.x > 0, abs(v.x) > abs(v.y) * 1.4, t.x >= 0 else { return false }
            // не трогаем горизонтальные ленты (альбомы, истории, ползунки)
            let p = pan.location(in: pan.view)
            if let hit = pan.view?.hitTest(p, with: nil), blocksSwipe(hit) { return false }
        }
        return true
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool { false }

    private func blocksSwipe(_ v: UIView) -> Bool {
        var cur: UIView? = v
        while let c = cur {
            if c is UISlider { return true }
            if let s = c as? UIScrollView, s.contentSize.width > s.bounds.width + 1, s.contentOffset.x > 1 { return true }
            cur = c.superview
        }
        return false
    }

    private func navController(of v: UIView?) -> UINavigationController? {
        var r: UIResponder? = v
        while let x = r { if let n = x as? UINavigationController { return n }; r = x.next }
        return nil
    }
}

/// Невидимая вставка: находит стек навигации и включает на нём свайп назад с любого места
struct SwipeBackInstaller: UIViewControllerRepresentable {
    final class VC: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            reinstall()
            // SwiftUI может переставить делегата чуть позже появления экрана
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.reinstall() }
        }
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reinstall()
        }
        private func reinstall() { if let n = navigationController { FullSwipeBack.shared.install(on: n) } }
    }
    func makeUIViewController(context: Context) -> VC { let v = VC(); v.view.isUserInteractionEnabled = false; return v }
    func updateUIViewController(_ v: VC, context: Context) {}
}

extension Notification.Name {
    /// нажали «Чаты» на нижней панели — прокрутить список чатов наверх
    static let lumoChatsTop = Notification.Name("lumoChatsTop")
}
