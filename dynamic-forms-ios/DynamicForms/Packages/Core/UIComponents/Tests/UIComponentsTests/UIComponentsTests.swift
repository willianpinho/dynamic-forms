import XCTest
@testable import UIComponents

final class UIComponentsTests: XCTestCase {
    
    func testUIComponentsConfiguration() {
        UIComponents.configure()
        XCTAssertEqual(UIComponents.version, "1.0.0")
    }
}