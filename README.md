# Money App iOS

A modern iOS expense tracking app built with SwiftUI that connects to a FastAPI backend for comprehensive financial management and bank account integration via Plaid.

## 📱 Project Overview

Money App iOS is the mobile client for a personal finance management system. Users can link their bank accounts, automatically sync transactions, categorize spending, and receive intelligent push notifications about their financial activity.

### Key Features

- 🔐 **Secure Authentication**: JWT-based login with biometric authentication support
- 🏦 **Bank Account Integration**: Link accounts via Plaid for automatic transaction import
- 💳 **Transaction Management**: View, categorize, and analyze spending patterns
- 📊 **Spending Analytics**: Daily summaries and category-based spending insights
- 📱 **Smart Notifications**: Push alerts for new transactions and spending patterns
- 🔄 **Real-time Sync**: Polling-based updates for fresh financial data

## 🏗️ Architecture

### MVVM + SwiftUI
- **Views**: SwiftUI components focused purely on UI presentation
- **ViewModels**: `@ObservableObject` classes containing business logic and state management
- **Models**: `Codable` data structures matching backend API schemas
- **Services**: API communication and networking layer

### Feature-Based Organization
```
MoneyApp/
├── Features/                   # Business domain organization
│   ├── Auth/                  # Authentication & user management
│   ├── Accounts/              # Bank account management & Plaid
│   ├── Transactions/          # Financial transaction handling
│   └── Notifications/         # Push notification management
├── Shared/                    # Cross-feature components
├── Core/                      # Infrastructure & configuration
└── Resources/                 # Assets, strings, etc.
```

### Data Strategy
- **No Caching**: Fresh data fetched on demand for simplicity
- **Polling-Based**: Background polling for transaction updates when app is active
- **Secure Storage**: JWT tokens and sensitive data stored in iOS Keychain

## 🔗 Backend Integration

This iOS app connects to the [Money App Backend](../money-app-backend/) FastAPI server.

### API Endpoints Used
```swift
// Authentication
POST /api/auth/register        // User registration
POST /api/auth/login          // User login with JWT
POST /api/auth/device-token   // Update push notification token

// Account Management
POST /api/accounts/link/token     // Create Plaid Link token
POST /api/accounts/link/exchange  // Link bank account
GET  /api/accounts/              // Get linked accounts
GET  /api/accounts/sync/status   // Check sync status (polling)

// Transactions
GET /api/transactions/recent     // Get recent transactions (polling)
GET /api/transactions/          // Get filtered transactions
GET /api/transactions/summary   // Get spending analytics
```

### Data Flow
1. **Authentication**: User logs in → JWT stored securely in Keychain
2. **Account Linking**: Plaid Link SDK → Public token → Backend exchange
3. **Transaction Sync**: Background polling → Fresh transaction data
4. **Push Notifications**: Backend sends alerts → iOS handles display

## 🛠️ Technology Stack

### Core Technologies
- **SwiftUI**: Declarative UI framework
- **Swift Concurrency**: Modern async/await patterns
- **Combine**: Reactive programming for data binding
- **Foundation**: Core iOS networking and data handling

### Key Dependencies
- **iOS 17.0+**: Minimum deployment target
- **Xcode 16.4+**: Development environment
- **Swift 6+**: Language version

### Security & Authentication
- **Keychain Services**: Secure JWT token storage
- **Local Authentication**: Biometric authentication (Face ID/Touch ID)
- **Certificate Pinning**: API security validation
- **App Transport Security**: HTTPS enforcement

## 🚀 Getting Started

### Prerequisites
1. **Xcode 16.4+** installed on macOS
2. **iOS Simulator** or physical iOS device
3. **Backend Running**: [Money App Backend](../money-app-backend/) must be running locally or deployed

### Setup Instructions

1. **Clone and Open Project**
   ```bash
   cd money-app-ios
   open MoneyApp.xcodeproj
   ```

2. **Configure Backend URL**
   ```swift
   // Update in Core/Configuration/AppConfig.swift
   static let apiBaseURL = "https://your-backend-url.com"
   // or for local development:
   static let apiBaseURL = "http://localhost:8000"
   ```

3. **Build and Run**
   ```bash
   # In Xcode:
   Cmd+B  # Build project
   Cmd+R  # Run on simulator/device
   ```

### Development Workflow
```bash
# Essential commands after every Swift file change:
Cmd+B  # Build (must succeed)
Cmd+U  # Run tests (must pass)
```

See [Development Workflow Rules](.cursor/rules/development-workflow.md) for detailed guidelines.

## 📋 Project Structure

### Feature Modules
- **Auth**: Login, registration, user profile management
- **Accounts**: Plaid integration, account linking, account list
- **Transactions**: Transaction list, filtering, spending summaries
- **Notifications**: Push notification settings and handling

### Shared Components
- **Models**: Common data structures (`User`, `Account`, `Transaction`)
- **Views**: Reusable UI components (`LoadingView`, `ErrorView`)
- **Services**: Networking utilities (`APIClient`, `KeychainService`)

### Core Infrastructure
- **Networking**: Base API client with JWT authentication
- **Security**: Token management, biometric auth, certificate pinning
- **Configuration**: Environment settings, feature flags

## 🧪 Testing Strategy

### Test Types
- **Unit Tests**: ViewModels, Services, and business logic
- **UI Tests**: Critical user flows and navigation
- **Integration Tests**: API communication with mock backend

### Test Organization
```
MoneyAppTests/
├── Features/           # Feature-specific tests
│   ├── Auth/
│   ├── Accounts/
│   └── Transactions/
├── Shared/            # Shared component tests
└── TestHelpers/       # Mock services and test utilities
```

### Running Tests
```bash
# In Xcode:
Cmd+U                 # Run all tests
Cmd+6                 # Open test navigator
```

## 🔒 Security Considerations

### Data Protection
- **JWT Tokens**: Stored securely in iOS Keychain
- **Biometric Auth**: Face ID/Touch ID for app access
- **Certificate Pinning**: Validates backend API certificates
- **Input Validation**: All user inputs validated and sanitized

### Financial Data Security
- **No Local Storage**: Sensitive data not cached locally
- **HTTPS Only**: All API communication over TLS
- **Token Expiration**: JWT tokens automatically managed
- **Device Security**: Jailbreak detection and security checks

## 📱 Platform Features

### iOS Integration
- **Push Notifications**: APNs integration for transaction alerts
- **Keychain**: Secure credential storage
- **Biometric Authentication**: Face ID and Touch ID support
- **Background App Refresh**: Polling when app becomes active

### Accessibility
- **VoiceOver**: Full screen reader support
- **Dynamic Type**: Supports system font scaling
- **High Contrast**: Respects accessibility display settings
- **Keyboard Navigation**: Full keyboard accessibility

## 🔄 Data Synchronization

### Polling Strategy
- **Active Polling**: Every 2-3 minutes when app is in foreground
- **Background Pause**: Polling stops when app goes to background
- **Fresh Data**: No local caching, always fetch from backend
- **Error Handling**: Exponential backoff on network errors

### Sync Flow
1. App becomes active → Start polling timer
2. Poll `/api/accounts/sync/status` → Check if sync recommended
3. If needed → Call `/api/accounts/sync` → Trigger backend sync
4. Poll `/api/transactions/recent` → Get new transactions
5. Update UI → Notify user of new data

## 📚 Development Resources

### Documentation
- [Architecture Rules](.cursor/rules/architecture.md) - MVVM patterns and organization
- [Testing Guidelines](.cursor/rules/testing.md) - Testing strategies and patterns
- [API Integration](.cursor/rules/api-integration.md) - Backend communication patterns
- [Security Rules](.cursor/rules/security.md) - Security implementation guidelines
- [Error Handling](.cursor/rules/error-handling.md) - Error management patterns

### Code Style
- **SwiftUI Conventions**: Declarative view patterns
- **Async/Await**: Modern concurrency patterns
- **MVVM Separation**: Clear layer responsibilities
- **Feature Organization**: Domain-driven structure

## 🚀 Deployment

### App Store Preparation
1. **Code Signing**: Configure development/distribution certificates
2. **Provisioning**: Set up App Store provisioning profiles
3. **Build Configuration**: Release build settings
4. **Testing**: TestFlight distribution for beta testing

### Environment Configuration
- **Development**: Local backend connection
- **Staging**: Staging backend for testing
- **Production**: Production backend for App Store

## 🔗 Related Projects

- **[Money App Backend](../money-app-backend/)**: FastAPI backend with Plaid integration
- **Backend API Documentation**: Available at `/docs` when backend is running

## 📞 Support & Development

### Architecture Decisions
This iOS app implements a **polling-based architecture** for simplicity:
- ✅ No complex caching or state management
- ✅ Always fresh data from backend
- ✅ Easy to debug and maintain
- ✅ Fast development iteration

### Contributing
1. Follow [Development Workflow](.cursor/rules/development-workflow.md)
2. Ensure all tests pass before committing
3. Maintain MVVM architecture patterns
4. Update documentation for new features

## 📄 License

This project is part of the Money App financial management system.

---

**Built with ❤️ using SwiftUI and modern iOS development practices**