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

struct CardDetails: Codable {
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int

    enum CodingKeys: String, CodingKey {
        case brand, last4
        case expMonth = "exp_month"
        case expYear = "exp_year"
    }
}

struct PaymentMethod: Codable, Identifiable {
    let id: String
    let type: String
    let card: CardDetails?
    let created: Int64
}

struct PaymentMethodsResponse: Codable {
    let paymentMethods: [PaymentMethod]

    enum CodingKeys: String, CodingKey {
        case paymentMethods = "payment_methods"
    }
}

struct SetupIntentResponse: Codable {
    let clientSecret: String
    let setupIntentId: String
    let customerId: String?

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case setupIntentId = "setup_intent_id"
        case customerId = "customer_id"
    }
}

struct ExternalAccount: Codable, Identifiable {
    let id: String
    let object: String
    let bankName: String?
    let last4: String
    let routingNumber: String?
    let currency: String
    let country: String
    let defaultForCurrency: Bool
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, object, last4, currency, country, status
        case bankName = "bank_name"
        case routingNumber = "routing_number"
        case defaultForCurrency = "default_for_currency"
    }
}

struct ExternalAccountsResponse: Codable {
    let externalAccounts: [ExternalAccount]

    enum CodingKeys: String, CodingKey {
        case externalAccounts = "external_accounts"
    }
}

struct CreateExternalAccountRequest: Codable {
    let token: String
}

struct PayUserRequest: Codable {
    let amount: Int
    let currency: String
    let recipientAccountId: String
    let paymentMethodId: String

    enum CodingKeys: String, CodingKey {
        case amount, currency
        case recipientAccountId = "recipient_account_id"
        case paymentMethodId = "payment_method_id"
    }

    init(amount: Int, currency: String = "usd", recipientAccountId: String, paymentMethodId: String) {
        self.amount = amount
        self.currency = currency
        self.recipientAccountId = recipientAccountId
        self.paymentMethodId = paymentMethodId
    }
}

struct PayUserResponse: Codable {
    let id: String
    let amount: Int
    let currency: String
    let status: String
    let recipient: String
    let transfer: String?
    let created: Int64
}

struct AccountLinkRequest: Codable {
    let refreshUrl: String
    let returnUrl: String

    enum CodingKeys: String, CodingKey {
        case refreshUrl = "refresh_url"
        case returnUrl = "return_url"
    }
}

struct AccountLinkResponse: Codable {
    let url: String
    let created: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case url, created
        case expiresAt = "expires_at"
    }
}

struct CreatePaymentIntentRequest: Codable {
    let amount: Int
    let currency: String
    let recipientAccountId: String
    let savePaymentMethod: Bool

    enum CodingKeys: String, CodingKey {
        case amount, currency
        case recipientAccountId = "recipient_account_id"
        case savePaymentMethod = "save_payment_method"
    }

    init(amount: Int, currency: String = "usd", recipientAccountId: String, savePaymentMethod: Bool) {
        self.amount = amount
        self.currency = currency
        self.recipientAccountId = recipientAccountId
        self.savePaymentMethod = savePaymentMethod
    }
}

struct CreatePaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
    let amount: Int
    let currency: String
    let recipient: String

    enum CodingKeys: String, CodingKey {
        case amount, currency, recipient
        case clientSecret = "client_secret"
        case paymentIntentId = "payment_intent_id"
    }
}

struct UpgradeToRecipientResponse: Codable {
    let id: String
    let stripeAccountId: String
    let isMerchant: Bool
    let isRecipient: Bool
    let merchantCapabilities: [String: AnyCodable]?
    let recipientCapabilities: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id
        case stripeAccountId = "stripe_account_id"
        case isMerchant = "is_merchant"
        case isRecipient = "is_recipient"
        case merchantCapabilities = "merchant_capabilities"
        case recipientCapabilities = "recipient_capabilities"
    }
}

struct ErrorResponse: Codable {
    let detail: String?
}

// MARK: - AnyCodable helper for dynamic JSON values

struct AnyCodable: Codable, Hashable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else {
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}
