//
//  OnboardingService.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation

// MARK: - Protocol Definition

protocol OnboardingServiceProtocol: Sendable {
    func login(_ request: LoginRequest) async throws -> AuthResponse
    func register(_ request: RegisterRequest) async throws -> AuthResponse
    func updateDeviceToken(_ token: String) async throws -> SuccessResponse
    func completeOnboarding(_ completion: OnboardingCompletion) async throws -> SuccessResponse
    func logout() async throws -> SuccessResponse
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse
}

// MARK: - OnboardingService Actor

actor OnboardingService: OnboardingServiceProtocol {
    
    // MARK: - Dependencies
    
    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManagerProtocol
    
    // MARK: - Initialization
    
    init(apiClient: APIClientProtocol = APIClient.shared,
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }
    
    // MARK: - Authentication Methods
    
    func login(_ request: LoginRequest) async throws -> AuthResponse {
        do {
            let response: AuthResponse = try await apiClient.post("/api/auth/login", body: request)
            
            // Store JWT tokens securely
            await tokenManager.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            
            return response
            
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        do {
            let response: AuthResponse = try await apiClient.post("/api/auth/register", body: request)
            
            // Store JWT tokens securely for new user
            await tokenManager.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            
            return response
            
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await apiClient.post("/api/auth/refresh", body: request)
            
            // Update stored tokens
            await tokenManager.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            
            return response
            
        } catch {
            // Clear tokens on refresh failure
            await tokenManager.clearTokens()
            throw mapAuthError(error)
        }
    }
    
    func logout() async throws -> SuccessResponse {
        do {
            // Notify backend of logout (optional)
            let response: SuccessResponse = try await apiClient.post("/api/auth/logout")
            
            // Clear local tokens
            await tokenManager.clearTokens()
            
            return response
            
        } catch {
            // Always clear tokens even if backend call fails
            await tokenManager.clearTokens()
            throw error
        }
    }
    
    // MARK: - Device & Onboarding Methods
    
    func updateDeviceToken(_ token: String) async throws -> SuccessResponse {
        let request = DeviceTokenRequest(deviceToken: token)
        return try await apiClient.post("/api/auth/device-token", body: request)
    }
    
    func completeOnboarding(_ completion: OnboardingCompletion) async throws -> SuccessResponse {
        return try await apiClient.post("/api/user/onboarding/complete", body: completion)
    }
    
    // MARK: - Private Helper Methods
    
    private func mapAuthError(_ error: Error) -> Error {
        if let apiError = error as? OnboardingAPIError {
            switch apiError {
            case .unauthorized:
                return AuthError.invalidCredentials
            case .forbidden:
                return AuthError.accountLocked
            case .networkError, .requestTimeout, .noInternetConnection:
                return apiError // Pass through network errors
            default:
                return AuthError.registrationFailed
            }
        }
        return error
    }
}

// MARK: - Helper Models

private struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Token Manager Protocol & Implementation

protocol TokenManagerProtocol: Sendable {
    func saveTokens(accessToken: String, refreshToken: String?) async
    func getAccessToken() async -> String?
    func getRefreshToken() async -> String?
    func clearTokens() async
    func isAuthenticated() async -> Bool
}

actor TokenManager: TokenManagerProtocol {
    static let shared = TokenManager()
    
    private let keychainService: KeychainServiceProtocol
    private let accessTokenKey = "jwt_access_token"
    private let refreshTokenKey = "jwt_refresh_token"
    
    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.keychainService = keychainService
    }
    
    func saveTokens(accessToken: String, refreshToken: String?) async {
        await keychainService.save(accessToken, for: accessTokenKey)
        if let refreshToken = refreshToken {
            await keychainService.save(refreshToken, for: refreshTokenKey)
        }
    }
    
    func getAccessToken() async -> String? {
        return await keychainService.get(accessTokenKey)
    }
    
    func getRefreshToken() async -> String? {
        return await keychainService.get(refreshTokenKey)
    }
    
    func clearTokens() async {
        await keychainService.delete(accessTokenKey)
        await keychainService.delete(refreshTokenKey)
        
        // Also clear any other sensitive data
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "last_login")
    }
    
    func isAuthenticated() async -> Bool {
        return await getAccessToken() != nil
    }
}

// MARK: - Keychain Service Protocol & Implementation

protocol KeychainServiceProtocol: Sendable {
    func save(_ data: String, for key: String) async
    func get(_ key: String) async -> String?
    func delete(_ key: String) async
}

actor KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()
    
    private let serviceName = "com.moneyapp.keychain"
    
    func save(_ data: String, for key: String) async {
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
    
    func get(_ key: String) async -> String? {
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
    
    func delete(_ key: String) async {
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

// MARK: - API Client Protocol (placeholder - should be implemented in Core/Networking)

protocol APIClientProtocol: Sendable {
    func post<T: Codable & Sendable, U: Codable & Sendable>(_ endpoint: String, body: U) async throws -> T
    func post<T: Codable & Sendable>(_ endpoint: String) async throws -> T
    func get<T: Codable & Sendable>(_ endpoint: String) async throws -> T
}

// MARK: - Temporary API Client (should be replaced with actual implementation)

actor APIClient: APIClientProtocol {
    static let shared = APIClient()
    
    private let baseURL = URL(string: "https://api.moneyapp.com")!
    private let session = URLSession.shared
    
    func post<T: Codable & Sendable, U: Codable & Sendable>(_ endpoint: String, body: U) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw OnboardingAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if token exists
        if let token = await TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw OnboardingAPIError.encodingError
        }
        
        return try await performRequest(request)
    }
    
    func post<T: Codable & Sendable>(_ endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw OnboardingAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if token exists
        if let token = await TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await performRequest(request)
    }
    
    func get<T: Codable & Sendable>(_ endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw OnboardingAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header if token exists
        if let token = await TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await performRequest(request)
    }
    
    private func performRequest<T: Codable & Sendable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OnboardingAPIError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    print("🔴 Decoding error for \(request.url?.path ?? "unknown"): \(error)")
                    throw OnboardingAPIError.decodingError
                }
            case 401:
                throw OnboardingAPIError.unauthorized
            case 403:
                throw OnboardingAPIError.forbidden
            case 404:
                throw OnboardingAPIError.notFound
            case 408:
                throw OnboardingAPIError.requestTimeout
            case 500...599:
                throw OnboardingAPIError.serverError(httpResponse.statusCode)
            default:
                throw OnboardingAPIError.networkError
            }
        } catch let error as OnboardingAPIError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw OnboardingAPIError.noInternetConnection
            case .timedOut:
                throw OnboardingAPIError.requestTimeout
            default:
                throw OnboardingAPIError.networkError
            }
        } catch {
            throw OnboardingAPIError.networkError
        }
    }
}

// MARK: - API Error Definitions

enum OnboardingAPIError: LocalizedError, Equatable {
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
}
