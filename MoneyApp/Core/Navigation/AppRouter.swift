//
//  AppRouter.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import SwiftUI
import Combine

final class AppRouter: ObservableObject {
    @Published var currentScreen: Screen = .auth
    @Published var navigationPath = NavigationPath()
    
    // Authentication state
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    enum Screen: Hashable {
        case auth
        case onboarding(User)
        case home
        case accounts
        case transactions
        case settings
    }
    
    // MARK: - Primary Navigation
    func navigate(to screen: Screen) {
        currentScreen = screen
    }
    
    // MARK: - Stack Navigation
    func push<T: Hashable>(_ value: T) {
        navigationPath.append(value)
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    // MARK: - Authentication Navigation
    func showAuth() {
        navigate(to: .auth)
        popToRoot()
        isAuthenticated = false
        currentUser = nil
    }
    
    func showOnboarding(for user: User) {
        navigate(to: .onboarding(user))
        popToRoot()
        isAuthenticated = true
        currentUser = user
    }
    
    func showMainApp() {
        navigate(to: .home)
        popToRoot()
        isAuthenticated = true
    }
    
    // MARK: - App Navigation
    func showHome() {
        navigate(to: .home)
    }
    
    func showTransactions() {
        navigate(to: .transactions)
    }
    
    func showAccounts() {
        navigate(to: .accounts)
    }
    
    func showSettings() {
        navigate(to: .settings)
    }
    
    // MARK: - Authentication Actions
    func handleSuccessfulAuth(_ response: AuthResponse) {
        currentUser = response.user
        
        if response.user.needsOnboarding || response.isFirstLogin {
            showOnboarding(for: response.user)
        } else {
            showMainApp()
        }
    }
    
    func logout() async {
        // Clear authentication state
        isAuthenticated = false
        currentUser = nil
        
        // Clear tokens through service
        do {
            let onboardingService = OnboardingService()
            _ = try await onboardingService.logout()
        } catch {
            print("🔴 Logout error: \(error)")
        }
        
        // Navigate to auth
        showAuth()
    }
}

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case accountDetail(accountId: String)
    case transactionDetail(transactionId: String)
    case addTransaction
    case linkAccount
    case profile
}

// MARK: - Onboarding Destinations
enum OnboardingDestination: Hashable {
    case login
    case register
    case welcome
    case onboardingStep(Int)
    case completeOnboarding
}
