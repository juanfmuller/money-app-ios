import Foundation
import FirebaseCore
import FirebaseCrashlytics

// MARK: - Firebase Configuration
class FirebaseConfig {
    static func configure() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Enable Crashlytics in debug builds for testing
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        
        // Set up custom keys for better crash analysis
        Crashlytics.crashlytics().setCustomValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown", forKey: "app_version")
        Crashlytics.crashlytics().setCustomValue(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown", forKey: "build_number")
        
        logInfo("Firebase configured successfully", category: "Configuration")
    }
} 