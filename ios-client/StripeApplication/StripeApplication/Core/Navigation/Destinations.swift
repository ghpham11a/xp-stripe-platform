import Foundation

enum HomeDestination: Hashable {
    case accountDetail(Account)
    case paymentMethods(Account)
    case bankAccounts(Account)
}
