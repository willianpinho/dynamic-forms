import XCTest
@testable import TestUtils

final class TestUtilsTests: XCTestCase {
    
    func testMockLoggerLogsMessages() {
        let mockLogger = MockLogger()
        
        mockLogger.debug("Debug message")
        mockLogger.info("Info message")
        mockLogger.warning("Warning message")
        mockLogger.error("Error message")
        
        let loggedMessages = mockLogger.getLoggedMessages()
        
        XCTAssertEqual(loggedMessages.count, 4)
        XCTAssertEqual(loggedMessages[0].0, "Debug message")
        XCTAssertEqual(loggedMessages[1].0, "Info message")
        XCTAssertEqual(loggedMessages[2].0, "Warning message")
        XCTAssertEqual(loggedMessages[3].0, "Error message")
    }
    
    func testMockLoggerClearLogs() {
        let mockLogger = MockLogger()
        
        mockLogger.info("Test message")
        XCTAssertEqual(mockLogger.getLoggedMessages().count, 1)
        
        mockLogger.clearLogs()
        XCTAssertEqual(mockLogger.getLoggedMessages().count, 0)
    }
    
    func testRandomStringGeneration() {
        let randomString1 = String.random(length: 10)
        let randomString2 = String.random(length: 10)
        
        XCTAssertEqual(randomString1.count, 10)
        XCTAssertEqual(randomString2.count, 10)
        XCTAssertNotEqual(randomString1, randomString2)
    }
    
    func testTestDate() {
        let testDate = Date.testDate
        let expectedDate = Date(timeIntervalSince1970: 1640995200)
        
        XCTAssertEqual(testDate, expectedDate)
    }
}