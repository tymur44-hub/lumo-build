import SwiftUI
import QuickLook

// MARK: - Фото в сообщении: с телефона; из сети — сразу или по нажатию (по настройкам автозагрузки)

struct AutoPhoto: View {
    let url: URL
    let size: Int?
    var onOpen: (() -> Void)? = nil
    @State private var image: UIImage?
    @State private var loading = false
    @State private var asked = false

    init(url: URL, size: Int?, onOpen: (() -> Void)? = nil) {
        self.url = url; self.size = size; self.onOpen = onOpen
        _image = State(initialValue: ImageCache.shared.get(url))
    }

    var body: some View {
        ZStack {
            if let i = image {
                Image(uiImage: i).resizable().scaledToFill()
            } else {
                Color.white.opacity(0.06)
                if loading { ProgressView() }
                else {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.down").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            .frame(width: 48, height: 48).background(Circle().fill(Color.black.opacity(0.45)))
                        if let s = size { Text(Fmt.size(s)).font(.caption.weight(.semibold)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(Color.black.opacity(0.45))) }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        // одно касание: фото уже есть — открыть во весь экран, нет — загрузить
        .onTapGesture {
            if image != nil { onOpen?() }
            else if !loading { Task { await load() } }
        }
        .task(id: url) {
            if image != nil { return }
            if ImageCache.shared.has(url) || AutoDownloadSettings.shared.allow(.photo, bytes: size) { await load() }
        }
    }

    private func load() async {
        loading = true
        image = await ImageCache.shared.load(url, kind: .photo)
        loading = false
    }
}

// MARK: - Файл в сообщении: скачивается на телефон один раз и открывается с него

struct FileBubbleView: View {
    let m: Message
    let mine: Bool
    @State private var local: URL?
    @State private var loading = false

    private var remote: URL? { m.mediaURL.flatMap(URL.init(string:)) }

    var body: some View {
        Button { Task { await open() } } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(mine ? Color.white.opacity(0.2) : Theme.a1)
                    if loading { ProgressView().tint(.white) }
                    else { Image(systemName: local != nil ? "doc.fill" : "arrow.down").font(.title3).foregroundColor(.white) }
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.fileName).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                    if let s = m.fileSize { Text(Fmt.size(s) + (local != nil ? " · на телефоне" : "")).font(.caption).opacity(0.7) }
                }
                .foregroundColor(mine ? .white : Theme.text)
            }
        }
        .buttonStyle(.plain)
        .disabled(remote == nil)
        .task {
            guard let u = remote else { return }
            if let l = FileStore.shared.local(u, .file) { local = l; return }
            if AutoDownloadSettings.shared.allow(.file, bytes: m.fileSize) { loading = true; local = await FileStore.shared.fetch(u, .file); loading = false }
        }
    }

    private func open() async {
        guard let u = remote else { return }
        if local == nil {
            loading = true
            local = await FileStore.shared.fetch(u, .file)
            loading = false
        }
        guard let l = local else { AppModel.shared.say("Не удалось скачать файл"); return }
        // файл хранится под служебным именем — показываем с настоящим
        let named = FileManager.default.temporaryDirectory.appendingPathComponent(m.fileName.isEmpty ? l.lastPathComponent : m.fileName)
        try? FileManager.default.removeItem(at: named)
        let show = (try? FileManager.default.linkItem(at: l, to: named)) != nil || (try? FileManager.default.copyItem(at: l, to: named)) != nil ? named : l
        FilePreview.show(show)
    }
}

/// Просмотр файла (QuickLook): «Поделиться», «Сохранить в Файлы» — там же
enum FilePreview {
    final class Source: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(_ u: URL) { url = u }
        func numberOfPreviewItems(in c: QLPreviewController) -> Int { 1 }
        func previewController(_ c: QLPreviewController, previewItemAt i: Int) -> QLPreviewItem { url as NSURL }
    }
    private static var keep: Source?
    @MainActor static func show(_ u: URL) {
        let src = Source(u); keep = src
        let c = QLPreviewController(); c.dataSource = src
        var top = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
        while let p = top?.presentedViewController { top = p }
        top?.present(c, animated: true)
    }
}

// MARK: - Кольцевая диаграмма

struct DonutChart: View {
    struct Slice: Identifiable { let id: String; let value: Double; let color: Color }
    let slices: [Slice]
    let center: String
    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height), r = s / 2, w = s * 0.25
            let total = max(slices.reduce(0) { $0 + $1.value }, 1)
            ZStack {
                if slices.allSatisfy({ $0.value <= 0 }) {
                    Circle().stroke(Theme.line, lineWidth: w).padding(w / 2)
                }
                ForEach(Array(arcs(total).enumerated()), id: \.offset) { _, a in
                    Arc(start: a.0, end: a.1).stroke(a.2, style: StrokeStyle(lineWidth: w, lineCap: .butt)).padding(w / 2)
                    // доля на самом секторе (если сектор заметный)
                    if a.1 - a.0 > 0.045 {
                        let mid = (a.0 + a.1) / 2 * 2 * Double.pi - Double.pi / 2
                        Text(pct((a.1 - a.0) * 100)).font(.system(size: a.1 - a.0 > 0.12 ? 15 : 11, weight: .bold)).foregroundColor(.white)
                            .position(x: r + CGFloat(cos(mid)) * (r - w / 2), y: r + CGFloat(sin(mid)) * (r - w / 2))
                    }
                }
                Text(center).font(.system(size: s * 0.11, weight: .bold)).foregroundColor(Theme.text).minimumScaleFactor(0.5).lineLimit(1).padding(.horizontal, w + 6)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity)
        }
    }
    private func arcs(_ total: Double) -> [(Double, Double, Color)] {
        var acc = 0.0, out: [(Double, Double, Color)] = []
        for sl in slices where sl.value > 0 {
            let a = acc / total, b = (acc + sl.value) / total
            out.append((a + 0.002, max(a + 0.002, b - 0.002), sl.color)); acc += sl.value
        }
        return out
    }
    private func pct(_ p: Double) -> String { p >= 10 ? String(format: "%.0f%%", p) : String(format: "%.1f%%", p) }
    struct Arc: Shape {
        var start: Double, end: Double
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: min(rect.width, rect.height) / 2,
                     startAngle: .radians(start * 2 * .pi - .pi / 2), endAngle: .radians(end * 2 * .pi - .pi / 2), clockwise: false)
            return p
        }
    }
}

// MARK: - «Данные и память»

struct DataStorageView: View {
    @ObservedObject private var stats = NetStats.shared
    @ObservedObject private var ad = AutoDownloadSettings.shared
    @State private var usage: Int64?
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsGroup {
                    NavigationLink { StorageUsageView() } label: {
                        SettingsRow(icon: "chart.pie.fill", color: Color(hex: 0xf4a73a), title: "Использование памяти") {
                            Text(usage.map(DeviceStorage.fmt) ?? "…").foregroundColor(Theme.muted)
                        }
                    }
                    Divider().overlay(Theme.line).padding(.leading, 50)
                    NavigationLink { NetUsageView() } label: {
                        SettingsRow(icon: "chart.bar.fill", color: Color(hex: 0xa855f7), title: "Использование трафика") {
                            Text(DeviceStorage.fmt(stats.total(net: nil))).foregroundColor(Theme.muted)
                        }
                    }
                }
                SectionTitle(text: "Автозагрузка медиа")
                SettingsGroup {
                    NavigationLink { AutoDownloadView(cellular: true) } label: {
                        SettingsRow(icon: "antenna.radiowaves.left.and.right", color: Color(hex: 0x4cc764), title: "Через мобильную сеть", subtitle: ad.cell.summary)
                    }
                    Divider().overlay(Theme.line).padding(.leading, 50)
                    NavigationLink { AutoDownloadView(cellular: false) } label: {
                        SettingsRow(icon: "wifi", color: Color(hex: 0x3d82f6), title: "Через Wi-Fi", subtitle: ad.wifi.summary)
                    }
                    Divider().overlay(Theme.line).padding(.leading, 50)
                    Button { confirmReset = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 18, weight: .semibold)).frame(width: 30)
                            Text("Сбросить настройки").font(.system(size: 17))
                            Spacer()
                        }
                        .foregroundColor(ad.isDefault ? Theme.muted : Theme.a1)
                        .padding(.vertical, 12)
                    }
                    .disabled(ad.isDefault)
                }
                Text("Медиа меньше указанного размера скачиваются сами, остальное — по нажатию. Всё скачанное хранится на телефоне и открывается без интернета.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Данные и память").navigationBarTitleDisplayMode(.inline)
        .task { usage = await Task.detached { DeviceStorage.usage().values.reduce(0, +) }.value }
        .confirmationDialog("Вернуть настройки автозагрузки по умолчанию?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Сбросить", role: .destructive) { ad.reset() }
        }
    }
}

// MARK: Использование памяти

struct StorageUsageView: View {
    @State private var usage: [DeviceStorage.Bucket: Int64] = [:]
    @State private var loaded = false
    @State private var selected: Set<DeviceStorage.Bucket> = Set(DeviceStorage.Bucket.allCases)
    @State private var clearing = false
    @State private var confirm = false
    @State private var keepDays = DeviceStorage.keepDays
    @State private var maxGB = DeviceStorage.maxGB

    private var order: [DeviceStorage.Bucket] { DeviceStorage.Bucket.allCases.sorted { (usage[$0] ?? 0) > (usage[$1] ?? 0) } }
    private var total: Int64 { usage.values.reduce(0, +) }
    private var chosen: Int64 { selected.reduce(0) { $0 + (usage[$1] ?? 0) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                DonutChart(slices: order.map { .init(id: $0.rawValue, value: Double(usage[$0] ?? 0), color: Color(hex: $0.color)) },
                           center: loaded ? DeviceStorage.fmt(total) : "…")
                    .frame(height: 230).padding(.top, 8)
                Text("Использование памяти").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text)
                let free = DeviceStorage.freeSpace
                let share = free > 0 ? Double(total) / Double(free + total) : 0
                Text("Lumo занимает \(max(share * 100, total > 0 ? 0.1 : 0) < 1 ? String(format: "%.1f", share * 100) : String(format: "%.0f", share * 100))% свободного места на устройстве.")
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.a1.opacity(0.18))
                        Capsule().fill(Theme.a1).frame(width: max(6, g.size.width * CGFloat(min(1, share))))
                    }
                }
                .frame(height: 6).padding(.horizontal, 60)

                SettingsGroup {
                    ForEach(order, id: \.self) { b in
                        let v = usage[b] ?? 0
                        Button {
                            if selected.contains(b) { selected.remove(b) } else { selected.insert(b) }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(selected.contains(b) ? Color(hex: b.color) : Color.clear)
                                    Circle().stroke(selected.contains(b) ? Color(hex: b.color) : Theme.muted, lineWidth: 1.6)
                                    if selected.contains(b) { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                                }
                                .frame(width: 24, height: 24)
                                Text(b.title).font(.system(size: 17)).foregroundColor(Theme.text)
                                + Text(total > 0 && v > 0 ? "  " + percent(v) : "").font(.system(size: 17)).foregroundColor(Theme.muted)
                                Spacer()
                                Text(DeviceStorage.fmt(v)).foregroundColor(Theme.muted)
                            }
                            .padding(.vertical, 11)
                        }
                        .buttonStyle(.plain)
                        if b != order.last { Divider().overlay(Theme.line).padding(.leading, 38) }
                    }
                    Button { confirm = true } label: {
                        HStack(spacing: 6) {
                            if clearing { ProgressView().tint(.white) }
                            Text(selected.count == DeviceStorage.Bucket.allCases.count ? "Очистить весь кэш" : "Очистить выбранное").font(.system(size: 17, weight: .semibold))
                            Text(DeviceStorage.fmt(chosen)).font(.system(size: 17, weight: .semibold)).opacity(0.7)
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.accent, in: Capsule())
                    }
                    .disabled(chosen == 0 || clearing)
                    .opacity(chosen == 0 ? 0.5 : 1)
                    .padding(.vertical, 10)
                }
                Text("Все фото, видео, файлы и голосовые хранятся в облаке Lumo — после очистки их можно скачать снова.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24)

                SectionTitle(text: "Хранить медиа")
                SettingsGroup {
                    Picker("Хранить медиа", selection: $keepDays) {
                        Text("3 дня").tag(3); Text("1 неделю").tag(7); Text("1 месяц").tag(30); Text("Всегда").tag(0)
                    }
                    .pickerStyle(.segmented).padding(.vertical, 10)
                }
                SectionTitle(text: "Максимальный размер кэша")
                SettingsGroup {
                    Picker("Максимальный размер", selection: $maxGB) {
                        Text("1 ГБ").tag(1); Text("5 ГБ").tag(5); Text("20 ГБ").tag(20); Text("Нет").tag(0)
                    }
                    .pickerStyle(.segmented).padding(.vertical, 10)
                }
                Text("Медиа, которые давно не открывали, удаляются сами — чтобы Lumo не занимал лишнее место.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24)
            }
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .onChange(of: keepDays) { v in DeviceStorage.keepDays = v; Task { await Task.detached { DeviceStorage.trim() }.value; await reload() } }
        .onChange(of: maxGB) { v in DeviceStorage.maxGB = v; Task { await Task.detached { DeviceStorage.trim() }.value; await reload() } }
        .confirmationDialog("Очистить \(DeviceStorage.fmt(chosen))?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Очистить", role: .destructive) {
                let sel = selected
                clearing = true
                Task {
                    await Task.detached { DeviceStorage.clear(sel) }.value
                    await reload()
                    clearing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    private func reload() async {
        let u = await Task.detached { DeviceStorage.usage() }.value
        withAnimation(Motion.snappy) { usage = u; loaded = true }
    }
    private func percent(_ v: Int64) -> String {
        let p = Double(v) / Double(max(total, 1)) * 100
        return p < 0.1 ? "<0.1%" : (p < 10 ? String(format: "%.1f%%", p) : String(format: "%.0f%%", p))
    }
}

// MARK: Использование трафика

struct NetUsageView: View {
    @ObservedObject private var stats = NetStats.shared
    @State private var net: String? = nil   // nil — всё, "cell", "wifi"
    @State private var open: Set<DataKind> = []
    @State private var confirm = false

    private var total: Int64 { stats.total(net: net) }
    private var order: [DataKind] { DataKind.allCases.sorted { stats.counter($0, net: net).total > stats.counter($1, net: net).total } }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                DonutChart(slices: order.map { .init(id: $0.rawValue, value: Double(stats.counter($0, net: net).total), color: Color(hex: $0.color)) },
                           center: DeviceStorage.fmt(total))
                    .frame(height: 230).padding(.top, 8)
                Text("Использование сети").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text)
                Text("Статистика использования сети с \(Self.df.string(from: stats.since))")
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 30)
                Picker("", selection: $net) {
                    Text("Весь").tag(String?.none); Text("Мобильный").tag(String?.some("cell")); Text("Wi-Fi").tag(String?.some("wifi"))
                }
                .pickerStyle(.segmented).padding(.horizontal, 30)

                SettingsGroup {
                    ForEach(order, id: \.self) { k in
                        let c = stats.counter(k, net: net)
                        Button {
                            withAnimation(Motion.snappy) { if open.contains(k) { open.remove(k) } else { open.insert(k) } }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: k.icon).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                    .frame(width: 30, height: 30).background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: k.color)))
                                Text(k.title).font(.system(size: 17)).foregroundColor(Theme.text)
                                + Text(total > 0 && c.total > 0 ? "  " + percent(c.total) : "").font(.system(size: 17)).foregroundColor(Theme.muted)
                                Spacer()
                                Text(DeviceStorage.fmt(c.total)).foregroundColor(Theme.muted)
                                Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.muted)
                                    .rotationEffect(.degrees(open.contains(k) ? 180 : 0))
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if open.contains(k) {
                            VStack(spacing: 6) {
                                row("arrow.up", "Отправлено", c.sent)
                                row("arrow.down", "Получено", c.recv)
                            }
                            .padding(.leading, 44).padding(.bottom, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        if k != order.last { Divider().overlay(Theme.line).padding(.leading, 44) }
                    }
                }
                Text("При нажатии на строку появится подробная статистика: сколько отправлено и сколько получено.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24)
                SettingsGroup {
                    Button { confirm = true } label: {
                        Text("Сбросить статистику").font(.system(size: 17)).foregroundColor(Theme.danger)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { stats.flush() }
        .confirmationDialog("Сбросить статистику трафика?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Сбросить", role: .destructive) { stats.reset() }
        }
    }

    private func row(_ icon: String, _ t: String, _ v: Int64) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted).frame(width: 16)
            Text(t).font(.system(size: 15)).foregroundColor(Theme.muted)
            Spacer()
            Text(DeviceStorage.fmt(v)).font(.system(size: 15)).foregroundColor(Theme.muted)
        }
    }
    private func percent(_ v: Int64) -> String {
        let p = Double(v) / Double(max(total, 1)) * 100
        return p < 0.1 ? "<0.1%" : (p < 10 ? String(format: "%.1f%%", p) : String(format: "%.0f%%", p))
    }
    static let df: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "d MMM yyyy 'в' HH:mm"; return f }()
}

// MARK: Автозагрузка (мобильная сеть / Wi-Fi)

struct AutoDownloadView: View {
    let cellular: Bool
    @ObservedObject private var ad = AutoDownloadSettings.shared

    private var s: Binding<AutoDownload> { cellular ? $ad.cell : $ad.wifi }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsGroup {
                    SettingsRow(icon: cellular ? "antenna.radiowaves.left.and.right" : "wifi", color: Color(hex: cellular ? 0x4cc764 : 0x3d82f6), title: "Автозагрузка медиа") {
                        Toggle("", isOn: s.enabled).labelsHidden().tint(Theme.a1)
                    }
                }
                SectionTitle(text: "Типы медиа")
                SettingsGroup {
                    SettingsRow(icon: "photo.fill", color: Color(hex: 0x6cc3f5), title: "Фото") { Toggle("", isOn: s.photos).labelsHidden().tint(Theme.a1) }
                    Divider().overlay(Theme.line).padding(.leading, 50)
                    SettingsRow(icon: "video.fill", color: Color(hex: 0x3d82f6), title: "Видео", subtitle: "До \(AutoDownload.mb(s.wrappedValue.mediaMB))") { Toggle("", isOn: s.videos).labelsHidden().tint(Theme.a1) }
                    if s.wrappedValue.videos { limit(s.mediaMB, 1...200) }
                    Divider().overlay(Theme.line).padding(.leading, 50)
                    SettingsRow(icon: "doc.fill", color: Color(hex: 0x4cc764), title: "Файлы", subtitle: "До \(AutoDownload.mb(s.wrappedValue.filesMB))") { Toggle("", isOn: s.files).labelsHidden().tint(Theme.a1) }
                    if s.wrappedValue.files { limit(s.filesMB, 0.5...100) }
                }
                .disabled(!s.wrappedValue.enabled)
                .opacity(s.wrappedValue.enabled ? 1 : 0.5)
                Text(cellular ? "Работает, когда телефон в мобильной сети. Голосовые и видеосообщения скачиваются всегда — они маленькие."
                              : "Работает при подключении к Wi-Fi. Голосовые и видеосообщения скачиваются всегда — они маленькие.")
                    .font(.footnote).foregroundColor(Theme.muted).padding(.horizontal, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(cellular ? "Мобильная сеть" : "Wi-Fi").navigationBarTitleDisplayMode(.inline)
    }

    private func limit(_ v: Binding<Double>, _ r: ClosedRange<Double>) -> some View {
        // шкала логарифмическая: маленькие значения настраиваются точнее
        let lo = log(r.lowerBound), hi = log(r.upperBound)
        let pos = Binding<Double>(get: { (log(max(r.lowerBound, v.wrappedValue)) - lo) / (hi - lo) },
                                  set: { let x = exp(lo + $0 * (hi - lo)); v.wrappedValue = x >= 1 ? x.rounded() : (x * 10).rounded() / 10 })
        return HStack(spacing: 10) {
            Text(AutoDownload.mb(r.lowerBound)).font(.caption).foregroundColor(Theme.muted)
            Slider(value: pos, in: 0...1).tint(Theme.a1)
            Text(AutoDownload.mb(r.upperBound)).font(.caption).foregroundColor(Theme.muted)
        }
        .padding(.leading, 44).padding(.bottom, 8)
    }
}
