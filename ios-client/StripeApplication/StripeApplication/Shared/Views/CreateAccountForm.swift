import SwiftUI

struct CreateAccountForm: View {
    let isLoading: Bool
    let onCreateAccount: (String, String) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var email = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create New Account")
                .font(.headline)

            TextField("Display Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disabled(isLoading)

            HStack(spacing: 8) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(isLoading)

                Button {
                    onCreateAccount(name, email)
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty || email.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
