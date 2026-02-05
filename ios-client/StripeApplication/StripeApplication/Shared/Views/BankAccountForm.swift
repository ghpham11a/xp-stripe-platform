import SwiftUI

struct BankAccountForm: View {
    let isLoading: Bool
    let onSubmit: (String, String, String) -> Void
    let onCancel: () -> Void

    @State private var accountHolderName = ""
    @State private var routingNumber = ""
    @State private var accountNumber = ""
    @State private var confirmAccountNumber = ""

    private var isValid: Bool {
        !accountHolderName.trimmingCharacters(in: .whitespaces).isEmpty &&
        routingNumber.count == 9 &&
        !accountNumber.isEmpty &&
        accountNumber == confirmAccountNumber
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Bank Account")
                .font(.headline)

            // Test data info
            VStack(alignment: .leading, spacing: 4) {
                Text("Test Data:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Text("Routing: 110000000")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("Account: 000123456789")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )

            TextField("Account Holder Name", text: $accountHolderName)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Routing Number", text: $routingNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .disabled(isLoading)
                    .onChange(of: routingNumber) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count <= 9 {
                            routingNumber = filtered
                        } else {
                            routingNumber = String(filtered.prefix(9))
                        }
                    }

                Text("\(routingNumber.count)/9 digits")
                    .font(.caption)
                    .foregroundColor(routingNumber.isEmpty || routingNumber.count == 9 ? Color.secondary : Color.red)
            }

            TextField("Account Number", text: $accountNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .disabled(isLoading)
                .onChange(of: accountNumber) { _, newValue in
                    accountNumber = newValue.filter { $0.isNumber }
                }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Confirm Account Number", text: $confirmAccountNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .disabled(isLoading)
                    .onChange(of: confirmAccountNumber) { _, newValue in
                        confirmAccountNumber = newValue.filter { $0.isNumber }
                    }

                if !confirmAccountNumber.isEmpty && accountNumber != confirmAccountNumber {
                    Text("Account numbers don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 8) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)

                Button {
                    onSubmit(accountHolderName, routingNumber, accountNumber)
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Add Bank")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(isLoading || !isValid)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
