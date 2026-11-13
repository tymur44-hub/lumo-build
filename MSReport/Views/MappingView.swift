import SwiftUI

/// Проверка столбцов перед анализом.
struct MappingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pending: PendingImport
    let onConfirm: (PendingImport) -> Void

    init(pending: PendingImport, onConfirm: @escaping (PendingImport) -> Void) {
        _pending = State(initialValue: pending)
        self.onConfirm = onConfirm
    }

    private var isValid: Bool {
        pending.mapping[.date] != nil && (pending.mapping[.amount] != nil || pending.mapping[.price] != nil)
    }

    private var foundCount: Int { pending.mapping.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    summary.appear(0)

                    VStack(spacing: 0) {
                        ForEach(Array(ColumnRole.allCases.enumerated()), id: \.element) { i, role in
                            roleRow(role)
                            if i < ColumnRole.allCases.count - 1 {
                                Rectangle().fill(Theme.stroke).frame(height: 1).padding(.leading, 46)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.stroke))
                    .appear(1)

                    Text("Чем больше столбцов найдено, тем больше находок будет в отчёте. Обязательны только дата и сумма.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(18)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.tap()
                    onConfirm(pending)
                } label: {
                    Label("Построить отчёт", systemImage: "sparkles")
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.5)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .background(Theme.background)
            .navigationTitle("Столбцы файла")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    private var summary: some View {
        HStack(spacing: 14) {
            Image(systemName: "tablecells")
                .font(.title2)
                .foregroundStyle(Theme.gold)
                .frame(width: 52, height: 52)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(pending.fileName).font(.headline).lineLimit(1)
                Text("\(Fmt.int(Double(pending.table.rows.count))) строк · найдено столбцов: \(foundCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(isValid ? Theme.success : Theme.danger)
                .contentTransition(.symbolEffect(.replace))
        }
        .card(radius: 20, padding: 14)
    }

    private func roleRow(_ role: ColumnRole) -> some View {
        let selected = pending.mapping[role]
        return Menu {
            Button("Нет") { set(role, nil) }
            Divider()
            ForEach(pending.table.headers.indices, id: \.self) { i in
                Button {
                    set(role, i)
                } label: {
                    if selected == i {
                        Label(pending.table.headers[i], systemImage: "checkmark")
                    } else {
                        Text(pending.table.headers[i])
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected == nil ? "circle.dashed" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(selected == nil ? Color.white.opacity(0.3) : Theme.gold)
                    .frame(width: 24)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(role.title).foregroundStyle(.white)
                        if let note = role.note {
                            Text(note).font(.caption2.weight(.semibold)).foregroundStyle(Theme.gold)
                        }
                    }
                    if let s = sample(for: role) {
                        Text(s).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(selected.map { pending.table.headers[$0] } ?? "Нет")
                    .font(.subheadline)
                    .foregroundStyle(selected == nil ? Color.secondary : Theme.gold)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

    private func set(_ role: ColumnRole, _ index: Int?) {
        Haptics.soft()
        withAnimation(Theme.snappy) { pending.mapping[role] = index }
    }

    private func sample(for role: ColumnRole) -> String? {
        guard let i = pending.mapping[role] else { return nil }
        for row in pending.table.rows.prefix(30) where i < row.count {
            let v = row[i].trimmingCharacters(in: .whitespaces)
            if !v.isEmpty { return "например: \(v)" }
        }
        return nil
    }
}
