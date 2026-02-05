import Foundation

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
