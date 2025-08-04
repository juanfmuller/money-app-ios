//
//  AppConstants.swift
//  MoneyApp
//
//  Created by Juan Muller on 8/3/25.
//

import Foundation

/// Centralized app-wide constants.
/// Use these for static configuration values only.
/// Do not hardcode secrets or environment-specific values here.
enum AppConstants {
    /// The base URL for API requests.
    /// This is determined by the build configuration.
    static var apiBaseURL: URL {
        #if DEBUG
        return URL(string: "http://localhost:8000")!
        #else
        return URL(string: "https://api.money-app-backend.com")!
        #endif
    }

    /// The app's bundle identifier (for push, etc).
    static let bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.moneyapp.ios"

    /// The polling interval (in seconds) for real-time data updates.
    static let pollingInterval: TimeInterval = 3.0

    /// The keychain service name for secure storage.
    static let keychainService: String = "com.moneyapp.ios.keychain"

    /// The default timeout for API requests (in seconds).
    static let apiTimeout: TimeInterval = 15.0

    /// The app display name.
    static let appDisplayName: String = "Money App"
}

