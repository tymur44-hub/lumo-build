import SwiftUI
import UIKit

/// Защита от скриншотов и записи экрана: содержимое лежит внутри «защищённого» слоя поля пароля,
/// который система не попадает на снимок — вместо переписки на скриншоте пустое место.
struct ScreenShield<Content: View>: UIViewRepresentable {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    func makeUIView(context: Context) -> ShieldView<Content> { ShieldView(content) }
    func updateUIView(_ v: ShieldView<Content>, context: Context) { v.host.rootView = content }
}

final class ShieldView<Content: View>: UIView {
    let host: UIHostingController<Content>
    private let field = UITextField()
    private var canvas: UIView?

    init(_ c: Content) {
        host = UIHostingController(rootView: c)
        super.init(frame: .zero)
        backgroundColor = .clear
        field.isSecureTextEntry = true
        field.backgroundColor = .clear
        addSubview(field)
        field.layoutIfNeeded()
        // внутри поля пароля есть слой, скрытый от снимков экрана
        let cv = field.subviews.first(where: { String(describing: type(of: $0)).contains("Canvas") }) ?? field.subviews.first
        canvas = cv
        host.view.backgroundColor = .clear
        (cv ?? self).addSubview(host.view)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        field.frame = bounds
        canvas?.frame = bounds
        host.view.frame = bounds
    }

    // нажатия отдаём сразу содержимому, минуя поле
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let p = convert(point, to: host.view)
        return host.view.hitTest(p, with: event)
    }
}
