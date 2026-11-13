import SwiftUI

/// Проверка столбцов перед построением отчёта.
struct MappingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pending: PendingImport
    @State private var errorText: String?
    @State private var building = false
    let onDone: (SalesReport) -> Void

    init(pending: PendingImport, onDone: @escaping (SalesReport) -> Void) {
        _pending = State(initialValue: pending)
        self.onDone = onDone
    }

    private var isValid: Bool {
        pending.mapping[.date] != nil && (pending.mapping[.amount] != nil || pending.mapping[.price] != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Файл", value: pending.fileName)
                    LabeledContent("Строк", value: "\(pending.table.rows.count)")
                } footer: {
                    Text("Мы сами нашли столбцы. Проверьте, что дата и сумма выбраны верно. Чем больше столбцов найдено, тем больше находок будет в отчёте.")
                }

                Section("Столбцы") {
                    ForEach(ColumnRole.allCases) { role in
                        Picker(selection: binding(for: role)) {
                            Text("Нет").tag(-1)
                            ForEach(pending.table.headers.indices, id: \.self) { i in
                                Text(pending.table.headers[i]).tag(i)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(role.title)
                                    if let note = role.note {
                                        Text(note).font(.caption2).foregroundStyle(Theme.gold)
                                    }
                                }
                                if let sample = sample(for: role) {
                                    Text(sample)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }

                if let errorText {
                    Section {
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.danger)
                    }
                }
            }
            .navigationTitle("Столбцы файла")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if building {
                        ProgressView()
                    } else {
                        Button("Готово") { build() }
                            .fontWeight(.semibold)
                            .disabled(!isValid)
                    }
                }
            }
        }
    }

    private func binding(for role: ColumnRole) -> Binding<Int> {
        Binding(
            get: { pending.mapping[role] ?? -1 },
            set: { pending.mapping[role] = $0 < 0 ? nil : $0 }
        )
    }

    private func sample(for role: ColumnRole) -> String? {
        guard let i = pending.mapping[role] else { return nil }
        for row in pending.table.rows.prefix(30) where i < row.count {
            let v = row[i].trimmingCharacters(in: .whitespaces)
            if !v.isEmpty { return "например: \(v)" }
        }
        return nil
    }

    private func build() {
        errorText = nil
        building = true
        let table = pending.table
        let mapping = pending.mapping
        let name = pending.fileName
        Task.detached(priority: .userInitiated) {
            do {
                let report = try ReportBuilder.makeReport(table: table, mapping: mapping, fileName: name)
                await MainActor.run {
                    building = false
                    onDone(report)
                }
            } catch {
                await MainActor.run {
                    building = false
                    errorText = error.localizedDescription
                }
            }
        }
    }
}
