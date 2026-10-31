import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers
import VisionKit

/// Особые текстовые сообщения (без изменения схемы базы): геопозиция и контакт.
/// Они хранятся как обычный текст, поэтому шифруются и читаются даже в старых версиях.
enum SpecialMsg {
    case location(title: String, lat: Double, lng: Double)
    case contact(name: String, id: String)

    static func locationBody(title: String?, lat: Double, lng: Double) -> String {
        "📍 \((title?.isEmpty == false ? title! : "Геопозиция"))\nhttps://maps.apple.com/?ll=\(String(format: "%.6f", lat)),\(String(format: "%.6f", lng))"
    }

    static func contactBody(name: String, id: String) -> String { "👤 \(name)\nlumo://user/\(id)" }

    static func parse(_ body: String?) -> SpecialMsg? {
        guard let b = body else { return nil }
        let lines = b.components(separatedBy: "\n")
        guard lines.count >= 2, let last = lines.last else { return nil }
        let head = lines.dropLast().joined(separator: "\n")
        if head.hasPrefix("📍 "), last.hasPrefix("https://maps.apple.com/?ll=") {
            let c = last.dropFirst("https://maps.apple.com/?ll=".count).split(separator: ",")
            if c.count == 2, let la = Double(c[0]), let lo = Double(c[1]) {
                return .location(title: String(head.dropFirst(2)), lat: la, lng: lo)
            }
        }
        if head.hasPrefix("👤 "), last.hasPrefix("lumo://user/") {
            return .contact(name: String(head.dropFirst(2)), id: String(last.dropFirst("lumo://user/".count)))
        }
        return nil
    }
}

private struct Pin: Identifiable { let id = UUID(); let c: CLLocationCoordinate2D }

/// Карточка геопозиции в ленте
struct LocationCard: View {
    let title: String, lat: Double, lng: Double, mine: Bool
    var body: some View {
        let c = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        VStack(alignment: .leading, spacing: 6) {
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: c, latitudinalMeters: 500, longitudinalMeters: 500)),
                interactionModes: [], annotationItems: [Pin(c: c)]) { p in MapMarker(coordinate: p.c, tint: .red) }
                .frame(width: 240, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .allowsHitTesting(false)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(mine ? .white : Theme.text).lineLimit(2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let u = URL(string: "https://maps.apple.com/?ll=\(lat),\(lng)&q=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(u)
            }
        }
    }
}

/// Карточка контакта в ленте: по нажатию открывается личный чат
struct ContactCard: View {
    @EnvironmentObject var model: AppModel
    let name: String, id: String, mine: Bool
    var body: some View {
        Button { Task { await model.openDM(id) } } label: {
            HStack(spacing: 10) {
                avatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Text("Контакт").font(.caption).opacity(0.7)
                }
                .foregroundColor(mine ? .white : Theme.text)
            }
            .frame(minWidth: 200, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var avatar: some View {
        let p = model.profiles[id]
        ZStack {
            Circle().fill(mine ? Color.white.opacity(0.25) : Theme.a1)
            if let u = p?.avatarURL.flatMap(URL.init(string:)) {
                CachedImage(url: u) { $0.resizable().scaledToFill() } placeholder: { Color.clear }.clipShape(Circle())
            } else {
                Text(String(name.prefix(1)).uppercased()).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }
        }
        .frame(width: 44, height: 44)
        .task { if model.profiles[id] == nil { _ = await model.profile(id) } }
    }
}

// MARK: геолокация

final class OneShotLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coord: CLLocationCoordinate2D?
    @Published var denied = false
    private let mgr = CLLocationManager()

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        switch mgr.authorizationStatus {
        case .notDetermined: mgr.requestWhenInUseAuthorization()
        case .denied, .restricted: denied = true
        default: mgr.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        switch m.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: denied = false; m.requestLocation()
        case .denied, .restricted: denied = true
        default: break
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations l: [CLLocation]) { coord = l.last?.coordinate }
    func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {}
}

struct NearbyPlace: Identifiable { let id = UUID(); let name: String; let addr: String; let c: CLLocationCoordinate2D }

/// Вкладка «Геопозиция»
struct LocationPanel: View {
    var onPick: (String?, Double, Double) -> Void
    var onSoon: (String) -> Void
    @StateObject private var loc = OneShotLocation()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State private var places: [NearbyPlace] = []

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $region, showsUserLocation: true).frame(height: 230)
            ScrollView {
                VStack(spacing: 0) {
                    row("mappin", .blue, "Отправить геопозицию", "С точностью до \(accuracy)") {
                        if let c = loc.coord { onPick(nil, c.latitude, c.longitude) }
                    }
                    row("dot.radiowaves.left.and.right", .green, "Транслировать геопозицию", "Обновляется в реальном времени · в разработке") {
                        onSoon("Трансляция геопозиции")
                    }
                    if loc.denied {
                        Text("Разрешите доступ к геопозиции в настройках iPhone").font(.subheadline).foregroundColor(Theme.muted).padding(20)
                    }
                    if !places.isEmpty {
                        Text("ИЛИ ВЫБРАТЬ МЕСТО").font(.system(size: 13)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 6)
                        ForEach(places) { p in
                            row("building.2.fill", .orange, p.name, p.addr) { onPick(p.name, p.c.latitude, p.c.longitude) }
                        }
                    }
                    Color.clear.frame(height: 110)
                }
            }
        }
        .onAppear { loc.start() }
        .onReceive(loc.$coord.compactMap { $0 }) { c in
            region = MKCoordinateRegion(center: c, latitudinalMeters: 800, longitudinalMeters: 800)
            Task { await search(c) }
        }
    }

    private var accuracy: String { loc.coord == nil ? "…" : "20 м" }

    private func row(_ icon: String, _ color: Color, _ title: String, _ sub: String, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 48, height: 48).background(Circle().fill(color))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    Text(sub).font(.system(size: 14)).foregroundColor(Theme.muted).lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func search(_ c: CLLocationCoordinate2D) async {
        let r = MKLocalPointsOfInterestRequest(center: c, radius: 700)
        guard let res = try? await MKLocalSearch(request: r).start() else { return }
        places = res.mapItems.prefix(15).map { i in
            let p = i.placemark
            let addr = [p.thoroughfare, p.subThoroughfare].compactMap { $0 }.joined(separator: ", ")
            return NearbyPlace(name: i.name ?? "Место", addr: addr.isEmpty ? (p.locality ?? "") : addr, c: p.coordinate)
        }
    }
}

/// Вкладка «Контакт»
struct ContactsPanel: View {
    @EnvironmentObject var model: AppModel
    var onPick: (Profile) -> Void
    @State private var q = ""

    private var list: [Profile] {
        var ids = Set(model.contacts)
        for c in model.chats where c.isPrivate { if let p = c.peerId { ids.insert(p) } }
        if let me = model.myId { ids.remove(me) }
        let all = ids.compactMap { model.profiles[$0] }.filter { !$0.isBot }
        let f = q.trimmingCharacters(in: .whitespaces).lowercased()
        let r = f.isEmpty ? all : all.filter { $0.name.lowercased().contains(f) || $0.username.lowercased().contains(f) }
        return r.sorted { name($0).localizedCaseInsensitiveCompare(name($1)) == .orderedAscending }
    }

    private func name(_ p: Profile) -> String { model.aliases[p.id] ?? p.name }
    private func letter(_ p: Profile) -> String { String(name(p).prefix(1)).uppercased() }

    var body: some View {
        let groups = Dictionary(grouping: list, by: letter).sorted { $0.key < $1.key }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Поиск", text: $q).padding(12).lumoGlass(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 14).padding(.bottom, 6)
                if list.isEmpty { Text("Контактов пока нет").foregroundColor(Theme.muted).padding(24) }
                ForEach(groups, id: \.key) { g in
                    Text(g.key).font(.system(size: 15)).foregroundColor(Theme.muted).padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 4)
                    VStack(spacing: 0) {
                        ForEach(g.value) { p in
                            Button { onPick(p) } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Theme.a1)
                                        if let u = p.avatarURL.flatMap(URL.init(string:)) {
                                            CachedImage(url: u) { $0.resizable().scaledToFill() } placeholder: { Color.clear }.clipShape(Circle())
                                        } else {
                                            Text(letter(p)).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: 46, height: 46)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name(p)).font(.system(size: 17, weight: .medium)).foregroundColor(Theme.text).lineLimit(1)
                                        if !p.username.isEmpty { Text("@" + p.username).font(.system(size: 14)).foregroundColor(Theme.muted) }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14).padding(.vertical, 7)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 22).fill(Theme.panel))
                    .padding(.horizontal, 14)
                }
                Color.clear.frame(height: 110)
            }
        }
        .task {
            let need = Set(model.contacts).union(model.chats.compactMap { $0.isPrivate ? $0.peerId : nil })
            await model.loadProfiles(Array(need))
        }
    }
}

/// Файлы, которые уже отправлялись в чатах (для «Недавно отправленные» и «Ваши чаты»)
enum RecentFiles {
    static func list(_ model: AppModel, audio: Bool) -> [Message] {
        var out: [Message] = []
        for (_, msgs) in model.messages {
            for m in msgs where m.kind == "file" && !m.deleted && m.mediaURL != nil && !m.id.isNegative {
                let isAudio = ["mp3", "m4a", "wav", "flac", "ogg", "aac", "opus"].contains((m.fileName as NSString).pathExtension.lowercased())
                if isAudio == audio { out.append(m) }
            }
        }
        var seen = Set<String>()
        return out.sorted { $0.createdAt > $1.createdAt }.filter { seen.insert($0.mediaURL ?? "").inserted }.prefix(30).map { $0 }
    }
}

private extension Int { var isNegative: Bool { self < 0 } }

/// Вкладки «Файл» и «Звук»
struct FilesPanel: View {
    @EnvironmentObject var model: AppModel
    let audio: Bool
    var onGallery: () -> Void
    var onPickFile: () -> Void
    var onScan: () -> Void
    var onResend: (Message) -> Void

    var body: some View {
        let recent = RecentFiles.list(model, audio: audio)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    if !audio { action("photo", "Выбрать из Галереи", onGallery); Divider().padding(.leading, 62) }
                    action("icloud", "Выбрать из файлов", onPickFile)
                    if !audio { Divider().padding(.leading, 62); action("doc.viewfinder", "Сканировать документ", onScan) }
                }
                .background(RoundedRectangle(cornerRadius: 24).fill(Theme.panel)).padding(.horizontal, 14)
                if !recent.isEmpty {
                    Text(audio ? "ВАШИ ЧАТЫ" : "НЕДАВНО ОТПРАВЛЕННЫЕ").font(.system(size: 14)).foregroundColor(Theme.muted)
                        .padding(.horizontal, 28).padding(.top, 22).padding(.bottom, 6)
                    VStack(spacing: 0) {
                        ForEach(Array(recent.enumerated()), id: \.element.id) { i, m in
                            if i > 0 { Divider().padding(.leading, 74) }
                            Button { onResend(m) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: audio ? "play.fill" : "doc.fill").font(.system(size: 20)).foregroundColor(.white)
                                        .frame(width: 48, height: 48).background(Circle().fill(Theme.a1))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(m.fileName).font(.system(size: 17, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                                        Text([m.fileSize.map { Fmt.size($0) }, Fmt.day(m.createdAt)].compactMap { $0 }.joined(separator: " · "))
                                            .font(.system(size: 14)).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 24).fill(Theme.panel)).padding(.horizontal, 14)
                } else {
                    Text(audio ? "Здесь появятся аудиофайлы из ваших чатов" : "Здесь появятся файлы, которые вы отправляли")
                        .font(.subheadline).foregroundColor(Theme.muted).padding(24)
                }
                Color.clear.frame(height: 110)
            }
        }
    }

    private func action(_ icon: String, _ t: String, _ f: @escaping () -> Void) -> some View {
        Button(action: f) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(Theme.a1).frame(width: 30)
                Text(t).font(.system(size: 20)).foregroundColor(Theme.a1)
                Spacer()
            }
            .padding(.horizontal, 18).frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}

/// Сканер документов: страницы собираются в один PDF
struct DocScanner: UIViewControllerRepresentable {
    var onDone: (Data?) -> Void
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let v = VNDocumentCameraViewController(); v.delegate = context.coordinator; return v
    }
    func updateUIViewController(_ v: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(onDone) }

    final class Coord: NSObject, VNDocumentCameraViewControllerDelegate {
        let done: (Data?) -> Void
        init(_ d: @escaping (Data?) -> Void) { done = d }
        func documentCameraViewControllerDidCancel(_ c: VNDocumentCameraViewController) { done(nil) }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFailWithError error: Error) { done(nil) }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let pdf = PDFBuilder.make((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
            done(pdf)
        }
    }
}

enum PDFBuilder {
    static func make(_ pages: [UIImage]) -> Data? {
        guard let first = pages.first else { return nil }
        let r = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: first.size))
        return r.pdfData { ctx in
            for p in pages {
                let b = CGRect(origin: .zero, size: p.size)
                ctx.beginPage(withBounds: b, pageInfo: [:])
                p.draw(in: b)
            }
        }
    }
}
