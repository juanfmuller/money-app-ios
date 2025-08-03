# 🔐 iOS Security Rules

## Security Philosophy

This iOS app implements **comprehensive security practices** to protect user financial data, authentication credentials, and personal information. Security is integrated at every layer of the architecture.

## 🛡️ Authentication & Authorization

### JWT Token Security

```swift
// ✅ GOOD: Secure token storage with Keychain
class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.moneyapp.keychain"
    
    func save(_ data: String, for key: String) {
        let data = Data(data.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("🔴 Keychain save failed: \(status)")
        }
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        
        return nil
    }
    
    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("🔴 Keychain delete failed: \(status)")
        }
    }
}

// ✅ GOOD: Secure token management
class TokenManager {
    static let shared = TokenManager()
    
    private let keychainService = KeychainService.shared
    private let accessTokenKey = "jwt_access_token"
    private let refreshTokenKey = "jwt_refresh_token"
    
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
    
    func clearAllTokens() {
        keychainService.delete(accessTokenKey)
        keychainService.delete(refreshTokenKey)
        
        // Also clear any other sensitive data
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "last_login")
    }
    
    var isAuthenticated: Bool {
        return getAccessToken() != nil
    }
}
```

### Biometric Authentication

```swift
// ✅ GOOD: Biometric authentication for app access
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private let context = LAContext()
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
    }
    
    var biometricType: BiometricType {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    var isBiometricAvailable: Bool {
        return biometricType != .none
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }
        
        let reason = "Authenticate to access your financial data"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw BiometricError.authenticationFailed
        }
    }
    
    func authenticateWithPasscode() async throws -> Bool {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw BiometricError.notAvailable
        }
        
        let reason = "Enter your device passcode to access the app"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            throw BiometricError.authenticationFailed
        }
    }
}

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        }
    }
}
```

## 🔒 Network Security

### Certificate Pinning

```swift
// ✅ GOOD: Certificate pinning for API security
class CertificatePinner: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [SecCertificate]
    
    init(certificateNames: [String]) {
        var certificates: [SecCertificate] = []
        
        for certificateName in certificateNames {
            if let certPath = Bundle.main.path(forResource: certificateName, ofType: "cer"),
               let certData = NSData(contentsOfFile: certPath),
               let certificate = SecCertificateCreateWithData(nil, certData) {
                certificates.append(certificate)
            }
        }
        
        self.pinnedCertificates = certificates
        super.init()
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Get server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get server certificate
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get server certificate data
        let serverCertData = SecCertificateCopyData(serverCertificate)
        
        // Check against pinned certificates
        for pinnedCertificate in pinnedCertificates {
            let pinnedCertData = SecCertificateCopyData(pinnedCertificate)
            
            if CFEqual(serverCertData, pinnedCertData) {
                // Certificate matches - allow connection
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        // No match found - reject connection
        print("🔴 Certificate pinning failed - rejecting connection")
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
```

### Secure API Client

```swift
// ✅ GOOD: Security-enhanced API client
class SecureAPIClient {
    static let shared = SecureAPIClient()
    
    private let session: URLSession
    private let certificatePinner: CertificatePinner
    
    init() {
        // Initialize certificate pinning
        self.certificatePinner = CertificatePinner(certificateNames: ["api.moneyapp.com"])
        
        // Configure secure session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.urlCache = nil // Disable caching for security
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        self.session = URLSession(
            configuration: configuration,
            delegate: certificatePinner,
            delegateQueue: nil
        )
    }
    
    func performSecureRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        // Verify request is going to expected domain
        guard let url = request.url,
              let host = url.host,
              AppConfig.allowedHosts.contains(host) else {
            throw SecurityError.untrustedDomain
        }
        
        // Ensure HTTPS
        guard url.scheme == "https" else {
            throw SecurityError.insecureConnection
        }
        
        // Add security headers
        var secureRequest = request
        secureRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        secureRequest.setValue("no-store", forHTTPHeaderField: "Pragma")
        
        do {
            let (data, response) = try await session.data(for: secureRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SecurityError.invalidResponse
            }
            
            // Verify security headers in response
            try validateSecurityHeaders(httpResponse)
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
                // Clear tokens on auth failure
                TokenManager.shared.clearAllTokens()
                throw APIError.unauthorized
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
            
        } catch {
            print("🔴 Secure request failed: \(error)")
            throw error
        }
    }
    
    private func validateSecurityHeaders(_ response: HTTPURLResponse) throws {
        // Check for security headers
        let headers = response.allHeaderFields
        
        // Verify HSTS header
        if headers["Strict-Transport-Security"] == nil {
            print("⚠️ Missing HSTS header")
        }
        
        // Verify Content-Type header
        if let contentType = headers["Content-Type"] as? String,
           !contentType.contains("application/json") {
            throw SecurityError.unexpectedContentType
        }
    }
}

enum SecurityError: LocalizedError {
    case untrustedDomain
    case insecureConnection
    case invalidResponse
    case unexpectedContentType
    
    var errorDescription: String? {
        switch self {
        case .untrustedDomain:
            return "Request to untrusted domain blocked."
        case .insecureConnection:
            return "Insecure connection blocked."
        case .invalidResponse:
            return "Invalid server response."
        case .unexpectedContentType:
            return "Unexpected response format."
        }
    }
}
```

## 📱 App Security Configuration

### App Transport Security (ATS)

```xml
<!-- ✅ GOOD: Secure ATS configuration in Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.moneyapp.com</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### App Configuration Security

```swift
// ✅ GOOD: Secure app configuration
class AppConfig {
    static let shared = AppConfig()
    
    // API Configuration
    static let apiBaseURL: String = {
        #if DEBUG
        return "https://api-dev.moneyapp.com"
        #else
        return "https://api.moneyapp.com"
        #endif
    }()
    
    static let allowedHosts = [
        "api.moneyapp.com",
        "api-dev.moneyapp.com"
    ]
    
    // Security Configuration
    static let maxLoginAttempts = 5
    static let loginTimeoutMinutes = 15
    static let sessionTimeoutMinutes = 60
    
    // Feature Flags (for security-sensitive features)
    static let biometricAuthEnabled = true
    static let certificatePinningEnabled = true
    static let debugLoggingEnabled = false
    
    private init() {}
}

// ❌ BAD: Never hardcode secrets in code
class BadConfig {
    static let apiKey = "sk_live_abc123..." // ❌ NEVER DO THIS
    static let secretKey = "secret123"      // ❌ NEVER DO THIS
}
```

## 🔍 Input Validation & Sanitization

### Secure Input Handling

```swift
// ✅ GOOD: Comprehensive input validation
class InputValidator {
    static func validateEmail(_ email: String) throws {
        // Basic format check
        guard !email.isEmpty else {
            throw ValidationError.required(field: "Email")
        }
        
        // Length check
        guard email.count <= 254 else {
            throw ValidationError.tooLong(field: "Email", maxLength: 254)
        }
        
        // Format validation
        let emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidFormat(field: "Email")
        }
    }
    
    static func validatePassword(_ password: String) throws {
        // Basic checks
        guard !password.isEmpty else {
            throw ValidationError.required(field: "Password")
        }
        
        guard password.count >= 8 else {
            throw ValidationError.tooShort(field: "Password", minLength: 8)
        }
        
        guard password.count <= 128 else {
            throw ValidationError.tooLong(field: "Password", maxLength: 128)
        }
        
        // Complexity checks
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasLetter && hasNumber else {
            throw ValidationError.invalidFormat(field: "Password must contain both letters and numbers")
        }
    }
    
    static func sanitizeSearchTerm(_ term: String) -> String {
        // Remove potentially dangerous characters
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        let filtered = term.unicodeScalars.filter { allowedCharacters.contains($0) }
        
        let sanitized = String(String.UnicodeScalarView(filtered))
        
        // Limit length
        return String(sanitized.prefix(100))
    }
    
    static func validateAmount(_ amount: String) throws -> Decimal {
        guard !amount.isEmpty else {
            throw ValidationError.required(field: "Amount")
        }
        
        guard let decimal = Decimal(string: amount) else {
            throw ValidationError.invalidFormat(field: "Amount must be a valid number")
        }
        
        guard decimal >= 0 else {
            throw ValidationError.invalidFormat(field: "Amount must be positive")
        }
        
        guard decimal <= 999999.99 else {
            throw ValidationError.invalidFormat(field: "Amount too large")
        }
        
        return decimal
    }
}
```

## 📊 Secure Data Handling

### Memory Security

```swift
// ✅ GOOD: Secure string handling for sensitive data
class SecureString {
    private var data: Data
    
    init(_ string: String) {
        self.data = Data(string.utf8)
    }
    
    func withUnsafeString<T>(_ body: (String) throws -> T) rethrows -> T {
        return try data.withUnsafeBytes { bytes in
            let string = String(decoding: bytes, as: UTF8.self)
            defer {
                // Zero out the string memory (best effort)
                string.withCString { ptr in
                    memset(UnsafeMutableRawPointer(mutating: ptr), 0, string.utf8.count)
                }
            }
            return try body(string)
        }
    }
    
    deinit {
        // Zero out data on deallocation
        data.withUnsafeMutableBytes { bytes in
            memset(bytes.baseAddress, 0, bytes.count)
        }
    }
}

// ✅ GOOD: Secure password handling
class SecurePasswordField: ObservableObject {
    private var securePassword: SecureString?
    
    @Published var maskedPassword: String = ""
    
    func setPassword(_ password: String) {
        securePassword = SecureString(password)
        maskedPassword = String(repeating: "•", count: password.count)
    }
    
    func withPassword<T>(_ body: (String) throws -> T) rethrows -> T? {
        return try securePassword?.withUnsafeString(body)
    }
    
    func clearPassword() {
        securePassword = nil
        maskedPassword = ""
    }
}
```

### Secure Local Storage

```swift
// ✅ GOOD: Secure UserDefaults wrapper
class SecureUserDefaults {
    static let shared = SecureUserDefaults()
    
    private let userDefaults = UserDefaults.standard
    private let encryptionKey: Data
    
    init() {
        // Generate or retrieve encryption key from Keychain
        if let existingKey = KeychainService.shared.get("userdefaults_encryption_key") {
            self.encryptionKey = Data(existingKey.utf8)
        } else {
            // Generate new key
            var key = Data(count: 32)
            let result = key.withUnsafeMutableBytes { bytes in
                SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
            }
            
            guard result == errSecSuccess else {
                fatalError("Failed to generate encryption key")
            }
            
            self.encryptionKey = key
            KeychainService.shared.save(key.base64EncodedString(), for: "userdefaults_encryption_key")
        }
    }
    
    func setSecure(_ value: String, forKey key: String) {
        guard let encryptedData = encrypt(value.data(using: .utf8)!) else {
            print("🔴 Failed to encrypt data for key: \(key)")
            return
        }
        
        userDefaults.set(encryptedData.base64EncodedString(), forKey: "secure_\(key)")
    }
    
    func getSecure(forKey key: String) -> String? {
        guard let encryptedString = userDefaults.string(forKey: "secure_\(key)"),
              let encryptedData = Data(base64Encoded: encryptedString),
              let decryptedData = decrypt(encryptedData) else {
            return nil
        }
        
        return String(data: decryptedData, encoding: .utf8)
    }
    
    func removeSecure(forKey key: String) {
        userDefaults.removeObject(forKey: "secure_\(key)")
    }
    
    private func encrypt(_ data: Data) -> Data? {
        // Simple AES encryption (implement proper encryption)
        // This is a simplified example - use CryptoKit for production
        return data // Placeholder
    }
    
    private func decrypt(_ data: Data) -> Data? {
        // Simple AES decryption (implement proper decryption)
        // This is a simplified example - use CryptoKit for production
        return data // Placeholder
    }
}
```

## 🔒 Device Security Integration

### Jailbreak Detection

```swift
// ✅ GOOD: Basic jailbreak detection
class DeviceSecurityChecker {
    static let shared = DeviceSecurityChecker()
    
    private let jailbreakPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/"
    ]
    
    var isJailbroken: Bool {
        return checkJailbreakFiles() || checkJailbreakFileAccess() || checkSuspiciousApps()
    }
    
    private func checkJailbreakFiles() -> Bool {
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private func checkJailbreakFileAccess() -> Bool {
        // Try to write to system directory
        let testString = "test"
        do {
            try testString.write(toFile: "/private/test.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/test.txt")
            return true // Should not be able to write here on non-jailbroken device
        } catch {
            return false // Expected on non-jailbroken device
        }
    }
    
    private func checkSuspiciousApps() -> Bool {
        // Check if suspicious apps can be opened
        let suspiciousURLs = [
            "cydia://package/com.example.package",
            "sileo://package/com.example.package"
        ]
        
        for urlString in suspiciousURLs {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    func performSecurityCheck() throws {
        if isJailbroken {
            throw SecurityError.jailbrokenDevice
        }
        
        // Additional security checks could go here
    }
}

extension SecurityError {
    static let jailbrokenDevice = SecurityError.deviceCompromised
    
    case deviceCompromised
    
    var errorDescription: String? {
        switch self {
        case .deviceCompromised:
            return "This app cannot run on compromised devices for security reasons."
        default:
            return "Security check failed."
        }
    }
}
```

## 🧪 Security Testing

### Security Test Patterns

```swift
// ✅ GOOD: Security-focused tests
class SecurityTests: XCTestCase {
    
    func testKeychainService_SecureStorage() {
        let keychain = KeychainService.shared
        let testKey = "test_token"
        let testValue = "sensitive_data_123"
        
        // Save data
        keychain.save(testValue, for: testKey)
        
        // Verify data can be retrieved
        let retrievedValue = keychain.get(testKey)
        XCTAssertEqual(retrievedValue, testValue)
        
        // Delete data
        keychain.delete(testKey)
        
        // Verify data is gone
        let deletedValue = keychain.get(testKey)
        XCTAssertNil(deletedValue)
    }
    
    func testInputValidator_EmailValidation() {
        // Valid emails
        XCTAssertNoThrow(try InputValidator.validateEmail("test@example.com"))
        XCTAssertNoThrow(try InputValidator.validateEmail("user.name+tag@domain.co.uk"))
        
        // Invalid emails
        XCTAssertThrowsError(try InputValidator.validateEmail(""))
        XCTAssertThrowsError(try InputValidator.validateEmail("invalid-email"))
        XCTAssertThrowsError(try InputValidator.validateEmail("@example.com"))
        XCTAssertThrowsError(try InputValidator.validateEmail("test@"))
        
        // SQL injection attempt
        XCTAssertThrowsError(try InputValidator.validateEmail("test'; DROP TABLE users; --"))
    }
    
    func testInputValidator_PasswordValidation() {
        // Valid passwords
        XCTAssertNoThrow(try InputValidator.validatePassword("password123"))
        XCTAssertNoThrow(try InputValidator.validatePassword("MySecure123"))
        
        // Invalid passwords
        XCTAssertThrowsError(try InputValidator.validatePassword(""))
        XCTAssertThrowsError(try InputValidator.validatePassword("short"))
        XCTAssertThrowsError(try InputValidator.validatePassword("onlyletters"))
        XCTAssertThrowsError(try InputValidator.validatePassword("123456789"))
    }
    
    func testTokenManager_TokenClearing() {
        let tokenManager = TokenManager.shared
        
        // Set tokens
        tokenManager.saveTokens(accessToken: "access123", refreshToken: "refresh456")
        XCTAssertTrue(tokenManager.isAuthenticated)
        
        // Clear tokens
        tokenManager.clearAllTokens()
        XCTAssertFalse(tokenManager.isAuthenticated)
        XCTAssertNil(tokenManager.getAccessToken())
        XCTAssertNil(tokenManager.getRefreshToken())
    }
    
    func testAPIClient_HTTPSEnforcement() async {
        let apiClient = SecureAPIClient.shared
        
        // HTTPS request should work (mocked)
        // HTTP request should fail
        do {
            var request = URLRequest(url: URL(string: "http://api.example.com/test")!)
            request.httpMethod = "GET"
            
            let _: TestResponse = try await apiClient.performSecureRequest(request)
            XCTFail("HTTP request should have been blocked")
        } catch SecurityError.insecureConnection {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}

struct TestResponse: Codable {
    let message: String
}
```

## 📋 Security Checklist

### Before Submitting Code:

**Authentication ✅**
- [ ] JWT tokens stored in Keychain (not UserDefaults)
- [ ] Tokens cleared on logout/auth failure
- [ ] Biometric authentication implemented where appropriate
- [ ] Session timeout implemented

**Network Security ✅**
- [ ] All requests use HTTPS
- [ ] Certificate pinning implemented for API
- [ ] Request/response validation implemented
- [ ] No sensitive data in URLs or logs

**Input Validation ✅**
- [ ] All user inputs validated and sanitized
- [ ] Email format validation implemented
- [ ] Password complexity requirements enforced
- [ ] Amount/numeric input bounds checking

**Data Protection ✅**
- [ ] Sensitive data not stored in UserDefaults
- [ ] Keychain used for credentials
- [ ] Data encrypted where appropriate
- [ ] Memory cleared after use for sensitive data

**App Security ✅**
- [ ] App Transport Security configured
- [ ] Debug logging disabled in production
- [ ] Jailbreak detection implemented
- [ ] Screen recording/screenshot protection considered

**Code Security ✅**
- [ ] No hardcoded secrets or API keys
- [ ] No sensitive data in logs
- [ ] Error messages don't reveal system internals
- [ ] Security headers validated

## 🚀 Security Quick Reference

### Common Security Patterns

```swift
// Secure token storage
TokenManager.shared.saveTokens(accessToken: token, refreshToken: nil)

// Input validation
try InputValidator.validateEmail(email)
try InputValidator.validatePassword(password)

// Secure API request
let response: UserResponse = try await SecureAPIClient.shared.performSecureRequest(request)

// Biometric authentication
let authenticated = try await BiometricAuthManager.shared.authenticateWithBiometrics()

// Clear sensitive data
TokenManager.shared.clearAllTokens()
```

### Security Configuration

```swift
// App configuration
#if DEBUG
let debugMode = true
#else
let debugMode = false
#endif

// Security settings
let maxLoginAttempts = 5
let sessionTimeoutMinutes = 60
let biometricAuthEnabled = true
```

## 📚 Remember

Security is not optional for financial apps:

- **🔐 Defense in Depth**: Multiple layers of security
- **🛡️ Secure by Default**: Security integrated from the start
- **🔍 Validate Everything**: Never trust user input
- **🚫 Fail Securely**: Errors should not reveal sensitive information
- **📱 Device Integration**: Use platform security features
- **🧪 Test Security**: Include security testing in your workflow

**Every line of code is a potential security vulnerability. Code defensively.** 🛡️