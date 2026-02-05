import SwiftUI

struct AccountCard: View {
    let account: Account
    let isLoading: Bool
    let onDelete: () -> Void
    let onUpgradeToRecipient: () -> Void
    let onStartOnboarding: () -> Void

    @State private var showDeleteDialog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Account Details")
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    showDeleteDialog = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .disabled(isLoading)
            }

            // Status badges
            HStack(spacing: 8) {
                if account.isCustomer {
                    BadgeView(text: "Customer", color: .secondary)
                }
                if account.isRecipient {
                    BadgeView(text: "Recipient", color: .blue)
                }
                if account.isOnboarding == true {
                    BadgeView(text: "Onboarding", color: .orange)
                }
            }

            Divider()

            // Account info
            InfoRow(label: "Email", value: account.email ?? "N/A")
            InfoRow(label: "Display Name", value: account.displayName ?? "N/A")
            InfoRow(label: "Platform ID", value: account.id)
            InfoRow(label: "Stripe Account ID", value: account.stripeAccountId)
            if let customerId = account.stripeCustomerId {
                InfoRow(label: "Stripe Customer ID", value: customerId)
            }
            InfoRow(label: "Created", value: account.created)

            // Actions
            if !account.isRecipient {
                Divider()
                Button {
                    onUpgradeToRecipient()
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Upgrade to Recipient")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }

            if account.isRecipient && account.isOnboarding == true {
                Divider()
                Button {
                    onStartOnboarding()
                } label: {
                    HStack {
                        Spacer()
                        Text("Complete Onboarding")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
        .alert("Delete Account", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
