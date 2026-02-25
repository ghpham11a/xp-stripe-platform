import SwiftUI
import StripePaymentSheet

struct PaymentMethodsView: View {

    @State private var viewModel: PaymentMethodsViewModel

    @State private var showAddCardSheet = false
    @State private var setupPaymentSheet: PaymentSheet?

    // Toast messages
    @State private var toastMessage: String? = nil
    @State private var toastIsError = false

    init(viewModel: PaymentMethodsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                testCardBanner

                if showAddCardSheet {
                    addCardSection
                } else {
                    PaymentMethodList(
                        paymentMethods: viewModel.paymentMethods,
                        isLoading: viewModel.isLoading,
                        onAddCard: { showAddCardSheet = true },
                        onDeletePaymentMethod: { pmId in
                            Task { await viewModel.deletePaymentMethod(paymentMethodId: pmId) }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadPaymentMethods()
        }
        .onChange(of: viewModel.setupIntentClientSecret) { _, clientSecret in
            if let clientSecret {
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Stripe Connect Demo"
                setupPaymentSheet = PaymentSheet(setupIntentClientSecret: clientSecret, configuration: config)
                presentSetupPaymentSheet()
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

    private var addCardSection: some View {
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
                        await viewModel.createSetupIntent()
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
                viewModel.onSetupIntentConfirmed()
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
