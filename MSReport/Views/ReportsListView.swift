import SwiftUI

struct ReportsListView: View {
    @Environment(ReportStore.self) private var store
    @Environment(ImportFlow.self) private var flow
    @State private var query = ""
    @State private var toDelete: SalesReport?

    private var filtered: [SalesReport] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return store.reports }
        return store.reports.filter {
            $0.fileName.lowercased().contains(q) || $0.periodTitle.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.reports.isEmpty {
                    empty
                } else {
                    list
                }
            }
            .navigationTitle("Отчёты")
            .navigationDestination(for: UUID.self) { id in
                if let r = store.reports.first(where: { $0.id == id }) {
                    ReportView(report: r)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        flow.startImport()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
            .confirmationDialog("Удалить отчёт?", isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }), titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    if let r = toDelete {
                        withAnimation(Theme.spring) { store.delete(r.id) }
                        Haptics.warning()
                    }
                    toDelete = nil
                }
            } message: {
                Text(toDelete?.periodTitle ?? "")
            }
        }
    }

    private var list: some View {
        List {
            Section {
                summary
                    .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 10, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            Section {
                ForEach(Array(filtered.enumerated()), id: \.element.id) { i, r in
                    NavigationLink(value: r.id) {
                        ReportCardRow(report: r, isLatest: r.id == store.latest?.id)
                    }
                    .appear(i)
                    .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            toDelete = r
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            toDelete = r
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $query, prompt: "Файл или период")
        .animation(Theme.spring, value: filtered.map(\.id))
    }

    private var summary: some View {
        HStack(spacing: 10) {
            stat("Отчётов", Fmt.int(Double(store.reports.count)), icon: "doc.on.doc")
            stat("Найдено всего", Fmt.compact(store.totalFoundAllTime) + " ₽", icon: "rublesign.circle")
        }
    }

    private func stat(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.gold)
                .frame(width: 34, height: 34)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(.headline, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
        }
        .card(radius: 18, padding: 12)
    }

    private var empty: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(Theme.goldGradient)
                .symbolEffect(.pulse, options: .repeating)
            Text("Здесь будут ваши отчёты")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text("Каждый загруженный файл сохраняется, и новые отчёты сравниваются с прошлыми.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button {
                flow.startImport()
            } label: {
                Label("Загрузить выгрузку", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
    }
}

private struct ReportCardRow: View {
    let report: SalesReport
    let isLatest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(report.periodTitle).font(.headline)
                        if isLatest {
                            Text("НОВЫЙ")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.goldGradient, in: Capsule())
                        }
                    }
                    Text(report.fileName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.rub(report.foundPerMonth))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.gold)
                    Text("в месяц").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Sparkline(values: report.daily.map(\.revenue), animated: false)
                .frame(height: 38)
            HStack(spacing: 14) {
                Label(Fmt.compact(report.revenue) + " ₽", systemImage: "banknote")
                Label(Fmt.rub(report.avgCheck), systemImage: "receipt")
                Label("\(report.dayCount) дн.", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        }
        .card(radius: 20, padding: 14)
    }
}
