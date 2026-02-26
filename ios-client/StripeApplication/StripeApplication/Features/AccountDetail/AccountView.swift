import SwiftUI

struct AccountView: View {

    @State private var viewModel: AccountViewModel
    @Environment(\.dismiss) private var dismiss

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    init(viewModel: AccountViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
        .onChange(of: viewModel.wasDeleted) { _, wasDeleted in
            if wasDeleted {
                dismiss()
            }
        }
        .onChange(of: viewModel.onboardingUrl) { _, url in
            if let url, let onboardingURL = URL(string: url) {
                UIApplication.shared.open(onboardingURL)
                viewModel.clearOnboardingUrl()
            }
        }
        .onChange(of: viewModel.error) { _, error in
            if let error {
                toastMessage = error
                toastIsError = true
                viewModel.clearError()
            }
        }
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
