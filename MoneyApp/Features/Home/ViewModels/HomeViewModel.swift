//
//  HomeViewModel.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import Foundation
import Observation

// MARK: - HomeViewModel (@Observable - Swift 6)
@Observable
@MainActor
final class HomeViewModel {
    // MARK: - Published Properties (No @Published needed with @Observable)
    var dashboardSummary: DashboardSummary?
    var isLoading = false
    var isPolling = false
    var showError = false
    var errorMessage = ""
    
    // MARK: - Navigation
    var router: AppRouter?
    
    // MARK: - Private Properties
    private let homeService: HomeServiceProtocol
    private var pollingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(homeService: HomeServiceProtocol = HomeService()) {
        self.homeService = homeService
    }
    
    // MARK: - Public Methods
    
    func loadDashboard() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            dashboardSummary = try await homeService.getDashboardSummary()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refreshDashboard() async {
        do {
            dashboardSummary = try await homeService.refreshAllData()
        } catch {
            handleError(error)
        }
    }
    
    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        
        pollingTask = Task {
            while !Task.isCancelled {
                await refreshDashboard()
                
                // Wait 30 seconds before next poll (configurable based on needs)
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }
    
    // MARK: - Quick Actions
    
    func handleQuickAction(_ action: QuickAction) {
        guard let router = router else { return }
        
        switch action {
        case .addTransaction:
            router.push(NavigationDestination.addTransaction)
        case .linkAccount:
            router.push(NavigationDestination.linkAccount)
        case .viewBudgets:
            // Navigate to budgets (would need to add to router)
            break
        case .payBills:
            // Navigate to bills (would need to add to router)
            break
        }
    }
    
    func showAccountDetail(accountId: String) {
        router?.push(NavigationDestination.accountDetail(accountId: accountId))
    }
    
    func showTransactionDetail(transactionId: String) {
        router?.push(NavigationDestination.transactionDetail(transactionId: transactionId))
    }
    
    func showAllTransactions() {
        router?.navigate(to: .transactions)
    }
    
    func showAllAccounts() {
        router?.navigate(to: .accounts)
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        Task {
            await loadDashboard()
            startPolling()
        }
    }
    
    func onDisappear() {
        stopPolling()
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        
        // Log error for debugging
        print("HomeViewModel Error: \(error)")
    }
}

// MARK: - Computed Properties
extension HomeViewModel {
    var totalBalanceText: String {
        dashboardSummary?.totalBalance.formattedAmount ?? "$0.00"
    }
    
    var monthlySpendingText: String {
        dashboardSummary?.monthlySpending.formattedAmount ?? "$0.00"
    }
    
    var hasData: Bool {
        dashboardSummary != nil
    }
    
    var shouldShowEmptyState: Bool {
        !isLoading && !hasData
    }
    
    var quickActions: [QuickAction] {
        QuickAction.allCases
    }
}