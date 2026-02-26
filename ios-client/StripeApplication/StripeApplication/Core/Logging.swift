import Foundation
import os

enum Log {
    static let networking = Logger(subsystem: Bundle.main.bundleIdentifier ?? "StripeApplication", category: "networking")
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "StripeApplication", category: "general")
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "StripeApplication", category: "auth")
    static let navigation = Logger(subsystem: Bundle.main.bundleIdentifier ?? "StripeApplication", category: "navigation")
}
