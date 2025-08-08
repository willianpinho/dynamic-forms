import XCTest
@testable import Domain

final class DomainTests: XCTestCase {
    
    func testFormFieldCreation() {
        let field = FormField.textField(
            uuid: "test-field",
            name: "test",
            label: "Test Field",
            required: true,
            value: "test value"
        )
        
        XCTAssertEqual(field.uuid, "test-field")
        XCTAssertEqual(field.type, .text)
        XCTAssertEqual(field.name, "test")
        XCTAssertEqual(field.label, "Test Field")
        XCTAssertTrue(field.required)
        XCTAssertEqual(field.value, "test value")
    }
    
    func testFormEntryCreation() {
        let entry = FormEntry.newDraft(formId: "test-form")
        
        XCTAssertEqual(entry.formId, "test-form")
        XCTAssertTrue(entry.isDraft)
        XCTAssertFalse(entry.isComplete)
    }
}