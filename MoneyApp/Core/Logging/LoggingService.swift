import Foundation
import FirebaseCrashlytics
import OSLog

// MARK: - Logging Service Protocol
protocol LoggingServiceProtocol: Sendable {
    func logInfo(_ message: String, category: String, file: String, function: String, line: Int) async
    func logWarning(_ message: String, category: String, file: String, function: String, line: Int) async
    func logError(_ error: Error, category: String, file: String, function: String, line: Int) async
    func logUserAction(_ action: String, parameters: [String: String]?) async
    func setUserIdentifier(_ userId: String) async
    func setCustomValue(_ value: String, forKey key: String) async
}

// MARK: - Logging Service Implementation
actor LoggingService: LoggingServiceProtocol {
    private let logger: Logger
    private let crashlytics: Crashlytics
    
    init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyApp", category: "general")
        self.crashlytics = Crashlytics.crashlytics()
    }
    
    func logInfo(_ message: String, category: String, file: String, function: String, line: Int) async {
        let logMessage = "[\(category)] \(message) - \(file):\(line) \(function)"
        logger.info("\(logMessage)")
    }
    
    func logWarning(_ message: String, category: String, file: String, function: String, line: Int) async {
        let logMessage = "[\(category)] \(message) - \(file):\(line) \(function)"
        logger.warning("\(logMessage)")
    }
    
    func logError(_ error: Error, category: String, file: String, function: String, line: Int) async {
        let logMessage = "[\(category)] \(error.localizedDescription) - \(file):\(line) \(function)"
        logger.error("\(logMessage)")
        
        // Log to Crashlytics for crash reporting
        crashlytics.record(error: error)
    }
    
    func logUserAction(_ action: String, parameters: [String: String]? = nil) async {
        var logMessage = "User Action: \(action)"
        if let parameters = parameters {
            let paramString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " [\(paramString)]"
        }
        logger.info("\(logMessage)")
        
        // Log to Crashlytics for analytics
        if let parameters = parameters {
            crashlytics.log("\(logMessage)")
        }
    }
    
    func setUserIdentifier(_ userId: String) async {
        crashlytics.setUserID(userId)
        logger.info("User ID set: \(userId)")
    }
    
    func setCustomValue(_ value: String, forKey key: String) async {
        crashlytics.setCustomValue(value, forKey: key)
        logger.info("Custom value set: \(key) = \(value)")
    }
}

// MARK: - Global Logging Functions
private let loggingService = LoggingService()

/// Log an informational message
func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await loggingService.logInfo(message, category: category, file: file, function: function, line: line)
    }
}

/// Log a warning message
func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await loggingService.logWarning(message, category: category, file: file, function: function, line: line)
    }
}

/// Log an error
func logError(_ error: Error, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await loggingService.logError(error, category: category, file: file, function: function, line: line)
    }
}

/// Log a user action with optional parameters
func logUserAction(_ action: String, parameters: [String: String]? = nil) {
    Task {
        await loggingService.logUserAction(action, parameters: parameters)
    }
}

/// Set the user identifier for crash reporting
func setUserIdentifier(_ userId: String) {
    Task {
        await loggingService.setUserIdentifier(userId)
    }
}

/// Set a custom value for crash reporting
func setCustomValue(_ value: String, forKey key: String) {
    Task {
        await loggingService.setCustomValue(value, forKey: key)
    }
} 
