//
//  LoginViewModel.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation
import Observation

// MARK: - LoginViewModel (@Observable - Swift 6)

@Observable
@MainActor
final class LoginViewModel {
    
    // MARK: - Published Properties (No @Published needed with @Observable)
    
    var email = ""
    var password = ""
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var isAuthenticated = false
    var currentUser: User?
    
    // MARK: - Navigation
    
    var router: AppRouter?
    
    // MARK: - Private Properties
    
    private let onboardingService: OnboardingServiceProtocol
    
    // MARK: - Initialization
    
    init(onboardingService: OnboardingServiceProtocol = OnboardingService()) {
        self.onboardingService = onboardingService
    }
    
    // MARK: - Public Methods
    
    func login() async {
        logUserAction("login_attempted", parameters: ["email": email])
        
        // Clear previous errors
        clearError()
        
        // Validate input
        guard validateInput() else { 
            logWarning("Login validation failed", category: "Auth")
            return 
        }
        
        logInfo("Login validation passed, attempting API call", category: "Auth")
        isLoading = true
        
        do {
            let request = LoginRequest(email: email, password: password)
            let response = try await onboardingService.login(request)
            
            // Handle successful login
            await handleSuccessfulLogin(response)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func resetPassword() {
        // TODO: Implement password reset functionality
        showErrorMessage("Password reset functionality will be implemented soon.")
    }
    
    func navigateToRegister() {
        router?.push(OnboardingDestination.register)
    }
    
    // MARK: - Private Methods
    
    private func validateInput() -> Bool {
        if email.isEmpty {
            showErrorMessage("Please enter your email address.")
            return false
        }
        
        if !isValidEmail(email) {
            showErrorMessage("Please enter a valid email address.")
            return false
        }
        
        if password.isEmpty {
            showErrorMessage("Please enter your password.")
            return false
        }
        
        if password.count < 6 {
            showErrorMessage("Password must be at least 6 characters.")
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleSuccessfulLogin(_ response: AuthResponse) async {
        logUserAction("login_successful", parameters: [
            "user_id": response.user.id,
            "needs_onboarding": response.user.needsOnboarding,
            "is_first_login": response.isFirstLogin
        ])
        
        // Set user identifier for crash reporting
        LoggingManager.shared.setUserIdentifier(String(response.user.id))
        
        currentUser = response.user
        isAuthenticated = true
        
        // Navigate based on user state
        if response.user.needsOnboarding || response.isFirstLogin {
            logInfo("Navigating to onboarding flow", category: "Navigation")
            router?.push(OnboardingDestination.welcome)
        } else {
            logInfo("Navigating to main app", category: "Navigation")
            router?.showMainApp()
        }
        
        // Clear sensitive form data
        password = ""
    }
    
    private func handleError(_ error: Error) {
        logError(error, category: "Auth")
        logUserAction("login_failed", parameters: [
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription
        ])
        
        switch error {
        case let authError as AuthError:
            errorMessage = authError.localizedDescription
        case let apiError as OnboardingAPIError:
            errorMessage = apiError.localizedDescription
        case let validationError as ValidationError:
            errorMessage = validationError.localizedDescription
        default:
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        showError = true
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearError() {
        showError = false
        errorMessage = ""
    }
}
