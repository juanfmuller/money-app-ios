# 🔗 iOS API Integration Rules

## API Integration Philosophy

This iOS app uses **polling-based data synchronization** with the FastAPI backend. No caching is implemented - all data is fetched fresh on demand for maximum simplicity and fast iteration.

## 🎯 Integration Architecture

### Backend API Overview

The Money App backend provides these key endpoints:

```swift
// Authentication Endpoints
POST /api/auth/register     // Create new user account
POST /api/auth/login        // User login with JWT token
POST /api/auth/device-token // Update iOS device token for push notifications

// Account Management Endpoints  
POST /api/accounts/link/token    // Create Plaid Link token
POST /api/accounts/link/exchange // Link bank account via Plaid
GET  /api/accounts/             // Get user's linked accounts
POST /api/accounts/sync         // Manual account/transaction sync
GET  /api/accounts/sync/status  // Get sync status (for polling)

// Transaction Endpoints
GET /api/transactions/          // Get transactions with filtering/pagination
GET /api/transactions/recent    // Get recent transactions (optimized for polling)  
GET /api/transactions/summary   // Get spending summary and analytics
GET /api/transactions/categories // Get available spending categories

// Notification Endpoints
POST /api/notifications/test    // Send test push notification
GET  /api/notifications/preferences // Get notification settings
```

## 🏗️ Service Layer Architecture

### Base API Client

```swift
// ✅ GOOD: Centralized API client with JWT auth
class APIClient {
    static let shared = APIClient()
    
    private let baseURL: URL
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    init() {
        self.baseURL = URL(string: AppConfig.apiBaseURL)!
        
        // Configure session with reasonable timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Configure JSON handling
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // GET request
    func get<T: Codable>(_ endpoint: String, queryParams: [String: String] = [:]) async throws -> T {
        let request = try buildRequest(method: "GET", endpoint: endpoint, queryParams: queryParams)
        return try await performRequest(request)
    }
    
    // POST request with body
    func post<T: Codable, U: Codable>(_ endpoint: String, body: U) async throws -> T {
        let request = try buildRequest(method: "POST", endpoint: endpoint, body: body)
        return try await performRequest(request)
    }
    
    // POST request without body
    func post<T: Codable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(method: "POST", endpoint: endpoint)
        return try await performRequest(request)
    }
    
    // PUT request
    func put<T: Codable, U: Codable>(_ endpoint: String, body: U) async throws -> T {
        let request = try buildRequest(method: "PUT", endpoint: endpoint, body: body)
        return try await performRequest(request)
    }
    
    // DELETE request
    func delete<T: Codable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(method: "DELETE", endpoint: endpoint)
        return try await performRequest(request)
    }
    
    private func buildRequest<T: Codable>(
        method: String,
        endpoint: String,
        queryParams: [String: String] = [:],
        body: T? = nil
    ) throws -> URLRequest {
        // Build URL with query parameters
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        
        if !queryParams.isEmpty {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header if token exists
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                throw APIError.encodingError
            }
        }
        
        return request
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try jsonDecoder.decode(T.self, from: data)
                } catch {
                    print("🔴 Decoding error for \(request.url?.path ?? "unknown"): \(error)")
                    throw APIError.decodingError
                }
                
            case 401:
                // Clear invalid token and throw auth error
                TokenManager.shared.clearTokens()
                throw APIError.unauthorized
                
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 408:
                throw APIError.requestTimeout
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.networkError
            }
            
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.noInternetConnection
            case .timedOut:
                throw APIError.requestTimeout
            default:
                throw APIError.networkError
            }
        } catch {
            throw APIError.networkError
        }
    }
}
```

### Feature-Specific Services

```swift
// ✅ GOOD: Authentication service matching backend endpoints
class AuthService {
    private let apiClient = APIClient.shared
    
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        return try await apiClient.post("/api/auth/register", body: request)
    }
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        let response: AuthResponse = try await apiClient.post("/api/auth/login", body: request)
        
        // Store JWT token for future requests
        TokenManager.shared.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        return response
    }
    
    func updateDeviceToken(_ token: String) async throws {
        let request = DeviceTokenRequest(deviceToken: token)
        let _: SuccessResponse = try await apiClient.post("/api/auth/device-token", body: request)
    }
    
    func logout() async throws {
        // Clear local tokens
        TokenManager.shared.clearTokens()
        
        // Optionally notify backend (if endpoint exists)
        // let _: SuccessResponse = try await apiClient.post("/api/auth/logout")
    }
}

// ✅ GOOD: Account service for Plaid integration
class AccountService {
    private let apiClient = APIClient.shared
    
    func createLinkToken() async throws -> LinkTokenResponse {
        let request = LinkTokenRequest(products: ["transactions"])
        return try await apiClient.post("/api/accounts/link/token", body: request)
    }
    
    func exchangePublicToken(_ publicToken: String) async throws -> ExchangeResponse {
        let request = PublicTokenExchangeRequest(publicToken: publicToken)
        return try await apiClient.post("/api/accounts/link/exchange", body: request)
    }
    
    func getAccounts() async throws -> AccountListResponse {
        return try await apiClient.get("/api/accounts/")
    }
    
    func syncAccounts() async throws -> SyncResponse {
        return try await apiClient.post("/api/accounts/sync")
    }
    
    func getSyncStatus() async throws -> SyncStatusResponse {
        return try await apiClient.get("/api/accounts/sync/status")
    }
}

// ✅ GOOD: Transaction service with polling optimization
class TransactionService {
    private let apiClient = APIClient.shared
    
    func getTransactions(
        limit: Int = 50,
        offset: Int = 0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: String? = nil
    ) async throws -> TransactionListResponse {
        var params: [String: String] = [
            "limit": String(limit),
            "offset": String(offset)
        ]
        
        if let startDate = startDate {
            params["start_date"] = ISO8601DateFormatter().string(from: startDate)
        }
        if let endDate = endDate {
            params["end_date"] = ISO8601DateFormatter().string(from: endDate)
        }
        if let category = category {
            params["category"] = category
        }
        
        return try await apiClient.get("/api/transactions/", queryParams: params)
    }
    
    // Optimized for polling - only recent transactions
    func getRecentTransactions(since: Date? = nil) async throws -> RecentTransactionsResponse {
        var params: [String: String] = [:]
        
        if let since = since {
            params["since"] = ISO8601DateFormatter().string(from: since)
        }
        
        return try await apiClient.get("/api/transactions/recent", queryParams: params)
    }
    
    func getSpendingSummary(startDate: Date, endDate: Date) async throws -> SpendingSummaryResponse {
        let params = [
            "start_date": ISO8601DateFormatter().string(from: startDate),
            "end_date": ISO8601DateFormatter().string(from: endDate)
        ]
        
        return try await apiClient.get("/api/transactions/summary", queryParams: params)
    }
    
    func getCategories() async throws -> CategoriesResponse {
        return try await apiClient.get("/api/transactions/categories")
    }
}
```

## 📱 Polling Strategy Implementation

### Automatic Background Polling

```swift
// ✅ GOOD: Polling manager for background data updates
@MainActor
class PollingManager: ObservableObject {
    static let shared = PollingManager()
    
    @Published var isPolling = false
    
    private var pollingTask: Task<Void, Never>?
    private let syncStatusInterval: TimeInterval = 180 // 3 minutes
    private let transactionInterval: TimeInterval = 120 // 2 minutes
    
    private let accountService = AccountService()
    private let transactionService = TransactionService()
    
    func startPolling() {
        guard !isPolling else { return }
        
        isPolling = true
        pollingTask = Task {
            await performPollingLoop()
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }
    
    private func performPollingLoop() async {
        while !Task.isCancelled {
            do {
                // Check if sync is recommended
                let syncStatus = try await accountService.getSyncStatus()
                if syncStatus.syncRecommended {
                    print("📡 Sync recommended, triggering account sync")
                    NotificationCenter.default.post(name: .syncRecommended, object: nil)
                }
                
                // Get recent transactions
                let lastUpdate = UserDefaults.standard.object(forKey: "last_transaction_update") as? Date
                let recentTransactions = try await transactionService.getRecentTransactions(since: lastUpdate)
                
                if !recentTransactions.transactions.isEmpty {
                    print("📡 Found \(recentTransactions.transactions.count) new transactions")
                    NotificationCenter.default.post(
                        name: .newTransactionsAvailable,
                        object: recentTransactions.transactions
                    )
                    
                    // Update last update timestamp
                    UserDefaults.standard.set(Date(), forKey: "last_transaction_update")
                }
                
                // Wait before next poll
                try await Task.sleep(nanoseconds: UInt64(syncStatusInterval * 1_000_000_000))
                
            } catch {
                print("🔴 Polling error: \(error)")
                
                // Exponential backoff on error
                try? await Task.sleep(nanoseconds: UInt64(min(syncStatusInterval * 2, 300) * 1_000_000_000))
            }
        }
    }
}

// Notification names for polling events
extension Notification.Name {
    static let syncRecommended = Notification.Name("syncRecommended")
    static let newTransactionsAvailable = Notification.Name("newTransactionsAvailable")
}
```

### ViewModel Polling Integration

```swift
// ✅ GOOD: ViewModel that responds to polling updates
@MainActor
class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    private let transactionService = TransactionService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPollingObservers()
    }
    
    private func setupPollingObservers() {
        // Listen for new transactions from polling
        NotificationCenter.default.publisher(for: .newTransactionsAvailable)
            .compactMap { $0.object as? [Transaction] }
            .sink { [weak self] newTransactions in
                self?.handleNewTransactions(newTransactions)
            }
            .store(in: &cancellables)
        
        // Listen for sync recommendations
        NotificationCenter.default.publisher(for: .syncRecommended)
            .sink { [weak self] _ in
                Task { await self?.refreshTransactions() }
            }
            .store(in: &cancellables)
    }
    
    func loadTransactions() async {
        isLoading = true
        
        do {
            let response = try await transactionService.getTransactions()
            transactions = response.transactions
            lastUpdated = Date()
        } catch {
            // Handle error
        }
        
        isLoading = false
    }
    
    func refreshTransactions() async {
        // Silent refresh without loading indicator
        do {
            let response = try await transactionService.getTransactions()
            transactions = response.transactions
            lastUpdated = Date()
        } catch {
            // Handle error silently in background refresh
        }
    }
    
    private func handleNewTransactions(_ newTransactions: [Transaction]) {
        // Merge new transactions with existing ones
        let existingIds = Set(transactions.map { $0.id })
        let uniqueNewTransactions = newTransactions.filter { !existingIds.contains($0.id) }
        
        transactions = (transactions + uniqueNewTransactions)
            .sorted { $0.date > $1.date }
        
        lastUpdated = Date()
    }
    
    func manualRefresh() async {
        await loadTransactions()
    }
}
```

## 📋 Data Models (Codable)

### Request Models

```swift
// ✅ GOOD: Request models matching backend schemas
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct DeviceTokenRequest: Codable {
    let deviceToken: String
    
    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
    }
}

struct LinkTokenRequest: Codable {
    let products: [String]
}

struct PublicTokenExchangeRequest: Codable {
    let publicToken: String
    
    enum CodingKeys: String, CodingKey {
        case publicToken = "public_token"
    }
}
```

### Response Models

```swift
// ✅ GOOD: Response models matching backend schemas
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
    let isActive: Bool
    let createdAt: Date
    let deviceToken: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case isActive = "is_active"
        case createdAt = "created_at"
        case deviceToken = "device_token"
    }
    
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else {
            return email
        }
    }
}

struct Account: Codable, Identifiable {
    let id: Int
    let accountId: String
    let name: String
    let accountType: String
    let accountSubtype: String?
    let balanceAvailable: Decimal?
    let balanceCurrent: Decimal
    let currencyCode: String
    let institutionName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case name
        case accountType = "account_type"
        case accountSubtype = "account_subtype"
        case balanceAvailable = "balance_available"
        case balanceCurrent = "balance_current"
        case currencyCode = "currency_code"
        case institutionName = "institution_name"
    }
}

struct Transaction: Codable, Identifiable {
    let id: Int
    let transactionId: String
    let amount: Decimal
    let currencyCode: String
    let name: String
    let merchantName: String?
    let date: Date
    let authorizedDate: Date?
    let category: [String]
    let primaryCategory: String
    let pending: Bool
    let accountId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case transactionId = "transaction_id"
        case amount
        case currencyCode = "currency_code"
        case name
        case merchantName = "merchant_name"
        case date
        case authorizedDate = "authorized_date"
        case category
        case primaryCategory = "primary_category"
        case pending
        case accountId = "account_id"
    }
    
    var isExpense: Bool {
        return amount > 0
    }
    
    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

struct AccountListResponse: Codable {
    let accounts: [Account]
    let total: Int
}

struct TransactionListResponse: Codable {
    let transactions: [Transaction]
    let total: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case transactions, total
        case hasMore = "has_more"
    }
}

struct RecentTransactionsResponse: Codable {
    let transactions: [Transaction]
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case lastUpdated = "last_updated"
    }
}

struct SyncStatusResponse: Codable {
    let syncRecommended: Bool
    let lastSyncAt: Date?
    let accountsNeedingUpdate: [Int]
    
    enum CodingKeys: String, CodingKey {
        case syncRecommended = "sync_recommended"
        case lastSyncAt = "last_sync_at"
        case accountsNeedingUpdate = "accounts_needing_update"
    }
}

struct SpendingSummaryResponse: Codable {
    let totalSpent: Decimal
    let transactionCount: Int
    let categoryBreakdown: [CategorySpending]
    let dailySpending: [DailySpending]
    
    enum CodingKeys: String, CodingKey {
        case totalSpent = "total_spent"
        case transactionCount = "transaction_count"
        case categoryBreakdown = "category_breakdown"
        case dailySpending = "daily_spending"
    }
}

struct CategorySpending: Codable {
    let category: String
    let amount: Decimal
    let transactionCount: Int
    let percentage: Decimal
    
    enum CodingKeys: String, CodingKey {
        case category, amount, percentage
        case transactionCount = "transaction_count"
    }
}

struct DailySpending: Codable {
    let date: Date
    let amount: Decimal
    let transactionCount: Int
    
    enum CodingKeys: String, CodingKey {
        case date, amount
        case transactionCount = "transaction_count"
    }
}

struct SuccessResponse: Codable {
    let message: String
}
```

## 🔐 Token Management

```swift
// ✅ GOOD: Secure token management with Keychain
class TokenManager {
    static let shared = TokenManager()
    
    private let keychainService = KeychainService.shared
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    func saveTokens(accessToken: String, refreshToken: String?) {
        keychainService.save(accessToken, for: accessTokenKey)
        if let refreshToken = refreshToken {
            keychainService.save(refreshToken, for: refreshTokenKey)
        }
    }
    
    func getAccessToken() -> String? {
        return keychainService.get(accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return keychainService.get(refreshTokenKey)
    }
    
    func clearTokens() {
        keychainService.delete(accessTokenKey)
        keychainService.delete(refreshTokenKey)
    }
    
    var isAuthenticated: Bool {
        return getAccessToken() != nil
    }
}
```

## 📱 App Lifecycle Integration

```swift
// ✅ GOOD: Polling lifecycle management
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Start polling when app launches (if authenticated)
        if TokenManager.shared.isAuthenticated {
            PollingManager.shared.startPolling()
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Stop polling when app goes to background
        PollingManager.shared.stopPolling()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Resume polling when app comes to foreground
        if TokenManager.shared.isAuthenticated {
            PollingManager.shared.startPolling()
        }
    }
}

// ✅ GOOD: Scene-based lifecycle for SwiftUI
@main
struct MoneyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    if authManager.isAuthenticated {
                        PollingManager.shared.startPolling()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    PollingManager.shared.stopPolling()
                }
        }
    }
}
```

## 🧪 Testing API Integration

### Mock Services for Testing

```swift
// ✅ GOOD: Mock service for testing
class MockTransactionService: TransactionServiceProtocol {
    var getTransactionsResult: Result<TransactionListResponse, Error> = .success(TransactionListResponse.sample)
    var getRecentTransactionsResult: Result<RecentTransactionsResponse, Error> = .success(RecentTransactionsResponse.sample)
    
    var getTransactionsCallCount = 0
    var getRecentTransactionsCallCount = 0
    
    func getTransactions(limit: Int, offset: Int, startDate: Date?, endDate: Date?, category: String?) async throws -> TransactionListResponse {
        getTransactionsCallCount += 1
        
        switch getTransactionsResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func getRecentTransactions(since: Date?) async throws -> RecentTransactionsResponse {
        getRecentTransactionsCallCount += 1
        
        switch getRecentTransactionsResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

// Protocol for dependency injection
protocol TransactionServiceProtocol {
    func getTransactions(limit: Int, offset: Int, startDate: Date?, endDate: Date?, category: String?) async throws -> TransactionListResponse
    func getRecentTransactions(since: Date?) async throws -> RecentTransactionsResponse
}

extension TransactionService: TransactionServiceProtocol {}
```

### API Integration Tests

```swift
// ✅ GOOD: API integration test patterns
class TransactionServiceTests: XCTestCase {
    private var service: TransactionService!
    private var mockAPIClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        service = TransactionService(apiClient: mockAPIClient)
    }
    
    func testGetTransactions_Success() async throws {
        // Given
        let expectedResponse = TransactionListResponse.sample
        mockAPIClient.mockResponse = expectedResponse
        
        // When
        let response = try await service.getTransactions()
        
        // Then
        XCTAssertEqual(response.transactions.count, expectedResponse.transactions.count)
        XCTAssertEqual(mockAPIClient.lastRequest?.url?.path, "/api/transactions/")
        XCTAssertEqual(mockAPIClient.lastRequest?.httpMethod, "GET")
    }
    
    func testGetTransactions_WithFilters() async throws {
        // Given
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400)
        let category = "Food and Drink"
        
        // When
        _ = try await service.getTransactions(
            startDate: startDate,
            endDate: endDate,
            category: category
        )
        
        // Then
        let urlComponents = URLComponents(url: mockAPIClient.lastRequest!.url!, resolvingAgainstBaseURL: false)!
        let queryItems = urlComponents.queryItems!
        
        XCTAssertTrue(queryItems.contains { $0.name == "start_date" })
        XCTAssertTrue(queryItems.contains { $0.name == "end_date" })
        XCTAssertTrue(queryItems.contains { $0.name == "category" && $0.value == category })
    }
}
```

## 📋 API Integration Checklist

### Before Submitting Code:

**Service Implementation ✅**
- [ ] Service methods match backend endpoints exactly
- [ ] Proper HTTP methods are used (GET, POST, PUT, DELETE)
- [ ] Request/response models use correct CodingKeys
- [ ] Authentication headers are included when required
- [ ] Error handling maps API errors correctly

**Data Models ✅**
- [ ] All models conform to Codable
- [ ] CodingKeys handle snake_case ↔ camelCase conversion
- [ ] Date handling uses ISO8601 format
- [ ] Optional properties are correctly marked
- [ ] Computed properties provide UI convenience

**Polling Implementation ✅**
- [ ] Polling respects app lifecycle (background/foreground)
- [ ] Polling intervals are reasonable (2-3 minutes)
- [ ] Error handling includes exponential backoff
- [ ] Polling can be started/stopped appropriately
- [ ] New data triggers UI updates via notifications

**Token Management ✅**
- [ ] JWT tokens are stored securely in Keychain
- [ ] Tokens are automatically included in authenticated requests
- [ ] Invalid tokens trigger logout flow
- [ ] Token clearing is complete on logout

**Testing ✅**
- [ ] Mock services are available for all API services
- [ ] Protocol-based dependency injection is implemented
- [ ] API integration tests cover success and error cases
- [ ] Request construction is verified in tests

## 🚀 Quick API Reference

### Common Request Patterns

```swift
// GET with query parameters
let response: TransactionListResponse = try await apiClient.get(
    "/api/transactions/",
    queryParams: ["limit": "50", "category": "Food"]
)

// POST with body
let response: AuthResponse = try await apiClient.post(
    "/api/auth/login",
    body: LoginRequest(email: email, password: password)
)

// POST without body
let response: SuccessResponse = try await apiClient.post("/api/accounts/sync")

// Authenticated request (token added automatically)
let accounts: AccountListResponse = try await apiClient.get("/api/accounts/")
```

### Error Handling Pattern

```swift
do {
    let response = try await service.performAPICall()
    // Handle success
} catch APIError.unauthorized {
    // Handle auth error - redirect to login
} catch APIError.noInternetConnection {
    // Handle network error - show retry option
} catch {
    // Handle unexpected error
}
```

## 📚 Remember

This polling-based approach enables:

- **🚀 Simple Architecture**: No complex caching or state management
- **🔄 Fresh Data**: Always get latest data from backend
- **⚡ Fast Iteration**: Easy to debug and modify
- **📱 Battery Efficient**: Polling only when app is active
- **🛡️ Reliable**: Network errors don't corrupt cached state

**Keep API integration simple and focused on the backend contract.** 🎯