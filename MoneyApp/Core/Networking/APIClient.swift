//
//  APIClient.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/3/25.
//

import Foundation

// MARK: - API Client Protocol

protocol APIClientProtocol: Sendable {
    func post<T: Codable & Sendable, U: Codable & Sendable>(_ endpoint: String, body: U) async throws -> T
    func post<T: Codable & Sendable>(_ endpoint: String) async throws -> T
    func get<T: Codable & Sendable>(_ endpoint: String) async throws -> T
}

// MARK: - Temporary API Client

actor APIClient: APIClientProtocol {
    static let shared = APIClient()
    
    private let baseURL = AppConstants.apiBaseURL
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
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
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
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    return try decoder.decode(T.self, from: data)
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

// MARK: - Auth Error Definitions

enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case accountLocked
    case emailAlreadyExists
    case registrationFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .accountLocked:
            return "Your account has been locked. Please contact support."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .registrationFailed:
            return "Registration failed. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
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

