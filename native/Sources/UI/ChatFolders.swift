import SwiftUI

/// Свои папки и архив чатов. Хранятся на устройстве, отдельно для каждого аккаунта.
@MainActor
final class FolderStore: ObservableObject {
    static let shared = FolderStore()
    struct Folder: Codable, Identifiable, Equatable { var id: String; var name: String; var icon: String; var chats: [String] }
    @Published private(set) var folders: [Folder] = []
    @Published private(set) var archived: Set<String> = []
    private var uid = ""

    private var keyF: String { "lm_folders_" + uid }
    private var keyA: String { "lm_archive_" + uid }

    /// подхватить данные нужного аккаунта (при входе и переключении)
    func use(_ id: String?) {
        guard let id = id, id != uid else { return }
        uid = id
        folders = (UserDefaults.standard.data(forKey: keyF).flatMap { try? JSONDecoder().decode([Folder].self, from: $0) }) ?? []
        archived = Set(UserDefaults.standard.stringArray(forKey: keyA) ?? [])
    }

    func save(_ f: Folder) {
        if let i = folders.firstIndex(where: { $0.id == f.id }) { folders[i] = f } else { folders.append(f) }
        persist()
    }
    func delete(_ id: String) { folders.removeAll { $0.id == id }; persist() }
    func setArchived(_ chatId: String, _ on: Bool) {
        if on { archived.insert(chatId) } else { archived.remove(chatId) }
        UserDefaults.standard.set(Array(archived), forKey: keyA)
    }
    private func persist() { if let d = try? JSONEncoder().encode(folders) { UserDefaults.standard.set(d, forKey: keyF) } }

    static let icons = ["folder.fill", "star.fill", "heart.fill", "briefcase.fill", "house.fill", "graduationcap.fill",
                        "gamecontroller.fill", "music.note", "airplane", "cart.fill", "person.2.fill", "bolt.fill"]
}

/// Создание и правка своей папки: название, значок, какие чаты в ней
struct FolderEditor: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var folder: FolderStore.Folder
    let isNew: Bool
    @State private var q = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Название папки", text: $folder.name)
                        .font(.system(size: 17, weight: .semibold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(FolderStore.icons, id: \.self) { ic in
                                Button { UISelectionFeedbackGenerator().selectionChanged(); folder.icon = ic } label: {
                                    Image(systemName: ic).font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(folder.icon == ic ? .white : Theme.text)
                                        .frame(width: 42, height: 42)
                                        .background(Circle().fill(folder.icon == ic ? Theme.a1 : Theme.text.opacity(0.07)))
                                }
                                .buttonStyle(BouncyButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Чаты в папке — \(folder.chats.count)") {
                    TextField("Поиск", text: $q)
                    ForEach(model.chats.filter { q.isEmpty || $0.displayName.lowercased().contains(q.lowercased()) }) { c in
                        Button {
                            if let i = folder.chats.firstIndex(of: c.id) { folder.chats.remove(at: i) } else { folder.chats.append(c.id) }
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(name: c.displayName, url: c.displayAvatar, color: c.displayColor, size: 38,
                                           icon: c.isPrivate && c.peerId == model.myId ? "bookmark.fill" : nil)
                                Text(c.isPrivate && c.peerId == model.myId ? "Избранное" : c.displayName).foregroundColor(Theme.text).lineLimit(1)
                                Spacer()
                                Image(systemName: folder.chats.contains(c.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21)).foregroundColor(folder.chats.contains(c.id) ? Theme.a1 : Theme.muted.opacity(0.5))
                            }
                        }
                    }
                }
                if !isNew {
                    Section {
                        Button(role: .destructive) { FolderStore.shared.delete(folder.id); dismiss() } label: { Label("Удалить папку", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isNew ? "Новая папка" : "Папка").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        var f = folder
                        f.name = f.name.trimmingCharacters(in: .whitespaces)
                        if f.name.isEmpty { f.name = "Папка" }
                        FolderStore.shared.save(f)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Архив: чаты, убранные из общего списка
struct ArchiveView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var store = FolderStore.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    let list = model.chats.filter { store.archived.contains($0.id) }
                    if list.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "archivebox").font(.system(size: 44)).foregroundColor(Theme.muted)
                            Text("Архив пуст").font(.headline)
                            Text("Смахните чат влево и нажмите «В архив», чтобы убрать его сюда").font(.subheadline).foregroundColor(Theme.muted)
                                .multilineTextAlignment(.center).padding(.horizontal, 40)
                        }
                        .padding(.top, 80)
                    }
                    ForEach(list) { c in
                        Button { dismiss(); model.path.append(c.id) } label: { ChatRow(chat: c) }
                            .buttonStyle(RowButtonStyle())
                            .contextMenu {
                                Button { withAnimation { store.setArchived(c.id, false) } } label: { Label("Вернуть из архива", systemImage: "tray.and.arrow.up") }
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Архив").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } } }
        }
    }
}
