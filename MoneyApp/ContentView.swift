//
//  ContentView.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    
    var body: some View {
        Group {
            switch router.currentScreen {
            case .auth:
                authView
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
        .environment(router)
    }
    
    // MARK: - Placeholder Views
    private var authView: some View {
        VStack(spacing: 20) {
            Text("Money App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Welcome! Authentication will be implemented in the next feature.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Go to Home (Demo)") {
                router.showMainApp()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
