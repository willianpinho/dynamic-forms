import XCTest
@testable import Utilities

final class UtilitiesTests: XCTestCase {
    
    func testStringExtensions() {
        XCTAssertTrue("".isBlank)
        XCTAssertTrue("   ".isBlank)
        XCTAssertFalse("test".isBlank)
        XCTAssertTrue("test".isNotBlank)
    }
    
    func testThreadSafeContainer() {
        let container = ThreadSafeContainer<String>("initial")
        
        XCTAssertEqual(container.value, "initial")
        
        container.setValue("updated")
        XCTAssertEqual(container.value, "updated")
    }
}