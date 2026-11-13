import SwiftUI

@main
struct MSReportApp: App {
    @State private var store = ReportStore()
    @State private var profile = ProfileStore()
    @State private var flow = ImportFlow()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(profile)
                .environment(flow)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}
