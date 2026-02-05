import Foundation

struct Account: Codable, Identifiable, Hashable {
    let id: String
    let stripeAccountId: String
    let stripeCustomerId: String?
    let email: String?
    let displayName: String?
    let created: String
    let isCustomer: Bool
    let isRecipient: Bool
    let isOnboarding: Bool?
    let customerCapabilities: [String: AnyCodable]?
    let merchantCapabilities: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id
        case stripeAccountId = "stripe_account_id"
        case stripeCustomerId = "stripe_customer_id"
        case email
        case displayName = "display_name"
        case created
        case isCustomer = "is_customer"
        case isRecipient = "is_recipient"
        case isOnboarding = "is_onboarding"
        case customerCapabilities = "customer_capabilities"
        case merchantCapabilities = "merchant_capabilities"
    }

    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AccountsResponse: Codable {
    let accounts: [Account]
}

struct CreateAccountRequest: Codable {
    let name: String
    let email: String
    let country: String

    init(name: String, email: String, country: String = "US") {
        self.name = name
        self.email = email
        self.country = country
    }
}
