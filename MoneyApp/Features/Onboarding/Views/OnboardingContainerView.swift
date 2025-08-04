//
//  OnboardingContainerView.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import SwiftUI
import MoneyAppGenerated

struct OnboardingContainerView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            LoginView()
                .navigationDestination(for: OnboardingDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: OnboardingDestination) -> some View {
        switch destination {
        case .login:
            LoginView()
        case .register:
            RegisterView()
        case .welcome:
            if let user = getCurrentUser() {
                OnboardingFlowView(user: user)
            } else {
                LoginView()
            }
        case .onboardingStep(let stepIndex):
            if let user = getCurrentUser() {
                OnboardingFlowView(user: user)
                    .onAppear {
                        // Set the specific step index
                        // This would be handled by the ViewModel
                    }
            } else {
                LoginView()
            }
        case .completeOnboarding:
            CompletionView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUser() -> UserResponse? {
        // In a real app, this would get the current user from auth state
        // For now, return a sample user
        return UserResponse.sample
    }
}

// MARK: - Completion View

struct CompletionView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: true)
                
                VStack(spacing: 12) {
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Welcome to Money App. Let's start managing your finances smarter.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                router.showMainApp()
            }) {
                Text("Continue to App")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
}
