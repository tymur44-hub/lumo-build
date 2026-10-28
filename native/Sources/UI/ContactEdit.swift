import SwiftUI
import PhotosUI

/// «Изменить контакт»: имя, фамилия, заметка и личное фото — всё это видите только вы
struct ContactEditView: View {
    let peerId: String
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var first = ""
    @State private var last = ""
    @State private var note = ""
    @State private var photo: String?          // текущая ссылка на личное фото (nil — настоящее фото человека)
    @State private var newPhoto: UIImage?
    @State private var pick: PhotosPickerItem?
    @State private var saving = false
    @State private var confirmDelete = false
    @State private var loaded = false

    private var peer: Profile? { model.profiles[peerId] }
    private var realName: String { peer?.name ?? "контакта" }
    private var shownPhoto: String? { photo ?? peer?.avatarURL }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    avatar.padding(.top, 62)
                    card {
                        TextField("Имя", text: $first).padding(.horizontal, 18).frame(height: 54)
                        Divider().padding(.leading, 18)
                        TextField("Фамилия", text: $last).padding(.horizontal, 18).frame(height: 54)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        card { TextField("Заметка", text: $note, axis: .vertical).lineLimit(1...4).padding(.horizontal, 18).padding(.vertical, 16) }
                        Text("Заметку видите только Вы.").font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 20)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        card {
                            PhotosPicker(selection: $pick, matching: .images) {
                                HStack(spacing: 14) {
                                    Image(systemName: "camera.badge.ellipsis").font(.system(size: 22)).frame(width: 34)
                                    Text("Установить фото для \(first.isEmpty ? realName : first)").lineLimit(1)
                                    Spacer()
                                }
                                .foregroundColor(Theme.a1).padding(.horizontal, 18).frame(height: 56)
                            }
                            if photo != nil || newPhoto != nil {
                                Divider().padding(.leading, 18)
                                Button { photo = nil; newPhoto = nil } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "arrow.uturn.backward").font(.system(size: 20)).frame(width: 34)
                                        Text("Вернуть настоящее фото"); Spacer()
                                    }
                                    .foregroundColor(Theme.a1).padding(.horizontal, 18).frame(height: 56)
                                }
                            }
                        }
                        Text("Вы можете заменить фотографию \(realName) другой по своему выбору. Она будет видна только Вам.")
                            .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 20)
                    }
                    if model.isContact(peerId) {
                        card {
                            Button { confirmDelete = true } label: {
                                HStack { Text("Удалить контакт"); Spacer() }
                                    .foregroundColor(Theme.danger).padding(.horizontal, 18).frame(height: 56)
                            }
                        }
                    }
                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundColor(Theme.text)
                        .frame(width: 48, height: 48).lumoGlass(Circle(), interactive: true)
                }
                Spacer()
                Button { Task { await save() } } label: {
                    Group {
                        if saving { ProgressView().tint(.white) }
                        else { Image(systemName: "checkmark").font(.system(size: 19, weight: .bold)) }
                    }
                    .foregroundColor(.white).frame(width: 48, height: 48)
                    .background(Circle().fill(Theme.a1.opacity(0.0)))
                    .lumoGlass(Circle(), interactive: true, tint: Theme.a1)
                    .background(Circle().fill(Theme.a1).opacity(glassAvailable ? 0 : 1))
                }
                .disabled(saving)
            }
            .padding(.horizontal, 16).padding(.top, 10)
        }
        .onAppear(perform: fill)
        .onChange(of: pick) { item in
            guard let item = item else { return }
            pick = nil
            Task {
                guard let d = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: d) else { return }
                newPhoto = img
            }
        }
        .confirmationDialog("Удалить контакт?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) { Task { await model.removeContact(peerId); dismiss() } }
            Button("Отмена", role: .cancel) {}
        }
    }

    private var glassAvailable: Bool {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    private var avatar: some View {
        Group {
            if let img = newPhoto {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 116, height: 116).clipShape(Circle())
            } else {
                AvatarView(name: first.isEmpty ? realName : first, url: shownPhoto, color: peer?.color ?? 0, size: 116)
            }
        }
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0, content: content)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 26))
    }

    private func fill() {
        guard !loaded else { return }
        loaded = true
        let full = model.aliases[peerId] ?? peer?.name ?? ""
        let parts = full.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
        first = parts.first ?? ""
        last = parts.count > 1 ? parts[1] : ""
        note = model.contactNotes[peerId] ?? ""
        photo = model.contactPhotos[peerId]
    }

    private func save() async {
        saving = true
        defer { saving = false }
        var url = photo
        if let img = newPhoto {
            guard let u = await model.uploadContactPhoto(img) else { return }
            url = u
        }
        let name = [first, last].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
        // имя, совпадающее с настоящим, равно «без своего имени»
        let alias = name == (peer?.name ?? "") ? "" : name
        guard await model.setContactExtra(peerId, note: note.trimmingCharacters(in: .whitespacesAndNewlines), photo: url) else { return }
        await model.setAlias(peerId, alias)
        dismiss()
    }
}
