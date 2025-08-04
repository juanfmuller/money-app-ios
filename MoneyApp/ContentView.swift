//
//  ContentView.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    
    var body: some View {
        Group {
            switch router.currentScreen {
            case .auth:
                OnboardingContainerView()
            case .onboarding(let user):
                OnboardingFlowView(user: user)
            case .home:
                HomeView()
            case .accounts:
                accountsPlaceholder
            case .transactions:
                transactionsPlaceholder
            case .settings:
                settingsPlaceholder
            }
        }
        .environmentObject(router)
        .onAppear {
            checkAuthenticationState()
        }
    }
    
    // MARK: - Authentication Check
    private func checkAuthenticationState() {
        Task {
            // Check if user is already authenticated
            let tokenManager = TokenManager.shared
            let isAuthenticated = await tokenManager.isAuthenticated()
            
            if isAuthenticated {
                // TODO: Get current user from API/storage
                // For now, redirect to main app
                router.showMainApp()
            } else {
                router.showAuth()
            }
        }
    }
    
    private var accountsPlaceholder: some View {
        NavigationView {
            VStack {
                Text("Accounts Feature")
                    .font(.title)
                Button("Back to Home") {
                    router.showHome()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Accounts")
        }
    }
    
    private var transactionsPlaceholder: some View {
        NavigationView {
            VStack {
                Text("Transactions Feature")
                    .font(.title)
                Button("Back to Home") {
                    router.showHome()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Transactions")
        }
    }
    
    private var settingsPlaceholder: some View {
        NavigationView {
            VStack {
                Text("Settings Feature")
                    .font(.title)
                Button("Back to Home") {
                    router.showHome()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Settings")
        }
    }
}
