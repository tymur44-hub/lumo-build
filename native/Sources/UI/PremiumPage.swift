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

/// Значок статуса: нарисованный анимированный значок или обычный эмодзи
struct StatusEmojiView: View {
    let s: String
    var size: CGFloat = 16

    var body: some View {
        if s.hasPrefix("a:") {
            DrawnStatusView(key: String(s.dropFirst(2)), size: size * 1.15)
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

struct Feat: Identifiable {
    let id = UUID()
    let icon: String, color: UInt32, title: String, desc: String
    var soon = false
}

/// Кнопка с градиентом и бегущим бликом
struct ShimmerButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            TimelineView(.animation) { tl in
                let x = ((tl.date.timeIntervalSinceReferenceDate / 2.2).truncatingRemainder(dividingBy: 1)) * 1.8 - 0.4
                Text(title).font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(
                        GeometryReader { geo in
                            ZStack {
                                LinearGradient(colors: [Color(hex: 0x5b8cff), Color(hex: 0xa066ff), Color(hex: 0xd86bff)], startPoint: .leading, endPoint: .trailing)
                                LinearGradient(colors: [.clear, .white.opacity(0.38), .clear], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: geo.size.width * 0.36)
                                    .offset(x: geo.size.width * (x - 0.5))
                            }
                        }
                    )
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DetailIdx: Identifiable { let i: Int; var id: Int { i } }

struct PremiumPageView: View {
    @EnvironmentObject var model: AppModel
    @State private var plan = "year"
    @State private var until: String?
    @State private var owner = false
    @State private var showEmoji = false
    @State private var detail: Int?

    private let plans: [(String, String, String, String)] = [
        ("year", "12 месяцев", "2 490 ₽", "около 207 ₽ в месяц · выгода 48%"),
        ("half", "6 месяцев", "1 490 ₽", "около 248 ₽ в месяц"),
        ("month", "1 месяц", "199 ₽", "без скидки"),
    ]
    private let features: [Feat] = [
        Feat(icon: "sparkles", color: 0xff9f0a, title: "Анимированные смайлик-статусы", desc: "Двигающийся значок рядом с именем"),
        Feat(icon: "party.popper.fill", color: 0xff5b7a, title: "Анимированные эффекты сообщений", desc: "Удерживайте кнопку отправки и выберите эффект"),
        Feat(icon: "face.smiling.inverse", color: 0xffb020, title: "Анимированные эмодзи", desc: "Вкладка «Анимации» в панели эмодзи: оживающие эмодзи в любом чате"),
        Feat(icon: "heart.circle.fill", color: 0xff5b7a, title: "До 3 реакций на сообщение", desc: "Без Premium — одна реакция"),
        Feat(icon: "photo.artframe", color: 0x2b8cff, title: "Обои для вас и собеседника", desc: "Свои обои в личном чате — только для вас или сразу для двоих"),
        Feat(icon: "timer", color: 0x1fb6a6, title: "Исчезающие сообщения", desc: "Автоудаление в чате через час, день, неделю или месяц"),
        Feat(icon: "chart.bar.fill", color: 0x22a6ff, title: "Статистика каналов", desc: "Подписчики и посты по дням"),
        Feat(icon: "cpu.fill", color: 0xff8a3d, title: "Создание своих ботов", desc: "Через @botfather командой /newbot"),
        Feat(icon: "waveform", color: 0xa35bff, title: "Расшифровка голосовых и кружков", desc: "Кнопка справа от голосового сообщения"),
        Feat(icon: "square.grid.2x2.fill", color: 0x5b6cff, title: "Иконки приложения", desc: "Шесть оформлений иконки с премиум-значком"),
        Feat(icon: "faceid", color: 0x5b6cff, title: "Блокировка и Face ID", desc: "Код или Face ID при входе в Lumo"),
        Feat(icon: "envelope.fill", color: 0xffb020, title: "Писать мне только Premium", desc: "Ограничьте входящие сообщения в «Конфиденциальности»"),
        Feat(icon: "paintpalette.fill", color: 0xe05bff, title: "Свои цвета и фоны чатов", desc: "Цвет сообщений, обои и акценты оформления"),
        Feat(icon: "shield.lefthalf.filled", color: 0x2b8cff, title: "Запрет пересылки и скриншотов", desc: "Защищённый чат: пересылка и копирование отключены, экран скрывается при записи"),
        Feat(icon: "person.3.fill", color: 0x34c759, title: "Групповые голосовые и видеозвонки", desc: "Звонок с несколькими участниками", soon: true),
        Feat(icon: "person.crop.rectangle.fill", color: 0x64d2ff, title: "Размытие фона в видеозвонке", desc: "Кнопка «Фон» в звонке открывает системные эффекты камеры"),
        Feat(icon: "record.circle.fill", color: 0xff453a, title: "Запись звонка с согласия собеседника", desc: "Собеседник должен подтвердить запись", soon: true),
        Feat(icon: "star.fill", color: 0xffb020, title: "Значок Premium", desc: "Звезда рядом с именем в чатах и профиле"),
    ]
    private let about: [(String, String)] = [
        ("Что это", "Lumo Premium — необязательная подписка с дополнительными возможностями для общения. Основные функции мессенджера остаются бесплатными."),
        ("Где работает", "Подписка привязана к вашему аккаунту и действует на всех устройствах: сайт, iOS, Android и Windows."),
        ("Как оформить", "Оплата проходит через встроенного бота @lumo_premium прямо в Lumo. После оплаты значок и функции включаются сами."),
        ("Безопасность", "Шифрование медиа остаётся бесплатным для всех. Premium не даёт доступа к чужим перепискам."),
        ("Скоро", "Функции с пометкой «в разработке» появятся в следующих обновлениях."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        LinearGradient(colors: [Color(hex: 0x9b6bff).opacity(0.22), .clear], startPoint: .top, endPoint: .bottom).frame(height: 240)
                        SparkleFieldView().frame(height: 240)
                        VStack(spacing: 4) {
                            PremiumStarView(size: 130)
                            Text("Lumo Premium").font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text)
                            Text("Больше свободы и десятки эксклюзивных функций").font(.system(size: 14)).foregroundColor(Theme.muted)
                                .multilineTextAlignment(.center).padding(.horizontal, 40)
                        }
                    }
                    VStack(spacing: 12) {
                        if model.isPremium {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("У вас активен Premium").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                Text(owner ? "Бессрочно — вы владелец Lumo" : (until.map { "Действует до " + String($0.prefix(10)) } ?? "Подписка активна"))
                                    .font(.system(size: 14)).foregroundColor(Theme.muted)
                                Button { showEmoji = true } label: {
                                    HStack(spacing: 8) {
                                        Text("Ваш смайлик-статус:").font(.system(size: 14)).foregroundColor(Theme.muted)
                                        if let e = model.me?.emojiStatus { StatusEmojiView(s: e, size: 22) } else { Text("выбрать").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.a1) }
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                        }
                        VStack(spacing: 0) {
                            ForEach(Array(plans.enumerated()), id: \.element.0) { i, pl in
                                let on = plan == pl.0
                                if i > 0 { Divider().overlay(Theme.line).padding(.leading, 50) }
                                Button { plan = pl.0 } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.system(size: 24)).foregroundColor(on ? Theme.a1 : Theme.muted)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pl.1).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                            Text(pl.3).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                        }
                                        Spacer()
                                        Text(pl.2).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.text)
                                    }
                                    .padding(14).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                        Text("ПРЕИМУЩЕСТВА ПОДПИСКИ").font(.system(size: 12.5, weight: .semibold)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 14).padding(.top, 6)
                        VStack(spacing: 0) {
                            ForEach(Array(features.enumerated()), id: \.element.id) { i, f in
                                if i > 0 { Divider().overlay(Theme.line).padding(.leading, 62) }
                                Button { detail = i } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: f.icon).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                        .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: f.color)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(f.title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                                            if f.soon {
                                                Text("в разработке").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.a1)
                                                    .padding(.horizontal, 6).padding(.vertical, 1).background(Theme.a1.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                                            }
                                        }
                                        Text(f.desc).font(.system(size: 12.5)).foregroundColor(Theme.muted)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.6))
                                }
                                .padding(.horizontal, 14).padding(.vertical, 11).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("О Lumo Premium").font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.text)
                            ForEach(Array(about.enumerated()), id: \.offset) { _, a in
                                Text(a.0).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.a1).padding(.top, 12)
                                Text(a.1).font(.system(size: 14)).foregroundColor(Theme.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            ShimmerButton(title: model.isPremium ? "Продлить подписку" : "Оформить Premium") {
                if owner { Task { await model.openByUsername("lumo_premium") } } else { model.say("Оплата пока временно недоступна") }
            }
            .padding(12).background(Theme.panel)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Lumo Premium").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEmoji) { EmojiStatusSheet() }
        .sheet(item: Binding(get: { detail.map { DetailIdx(i: $0) } }, set: { detail = $0?.i })) { d in
            PremiumDetailSheet(features: features, index: d.i, owner: owner) {
                if owner { detail = nil; Task { await model.openByUsername("lumo_premium") } } else { model.say("Оплата пока временно недоступна") }
            }
            .environmentObject(model)
        }
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


// MARK: - Иконка приложения

struct AppIconSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var cur: String? = UIApplication.shared.alternateIconName
    private let icons: [(String?, String, String)] = [
        (nil, "Классика", "IconPrev-classic"), ("AppIcon-gold", "Золото", "IconPrev-gold"), ("AppIcon-aurora", "Аврора", "IconPrev-aurora"),
        ("AppIcon-midnight", "Полночь", "IconPrev-midnight"), ("AppIcon-sakura", "Сакура", "IconPrev-sakura"), ("AppIcon-neon", "Неон", "IconPrev-neon"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Иконка на экране «Домой» поменяется сразу.").font(.footnote).foregroundColor(Theme.muted)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(icons, id: \.1) { ic in
                            Button { pick(ic.0) } label: {
                                VStack(spacing: 6) {
                                    IconPreview(name: ic.2)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cur == ic.0 ? Theme.a1 : Color.clear, lineWidth: 3).padding(-2))
                                    Text(ic.1).font(.system(size: 13, weight: .semibold)).foregroundColor(cur == ic.0 ? Theme.a1 : Theme.text)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Иконка приложения").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func pick(_ name: String?) {
        if name != nil && !model.isPremium { model.say(premiumSoon); return }
        UIApplication.shared.setAlternateIconName(name) { err in
            DispatchQueue.main.async {
                if let err = err { model.say(err.localizedDescription) } else { cur = name }
            }
        }
    }
}

/// Превью иконки из каталога ресурсов (набор иконок читаем из бандла как файл, иначе рисуем градиент)
private struct IconPreview: View {
    let name: String
    var body: some View {
        if let img = UIImage(named: name) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            LinearGradient(colors: [Color(hex: 0x7c5cff), Color(hex: 0x22c1ff)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Image(systemName: "bubble.left.fill").font(.system(size: 34)).foregroundColor(.white))
        }
    }
}
