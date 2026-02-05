//
//  AccountView.swift
//  StripeApplication
//

import SwiftUI

struct AccountView: View {

    @State private var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    init(account: Account) {
        _viewModel = State(initialValue: ViewModel(account: account))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Account details card
                AccountCard(
                    account: viewModel.account,
                    isLoading: viewModel.isLoading,
                    onDelete: {
                        Task { await viewModel.deleteAccount() }
                    },
                    onUpgradeToRecipient: {
                        Task { await viewModel.upgradeToRecipient() }
                    },
                    onStartOnboarding: {
                        Task { await viewModel.createOnboardingLink() }
                    }
                )
            }
            .padding()
        }
        .navigationTitle(viewModel.account.displayName ?? viewModel.account.email ?? "Account")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadAccount()
        }
        // Handle account deletion - pop back to home
        .onChange(of: viewModel.wasDeleted) { _, wasDeleted in
            if wasDeleted {
                dismiss()
            }
        }
        // Handle onboarding URL
        .onChange(of: viewModel.onboardingUrl) { _, url in
            if let url, let onboardingURL = URL(string: url) {
                UIApplication.shared.open(onboardingURL)
                viewModel.clearOnboardingUrl()
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
