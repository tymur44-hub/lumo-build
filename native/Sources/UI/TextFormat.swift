import SwiftUI
import UIKit

/// Форматирование текста при выделении в поле ввода (как в Telegram):
/// выделить текст → меню → «Форматировать» → Цитата, Скрытый, Жирный, Курсив, Моноширинный, Ссылка, Дата, Зачёркнутый.
/// Разметка та же, что на сайте: **жирный**, __курсив__, `моно`, ~~зачёркнутый~~, ||скрытый||, > цитата, [текст](ссылка), [текст](date:время).
enum TextFormat {
    /// Зоны, где меню включено (поле ввода сообщения). Хранятся слабые ссылки на маркерные виды.
    private static var zones = NSHashTable<UIView>.weakObjects()
    private static var started = false

    static func register(_ v: UIView) {
        zones.add(v)
        guard !started else { return }
        started = true
        NotificationCenter.default.addObserver(forName: UITextView.textDidBeginEditingNotification, object: nil, queue: .main) { n in
            guard let tv = n.object as? UITextView else { return }
            install(tv)
        }
    }

    private static func inZone(_ tv: UITextView) -> Bool {
        guard let w = tv.window else { return false }
        let r = tv.convert(tv.bounds, to: w)
        for z in zones.allObjects where z.window === w {
            if z.convert(z.bounds, to: w).insetBy(dx: -4, dy: -4).intersects(r) { return true }
        }
        return false
    }

    private static var proxyKey: UInt8 = 0
    static func install(_ tv: UITextView) {
        guard inZone(tv) else { return }
        if tv.delegate is FormatDelegateProxy { return }
        let p = FormatDelegateProxy()
        p.inner = tv.delegate
        objc_setAssociatedObject(tv, &proxyKey, p, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        tv.delegate = p
    }

    // MARK: меню

    static func menu(_ tv: UITextView, _ range: NSRange) -> UIMenu {
        func a(_ t: String, _ icon: String, _ f: @escaping () -> Void) -> UIAction {
            UIAction(title: t, image: UIImage(systemName: icon)) { _ in f() }
        }
        let items: [UIMenuElement] = [
            a("Цитата", "text.quote") { quote(tv, range) },
            a("Скрытый", "eye.slash") { wrap(tv, range, "||", "||") },
            a("Жирный", "bold") { wrap(tv, range, "**", "**") },
            a("Курсив", "italic") { wrap(tv, range, "__", "__") },
            a("Моноширинный", "chevron.left.forwardslash.chevron.right") { wrap(tv, range, "`", "`") },
            a("Ссылка", "link") { askLink(tv, range) },
            a("Дата", "calendar") { askDate(tv, range) },
            a("Зачёркнутый", "strikethrough") { wrap(tv, range, "~~", "~~") },
        ]
        return UIMenu(title: "Форматировать", image: UIImage(systemName: "textformat"), children: items)
    }

    // MARK: правка текста через UITextInput — так SwiftUI получает изменения как обычный ввод

    private static func replace(_ tv: UITextView, _ range: NSRange, _ s: String, select: NSRange?) {
        guard let st = tv.position(from: tv.beginningOfDocument, offset: range.location),
              let en = tv.position(from: st, offset: range.length),
              let tr = tv.textRange(from: st, to: en) else { return }
        tv.replace(tr, withText: s)
        if let sel = select { tv.selectedRange = sel }
        tv.delegate?.textViewDidChange?(tv)
    }

    static func wrap(_ tv: UITextView, _ range: NSRange, _ l: String, _ r: String) {
        let ns = (tv.text ?? "") as NSString
        guard range.location + range.length <= ns.length else { return }
        let sel = ns.substring(with: range)
        let ll = (l as NSString).length, rl = (r as NSString).length
        // уже размечено — снять разметку
        if range.location >= ll, range.location + range.length + rl <= ns.length,
           ns.substring(with: NSRange(location: range.location - ll, length: ll)) == l,
           ns.substring(with: NSRange(location: range.location + range.length, length: rl)) == r {
            replace(tv, NSRange(location: range.location - ll, length: range.length + ll + rl), sel,
                    select: NSRange(location: range.location - ll, length: range.length))
            return
        }
        if sel.hasPrefix(l), sel.hasSuffix(r), (sel as NSString).length >= ll + rl {
            let inner = (sel as NSString).substring(with: NSRange(location: ll, length: (sel as NSString).length - ll - rl))
            replace(tv, range, inner, select: NSRange(location: range.location, length: (inner as NSString).length))
            return
        }
        // пробелы по краям выделения оставляем снаружи разметки
        let trimmed = sel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let tr = sel.range(of: trimmed) else { return }
        let lead = String(sel[sel.startIndex..<tr.lowerBound]), trail = String(sel[tr.upperBound...])
        let out = lead + l + trimmed + r + trail
        replace(tv, range, out, select: NSRange(location: range.location + (lead as NSString).length + ll, length: (trimmed as NSString).length))
    }

    static func quote(_ tv: UITextView, _ range: NSRange) {
        let ns = (tv.text ?? "") as NSString
        guard range.location + range.length <= ns.length else { return }
        let sel = ns.substring(with: range).trimmingCharacters(in: .newlines)
        let lines = sel.components(separatedBy: "\n")
        if lines.allSatisfy({ $0.hasPrefix("> ") }) {
            let plain = lines.map { String($0.dropFirst(2)) }.joined(separator: "\n")
            replace(tv, range, plain, select: NSRange(location: range.location, length: (plain as NSString).length))
            return
        }
        let body = lines.map { "> " + $0 }.joined(separator: "\n")
        let before = range.location > 0 && ns.character(at: range.location - 1) != 10 ? "\n" : ""
        let endAt = range.location + range.length
        let after = endAt < ns.length && ns.character(at: endAt) != 10 ? "\n" : ""
        replace(tv, range, before + body + after, select: NSRange(location: range.location + (before as NSString).length, length: (body as NSString).length))
    }

    private static func top(_ tv: UITextView) -> UIViewController? {
        var vc = tv.window?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }

    static func askLink(_ tv: UITextView, _ range: NSRange) {
        let ns = (tv.text ?? "") as NSString
        guard range.location + range.length <= ns.length else { return }
        let sel = ns.substring(with: range)
        let al = UIAlertController(title: "Ссылка", message: "Текст «\(sel.prefix(40))» станет ссылкой", preferredStyle: .alert)
        al.addTextField { f in
            f.placeholder = "https://"
            f.keyboardType = .URL; f.autocapitalizationType = .none; f.autocorrectionType = .no
            if let s = UIPasteboard.general.string, s.hasPrefix("http") { f.text = s }
        }
        al.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        al.addAction(UIAlertAction(title: "Готово", style: .default) { _ in
            var u = (al.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespaces)
            guard !u.isEmpty else { return }
            if !u.contains("://") && !u.hasPrefix("mailto:") && !u.hasPrefix("tel:") { u = "https://" + u }
            let safe = sel.replacingOccurrences(of: "[", with: "(").replacingOccurrences(of: "]", with: ")")
            let out = "[\(safe)](\(u.replacingOccurrences(of: ")", with: "%29").replacingOccurrences(of: " ", with: "%20")))"
            tv.becomeFirstResponder()
            replace(tv, range, out, select: NSRange(location: range.location + (out as NSString).length, length: 0))
        })
        top(tv)?.present(al, animated: true)
    }

    static func askDate(_ tv: UITextView, _ range: NSRange) {
        let ns = (tv.text ?? "") as NSString
        guard range.location + range.length <= ns.length else { return }
        let sel = ns.substring(with: range)
        let vc = DatePickVC()
        vc.onDone = { d in
            let safe = sel.replacingOccurrences(of: "[", with: "(").replacingOccurrences(of: "]", with: ")")
            let out = "[\(safe)](date:\(Int(d.timeIntervalSince1970)))"
            tv.becomeFirstResponder()
            replace(tv, range, out, select: NSRange(location: range.location + (out as NSString).length, length: 0))
        }
        let nav = UINavigationController(rootViewController: vc)
        if let s = nav.sheetPresentationController { s.detents = [.medium(), .large()]; s.prefersGrabberVisible = true }
        top(tv)?.present(nav, animated: true)
    }

    /// дата для показа: «суббота, 15 ноября 2026 г. в 18:00» — у каждого в его часовом поясе
    static func dateText(_ ts: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: Lang.current == "en" ? "en_US" : "ru_RU")
        f.dateStyle = .full; f.timeStyle = .short
        return f.string(from: Date(timeIntervalSince1970: TimeInterval(ts)))
    }
}

private final class DatePickVC: UIViewController {
    var onDone: ((Date) -> Void)?
    private let picker = UIDatePicker()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Дата"
        view.backgroundColor = .systemBackground
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale(identifier: Lang.current == "en" ? "en_US" : "ru_RU")
        picker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            picker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            picker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Отмена", style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(done))
    }
    @objc private func cancel() { dismiss(animated: true) }
    @objc private func done() { let d = picker.date; dismiss(animated: true) { self.onDone?(d) } }
}

/// Делегат-посредник: всё пересылает делегату SwiftUI и добавляет пункт «Форматировать» в меню выделенного текста
final class FormatDelegateProxy: NSObject, UITextViewDelegate {
    weak var inner: UITextViewDelegate?

    override func responds(to s: Selector!) -> Bool {
        super.responds(to: s) || (inner?.responds(to: s) ?? false)
    }
    override func forwardingTarget(for s: Selector!) -> Any? {
        (inner?.responds(to: s) ?? false) ? inner : nil
    }

    func textView(_ tv: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var acts = suggestedActions
        if let m = inner?.textView?(tv, editMenuForTextIn: range, suggestedActions: suggestedActions) { acts = m.children }
        guard range.length > 0 else { return UIMenu(children: acts) }
        let f = TextFormat.menu(tv, range)
        acts.insert(f, at: min(1, acts.count))
        return UIMenu(children: acts)
    }
}

/// Маркер зоны, где включено форматирование (ставится фоном у поля ввода)
struct FormatZone: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView(); v.isUserInteractionEnabled = false; v.backgroundColor = .clear
        TextFormat.register(v)
        return v
    }
    func updateUIView(_ v: UIView, context: Context) {}
}

/// Открытые «скрытые» фрагменты (по нажатию)
final class SpoilerState: ObservableObject {
    static let shared = SpoilerState()
    @Published var open: Set<String> = []
}

/// Поле ввода сообщения на UITextView: растёт до 6 строк, а в меню выделенного текста есть «Форматировать»
struct ComposerField: UIViewRepresentable {
    @Binding var text: String
    @Binding var focused: Bool
    var placeholder: String
    var textColor: UIColor
    var tint: UIColor
    var placeholderColor: UIColor
    var font: UIFont = .systemFont(ofSize: 16)
    var maxLines: CGFloat = 6

    func makeCoordinator() -> Coord { Coord(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.font = font
        tv.textContainerInset = UIEdgeInsets(top: 11, left: 0, bottom: 11, right: 0)
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = false
        tv.text = text
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultHigh, for: .vertical)
        let ph = UILabel()
        ph.font = font
        ph.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(ph)
        NSLayoutConstraint.activate([
            ph.leadingAnchor.constraint(equalTo: tv.leadingAnchor),
            ph.topAnchor.constraint(equalTo: tv.topAnchor, constant: 11),
        ])
        context.coordinator.ph = ph
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.parent = self
        if tv.markedTextRange == nil && tv.text != text { tv.text = text }
        tv.textColor = textColor
        tv.tintColor = tint
        context.coordinator.ph?.text = placeholder
        context.coordinator.ph?.textColor = placeholderColor
        context.coordinator.ph?.isHidden = !text.isEmpty
        if focused && !tv.isFirstResponder && tv.window != nil {
            DispatchQueue.main.async { if self.focused { tv.becomeFirstResponder() } }
        } else if !focused && tv.isFirstResponder {
            DispatchQueue.main.async { if !self.focused { tv.resignFirstResponder() } }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView tv: UITextView, context: Context) -> CGSize? {
        let w = proposal.width ?? UIScreen.main.bounds.width - 120
        let fit = tv.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude)).height
        let maxH = (font.lineHeight * maxLines).rounded(.up) + 22
        let h = min(max(fit, font.lineHeight.rounded(.up) + 22), maxH)
        let scroll = fit > maxH
        if tv.isScrollEnabled != scroll { DispatchQueue.main.async { tv.isScrollEnabled = scroll } }
        return CGSize(width: w, height: h)
    }

    final class Coord: NSObject, UITextViewDelegate {
        var parent: ComposerField
        weak var ph: UILabel?
        init(_ p: ComposerField) { parent = p }

        func textViewDidChange(_ tv: UITextView) {
            ph?.isHidden = !tv.text.isEmpty
            if parent.text != tv.text { parent.text = tv.text }
        }
        func textViewDidBeginEditing(_ tv: UITextView) {
            if !parent.focused { DispatchQueue.main.async { self.parent.focused = true } }
        }
        func textViewDidEndEditing(_ tv: UITextView) {
            if parent.focused { DispatchQueue.main.async { self.parent.focused = false } }
        }
        func textView(_ tv: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            guard range.length > 0 else { return nil }
            var acts = suggestedActions
            acts.insert(TextFormat.menu(tv, range), at: min(1, acts.count))
            return UIMenu(children: acts)
        }
    }
}
