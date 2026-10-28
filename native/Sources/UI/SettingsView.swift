import SwiftUI
import PhotosUI
import UIKit

enum SettingsPage: Hashable {
    case premium, profile, profileEdit, calls, notifications, privacy, about, blocked, look, username, colors
    case privacyKey(String)
}

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @Binding var path: [SettingsPage]
    @State private var avatarPick: PhotosPickerItem?
    @State private var confirmLogout = false
    @State private var showQR = false
    @State private var showScan = false
    @State private var showEmoji = false
    @State private var share = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 12) {
                    hero
                    if let r = model.staffRole {
                        SettingsGroup {
                            Button {
                                if let u = URL(string: "https://volshebny-mir.ru/page322172009.html") { UIApplication.shared.open(u) }
                            } label: {
                                SettingsRow(icon: "shield.fill", color: Color(hex: 0xff8a3d), title: "Админ-панель",
                                            subtitle: (r == "owner" ? "Вы владелец Lumo" : "Вы администратор Lumo") + " · открывается на сайте")
                            }
                        }
                    }
                    SettingsGroup {
                        NavigationLink(value: SettingsPage.premium) {
                            SettingsRow(icon: "star.fill", color: Color(hex: 0xffb020), title: "Lumo Premium", subtitle: "Дополнительные возможности и боты")
                        }
                    }
                    SettingsGroup {
                        NavigationLink(value: SettingsPage.profile) {
                            SettingsRow(icon: "person.fill", color: Theme.a1, title: "Мой профиль", subtitle: "Имя, юзернейм, о себе, пароль")
                        }
                        divider
                        Button { Task { await model.openSaved() } } label: {
                            SettingsRow(icon: "bookmark.fill", color: Color(hex: 0x3a7bff), title: "Избранное", subtitle: "Заметки и сохранённые сообщения")
                        }
                        divider
                        NavigationLink(value: SettingsPage.calls) {
                            SettingsRow(icon: "phone.fill", color: Color(hex: 0x2bd67b), title: "Звонки", subtitle: "Недавние и пропущенные")
                        }
                        divider
                        Button { showScan = true } label: {
                            SettingsRow(icon: "laptopcomputer", color: Color(hex: 0xff8a3d), title: "Устройства", subtitle: "Войти на компьютере по QR-коду")
                        }
                    }
                    SettingsGroup {
                        NavigationLink(value: SettingsPage.notifications) {
                            SettingsRow(icon: "bell.fill", color: Color(hex: 0xff5b5b), title: "Уведомления и звуки",
                                        subtitle: model.tgLinked ? "Telegram подключён" : "Telegram не подключён")
                        }
                        divider
                        NavigationLink(value: SettingsPage.privacy) {
                            SettingsRow(icon: "lock.fill", color: Color(hex: 0x5b6cff), title: "Конфиденциальность", subtitle: "Время захода, звонки, блокировки")
                        }
                        divider
                        NavigationLink(value: SettingsPage.look) {
                            SettingsRow(icon: "paintpalette.fill", color: Color(hex: 0x22a6ff), title: "Оформление",
                                        subtitle: lookSubtitle)
                        }
                    }
                    SettingsGroup {
                        Button { share = true } label: {
                            SettingsRow(icon: "person.badge.plus", color: Color(hex: 0xff5b8a), title: "Пригласить друзей", subtitle: "Поделиться ссылкой на ваш профиль")
                        }
                        divider
                        Button { showScan = true } label: {
                            SettingsRow(icon: "qrcode.viewfinder", color: Theme.a1, title: "Сканировать QR-код", subtitle: "Открыть профиль человека или войти на компьютере")
                        }
                        divider
                        NavigationLink(value: SettingsPage.about) {
                            SettingsRow(icon: "info.circle.fill", color: Color(hex: 0x8e8ea8), title: "О Lumo")
                        }
                    }
                    SettingsGroup {
                        Button { confirmLogout = true } label: {
                            SettingsRow(icon: "rectangle.portrait.and.arrow.right", color: Color(hex: 0xff3b5c), title: "Выйти из аккаунта",
                                        titleColor: Theme.danger, chevron: false)
                        }
                    }
                    Text("Lumo · " + Config.versionLabel.lowercased()).font(.footnote).foregroundColor(Theme.muted).padding(.top, 4)
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsPage.self) { p in
                switch p {
                case .premium: PremiumPageView()
                case .profile: MyProfileView()
                case .profileEdit: ProfileEditView()
                case .calls: CallsView()
                case .notifications: NotificationsView()
                case .privacy: PrivacyView()
                case .blocked: BlockedView()
                case .about: AboutView()
                case .look: AppearanceView()
                case .username: UsernameEditView()
                case .colors: ColorsEditView()
                case .privacyKey(let k): PrivacyKeyView(key: k)
                }
            }
            .onChange(of: avatarPick) { item in
                guard let item = item else { return }
                avatarPick = nil
                Task {
                    guard let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) else { return }
                    do { try await model.setAvatar(img) } catch { model.say(error.localizedDescription) }
                }
            }
            .confirmationDialog("Выйти из аккаунта на этом iPhone?", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Выйти", role: .destructive) { Task { await model.logout() } }
            }
            .sheet(isPresented: $showQR) { MyQRView().environmentObject(model) }
            .sheet(isPresented: $showEmoji) { EmojiStatusSheet().environmentObject(model) }
            .fullScreenCover(isPresented: $showScan) { QRScanScreen().environmentObject(model) }
            .sheet(isPresented: $share) { ShareSheet(items: ["Я в Lumo — напиши мне: " + model.profileLink]) }
        }
    }

    private var divider: some View { Divider().overlay(Theme.line).padding(.leading, 50) }

    private var lookSubtitle: String {
        let t = Appearance.shared.theme
        return (t == "light" ? "Светлая тема" : t == "dark" ? "Тёмная тема" : "Как в системе") + " · цвет, фон, текст"
    }

    private var hero: some View {
        let me = model.me
        return VStack(spacing: 4) {
            PhotosPicker(selection: $avatarPick, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(name: me?.name ?? "", url: me?.avatarURL, color: me?.color ?? 0, size: 110)
                    Image(systemName: "camera.fill").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        .frame(width: 34, height: 34).background(Circle().fill(Theme.a1))
                        .overlay(Circle().stroke(Theme.bg, lineWidth: 3))
                }
            }
            HStack(spacing: 6) {
                Text(me?.name ?? "").font(.system(size: 24, weight: .heavy)).foregroundColor(Theme.text)
                if me?.verified == true { Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.a2) }
                if me?.premium == true { Button { showEmoji = true } label: { if let e = me?.emojiStatus { StatusEmojiView(s: e, size: 22) } else { Image(systemName: "star.fill").foregroundColor(Color(hex: 0xffb020)) } } }
            }
            .padding(.top, 8)
            Text("@" + (me?.username ?? "")).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.muted)
            if let b = me?.bio, !b.isEmpty {
                Text(b).font(.system(size: 14.5)).foregroundColor(Theme.text).multilineTextAlignment(.center).padding(.top, 4).padding(.horizontal, 14)
            }
            HStack(spacing: 8) {
                NavigationLink(value: SettingsPage.profile) {
                    Label("Изменить профиль", systemImage: "pencil").font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.panel2))
                }
                Button { showQR = true } label: {
                    Label("QR-код", systemImage: "qrcode").font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.panel2))
                }
            }
            .foregroundColor(Theme.text)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 26).fill(LinearGradient(colors: [Theme.a1.opacity(0.16), Theme.a2.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.line))
        .padding(.horizontal, 14)
    }
}

// MARK: - Мой профиль (просмотр, как в Telegram): «+» и «Изм.» сверху, большая аватарка, юзернейм с QR-кодом

struct MyProfileView: View {
    @EnvironmentObject var model: AppModel
    @State private var avatarPick: PhotosPickerItem?
    @State private var showPicker = false
    @State private var addStory = false
    @State private var showQR = false
    @State private var avatarFull: IdentifiedURL?
    @State private var uploading = false

    var body: some View {
        let me = model.me
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Button {
                        if let u = me?.avatarURL.flatMap(URL.init(string:)) { avatarFull = IdentifiedURL(url: u) } else { showPicker = true }
                    } label: {
                        ZStack {
                            AvatarView(name: me?.name ?? "", url: me?.avatarURL, color: me?.color ?? 0, size: 120)
                            if uploading { Circle().fill(Color.black.opacity(0.4)).frame(width: 120, height: 120); ProgressView().tint(.white) }
                        }
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .padding(.bottom, 6)
                    Text(me?.name ?? "").font(.system(size: 28, weight: .bold)).foregroundColor(Theme.text)
                        .multilineTextAlignment(.center)
                    Text("в сети").font(.system(size: 16)).foregroundColor(Theme.a2)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

                VStack(spacing: 0) {
                    HStack {
                        Button {
                            UIPasteboard.general.string = "@" + (me?.username ?? "")
                            model.say("Юзернейм скопирован")
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("имя пользователя").font(.system(size: 14)).foregroundColor(Theme.text)
                                Text("@" + (me?.username ?? "")).font(.system(size: 17)).foregroundColor(Theme.a1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Button { showQR = true } label: {
                            Image(systemName: "qrcode").font(.system(size: 26, weight: .medium)).foregroundColor(Theme.a1)
                                .frame(width: 48, height: 48).contentShape(Rectangle())
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .padding(.vertical, 10)
                    if let bio = me?.bio, !bio.isEmpty {
                        Divider().overlay(Theme.line)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("о себе").font(.system(size: 14)).foregroundColor(Theme.text)
                            Text(bio).font(.system(size: 17)).foregroundColor(Theme.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                    }
                    if let b = Birthday.text(me?.birthday, age: true) {
                        Divider().overlay(Theme.line)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("день рождения").font(.system(size: 14)).foregroundColor(Theme.text)
                            Text(b).font(.system(size: 17)).foregroundColor(Theme.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 18)
                .background(RoundedRectangle(cornerRadius: 22).fill(Theme.panel))
                .padding(.horizontal, 14)
                if let p = me { ProfileChannelCard(p: p) }
                Color.clear.frame(height: 30)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button { showPicker = true } label: { Label("Новое фото профиля", systemImage: "camera") }
                    Button { addStory = true } label: { Label("Новая история", systemImage: "plus.circle.dashed") }
                } label: {
                    Image(systemName: "plus.circle.dashed").font(.system(size: 19, weight: .semibold))
                }
                NavigationLink(value: SettingsPage.profileEdit) {
                    Text("Изм.").font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $avatarPick, matching: .images)
        .onChange(of: avatarPick) { item in
            guard let item = item else { return }
            avatarPick = nil
            uploading = true
            Task {
                if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) {
                    do { try await model.setAvatar(img); model.say("Фото профиля обновлено") } catch { model.say(error.localizedDescription) }
                }
                uploading = false
            }
        }
        .sheet(isPresented: $showQR) { MyQRView().environmentObject(model) }
        .sheet(isPresented: $addStory) { AddStoryView().environmentObject(model) }
        .fullScreenCover(item: $avatarFull) { ImageScreen(url: $0.url) }
    }
}

// MARK: - Изменить профиль (как в Telegram)

/// Карточка со скруглением как в Telegram
struct TGCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 16)
    }
}

/// Подсказка под карточкой и ссылка «Изменить ›»
struct TGHint: View {
    let text: String
    var link: String? = nil
    var action: () -> Void = {}
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text).font(.system(size: 14)).foregroundColor(Theme.muted)
            if let l = link {
                Button(action: action) { Text(l + " ›").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.a1) }
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32).padding(.top, 6).padding(.bottom, 16)
    }
}

struct TGIconRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String? = nil
    var valueColor: Color = Theme.muted
    var chevron = true
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(color))
            Text(title).font(.system(size: 17)).foregroundColor(Theme.text).lineLimit(1)
            Spacer(minLength: 8)
            if let v = value { Text(v).font(.system(size: 17)).foregroundColor(valueColor).lineLimit(1) }
            if chevron { Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.6)) }
        }
        .padding(.horizontal, 18).frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

func privLabel(_ v: String) -> String { v == "contacts" ? "Контакты" : (v == "none" ? "Никто" : "Все") }

struct ProfileEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var first = ""
    @State private var last = ""
    @State private var bio = ""
    @State private var birthday: String?
    @State private var saving = false
    @State private var photoMenu = false
    @State private var showPicker = false
    @State private var avatarPick: PhotosPickerItem?
    @State private var dateSheet = false
    @State private var datePick = Date()
    @State private var channelSheet = false
    @State private var showExtra = false
    @State private var pwSheet = false
    @State private var confirmDelete = false
    @State private var loaded = false

    var body: some View {
        let me = model.me
        ScrollView {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 20, weight: .semibold)).foregroundColor(Theme.text)
                            .frame(width: 52, height: 52).background(Circle().fill(Theme.panel))
                    }
                    .buttonStyle(BouncyButtonStyle())
                    Spacer()
                    VStack(spacing: 12) {
                        Button { photoMenu = true } label: {
                            AvatarView(name: [first, last].joined(separator: " "), url: me?.avatarURL, color: me?.color ?? 0, size: 124)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        Button { photoMenu = true } label: {
                            Text("Изменить фотографию").font(.system(size: 18)).foregroundColor(Theme.a1)
                        }
                    }
                    .padding(.top, 6)
                    Spacer()
                    Button { save() } label: {
                        ZStack {
                            Circle().fill(Theme.accent).frame(width: 52, height: 52)
                            if saving { ProgressView().tint(.white) }
                            else { Image(systemName: "checkmark").font(.system(size: 22, weight: .bold)).foregroundColor(.white) }
                        }
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 22)

                TGCard {
                    TextField("Имя", text: $first).font(.system(size: 17)).padding(.horizontal, 20).frame(height: 58)
                    Divider().overlay(Theme.line).padding(.leading, 20)
                    TextField("Фамилия", text: $last).font(.system(size: 17)).padding(.horizontal, 20).frame(height: 58)
                }
                TGHint(text: "Укажите имя и, если хотите, добавьте фотографию для Вашего профиля.")

                TGCard {
                    TextField("О себе", text: $bio, axis: .vertical).font(.system(size: 17)).lineLimit(1...4)
                        .padding(.horizontal, 20).padding(.vertical, 18)
                        .onChange(of: bio) { v in if v.count > 70 { bio = String(v.prefix(70)) } }
                }
                TGHint(text: "Раздел «О себе» видят: " + privLabel(me?.priv("bio") ?? "all").lowercased() + ".", link: "Изменить") {
                    model.settingsPath.append(.privacyKey("bio"))
                }

                TGCard {
                    Button {
                        datePick = Birthday.date(birthday) ?? Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
                        dateSheet = true
                    } label: {
                        TGIconRow(icon: "birthday.cake.fill", color: Color(hex: 0x3a8dff), title: "День рождения",
                                  value: Birthday.text(birthday) ?? "Указать", valueColor: birthday == nil ? Theme.a1 : Theme.muted, chevron: false)
                    }
                    .buttonStyle(RowButtonStyle())
                }
                TGHint(text: "Ваш день рождения видят: " + privLabel(me?.priv("birthday") ?? "contacts").lowercased() + ".", link: "Изменить") {
                    model.settingsPath.append(.privacyKey("birthday"))
                }

                TGCard {
                    NavigationLink(value: SettingsPage.username) {
                        TGIconRow(icon: "at", color: Color(hex: 0x7c5cff), title: "Имя пользователя", value: "@" + (me?.username ?? ""))
                    }
                    .buttonStyle(RowButtonStyle())
                    Divider().overlay(Theme.line).padding(.leading, 68)
                    NavigationLink(value: SettingsPage.colors) {
                        TGIconRow(icon: "paintbrush.pointed.fill", color: Color(hex: 0x3ab8ff), title: "Персональные цвета")
                    }
                    .buttonStyle(RowButtonStyle())
                    Divider().overlay(Theme.line).padding(.leading, 68)
                    ExtraProfileRow(show: $showExtra)
                    Divider().overlay(Theme.line).padding(.leading, 68)
                    Button { channelSheet = true } label: {
                        TGIconRow(icon: "megaphone.fill", color: Color(hex: 0xffa33a), title: "Канал", value: me?.channelTitle ?? "Добавить")
                    }
                    .buttonStyle(RowButtonStyle())
                }
                Color.clear.frame(height: 22)
                TGCard {
                    Button { pwSheet = true } label: {
                        TGIconRow(icon: "key.fill", color: Color(hex: 0x2bd67b), title: "Пароль", value: "Изменить")
                    }
                    .buttonStyle(RowButtonStyle())
                }
                Color.clear.frame(height: 22)
                TGCard {
                    Button { confirmDelete = true } label: {
                        Text("Удалить аккаунт").font(.system(size: 17)).foregroundColor(Theme.danger)
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(RowButtonStyle())
                }
                Color.clear.frame(height: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            first = me?.firstName ?? ""
            last = me?.lastName ?? ""
            bio = me?.bio ?? ""
            birthday = me?.birthday.map { String($0.prefix(10)) }
        }
        .confirmationDialog("Фото профиля", isPresented: $photoMenu) {
            Button("Выбрать фото") { showPicker = true }
            if me?.avatarURL != nil {
                Button("Удалить фото", role: .destructive) { Task { do { try await model.setAvatar(nil) } catch { model.say(error.localizedDescription) } } }
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $avatarPick, matching: .images)
        .onChange(of: avatarPick) { item in
            guard let item = item else { return }
            avatarPick = nil
            Task {
                if let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) {
                    do { try await model.setAvatar(img); model.say("Фото профиля обновлено") } catch { model.say(error.localizedDescription) }
                }
            }
        }
        .sheet(isPresented: $dateSheet) {
            NavigationStack {
                DatePicker("", selection: $datePick, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel).labelsHidden().environment(\.locale, Locale(identifier: "ru_RU"))
                    .padding()
                    .navigationTitle("День рождения").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            if birthday != nil { Button("Удалить", role: .destructive) { birthday = nil; dateSheet = false }.foregroundColor(Theme.danger) }
                            else { Button("Отмена") { dateSheet = false } }
                        }
                        ToolbarItem(placement: .confirmationAction) { Button("Готово") { birthday = Birthday.string(datePick); dateSheet = false } }
                    }
            }
            .presentationDetents([.height(340)])
        }
        .sheet(isPresented: $showExtra) { ProfileExtraSheet().environmentObject(model) }
        .sheet(isPresented: $channelSheet) { ChannelPickSheet().environmentObject(model).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $pwSheet) { PasswordSheet().environmentObject(model).presentationDetents([.height(300)]) }
        .confirmationDialog("Удалить аккаунт навсегда? Вернуть его будет нельзя.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить навсегда", role: .destructive) {
                Task { do { try await model.deleteAccount() } catch { model.say(error.localizedDescription) } }
            }
        }
    }

    private func save() {
        guard !saving else { return }
        saving = true
        Task {
            do {
                try await model.saveProfileFull(first: first, last: last, bio: bio, birthday: birthday)
                model.say("Сохранено")
                dismiss()
            } catch { model.say(error.localizedDescription) }
            saving = false
        }
    }
}

/// Выбор своего канала для профиля
struct ChannelPickSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        let mine = model.chats.filter { $0.isChannel && $0.role == "owner" }
        NavigationStack {
            List {
                if mine.isEmpty {
                    Text("У вас пока нет своих каналов. Создайте канал — и его можно будет показать в профиле.").foregroundColor(Theme.muted)
                }
                ForEach(mine) { c in
                    Button {
                        Task { await model.setChannel(c.id); dismiss() }
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 40)
                            Text(c.displayName).foregroundColor(Theme.text)
                            Spacer()
                            if model.me?.channelId == c.id { Image(systemName: "checkmark").foregroundColor(Theme.a1) }
                        }
                    }
                }
                if model.me?.channelId != nil {
                    Button("Убрать канал из профиля", role: .destructive) { Task { await model.setChannel(nil); dismiss() } }
                }
            }
            .navigationTitle("Канал в профиле").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}

struct PasswordSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var pw1 = ""
    @State private var pw2 = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                SecureField("Новый пароль", text: $pw1).lumoField()
                SecureField("Повторите пароль", text: $pw2).lumoField()
                Spacer()
            }
            .padding(16)
            .navigationTitle("Пароль").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        guard pw1.count >= 6 else { model.say("Пароль — минимум 6 символов"); return }
                        guard pw1 == pw2 else { model.say("Пароли не совпадают"); return }
                        Task {
                            do { try await model.setPassword(pw1); model.say("Пароль изменён"); dismiss() }
                            catch { model.say(error.localizedDescription) }
                        }
                    }
                }
            }
        }
    }
}

struct UsernameEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var u = ""
    @State private var busy = false
    var body: some View {
        let ok = u.lowercased().range(of: "^[a-z0-9_]{3,32}$", options: .regularExpression) != nil
        ScrollView {
            VStack(spacing: 0) {
                TGCard {
                    HStack(spacing: 2) {
                        Text("@").foregroundColor(Theme.muted)
                        TextField("username", text: $u).textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    .font(.system(size: 17)).padding(.horizontal, 20).frame(height: 58)
                }
                .padding(.top, 16)
                TGHint(text: "Латинские буквы, цифры и _, от 3 до 32 символов. По этому имени вас смогут найти в Lumo.\nСсылка: " + "https://volshebny-mir.ru/page322172009.html#@" + u.lowercased())
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Имя пользователя").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") {
                    busy = true
                    Task {
                        do { try await model.setUsername(u); model.say("Сохранено"); dismiss() } catch { model.say(error.localizedDescription) }
                        busy = false
                    }
                }
                .disabled(!ok || busy)
            }
        }
        .onAppear { if u.isEmpty { u = model.me?.username ?? "" } }
    }
}

struct ColorsEditView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var c = -1
    var body: some View {
        let me = model.me
        let sel = c < 0 ? (me?.color ?? 0) : c
        ScrollView {
            VStack(spacing: 0) {
                TGCard {
                    HStack(spacing: 14) {
                        AvatarView(name: me?.name ?? "", url: nil, color: sel, size: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(me?.name ?? "").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.nameColor(sel))
                            Text("Так ваше имя выглядит в группах").foregroundColor(Theme.text)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.panel2))
                        Spacer()
                    }
                    .padding(18)
                }
                .padding(.top, 16)
                TGHint(text: "Цвет используется для кружка с инициалами и вашего имени в группах.")
                TGCard {
                    HStack {
                        ForEach(0..<8, id: \.self) { i in
                            Button { withAnimation(.spring(response: 0.3)) { c = i } } label: {
                                ZStack {
                                    Circle().fill(Theme.avatarGradient(i)).frame(width: 36, height: 36)
                                    if sel == i { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white) }
                                }
                                .overlay(Circle().stroke(sel == i ? Theme.text : .clear, lineWidth: 2.5).frame(width: 42, height: 42))
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(BouncyButtonStyle())
                        }
                    }
                    .padding(.vertical, 18).padding(.horizontal, 8)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Персональные цвета").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { Task { await model.setColor(sel); model.say("Цвет сохранён"); dismiss() } }
            }
        }
    }
}

// MARK: - Звонки

struct CallsView: View {
    @EnvironmentObject var model: AppModel

    private var rows: [CallEntry] {
        model.calls.compactMap { m in
            guard let c = model.chat(m.chatId), c.isPrivate else { return nil }
            return CallEntry(message: m, chat: c)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if rows.isEmpty {
                    Text("Звонков пока нет.\nПозвонить можно из чата или из контактов")
                        .multilineTextAlignment(.center).foregroundColor(Theme.muted).padding(40)
                }
                ForEach(rows) { e in CallRowView(entry: e) }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Звонки")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadCalls() }
        .refreshable { await model.loadCalls() }
    }
}

struct CallEntry: Identifiable {
    var id: Int { message.id }
    let message: Message
    let chat: ChatItem
}

struct CallRowView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var calls: CallManager
    let entry: CallEntry

    private var out: Bool { entry.message.senderId == model.myId }
    private var status: String { entry.message.metaStatus ?? "" }
    private var ok: Bool { status == "ended" }
    private var missed: Bool { !ok && !out && status != "rejected" }

    private var label: String {
        let m = entry.message
        var kind: String
        if out { kind = ok ? "Исходящий" : "Отменённый" }
        else if ok { kind = "Входящий" }
        else if status == "rejected" { kind = "Отклонённый" }
        else { kind = "Пропущенный" }
        kind += m.isVideoCall ? " видеозвонок" : " звонок"
        kind += " · " + Fmt.time(m.createdAt)
        if ok && m.duration > 0 { kind += " · " + Fmt.duration(m.duration) }
        return kind
    }

    var body: some View {
        let c = entry.chat
        let m = entry.message
        HStack(spacing: 12) {
            AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 50, online: model.isOnline(c.peerId))
            VStack(alignment: .leading, spacing: 2) {
                Text(c.displayName).font(.system(size: 16, weight: .bold)).foregroundColor(missed ? Theme.danger : Theme.text)
                HStack(spacing: 4) {
                    Image(systemName: out ? "arrow.up.right" : "arrow.down.left").font(.caption.weight(.bold))
                        .foregroundColor(ok ? Theme.ok : Theme.danger)
                    Text(label).font(.subheadline).foregroundColor(Theme.muted).lineLimit(1)
                }
            }
            Spacer()
            Button { calls.startCall(chat: c, video: m.isVideoCall) } label: {
                Image(systemName: m.isVideoCall ? "video.fill" : "phone.fill").foregroundColor(Theme.a1)
                    .frame(width: 40, height: 40).background(Circle().fill(Theme.panel2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { model.open(c.id) }
    }
}

// MARK: - Уведомления

struct NotificationsView: View {
    @EnvironmentObject var model: AppModel
    @State private var keepAlive = BackgroundKeeper.shared.enabled

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsGroup {
                    SettingsRow(icon: "bell.badge.fill", color: Color(hex: 0xff5b5b), title: "Уведомления, когда Lumo свёрнут",
                                subtitle: "Сообщения и звонки приходят сразу. Расходует больше батареи") {
                        Toggle("", isOn: $keepAlive).labelsHidden().tint(Theme.a1)
                    }
                    .onChange(of: keepAlive) { v in BackgroundKeeper.shared.enabled = v }
                    Divider().overlay(Theme.line)
                    Button {
                        if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
                    } label: {
                        SettingsRow(icon: "gearshape.fill", color: Color(hex: 0x8e8ea8), title: "Настройки уведомлений iPhone", subtitle: "Звук, баннеры, значок на иконке")
                    }
                }
                Text("Если смахнуть Lumo из списка открытых приложений, iOS его закроет — тогда уведомления придут только через Telegram-бота.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24)

                SectionTitle(text: "Telegram")
                SettingsGroup {
                    if model.tgLinked {
                        SettingsRow(icon: "paperplane.fill", color: Color(hex: 0x2aabee), title: "Уведомления в Telegram",
                                    subtitle: "Подключено" + (model.botName.map { " · @" + $0 } ?? ""), chevron: false)
                        Divider().overlay(Theme.line)
                        Button { Task { await model.telegramOff() } } label: {
                            SettingsRow(icon: "bell.slash.fill", color: Theme.danger, title: "Отключить", titleColor: Theme.danger, chevron: false)
                        }
                    } else {
                        Button {
                            Task { if let u = await model.telegramLink() { await UIApplication.shared.open(u) } else { model.say("Бот уведомлений ещё не подключён") } }
                        } label: {
                            SettingsRow(icon: "paperplane.fill", color: Color(hex: 0x2aabee), title: "Подключить Telegram",
                                        subtitle: "Бот пришлёт сообщения и звонки, даже когда Lumo закрыт")
                        }
                    }
                }
            }
            .padding(.top, 12)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Уведомления и звуки")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Конфиденциальность (как в Telegram)

struct PrivItem {
    let key: String
    let title: String
    let question: String
    let hint: String
    var noneAllowed = true
}

let privacyItems: [PrivItem] = [
    PrivItem(key: "seen", title: "Время захода", question: "Кто видит время моего последнего входа?", hint: "Если вы скрываете время захода, вы тоже не увидите его у других. Вместо времени будет «был(а) недавно»."),
    PrivItem(key: "photo", title: "Фотографии профиля", question: "Кто видит фотографию моего профиля?", hint: "Те, кому фото недоступно, увидят цветной кружок с инициалами."),
    PrivItem(key: "bio", title: "Раздел «О себе»", question: "Кто видит раздел «О себе»?", hint: "Текст из раздела «О себе» в вашем профиле."),
    PrivItem(key: "birthday", title: "День рождения", question: "Кто видит мой день рождения?", hint: "Дата рождения в вашем профиле."),
    PrivItem(key: "calls", title: "Звонки", question: "Кто может мне звонить?", hint: "Остальные не смогут вам позвонить."),
    PrivItem(key: "voice", title: "Голосовые сообщения", question: "Кто может присылать мне голосовые и видеосообщения?", hint: "Остальные смогут писать только текстом."),
    PrivItem(key: "messages", title: "Сообщения", question: "Кто может писать мне первым?", hint: "Тем, с кем вы уже переписываетесь, ограничение не помешает ответить.", noneAllowed: false),
    PrivItem(key: "invites", title: "Приглашения", question: "Кто может приглашать меня в группы и каналы?", hint: "Вы можете выбрать, кому разрешаете приглашать Вас в группы и каналы."),
]

struct PrivacyView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject private var e2e = E2E.shared
    @ObservedObject private var ex = ExtraStore.shared
    @State private var showLock = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TGCard {
                    NavigationLink(value: SettingsPage.blocked) {
                        TGIconRow(icon: "hand.raised.fill", color: Theme.danger, title: "Заблокированные",
                                  value: model.blockedByMe.isEmpty ? "Никого" : "\(model.blockedByMe.count)")
                    }
                    .buttonStyle(RowButtonStyle())
                }
                .padding(.top, 12)
                TGCard {
                    Button { if e2e.status == .ready { e2e.promptBackup = true } } label: {
                        TGIconRow(icon: "lock.shield.fill", color: Theme.a1, title: "Сквозное шифрование",
                                  value: e2e.status == .ready ? (e2e.backedUp ? "Копия ключей сохранена" : "Задайте пароль копии") : "Личные чаты")
                    }
                    .buttonStyle(RowButtonStyle())
                }
                .padding(.top, 12)
                TGCard {
                    Button { showLock = true } label: {
                        TGIconRow(icon: "lock.fill", color: Color(hex: 0x5b6cff), title: "Блокировка приложения", value: ex.hasLock ? "Включена" : "Код при входе")
                    }
                    .buttonStyle(RowButtonStyle())
                }
                .padding(.top, 12)
                Text("КОНФИДЕНЦИАЛЬНОСТЬ").font(.system(size: 13)).foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32).padding(.top, 26).padding(.bottom, 8)
                TGCard {
                    ForEach(Array(privacyItems.enumerated()), id: \.offset) { i, it in
                        NavigationLink(value: SettingsPage.privacyKey(it.key)) {
                            HStack {
                                Text(it.title).font(.system(size: 17)).foregroundColor(Theme.text)
                                Spacer()
                                Text(privLabel(model.me?.priv(it.key) ?? "all")).font(.system(size: 17)).foregroundColor(Theme.muted)
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.6))
                            }
                            .padding(.horizontal, 20).frame(height: 58).contentShape(Rectangle())
                        }
                        .buttonStyle(RowButtonStyle())
                        if i < privacyItems.count - 1 { Divider().overlay(Theme.line).padding(.leading, 20) }
                    }
                }
                TGHint(text: "Вы можете выбрать, кому разрешаете приглашать Вас в группы и каналы.")
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showLock) { LockSettingsSheet().environmentObject(model) }
        .navigationTitle("Конфиденциальность")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadBlocks(); await model.loadMe() }
    }
}

struct PrivacyKeyView: View {
    @EnvironmentObject var model: AppModel
    let key: String

    var body: some View {
        let item = privacyItems.first { $0.key == key }
        let cur = model.me?.priv(key) ?? "all"
        let opts = ["all", "contacts"] + ((item?.noneAllowed ?? true) ? ["none"] : [])
        ScrollView {
            VStack(spacing: 0) {
                Text((item?.question ?? "").uppercased()).font(.system(size: 13)).foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32).padding(.top, 20).padding(.bottom, 8)
                TGCard {
                    ForEach(Array(opts.enumerated()), id: \.offset) { i, v in
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            Task { await model.setPrivacyKey(key, v) }
                        } label: {
                            HStack {
                                Text(v == "contacts" ? "Мои контакты" : privLabel(v)).font(.system(size: 17)).foregroundColor(Theme.text)
                                Spacer()
                                if cur == v { Image(systemName: "checkmark").font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.a1) }
                            }
                            .padding(.horizontal, 20).frame(height: 56).contentShape(Rectangle())
                        }
                        .buttonStyle(RowButtonStyle())
                        if i < opts.count - 1 { Divider().overlay(Theme.line).padding(.leading, 20) }
                    }
                }
                TGHint(text: item?.hint ?? "")
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(item?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BlockedView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if model.blockedByMe.isEmpty {
                    Text("Вы никого не заблокировали").foregroundColor(Theme.muted).padding(40)
                }
                ForEach(Array(model.blockedByMe), id: \.self) { id in
                    HStack(spacing: 12) {
                        AvatarView(name: model.displayName(id), url: model.profiles[id]?.avatarURL, color: model.profiles[id]?.color ?? 0, size: 46)
                        Text(model.displayName(id)).font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button("Разблокировать") { Task { await model.setBlocked(id, false) } }
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Заблокированные")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadBlocks(); await model.loadProfiles(Array(model.blockedByMe)) }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image("LaunchLogo").resizable().scaledToFit().frame(width: 96, height: 96).padding(.top, 20)
                Text("Lumo").font(.system(size: 30, weight: .heavy))
                BetaBadge()
                Text(Config.versionLabel).foregroundColor(Theme.muted)
                Text("Приложение в бета-версии: мы ещё исправляем ошибки. Если что-то работает не так — напишите нам.")
                    .font(.footnote).multilineTextAlignment(.center).foregroundColor(Theme.muted).padding(.horizontal, 30)
                Text("Быстрый и красивый мессенджер: переписка, голосовые и видеосообщения, звонки, истории, группы и каналы. Тот же аккаунт работает на сайте и в приложении.")
                    .multilineTextAlignment(.center).foregroundColor(Theme.text).padding(.horizontal, 30)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("О Lumo")
        .navigationBarTitleDisplayMode(.inline)
    }
}


/// Личный канал в профиле
struct ProfileChannelCard: View {
    @EnvironmentObject var model: AppModel
    let p: Profile
    var body: some View {
        if let id = p.channelId {
            Button {
                Task { if model.chat(id) != nil { model.open(id) } else { await model.join(id) } }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("КАНАЛ").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                    HStack(spacing: 12) {
                        AvatarView(name: p.channelTitle ?? "", url: p.channelAvatar, color: p.channelColor, size: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.channelTitle ?? "Канал").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                            Text("\(p.channelMembers) подписч." + (p.channelUsername.map { " · @" + $0 } ?? "")).font(.subheadline).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(Theme.muted)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 22).fill(Theme.panel))
                .padding(.horizontal, 14)
            }
            .buttonStyle(BouncyButtonStyle())
        }
    }
}
