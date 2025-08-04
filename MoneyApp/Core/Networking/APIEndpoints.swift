//
//  APIEndpoints.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/3/25.
//

import Foundation

// MARK: - API Endpoints Enum

enum APIEndpoints {
    
    // MARK: - Authentication Endpoints
    
    enum Auth {
        static let login = "/api/auth/login"
        static let register = "/api/auth/register"
        static let logout = "/api/auth/logout"
        static let deviceToken = "/api/auth/device-token"
    }
    
    // MARK: - Account Management Endpoints
    
    enum Accounts {
        static let list = "/api/accounts"
        static let linkToken = "/api/accounts/link/token"
        static let linkExchange = "/api/accounts/link/exchange"
        static let sync = "/api/accounts/sync"
        static let syncStatus = "/api/accounts/sync/status"
    }
    
    // MARK: - Transaction Endpoints
    
    enum Transactions {
        static let list = "/api/transactions"
        static let recent = "/api/transactions/recent"
        static let summary = "/api/transactions/summary"
        static let categories = "/api/transactions/categories"
    }
    
    // MARK: - Notification Endpoints
    
    enum Notifications {
        static let test = "/api/notifications/test"
        static let preferences = "/api/notifications/preferences"
    }
}

