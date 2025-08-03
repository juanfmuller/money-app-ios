//
//  AppRouter.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import SwiftUI
import Observation

@Observable
final class AppRouter {
    var currentScreen: Screen = .auth
    var navigationPath = NavigationPath()
    
    enum Screen: Hashable {
        case auth
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
    
    // MARK: - Quick Navigation Methods
    func showAuth() {
        navigate(to: .auth)
        popToRoot() // Clear any navigation stack
    }
    
    func showMainApp() {
        navigate(to: .home) // Default main screen
        popToRoot()
    }
    
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
}

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case accountDetail(accountId: String)
    case transactionDetail(transactionId: String)
    case addTransaction
    case linkAccount
    case profile
}