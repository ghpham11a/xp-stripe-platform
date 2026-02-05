import Foundation

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
