import Foundation

enum Config {
    static let apiURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String,
              !url.isEmpty else {
            fatalError("API_URL not configured. Check your xcconfig files.")
        }
        return url
    }()

    static let stripePublishableKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "STRIPE_PUBLISHABLE_KEY") as? String,
              !key.isEmpty else {
            fatalError("STRIPE_PUBLISHABLE_KEY not configured. Check your xcconfig files.")
        }
        return key
    }()
}
