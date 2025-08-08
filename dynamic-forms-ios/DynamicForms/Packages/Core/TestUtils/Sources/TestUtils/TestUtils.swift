import Foundation
import Utilities

/// Test utilities for Dynamic Forms project
/// Provides common testing helpers and mock objects
public struct TestUtils {
    
    /// TestUtils version
    public static let version = "1.0.0"
    
    /// Initialize test utilities
    public static func configure() {
        setupMockLogger()
        setupTestEnvironment()
    }
    
    private static func setupMockLogger() {
        // Configure mock logger for tests
    }
    
    private static func setupTestEnvironment() {
        // Configure test environment
    }
}

// MARK: - Mock Logger
public final class MockLogger: Logger {
    private var loggedMessages: [(String, LogLevel)] = []
    
    public init() {}
    
    public func log(_ message: String, level: LogLevel) {
        loggedMessages.append((message, level))
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
    
    public func getLoggedMessages() -> [(String, LogLevel)] {
        return loggedMessages
    }
    
    public func clearLogs() {
        loggedMessages.removeAll()
    }
}

// MARK: - Test Helpers
public extension String {
    static func random(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

public extension Date {
    static var testDate: Date {
        return Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
    }
}