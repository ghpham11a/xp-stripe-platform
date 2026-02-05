# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Open in Xcode
open StripeApplication/StripeApplication.xcodeproj

# Build via command line
cd StripeApplication
xcodebuild -scheme StripeApplication -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -scheme StripeApplication -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Configuration

Settings are injected via xcconfig files into Info.plist at build time:

1. Copy `Configuration/Config.xcconfig.template` to `Debug.xcconfig` and `Release.xcconfig`
2. Set `API_URL` (use `$()` to escape slashes: `https:/$()/example.com`)
3. Set `STRIPE_PUBLISHABLE_KEY`

Values are accessed at runtime via `Config.apiURL` and `Config.stripePublishableKey`.

## Architecture

SwiftUI app using the `@Observable` ViewModel pattern (Swift Observation framework).

### Project Structure

```
StripeApplication/
├── App/                      # Entry point (StripeApplicationApp, ContentView)
├── Core/
│   ├── Configuration/        # Config.swift (reads from Info.plist)
│   └── Networking/           # APIClient singleton
├── Features/
│   ├── Home/                 # HomeView + ViewModel (main dashboard)
│   ├── AccountDetail/        # AccountView + ViewModel (account management)
│   ├── PaymentMethods/       # PaymentMethodsView + ViewModel
│   └── BankAccounts/         # BankAccountsView + ViewModel
├── Data/
│   ├── Models/               # Codable structs (Account, PaymentMethod, etc.)
│   └── Repositories/         # API wrappers per domain
└── Shared/Views/             # Reusable components (AccountCard, forms, lists)
```

### Key Patterns

- **ViewModel**: Each feature has a ViewModel defined as `extension FeatureView { class ViewModel }` using `@Observable` (Swift Observation framework). ViewModels manage UI state and async business logic.
- **Repository Pattern**: Singleton repositories (`AccountRepository.shared`, `PaymentMethodRepository.shared`, etc.) encapsulate API calls
- **APIClient**: URLSession-based singleton with generic `request<T: Decodable>()` method
- **Auto-sync**: Uses `PBXFileSystemSynchronizedRootGroup` - new .swift files are auto-discovered by Xcode

### Networking

- `APIClient.shared.request<T>()` for JSON responses
- `APIClient.shared.requestVoid()` for no-body responses
- `APIClient.shared.requestExternalRaw()` for direct Stripe API calls (bank account tokens)

Bank account tokens are created via direct POST to `https://api.stripe.com/v1/tokens` using the publishable key.

### Stripe Integration

- **StripePaymentSheet** via Swift Package Manager
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
