import SwiftUI

struct ContentView: View {
    
    @Environment(RouteManager.self) private var routeManager
    @Environment(ConnectivityMonitor.self) private var connectivity

    var body: some View {
        @Bindable var router = routeManager

        VStack(spacing: 0) {
            if !connectivity.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("No internet connection")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red)
            }

            NavigationStack(path: $router.homePath) {
                HomeView(viewModel: DependencyContainer.shared.resolve(HomeViewModel.self))
            }
        }
    }
}
