import SwiftUI

/// Первый запуск: три экрана о приложении и настройка кабинета.
struct OnboardingView: View {
    @Environment(ProfileStore.self) private var profileStore
    @State private var page = 0
    @State private var draft = UserProfile()
    @FocusState private var focused: Field?

    private enum Field { case name, shop, city }

    private struct Slide {
        let icon: String
        let title: String
        let text: String
    }

    private let slides: [Slide] = [
        Slide(icon: "rublesign.circle.fill",
              title: "Найдём деньги, которые теряет ваша кофейня",
              text: "Загрузите выгрузку продаж из кассы — через минуту увидите, сколько можно вернуть в месяц."),
        Slide(icon: "clock.badge.exclamationmark.fill",
              title: "Пустые часы, слабые дни и отстающие точки",
              text: "Разбираем каждый час, день недели, точку и позицию меню. Каждая находка — в рублях и с понятным действием."),
        Slide(icon: "lock.shield.fill",
              title: "Данные остаются у вас",
              text: "Файл обрабатывается прямо на телефоне и никуда не отправляется. Подходят iiko, Эвотор, r_keeper, Quick Resto и ОФД."),
    ]

    private var lastPage: Int { slides.count }

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                HStack {
                    Text("M.S")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.goldGradient)
                    Spacer()
                    if page < lastPage {
                        Button("Пропустить") {
                            withAnimation(Theme.spring) { page = lastPage }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { i in
                        slideView(slides[i], index: i).tag(i)
                    }
                    profileForm.tag(lastPage)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(Theme.spring, value: page)

                // Точки страниц
                HStack(spacing: 6) {
                    ForEach(0...lastPage, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Color.white.opacity(0.2)))
                            .frame(width: i == page ? 26 : 7, height: 7)
                    }
                }
                .animation(Theme.snappy, value: page)
                .padding(.bottom, 18)

                Button {
                    Haptics.tap()
                    if page < lastPage {
                        withAnimation(Theme.spring) { page += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(page < lastPage ? "Дальше" : "Начать работу")
                        Image(systemName: page < lastPage ? "arrow.right" : "checkmark")
                    }
                }
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .onChange(of: page) { _, _ in Haptics.soft() }
    }

    private func slideView(_ s: Slide, index: Int) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.10))
                    .frame(width: 210, height: 210)
                Circle()
                    .stroke(Theme.gold.opacity(0.25), lineWidth: 1)
                    .frame(width: 250, height: 250)
                if index == 0 {
                    GrowthIllustration()
                } else {
                    Image(systemName: s.icon)
                        .font(.system(size: 84, weight: .semibold))
                        .foregroundStyle(Theme.goldGradient)
                        .symbolEffect(.bounce, value: page == index)
                        .shadow(color: Theme.gold.opacity(0.5), radius: 20)
                }
            }
            .scaleEffect(page == index ? 1 : 0.8)
            .opacity(page == index ? 1 : 0.3)
            .animation(Theme.spring, value: page)

            VStack(spacing: 12) {
                Text(s.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(s.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .offset(y: page == index ? 0 : 20)
            .opacity(page == index ? 1 : 0)
            .animation(Theme.spring.delay(0.08), value: page)
            Spacer()
            Spacer()
        }
    }

    private var profileForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    AvatarView(initials: draft.initials, size: 64)
                        .animation(Theme.snappy, value: draft.initials)
                    Text("Ваш кабинет")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Так отчёты будут подписаны, а цель по выручке появится на главной.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: 12) {
                    field("Как вас зовут", text: $draft.name, icon: "person.fill", field: .name)
                    field("Название кофейни или сети", text: $draft.shopName, icon: "cup.and.saucer.fill", field: .shop)
                    field("Город", text: $draft.city, icon: "mappin.and.ellipse", field: .city)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Stepper(value: $draft.points, in: 1...50) {
                        HStack(spacing: 10) {
                            Image(systemName: "building.2.fill").foregroundStyle(Theme.gold).frame(width: 22)
                            Text("Точек: \(draft.points)").contentTransition(.numericText())
                        }
                    }
                    Divider().overlay(Theme.stroke)
                    HStack(spacing: 10) {
                        Image(systemName: "target").foregroundStyle(Theme.gold).frame(width: 22)
                        TextField("Цель по выручке в месяц, ₽", value: $draft.monthlyGoal, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
                .card(radius: 18, padding: 14)

                Text("Можно заполнить позже в разделе «Кабинет».")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func field(_ title: String, text: Binding<String>, icon: String, field: Field) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(focused == field ? Theme.gold : Color.white.opacity(0.5))
                .frame(width: 22)
            TextField(title, text: text)
                .focused($focused, equals: field)
                .submitLabel(.next)
                .onSubmit {
                    switch field {
                    case .name: focused = .shop
                    case .shop: focused = .city
                    case .city: focused = nil
                    }
                }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(focused == field ? Theme.gold.opacity(0.6) : Theme.stroke, lineWidth: focused == field ? 1.5 : 1))
        .animation(Theme.snappy, value: focused)
    }

    private func finish() {
        focused = nil
        var p = draft
        p.name = p.name.trimmingCharacters(in: .whitespaces)
        p.shopName = p.shopName.trimmingCharacters(in: .whitespaces)
        p.city = p.city.trimmingCharacters(in: .whitespaces)
        p.createdAt = Date()
        profileStore.profile = p
        Haptics.success()
        profileStore.onboarded = true
    }
}
