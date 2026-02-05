# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Build debug APK
./gradlew assembleDebug

# Install on connected device/emulator
./gradlew installDebug

# Run unit tests
./gradlew test

# Run instrumented tests (requires device/emulator)
./gradlew connectedAndroidTest

# Clean build
./gradlew clean
```

## Configuration

Settings are defined as BuildConfig fields in `app/build.gradle.kts`:

```kotlin
buildConfigField("String", "API_URL", "\"https://feedback-test.ngrok.io/\"")
buildConfigField("String", "STRIPE_PUBLISHABLE_KEY", "\"pk_test_YOUR_KEY\"")
```

Values are accessed at runtime via `BuildConfig.API_URL` and `BuildConfig.STRIPE_PUBLISHABLE_KEY`.

## Architecture

Jetpack Compose app using MVVM with Hilt dependency injection.

### Project Structure

```
com.example.stripedemo/
├── MainActivity.kt               # Single-activity entry point
├── StripeDemoApplication.kt      # @HiltAndroidApp
├── core/navigation/              # Navigation routes and NavHost
├── data/
│   ├── models/                   # Data classes (Account, PaymentMethod, etc.)
│   ├── networking/               # Retrofit ApiService
│   └── repositories/             # Repository + Result sealed class
├── di/                           # Hilt modules (NetworkModule, RepositoryModule)
├── features/
│   ├── home/                     # HomeScreen + HomeViewModel
│   ├── accountdetail/            # AccountDetailScreen
│   ├── paymentmethods/           # PaymentMethodsScreen
│   └── bankaccounts/             # BankAccountsScreen
└── shared/
    ├── components/               # Reusable Composables
    └── theme/                    # Material 3 theme
```

### Key Patterns

- **ViewModel**: `@HiltViewModel` classes with `StateFlow<UiState>` for reactive state. Each feature has a dedicated UiState data class.
- **Repository Pattern**: `AccountRepository` wraps API calls and returns `Result<T>` sealed class for type-safe error handling.
- **Dependency Injection**: Hilt with `@Provides` in modules for Retrofit, OkHttpClient, Gson, and repositories.
- **Navigation**: Jetpack Navigation Compose with `Routes` object defining all destinations.

### Networking

- `ApiService` interface defines all Retrofit endpoints
- `NetworkModule` configures OkHttpClient with logging interceptor (30s timeouts)
- `AccountRepository.handleResponse<T>()` converts Retrofit responses to `Result<T>`

### Stripe Integration

- Stripe Android SDK (v20.48.6) via `libs.stripe.android`
- Ready for SetupIntent/PaymentIntent handling (SDK declared but payment flows not yet implemented)

## Parent Project

This is the Android client for a Stripe Connect demo. See `../CLAUDE.md` for:
- Backend API endpoints and structure
- Stripe v2 Accounts model details
- Test data (cards, bank accounts)
- Full-stack architecture
