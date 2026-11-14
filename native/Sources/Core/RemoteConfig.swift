import SwiftUI

/// Настройки с сервера (таблица lm_config, ключи app / look / announce): то, что можно менять без выпуска новой версии.
/// Последний полученный вариант хранится на устройстве, поэтому всё работает и без сети.
struct RemoteWall: Identifiable { let n: Int; let url: URL; let premium: Bool; var section: String? = nil; var id: Int { 1000 + n } }
struct RemoteSticker: Identifiable { let id: String; let url: URL }
struct RemotePack: Identifiable { let id: String; let name: String; let items: [RemoteSticker] }
struct Announce: Equatable { let id: String; let title: String; let text: String; let url: URL?; let button: String? }

let stickerImgPrefix = "img:"

final class RemoteConfig: ObservableObject {
    static let shared = RemoteConfig()
    @Published private(set) var cfg: JSON = [:]
    private var lastFetch = Date.distantPast
    private let d = UserDefaults.standard

    private init() {
        if let data = d.data(forKey: "lm_rcfg"), let o = (try? JSONSerialization.jsonObject(with: data)) as? JSON { cfg = o }
    }

    func refresh(force: Bool = false) async {
        if !force && Date().timeIntervalSince(lastFetch) < 60 { return }
        lastFetch = Date()
        guard let o = (try? await API.shared.rpc("lm_get_config")) as? JSON else { return }
        if let data = try? JSONSerialization.data(withJSONObject: o) { d.set(data, forKey: "lm_rcfg") }
        await MainActor.run { self.cfg = o }
        await syncGames()
    }

    // MARK: переключатели
    private var app: JSON { cfg["app"] as? JSON ?? [:] }
    private var look: JSON { cfg["look"] as? JSON ?? [:] }
    /// функция включена, пока сервер явно не выключил её
    func on(_ feature: String) -> Bool { ((app["features"] as? JSON)?[feature] as? Bool) ?? true }
    var legacyLogin: Bool { ((app["features"] as? JSON)?["legacy_login"] as? Bool) ?? false }
    var secretNumbers: [String] { ((app["login"] as? JSON)?["secret_numbers"] as? [String]) ?? ["79999999999"] }

    // MARK: обязательное обновление
    private var minV: JSON { app["min_version"] as? JSON ?? [:] }
    static var build: Int { Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") ?? 0 }
    var needsUpdate: Bool { (minV["ios"] as? Int ?? 0) > RemoteConfig.build }
    var updateText: String { (minV["text"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Вышла новая версия Lumo. Обновите приложение, чтобы продолжить." }
    var updateURL: URL? { (minV["url_ios"] as? String).flatMap { $0.isEmpty ? nil : URL(string: $0) } }

    // MARK: объявление в списке чатов
    var announce: Announce? {
        guard let a = cfg["announce"] as? JSON, let text = a["text"] as? String, !text.isEmpty else { return nil }
        let id = a["id"].map { "\($0)" } ?? text
        if let p = a["platforms"] as? [String], !p.contains("ios") { return nil }
        if let u = a["until"] as? String, let t = ISO8601DateFormatter().date(from: u), t < Date() { return nil }
        return Announce(id: id, title: (a["title"] as? String) ?? "Объявление", text: text,
                        url: (a["url"] as? String).flatMap { URL(string: $0) }, button: a["button"] as? String)
    }

    // MARK: оформление
    static func hex(_ v: Any?) -> UInt32? {
        guard var s = v as? String else { return nil }
        s = s.replacingOccurrences(of: "#", with: "")
        return s.count == 6 ? UInt32(s, radix: 16) : nil
    }
    /// дополнительные цвета: [{a:"#rrggbb", b:"#rrggbb", premium:true}]
    var accents: [(UInt32, UInt32, Bool)] {
        ((look["accents"] as? [JSON]) ?? []).compactMap { j in
            guard let a = RemoteConfig.hex(j["a"]), let b = RemoteConfig.hex(j["b"]) else { return nil }
            return (a, b, (j["premium"] as? Bool) ?? false)
        }
    }
    /// дополнительные обои: [{n:1, url:"https://…", premium:false, section:"Новогодние"}] — номер обоев 1000+n
    var walls: [RemoteWall] {
        ((look["walls"] as? [JSON]) ?? []).compactMap { j in
            guard let n = j["n"] as? Int, let u = (j["url"] as? String).flatMap(URL.init(string:)) else { return nil }
            return RemoteWall(n: n, url: u, premium: (j["premium"] as? Bool) ?? false, section: (j["section"] as? String).flatMap { $0.isEmpty ? nil : $0 })
        }
    }
    func wall(_ index: Int) -> RemoteWall? { walls.first { $0.id == index } }
    /// наборы стикеров: [{id, name, items:[{id, url}]}]
    var packs: [RemotePack] {
        ((look["stickers"] as? [JSON]) ?? []).compactMap { p in
            guard let id = p["id"] as? String else { return nil }
            let items: [RemoteSticker] = ((p["items"] as? [JSON]) ?? []).compactMap { i in
                guard let u = (i["url"] as? String).flatMap(URL.init(string:)) else { return nil }
                return RemoteSticker(id: (i["id"] as? String) ?? u.lastPathComponent, url: u)
            }
            return items.isEmpty ? nil : RemotePack(id: id, name: (p["name"] as? String) ?? id, items: items)
        }
    }

    // MARK: игры: страница скачивается один раз на каждую новую версию
    private var gamesFile: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("games.html")
    }
    func gamesHTML() -> String? {
        guard d.integer(forKey: "lm_games_ver") > 0 else { return nil }
        guard let s = try? String(contentsOf: gamesFile, encoding: .utf8), s.contains("/*CFG*/") else { return nil }
        return s
    }
    private func syncGames() async {
        let ver = app["games_ver"] as? Int ?? 0
        if ver <= 0 {
            if d.integer(forKey: "lm_games_ver") != 0 { d.set(0, forKey: "lm_games_ver"); try? FileManager.default.removeItem(at: gamesFile) }
            return
        }
        if d.integer(forKey: "lm_games_ver") == ver { return }
        guard let o = (try? await API.shared.rpc("lm_games_html")) as? JSON, let html = o["html"] as? String, html.contains("/*CFG*/"),
              let v = o["ver"] as? Int, v == ver else { return }
        do { try html.write(to: gamesFile, atomically: true, encoding: .utf8); d.set(ver, forKey: "lm_games_ver") } catch {}
    }
}

/// Экран «Обновите приложение» — когда версия старше той, что указана на сервере
struct UpdateRequiredScreen: View {
    @ObservedObject var rc = RemoteConfig.shared
    @Environment(\.openURL) private var openURL
    var body: some View {
        ZStack {
            AuroraBackground(intensity: 1, speed: 1)
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    Circle().fill(Theme.accent).frame(width: 110, height: 110).shadow(color: Theme.a1.opacity(0.5), radius: 24)
                    Image(systemName: "arrow.down.app.fill").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                }
                Text("Нужно обновление").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                Text(rc.updateText).font(.system(size: 16)).foregroundColor(.white.opacity(0.85)).multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer()
                if let u = rc.updateURL {
                    GradientButton(title: "Обновить") { openURL(u) }.padding(.horizontal, 24)
                }
                Button("Проверить ещё раз") { Task { await rc.refresh(force: true) } }
                    .font(.subheadline.weight(.semibold)).foregroundColor(.white.opacity(0.8)).padding(.bottom, 30)
            }
        }
        .ignoresSafeArea()
    }
}

/// Объявление в списке чатов (текст задаётся на сервере); крестик скрывает его до следующего объявления
struct AnnounceCard: View {
    @ObservedObject var rc = RemoteConfig.shared
    @AppStorage("lm_ann_hide") private var hidden = ""
    @Environment(\.openURL) private var openURL
    var body: some View {
        if let a = rc.announce, hidden != a.id {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "megaphone.fill").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 38, height: 38).background(Circle().fill(Theme.accent))
                VStack(alignment: .leading, spacing: 3) {
                    Text(a.title).font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                    Text(a.text).font(.system(size: 14)).foregroundColor(Theme.muted).fixedSize(horizontal: false, vertical: true)
                    if let u = a.url {
                        Button(a.button ?? "Подробнее") { openURL(u) }.font(.system(size: 14, weight: .bold)).foregroundColor(Theme.a1).padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
                Button { withAnimation { hidden = a.id } } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted).padding(6)
                }
            }
            .padding(12)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

/// Стикер-картинка с сервера
struct RemoteStickerView: View {
    let url: URL
    var size: CGFloat = 96
    var body: some View {
        CachedImage(url: url, kind: .sticker) { $0.resizable().scaledToFit() } placeholder: { RoundedRectangle(cornerRadius: 14).fill(Theme.panel2.opacity(0.5)) }
            .frame(width: size, height: size)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
