//
//  RegisterViewModel.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation
import Observation

// MARK: - RegisterViewModel (@Observable - Swift 6)

@Observable
@MainActor
final class RegisterViewModel {
    
    // MARK: - Published Properties (No @Published needed with @Observable)
    
    var email = ""
    var password = ""
    var confirmPassword = ""
    var firstName = ""
    var lastName = ""
    var acceptedTerms = false
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var isAuthenticated = false
    var currentUser: UserResponse?
    
    // Field-specific errors for inline display
    var emailError: String?
    var passwordError: String?
    var confirmPasswordError: String?
    var firstNameError: String?
    var lastNameError: String?
    
    // MARK: - Navigation
    
    var router: AppRouter?
    
    // MARK: - Private Properties
    
    private let onboardingService: OnboardingServiceProtocol
    
    // MARK: - Initialization
    
    init(onboardingService: OnboardingServiceProtocol = OnboardingService()) {
        self.onboardingService = onboardingService
    }
    
    // MARK: - Public Methods
    
    func register() async {
        // Clear previous errors
        clearAllErrors()
        
        // Validate all input
        guard validateAllInput() else { return }
        
        isLoading = true
        
        do {
            let request = UserRegistrationRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            let response = try await onboardingService.register(request)
            
            // Handle successful registration
            await handleSuccessfulRegistration(response)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func navigateToLogin() {
        router?.pop()
    }
    
    func validateField(_ field: String) {
        switch field {
        case "email":
            emailError = validateEmail()
        case "password":
            passwordError = validatePassword()
        case "confirmPassword":
            confirmPasswordError = validateConfirmPassword()
        case "firstName":
            firstNameError = validateFirstName()
        case "lastName":
            lastNameError = validateLastName()
        default:
            break
        }
    }
    
    // MARK: - Private Validation Methods
    
    private func validateAllInput() -> Bool {
        let emailValid = validateEmail() == nil
        let passwordValid = validatePassword() == nil
        let confirmPasswordValid = validateConfirmPassword() == nil
        let firstNameValid = validateFirstName() == nil
        let lastNameValid = validateLastName() == nil
        let termsValid = validateTermsAcceptance()
        
        // Update field errors
        emailError = validateEmail()
        passwordError = validatePassword()
        confirmPasswordError = validateConfirmPassword()
        firstNameError = validateFirstName()
        lastNameError = validateLastName()
        
        return emailValid && passwordValid && confirmPasswordValid && 
               firstNameValid && lastNameValid && termsValid
    }
    
    private func validateEmail() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            return "Email is required."
        }
        
        if !isValidEmail(trimmedEmail) {
            return "Please enter a valid email address."
        }
        
        return nil
    }
    
    private func validatePassword() -> String? {
        if password.isEmpty {
            return "Password is required."
        }
        
        if password.count < 8 {
            return "Password must be at least 8 characters."
        }
        
        if !hasRequiredPasswordComplexity(password) {
            return "Password must contain letters, numbers, and special characters."
        }
        
        return nil
    }
    
    private func validateConfirmPassword() -> String? {
        if confirmPassword.isEmpty {
            return "Please confirm your password."
        }
        
        if password != confirmPassword {
            return "Passwords do not match."
        }
        
        return nil
    }
    
    private func validateFirstName() -> String? {
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "First name is required."
        }
        
        if trimmedName.count < 2 {
            return "First name must be at least 2 characters."
        }
        
        return nil
    }
    
    private func validateLastName() -> String? {
        let trimmedName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "Last name is required."
        }
        
        if trimmedName.count < 2 {
            return "Last name must be at least 2 characters."
        }
        
        return nil
    }
    
    private func validateTermsAcceptance() -> Bool {
        if !acceptedTerms {
            showErrorMessage("Please accept the Terms of Service and Privacy Policy to continue.")
            return false
        }
        return true
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func hasRequiredPasswordComplexity(_ password: String) -> Bool {
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChar = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")) != nil
        
        return hasLetter && hasNumber && hasSpecialChar
    }
    
    private func handleSuccessfulRegistration(_ response: AuthTokenResponse) async {
        // Note: AuthTokenResponse doesn't contain user data directly
        // In a real implementation, you would fetch user data separately or the response would include it
        // For now, we'll just mark as authenticated and show onboarding
        isAuthenticated = true
        
        // Always show onboarding for new users
        router?.push(OnboardingDestination.welcome)
        
        // Clear sensitive form data
        password = ""
        confirmPassword = ""
    }
    
    private func handleError(_ error: Error) {
        print("🔴 Registration error: \(error)")
        
        switch error {
        case let authError as AuthError:
            if case .emailAlreadyExists = authError {
                emailError = "An account with this email already exists."
            } else {
                errorMessage = authError.localizedDescription
                showError = true
            }
        case let apiError as OnboardingAPIError:
            errorMessage = apiError.localizedDescription
            showError = true
        case let validationError as ValidationError<LocalizedValidationError>:
            errorMessage = validationError.localizedDescription
            showError = true
        default:
            errorMessage = "Registration failed. Please try again."
            showError = true
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearAllErrors() {
        showError = false
        errorMessage = ""
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        firstNameError = nil
        lastNameError = nil
    }
}
