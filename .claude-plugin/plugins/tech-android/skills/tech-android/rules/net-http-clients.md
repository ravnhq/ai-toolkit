---
title: HTTP Clients — Retrofit, Ktor, Error Handling
impact: HIGH
tags: networking, retrofit, ktor, error-handling, interceptor, auth, headers
---

## HTTP Clients — Retrofit, Ktor, Error Handling

Use suspend functions, handle errors with `Result`, and configure clients with interceptors/plugins for cross-cutting concerns. Choose between Retrofit and Ktor based on project needs.

### Retrofit

Use `suspend` functions, not `Call<T>`. Configure OkHttp interceptors for auth and logging.

**Incorrect:**

```kotlin
// Bad - blocking Call, no cancellation support
interface UserApi {
    @GET("users/{id}")
    fun getUser(@Path("id") id: String): Call<UserDto>
}

// Bad - swallows all errors
class UserRepository(private val api: UserApi) {
    suspend fun getUser(id: String): UserDto? {
        return try {
            api.getUser(id).execute().body()  // Blocks!
        } catch (e: Exception) {
            null  // Network error? 404? Parse failure? Who knows
        }
    }
}
```

**Correct:**

```kotlin
// Good - suspend functions
interface UserApi {
    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): UserDto

    @GET("users")
    suspend fun getUsers(@Query("page") page: Int): List<UserDto>
}

// Good - structured error handling with Result
class UserRepositoryImpl(private val api: UserApi) : UserRepository {
    override suspend fun getUser(id: String): Result<User> {
        return runCatching { api.getUser(id).toDomain() }
    }
}

// Good - OkHttp client with interceptors
val okHttpClient = OkHttpClient.Builder()
    .addInterceptor(AuthInterceptor(tokenProvider))
    .addInterceptor(HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BODY
        else HttpLoggingInterceptor.Level.NONE
    })
    .connectTimeout(30, TimeUnit.SECONDS)
    .readTimeout(30, TimeUnit.SECONDS)
    .build()

val retrofit = Retrofit.Builder()
    .baseUrl("https://api.example.com/")
    .client(okHttpClient)
    .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
    .build()
```

### Ktor

Configure with plugins for content negotiation, logging, and timeouts. Use `HttpClient` as a singleton.

**Incorrect:**

```kotlin
// Bad - raw client, manual JSON, no error handling
val client = HttpClient()
val json = client.get("https://api.example.com/users/$id").bodyAsText()
return Json.decodeFromString(json)  // Crashes on non-200
```

**Correct:**

```kotlin
// Good - configured singleton with plugins
val client = HttpClient(OkHttp) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true; isLenient = true })
    }
    install(Logging) {
        level = if (BuildConfig.DEBUG) LogLevel.BODY else LogLevel.NONE
    }
    install(HttpTimeout) {
        requestTimeoutMillis = 30_000
        connectTimeoutMillis = 15_000
    }
    install(DefaultRequest) {
        url("https://api.example.com/")
        contentType(ContentType.Application.Json)
    }
}

// Good - repository with Result wrapper
class UserRepositoryImpl(private val client: HttpClient) : UserRepository {
    override suspend fun getUser(id: String): Result<User> {
        return runCatching { client.get("users/$id").body<UserDto>().toDomain() }
    }
}
```

### Auth Interceptors, Token Refresh, and Custom Headers

Centralize authentication and custom headers in interceptors (OkHttp) or plugins (Ktor). Handle 401 responses with transparent token refresh and request retry.

**Incorrect:**

```kotlin
// Bad - auth logic scattered per-endpoint
interface UserApi {
    @GET("users/{id}")
    suspend fun getUser(
        @Header("Authorization") token: String,  // Repeated on every call
        @Header("X-App-Version") version: String, // Repeated on every call
        @Path("id") id: String
    ): UserDto
}

// Bad - caller must remember to pass token
class UserRepositoryImpl(
    private val api: UserApi,
    private val prefs: SharedPreferences
) : UserRepository {
    override suspend fun getUser(id: String): Result<User> {
        val token = prefs.getString("token", "") ?: ""
        return runCatching {
            api.getUser("Bearer $token", BuildConfig.VERSION_NAME, id).toDomain()
        }
    }
}
```

**Correct — OkHttp interceptors (Retrofit):**

```kotlin
// Good - auth interceptor attaches token to every request
class AuthInterceptor(
    private val tokenProvider: TokenProvider
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val token = tokenProvider.accessToken ?: return chain.proceed(chain.request())
        val request = chain.request().newBuilder()
            .header("Authorization", "Bearer $token")
            .build()
        return chain.proceed(request)
    }
}

// Good - authenticator handles 401 with token refresh and retry
class TokenAuthenticator(
    private val tokenProvider: TokenProvider
) : Authenticator {
    override fun authenticate(route: Route?, response: Response): Request? {
        // Avoid infinite retry loops
        if (response.request.header("X-Retry-Auth") != null) return null

        val newToken = runBlocking { tokenProvider.refreshToken() } ?: return null
        return response.request.newBuilder()
            .header("Authorization", "Bearer $newToken")
            .header("X-Retry-Auth", "true")
            .build()
    }
}

// Good - custom headers interceptor for app-wide metadata
class AppHeadersInterceptor(
    private val appVersion: String,
    private val deviceId: () -> String
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request().newBuilder()
            .header("X-App-Version", appVersion)
            .header("X-Device-Id", deviceId())
            .header("X-Platform", "Android")
            .build()
        return chain.proceed(request)
    }
}

// Good - wire everything into OkHttpClient
val okHttpClient = OkHttpClient.Builder()
    .addInterceptor(AppHeadersInterceptor(BuildConfig.VERSION_NAME, deviceIdProvider::get))
    .addInterceptor(AuthInterceptor(tokenProvider))
    .authenticator(TokenAuthenticator(tokenProvider))  // Handles 401 retry
    .addInterceptor(loggingInterceptor)                // Logging last to capture final headers
    .build()
```

**Correct — Ktor plugin equivalent:**

```kotlin
val client = HttpClient(OkHttp) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }

    // Custom headers on every request
    install(DefaultRequest) {
        url("https://api.example.com/")
        header("X-App-Version", BuildConfig.VERSION_NAME)
        header("X-Platform", "Android")
    }

    // Auth with automatic 401 refresh
    install(Auth) {
        bearer {
            loadTokens {
                val access = tokenProvider.accessToken ?: ""
                val refresh = tokenProvider.refreshTokenString ?: ""
                BearerTokens(access, refresh)
            }
            refreshTokens {
                val newToken = tokenProvider.refreshToken()
                    ?: return@refreshTokens null
                BearerTokens(newToken, tokenProvider.refreshTokenString ?: "")
            }
        }
    }
}
```

**Key points:**
- **`Interceptor`** — runs on every request; use for attaching headers (auth, app metadata)
- **`Authenticator`** — runs only on 401 responses; use for token refresh + retry
- Add a retry guard header (`X-Retry-Auth`) to prevent infinite 401 loops
- Ktor's `Auth` plugin with `bearer { refreshTokens {} }` handles the same flow declaratively
- Logging interceptor should be added last so it captures the final request with all headers

### Choosing Between Retrofit and Ktor

| Criteria | Retrofit | Ktor |
|----------|----------|------|
| **API style** | Interface + annotations | DSL builder |
| **KMP support** | Android/JVM only | Multiplatform |
| **WebSocket** | Via OkHttp | First-class support |
| **Testing** | MockWebServer | MockEngine (no server) |
| **Ecosystem** | Mature, widely adopted | Growing, JetBrains-maintained |

- **Retrofit** — Android-only REST APIs, team familiarity, mature interceptor ecosystem
- **Ktor** — Kotlin Multiplatform, first-class WebSocket, DSL-based config, MockEngine testing
- **Both together** is fine — e.g., Retrofit for REST, Ktor for WebSocket

**Why it matters:**
- `Call<T>` blocks threads and ignores coroutine cancellation
- Swallowing exceptions hides network, auth, and parsing failures
- Interceptors/plugins centralize auth, logging, and retry — don't repeat per-endpoint
- `HttpClient` and `OkHttpClient` should be singletons — creating per-request wastes resources

Reference: [Retrofit](https://square.github.io/retrofit/) | [Ktor Client](https://ktor.io/docs/client-create-new-application.html)
