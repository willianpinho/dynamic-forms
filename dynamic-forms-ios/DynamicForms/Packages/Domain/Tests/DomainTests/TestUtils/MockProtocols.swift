import Foundation
import Utilities
@testable import Domain

// MARK: - AutoSaveFormEntryUseCase Protocol
@available(iOS 13.0, macOS 10.15, *)
public protocol AutoSaveFormEntryUseCaseProtocol {
    func execute(entry: FormEntry) async -> Result<Void, Error>
    func scheduleAutoSave(for entry: FormEntry)
    func cancelScheduledAutoSave(for entryId: String)
    func executeWithRetry(entry: FormEntry) async -> Result<Void, Error>
    func batchAutoSave(entries: [FormEntry]) async -> Result<[String], Error>
    func getStatistics() -> AutoSaveStatistics
    func cancelAllPendingAutoSaves()
}

// MARK: - Logger Protocol (Re-exported from Utilities)
// Using the Logger protocol from Utilities module

// MARK: - Console Logger Implementation (Using Utilities)
// ConsoleLogger is now imported from Utilities module

// MARK: - String Extension for Blank Check
public extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - FieldValidator Mock Implementation
public struct FieldValidator {
    
    public enum FieldType {
        case text
        case number
        case email
        case dropdown
        case other
        
        public static func from(_ rawValue: String) -> FieldType {
            switch rawValue.lowercased() {
            case "text":
                return .text
            case "number":
                return .number
            case "email":
                return .email
            case "dropdown":
                return .dropdown
            default:
                return .other
            }
        }
    }
    
    public struct ValidationResult {
        public let isValid: Bool
        public let errorMessage: String?
        
        public init(isValid: Bool, errorMessage: String? = nil) {
            self.isValid = isValid
            self.errorMessage = errorMessage
        }
    }
    
    public static func validateField(
        value: String,
        fieldType: FieldType,
        isRequired: Bool,
        options: [String] = [],
        fieldName: String
    ) -> ValidationResult {
        
        // Check if required field is empty
        if isRequired && value.isBlank {
            return ValidationResult(isValid: false, errorMessage: "\(fieldName) is required")
        }
        
        // If empty and not required, it's valid
        if value.isBlank {
            return ValidationResult(isValid: true)
        }
        
        // Type-specific validation
        switch fieldType {
        case .email:
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: value) {
                return ValidationResult(isValid: false, errorMessage: "Invalid email format")
            }
            
        case .number:
            if Double(value) == nil {
                return ValidationResult(isValid: false, errorMessage: "Must be a valid number")
            }
            
        case .dropdown:
            if !options.contains(value) {
                return ValidationResult(isValid: false, errorMessage: "Invalid selection")
            }
            
        case .text, .other:
            break // Text fields are generally valid if not empty
        }
        
        return ValidationResult(isValid: true)
    }
}

// MARK: - FormField Factory Extensions for Testing
public extension FormField {
    
    static func textField(
        uuid: String,
        name: String,
        label: String,
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .text,
            name: name,
            label: label,
            required: required,
            options: [],
            value: value,
            validationError: nil
        )
    }
    
    static func numberField(
        uuid: String,
        name: String,
        label: String,
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .number,
            name: name,
            label: label,
            required: required,
            options: [],
            value: value,
            validationError: nil
        )
    }
    
    static func emailField(
        uuid: String,
        name: String,
        label: String,
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .email,
            name: name,
            label: label,
            required: required,
            options: [],
            value: value,
            validationError: nil
        )
    }
    
    static func dropdownField(
        uuid: String,
        name: String,
        label: String,
        required: Bool = false,
        options: [FieldOption] = [],
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .dropdown,
            name: name,
            label: label,
            required: required,
            options: options,
            value: value,
            validationError: nil
        )
    }
}

// MARK: - SectionProgress for ValidateFormEntryUseCase
public struct SectionProgress: Sendable {
    public let sectionId: String
    public let completedFields: Int
    public let totalFields: Int
    public let requiredFields: Int
    public let completedRequiredFields: Int
    public let hasErrors: Bool
    
    public init(
        sectionId: String,
        completedFields: Int,
        totalFields: Int,
        requiredFields: Int,
        completedRequiredFields: Int,
        hasErrors: Bool
    ) {
        self.sectionId = sectionId
        self.completedFields = completedFields
        self.totalFields = totalFields
        self.requiredFields = requiredFields
        self.completedRequiredFields = completedRequiredFields
        self.hasErrors = hasErrors
    }
}

// MARK: - Mock Logger
public final class MockLogger: Logger, @unchecked Sendable {
    
    private var logMessages: [LogMessage] = []
    private let queue = DispatchQueue(label: "MockLogger", attributes: .concurrent)
    
    public init() {}
    
    public func log(_ message: String, level: LogLevel) {
        let mockLevel = MockLogLevel.from(level)
        let logMessage = LogMessage(level: mockLevel, message: message)
        
        queue.async(flags: .barrier) {
            self.logMessages.append(logMessage)
        }
        
        print("[\(level.rawValue)] \(message)")
    }
    
    public func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    public func info(_ message: String) {
        log(message, level: .info)
    }
    
    public func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    public func error(_ message: String) {
        log(message, level: .error)
    }
    
    // Test helpers
    public func getLogMessages() -> [LogMessage] {
        return queue.sync {
            return logMessages
        }
    }
    
    public func clearLogs() {
        queue.sync(flags: .barrier) {
            self.logMessages.removeAll()
        }
    }
    
    public func getLogCount(for level: MockLogLevel) -> Int {
        return queue.sync {
            return logMessages.filter { $0.level == level }.count
        }
    }
    
    public func hasLogMessage(containing text: String) -> Bool {
        return queue.sync {
            return logMessages.contains { $0.message.contains(text) }
        }
    }
}

// MARK: - Logger Support Types
public enum MockLogLevel: Sendable {
    case debug
    case info
    case warning
    case error
    
    static func from(_ utilityLevel: LogLevel) -> MockLogLevel {
        switch utilityLevel {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}

public struct LogMessage: Sendable {
    public let level: MockLogLevel
    public let message: String
    public let timestamp: Date
    
    public init(level: MockLogLevel, message: String, timestamp: Date = Date()) {
        self.level = level
        self.message = message
        self.timestamp = timestamp
    }
}
