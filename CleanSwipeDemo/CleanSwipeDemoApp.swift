import SwiftUI

@main
struct CleanSwipeDemoApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(.light)
        }
    }
}

