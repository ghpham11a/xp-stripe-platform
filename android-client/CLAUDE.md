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
buildConfigField("String", "API_URL", "\"https://xp-server.ngrok.dev/\"")
buildConfigField("String", "STRIPE_PUBLISHABLE_KEY", "\"pk_test_YOUR_KEY\"")
```

Values are accessed at runtime via `BuildConfig.API_URL` and `BuildConfig.STRIPE_PUBLISHABLE_KEY`.

## Architecture

Jetpack Compose app using MVVM with Hilt dependency injection, Retrofit/Moshi networking, and DataStore for persistence.

### Project Structure

```
com.example.stripedemo/
├── app/
│   ├── MainActivity.kt               # @AndroidEntryPoint single-activity entry
│   └── StripeDemoApplication.kt      # @HiltAndroidApp
├── core/
│   ├── datastore/
│   │   ├── DataStoreModule.kt        # Hilt module for DataStore<Preferences>
│   │   └── AppPreferences.kt         # Preferences manager (selected account persistence)
│   ├── navigation/
│   │   ├── AppNavigation.kt          # NavHost with screen routing
│   │   └── AppViewModel.kt           # Root ViewModel
│   └── networking/
│       └── NetworkModule.kt          # Hilt module: Retrofit, Moshi, OkHttp
├── data/
│   ├── models/                       # @JsonClass data classes (Account, PaymentMethod, etc.)
│   └── repositories/
│       └── accounts/
│           ├── AccountsEndpoints.kt  # Retrofit interface with suspend functions
│           └── AccountRepository.kt  # Result-wrapped API calls + direct Stripe API
├── features/
│   ├── home/                         # Account list/selection, create account
│   ├── accountdetail/                # Account capabilities, upgrade to recipient, onboarding
│   ├── paymentmethods/               # SetupIntent flow, list/delete payment methods
│   └── bankaccounts/                 # Bank account management
└── shared/
    ├── components/                   # Reusable Composables (PayUserForm)
    └── theme/                        # Material 3 theme
```

### Key Patterns

- **ViewModel**: `@HiltViewModel` classes with `StateFlow<UiState>` for reactive state. Each feature has a dedicated UiState data class.
- **Repository Pattern**: `AccountRepository` wraps API calls, returns Kotlin `Result<T>` for type-safe error handling.
- **Dependency Injection**: Hilt with `@Module`/`@InstallIn(SingletonComponent::class)`/`@Provides` in `core/` modules.
- **DataStore**: `AppPreferences` persists selected account ID across sessions.
- **Navigation**: Jetpack Navigation Compose with routes defined in `AppNavigation.kt`.

### Networking

- `AccountsEndpoints` - Retrofit interface defining all backend API endpoints
- `NetworkModule` - Provides Retrofit, Moshi (with `KotlinJsonAdapterFactory`), OkHttpClient (30s timeouts, logging interceptor)
- `AccountRepository` - Wraps Retrofit calls in `Result<T>`, handles direct Stripe API calls for bank token creation

### Bank Account Token Creation

Bank account tokens are created via direct POST to `https://api.stripe.com/v1/tokens` using the publishable key (bypasses SDK). This is implemented in `AccountRepository.createBankAccountToken()` using OkHttp directly.

### Stripe Integration

- Stripe Android SDK (v20.48.6) via `libs.stripe.android`
- SetupIntent flow for saving payment methods
- Bank tokens created via direct API call (no SDK import needed)

## Parent Project

This is the Android client for a Stripe Connect demo. See `../CLAUDE.md` for:
- Backend API endpoints and structure
- Stripe v2 Accounts model details
- Test data (cards: `4242 4242 4242 4242`, bank: routing `110000000`, account `000123456789`)
- Full-stack architecture
