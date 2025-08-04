import Foundation
import FirebaseCrashlytics
import OSLog

// MARK: - Logging Service Protocol
protocol LoggingServiceProtocol: Sendable {
    func logInfo(_ message: String, category: String, file: String, function: String, line: Int)
    func logWarning(_ message: String, category: String, file: String, function: String, line: Int)
    func logError(_ error: Error, category: String, file: String, function: String, line: Int)
    func logUserAction(_ action: String, parameters: [String: Any]?)
    func setUserIdentifier(_ userId: String)
    func setCustomValue(_ value: Any, forKey key: String)
}

// MARK: - Logging Service Implementation
actor LoggingService: LoggingServiceProtocol {
    private let crashlytics = Crashlytics.crashlytics()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyApp", category: "default")
    
    func logInfo(_ message: String, category: String, file: String, function: String, line: Int) {
        let logMessage = "[\(category)] \(message) - \(file):\(line) \(function)"
        logger.info("\(logMessage)")
        crashlytics.log(logMessage)
    }
    
    func logWarning(_ message: String, category: String, file: String, function: String, line: Int) {
        let logMessage = "[\(category)] WARNING: \(message) - \(file):\(line) \(function)"
        logger.warning("\(logMessage)")
        crashlytics.log(logMessage)
    }
    
    func logError(_ error: Error, category: String, file: String, function: String, line: Int) {
        let logMessage = "[\(category)] ERROR: \(error.localizedDescription) - \(file):\(line) \(function)"
        logger.error("\(logMessage)")
        crashlytics.record(error: error)
    }
    
    func logUserAction(_ action: String, parameters: [String: Any]? = nil) {
        let logMessage = "USER_ACTION: \(action)"
        logger.info("\(logMessage)")
        crashlytics.log(logMessage)
        
        if let parameters = parameters {
            for (key, value) in parameters {
                crashlytics.setCustomValue(value, forKey: "action_\(key)")
            }
        }
    }
    
    func setUserIdentifier(_ userId: String) {
        crashlytics.setUserID(userId)
        logger.info("User ID set: \(userId)")
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        crashlytics.setCustomValue(value, forKey: key)
    }
}

// MARK: - Convenience Extensions
extension LoggingServiceProtocol {
    func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        logInfo(message, category: category, file: file, function: function, line: line)
    }
    
    func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        logWarning(message, category: category, file: file, function: function, line: line)
    }
    
    func logError(_ error: Error, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        logError(error, category: category, file: file, function: function, line: line)
    }
} 