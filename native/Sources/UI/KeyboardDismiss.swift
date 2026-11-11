import UIKit

/// Клавиатура убирается касанием любого места экрана.
/// Не срабатывает на самих полях ввода и на строке ввода сообщения прямо над клавиатурой
/// (там кнопки «Отправить», вложения и т.п. — клавиатура должна оставаться).
final class KeyboardDismiss: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismiss()
    private var keyboardTop: CGFloat = .infinity
    private var installed = Set<ObjectIdentifier>()
    private var observing = false

    func install() {
        if !observing {
            observing = true
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] n in
                guard let f = (n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                self?.keyboardTop = f.minY >= UIScreen.main.bounds.height - 1 ? .infinity : f.minY
                self?.install()   // новые окна (листы, полноэкранные экраны)
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
                self?.keyboardTop = .infinity
            }
        }
        for w in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
            let id = ObjectIdentifier(w)
            if installed.contains(id) { continue }
            installed.insert(id)
            let g = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            g.cancelsTouchesInView = false
            g.delaysTouchesEnded = false
            g.delegate = self
            w.addGestureRecognizer(g)
        }
    }

    @objc private func tap(_ g: UITapGestureRecognizer) {
        g.view?.endEditing(true)
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard keyboardTop.isFinite, let w = g.view else { return false }
        // строка ввода над клавиатурой
        let y = touch.location(in: nil).y
        if y > keyboardTop - 120 { return false }
        // касание самого поля ввода
        var v: UIView? = touch.view
        while let x = v, x !== w {
            if x is UITextField || x is UITextView || x is UISearchBar { return false }
            v = x.superview
        }
        return true
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}
