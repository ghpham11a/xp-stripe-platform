import Foundation

protocol ExternalAccountsRepo {
    func create(accountId: String, token: String) async throws -> ExternalAccount
    func list(accountId: String) async throws -> [ExternalAccount]
    func delete(accountId: String, externalAccountId: String) async throws
    func setDefault(accountId: String, externalAccountId: String) async throws -> ExternalAccount
    func createBankAccountToken(accountHolderName: String, routingNumber: String, accountNumber: String) async throws -> String
}
