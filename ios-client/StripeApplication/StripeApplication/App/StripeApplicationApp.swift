import SwiftUI
import StripePaymentSheet

@main
struct StripeApplicationApp: App {

    init() {
        StripeAPI.defaultPublishableKey = Config.stripePublishableKey
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(DependencyContainer.shared.resolve(RouteManager.self))
                .environment(DependencyContainer.shared.resolve(AuthManager.self))
                .environment(DependencyContainer.shared.resolve(ConnectivityMonitor.self))
        }
    }
}
