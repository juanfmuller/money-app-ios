//
//  APIService.swift
//  MoneyAppGenerated
//
//  Auto-generated API service template for Swift 6 generator
//  You can customize this file as needed
//
//  Swift 6 Features:
//  - Pure async/await support (no Combine dependency)
//  - Request interceptors and retriers via OpenAPIClient.shared.interceptor
//  - No external dependencies (AnyCodable replaced with JSONValue)
//  - Modern Swift concurrency patterns
//

import Foundation
import MoneyAppGenerated

actor APIService {
    static let shared = APIService()
    
    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?
    
    private init() {
        // Configure based on build configuration
        #if DEBUG
        self.baseURL = URL(string: "http://localhost:8000")!
        #else
        self.baseURL = URL(string: "https://api.money-app-backend.com")!
        #endif
        
        self.session = URLSession.shared
        
        // Swift 6: Configure interceptors if needed
        // OpenAPIClient.shared.interceptor = CustomInterceptor()
    }
    
    // MARK: - Authentication
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    // MARK: - Generic Request Method (Modern Swift Concurrency)
    
    private func makeRequest<T: Codable>(
        path: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        // Handle HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
    
    // MARK: - API Methods (Modern Swift Concurrency)
    
    func fetchTransactions() async throws -> TransactionListResponse {
        return try await makeRequest(path: "/api/transactions/", responseType: TransactionListResponse.self)
    }
    
    func fetchAccounts() async throws -> AccountListResponse {
        return try await makeRequest(path: "/api/accounts/", responseType: AccountListResponse.self)
    }
    
    func fetchSpendingSummary(days: Int = 30) async throws -> SpendingSummaryResponse {
        return try await makeRequest(path: "/api/transactions/summary?days=\(days)", responseType: SpendingSummaryResponse.self)
    }
    
    func createLinkToken() async throws -> LinkTokenResponse {
        return try await makeRequest(path: "/api/accounts/link/token", method: .POST, responseType: LinkTokenResponse.self)
    }
    
    func exchangePublicToken(_ request: PublicTokenExchangeRequest) async throws -> PublicTokenExchangeResponse {
        let body = try JSONEncoder().encode(request)
        return try await makeRequest(path: "/api/accounts/link/exchange", method: .POST, body: body, responseType: PublicTokenExchangeResponse.self)
    }
    
    func login(_ request: UserLoginRequest) async throws -> AuthTokenResponse {
        let body = try JSONEncoder().encode(request)
        return try await makeRequest(path: "/api/auth/login", method: .POST, body: body, responseType: AuthTokenResponse.self)
    }
    
    func register(_ request: UserRegistrationRequest) async throws -> UserResponse {
        let body = try JSONEncoder().encode(request)
        return try await makeRequest(path: "/api/auth/register", method: .POST, body: body, responseType: UserResponse.self)
    }
    
    func getCurrentUser() async throws -> UserResponse {
        return try await makeRequest(path: "/api/auth/me", responseType: UserResponse.self)
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
