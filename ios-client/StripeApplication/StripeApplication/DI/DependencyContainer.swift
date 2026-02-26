import Swinject

final class DependencyContainer {
    static let shared = DependencyContainer()

    let container: Container

    private init() {
        container = Container()
        registerCore()
        registerRepositories()
        registerViewModels()
    }

    private func registerCore() {
        container.register(AuthManager.self) { _ in AuthManager() }
            .inObjectScope(.container)

        container.register(Networking.self) { _ in NetworkService() }
            .inObjectScope(.container)

        container.register(RouteManager.self) { _ in RouteManager() }
            .inObjectScope(.container)

        container.register(ConnectivityMonitor.self) { _ in ConnectivityMonitor() }
            .inObjectScope(.container)
    }

    private func registerRepositories() {
        container.register(AccountsRepo.self) { r in
            AccountsRepository(networking: r.resolve(Networking.self)!)
        }.inObjectScope(.container)

        container.register(PaymentMethodsRepo.self) { r in
            PaymentMethodsRepository(networking: r.resolve(Networking.self)!)
        }.inObjectScope(.container)

        container.register(ExternalAccountsRepo.self) { r in
            ExternalAccountsRepository(networking: r.resolve(Networking.self)!)
        }.inObjectScope(.container)

        container.register(TransactionsRepo.self) { r in
            TransactionsRepository(networking: r.resolve(Networking.self)!)
        }.inObjectScope(.container)
    }

    private func registerViewModels() {
        container.register(HomeViewModel.self) { r in
            HomeViewModel(accountsRepo: r.resolve(AccountsRepo.self)!)
        }

        container.register(PaymentMethodsViewModel.self) { (r, accountId: String, customerId: String?) in
            PaymentMethodsViewModel(
                accountId: accountId,
                customerId: customerId,
                paymentMethodsRepo: r.resolve(PaymentMethodsRepo.self)!
            )
        }

        container.register(BankAccountsViewModel.self) { (r, accountId: String, isRecipient: Bool) in
            BankAccountsViewModel(
                accountId: accountId,
                isRecipient: isRecipient,
                externalAccountsRepo: r.resolve(ExternalAccountsRepo.self)!
            )
        }
    }

    func resolve<T>(_ type: T.Type) -> T {
        guard let resolved = container.resolve(type) else {
            fatalError("Failed to resolve \(type)")
        }
        return resolved
    }

    func makeAccountViewModel(account: Account) -> AccountViewModel {
        AccountViewModel(account: account, accountsRepo: resolve(AccountsRepo.self))
    }

    func makePaymentMethodsViewModel(accountId: String, customerId: String?) -> PaymentMethodsViewModel {
        PaymentMethodsViewModel(
            accountId: accountId,
            customerId: customerId,
            paymentMethodsRepo: resolve(PaymentMethodsRepo.self)
        )
    }

    func makeBankAccountsViewModel(accountId: String, isRecipient: Bool) -> BankAccountsViewModel {
        BankAccountsViewModel(
            accountId: accountId,
            isRecipient: isRecipient,
            externalAccountsRepo: resolve(ExternalAccountsRepo.self)
        )
    }
}
