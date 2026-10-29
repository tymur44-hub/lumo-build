import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var model: AppModel
    @Binding var path: [String]
    @State private var q = ""
    @State private var found: [SearchResult] = []
    @State private var person: IdentifiedString?
    @State private var share = false
    @ObservedObject private var store = PhoneStore.shared

    private var friends: [MatchedContact] {
        let s = q.lowercased()
        return store.matched.filter { !model.isContact($0.id) && (s.isEmpty || $0.bookName.lowercased().contains(s) || $0.name.lowercased().contains(s)) }
    }
    private var inviteList: [InviteContact] {
        let s = q.lowercased()
        return store.invites.filter { s.isEmpty || $0.name.lowercased().contains(s) || $0.phone.contains(s) }
    }
    private func invite(_ c: InviteContact) {
        let body = "Я в Lumo — мессенджере. Присоединяйся: " + model.profileLink
        let enc = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let u = URL(string: "sms:+\(c.phone)&body=\(enc)") { UIApplication.shared.open(u) }
    }

    private var list: [String] {
        let s = q.lowercased().replacingOccurrences(of: "@", with: "")
        var l = model.contacts.filter { model.profiles[$0] != nil }
        if !s.isEmpty {
            l = l.filter { model.displayName($0).lowercased().contains(s) || (model.profiles[$0]?.username ?? "").contains(s) }
        }
        return l.sorted {
            let a = model.isOnline($0), b = model.isOnline($1)
            if a != b { return a }
            return (model.profiles[$0]?.lastSeen ?? .distantPast) > (model.profiles[$1]?.lastSeen ?? .distantPast)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                ScreenTitle(text: "Контакты")
                SearchField(placeholder: "Поиск людей", text: $q).padding(.horizontal, 14).padding(.vertical, 8)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if q.isEmpty {
                            Button { share = true } label: {
                                HStack(spacing: 12) {
                                    AvatarView(name: "", url: nil, color: 2, size: 50, icon: "link")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Пригласить друзей").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                        Text("Поделиться ссылкой на мой профиль").font(.subheadline).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 8)
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                        if !list.isEmpty {
                            SectionTitle(text: q.isEmpty ? "Контакты · \(list.count)" : "Мои контакты")
                            ForEach(list, id: \.self) { id in personRow(id: id, name: model.displayName(id), url: model.profiles[id]?.avatarURL,
                                                                        color: model.profiles[id]?.color ?? 0, sub: model.lastSeenText(id), contact: true) }
                        }
                        if q.isEmpty && store.contactsState != "ok" {
                            Button {
                                if store.contactsState == "denied", let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
                                else { Task { await store.syncContacts() } }
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(name: "", url: nil, color: 4, size: 50, icon: "person.crop.circle.badge.checkmark")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Найти друзей в Lumo").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                        Text(store.contactsState == "denied" ? "Разрешите доступ к контактам в настройках" : "Разрешите доступ к контактам")
                                            .font(.subheadline).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 8)
                            }
                            .buttonStyle(RowButtonStyle())
                        }
                        if !friends.isEmpty {
                            SectionTitle(text: "Друзья в Lumo · \(friends.count)")
                            ForEach(friends) { f in
                                personRow(id: f.id, name: f.bookName.isEmpty ? f.name : f.bookName, url: f.avatarURL?.absoluteString, color: f.color,
                                          sub: "@" + f.username + " · из контактов", contact: false)
                            }
                        }
                        if !inviteList.isEmpty {
                            SectionTitle(text: "Пригласить в Lumo · \(inviteList.count)")
                            ForEach(inviteList.prefix(200)) { c in
                                HStack(spacing: 12) {
                                    AvatarView(name: c.name, url: nil, color: abs(c.name.hashValue) % 8, size: 50)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.name).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                                        Text(PhoneStore.pretty(c.phone)).font(.subheadline).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                    Button { invite(c) } label: {
                                        Text("Пригласить").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.a1)
                                            .padding(.horizontal, 14).frame(height: 34).background(Capsule().fill(Theme.panel2))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                            }
                        }
                        let global = found.filter { $0.kind == "user" && $0.id != model.myId && !model.isContact($0.id) }
                        if !q.isEmpty && !global.isEmpty {
                            SectionTitle(text: "Глобальный поиск")
                            ForEach(global) { r in personRow(id: r.id, name: r.name, url: r.avatarURL, color: r.color, sub: "@" + (r.username ?? ""), contact: false) }
                        }
                        if list.isEmpty && (q.isEmpty || global.isEmpty) {
                            Text(q.isEmpty ? "Контактов пока нет.\nНайдите человека по имени или @юзернейму и нажмите «+»" : "Никого не найдено")
                                .multilineTextAlignment(.center).foregroundColor(Theme.muted)
                                .frame(maxWidth: .infinity).padding(34)
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await model.loadContacts(); await store.syncIfAllowed() }
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: q) { t in search(t) }
            .sheet(item: $person) { p in PersonSheet(userId: p.value).environmentObject(model) }
            .sheet(isPresented: $share) { ShareSheet(items: [model.profileLink]) }
            .task { await model.loadContacts(); if store.matched.isEmpty && store.invites.isEmpty { await store.syncIfAllowed() } }
        }
    }

    private func personRow(id: String, name: String, url: String?, color: Int, sub: String, contact: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: name, url: url, color: color, size: 50, online: model.isOnline(id))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                Text(sub).font(.subheadline).foregroundColor(model.isOnline(id) ? Theme.a2 : Theme.muted)
            }
            Spacer()
            Button {
                if contact { Task { await model.openDM(id) } } else { Task { await model.addContact(id) } }
            } label: {
                Image(systemName: contact ? "bubble.left.fill" : "person.badge.plus")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.a1)
                    .frame(width: 40, height: 40).background(Circle().fill(Theme.panel2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { person = IdentifiedString(value: id) }
    }

    private func search(_ t: String) {
        let s = t.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !s.isEmpty else { found = []; return }
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard s == q.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "") else { return }
            found = await model.search(s)
        }
    }
}

/// Профиль человека (из контактов, участников и поиска)
struct PersonSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let userId: String
    @State private var report: ReportTarget?
    @State private var showSafety = false
    @State private var phone: String?

    var body: some View {
        let p = model.profiles[userId]
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        AvatarView(name: model.displayName(userId), url: p?.avatarURL, color: p?.color ?? 0, size: 110, online: model.isOnline(userId))
                        HStack(spacing: 6) {
                            Text(model.displayName(userId)).font(.system(size: 24, weight: .heavy))
                            if p?.verified == true { Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.a2) }
                        }
                        Text("@" + (p?.username ?? "") + " · " + model.lastSeenText(userId)).font(.subheadline.weight(.semibold)).foregroundColor(Theme.muted)
                        if let b = model.peerBlockText(userId), p?.banned == true {
                            Text(b).font(.subheadline.weight(.bold)).foregroundColor(Theme.danger).multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [Theme.a1.opacity(0.16), Theme.a2.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .padding(.horizontal, 14)

                    if let ph = phone {
                        SettingsGroup {
                            HStack {
                                Text("Телефон").foregroundColor(Theme.muted)
                                Spacer()
                                Text(PhoneStore.pretty(ph)).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                            }
                            .padding(12)
                        }
                    }
                    if let bio = p?.bio, !bio.isEmpty {
                        SettingsGroup {
                            Text(bio).frame(maxWidth: .infinity, alignment: .leading).padding(10)
                        }
                    }
                    if userId != model.myId {
                        SettingsGroup {
                            Button { dismiss(); Task { await model.openDM(userId) } } label: {
                                SettingsRow(icon: "bubble.left.fill", color: Theme.a1, title: "Написать")
                            }
                            Divider().overlay(Theme.line)
                            Button { showSafety = true } label: {
                                SettingsRow(icon: "lock.fill", color: Theme.a1, title: "Код безопасности", chevron: false)
                            }
                            Divider().overlay(Theme.line)
                            Button {
                                Task {
                                    if model.isContact(userId) { await model.removeContact(userId) } else { await model.addContact(userId) }
                                }
                            } label: {
                                SettingsRow(icon: model.isContact(userId) ? "person.badge.minus" : "person.badge.plus", color: Color(hex: 0x2bd67b),
                                            title: model.isContact(userId) ? "Удалить из контактов" : "Добавить в контакты", chevron: false)
                            }
                            Divider().overlay(Theme.line)
                            let blocked = model.blockedByMe.contains(userId)
                            Button { Task { await model.setBlocked(userId, !blocked) } } label: {
                                SettingsRow(icon: blocked ? "lock.open.fill" : "hand.raised.fill", color: Theme.danger,
                                            title: blocked ? "Разблокировать" : "Заблокировать", titleColor: blocked ? Theme.text : Theme.danger, chevron: false)
                            }
                            Divider().overlay(Theme.line)
                            Button { report = ReportTarget(user: userId, chat: nil, message: nil) } label: {
                                SettingsRow(icon: "exclamationmark.bubble.fill", color: Color(hex: 0xff8a3d), title: "Пожаловаться", chevron: false)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .sheet(item: $report) { t in ReportView(target: t).environmentObject(model) }
            .sheet(isPresented: $showSafety) { SafetyView(peerId: userId) }
            .task {
                await model.refreshProfile(userId)
                if userId != model.myId { phone = (try? await API.shared.rpc("lm_phone_of", ["p_user": userId])) as? String }
            }
        }
    }
}
