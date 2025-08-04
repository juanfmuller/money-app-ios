import Foundation

// MARK: - Logging Manager
@MainActor
class LoggingManager {
    static let shared = LoggingManager()
    
    private let loggingService: LoggingServiceProtocol
    
    private init() {
        self.loggingService = LoggingService()
    }
    
    // MARK: - Convenience Methods
    func logInfo(_ message: String, category: String = "General") {
        Task {
            await loggingService.logInfo(message, category: category)
        }
    }
    
    func logWarning(_ message: String, category: String = "General") {
        Task {
            await loggingService.logWarning(message, category: category)
        }
    }
    
    func logError(_ error: Error, category: String = "General") {
        Task {
            await loggingService.logError(error, category: category)
        }
    }
    
    func logUserAction(_ action: String, parameters: [String: Any]? = nil) {
        Task {
            await loggingService.logUserAction(action, parameters: parameters)
        }
    }
    
    func setUserIdentifier(_ userId: String) {
        Task {
            await loggingService.setUserIdentifier(userId)
        }
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        Task {
            await loggingService.setCustomValue(value, forKey: key)
        }
    }
}

// MARK: - Global Logging Functions
func logInfo(_ message: String, category: String = "General") {
    LoggingManager.shared.logInfo(message, category: category)
}

func logWarning(_ message: String, category: String = "General") {
    LoggingManager.shared.logWarning(message, category: category)
}

func logError(_ error: Error, category: String = "General") {
    LoggingManager.shared.logError(error, category: category)
}

func logUserAction(_ action: String, parameters: [String: Any]? = nil) {
    LoggingManager.shared.logUserAction(action, parameters: parameters)
} 