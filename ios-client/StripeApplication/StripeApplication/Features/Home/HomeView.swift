import SwiftUI

struct HomeView: View {

    @State private var viewModel: HomeViewModel
    @State private var showCreateAccountForm = false

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    private let di = DependencyContainer.shared

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Account selector or create form
                if showCreateAccountForm {
                    CreateAccountForm(
                        isLoading: viewModel.isLoading,
                        onCreateAccount: { name, email in
                            showCreateAccountForm = false
                            Task {
                                await viewModel.createAccount(name: name, email: email)
                            }
                        },
                        onCancel: { showCreateAccountForm = false }
                    )
                } else {
                    AccountSelector(
                        accounts: viewModel.accounts,
                        selectedAccount: viewModel.selectedAccount,
                        onAccountSelected: { account in
                            viewModel.selectAccount(account)
                        },
                        onCreateNewAccount: { showCreateAccountForm = true }
                    )
                }

                // Navigation cards (only show when account is selected)
                if let account = viewModel.selectedAccount {
                    VStack(spacing: 12) {
                        NavigationLink(value: HomeDestination.accountDetail(account)) {
                            NavigationCard(
                                title: "Account Details",
                                subtitle: "View and manage account settings",
                                icon: "person.circle.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeDestination.paymentMethods(account)) {
                            NavigationCard(
                                title: "Payment Methods",
                                subtitle: "Manage saved cards",
                                icon: "creditcard.fill",
                                color: .green
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeDestination.bankAccounts(account)) {
                            NavigationCard(
                                title: "Bank Accounts",
                                subtitle: account.isRecipient ? "Manage linked accounts" : "Upgrade to recipient to add",
                                icon: "building.columns.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Loading indicator
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView()
                        .padding()
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Stripe Demo")
        .refreshable {
            await viewModel.loadAccounts()
        }
        .navigationDestination(for: HomeDestination.self) { destination in
            switch destination {
            case .accountDetail(let account):
                AccountView(viewModel: di.makeAccountViewModel(account: account))
            case .paymentMethods(let account):
                PaymentMethodsView(viewModel: di.makePaymentMethodsViewModel(
                    accountId: account.id, customerId: account.stripeCustomerId
                ))
            case .bankAccounts(let account):
                BankAccountsView(viewModel: di.makeBankAccountsViewModel(
                    accountId: account.id, isRecipient: account.isRecipient
                ))
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
}

// MARK: - Navigation Card

struct NavigationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
