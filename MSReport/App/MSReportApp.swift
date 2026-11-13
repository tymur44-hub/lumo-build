import SwiftUI

@main
struct MSReportApp: App {
    @State private var store = ReportStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}
