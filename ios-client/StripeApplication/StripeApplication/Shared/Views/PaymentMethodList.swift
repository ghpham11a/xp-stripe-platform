import SwiftUI

struct PaymentMethodList: View {
    let paymentMethods: [PaymentMethod]
    let isLoading: Bool
    let onAddCard: () -> Void
    let onDeletePaymentMethod: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment Methods")
                    .font(.headline)
                Spacer()
                Button {
                    onAddCard()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
                .disabled(isLoading)
            }

            if paymentMethods.isEmpty {
                Text("No payment methods saved")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(paymentMethods) { pm in
                    PaymentMethodItem(
                        paymentMethod: pm,
                        isLoading: isLoading,
                        onDelete: { onDeletePaymentMethod(pm.id) }
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

struct PaymentMethodItem: View {
    let paymentMethod: PaymentMethod
    let isLoading: Bool
    let onDelete: () -> Void

    @State private var showDeleteDialog = false

    var body: some View {
        HStack {
            Text("\u{1F4B3}")
                .font(.title2)

            VStack(alignment: .leading) {
                Text("\(paymentMethod.card?.brand.capitalized ?? "Card") \u{2022}\u{2022}\u{2022}\u{2022} \(paymentMethod.card?.last4 ?? "****")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Expires \(paymentMethod.card?.expMonth ?? 0)/\(paymentMethod.card?.expYear ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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
        .alert("Remove Payment Method", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove this card?")
        }
    }
}
