import Foundation
import Observation

@Observable
class PaymentMethodsViewModel {
    let accountId: String
    let customerId: String?

    var paymentMethods: [PaymentMethod] = []
    var isLoading: Bool = false
    var error: String? = nil
    var successMessage: String? = nil
    var setupIntentClientSecret: String? = nil

    private let paymentMethodsRepo: PaymentMethodsRepo

    init(accountId: String, customerId: String?, paymentMethodsRepo: PaymentMethodsRepo) {
        self.accountId = accountId
        self.customerId = customerId
        self.paymentMethodsRepo = paymentMethodsRepo
        Task { await loadPaymentMethods() }
    }

    func loadPaymentMethods() async {
        do {
            paymentMethods = try await paymentMethodsRepo.list(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createSetupIntent() async {
        isLoading = true
        error = nil
        do {
            let response = try await paymentMethodsRepo.createSetupIntent(
                accountId: accountId,
                customerId: customerId
            )
            setupIntentClientSecret = response.clientSecret
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func clearSetupIntent() {
        setupIntentClientSecret = nil
    }

    func onSetupIntentConfirmed() {
        setupIntentClientSecret = nil
        successMessage = "Card added successfully"
        Task { await loadPaymentMethods() }
    }

    func deletePaymentMethod(paymentMethodId: String) async {
        isLoading = true
        error = nil
        do {
            try await paymentMethodsRepo.delete(accountId: accountId, paymentMethodId: paymentMethodId)
            successMessage = "Payment method removed"
            isLoading = false
            await loadPaymentMethods()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func clearError() {
        error = nil
    }

    func clearSuccessMessage() {
        successMessage = nil
    }
}
