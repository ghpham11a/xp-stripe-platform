# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Open in Xcode
open StripeApplication/StripeApplication.xcodeproj

# Build via command line
cd StripeApplication
xcodebuild -scheme StripeApplication -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild -scheme StripeApplication -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Configuration

Settings are injected via xcconfig files into Info.plist at build time:

1. Copy `Configuration/Config.xcconfig.template` to `Debug.xcconfig` and `Release.xcconfig`
2. Set `API_URL` (use `$()` to escape slashes: `https:/$()/example.com`)
3. Set `STRIPE_PUBLISHABLE_KEY`

Values are accessed at runtime via `Config.value(for: .apiURL)` / `Config.apiURL` and `Config.stripePublishableKey`.

## Architecture

SwiftUI app using the `@Observable` ViewModel pattern with Swinject dependency injection.

### Project Structure

```
StripeApplication/
├── App/                      # Entry point (StripeApplicationApp, ContentView)
├── Core/
│   ├── Auth/                 # AuthManager stub (@Observable)
│   ├── Configuration/        # Config.swift (reads from Info.plist via ConfigKey)
│   ├── DI/                   # DependencyContainer (Swinject)
│   ├── Navigation/           # RouteManager, Destinations (tab + path routing)
│   ├── Networking/           # Endpoint protocol, Networking protocol, NetworkService, ConnectivityMonitor
│   └── Logging.swift         # os.Logger instances (networking, general, auth, navigation)
├── Features/
│   ├── Home/                 # HomeView + HomeViewModel
│   ├── AccountDetail/        # AccountView + AccountViewModel
│   ├── PaymentMethods/       # PaymentMethodsView + PaymentMethodsViewModel
│   └── BankAccounts/         # BankAccountsView + BankAccountsViewModel
├── Data/
│   ├── Models/               # Codable structs (Account, PaymentMethod, etc.)
│   └── Repositories/         # Protocol + Endpoints + Implementation per domain
│       ├── Accounts/         # AccountsRepo, AccountsEndpoints, AccountsRepository
│       ├── PaymentMethods/   # PaymentMethodsRepo, PaymentMethodsEndpoints, PaymentMethodsRepository
│       ├── ExternalAccounts/ # ExternalAccountsRepo, ExternalAccountsEndpoints, ExternalAccountsRepository
│       └── Transactions/     # TransactionsRepo, TransactionsEndpoints, TransactionsRepository
└── Shared/Views/             # Reusable components (AccountCard, forms, lists)
```

### Key Patterns

- **Dependency Injection**: Swinject `DependencyContainer.shared` registers all dependencies. Core services (Networking, AuthManager, RouteManager, ConnectivityMonitor) are `.container` singletons. Repositories are `.container` singletons. ViewModels are transient.
- **ViewModel**: Standalone `@Observable` classes (e.g., `HomeViewModel`, `AccountViewModel`). Accept repository protocols via init. Created by DI container or factory methods on `DependencyContainer`.
- **Repository Pattern**: Protocol-based (`AccountsRepo`, `PaymentMethodsRepo`, etc.) with concrete implementations that take `Networking` via init.
- **Endpoint Pattern**: Each API call is a struct conforming to `Endpoint` protocol, grouped in enums (e.g., `AccountsEndpoints.Create`). Endpoint defines path, method, headers, body, queryItems, and optional baseURL.
- **Networking Protocol**: `Networking` protocol with `makeRequest<T>()`, `makeRequestVoid()`, `makeRawRequest()`. `NetworkService` is the concrete implementation with retry logic for GETs and 401 handling.
- **Navigation**: `RouteManager` manages `NavigationPath` per tab. `HomeDestination` enum for type-safe navigation.
- **Auto-sync**: Uses `PBXFileSystemSynchronizedRootGroup` - new .swift files are auto-discovered by Xcode

### Networking

- `Networking.makeRequest<T>(endpoint:)` for typed JSON responses
- `Networking.makeRequestVoid(endpoint:)` for no-body responses
- `Networking.makeRawRequest(endpoint:)` for raw responses (Stripe bank token)

Bank account tokens are created via the `ExternalAccountsEndpoints.CreateBankToken` endpoint which posts to `https://api.stripe.com/v1/tokens`.

### Stripe Integration

- **StripePaymentSheet** + **Swinject** via Swift Package Manager
- PaymentSheet for card collection (SetupIntents/PaymentIntents)
- Initialized in app entry: `StripeAPI.defaultPublishableKey = Config.stripePublishableKey`

### AnyCodable

`Data/Models/AnyCodable.swift` handles dynamic JSON fields from Stripe API responses (capabilities objects with varying structures).

## Parent Project

This is the iOS client for a Stripe Connect demo. See `../CLAUDE.md` for:
- Backend API endpoints and structure
- Stripe v2 Accounts model details
- Test data (cards, bank accounts)
- Full-stack architecture
