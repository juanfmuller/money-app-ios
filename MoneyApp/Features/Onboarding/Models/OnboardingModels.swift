//
//  OnboardingModels.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation

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

// MARK: - Validation Models

enum LocalizedValidationError: LocalizedError, Hashable {
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

// MARK: - UI State Models

struct OnboardingFormState: Sendable {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var firstName = ""
    var lastName = ""
    var acceptedTerms = false
    var isLoading = false
    var currentStep = 0
    var completedSteps: Set<String> = []
}

// MARK: - UI Helper Models

struct OnboardingProgress: Sendable {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    init(currentStep: Int, totalSteps: Int) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.progress = Double(currentStep) / Double(totalSteps)
    }
}

// MARK: - Sample Data Extensions (for testing and previews)

extension UserResponse {
    static let sample = UserResponse(
        id: 1,
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        isActive: true,
        createdAt: Date()
    )
    
    static let sampleCompleted = UserResponse(
        id: 2,
        email: "jane.smith@example.com",
        firstName: "Jane",
        lastName: "Smith",
        isActive: true,
        createdAt: Date()
    )
    
    // MARK: - Computed Properties for UI
    
    var displayName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let firstInitial = firstName?.first?.uppercased() ?? ""
        let lastInitial = lastName?.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
}

extension AuthTokenResponse {
    static let sample = AuthTokenResponse(
        accessToken: "sample_access_token_123",
        tokenType: "bearer",
        expiresIn: 3600
    )
}
