import Foundation

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
