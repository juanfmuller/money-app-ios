//
//  OnboardingService.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation
import MoneyAppGenerated

// MARK: - Protocol Definition

protocol OnboardingServiceProtocol: Sendable {
    func login(_ request: UserLoginRequest) async throws -> AuthTokenResponse
    func register(_ request: UserRegistrationRequest) async throws -> AuthTokenResponse
    func updateDeviceToken(_ token: String) async throws -> DeviceTokenResponse
    func logout() async throws -> DeviceTokenResponse
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
    
    func login(_ request: UserLoginRequest) async throws -> AuthTokenResponse {
        do {
            let response: AuthTokenResponse = try await apiClient.post(APIEndpoints.Auth.login, body: request)
            
            // Store JWT tokens securely
            await tokenManager.saveTokens(
                accessToken: response.accessToken,
                refreshToken: nil // AuthTokenResponse doesn't include refresh token
            )
            
            return response
            
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func register(_ request: UserRegistrationRequest) async throws -> AuthTokenResponse {
        do {
            let _: UserResponse = try await apiClient.post(APIEndpoints.Auth.register, body: request)
            
            let login_response = try await self.login(UserLoginRequest(
                email: request.email,
                password: request.password
            ))
            
            return login_response
            
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func logout() async throws -> DeviceTokenResponse {
        do {
            // Notify backend of logout (optional)
            let response: DeviceTokenResponse = try await apiClient.post(APIEndpoints.Auth.logout)
            
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
    
    func updateDeviceToken(_ token: String) async throws -> DeviceTokenResponse {
        let request = DeviceTokenRequest(deviceToken: token)
        return try await apiClient.post(APIEndpoints.Auth.deviceToken, body: request)
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

// Note: Using generated models from MoneyAppGenerated instead of custom models

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

