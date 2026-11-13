import SwiftUI

struct ReportView: View {
    let report: SalesReport
    var showsClose: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ReportContent(report: report, palette: .app)
                FullReviewCard().appear(14)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(AmbientBackground())
        .navigationTitle(report.isDemo ? "Пример отчёта" : "Отчёт")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.soft()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Theme.cardRaised, in: Circle())
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(Theme.goldGradient, in: Circle())
                    }
                    .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })
                    .transition(.scale.combined(with: .opacity))
                } else {
                    ProgressView().controlSize(.small)
                }
            }
        }
        .task {
            if pdfURL == nil {
                try? await Task.sleep(nanoseconds: 400_000_000)
                let url = PDFExporter.export(report)
                withAnimation(Theme.snappy) { pdfURL = url }
            }
        }
    }
}

/// Предложение полного разбора — ведёт в Telegram-бот.
private struct FullReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(Theme.goldGradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Полный разбор").font(.system(.headline, design: .rounded))
                    Text("по точкам и сменам").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("Разберём продажи вместе и составим план на неделю: что поменять, чтобы вернуть эти деньги.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Haptics.tap()
                if let url = URL(string: "https://t.me/ms_sales_report_bot") { UIApplication.shared.open(url) }
            } label: {
                Label("Хочу полный разбор", systemImage: "paperplane.fill")
            }
            .buttonStyle(GoldButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Theme.card, Theme.gold.opacity(0.14)], startPoint: .top, endPoint: .bottom))
        }
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.gold.opacity(0.3)))
    }
}

@MainActor
enum PDFExporter {
    /// Рисует отчёт в одностраничный PDF (светлая тема, удобно печатать и пересылать).
    static func export(_ report: SalesReport) -> URL? {
        let width: CGFloat = 595
        let content = ReportContent(report: report, palette: .print)
            .padding(28)
            .frame(width: width)
            .background(Color.white)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)

        let safeName = report.periodTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Отчёт M.S \(safeName).pdf")
        try? FileManager.default.removeItem(at: url)

        var ok = false
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            ctx.beginPDFPage(nil)
            draw(ctx)
            ctx.endPDFPage()
            ctx.closePDF()
            ok = true
        }
        return ok ? url : nil
    }
}
