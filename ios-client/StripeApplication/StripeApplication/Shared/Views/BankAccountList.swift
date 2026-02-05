import SwiftUI

struct BankAccountList: View {
    let externalAccounts: [ExternalAccount]
    let isLoading: Bool
    let onAddBankAccount: () -> Void
    let onSetDefault: (String) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bank Accounts")
                    .font(.headline)
                Spacer()
                Button {
                    onAddBankAccount()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
                .disabled(isLoading)
            }

            if externalAccounts.isEmpty {
                Text("No bank accounts linked")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(externalAccounts) { account in
                    BankAccountItem(
                        account: account,
                        isLoading: isLoading,
                        onSetDefault: { onSetDefault(account.id) },
                        onDelete: { onDelete(account.id) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }
}

struct BankAccountItem: View {
    let account: ExternalAccount
    let isLoading: Bool
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteDialog = false

    var body: some View {
        HStack {
            Text("\u{1F3E6}")
                .font(.title2)

            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Text("\(account.bankName ?? "Bank") \u{2022}\u{2022}\u{2022}\u{2022} \(account.last4)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if account.defaultForCurrency {
                        BadgeView(text: "Default", color: .green)
                    }
                }
                Text("\(account.currency.uppercased()) \u{2022} \(account.country)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !account.defaultForCurrency {
                Button {
                    onSetDefault()
                } label: {
                    Image(systemName: "star")
                        .foregroundStyle(.blue)
                }
                .disabled(isLoading)
            }

            Button(role: .destructive) {
                showDeleteDialog = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .disabled(isLoading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
        .alert("Remove Bank Account", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove this bank account?")
        }
    }
}
