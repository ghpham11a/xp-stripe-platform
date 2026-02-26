import Foundation

protocol PaymentMethodsRepo {
    func createSetupIntent(accountId: String, customerId: String?) async throws -> SetupIntentResponse
    func list(accountId: String) async throws -> [PaymentMethod]
    func delete(accountId: String, paymentMethodId: String) async throws
}
