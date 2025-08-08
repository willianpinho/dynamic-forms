import Foundation

/// Main Utilities module providing access to all utility functions and extensions
/// Following SOLID principles with clear separation of concerns
public struct Utilities {
    
    /// Utilities version for compatibility tracking
    public static let version = "1.0.0"
    
    /// Initialize utilities with default configuration
    public static func configure() {
        // Configure any global utility settings
        setupLogging()
        setupDateFormatters()
    }
    
    // MARK: - Private Configuration
    private static func setupLogging() {
        // Configure logging utilities if needed
    }
    
    private static func setupDateFormatters() {
        // Configure global date formatters for consistency
    }
}

// MARK: - Common Error Types
public enum UtilityError: Error, LocalizedError {
    case invalidFormat(String)
    case conversionFailed(String)
    case validationFailed(String)
    case networkError(String)
    case storageError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        }
    }
}

// MARK: - Logger Protocol
public protocol Logger {
    func log(_ message: String, level: LogLevel)
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

// MARK: - Default Console Logger
public struct ConsoleLogger: Logger {
    public init() {}
    
    public func log(_ message: String, level: LogLevel) {
        let timestamp = DateFormatter.timestamp.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] \(message)")
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
}

// MARK: - Date Formatter Extensions
public extension DateFormatter {
    
    /// ISO 8601 date formatter
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// Simple date formatter (YYYY-MM-DD)
    static let simpleDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Display date formatter for UI
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Timestamp formatter for logging
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - Thread Safety Utilities
public final class ThreadSafeContainer<T> {
    private var _value: T
    private let queue = DispatchQueue(label: "ThreadSafeContainer", attributes: .concurrent)
    
    public init(_ value: T) {
        self._value = value
    }
    
    public var value: T {
        queue.sync { _value }
    }
    
    public func setValue(_ newValue: T) {
        queue.async(flags: .barrier) {
            self._value = newValue
        }
    }
    
    public func mutate(_ mutation: @escaping (inout T) -> Void) {
        queue.async(flags: .barrier) {
            mutation(&self._value)
        }
    }
}

// MARK: - Weak Reference Wrapper
public final class WeakReference<T: AnyObject> {
    public weak var value: T?
    
    public init(_ value: T) {
        self.value = value
    }
}

// MARK: - Debouncer
public final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    public func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
    public func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}