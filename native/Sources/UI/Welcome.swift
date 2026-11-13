import SwiftUI

/// Приветствие перед вводом номера: появляется плавно, по очереди
struct WelcomeView: View {
    var onContinue: () -> Void
    @State private var logo = false
    @State private var title = false
    @State private var rows = [false, false, false]
    @State private var button = false
    @State private var float = false
    @State private var pulse = false
    @State private var agree = false
    @State private var warn = false

    private let items: [(String, String, String)] = [
        ("bolt.fill", "Быстрые сообщения", "Доставляются мгновенно и без лишних шагов"),
        ("video.fill", "Звонки и видеосообщения", "Голос, видео и кружки — всё в одном месте"),
        ("lock.shield.fill", "Вход без паролей", "Только номер телефона и код")
    ]

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.5, speed: 0.6, base: Theme.bg, dim: 0).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 30)
                ZStack {
                    Circle().stroke(Theme.a1.opacity(pulse ? 0 : 0.45), lineWidth: 3)
                        .frame(width: 104, height: 104).scaleEffect(pulse ? 1.9 : 1)
                    Image("LaunchLogo").resizable().scaledToFit().frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: Theme.a1.opacity(0.45), radius: 22, y: 10)
                }
                .scaleEffect(logo ? 1 : 0.4).opacity(logo ? 1 : 0)
                .offset(y: float ? -6 : 6)
                Text("Добро пожаловать\nв Lumo").font(.system(size: 32, weight: .heavy)).multilineTextAlignment(.center)
                    .foregroundColor(Theme.text).padding(.top, 26)
                    .opacity(title ? 1 : 0).offset(y: title ? 0 : 16)
                Text("Быстрый и красивый мессенджер, в котором приятно общаться").font(.system(size: 16))
                    .foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.top, 10).padding(.horizontal, 30)
                    .opacity(title ? 1 : 0).offset(y: title ? 0 : 16)
                VStack(spacing: 14) {
                    ForEach(0..<items.count, id: \.self) { i in
                        HStack(spacing: 14) {
                            Image(systemName: items[i].0).font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(Circle().fill(Theme.accent))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(items[i].1).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                Text(items[i].2).font(.system(size: 13)).foregroundColor(Theme.muted)
                            }
                            Spacer(minLength: 0)
                        }
                        .opacity(rows[i] ? 1 : 0).offset(x: rows[i] ? 0 : -30)
                    }
                }
                .padding(.horizontal, 28).padding(.top, 30)
                Spacer(minLength: 20)
                VStack(spacing: 10) {
                    ConsentRow(agree: $agree)
                    if warn { Text("Чтобы продолжить, примите Политику конфиденциальности").font(.footnote).foregroundColor(Theme.danger) }
                    GradientButton(title: "Продолжить") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if agree { onContinue() } else { warn = true }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 56)
                .opacity(button ? 1 : 0).offset(y: button ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) { logo = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.25)) { title = true }
            for i in 0..<3 { withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5 + Double(i) * 0.14)) { rows[i] = true } }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.05)) { button = true }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { float = true }
            withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}
