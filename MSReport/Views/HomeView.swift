import SwiftUI

enum Route: Hashable {
    case saved(UUID)
    case demo
}

struct PendingImport: Identifiable {
    let id = UUID()
    let fileName: String
    let table: RawTable
    var mapping: [ColumnRole: Int]
}

struct HomeView: View {
    @Environment(ReportStore.self) private var store
    @State private var path: [Route] = []
    @State private var showImporter = false
    @State private var pending: PendingImport?
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var demo: SalesReport?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    if !store.reports.isEmpty { reportsSection }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("M.S")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { route in
                destination(route)
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: FileLoader.allowedTypes) { result in
                handle(result)
            }
            .sheet(item: $pending) { p in
                MappingView(pending: p) { report in
                    store.add(report)
                    pending = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        path.append(.saved(report.id))
                    }
                }
            }
            .alert("Не получилось открыть файл",
                   isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button("Понятно", role: .cancel) {}
            } message: {
                Text(errorText ?? "")
            }
            .overlay {
                if isLoading { ReadingOverlay() }
            }
        }
    }

    // MARK: - Главный экран

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.gold)
                .frame(width: 64, height: 64)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("Найдём деньги, которые теряет ваша кофейня")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            Text("Отчёт по продажам за минуту")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                StepRow(number: 1, title: "Выгрузите продажи из кассы", subtitle: "iiko, Эвотор, r_keeper, Quick Resto или ОФД")
                StepRow(number: 2, title: "Загрузите файл", subtitle: "Excel или CSV — нужны хотя бы дата и сумма")
                StepRow(number: 3, title: "Получите находки в рублях", subtitle: "Пустые часы, слабые дни, точки и тренды")
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                showImporter = true
            } label: {
                Label("Загрузить выгрузку", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                if demo == nil { demo = DemoData.report() }
                path.append(.demo)
            } label: {
                Label("Посмотреть на примере", systemImage: "eye")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Label("Файл обрабатывается на телефоне и никуда не отправляется", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Мои отчёты").font(.title3.bold())
            ForEach(store.reports) { report in
                NavigationLink(value: Route.saved(report.id)) {
                    ReportRow(report: report)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        store.delete(report.id)
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
            Text("Чтобы удалить отчёт, нажмите и удерживайте его.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .saved(let id):
            if let report = store.reports.first(where: { $0.id == id }) {
                ReportView(report: report)
            } else {
                Text("Отчёт удалён").foregroundStyle(.secondary)
            }
        case .demo:
            if let demo {
                ReportView(report: demo)
            }
        }
    }

    // MARK: - Загрузка файла

    private func handle(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            errorText = error.localizedDescription
        case .success(let url):
            isLoading = true
            let started = Date()
            Task.detached(priority: .userInitiated) {
                do {
                    let table = try FileLoader.load(url: url)
                    let mapping = ColumnDetector.detect(headers: table.headers)
                    // Короткая пауза, чтобы экран «Читаем файл…» не мигал
                    let elapsed = Date().timeIntervalSince(started)
                    if elapsed < 0.8 { try? await Task.sleep(nanoseconds: UInt64((0.8 - elapsed) * 1_000_000_000)) }
                    await MainActor.run {
                        isLoading = false
                        pending = PendingImport(fileName: url.lastPathComponent, table: table, mapping: mapping)
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorText = error.localizedDescription
                    }
                }
            }
        }
    }
}

// MARK: - Мелкие элементы

private struct StepRow: View {
    let number: Int
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Theme.gold, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

private struct ReportRow: View {
    let report: SalesReport

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title3)
                .foregroundStyle(Theme.gold)
                .frame(width: 44, height: 44)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(report.periodTitle).font(.subheadline.weight(.semibold))
                Text(report.fileName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Fmt.rub(report.foundPerMonth))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.gold)
                Text("в месяц").font(.caption).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
    }
}

private struct ReadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ProgressView().tint(Theme.gold)
                    Text("Читаем файл…")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Theme.gold)
                }
                Text("> ищем дату, сумму и товары\n> считаем часы, дни и точки")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
