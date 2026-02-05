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
        }
    }
}
