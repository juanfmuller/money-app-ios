//
//  HomeView.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && !viewModel.hasData {
                        loadingView
                    } else if viewModel.shouldShowEmptyState {
                        emptyStateView
                    } else {
                        dashboardContent
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .onAppear {
                viewModel.router = router
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your dashboard...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to Money App!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Connect your accounts to get started with tracking your finances.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Link Your First Account") {
                viewModel.handleQuickAction(.linkAccount)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Dashboard Content
    private var dashboardContent: some View {
        VStack(spacing: 24) {
            balanceSummaryCard
            quickActionsSection
            recentTransactionsSection
            accountSummariesSection
        }
    }
    
    // MARK: - Balance Summary Card
    private var balanceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Total Balance")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if viewModel.isPolling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text(viewModel.totalBalanceText)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Text("Monthly Spending:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.monthlySpendingText)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.quickActions, id: \.title) { action in
                    Button {
                        viewModel.handleQuickAction(action)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: action.systemImage)
                                .font(.title2)
                            Text(action.title)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    viewModel.showAllTransactions()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let transactions = viewModel.dashboardSummary?.recentTransactions, !transactions.isEmpty {
                ForEach(transactions) { transaction in
                    transactionRow(transaction)
                }
            } else {
                Text("No recent transactions")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            }
        }
    }
    
    // MARK: - Account Summaries Section
    private var accountSummariesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accounts")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    viewModel.showAllAccounts()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let accounts = viewModel.dashboardSummary?.accountSummaries, !accounts.isEmpty {
                ForEach(accounts) { account in
                    accountRow(account)
                }
            } else {
                Text("No accounts connected")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            }
        }
    }
    
    // MARK: - Transaction Row
    private func transactionRow(_ transaction: Transaction) -> some View {
        Button {
            viewModel.showTransactionDetail(transactionId: transaction.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.body)
                        .foregroundColor(.primary)
                    if let category = transaction.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(transaction.amount.formattedAmount)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(transaction.amount.amount >= 0 ? .green : .primary)
                    
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Account Row
    private func accountRow(_ account: AccountSummary) -> some View {
        Button {
            viewModel.showAccountDetail(accountId: account.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(account.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(account.balance.formattedAmount)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment(AppRouter())
}
