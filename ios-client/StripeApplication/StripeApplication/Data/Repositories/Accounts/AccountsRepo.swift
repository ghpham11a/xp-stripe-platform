import Foundation

protocol AccountsRepo {
    func create(name: String, email: String) async throws -> Account
    func list() async throws -> [Account]
    func get(accountId: String) async throws -> Account
    func delete(accountId: String) async throws
    func upgradeToRecipient(accountId: String) async throws -> UpgradeToRecipientResponse
    func createOnboardingLink(accountId: String, refreshUrl: String, returnUrl: String) async throws -> AccountLinkResponse
}
