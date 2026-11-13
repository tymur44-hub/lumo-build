import SwiftUI

struct Tip: Identifiable {
    let id: Int
    let category: String
    let icon: String
    let title: String
    let summary: String
    let steps: [String]

    static let all: [Tip] = [
        Tip(id: 1, category: "Чек", icon: "cart.badge.plus",
            title: "Допродажа к каждому напитку",
            summary: "Самый быстрый способ поднять средний чек на 10–15%.",
            steps: ["Выберите 2–3 позиции для допродажи: десерт, сироп, выпечка.",
                    "Дайте бариста одну фразу: «К капучино отлично идёт наш чизкейк».",
                    "Поставьте выпечку у кассы на уровне глаз.",
                    "Через две недели сравните долю чеков из одной позиции в новом отчёте."]),
        Tip(id: 2, category: "Часы", icon: "clock.badge.exclamationmark",
            title: "Что делать с пустыми часами",
            summary: "Тихие часы можно заполнить акцией или сократить смену.",
            steps: ["Найдите в отчёте часы, где выручка вдвое ниже обычной.",
                    "Запустите «счастливые часы»: второй напиток со скидкой или комбо с десертом.",
                    "Расскажите об акции в соцсетях и на табличке у входа.",
                    "Если через месяц не сработало — сократите в эти часы смену на одного человека."]),
        Tip(id: 3, category: "Дни", icon: "calendar.badge.exclamationmark",
            title: "Поднять слабые дни недели",
            summary: "Понедельник и вторник обычно проседают на 20–40%.",
            steps: ["Сделайте акцию дня только на слабые дни: «Понедельник — латте за полцены до 11:00».",
                    "Предложите офисам рядом предзаказ к началу рабочего дня.",
                    "Начисляйте двойные бонусы по карте лояльности в эти дни."]),
        Tip(id: 4, category: "Скидки", icon: "tag",
            title: "Держите скидки до 3% выручки",
            summary: "Ручные скидки на кассе — частая утечка денег.",
            steps: ["Посмотрите в отчёте долю скидок.",
                    "Запретите ручные скидки без согласования или ограничьте их правами в кассе.",
                    "Замените скидки бонусами: гость получает выгоду, а вы — повторный визит."]),
        Tip(id: 5, category: "Меню", icon: "square.stack.3d.down.right",
            title: "Чистка меню по ABC-анализу",
            summary: "Позиции группы C занимают место и увеличивают списания.",
            steps: ["Откройте топ позиций в отчёте и найдите группу C.",
                    "Оставьте из неё только то, что нужно для ассортимента: чай, безлактозное молоко.",
                    "Остальное уберите или замените сезонной позицией.",
                    "Меньше выбор — быстрее решение гостя и короче очередь."]),
        Tip(id: 6, category: "Маржа", icon: "percent",
            title: "Проверьте маржу напитков",
            summary: "Для кофейни ориентир — от 60% маржи.",
            steps: ["Добавьте себестоимость в выгрузку из кассы — отчёт посчитает маржу.",
                    "У позиций с низкой маржой пересмотрите техкарту: объём, молоко, сиропы.",
                    "Поднимите цену на 10–20 ₽ — гости редко замечают такую разницу."]),
        Tip(id: 7, category: "Точки", icon: "building.2",
            title: "Сравнивайте точки сети",
            summary: "Отстающую точку проще подтянуть до уровня лидера.",
            steps: ["Сравните выручку в день и средний чек точек в отчёте.",
                    "Выпишите, что делает лидер иначе: витрина, ассортимент, часы работы, команда.",
                    "Перенесите одну практику за раз и проверьте эффект в следующем отчёте."]),
    ]

    static var categories: [String] {
        var seen: [String] = []
        for t in all where !seen.contains(t.category) { seen.append(t.category) }
        return seen
    }

    static var ofTheDay: Tip {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return all[day % all.count]
    }
}

struct TipsView: View {
    @State private var category: String = "Все"
    @State private var expanded: Int?

    private var filtered: [Tip] {
        category == "Все" ? Tip.all : Tip.all.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Советы")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Что делать с находками из отчёта")
                            .foregroundStyle(.secondary)
                    }
                    .appear(0)

                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(["Все"] + Tip.categories, id: \.self) { c in
                                let active = c == category
                                Button {
                                    Haptics.soft()
                                    withAnimation(Theme.spring) { category = c; expanded = nil }
                                } label: {
                                    Text(c)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(active ? .black : .white.opacity(0.8))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background {
                                            if active {
                                                Capsule().fill(Theme.goldGradient)
                                            } else {
                                                Capsule().fill(Theme.card).overlay(Capsule().stroke(Theme.stroke))
                                            }
                                        }
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .appear(1)

                    VStack(spacing: 12) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { i, tip in
                            TipCard(tip: tip, expanded: expanded == tip.id) {
                                Haptics.soft()
                                withAnimation(Theme.spring) { expanded = expanded == tip.id ? nil : tip.id }
                            }
                            .appear(i + 2)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct TipCard: View {
    let tip: Tip
    let expanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                        .frame(width: 42, height: 42)
                        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.category.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.gold)
                        Text(tip.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Text(tip.summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                if expanded {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(tip.steps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.black)
                                    .frame(width: 22, height: 22)
                                    .background(Theme.goldGradient, in: Circle())
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .card(radius: 20, padding: 16)
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.gold.opacity(expanded ? 0.35 : 0)))
        }
        .buttonStyle(PressableStyle(scale: 0.985))
    }
}
