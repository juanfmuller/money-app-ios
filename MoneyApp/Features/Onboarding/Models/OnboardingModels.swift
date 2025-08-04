//
//  OnboardingModels.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation

// MARK: - Authentication Request Models

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable, Sendable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let acceptedTerms: Bool
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case firstName = "first_name"
        case lastName = "last_name"
        case acceptedTerms = "accepted_terms"
    }
}

struct DeviceTokenRequest: Codable, Sendable {
    let deviceToken: String
    
    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
    }
}

// MARK: - Authentication Response Models

struct AuthResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let user: User
    let isFirstLogin: Bool
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
        case isFirstLogin = "is_first_login"
    }
}

struct User: Codable, Identifiable, Sendable, Hashable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let isActive: Bool
    let createdAt: Date
    let deviceToken: String?
    let hasCompletedOnboarding: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case isActive = "is_active"
        case createdAt = "created_at"
        case deviceToken = "device_token"
        case hasCompletedOnboarding = "has_completed_onboarding"
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
    
    var needsOnboarding: Bool {
        return !hasCompletedOnboarding
    }
}

// MARK: - Onboarding Flow Models

struct OnboardingStep: Sendable {
    let id: String
    let title: String
    let description: String
    let imageName: String
    let isCompleted: Bool
    
    static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "welcome",
            title: "Welcome to Money App",
            description: "Take control of your finances with smart budgeting and expense tracking.",
            imageName: "dollarsign.circle.fill",
            isCompleted: false
        ),
        OnboardingStep(
            id: "connect_accounts",
            title: "Connect Your Accounts",
            description: "Securely link your bank accounts to automatically track your spending.",
            imageName: "creditcard.fill",
            isCompleted: false
        ),
        OnboardingStep(
            id: "set_goals",
            title: "Set Financial Goals",
            description: "Create savings goals and budgets to reach your financial targets.",
            imageName: "target",
            isCompleted: false
        ),
        OnboardingStep(
            id: "notifications",
            title: "Stay Informed",
            description: "Get notified about spending patterns and important account activity.",
            imageName: "bell.fill",
            isCompleted: false
        )
    ]
}

struct OnboardingCompletion: Codable, Sendable {
    let userId: Int
    let completedSteps: [String]
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case completedSteps = "completed_steps"
        case completedAt = "completed_at"
    }
}

// MARK: - Validation Models

enum ValidationError: LocalizedError {
    case required(field: String)
    case invalidFormat(field: String)
    case tooShort(field: String, minLength: Int)
    case tooLong(field: String, maxLength: Int)
    case mismatch(field1: String, field2: String)
    case weakPassword
    case termsNotAccepted
    
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
        case .weakPassword:
            return "Password must contain at least 8 characters with letters, numbers, and special characters."
        case .termsNotAccepted:
            return "Please accept the Terms of Service and Privacy Policy to continue."
        }
    }
}

// MARK: - API Error Models

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case accountLocked
    case tooManyAttempts
    case sessionExpired
    case registrationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .emailAlreadyExists:
            return "An account with this email already exists. Please sign in instead."
        case .accountLocked:
            return "Your account has been temporarily locked. Please try again in 15 minutes."
        case .tooManyAttempts:
            return "Too many login attempts. Please wait before trying again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .registrationFailed:
            return "Registration failed. Please check your information and try again."
        }
    }
}

// MARK: - Success Response Model

struct SuccessResponse: Codable, Sendable {
    let message: String
    let success: Bool
}

// MARK: - Sample Data Extensions (for testing and previews)

extension User {
    static let sample = User(
        id: 1,
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        isActive: true,
        createdAt: Date(),
        deviceToken: nil,
        hasCompletedOnboarding: false
    )
    
    static let sampleCompleted = User(
        id: 2,
        email: "jane.smith@example.com",
        firstName: "Jane",
        lastName: "Smith",
        isActive: true,
        createdAt: Date(),
        deviceToken: "sample_device_token",
        hasCompletedOnboarding: true
    )
}

extension AuthResponse {
    static let sample = AuthResponse(
        accessToken: "sample_access_token_123",
        refreshToken: "sample_refresh_token_456",
        user: User.sample,
        isFirstLogin: true
    )
    
    static let sampleReturningUser = AuthResponse(
        accessToken: "sample_access_token_789",
        refreshToken: "sample_refresh_token_012",
        user: User.sampleCompleted,
        isFirstLogin: false
    )
}