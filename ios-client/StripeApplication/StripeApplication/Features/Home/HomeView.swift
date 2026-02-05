//
//  HomeView.swift
//  StripeApplication
//
//  Created by Anthony Pham on 2/4/26.
//
import SwiftUI

struct HomeView: View {

    @State private var viewModel = ViewModel()
    @State private var showCreateAccountForm = false

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    var body: some View {
        NavigationStack {
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
                            NavigationLink {
                                AccountView(account: account)
                            } label: {
                                NavigationCard(
                                    title: "Account Details",
                                    subtitle: "View and manage account settings",
                                    icon: "person.circle.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                PaymentMethodsView(account: account)
                            } label: {
                                NavigationCard(
                                    title: "Payment Methods",
                                    subtitle: "Manage saved cards",
                                    icon: "creditcard.fill",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                BankAccountsView(account: account)
                            } label: {
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
