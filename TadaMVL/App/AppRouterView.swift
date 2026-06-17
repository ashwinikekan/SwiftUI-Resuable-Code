import SwiftUI

struct AppRouterView: View {

    @EnvironmentObject private var container: AppContainer

    var body: some View {
        MapScreen(container: container)
    }
}
