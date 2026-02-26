# Android Architecture Reference

This document describes the architecture patterns used in this Android app. Use it as a reference for refactoring other Android projects.

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Project Structure](#project-structure)
3. [Dependency Injection (Hilt)](#dependency-injection-hilt)
4. [Networking](#networking)
5. [Repository Pattern](#repository-pattern)
6. [ViewModel Pattern](#viewmodel-pattern)
7. [DataStore Preferences](#datastore-preferences)
8. [Navigation](#navigation)
9. [Feature Module Structure](#feature-module-structure)
10. [Data Models](#data-models)
11. [Utilities](#utilities)
12. [Build Configuration](#build-configuration)

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Jetpack Compose, Material 3 |
| DI | Hilt |
| Networking | Retrofit, Moshi, OkHttp |
| State | StateFlow, ViewModel |
| Persistence | DataStore Preferences |
| Async | Kotlin Coroutines |
| Build | Gradle KTS, KSP |

---

## Project Structure

```
app/src/main/java/com/example/scheduler/
├── app/
│   ├── SchedulerApp.kt              # @HiltAndroidApp Application class
│   └── MainActivity.kt              # @AndroidEntryPoint, hosts root ViewModel
├── core/
│   ├── datastore/
│   │   └── DataStoreModule.kt       # Provides DataStore<Preferences>
│   ├── navigation/
│   │   ├── AppNavigation.kt         # MainScreen, bottom nav, screen routing
│   │   ├── MainViewModel.kt         # Root ViewModel (users, preferences)
│   │   └── Tabs.kt                  # AppScreen enum (tab definitions)
│   └── networking/
│       └── NetworkModule.kt         # Provides Retrofit, Moshi, OkHttpClient
├── data/
│   ├── model/                       # Data classes (User, Meeting, TimeSlot, etc.)
│   └── repositories/
│       ├── SchedulerRepository.kt   # Result-wrapped API calls
│       └── SchedulerEndpoints.kt    # Retrofit API interface
├── features/                        # Feature modules
│   ├── calendar/
│   │   ├── CalendarScreen.kt
│   │   ├── CalendarViewModel.kt
│   │   └── components/
│   ├── availability/
│   │   ├── AvailabilityScreen.kt
│   │   ├── AvailabilityViewModel.kt
│   │   └── components/
│   ├── schedule/
│   │   ├── ScheduleScreen.kt
│   │   ├── ScheduleViewModel.kt
│   │   └── components/
│   └── settings/
│       ├── SettingsScreen.kt
│       ├── SettingsViewModel.kt
│       └── components/
└── shared/
    ├── components/                  # Header, UserAvatar, etc.
    ├── state/
    │   └── AppPreferences.kt        # Singleton preferences manager
    ├── theme/                       # Color, Theme, Type
    └── utils/                       # Time formatting, helpers
```

---

## Dependency Injection (Hilt)

### Application Class

```kotlin
@HiltAndroidApp
class SchedulerApp : Application()
```

### Activity Entry Point

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AppTheme {
                val viewModel: MainViewModel = hiltViewModel()
                val state by viewModel.state.collectAsState()

                MainScreen(
                    users = state.users,
                    isLoading = state.isLoading,
                    error = state.error,
                    onRetry = viewModel::retry
                )
            }
        }
    }
}
```

### Module Definition

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideRetrofit(): Retrofit { ... }

    @Provides
    @Singleton
    fun provideApi(retrofit: Retrofit): MyApi {
        return retrofit.create(MyApi::class.java)
    }
}
```

### Key Annotations

| Annotation | Purpose |
|------------|---------|
| `@HiltAndroidApp` | Marks Application class, triggers DI setup |
| `@AndroidEntryPoint` | Enables injection in Activity/Fragment |
| `@HiltViewModel` | Marks ViewModel for Hilt management |
| `@Module` | Defines a class that provides dependencies |
| `@InstallIn(SingletonComponent::class)` | Scope module to app lifetime |
| `@Provides` | Function that creates a dependency |
| `@Singleton` | Single instance across app |
| `@Inject constructor()` | Constructor injection |
| `@ApplicationContext` | Qualifier for app context |

---

## Networking

### Network Module

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideMoshi(): Moshi {
        return Moshi.Builder()
            .addLast(KotlinJsonAdapterFactory())
            .build()
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, moshi: Moshi): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    @Provides
    @Singleton
    fun provideApi(retrofit: Retrofit): MyApi {
        return retrofit.create(MyApi::class.java)
    }
}
```

### API Interface

```kotlin
interface MyApi {
    @GET("users")
    suspend fun getUsers(): List<User>

    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): User

    @POST("items")
    suspend fun createItem(@Body item: CreateItemRequest): Item

    @PUT("items/{id}")
    suspend fun updateItem(@Path("id") id: String, @Body item: Item): Item

    @DELETE("items/{id}")
    suspend fun deleteItem(@Path("id") id: String): DeleteResponse
}
```

**Key Points:**
- All methods are `suspend` functions (coroutine-based)
- Use `@Path`, `@Body`, `@Query` for parameters
- Moshi handles JSON serialization automatically

---

## Repository Pattern

```kotlin
@Singleton
class MyRepository @Inject constructor(
    private val api: MyApi
) {
    suspend fun getUsers(): Result<List<User>> {
        return runCatching { api.getUsers() }
    }

    suspend fun getUser(id: String): Result<User> {
        return runCatching { api.getUser(id) }
    }

    suspend fun createItem(request: CreateItemRequest): Result<Item> {
        return runCatching { api.createItem(request) }
    }

    suspend fun deleteItem(id: String): Result<Unit> {
        return runCatching {
            api.deleteItem(id)
            Unit
        }
    }
}
```

**Pattern Benefits:**
- **Result Wrapping**: Uses Kotlin's `Result<T>` for success/failure handling
- **runCatching**: Converts exceptions to Result automatically
- **Single Source of Truth**: All API calls go through repository
- **Testability**: Easy to mock for unit tests

### Result Usage in ViewModel

```kotlin
repository.getUsers()
    .onSuccess { users ->
        _state.update { it.copy(users = users, isLoading = false) }
    }
    .onFailure { error ->
        _state.update { it.copy(error = error.message, isLoading = false) }
    }
```

---

## ViewModel Pattern

### State Class

```kotlin
data class MyScreenState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)
```

### ViewModel Implementation

```kotlin
@HiltViewModel
class MyViewModel @Inject constructor(
    private val repository: MyRepository
) : ViewModel() {

    private val _state = MutableStateFlow(MyScreenState())
    val state: StateFlow<MyScreenState> = _state.asStateFlow()

    init {
        fetchData()
    }

    fun fetchData() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }

            repository.getItems()
                .onSuccess { items ->
                    _state.update { it.copy(items = items, isLoading = false) }
                }
                .onFailure { e ->
                    _state.update { it.copy(isLoading = false, error = e.message) }
                }
        }
    }

    fun deleteItem(id: String) {
        viewModelScope.launch {
            // Optimistic update
            _state.update { current ->
                current.copy(items = current.items.filter { it.id != id })
            }

            repository.deleteItem(id)
                .onFailure {
                    // Refetch on error to restore correct state
                    fetchData()
                }
        }
    }
}
```

### Screen Composable

```kotlin
@Composable
fun MyScreen(
    viewModel: MyViewModel = hiltViewModel(),
    modifier: Modifier = Modifier
) {
    val state by viewModel.state.collectAsState()

    when {
        state.isLoading -> LoadingScreen()
        state.error != null -> ErrorScreen(
            error = state.error!!,
            onRetry = viewModel::fetchData
        )
        else -> {
            ItemList(
                items = state.items,
                onDelete = viewModel::deleteItem
            )
        }
    }
}
```

### Key Patterns

| Pattern | Description |
|---------|-------------|
| `MutableStateFlow` | Internal mutable state |
| `asStateFlow()` | Expose read-only to UI |
| `viewModelScope` | Auto-cancels on ViewModel destruction |
| `_state.update {}` | Thread-safe state mutation |
| `collectAsState()` | Subscribe to Flow in Compose |

### Optimistic Updates

1. Update local state immediately (instant UI feedback)
2. Call API in background
3. On error, refetch from server to restore truth

---

## DataStore Preferences

### DataStore Module

```kotlin
private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "app_preferences"
)

@Module
@InstallIn(SingletonComponent::class)
object DataStoreModule {

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> {
        return context.dataStore
    }
}
```

### Preferences Manager

```kotlin
@Singleton
class AppPreferences @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    private companion object {
        val CURRENT_USER_KEY = stringPreferencesKey("current_user_id")
        val USE_24_HOUR_KEY = booleanPreferencesKey("use_24_hour_format")
    }

    val currentUserId: Flow<String> = dataStore.data.map { prefs ->
        prefs[CURRENT_USER_KEY] ?: ""
    }

    val use24HourFormat: Flow<Boolean> = dataStore.data.map { prefs ->
        prefs[USE_24_HOUR_KEY] ?: false
    }

    suspend fun setCurrentUserId(userId: String) {
        dataStore.edit { prefs ->
            prefs[CURRENT_USER_KEY] = userId
        }
    }

    suspend fun setUse24HourFormat(use24Hour: Boolean) {
        dataStore.edit { prefs ->
            prefs[USE_24_HOUR_KEY] = use24Hour
        }
    }
}
```

### ViewModel Integration

```kotlin
@HiltViewModel
class MainViewModel @Inject constructor(
    private val appPreferences: AppPreferences
) : ViewModel() {

    val currentUserId: StateFlow<String> = appPreferences.currentUserId
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = ""
        )

    fun setCurrentUser(userId: String) {
        viewModelScope.launch {
            appPreferences.setCurrentUserId(userId)
        }
    }
}
```

**Key Points:**
- `stateIn()` converts cold Flow to hot StateFlow
- `SharingStarted.WhileSubscribed(5000)` stops collecting 5s after last subscriber
- Non-blocking, type-safe replacement for SharedPreferences

---

## Navigation

### Tab Definitions

```kotlin
enum class AppScreen(
    val title: String,
    val icon: ImageVector
) {
    HOME("Home", Icons.Default.Home),
    SEARCH("Search", Icons.Default.Search),
    PROFILE("Profile", Icons.Default.Person),
    SETTINGS("Settings", Icons.Default.Settings)
}
```

### Main Screen with Bottom Navigation

```kotlin
@Composable
fun MainScreen(
    users: List<User>,
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit
) {
    var currentScreen by remember { mutableStateOf(AppScreen.HOME) }

    Scaffold(
        topBar = {
            Header(...)
        },
        bottomBar = {
            NavigationBar {
                AppScreen.entries.forEach { screen ->
                    NavigationBarItem(
                        icon = { Icon(screen.icon, contentDescription = screen.title) },
                        label = { Text(screen.title) },
                        selected = currentScreen == screen,
                        onClick = { currentScreen = screen }
                    )
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                isLoading -> LoadingScreen()
                error != null -> ErrorScreen(error = error, onRetry = onRetry)
                else -> {
                    when (currentScreen) {
                        AppScreen.HOME -> HomeScreen()
                        AppScreen.SEARCH -> SearchScreen()
                        AppScreen.PROFILE -> ProfileScreen()
                        AppScreen.SETTINGS -> SettingsScreen()
                    }
                }
            }
        }
    }
}
```

**Key Points:**
- State-driven routing with `when` expression
- `Scaffold` provides Material Design layout structure
- Loading/error states handled at root level
- Each screen is a composable with its own ViewModel

---

## Feature Module Structure

### Organization

```
features/
└── myfeature/
    ├── MyFeatureScreen.kt       # Root composable
    ├── MyFeatureViewModel.kt    # Business logic, state
    └── components/              # Feature-specific UI components
        ├── ItemCard.kt
        ├── FilterBar.kt
        └── DetailDialog.kt
```

### Screen Pattern

```kotlin
@Composable
fun MyFeatureScreen(
    currentUserId: String,              // Data from parent
    onNavigate: (String) -> Unit,       // Callbacks to parent
    viewModel: MyFeatureViewModel = hiltViewModel(),
    modifier: Modifier = Modifier
) {
    val state by viewModel.state.collectAsState()

    // Sync with parent state changes
    LaunchedEffect(currentUserId) {
        viewModel.setCurrentUserId(currentUserId)
    }

    // Local UI state
    var selectedItem by remember { mutableStateOf<Item?>(null) }

    Column(modifier = modifier.fillMaxSize()) {
        // Header
        FeatureHeader(
            title = "My Feature",
            onAction = { ... }
        )

        // Content
        when {
            state.isLoading -> LoadingIndicator()
            state.error != null -> ErrorMessage(state.error!!)
            else -> {
                ItemList(
                    items = state.items,
                    onItemClick = { selectedItem = it }
                )
            }
        }
    }

    // Dialogs
    selectedItem?.let { item ->
        ItemDetailDialog(
            item = item,
            onDismiss = { selectedItem = null },
            onDelete = {
                viewModel.deleteItem(item.id)
                selectedItem = null
            }
        )
    }
}
```

### Component Pattern (Stateless)

```kotlin
@Composable
fun ItemCard(
    item: Item,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(item.title)
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete")
            }
        }
    }
}
```

**Key Principles:**
- Screens own ViewModels, components are stateless
- Components receive data and callbacks as parameters
- `LaunchedEffect` syncs ViewModel with parent state
- Local UI state (dialogs, selections) stays in Screen

---

## Data Models

### Moshi Data Class

```kotlin
@JsonClass(generateAdapter = true)
data class User(
    val id: String,
    val name: String,
    val email: String,
    @Json(name = "avatar_color") val avatarColor: String
)
```

### Request/Response Models

```kotlin
@JsonClass(generateAdapter = true)
data class CreateItemRequest(
    val title: String,
    val description: String,
    val userId: String
)

@JsonClass(generateAdapter = true)
data class DeleteResponse(
    val success: Boolean,
    val message: String
)
```

**Annotations:**
- `@JsonClass(generateAdapter = true)` - Moshi code generation
- `@Json(name = "...")` - Map Kotlin property to JSON field name

---

## Utilities

### Time Formatting

```kotlin
fun formatHour(hour: Double, use24HourFormat: Boolean = false): String {
    val hours = hour.toInt()
    val minutes = ((hour - hours) * 60).toInt()

    return if (use24HourFormat) {
        String.format("%02d:%02d", hours, minutes)
    } else {
        val period = if (hours < 12) "AM" else "PM"
        val displayHour = when {
            hours == 0 -> 12
            hours > 12 -> hours - 12
            else -> hours
        }
        if (minutes == 0) "$displayHour $period"
        else String.format("%d:%02d %period", displayHour, minutes)
    }
}

fun formatTimeRange(
    startHour: Double,
    endHour: Double,
    use24HourFormat: Boolean = false
): String {
    return "${formatHour(startHour, use24HourFormat)} - ${formatHour(endHour, use24HourFormat)}"
}
```

### Date Extensions

```kotlin
fun LocalDate.toIsoString(): String =
    this.format(DateTimeFormatter.ISO_LOCAL_DATE)

fun String.toLocalDate(): LocalDate =
    LocalDate.parse(this, DateTimeFormatter.ISO_LOCAL_DATE)

fun formatDateShort(date: LocalDate): String {
    val dayOfWeek = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault())
    return "$dayOfWeek ${date.dayOfMonth}"
}
```

---

## Build Configuration

### app/build.gradle.kts

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.example.myapp"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        // API URL configured here
        buildConfigField("String", "API_URL", "\"https://api.example.com/\"")
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    // Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.activity.compose)

    // Hilt
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    // Networking
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.moshi)
    implementation(libs.moshi)
    implementation(libs.moshi.kotlin)
    ksp(libs.moshi.codegen)
    implementation(libs.okhttp.logging)

    // DataStore
    implementation(libs.androidx.datastore.preferences)

    // Lifecycle
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)

    // Coroutines
    implementation(libs.kotlinx.coroutines.android)
}
```

### Version Catalog (libs.versions.toml)

```toml
[versions]
kotlin = "2.0.21"
hilt = "2.56.1"
retrofit = "2.11.0"
moshi = "1.15.2"
okhttp = "4.12.0"
datastore = "1.1.4"
lifecycle = "2.8.7"
coroutines = "1.10.2"

[libraries]
hilt-android = { module = "com.google.dagger:hilt-android", version.ref = "hilt" }
hilt-compiler = { module = "com.google.dagger:hilt-compiler", version.ref = "hilt" }
hilt-navigation-compose = { module = "androidx.hilt:hilt-navigation-compose", version = "1.2.0" }

retrofit = { module = "com.squareup.retrofit2:retrofit", version.ref = "retrofit" }
retrofit-converter-moshi = { module = "com.squareup.retrofit2:converter-moshi", version.ref = "retrofit" }
moshi = { module = "com.squareup.moshi:moshi", version.ref = "moshi" }
moshi-kotlin = { module = "com.squareup.moshi:moshi-kotlin", version.ref = "moshi" }
moshi-codegen = { module = "com.squareup.moshi:moshi-kotlin-codegen", version.ref = "moshi" }
okhttp-logging = { module = "com.squareup.okhttp3:logging-interceptor", version.ref = "okhttp" }

androidx-datastore-preferences = { module = "androidx.datastore:datastore-preferences", version.ref = "datastore" }
androidx-lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }

[plugins]
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version = "2.0.21-1.0.28" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

---

## Summary Checklist

When refactoring an Android project to this architecture:

- [ ] Add Hilt plugins to root and app build.gradle
- [ ] Create `@HiltAndroidApp` Application class
- [ ] Add `@AndroidEntryPoint` to MainActivity
- [ ] Create `core/networking/NetworkModule.kt` with Retrofit/Moshi/OkHttp
- [ ] Create `core/datastore/DataStoreModule.kt` for preferences
- [ ] Create API interface with suspend functions
- [ ] Create Repository with Result-wrapped methods
- [ ] Create `shared/state/AppPreferences.kt` for user preferences
- [ ] Create state data classes for each screen
- [ ] Create `@HiltViewModel` classes with StateFlow
- [ ] Create feature modules with Screen/ViewModel/components structure
- [ ] Use `hiltViewModel()` in composables
- [ ] Use `collectAsState()` to observe StateFlows
- [ ] Implement optimistic updates in ViewModels
- [ ] Use `LaunchedEffect` to sync ViewModel with parent state