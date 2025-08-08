import Foundation

/// Main Domain module providing access to all domain components
/// Following SOLID principles with clear separation of concerns
public struct Domain {
    
    /// Domain version for compatibility tracking
    public static let version = "1.0.0"
    
    /// Initialize domain with default configuration
    public static func configure() {
        // Configure any global domain settings
        setupValidation()
        setupModels()
    }
    
    // MARK: - Private Configuration
    private static func setupValidation() {
        // Configure validation settings if needed
    }
    
    private static func setupModels() {
        // Configure model behavior if needed
    }
}

// MARK: - Domain Constants
public extension Domain {
    
    /// Default configuration values
    struct Defaults {
        public static let autoSaveInterval: TimeInterval = 30.0
        public static let validationDebounceDelay: TimeInterval = 0.5
        public static let maxRetryAttempts: Int = 3
        public static let batchSize: Int = 100
    }
    
    /// Field validation limits
    struct ValidationLimits {
        public static let maxTextLength: Int = 255
        public static let maxTextAreaLength: Int = 2000
        public static let minPasswordLength: Int = 6
        public static let maxOptionsCount: Int = 100
    }
    
    /// Performance thresholds
    struct Performance {
        public static let largeFormFieldCount: Int = 50
        public static let virtualScrollThreshold: Int = 200
        public static let batchProcessingThreshold: Int = 20
    }
}

// MARK: - Domain Error Types
public enum DomainError: Error, LocalizedError {
    case invalidData(String)
    case businessRuleViolation(String)
    case resourceNotFound(String)
    case operationNotAllowed(String)
    case concurrencyConflict(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .businessRuleViolation(let message):
            return "Business rule violation: \(message)"
        case .resourceNotFound(let message):
            return "Resource not found: \(message)"
        case .operationNotAllowed(let message):
            return "Operation not allowed: \(message)"
        case .concurrencyConflict(let message):
            return "Concurrency conflict: \(message)"
        }
    }
}

// MARK: - Use Case Protocols
/// Shared protocol for auto-save functionality
/// This allows different implementations to be used interchangeably
public protocol AutoSaveFormEntryUseCaseProtocol {
    func execute(entry: FormEntry) async -> Result<Void, Error>
}

// MARK: - Domain Events (for future use)
public protocol DomainEvent {
    var eventId: String { get }
    var timestamp: Date { get }
    var eventType: String { get }
}

public struct FormCreatedEvent: DomainEvent {
    public let eventId: String = UUID().uuidString
    public let timestamp: Date = Date()
    public let eventType: String = "FormCreated"
    public let formId: String
    public let formTitle: String
    
    public init(formId: String, formTitle: String) {
        self.formId = formId
        self.formTitle = formTitle
    }
}

public struct EntrySubmittedEvent: DomainEvent {
    public let eventId: String = UUID().uuidString
    public let timestamp: Date = Date()
    public let eventType: String = "EntrySubmitted"
    public let entryId: String
    public let formId: String
    
    public init(entryId: String, formId: String) {
        self.entryId = entryId
        self.formId = formId
    }
}

public struct ValidationFailedEvent: DomainEvent {
    public let eventId: String = UUID().uuidString
    public let timestamp: Date = Date()
    public let eventType: String = "ValidationFailed"
    public let formId: String
    public let entryId: String
    public let errorCount: Int
    
    public init(formId: String, entryId: String, errorCount: Int) {
        self.formId = formId
        self.entryId = entryId
        self.errorCount = errorCount
    }
}
