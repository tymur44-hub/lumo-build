import SwiftUI

/// Политика конфиденциальности (privacy.md из ресурсов) в оформлении приложения
struct PolicyView: View {
    @Environment(\.dismiss) private var dismiss
    private let lines: [String] = {
        guard let u = Bundle.main.url(forResource: "privacy", withExtension: "md"), let s = try? String(contentsOf: u) else {
            return ["Политика доступна на lumomess.ru/?privacy"]
        }
        return s.components(separatedBy: "\n")
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Политика конфиденциальности").font(.system(size: 19, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.text)
                        .frame(width: 36, height: 36).background(Circle().fill(Theme.panel2))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, raw in
                        let l = raw.trimmingCharacters(in: .whitespaces)
                        if l.isEmpty || l.hasPrefix("# ") { EmptyView() }
                        else if l.hasPrefix("## ") {
                            Text(String(l.dropFirst(3))).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text).padding(.top, 8)
                        } else if l.hasPrefix("- ") {
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Theme.a1).frame(width: 5, height: 5).padding(.top, 8)
                                Text(md(String(l.dropFirst(2)))).font(.system(size: 14.5)).foregroundColor(Theme.text)
                            }
                        } else {
                            Text(md(l)).font(.system(size: 14.5)).foregroundColor(Theme.text)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18).padding(.bottom, 30)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func md(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s)) ?? AttributedString(s)
    }
}

/// Согласие на обработку персональных данных (152-ФЗ)
struct ConsentRow: View {
    @Binding var agree: Bool
    @State private var showPolicy = false
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button { agree.toggle() } label: {
                Image(systemName: agree ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22)).foregroundColor(agree ? Theme.a1 : Theme.muted)
            }
            (Text("Принимаю ") + Text("Политику конфиденциальности").foregroundColor(Theme.a1).fontWeight(.semibold)
             + Text(" и даю согласие на обработку моих персональных данных"))
                .font(.system(size: 13)).foregroundColor(Theme.muted)
                .onTapGesture { showPolicy = true }
            Spacer(minLength: 0)
        }
        .sheet(isPresented: $showPolicy) { PolicyView() }
    }
}
