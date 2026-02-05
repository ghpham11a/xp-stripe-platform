import SwiftUI

struct AccountSelector: View {
    let accounts: [Account]
    let selectedAccount: Account?
    let onAccountSelected: (Account) -> Void
    let onCreateNewAccount: () -> Void
    
    

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(accounts) { account in
                    Button {
                        onAccountSelected(account)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.displayName ?? account.email ?? "Unknown")
                                Text(account.isRecipient ? "Customer + Recipient" : "Customer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if selectedAccount?.id == account.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    onCreateNewAccount()
                } label: {
                    Label("Create New Account", systemImage: "plus")
                }
            } label: {
                HStack {
                    Text(selectedAccount.map { $0.displayName ?? $0.email ?? "Unknown" } ?? "Select an account")
                        .foregroundStyle(selectedAccount != nil ? .primary : .secondary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
