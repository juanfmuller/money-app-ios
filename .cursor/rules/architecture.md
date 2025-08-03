# 🏗️ iOS Architecture Rules

## Core Principles

This iOS app follows a **strict MVVM pattern** with **feature-based organization** that mirrors the backend structure. Every feature is self-contained with clear separation of concerns.

## 📁 Feature-Based Organization

### Required Directory Structure

```
MoneyApp/
├── Features/                    # Business domains (mirrors backend)
│   ├── Auth/                   # Authentication & user management
│   │   ├── Views/              # SwiftUI views only
│   │   │   ├── LoginView.swift
│   │   │   ├── RegisterView.swift
│   │   │   └── ProfileView.swift
│   │   ├── ViewModels/         # @ObservableObject business logic
│   │   │   ├── LoginViewModel.swift
│   │   │   ├── RegisterViewModel.swift
│   │   │   └── ProfileViewModel.swift
│   │   ├── Models/             # Codable data structures
│   │   │   ├── User.swift
│   │   │   ├── LoginRequest.swift
│   │   │   └── AuthResponse.swift
│   │   └── Services/           # API networking
│   │       └── AuthService.swift
│   │
│   ├── Accounts/               # Bank account management & Plaid
│   │   ├── Views/
│   │   │   ├── AccountListView.swift
│   │   │   ├── PlaidLinkView.swift
│   │   │   └── AccountDetailView.swift
│   │   ├── ViewModels/
│   │   │   ├── AccountListViewModel.swift
│   │   │   ├── PlaidLinkViewModel.swift
│   │   │   └── AccountDetailViewModel.swift
│   │   ├── Models/
│   │   │   ├── Account.swift
│   │   │   ├── PlaidItem.swift
│   │   │   └── LinkTokenResponse.swift
│   │   └── Services/
│   │       └── AccountService.swift
│   │
│   ├── Transactions/           # Financial transactions
│   │   ├── Views/
│   │   │   ├── TransactionListView.swift
│   │   │   ├── TransactionDetailView.swift
│   │   │   └── SpendingSummaryView.swift
│   │   ├── ViewModels/
│   │   │   ├── TransactionListViewModel.swift
│   │   │   ├── TransactionDetailViewModel.swift
│   │   │   └── SpendingSummaryViewModel.swift
│   │   ├── Models/
│   │   │   ├── Transaction.swift
│   │   │   ├── SpendingSummary.swift
│   │   │   └── TransactionCategory.swift
│   │   └── Services/
│   │       └── TransactionService.swift
│   │
│   └── Notifications/          # Push notifications
│       ├── Views/
│       │   └── NotificationSettingsView.swift
│       ├── ViewModels/
│       │   └── NotificationSettingsViewModel.swift
│       ├── Models/
│       │   └── NotificationPreferences.swift
│       └── Services/
│           └── NotificationService.swift
│
├── Shared/                     # Cross-feature components
│   ├── Models/                 # Common data structures
│   │   ├── APIResponse.swift
│   │   ├── APIError.swift
│   │   └── PaginationInfo.swift
│   ├── Views/                  # Reusable UI components
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── PullToRefreshView.swift
│   └── Services/               # Shared networking utilities
│       ├── APIClient.swift
│       └── KeychainService.swift
│
├── Core/                       # Infrastructure & configuration
│   ├── Networking/
│   │   ├── NetworkManager.swift
│   │   ├── RequestBuilder.swift
│   │   └── ResponseParser.swift
│   ├── Security/
│   │   ├── TokenManager.swift
│   │   ├── BiometricAuth.swift
│   │   └── SecureStorage.swift
│   └── Configuration/
│       ├── AppConfig.swift
│       ├── Environment.swift
│       └── Constants.swift
│
└── Resources/                  # Assets, strings, etc.
    ├── Assets.xcassets/
    ├── Localizable.strings
    └── Info.plist
```

## 🎭 MVVM Layer Responsibilities

### 1. Views (SwiftUI) - UI Only
**Purpose**: Handle user interface and user interactions only

**✅ DO:**
- Define SwiftUI layout and styling
- Handle user input (buttons, text fields)
- Display data from ViewModels
- Navigate between screens
- Show loading/error states

**❌ DON'T:**
- Make API calls directly
- Contain business logic
- Store application state
- Perform data transformations
- Handle authentication

```swift
// ✅ GOOD: View focuses on UI only
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack {
            TextField("Email", text: $viewModel.email)
            SecureField("Password", text: $viewModel.password)
            
            Button("Login") {
                Task { await viewModel.login() }
            }
            .disabled(viewModel.isLoading)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// ❌ BAD: View contains business logic
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            
            Button("Login") {
                // ❌ DON'T: API call in view
                Task {
                    let request = LoginRequest(email: email, password: password)
                    let response = try await APIClient.shared.post("/auth/login", body: request)
                    // Handle response...
                }
            }
        }
    }
}
```

### 2. ViewModels (@ObservableObject) - Business Logic

**Purpose**: Contain all business logic and coordinate between Views and Services

**✅ DO:**
- Manage @Published properties for UI state
- Coordinate API calls through Services
- Handle error states and messages
- Transform data for UI presentation
- Manage loading states
- Implement business rules

**❌ DON'T:**
- Make direct API calls (use Services instead)
- Contain UI-specific code
- Store credentials or tokens
- Implement networking logic

```swift
// ✅ GOOD: ViewModel handles business logic
@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let authService = AuthService()
    
    func login() async {
        guard isValidInput() else {
            showErrorMessage("Please enter valid email and password")
            return
        }
        
        isLoading = true
        do {
            let request = LoginRequest(email: email, password: password)
            let response = try await authService.login(request)
            handleSuccessfulLogin(response)
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    private func isValidInput() -> Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
```

### 3. Services - API Integration

**Purpose**: Handle all networking and API communication

**✅ DO:**
- Make HTTP requests to backend
- Handle request/response serialization
- Manage authentication headers
- Implement retry logic
- Handle network errors

**❌ DON'T:**
- Contain business logic
- Manage UI state
- Transform data for UI (return raw API responses)
- Store credentials

```swift
// ✅ GOOD: Service handles API communication only
class AuthService {
    private let apiClient = APIClient.shared
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        return try await apiClient.post("/api/auth/login", body: request)
    }
    
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        return try await apiClient.post("/api/auth/register", body: request)
    }
    
    func updateDeviceToken(_ token: String) async throws {
        let request = DeviceTokenRequest(deviceToken: token)
        try await apiClient.post("/api/auth/device-token", body: request)
    }
}
```

### 4. Models (Codable) - Data Contracts

**Purpose**: Define data structures that match backend API schemas

**✅ DO:**
- Mirror backend Pydantic schemas exactly
- Use Codable for JSON serialization
- Include proper property names (snake_case → camelCase)
- Add computed properties for UI convenience

**❌ DON'T:**
- Include business logic
- Store state or behavior
- Contain networking code

```swift
// ✅ GOOD: Model matches backend schema
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
    let isActive: Bool
    let createdAt: Date
    let deviceToken: String?
    
    // Computed properties for UI convenience
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else {
            return email
        }
    }
    
    // CodingKeys to match backend snake_case
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case isActive = "is_active"
        case createdAt = "created_at"
        case deviceToken = "device_token"
    }
}
```

## 🔄 Data Flow Pattern

The data should flow in a unidirectional pattern:

```
User Interaction → View → ViewModel → Service → API
                ↑                              ↓
                └── Update UI ← Transform ← Response
```

1. **User Interaction**: User taps button, enters text, etc.
2. **View**: Calls appropriate ViewModel method
3. **ViewModel**: Validates input, calls Service
4. **Service**: Makes API request
5. **API Response**: Returns data
6. **Service**: Returns raw response to ViewModel
7. **ViewModel**: Transforms data, updates @Published properties
8. **View**: Automatically updates via @StateObject binding

## 🚨 Architecture Violations

### ❌ Common Anti-Patterns

```swift
// ❌ DON'T: View making API calls
struct TransactionListView: View {
    @State private var transactions: [Transaction] = []
    
    var body: some View {
        List(transactions) { transaction in
            TransactionRow(transaction: transaction)
        }
        .onAppear {
            // ❌ BAD: API call in view
            Task {
                transactions = try await APIClient.shared.get("/api/transactions")
            }
        }
    }
}

// ❌ DON'T: Service containing business logic
class TransactionService {
    func getTransactions() async throws -> [Transaction] {
        let transactions = try await apiClient.get("/api/transactions")
        
        // ❌ BAD: Business logic in service
        let filtered = transactions.filter { $0.amount > 100 }
        let sorted = filtered.sorted { $0.date > $1.date }
        
        return sorted
    }
}

// ❌ DON'T: Model with networking
struct Transaction: Codable {
    let id: Int
    let amount: Decimal
    let date: Date
    
    // ❌ BAD: Networking in model
    func sync() async throws {
        try await APIClient.shared.post("/api/transactions/\(id)/sync")
    }
}
```

### ✅ Correct Architecture

```swift
// ✅ GOOD: View delegates to ViewModel
struct TransactionListView: View {
    @StateObject private var viewModel = TransactionListViewModel()
    
    var body: some View {
        List(viewModel.filteredTransactions) { transaction in
            TransactionRow(transaction: transaction)
        }
        .onAppear {
            Task { await viewModel.loadTransactions() }
        }
    }
}

// ✅ GOOD: ViewModel contains business logic
@MainActor
class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var minAmount: Decimal = 0
    
    private let transactionService = TransactionService()
    
    var filteredTransactions: [Transaction] {
        transactions
            .filter { $0.amount > minAmount }
            .sorted { $0.date > $1.date }
    }
    
    func loadTransactions() async {
        do {
            transactions = try await transactionService.getTransactions()
        } catch {
            // Handle error
        }
    }
}

// ✅ GOOD: Service only handles API
class TransactionService {
    private let apiClient = APIClient.shared
    
    func getTransactions() async throws -> [Transaction] {
        return try await apiClient.get("/api/transactions")
    }
}

// ✅ GOOD: Model is pure data
struct Transaction: Codable, Identifiable {
    let id: Int
    let amount: Decimal
    let date: Date
    let merchantName: String
    let category: String
}
```

## 📱 SwiftUI Specific Guidelines

### State Management

```swift
// ✅ GOOD: Proper state object usage
struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()  // Owner
    
    var body: some View {
        if authViewModel.isAuthenticated {
            MainTabView()
                .environmentObject(authViewModel)  // Pass down
        } else {
            LoginView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel  // Receive from parent
    
    var body: some View {
        TabView {
            TransactionListView()
                .tabItem { Label("Transactions", systemImage: "list.bullet") }
        }
    }
}
```

### Navigation Patterns

```swift
// ✅ GOOD: NavigationStack with proper data passing
struct TransactionListView: View {
    @StateObject private var viewModel = TransactionListViewModel()
    
    var body: some View {
        NavigationStack {
            List(viewModel.transactions) { transaction in
                NavigationLink {
                    TransactionDetailView(transaction: transaction)
                } label: {
                    TransactionRow(transaction: transaction)
                }
            }
            .navigationTitle("Transactions")
        }
    }
}
```

## 🔄 Adding New Features

### Step-by-Step Process

1. **Create Feature Directory Structure**
```bash
mkdir -p MoneyApp/Features/NewFeature/{Views,ViewModels,Models,Services}
```

2. **Define Models** (API contracts first)
```swift
// Models/NewFeatureRequest.swift
struct NewFeatureRequest: Codable {
    let parameter: String
}

// Models/NewFeatureResponse.swift
struct NewFeatureResponse: Codable {
    let id: Int
    let result: String
}
```

3. **Create Service** (API integration)
```swift
// Services/NewFeatureService.swift
class NewFeatureService {
    private let apiClient = APIClient.shared
    
    func performAction(_ request: NewFeatureRequest) async throws -> NewFeatureResponse {
        return try await apiClient.post("/api/new-feature", body: request)
    }
}
```

4. **Implement ViewModel** (Business logic)
```swift
// ViewModels/NewFeatureViewModel.swift
@MainActor
class NewFeatureViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var result: String?
    
    private let service = NewFeatureService()
    
    func performAction(parameter: String) async {
        // Business logic implementation
    }
}
```

5. **Create View** (UI)
```swift
// Views/NewFeatureView.swift
struct NewFeatureView: View {
    @StateObject private var viewModel = NewFeatureViewModel()
    
    var body: some View {
        // SwiftUI implementation
    }
}
```

6. **Write Tests** (Test-driven development)
```swift
// Tests/NewFeatureViewModelTests.swift
// Tests/NewFeatureServiceTests.swift
```

## 🎯 Architecture Benefits

This architecture provides:

- **🔧 Maintainability**: Clear separation makes code easy to modify
- **🧪 Testability**: Each layer can be tested independently
- **♻️ Reusability**: Services and models can be shared across features
- **🎪 Consistency**: Standardized patterns across all features
- **🚀 Scalability**: Add new features without affecting existing ones
- **🔄 Backend Alignment**: Structure mirrors backend for easier integration

## 📚 Quick Reference Checklist

Before submitting code, verify:

- [ ] Code is organized by feature, not technical layer
- [ ] Views only contain SwiftUI UI code
- [ ] ViewModels handle all business logic
- [ ] Services only make API calls
- [ ] Models are pure Codable data structures
- [ ] No direct API calls in Views
- [ ] Proper async/await usage
- [ ] @MainActor on ViewModels
- [ ] @StateObject for ViewModel ownership