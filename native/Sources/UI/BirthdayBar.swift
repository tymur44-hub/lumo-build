import SwiftUI

/// Плашка «день рождения»: если у контакта сегодня ДР (и он указал дату), сверху списка чатов
/// горит строка с предложением подарить подарок. По нажатию открывается выбор подарка.
struct BirthdayBar: View {
    @EnvironmentObject var model: AppModel
    @State private var giftTarget: GiftTarget?
    @State private var list = false

    private var today: [Profile] {
        let c = Calendar.current.dateComponents([.month, .day], from: Date())
        return model.contacts.compactMap { model.profiles[$0] }.filter { p in
            guard let (_, m, d) = Birthday.parts(p.birthday) else { return false }
            return m == c.month && d == c.day && !p.banned
        }
    }

    var body: some View {
        let people = today
        if !people.isEmpty {
            Button {
                if people.count == 1 { giftTarget = GiftTarget(id: people[0].id) } else { list = true }
            } label: {
                HStack(spacing: 11) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [Color(hex: 0xff6ec4), Color(hex: 0xffa84b)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Image(systemName: "gift.fill").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    }
                    .frame(width: 38, height: 38)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(titleText(people)).font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                        Text("Нажмите, чтобы подарить подарок").font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.panel))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(LinearGradient(colors: [Color(hex: 0xff6ec4).opacity(0.5), Color(hex: 0xffa84b).opacity(0.5)], startPoint: .leading, endPoint: .trailing), lineWidth: 1))
            }
            .buttonStyle(BouncyButtonStyle())
            .sheet(item: $giftTarget) { t in GiftShopSheet(user: t.id).environmentObject(model) }
            .sheet(isPresented: $list) { BirthdayList(people: people) { giftTarget = GiftTarget(id: $0) } }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func titleText(_ p: [Profile]) -> String {
        if p.count == 1 { return "У \(p[0].name) сегодня день рождения" }
        return "День рождения у \(p.count) \(contactsWord(p.count))"
    }
    private func contactsWord(_ n: Int) -> String {
        (11...14).contains(n % 100) ? "контактов" : (n % 10 == 1 ? "контакта" : ((2...4).contains(n % 10) ? "контактов" : "контактов"))
    }
}

private struct BirthdayList: View {
    let people: [Profile]
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(people) { p in
                        Button { dismiss(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onPick(p.id) } } label: {
                            HStack(spacing: 12) {
                                AvatarView(name: p.name, url: p.avatarURL, color: p.color, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                                    Text(Birthday.text(p.birthday, age: true) ?? "").font(.system(size: 13)).foregroundColor(Theme.muted)
                                }
                                Spacer()
                                Image(systemName: "gift.fill").foregroundColor(Color(hex: 0xff5e8a))
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Дни рождения").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
        }
    }
}
