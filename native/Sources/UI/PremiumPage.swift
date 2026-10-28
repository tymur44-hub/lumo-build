import SwiftUI

// MARK: - Анимированные смайлик-статусы

/// Ключ хранится в профиле как «a:ключ»; у остальных клиентов он показывается как обычный эмодзи
let animEmoji: [(String, String)] = [("fire", "🔥"), ("heart", "❤️"), ("star", "⭐"), ("rocket", "🚀"), ("crown", "👑"), ("gem", "💎"),
                                      ("bolt", "⚡"), ("ghost", "👻"), ("sun", "☀️"), ("moon", "🌙"), ("clover", "🍀"), ("note", "🎵")]
let classicEmoji = ["🎧", "📚", "🌴", "☕", "🎮", "💼", "🛠", "🎯", "✈️", "🏆", "🎨", "📷"]

func emojiGlyph(_ s: String) -> String {
    if s.hasPrefix("a:") { return animEmoji.first { $0.0 == String(s.dropFirst(2)) }?.1 ?? "⭐" }
    return s
}

/// Значок статуса: анимированный (пульс и покачивание) или обычный
struct StatusEmojiView: View {
    let s: String
    var size: CGFloat = 16
    @State private var on = false

    var body: some View {
        if s.hasPrefix("a:") {
            Text(emojiGlyph(s)).font(.system(size: size))
                .scaleEffect(on ? 1.14 : 0.88)
                .rotationEffect(.degrees(on ? 9 : -9))
                .animation(.easeInOut(duration: 0.9 + Double(abs(s.hashValue) % 4) * 0.12).repeatForever(autoreverses: true), value: on)
                .onAppear { on = true }
        } else {
            Text(s).font(.system(size: size))
        }
    }
}

struct EmojiStatusSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Значок показывается рядом с вашим именем. Анимированные двигаются у всех, кто пользуется Lumo.")
                        .font(.footnote).foregroundColor(Theme.muted)
                    Text("Анимированные").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(animEmoji, id: \.0) { e in
                            Button { Task { await model.setEmojiStatus("a:" + e.0); dismiss() } } label: {
                                StatusEmojiView(s: "a:" + e.0, size: 32).frame(maxWidth: .infinity).frame(height: 58)
                                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    Text("Обычные").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).padding(.top, 6)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(classicEmoji, id: \.self) { e in
                            Button { Task { await model.setEmojiStatus(e); dismiss() } } label: {
                                Text(e).font(.system(size: 30)).frame(maxWidth: .infinity).frame(height: 58)
                                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    Button("Убрать статус", role: .destructive) { Task { await model.setEmojiStatus(""); dismiss() } }
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Смайлик-статус").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Страница Lumo Premium

struct PremiumPageView: View {
    @EnvironmentObject var model: AppModel
    @State private var plan = "year"
    @State private var until: String?
    @State private var owner = false

    private let plans: [(String, String, String, String)] = [
        ("year", "12 месяцев", "2 490 ₽", "около 207 ₽ в месяц · выгода 48%"),
        ("half", "6 месяцев", "1 490 ₽", "около 248 ₽ в месяц"),
        ("month", "1 месяц", "199 ₽", "без скидки"),
    ]
    private let features: [(String, String, String)] = [
        ("✨", "Анимированные смайлик-статусы", "Двигающийся значок рядом с именем"),
        ("🎉", "Анимированные эффекты сообщений", "Удерживайте кнопку отправки и выберите эффект"),
        ("🔕", "Отправка без звука", "Сообщение придёт тихо"),
        ("⏰", "Отложенные сообщения", "Уйдут сами в нужное время"),
        ("⏳", "Исчезающие сообщения", "Автоудаление в чате через час, день, неделю или месяц"),
        ("📊", "Статистика каналов", "Подписчики и посты по дням"),
        ("🤖", "Создание своих ботов", "Через @botfather командой /newbot"),
        ("⭐", "Значок Premium", "Звезда рядом с именем в чатах и профиле"),
    ]
    private var gold: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x7c5cff), Color(hex: 0xff5bb8), Color(hex: 0xffb020)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    ZStack {
                        Circle().fill(gold).frame(width: 96, height: 96)
                        Image(systemName: "star.fill").font(.system(size: 50)).foregroundColor(.white)
                    }
                    .padding(.top, 10)
                    Text("Lumo Premium").font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text)
                    Text("Больше возможностей для общения").font(.system(size: 15)).foregroundColor(Theme.muted)
                    if model.isPremium {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("У вас активен Premium").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                            Text(owner ? "Бессрочно — вы владелец Lumo" : (until.map { "Действует до " + String($0.prefix(10)) } ?? "Подписка активна"))
                                .font(.system(size: 14)).foregroundColor(Theme.muted)
                            HStack(spacing: 8) {
                                Text("Ваш смайлик-статус:").font(.system(size: 14)).foregroundColor(Theme.muted)
                                if let e = model.me?.emojiStatus { StatusEmojiView(s: e, size: 22) } else { Text("не выбран").font(.system(size: 14)).foregroundColor(Theme.muted) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                        .padding(.top, 6)
                    }
                    VStack(spacing: 8) {
                        ForEach(plans, id: \.0) { pl in
                            let on = plan == pl.0
                            Button { plan = pl.0 } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: on ? "largecircle.fill.circle" : "circle").font(.system(size: 22)).foregroundColor(on ? Theme.a1 : Theme.muted)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pl.1).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                        Text(pl.3).font(.system(size: 13)).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                    Text(pl.2).font(.system(size: 17, weight: .heavy)).foregroundColor(Theme.text)
                                }
                                .padding(14)
                                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(on ? Theme.a1 : Color.clear, lineWidth: 2))
                            }
                        }
                    }
                    .padding(.top, 6)
                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                            if i > 0 { Divider().overlay(Theme.line).padding(.leading, 56) }
                            HStack(spacing: 12) {
                                Text(f.0).font(.system(size: 26)).frame(width: 34)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.1).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                    Text(f.2).font(.system(size: 13)).foregroundColor(Theme.muted)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                        }
                    }
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                    .padding(.top, 6)
                    Text("Шифрование медиа остаётся бесплатным для всех.").font(.system(size: 12.5)).foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center).padding(12)
                }
                .padding(.horizontal, 16)
            }
            Button {
                if owner { Task { await model.openByUsername("lumo_premium") } } else { model.say("Оплата пока временно недоступна") }
            } label: {
                Text(model.isPremium ? "Продлить подписку" : "Оформить Premium").font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52).background(gold, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(12).background(Theme.panel)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Lumo Premium").navigationBarTitleDisplayMode(.inline)
        .task {
            if let r = try? await API.shared.rpc("lm_my_premium", [:]) {
                let o = (r as? [String: Any]) ?? ((r as? [[String: Any]])?.first)
                if let o = o { owner = (o["owner"] as? Bool) ?? false; until = o["until"] as? String }
            }
        }
    }
}

// MARK: - Эффекты сообщений

let fxList = ["👍", "👎", "❤️", "🔥", "🎉", "💩", "😍", "🤩", "🥳", "💯", "👏", "😂", "😢", "😡"]

private struct FxParticle {
    let x: CGFloat, delay: CGFloat, size: CGFloat, dx: CGFloat, dy: CGFloat, rot: CGFloat
}

/// Облако эмодзи, летящее по экрану
struct FxOverlayView: View {
    let emoji: String
    let onDone: () -> Void
    @State private var start = Date()
    @State private var parts: [FxParticle] = []

    private var up: Bool { emoji == "🔥" || emoji == "❤️" || emoji == "😍" }
    private var down: Bool { emoji == "💩" }

    private func make() -> [FxParticle] {
        (0..<28).map { _ in
            FxParticle(x: 0.08 + CGFloat.random(in: 0...1) * 0.84, delay: CGFloat.random(in: 0...0.35), size: 22 + CGFloat.random(in: 0...32),
                       dx: (CGFloat.random(in: 0...1) - 0.5) * ((up || down) ? 0.3 : 0.9),
                       dy: up ? -(0.4 + CGFloat.random(in: 0...0.35)) : (down ? (0.5 + CGFloat.random(in: 0...0.3)) : (CGFloat.random(in: 0...1) - 0.5) * 0.6),
                       rot: (CGFloat.random(in: 0...1) - 0.5) * 120)
        }
    }

    private func one(_ q: FxParticle, _ prog: CGFloat, _ size: CGSize) -> some View {
        let t = min(1, max(0, (prog - q.delay) / (1 - q.delay)))
        let a = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85
        let y0 = up ? size.height * (0.7 + q.delay * 0.7) : (down ? size.height * 0.05 : size.height * 0.5)
        return Text(emoji).font(.system(size: q.size))
            .scaleEffect(0.3 + 0.9 * t)
            .rotationEffect(.degrees(Double(q.rot * t)))
            .opacity(Double(max(0, min(1, a))))
            .position(x: size.width * (q.x + q.dx * t), y: y0 + q.dy * size.height * t)
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { tl in
                let prog = CGFloat(tl.date.timeIntervalSince(start) / 2.8)
                ZStack {
                    ForEach(0..<parts.count, id: \.self) { i in one(parts[i], prog, geo.size) }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .task {
            start = Date(); parts = make()
            try? await Task.sleep(nanoseconds: 2_900_000_000)
            onDone()
        }
    }
}

/// Меню долгого нажатия на кнопку отправки: эффекты и действия на размытом фоне
struct SendMenuOverlay: View {
    @EnvironmentObject var model: AppModel
    let text: String
    var onClose: () -> Void
    var onFx: (String) -> Void
    var onAction: (Int) -> Void
    var onSend: () -> Void
    @State private var more = false

    private func cell(_ e: String) -> some View {
        Button { onFx(e) } label: {
            ZStack(alignment: .bottomTrailing) {
                Text(e).font(.system(size: 28)).frame(width: 42, height: 42)
                if !model.isPremium {
                    Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                        .frame(width: 15, height: 15).background(Circle().fill(Theme.muted))
                }
            }
        }
    }

    private func row(_ icon: String, _ t: String, _ k: Int) -> some View {
        Button { onAction(k) } label: {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 18)).frame(width: 24)
                Text(t).font(.system(size: 16))
                Spacer()
            }
            .foregroundColor(Theme.text).padding(.horizontal, 14).padding(.vertical, 13)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea().onTapGesture { onClose() }
            VStack(alignment: .trailing, spacing: 10) {
                VStack(spacing: 6) {
                    Text("Добавить анимированный эффект").font(.system(size: 14)).foregroundColor(Theme.muted)
                    HStack { ForEach(Array(fxList.prefix(7)), id: \.self) { cell($0) } }
                    if more { HStack { ForEach(Array(fxList.dropFirst(7)), id: \.self) { cell($0) } } }
                    else {
                        Button { withAnimation { more = true } } label: {
                            Image(systemName: "chevron.down").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                .frame(width: 32, height: 32).background(Circle().fill(Theme.a1.opacity(0.5)))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(10).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                HStack(alignment: .bottom, spacing: 10) {
                    Text(String(text.prefix(400))).font(.system(size: 16)).foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.accent))
                    Button { onSend() } label: {
                        Image(systemName: "arrow.up").font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                            .frame(width: 48, height: 48).background(Circle().fill(Theme.accent))
                    }
                }
                VStack(spacing: 0) {
                    row("bell.slash", "Отправить без звука", 0)
                    row("clock", "Отложить отправку", 1)
                    row("list.bullet", "Запланированные", 2)
                }
                .frame(width: 260).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            }
            .padding(14).padding(.bottom, 58)
        }
        .transition(.opacity)
    }
}
