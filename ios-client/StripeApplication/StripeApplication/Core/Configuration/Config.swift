import Foundation

enum ConfigKey: String {
    case apiURL = "API_URL"
    case stripePublishableKey = "STRIPE_PUBLISHABLE_KEY"
}

enum Config {
    static func value(for key: ConfigKey) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String,
              !value.isEmpty else {
            fatalError("\(key.rawValue) not configured. Check your xcconfig files.")
        }
        return value
    }

    static let apiURL: String = value(for: .apiURL)
    static let stripePublishableKey: String = value(for: .stripePublishableKey)
}
