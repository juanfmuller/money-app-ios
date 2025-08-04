//
//  OnboardingFlowViewModel.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import Foundation
import Observation

// MARK: - OnboardingFlowViewModel (@Observable - Swift 6)

@Observable
@MainActor
final class OnboardingFlowViewModel {
    
    // MARK: - Published Properties
    
    var currentStepIndex = 0
    var onboardingSteps: [OnboardingStep] = OnboardingStep.allSteps
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var currentUser: UserResponse?
    
    // MARK: - Navigation
    
    var router: AppRouter?
    
    // MARK: - Private Properties
    
    private let onboardingService: OnboardingServiceProtocol
    private var completedSteps: [String] = []
    
    // MARK: - Computed Properties
    
    var currentStep: OnboardingStep {
        return onboardingSteps[currentStepIndex]
    }
    
    var isFirstStep: Bool {
        return currentStepIndex == 0
    }
    
    var isLastStep: Bool {
        return currentStepIndex == onboardingSteps.count - 1
    }
    
    var progressPercentage: Double {
        return Double(currentStepIndex + 1) / Double(onboardingSteps.count)
    }
    
    var canProceed: Bool {
        // Add specific logic for each step if needed
        switch currentStep.id {
        case "welcome":
            return true // Always can proceed from welcome
        case "connect_accounts":
            return true // Optional step for MVP
        case "set_goals":
            return true // Optional step for MVP
        case "notifications":
            return true // Optional step for MVP
        default:
            return true
        }
    }
    
    // MARK: - Initialization
    
    init(onboardingService: OnboardingServiceProtocol = OnboardingService(),
         user: UserResponse? = nil) {
        self.onboardingService = onboardingService
        self.currentUser = user
    }
    
    // MARK: - Navigation Methods
    
    func nextStep() {
        guard !isLastStep else {
            completeOnboarding()
            return
        }
        
        // Mark current step as completed
        markCurrentStepCompleted()
        
        // Move to next step
        currentStepIndex += 1
    }
    
    func previousStep() {
        guard !isFirstStep else { return }
        currentStepIndex -= 1
    }
    
    func skipToEnd() {
        // Mark all remaining steps as completed and finish onboarding
        completeOnboarding()
    }
    
    func goToStep(_ index: Int) {
        guard index >= 0 && index < onboardingSteps.count else { return }
        currentStepIndex = index
    }
    
    // MARK: - Onboarding Actions
    
    func markCurrentStepCompleted() {
        let stepId = currentStep.id
        if !completedSteps.contains(stepId) {
            completedSteps.append(stepId)
        }
        
        // Update the step in our array
        onboardingSteps[currentStepIndex] = OnboardingStep(
            id: currentStep.id,
            title: currentStep.title,
            description: currentStep.description,
            imageName: currentStep.imageName,
            isCompleted: true
        )
    }
    
    func completeOnboarding() {
        // Mark all steps as completed if user skips
        for step in onboardingSteps {
            if !completedSteps.contains(step.id) {
                completedSteps.append(step.id)
            }
        }
        
        Task {
            await submitOnboardingCompletion()
        }
    }
    
    // MARK: - API Methods
    
    private func submitOnboardingCompletion() async {
        guard let user = currentUser else {
            showErrorMessage("User information not available. Please try logging in again.")
            return
        }
        
        isLoading = true
        
        // For MVP, we'll just navigate to main app without calling an API
        // In a full implementation, you would call an API to mark onboarding as completed
        // The backend should track onboarding completion status based on user properties
        
        // Navigate to main app
        router?.showMainApp()
        
        isLoading = false
    }
    
    // MARK: - Step-Specific Actions
    
    func handleWelcomeAction() {
        // Welcome step - just proceed
        nextStep()
    }
    
    func handleConnectAccountsAction() {
        // For MVP, just mark as completed and proceed
        // In full implementation, would trigger Plaid Link flow
        nextStep()
    }
    
    func handleSetGoalsAction() {
        // For MVP, just mark as completed and proceed
        // In full implementation, would show goals setup
        nextStep()
    }
    
    func handleNotificationsAction() {
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    func skipCurrentStep() {
        nextStep()
    }
    
    // MARK: - Notification Permissions
    
    private func requestNotificationPermissions() {
        // Request notification permissions from system
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError(error)
                } else {
                    // Proceed regardless of permission grant
                    self?.nextStep()
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        print("🔴 Onboarding error: \(error)")
        
        switch error {
        case let apiError as OnboardingAPIError:
            errorMessage = apiError.localizedDescription
        default:
            errorMessage = "An error occurred during onboarding. Please try again."
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

// MARK: - Import for notifications
import UserNotifications

// MARK: - Onboarding Navigation Destinations

// OnboardingDestination is defined in AppRouter.swift
