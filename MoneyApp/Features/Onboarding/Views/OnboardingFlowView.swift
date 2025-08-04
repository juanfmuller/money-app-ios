//
//  OnboardingFlowView.swift
//  MoneyApp
//
//  Created by Juan Muller on 1/20/25.
//

import SwiftUI
import MoneyAppGenerated

struct OnboardingFlowView: View {
    @State private var viewModel = OnboardingFlowViewModel()
    @EnvironmentObject var router: AppRouter
    
    let user: UserResponse
    
    init(user: UserResponse) {
        self.user = user
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                progressBar
                
                // Main Content
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 20)
                        
                        // Step Content
                        stepContent
                        
                        // Navigation Buttons
                        navigationButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.router = router
            viewModel.currentUser = user
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.onboardingSteps.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Skip") {
                    viewModel.skipToEnd()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var stepContent: some View {
        VStack(spacing: 24) {
            // Step Icon
            Image(systemName: viewModel.currentStep.imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolRenderingMode(.hierarchical)
            
            // Step Title & Description
            VStack(spacing: 12) {
                Text(viewModel.currentStep.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.currentStep.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Step-specific content
            stepSpecificContent
        }
    }
    
    @ViewBuilder
    private var stepSpecificContent: some View {
        switch viewModel.currentStep.id {
        case "welcome":
            welcomeContent
        case "connect_accounts":
            connectAccountsContent
        case "set_goals":
            setGoalsContent
        case "notifications":
            notificationsContent
        default:
            EmptyView()
        }
    }
    
    private var welcomeContent: some View {
        VStack(spacing: 16) {
            Text("Hello, \(user.displayName)!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text("We're excited to help you take control of your financial future.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
    }
    
    private var connectAccountsContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FeatureCard(
                    icon: "shield.checkered",
                    title: "Bank-Level Security",
                    description: "256-bit encryption"
                )
                
                FeatureCard(
                    icon: "clock.arrow.circlepath",
                    title: "Real-Time Updates",
                    description: "Instant transaction sync"
                )
            }
            
            Text("We use Plaid to securely connect to over 11,000 financial institutions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var setGoalsContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FeatureCard(
                    icon: "target",
                    title: "Savings Goals",
                    description: "Track your progress"
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Smart Budgets",
                    description: "AI-powered insights"
                )
            }
            
            Text("Set personalized financial goals and get insights to help you achieve them.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var notificationsContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FeatureCard(
                    icon: "bell.badge",
                    title: "Smart Alerts",
                    description: "Important updates only"
                )
                
                FeatureCard(
                    icon: "chart.xyaxis.line",
                    title: "Spending Insights",
                    description: "Weekly summaries"
                )
            }
            
            Text("Stay informed about your spending patterns and account activity.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            // Primary Action Button
            Button(action: {
                handlePrimaryAction()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(primaryButtonTitle)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            
            // Secondary Actions
            HStack {
                if !viewModel.isFirstStep {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if !viewModel.isLastStep {
                    Button("Skip") {
                        viewModel.skipCurrentStep()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var primaryButtonTitle: String {
        switch viewModel.currentStep.id {
        case "welcome":
            return "Get Started"
        case "connect_accounts":
            return "Connect Accounts"
        case "set_goals":
            return "Set Up Goals"
        case "notifications":
            return "Enable Notifications"
        default:
            return viewModel.isLastStep ? "Complete Setup" : "Continue"
        }
    }
    
    // MARK: - Actions
    
    private func handlePrimaryAction() {
        switch viewModel.currentStep.id {
        case "welcome":
            viewModel.handleWelcomeAction()
        case "connect_accounts":
            viewModel.handleConnectAccountsAction()
        case "set_goals":
            viewModel.handleSetGoalsAction()
        case "notifications":
            viewModel.handleNotificationsAction()
        default:
            viewModel.nextStep()
        }
    }
}

// MARK: - Supporting Views

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView(user: UserResponse.sample)
        .environmentObject(AppRouter())
}