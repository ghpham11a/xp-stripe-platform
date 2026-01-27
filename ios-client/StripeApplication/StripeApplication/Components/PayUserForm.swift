import SwiftUI

enum PaymentMode {
    case savedCard
    case newCard
}

struct PayUserForm: View {
    let recipients: [Account]
    let paymentMethods: [PaymentMethod]
    let isLoading: Bool
    let onPayWithSavedCard: (String, String, Int) -> Void
    let onPayWithNewCard: (String, Int, Bool) -> Void
    let onCancel: () -> Void

    @State private var selectedRecipient: Account? = nil
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @State private var amountText = ""
    @State private var paymentMode: PaymentMode = .savedCard
    @State private var saveNewCard = false

    private var amountCents: Int {
        Int((Double(amountText) ?? 0) * 100)
    }

    private var isValid: Bool {
        selectedRecipient != nil && amountCents >= 50 &&
        (paymentMode == .newCard || selectedPaymentMethod != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pay User")
                .font(.headline)

            Text("Send money to another user (10% platform fee applies)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Recipient selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Recipient")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    if recipients.isEmpty {
                        Text("No recipients available")
                    } else {
                        ForEach(recipients) { recipient in
                            Button {
                                selectedRecipient = recipient
                            } label: {
                                HStack {
                                    Text(recipient.displayName ?? recipient.email ?? "Unknown")
                                    if selectedRecipient?.id == recipient.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRecipient?.displayName ?? selectedRecipient?.email ?? "Select recipient")
                            .foregroundStyle(selectedRecipient != nil ? .primary : .secondary)
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

            // Amount input
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .disabled(isLoading)
                        .onChange(of: amountText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            let parts = filtered.split(separator: ".", maxSplits: 2)
                            if parts.count <= 1 {
                                amountText = filtered
                            } else {
                                amountText = "\(parts[0]).\(String(parts[1]).prefix(2))"
                            }
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            !amountText.isEmpty && amountCents < 50 ? Color.red.opacity(0.5) : Color.secondary.opacity(0.3),
                            lineWidth: 1
                        )
                )

                Text("Minimum $0.50")
                    .font(.caption)
                    .foregroundStyle(!amountText.isEmpty && amountCents < 50 ? .red : .secondary)
            }

            // Payment mode toggle
            HStack(spacing: 8) {
                Button {
                    paymentMode = .savedCard
                } label: {
                    Text("Saved Card")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(paymentMode == .savedCard ? .blue : .secondary)

                Button {
                    paymentMode = .newCard
                } label: {
                    Text("New Card")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(paymentMode == .newCard ? .blue : .secondary)
            }

            if paymentMode == .savedCard {
                // Payment method selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Method")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Menu {
                        if paymentMethods.isEmpty {
                            Text("No saved cards")
                        } else {
                            ForEach(paymentMethods) { pm in
                                Button {
                                    selectedPaymentMethod = pm
                                } label: {
                                    HStack {
                                        Text("\(pm.card?.brand.capitalized ?? "Card") \u{2022}\u{2022}\u{2022}\u{2022} \(pm.card?.last4 ?? "****")")
                                        if selectedPaymentMethod?.id == pm.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let pm = selectedPaymentMethod {
                                Text("\(pm.card?.brand.capitalized ?? "Card") \u{2022}\u{2022}\u{2022}\u{2022} \(pm.card?.last4 ?? "****")")
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select payment method")
                                    .foregroundStyle(.secondary)
                            }
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
            } else {
                // Save card option
                Toggle("Save card for future payments", isOn: $saveNewCard)
                    .disabled(isLoading)
            }

            // Action buttons
            HStack(spacing: 8) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)

                Button {
                    guard let recipient = selectedRecipient else { return }
                    if paymentMode == .savedCard {
                        guard let pm = selectedPaymentMethod else { return }
                        onPayWithSavedCard(recipient.id, pm.id, amountCents)
                    } else {
                        onPayWithNewCard(recipient.id, amountCents, saveNewCard)
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Pay")
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
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }
}
