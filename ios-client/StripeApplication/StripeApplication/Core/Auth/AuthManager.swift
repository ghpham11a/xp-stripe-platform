import Foundation

@Observable
final class AuthManager {
    var showLoginView: Bool = false

    func getIdToken() -> String? {
        nil
    }

    func refreshTokenOrSignOut() -> Bool {
        false
    }
}
