import XCTest
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {
    
    func testDesignSystemConfiguration() {
        DesignSystem.configure()
        XCTAssertEqual(DesignSystem.version, "1.0.0")
    }
}