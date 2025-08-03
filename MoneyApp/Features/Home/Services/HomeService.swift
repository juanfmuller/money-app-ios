//
//  HomeService.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import Foundation
import MoneyAppGenerated

// MARK: - Protocol Definition
protocol HomeServiceProtocol: Sendable {
    func getDashboardSummary() async throws -> DashboardSummary
    func getRecentTransactions(limit: Int) async throws -> [Transaction]
    func getAccountSummaries() async throws -> [AccountSummary]
    func refreshAllData() async throws -> DashboardSummary
}

// MARK: - Actor Implementation
actor HomeService: HomeServiceProtocol {
    private let apiService: APIService
    
    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }
    
    func getDashboardSummary() async throws -> DashboardSummary {
        // Make parallel API calls for dashboard data
        async let recentTransactions = getRecentTransactions(limit: 5)
        async let accountSummaries = getAccountSummaries()
        
        let transactions = try await recentTransactions
        let accounts = try await accountSummaries
        
        // Calculate totals
        let totalBalance = calculateTotalBalance(from: accounts)
        let monthlySpending = calculateMonthlySpending(from: transactions)
        
        return DashboardSummary(
            totalBalance: totalBalance,
            monthlySpending: monthlySpending,
            recentTransactions: transactions,
            accountSummaries: accounts
        )
    }
    
    func getRecentTransactions(limit: Int = 5) async throws -> [Transaction] {
        // Use existing API service method
        let response = try await apiService.fetchTransactions()
        
        // Convert API response to local models and limit results
        return Array(response.domainTransactions.prefix(limit))
    }
    
    func getAccountSummaries() async throws -> [AccountSummary] {
        // Use existing API service method
        let response = try await apiService.fetchAccounts()
        
        // Convert API response to local models
        return response.domainAccounts
    }
    
    func refreshAllData() async throws -> DashboardSummary {
        // Force refresh all dashboard data
        return try await getDashboardSummary()
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateTotalBalance(from accounts: [AccountSummary]) -> Money {
        let total = accounts.reduce(0.0) { $0 + $1.balance.amount }
        return Money(amount: total, currency: "USD")
    }
    
    private func calculateMonthlySpending(from transactions: [Transaction]) -> Money {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let monthlyTotal = transactions
            .filter { $0.date >= startOfMonth && $0.amount.amount < 0 }
            .reduce(0.0) { $0 + abs($1.amount.amount) }
        
        return Money(amount: monthlyTotal, currency: "USD")
    }
}

// MARK: - Model Mapping Extensions
// Converting from generated API models to local domain models

extension TransactionListResponse {
    var domainTransactions: [Transaction] {
        return transactions.map { apiTransaction in
            Transaction(
                id: String(apiTransaction.id),
                amount: Money(amount: apiTransaction.amount, currency: apiTransaction.currencyCode),
                description: apiTransaction.name,
                date: apiTransaction.date,
                category: apiTransaction.primaryCategory,
                accountId: String(apiTransaction.account.id)
            )
        }
    }
}

extension AccountListResponse {
    var domainAccounts: [AccountSummary] {
        return accounts.map { apiAccount in
            AccountSummary(
                id: String(apiAccount.id),
                name: apiAccount.name,
                type: apiAccount.type,
                balance: Money(amount: apiAccount.currentBalance ?? 0.0, currency: apiAccount.currencyCode),
                lastSynced: apiAccount.lastUpdated
            )
        }
    }
}
