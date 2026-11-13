import SwiftUI
import Charts

/// Число, которое «накручивается» при появлении.
struct CountingText: View {
    let value: Double
    var animated: Bool = true
    var format: (Double) -> String = Fmt.rub

    @State private var shown: Double = 0

    var body: some View {
        Text(format(animated ? shown : value))
            .contentTransition(.numericText(value: shown))
            .monospacedDigit()
            .onAppear {
                guard animated else { return }
                shown = 0
                withAnimation(.easeOut(duration: 1.1).delay(0.15)) { shown = value }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.6)) { shown = newValue }
            }
    }
}

/// Мини-график для карточек.
struct Sparkline: View {
    let values: [Double]
    var color: Color = Theme.gold
    var animated: Bool = true
    @State private var progress: Double = 0

    var body: some View {
        let points = Array(values.enumerated())
        Chart(points, id: \.offset) { p in
            AreaMark(x: .value("i", p.offset), y: .value("v", p.element * (animated ? progress : 1)))
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.35), color.opacity(0)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
            LineMark(x: .value("i", p.offset), y: .value("v", p.element * (animated ? progress : 1)))
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...(max(values.max() ?? 1, 1) * 1.1))
        .onAppear {
            guard animated else { return }
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) { progress = 1 }
        }
    }
}

/// Кольцо прогресса.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var animated: Bool = true
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(Theme.stroke, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(animated ? shown : progress, 0), 1))
                .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.spring(response: 1.1, dampingFraction: 0.9).delay(0.2)) { shown = progress }
        }
        .onChange(of: progress) { _, v in withAnimation(Theme.spring) { shown = v } }
    }
}

/// Тёмный фон с медленно плывущими золотыми пятнами.
struct AmbientBackground: View {
    @State private var phase = false

    var body: some View {
        ZStack {
            Theme.background
            Circle()
                .fill(Theme.gold.opacity(0.20))
                .frame(width: 340, height: 340)
                .blur(radius: 110)
                .offset(x: phase ? 120 : -80, y: phase ? -260 : -180)
            Circle()
                .fill(Theme.goldDeep.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 120)
                .offset(x: phase ? -140 : 90, y: phase ? 320 : 240)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { phase = true }
        }
    }
}

/// Иллюстрация: растущие столбцы и монета.
struct GrowthIllustration: View {
    @State private var grow = false
    @State private var float = false

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array([0.38, 0.6, 0.85].enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.goldGradient)
                        .frame(width: 34, height: grow ? 110 * h : 8)
                        .overlay(alignment: .topLeading) {
                            Capsule().fill(Color.white.opacity(0.35)).frame(width: 6, height: grow ? 110 * h - 22 : 0).padding(6)
                        }
                        .animation(.spring(response: 0.8, dampingFraction: 0.65).delay(Double(i) * 0.12), value: grow)
                }
            }
            Image(systemName: "rublesign.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.goldLight, Theme.goldDeep)
                .shadow(color: Theme.gold.opacity(0.6), radius: 14)
                .offset(x: 46, y: float ? -128 : -118)
                .opacity(grow ? 1 : 0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: float)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: grow)
        }
        .frame(width: 150, height: 150)
        .onAppear {
            grow = true
            float = true
        }
    }
}

/// Аватар с инициалами.
struct AvatarView: View {
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .frame(width: size, height: size)
            .background(Theme.goldGradient, in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Theme.gold.opacity(0.35), radius: 10)
    }
}

/// Плашка «изменение к прошлому отчёту».
struct DeltaBadge: View {
    let current: Double
    let previous: Double?
    /// true — рост это хорошо
    var higherIsBetter: Bool = true

    var body: some View {
        if let previous, previous > 0 {
            let d = (current - previous) / previous
            let good = (d >= 0) == higherIsBetter
            HStack(spacing: 2) {
                Image(systemName: d >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(Fmt.pct(abs(d)))
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(good ? Theme.success : Theme.danger)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background((good ? Theme.success : Theme.danger).opacity(0.14), in: Capsule())
        }
    }
}

/// Заголовок секции.
struct SectionTitle: View {
    let title: String
    var action: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack {
            Text(title).font(.system(.title3, design: .rounded).weight(.bold))
            Spacer()
            if let action, let onAction {
                Button(action) { onAction() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.gold)
            }
        }
    }
}

/// Сегментированный переключатель с плавающей подложкой.
struct SegmentedTabs<T: Hashable>: View {
    let items: [(T, String)]
    @Binding var selection: T
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { i in
                let item = items[i]
                let active = item.0 == selection
                Button {
                    Haptics.soft()
                    withAnimation(Theme.snappy) { selection = item.0 }
                } label: {
                    Text(item.1)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(active ? .black : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if active {
                                Capsule().fill(Theme.goldGradient).matchedGeometryEffect(id: "seg", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.cardRaised, in: Capsule())
    }
}
