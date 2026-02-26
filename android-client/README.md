# Android Client - Hilt Dependency Injection Setup

This document highlights the key implementation details for getting Hilt dependency injection working in this Android project.

## Dependencies

Add these to your version catalog (`gradle/libs.versions.toml`):

```toml
[versions]
hilt = "2.58"
ksp = "2.0.21-1.0.28"
hiltNavigationCompose = "1.2.0"

[libraries]
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-compiler", version.ref = "hilt" }
hilt-navigation-compose = { group = "androidx.hilt", name = "hilt-navigation-compose", version.ref = "hiltNavigationCompose" }

[plugins]
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

## Gradle Configuration

In `app/build.gradle.kts`:

```kotlin
plugins {
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

dependencies {
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
}
```

## Implementation Steps

### 1. Application Class

Annotate your `Application` class with `@HiltAndroidApp`:

```kotlin
@HiltAndroidApp
class StripeDemoApplication : Application()
```

Register it in `AndroidManifest.xml`:

```xml
<application
    android:name=".StripeDemoApplication"
    ...>
```

### 2. Activity Entry Point

Annotate activities with `@AndroidEntryPoint`:

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    // Hilt can now inject dependencies here
}
```

### 3. Hilt Modules

Create modules in a `di/` package. Use `@Module`, `@InstallIn`, and `@Provides`:

**NetworkModule.kt** - Provides networking dependencies:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
}
```

**RepositoryModule.kt** - Provides repository dependencies:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideAccountRepository(
        apiService: ApiService,
        gson: Gson
    ): AccountRepository {
        return AccountRepository(apiService, gson)
    }
}
```

### 4. ViewModels with Hilt

Annotate ViewModels with `@HiltViewModel` and use `@Inject constructor`:

```kotlin
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val accountRepository: AccountRepository
) : ViewModel() {
    // ViewModel implementation
}
```

### 5. Obtaining ViewModels in Composables

Use `hiltViewModel()` from `androidx.hilt.navigation.compose`:

```kotlin
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    // UI implementation
}
```

## Dependency Graph

```
SingletonComponent
├── Gson
├── OkHttpClient
│   └── HttpLoggingInterceptor
├── Retrofit
│   ├── OkHttpClient
│   └── Gson
├── ApiService
│   └── Retrofit
└── AccountRepository
    ├── ApiService
    ├── Gson
    └── OkHttpClient
```

## Key Points

| Annotation | Purpose |
|------------|---------|
| `@HiltAndroidApp` | Triggers Hilt code generation, placed on Application class |
| `@AndroidEntryPoint` | Enables injection in Android classes (Activity, Fragment, etc.) |
| `@Module` | Declares a class as a Hilt module |
| `@InstallIn(SingletonComponent::class)` | Scopes module to application lifecycle |
| `@Provides` | Tells Hilt how to create an instance |
| `@Singleton` | Creates only one instance for the app |
| `@HiltViewModel` | Enables ViewModel injection |
| `@Inject constructor` | Constructor injection for dependencies |

## Common Issues

1. **Missing `@HiltAndroidApp`**: Build fails with "Hilt Activity must be attached to an @HiltAndroidApp Application"

2. **KSP vs KAPT**: This project uses KSP (`ksp(libs.hilt.compiler)`) which is faster than KAPT. Don't mix them.

3. **Missing `hilt-navigation-compose`**: Required for `hiltViewModel()` function in Compose.

4. **Manifest registration**: The Application class must be registered with `android:name` in the manifest.
