import SwiftUI
import StripePaymentSheet

struct ContentView: View {
    @State private var viewModel = MainViewModel()

    @State private var showCreateAccountForm = false
    @State private var showAddCardSheet = false
    @State private var showBankAccountForm = false
    @State private var showPayUserForm = false

    // Stripe PaymentSheet
    @State private var paymentSheet: PaymentSheet?
    @State private var setupPaymentSheet: PaymentSheet?

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Test card info
                    testCardBanner

                    // Account selector or create form
                    if showCreateAccountForm {
                        CreateAccountForm(
                            isLoading: viewModel.isLoading,
                            onCreateAccount: { name, email in
                                showCreateAccountForm = false
                                Task { await viewModel.createAccount(name: name, email: email) }
                            },
                            onCancel: { showCreateAccountForm = false }
                        )
                    } else {
                        AccountSelector(
                            accounts: viewModel.accounts,
                            selectedAccount: viewModel.selectedAccount,
                            onAccountSelected: { viewModel.selectAccount($0) },
                            onCreateNewAccount: { showCreateAccountForm = true }
                        )
                    }

                    // Selected account details
                    if let account = viewModel.selectedAccount {
                        AccountCard(
                            account: account,
                            isLoading: viewModel.isLoading,
                            onDelete: {
                                Task { await viewModel.deleteAccount(accountId: account.id) }
                            },
                            onUpgradeToRecipient: {
                                Task { await viewModel.upgradeToRecipient(accountId: account.id) }
                            },
                            onStartOnboarding: {
                                Task { await viewModel.createOnboardingLink(accountId: account.id) }
                            }
                        )

                        // Payment Methods
                        if showAddCardSheet {
                            addCardSection(account: account)
                        } else {
                            PaymentMethodList(
                                paymentMethods: viewModel.paymentMethods,
                                isLoading: viewModel.isLoading,
                                onAddCard: { showAddCardSheet = true },
                                onDeletePaymentMethod: { pmId in
                                    Task { await viewModel.deletePaymentMethod(accountId: account.id, paymentMethodId: pmId) }
                                }
                            )
                        }

                        // Bank Accounts (only for recipients)
                        if account.isRecipient {
                            if showBankAccountForm {
                                BankAccountForm(
                                    isLoading: viewModel.isLoading,
                                    onSubmit: { holderName, routing, accountNum in
                                        showBankAccountForm = false
                                        Task {
                                            await viewModel.createBankAccountToken(
                                                accountId: account.id,
                                                accountHolderName: holderName,
                                                routingNumber: routing,
                                                accountNumber: accountNum
                                            )
                                        }
                                    },
                                    onCancel: { showBankAccountForm = false }
                                )
                            } else {
                                BankAccountList(
                                    externalAccounts: viewModel.externalAccounts,
                                    isLoading: viewModel.isLoading,
                                    onAddBankAccount: { showBankAccountForm = true },
                                    onSetDefault: { eaId in
                                        Task { await viewModel.setDefaultExternalAccount(accountId: account.id, externalAccountId: eaId) }
                                    },
                                    onDelete: { eaId in
                                        Task { await viewModel.deleteExternalAccount(accountId: account.id, externalAccountId: eaId) }
                                    }
                                )
                            }
                        }

                        // Pay User
                        let recipients = viewModel.accounts.filter { $0.isRecipient && $0.id != account.id }
                        if !viewModel.paymentMethods.isEmpty || !recipients.isEmpty {
                            if showPayUserForm {
                                PayUserForm(
                                    recipients: recipients,
                                    paymentMethods: viewModel.paymentMethods,
                                    isLoading: viewModel.isLoading,
                                    onPayWithSavedCard: { recipientId, pmId, amount in
                                        showPayUserForm = false
                                        Task {
                                            await viewModel.payUser(
                                                accountId: account.id,
                                                recipientAccountId: recipientId,
                                                paymentMethodId: pmId,
                                                amount: amount
                                            )
                                        }
                                    },
                                    onPayWithNewCard: { recipientId, amount, saveCard in
                                        Task {
                                            await viewModel.createPaymentIntent(
                                                accountId: account.id,
                                                recipientAccountId: recipientId,
                                                amount: amount,
                                                savePaymentMethod: saveCard
                                            )
                                        }
                                    },
                                    onCancel: { showPayUserForm = false }
                                )
                            } else {
                                Button {
                                    showPayUserForm = true
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("Pay Another User")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    // Loading indicator
                    if viewModel.isLoading && viewModel.selectedAccount == nil {
                        ProgressView()
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Stripe Connect Demo")
            .refreshable {
                await viewModel.loadAccounts()
                if let account = viewModel.selectedAccount {
                    await viewModel.loadAccountData(accountId: account.id)
                }
            }
        }
        // Handle onboarding URL
        .onChange(of: viewModel.onboardingUrl) { _, url in
            if let url, let onboardingURL = URL(string: url) {
                UIApplication.shared.open(onboardingURL)
                viewModel.clearOnboardingUrl()
            }
        }
        // Handle SetupIntent client secret -> present PaymentSheet
        .onChange(of: viewModel.setupIntentClientSecret) { _, clientSecret in
            if let clientSecret {
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Stripe Connect Demo"
                setupPaymentSheet = PaymentSheet(setupIntentClientSecret: clientSecret, configuration: config)

                presentSetupPaymentSheet()
            }
        }
        // Handle PaymentIntent client secret -> present PaymentSheet
        .onChange(of: viewModel.paymentIntentClientSecret) { _, clientSecret in
            if let clientSecret {
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Stripe Connect Demo"
                paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)

                presentPaymentSheet()
            }
        }
        // Error toast
        .onChange(of: viewModel.error) { _, error in
            if let error {
                toastMessage = error
                toastIsError = true
                viewModel.clearError()
            }
        }
        // Success toast
        .onChange(of: viewModel.successMessage) { _, message in
            if let message {
                toastMessage = message
                toastIsError = false
                viewModel.clearSuccessMessage()
            }
        }
        .overlay(alignment: .bottom) {
            if let message = toastMessage {
                toastView(message: message, isError: toastIsError)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                toastMessage = nil
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: toastMessage)
    }

    // MARK: - Subviews

    private var testCardBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Test Card: 4242 4242 4242 4242")
                .font(.caption)
                .foregroundStyle(.blue)
            Text("Any future expiry, any CVC")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private func addCardSection(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Card")
                .font(.headline)
            Text("Click the button below to add a new card using Stripe's secure payment sheet.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button("Cancel") {
                    showAddCardSheet = false
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button {
                    Task {
                        await viewModel.createSetupIntent(
                            accountId: account.id,
                            customerId: account.stripeCustomerId
                        )
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Add Card")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isLoading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func toastView(message: String, isError: Bool) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isError ? Color.red : Color.green)
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
    }

    // MARK: - PaymentSheet Presentation

    private func presentSetupPaymentSheet() {
        guard let sheet = setupPaymentSheet else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        let presenter = topViewController(of: rootVC)
        sheet.present(from: presenter) { result in
            switch result {
            case .completed:
                if let account = viewModel.selectedAccount {
                    viewModel.onSetupIntentConfirmed(accountId: account.id)
                }
                showAddCardSheet = false
            case .canceled:
                viewModel.clearSetupIntent()
            case .failed(let error):
                viewModel.clearSetupIntent()
                self.viewModel.error = error.localizedDescription
            }
            setupPaymentSheet = nil
        }
    }

    private func presentPaymentSheet() {
        guard let sheet = paymentSheet else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        let presenter = topViewController(of: rootVC)
        sheet.present(from: presenter) { result in
            switch result {
            case .completed:
                if let account = viewModel.selectedAccount {
                    viewModel.onPaymentIntentConfirmed(accountId: account.id)
                }
                showPayUserForm = false
            case .canceled:
                viewModel.clearPaymentIntent()
            case .failed(let error):
                viewModel.clearPaymentIntent()
                self.viewModel.error = error.localizedDescription
            }
            paymentSheet = nil
        }
    }

    private func topViewController(of viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topViewController(of: presented)
        }
        if let nav = viewController as? UINavigationController,
           let visible = nav.visibleViewController {
            return topViewController(of: visible)
        }
        if let tab = viewController as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(of: selected)
        }
        return viewController
    }
}

#Preview {
    ContentView()
}
