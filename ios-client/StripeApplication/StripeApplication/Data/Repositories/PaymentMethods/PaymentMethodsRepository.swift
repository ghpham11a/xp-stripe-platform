import Foundation

final class PaymentMethodsRepository: PaymentMethodsRepo {
    private let networking: Networking

    init(networking: Networking) {
        self.networking = networking
    }

    func createSetupIntent(accountId: String, customerId: String?) async throws -> SetupIntentResponse {
        try await networking.makeRequest(endpoint: PaymentMethodsEndpoints.CreateSetupIntent(
            accountId: accountId, customerId: customerId
        ))
    }

    func list(accountId: String) async throws -> [PaymentMethod] {
        let response: PaymentMethodsResponse = try await networking.makeRequest(
            endpoint: PaymentMethodsEndpoints.List(accountId: accountId)
        )
        return response.paymentMethods
    }

    func delete(accountId: String, paymentMethodId: String) async throws {
        try await networking.makeRequestVoid(endpoint: PaymentMethodsEndpoints.Delete(
            accountId: accountId, paymentMethodId: paymentMethodId
        ))
    }
}
