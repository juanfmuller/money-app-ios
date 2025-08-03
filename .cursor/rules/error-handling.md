# 🚨 iOS Error Handling Rules

## Error Handling Philosophy

This iOS app implements **comprehensive, user-friendly error handling** that provides clear feedback while maintaining security. Every error scenario should be anticipated and handled gracefully.

## 🎯 Error Handling Architecture

### Error Flow Pattern

```
API Error → Service → ViewModel → View → User
    ↓         ↓         ↓         ↓       ↓
Raw Error → Map Error → UI State → Alert → Action
```

## 📋 Error Types Hierarchy

### 1. API Errors (Backend Communication)

```swift
// ✅ GOOD: Structured API error handling
enum APIError: LocalizedError, Equatable {
    case networkError
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingError
    case encodingError
    case invalidURL
    case requestTimeout
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to the server. Please check your internet connection."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested information could not be found."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError:
            return "There was a problem processing the server response."
        case .encodingError:
            return "There was a problem with your request."
        case .invalidURL:
            return "Invalid request. Please try again."
        case .requestTimeout:
            return "The request timed out. Please try again."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .requestTimeout, .noInternetConnection:
            return true
        case .unauthorized, .forbidden, .notFound, .decodingError, .encodingError, .invalidURL:
            return false
        }
    }
    
    var requiresReauth: Bool {
        return self == .unauthorized
    }
}
```

### 2. Business Logic Errors

```swift
// ✅ GOOD: Feature-specific errors
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case accountLocked
    case tooManyAttempts
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters with letters and numbers."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .accountLocked:
            return "Your account has been temporarily locked. Try again in 15 minutes."
        case .tooManyAttempts:
            return "Too many login attempts. Please wait before trying again."
        }
    }
}

enum PlaidError: LocalizedError {
    case linkTokenExpired
    case institutionNotSupported
    case accountLinkingFailed
    case itemUpdateRequired
    
    var errorDescription: String? {
        switch self {
        case .linkTokenExpired:
            return "The bank connection link has expired. Please try again."
        case .institutionNotSupported:
            return "This bank is not currently supported."
        case .accountLinkingFailed:
            return "Unable to connect to your bank. Please try again."
        case .itemUpdateRequired:
            return "Please update your bank connection in settings."
        }
    }
}

enum TransactionError: LocalizedError {
    case noTransactionsFound
    case syncInProgress
    case categoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .noTransactionsFound:
            return "No transactions found for the selected period."
        case .syncInProgress:
            return "Transaction sync in progress. Please wait a moment."
        case .categoryNotFound:
            return "Transaction category not found."
        }
    }
}
```

### 3. Validation Errors

```swift
// ✅ GOOD: Input validation errors
enum ValidationError: LocalizedError {
    case required(field: String)
    case invalidFormat(field: String)
    case tooShort(field: String, minLength: Int)
    case tooLong(field: String, maxLength: Int)
    case mismatch(field1: String, field2: String)
    
    var errorDescription: String? {
        switch self {
        case .required(let field):
            return "\(field) is required."
        case .invalidFormat(let field):
            return "\(field) format is invalid."
        case .tooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters."
        case .tooLong(let field, let maxLength):
            return "\(field) cannot exceed \(maxLength) characters."
        case .mismatch(let field1, let field2):
            return "\(field1) and \(field2) do not match."
        }
    }
}
```

## 🔧 Service Layer Error Mapping

### API Client Error Mapping

```swift
// ✅ GOOD: Centralized error mapping in API client
class APIClient {
    func request<T: Codable>(_ endpoint: String) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: buildRequest(endpoint))
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
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
        } catch let error as DecodingError {
            print("🔴 Decoding error: \(error)")
            throw APIError.decodingError
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
            print("🔴 Unexpected error: \(error)")
            throw APIError.networkError
        }
    }
}
```

### Service-Specific Error Handling

```swift
// ✅ GOOD: Service maps API errors to domain errors
class AuthService {
    private let apiClient = APIClient.shared
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        do {
            return try await apiClient.post("/api/auth/login", body: request)
        } catch APIError.unauthorized {
            throw AuthError.invalidCredentials
        } catch APIError.forbidden {
            throw AuthError.accountLocked
        } catch {
            throw error // Pass through other errors
        }
    }
    
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        do {
            return try await apiClient.post("/api/auth/register", body: request)
        } catch APIError.forbidden {
            // Check if backend returned specific error for existing email
            throw AuthError.emailAlreadyExists
        } catch {
            throw error
        }
    }
}
```

## 🎭 ViewModel Error Handling

### Error State Management

```swift
// ✅ GOOD: Comprehensive ViewModel error handling
@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    
    // Error state
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isRetryable = false
    @Published var requiresReauth = false
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    func login() async {
        // Clear previous errors
        clearError()
        
        // Validate input
        guard validateInput() else { return }
        
        isLoading = true
        
        do {
            let request = LoginRequest(email: email, password: password)
            let response = try await authService.login(request)
            
            // Handle success
            handleSuccessfulLogin(response)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func validateInput() -> Bool {
        if email.isEmpty {
            showErrorMessage("Please enter your email address.")
            return false
        }
        
        if !email.contains("@") || !email.contains(".") {
            showErrorMessage("Please enter a valid email address.")
            return false
        }
        
        if password.isEmpty {
            showErrorMessage("Please enter your password.")
            return false
        }
        
        if password.count < 8 {
            showErrorMessage("Password must be at least 8 characters.")
            return false
        }
        
        return true
    }
    
    private func handleError(_ error: Error) {
        print("🔴 Login error: \(error)")
        
        switch error {
        case let apiError as APIError:
            errorMessage = apiError.localizedDescription
            isRetryable = apiError.isRetryable
            requiresReauth = apiError.requiresReauth
            
        case let authError as AuthError:
            errorMessage = authError.localizedDescription
            isRetryable = false
            
        case let validationError as ValidationError:
            errorMessage = validationError.localizedDescription
            isRetryable = false
            
        default:
            errorMessage = "An unexpected error occurred. Please try again."
            isRetryable = true
        }
        
        showError = true
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        isRetryable = false
    }
    
    private func clearError() {
        showError = false
        errorMessage = ""
        isRetryable = false
        requiresReauth = false
    }
    
    func retryLogin() async {
        await login()
    }
    
    func handleReauth() {
        // Navigate to login or show re-auth flow
        // This would be handled by parent coordinator/view
    }
}
```

### Error Recovery Patterns

```swift
// ✅ GOOD: Automatic retry with exponential backoff
@MainActor
class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let transactionService = TransactionService()
    private var retryCount = 0
    private let maxRetries = 3
    
    func loadTransactions() async {
        await loadTransactionsWithRetry()
    }
    
    private func loadTransactionsWithRetry() async {
        do {
            isLoading = true
            clearError()
            
            transactions = try await transactionService.getTransactions()
            retryCount = 0 // Reset on success
            
        } catch {
            await handleLoadError(error)
        }
        
        isLoading = false
    }
    
    private func handleLoadError(_ error: Error) async {
        if let apiError = error as? APIError, apiError.isRetryable && retryCount < maxRetries {
            retryCount += 1
            let delay = pow(2.0, Double(retryCount)) // Exponential backoff
            
            print("🔄 Retrying transaction load (attempt \(retryCount)) in \(delay) seconds")
            
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await loadTransactionsWithRetry()
        } else {
            // Show error to user
            errorMessage = error.localizedDescription
            showError = true
            retryCount = 0
        }
    }
    
    func manualRetry() async {
        retryCount = 0
        await loadTransactions()
    }
}
```

## 📱 SwiftUI Error Display

### Error Alert Pattern

```swift
// ✅ GOOD: Comprehensive error alert with actions
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack {
            // Login form...
        }
        .alert("Error", isPresented: $viewModel.showError) {
            // Primary action based on error type
            if viewModel.isRetryable {
                Button("Retry") {
                    Task { await viewModel.retryLogin() }
                }
            }
            
            // Secondary actions
            if viewModel.requiresReauth {
                Button("Log In Again") {
                    viewModel.handleReauth()
                }
            }
            
            // Always provide dismiss option
            Button("OK") { }
            
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
```

### Inline Error Display

```swift
// ✅ GOOD: Inline error for form validation
struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                // Show field-specific error
                if let error = viewModel.emailError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .transition(.opacity)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let error = viewModel.passwordError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .transition(.opacity)
                }
            }
            
            // General error banner
            if viewModel.showGeneralError {
                ErrorBannerView(
                    message: viewModel.generalErrorMessage,
                    isRetryable: viewModel.isRetryable
                ) {
                    Task { await viewModel.retry() }
                }
            }
        }
    }
}
```

### Error Banner Component

```swift
// ✅ GOOD: Reusable error banner
struct ErrorBannerView: View {
    let message: String
    let isRetryable: Bool
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isRetryable {
                Button("Retry") {
                    onRetry()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}
```

## 🔒 Security Considerations

### Safe Error Messages

```swift
// ✅ GOOD: Security-safe error messages
enum SecureError: LocalizedError {
    case authenticationFailed
    case operationFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            // Don't reveal whether email exists or password is wrong
            return "Invalid email or password."
        case .operationFailed:
            // Don't reveal internal system details
            return "Operation failed. Please try again."
        }
    }
}

// ❌ BAD: Security-revealing error messages
enum UnsafeError: LocalizedError {
    case userNotFound
    case incorrectPassword
    case databaseConnectionFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "No user found with email john@example.com" // ❌ Reveals user existence
        case .incorrectPassword:
            return "Password is incorrect for john@example.com" // ❌ Confirms email exists
        case .databaseConnectionFailed:
            return "Database server at 192.168.1.100 is unreachable" // ❌ Reveals infrastructure
        }
    }
}
```

### Secure Logging

```swift
// ✅ GOOD: Secure error logging
private func logError(_ error: Error, context: String) {
    // Only log error types and general info, never sensitive data
    let errorInfo = [
        "context": context,
        "error_type": String(describing: type(of: error)),
        "timestamp": ISO8601DateFormatter().string(from: Date())
    ]
    
    print("🔴 Error: \(errorInfo)")
    
    // Don't log:
    // - User passwords
    // - API tokens
    // - Personal information
    // - Full error details in production
}

// ❌ BAD: Insecure logging
private func logErrorUnsafely(_ error: Error, email: String, token: String) {
    print("🔴 Login failed for \(email) with token \(token): \(error)") // ❌ Logs sensitive data
}
```

## 📊 Error Analytics & Monitoring

### Error Tracking

```swift
// ✅ GOOD: Error tracking for improvement
class ErrorTracker {
    static let shared = ErrorTracker()
    
    func trackError(_ error: Error, context: String) {
        let errorData = ErrorData(
            type: String(describing: type(of: error)),
            context: context,
            timestamp: Date(),
            userID: getCurrentUserID(), // Anonymized ID only
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        )
        
        // Send to analytics service (without sensitive data)
        // This helps identify common error patterns
        sendToAnalytics(errorData)
    }
    
    private func getCurrentUserID() -> String? {
        // Return anonymized user ID only, never actual user data
        return KeychainService.shared.getUserID()?.hashed
    }
}

struct ErrorData: Codable {
    let type: String
    let context: String
    let timestamp: Date
    let userID: String?
    let appVersion: String?
}
```

## 🧪 Testing Error Scenarios

### Error Testing Patterns

```swift
// ✅ GOOD: Comprehensive error testing
class LoginViewModelTests: XCTestCase {
    private var viewModel: LoginViewModel!
    private var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = LoginViewModel(authService: mockAuthService)
    }
    
    func testLogin_NetworkError_ShowsRetryableError() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthService.loginResult = .failure(APIError.networkError)
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertTrue(viewModel.isRetryable)
        XCTAssertEqual(viewModel.errorMessage, "Unable to connect to the server. Please check your internet connection.")
    }
    
    func testLogin_UnauthorizedError_ShowsAuthError() async {
        // Given
        viewModel.email = "wrong@example.com"
        viewModel.password = "wrongpassword"
        mockAuthService.loginResult = .failure(APIError.unauthorized)
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isRetryable)
        XCTAssertEqual(viewModel.errorMessage, "Your session has expired. Please log in again.")
    }
    
    func testLogin_ValidationError_ShowsValidationMessage() async {
        // Given
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isRetryable)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address.")
        XCTAssertEqual(mockAuthService.loginCallCount, 0) // Service not called for validation errors
    }
}
```

## 📋 Error Handling Checklist

### Before Submitting Code:

**Error Types ✅**
- [ ] All error types conform to LocalizedError
- [ ] Error messages are user-friendly
- [ ] Security-sensitive errors don't reveal system details
- [ ] Retryable errors are properly marked

**ViewModel Error Handling ✅**
- [ ] All async operations have error handling
- [ ] Error state is properly published
- [ ] Validation errors are handled immediately
- [ ] Loading states are managed correctly

**View Error Display ✅**
- [ ] Errors are displayed to users appropriately
- [ ] Retry actions are provided when applicable
- [ ] Error messages are accessible
- [ ] Error states don't break the UI

**Testing ✅**
- [ ] Error scenarios are tested
- [ ] Both recoverable and non-recoverable errors are covered
- [ ] Error message content is verified
- [ ] Error state management is tested

**Security ✅**
- [ ] No sensitive data in error messages
- [ ] Error logs don't contain credentials
- [ ] User enumeration is prevented
- [ ] System details are not exposed

## 🚀 Quick Reference

### Common Error Patterns

```swift
// API Call with Error Handling
do {
    let result = try await apiService.fetchData()
    // Handle success
} catch let apiError as APIError {
    handleAPIError(apiError)
} catch {
    handleUnexpectedError(error)
}

// Input Validation
guard !email.isEmpty else {
    showError("Email is required")
    return
}

// Error State Update
private func showError(_ message: String, isRetryable: Bool = false) {
    errorMessage = message
    self.isRetryable = isRetryable
    showError = true
}
```

Remember: **Good error handling is invisible to users when things work, but essential when they don't.** 🛡️