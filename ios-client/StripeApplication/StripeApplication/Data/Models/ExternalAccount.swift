import Foundation

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
