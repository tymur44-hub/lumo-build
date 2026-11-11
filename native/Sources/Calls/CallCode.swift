import SwiftUI
import CryptoKit
import UIKit

/// Код проверки звонка, как в Telegram: из ключей шифрования обоих телефонов (отпечатки DTLS в SDP)
/// получаются четыре значка. Одинаковые у обоих собеседников — значит, посередине никого нет.
/// Тот же алгоритм на iOS, Android и в веб-версии.
struct CallIcon { let name: String; let symbol: String; let a: UInt32; let b: UInt32 }

enum CallCode {
    static let icons: [CallIcon] = [
        CallIcon(name: "Звезда", symbol: "star.fill", a: 0xFFC93C, b: 0xFF8A00),
        CallIcon(name: "Сердце", symbol: "heart.fill", a: 0xFF5A7A, b: 0xE0245E),
        CallIcon(name: "Луна", symbol: "moon.fill", a: 0x8E8CFF, b: 0x5B4BDB),
        CallIcon(name: "Солнце", symbol: "sun.max.fill", a: 0xFFB703, b: 0xFB8500),
        CallIcon(name: "Молния", symbol: "bolt.fill", a: 0xFFE066, b: 0xF4A100),
        CallIcon(name: "Лист", symbol: "leaf.fill", a: 0x7BD88F, b: 0x2E9E5B),
        CallIcon(name: "Огонь", symbol: "flame.fill", a: 0xFF8A3D, b: 0xE63946),
        CallIcon(name: "Капля", symbol: "drop.fill", a: 0x5AC8FA, b: 0x1A73E8),
        CallIcon(name: "Снежинка", symbol: "snowflake", a: 0xA0E9FF, b: 0x4CA9E0),
        CallIcon(name: "Облако", symbol: "cloud.fill", a: 0xB8C6FF, b: 0x6C7FD8),
        CallIcon(name: "Самолёт", symbol: "airplane", a: 0x74C0FC, b: 0x3B82F6),
        CallIcon(name: "Ключ", symbol: "key.fill", a: 0xFFD166, b: 0xD4A017),
        CallIcon(name: "Колокол", symbol: "bell.fill", a: 0xFFB4A2, b: 0xE5737F),
        CallIcon(name: "Нота", symbol: "music.note", a: 0xC77DFF, b: 0x7B2CBF),
        CallIcon(name: "Камера", symbol: "camera.fill", a: 0x9AA5B1, b: 0x52606D),
        CallIcon(name: "Подарок", symbol: "gift.fill", a: 0xFF8FAB, b: 0xC9184A),
        CallIcon(name: "Флаг", symbol: "flag.fill", a: 0xFF6B6B, b: 0xC92A2A),
        CallIcon(name: "Планета", symbol: "globe", a: 0x63E6BE, b: 0x0CA678),
        CallIcon(name: "Лапа", symbol: "pawprint.fill", a: 0xE6A57E, b: 0xA0522D),
        CallIcon(name: "Машина", symbol: "car.fill", a: 0xFF922B, b: 0xD9480F),
        CallIcon(name: "Велосипед", symbol: "bicycle", a: 0x94D82D, b: 0x5C940D),
        CallIcon(name: "Дом", symbol: "house.fill", a: 0xF9A8D4, b: 0xDB2777),
        CallIcon(name: "Парусник", symbol: "sailboat.fill", a: 0x66D9E8, b: 0x1098AD),
        CallIcon(name: "Мяч", symbol: "soccerball", a: 0xCED4DA, b: 0x495057),
        CallIcon(name: "Кубок", symbol: "trophy.fill", a: 0xFCC419, b: 0xE67700),
        CallIcon(name: "Палитра", symbol: "paintpalette.fill", a: 0xDA77F2, b: 0x9C36B5),
        CallIcon(name: "Лампочка", symbol: "lightbulb.fill", a: 0xFFF3BF, b: 0xFAB005),
        CallIcon(name: "Зонт", symbol: "umbrella.fill", a: 0x91A7FF, b: 0x4263EB),
        CallIcon(name: "Компас", symbol: "safari.fill", a: 0x38D9A9, b: 0x087F5B),
        CallIcon(name: "Гора", symbol: "mountain.2.fill", a: 0xA9E34B, b: 0x2B8A3E),
        CallIcon(name: "Пазл", symbol: "puzzlepiece.fill", a: 0xFFA94D, b: 0xE8590C),
        CallIcon(name: "Дерево", symbol: "tree.fill", a: 0x8CE99A, b: 0x2F9E44)
    ]

    /// отпечатки ключей обоих сторон (порядок не важен) → 4 номера значков
    static func make(localSDP: String, remoteSDP: String) -> [Int]? {
        let fp = fingerprints(localSDP + "\n" + remoteSDP)
        guard fp.components(separatedBy: ",").count >= 2 else { return nil }
        let h = Array(SHA256.hash(data: Data(("lumo-callcode1|" + fp).utf8)))
        return (0..<4).map { Int(h[$0]) % icons.count }
    }

    static func fingerprints(_ s: String) -> String {
        guard let re = try? NSRegularExpression(pattern: #"a=fingerprint:(\S+) (\S+)"#, options: [.caseInsensitive]) else { return "" }
        let ns = s as NSString
        var set = Set<String>()
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            set.insert(ns.substring(with: m.range(at: 1)).lowercased() + " " + ns.substring(with: m.range(at: 2)).uppercased())
        }
        return set.sorted().joined(separator: ",")
    }
}

/// Один значок: цветной кружок-градиент с белым символом
struct CallIconView: View {
    let i: Int
    var size: CGFloat = 26
    var body: some View {
        let ic = CallCode.icons[i % CallCode.icons.count]
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(hex: ic.a), Color(hex: ic.b)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Color.white.opacity(0.35), lineWidth: max(1, size * 0.04))
            Image(systemName: ic.symbol).font(.system(size: size * 0.5, weight: .bold)).foregroundColor(.white)
                .shadow(color: .black.opacity(0.18), radius: size * 0.04, y: size * 0.03)
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: ic.b).opacity(0.45), radius: size * 0.18, y: size * 0.06)
    }
}

/// Маленькая плашка с кодом в звонке; нажатие — крупная карточка с объяснением
struct CallCodeBadge: View {
    let code: [Int]
    @State private var shown = false
    @State private var open = false
    var body: some View {
        Button {
            var t = Transaction(); t.disablesAnimations = true   // карточка появляется своей анимацией, без «выезда» снизу
            withTransaction(t) { open = true }
        } label: {
            HStack(spacing: 5) {
                ForEach(Array(code.enumerated()), id: \.offset) { k, i in
                    CallIconView(i: i, size: 24)
                        .scaleEffect(shown ? 1 : 0.2).opacity(shown ? 1 : 0)
                        .animation(.spring(response: 0.42, dampingFraction: 0.55).delay(Double(k) * 0.07), value: shown)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .environment(\.colorScheme, .dark)
        }
        .buttonStyle(BouncyButtonStyle())
        .onAppear { shown = true }
        .fullScreenCover(isPresented: $open) { CallCodeCard(code: code) { open = false } .background(ClearBackground()) }
    }
}

/// Крупная карточка: четыре значка с подписями и пояснение
struct CallCodeCard: View {
    let code: [Int]
    let close: () -> Void
    @State private var shown = false
    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.55 : 0).ignoresSafeArea().onTapGesture { dismiss() }
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    ForEach(Array(code.enumerated()), id: \.offset) { k, i in
                        VStack(spacing: 7) {
                            CallIconView(i: i, size: 58)
                            Text(CallCode.icons[i].name).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(width: 66)
                        .scaleEffect(shown ? 1 : 0.3).opacity(shown ? 1 : 0)
                        .rotationEffect(.degrees(shown ? 0 : -25))
                        .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.08 + Double(k) * 0.08), value: shown)
                    }
                }
                Text("Звонок зашифрован").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("Если у собеседника на экране те же четыре значка, разговор защищён сквозным шифрованием и никто посередине его не слышит.")
                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
                Button("Понятно") { dismiss() }
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                    .buttonStyle(BouncyButtonStyle())
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial))
            .environment(\.colorScheme, .dark)
            .padding(.horizontal, 22)
            .scaleEffect(shown ? 1 : 0.85).opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { shown = true }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { close() }
        }
    }
}

/// прозрачный фон для fullScreenCover
struct ClearBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        DispatchQueue.main.async { v.superview?.superview?.backgroundColor = .clear }
        return v
    }
    func updateUIView(_ v: UIView, context: Context) {}
}
