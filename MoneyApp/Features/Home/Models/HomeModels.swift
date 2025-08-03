//
//  HomeModels.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import Foundation

// MARK: - Dashboard Summary Model
struct DashboardSummary: Codable, Sendable {
    let totalBalance: Money
    let monthlySpending: Money
    let recentTransactions: [Transaction]
    let accountSummaries: [AccountSummary]
}

// MARK: - Account Summary Model
struct AccountSummary: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let type: String
    let balance: Money
    let lastSynced: Date?
}

// MARK: - Transaction Model
struct Transaction: Codable, Sendable, Identifiable {
    let id: String
    let amount: Money
    let description: String
    let date: Date
    let category: String?
    let accountId: String
}

// MARK: - Money Model
struct Money: Codable, Sendable {
    let amount: Double
    let currency: String
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Quick Action Types
enum QuickAction: CaseIterable {
    case addTransaction
    case linkAccount
    case viewBudgets
    case payBills
    
    var title: String {
        switch self {
        case .addTransaction: return "Add Transaction"
        case .linkAccount: return "Link Account"
        case .viewBudgets: return "View Budgets"
        case .payBills: return "Pay Bills"
        }
    }
    
    var systemImage: String {
        switch self {
        case .addTransaction: return "plus.circle"
        case .linkAccount: return "link"
        case .viewBudgets: return "chart.pie"
        case .payBills: return "creditcard"
        }
    }
}