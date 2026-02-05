//
//  PaymentMethodsView+ViewModel.swift
//  StripeApplication
//

import Foundation
import Observation

extension PaymentMethodsView {
    @Observable
    class ViewModel {
        let accountId: String
        let customerId: String?

        var paymentMethods: [PaymentMethod] = []
        var isLoading: Bool = false
        var error: String? = nil
        var successMessage: String? = nil
        var setupIntentClientSecret: String? = nil

        private let paymentMethodRepository = PaymentMethodRepository.shared

        init(accountId: String, customerId: String?) {
            self.accountId = accountId
            self.customerId = customerId
            Task { await loadPaymentMethods() }
        }

        func loadPaymentMethods() async {
            do {
                paymentMethods = try await paymentMethodRepository.list(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
            }
        }

        func createSetupIntent() async {
            isLoading = true
            error = nil
            do {
                let response = try await paymentMethodRepository.createSetupIntent(
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
                try await paymentMethodRepository.delete(accountId: accountId, paymentMethodId: paymentMethodId)
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
}
