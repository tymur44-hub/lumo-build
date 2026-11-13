import SwiftUI
import UIKit

enum Theme {
    static let gold = Color(red: 0.84, green: 0.66, blue: 0.30)
    static let goldLight = Color(red: 0.96, green: 0.82, blue: 0.52)
    static let goldDeep = Color(red: 0.66, green: 0.47, blue: 0.17)
    static let background = Color(red: 0.047, green: 0.043, blue: 0.037)
    static let card = Color(red: 0.098, green: 0.090, blue: 0.078)
    static let cardRaised = Color(red: 0.135, green: 0.124, blue: 0.106)
    static let danger = Color(red: 0.95, green: 0.42, blue: 0.36)
    static let success = Color(red: 0.40, green: 0.82, blue: 0.55)
    static let stroke = Color.white.opacity(0.07)

    static let goldGradient = LinearGradient(
        colors: [goldLight, gold, goldDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.82)
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
}

/// Цвета отчёта: тёмные для экрана, светлые для PDF.
struct Palette {
    let background: Color
    let card: Color
    let text: Color
    let secondary: Color
    let stroke: Color
    /// В PDF анимации выключены: всё сразу в конечном состоянии.
    let animated: Bool

    static let app = Palette(
        background: Theme.background,
        card: Theme.card,
        text: .white,
        secondary: Color.white.opacity(0.58),
        stroke: Theme.stroke,
        animated: true)

    static let print = Palette(
        background: .white,
        card: Color(white: 0.96),
        text: .black,
        secondary: Color(white: 0.4),
        stroke: Color(white: 0.88),
        animated: false)
}

// MARK: - Форматирование

enum Fmt {
    static let ru = Locale(identifier: "ru_RU")

    private static let money: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = ru
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f
    }()

    private static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = ru
        f.groupingSeparator = " "
        f.maximumFractionDigits = 1
        return f
    }()

    private static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = ru
        f.dateFormat = "d MMM"
        return f
    }()

    private static let dayMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = ru
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = ru
        f.unitsStyle = .full
        return f
    }()

    static func rub(_ v: Double) -> String {
        (money.string(from: NSNumber(value: v.rounded())) ?? "0") + " ₽"
    }

    static func num(_ v: Double) -> String {
        decimal.string(from: NSNumber(value: v)) ?? "0"
    }

    static func int(_ v: Double) -> String {
        money.string(from: NSNumber(value: v.rounded())) ?? "0"
    }

    static func pct(_ v: Double) -> String {
        "\(Int((v * 100).rounded()))%"
    }

    static func compact(_ v: Double) -> String {
        let a = abs(v)
        if a >= 1_000_000 { return num(v / 1_000_000) + " млн" }
        if a >= 1_000 { return num((v / 1_000).rounded()) + " тыс" }
        return num(v.rounded())
    }

    static func day(_ d: Date) -> String { dayMonth.string(from: d) }

    static func ago(_ d: Date) -> String { relative.localizedString(for: d, relativeTo: Date()) }

    static func period(_ a: Date, _ b: Date) -> String {
        if Calendar.current.isDate(a, inSameDayAs: b) { return dayMonthYear.string(from: a) }
        return "\(dayMonth.string(from: a)) – \(dayMonthYear.string(from: b))"
    }
}

// MARK: - Тактильный отклик

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Кнопки и карточки

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.goldGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    .blendMode(.overlay))
            .shadow(color: Theme.gold.opacity(configuration.isPressed ? 0.15 : 0.35), radius: configuration.isPressed ? 6 : 16, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.cardRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.stroke))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}

extension View {
    func card(_ palette: Palette = .app, radius: CGFloat = 22, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(palette.stroke))
    }

    /// Плавное появление снизу с задержкой по номеру.
    func appear(_ index: Int = 0, enabled: Bool = true) -> some View {
        modifier(AppearModifier(index: index, enabled: enabled))
    }
}

struct AppearModifier: ViewModifier {
    let index: Int
    let enabled: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        let visible = shown || !enabled
        return content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 22)
            .scaleEffect(visible ? 1 : 0.97, anchor: .top)
            .onAppear {
                guard enabled, !shown else { return }
                withAnimation(Theme.spring.delay(Double(min(index, 12)) * 0.06)) { shown = true }
            }
    }
}
