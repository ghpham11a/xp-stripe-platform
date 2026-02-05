//
//  BankAccountsView.swift
//  StripeApplication
//

import SwiftUI

struct BankAccountsView: View {

    @State private var viewModel: ViewModel

    @State private var showBankAccountForm = false

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    init(account: Account) {
        _viewModel = State(initialValue: ViewModel(
            accountId: account.id,
            isRecipient: account.isRecipient
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Test bank info
                testBankBanner

                if !viewModel.isRecipient {
                    // Not a recipient - show upgrade message
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Recipient Account Required")
                            .font(.headline)
                        Text("Upgrade this account to a recipient to add bank accounts for payouts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if showBankAccountForm {
                    BankAccountForm(
                        isLoading: viewModel.isLoading,
                        onSubmit: { holderName, routing, accountNum in
                            showBankAccountForm = false
                            Task {
                                await viewModel.createBankAccountToken(
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
                            Task { await viewModel.setDefaultExternalAccount(externalAccountId: eaId) }
                        },
                        onDelete: { eaId in
                            Task { await viewModel.deleteExternalAccount(externalAccountId: eaId) }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Bank Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadExternalAccounts()
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

    private var testBankBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Test Bank: Routing 110000000")
                .font(.caption)
                .foregroundStyle(.blue)
            Text("Account 000123456789")
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
