import SwiftUI

struct ReportView: View {
    let report: SalesReport
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ReportContent(report: report, palette: .app)
                FullReviewCard()
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(report.isDemo ? "Пример отчёта" : "Отчёт")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("PDF", systemImage: "square.and.arrow.up")
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            if pdfURL == nil { pdfURL = PDFExporter.export(report) }
        }
    }
}

/// Предложение полного разбора — ведёт в Telegram-бот.
private struct FullReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Полный разбор", systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)
                .foregroundStyle(Theme.gold)
            Text("Разберём продажи по точкам и сменам и составим план на неделю: что поменять, чтобы вернуть эти деньги.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let url = URL(string: "https://t.me/ms_sales_report_bot") {
                Link(destination: url) {
                    Label("Хочу полный разбор", systemImage: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.gold.opacity(0.3)))
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
