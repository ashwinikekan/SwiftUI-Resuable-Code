import SwiftUI

@main
struct TadaMVLApp: App {

    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRouterView()
                .environmentObject(container)
                // Mockup is light-only. Pinning here avoids half-supporting
                // dark mode across the screens.
                .preferredColorScheme(.light)
        }
    }
}
