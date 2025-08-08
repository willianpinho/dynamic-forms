import Foundation
@testable import Domain

/// Factory for creating test data objects
/// Following Factory Pattern for consistent test data creation
public final class TestDataFactory {
    
    // MARK: - FormField Factory Methods
    
    public static func createTextField(
        uuid: String = "text-field-\(UUID().uuidString)",
        name: String = "testField",
        label: String = "Test Field",
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField.textField(
            uuid: uuid,
            name: name,
            label: label,
            required: required,
            value: value
        )
    }
    
    public static func createNumberField(
        uuid: String = "number-field-\(UUID().uuidString)",
        name: String = "numberField",
        label: String = "Number Field",
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField.numberField(
            uuid: uuid,
            name: name,
            label: label,
            required: required,
            value: value
        )
    }
    
    public static func createEmailField(
        uuid: String = "email-field-\(UUID().uuidString)",
        name: String = "emailField",
        label: String = "Email Field",
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField.emailField(
            uuid: uuid,
            name: name,
            label: label,
            required: required,
            value: value
        )
    }
    
    public static func createDropdownField(
        uuid: String = "dropdown-field-\(UUID().uuidString)",
        name: String = "dropdownField",
        label: String = "Dropdown Field",
        required: Bool = false,
        options: [FieldOption] = [
            FieldOption(label: "Option 1", value: "option1"),
            FieldOption(label: "Option 2", value: "option2")
        ],
        value: String = ""
    ) -> FormField {
        return FormField.dropdownField(
            uuid: uuid,
            name: name,
            label: label,
            required: required,
            options: options,
            value: value
        )
    }
    
    // MARK: - FormSection Factory Methods
    
    public static func createFormSection(
        uuid: String = "section-\(UUID().uuidString)",
        title: String = "Test Section",
        from: Int = 0,
        to: Int = 1,
        index: Int = 0,
        fields: [FormField] = []
    ) -> FormSection {
        return FormSection(
            uuid: uuid,
            title: title,
            from: from,
            to: to,
            index: index,
            fields: fields
        )
    }
    
    // MARK: - DynamicForm Factory Methods
    
    public static func createSimpleForm(
        id: String = "test-form-\(UUID().uuidString)",
        title: String = "Test Form",
        fieldCount: Int = 3
    ) -> DynamicForm {
        let fields = (0..<fieldCount).map { index in
            createTextField(
                uuid: "field-\(index)",
                name: "field\(index)",
                label: "Field \(index + 1)",
                required: index == 0 // First field is required
            )
        }
        
        let sections = [
            createFormSection(
                uuid: "section-1",
                title: "Section 1",
                from: 0,
                to: fieldCount - 1,
                index: 0
            )
        ]
        
        return DynamicForm(
            id: id,
            title: title,
            fields: fields,
            sections: sections
        )
    }
    
    public static func createComplexForm(
        id: String = "complex-form-\(UUID().uuidString)",
        title: String = "Complex Test Form"
    ) -> DynamicForm {
        let fields = [
            createTextField(
                uuid: "name-field",
                name: "fullName",
                label: "Full Name",
                required: true
            ),
            createEmailField(
                uuid: "email-field",
                name: "email",
                label: "Email Address",
                required: true
            ),
            createNumberField(
                uuid: "age-field",
                name: "age",
                label: "Age",
                required: false
            ),
            createDropdownField(
                uuid: "country-field",
                name: "country",
                label: "Country",
                required: true,
                options: [
                    FieldOption(label: "United States", value: "us"),
                    FieldOption(label: "Canada", value: "ca"),
                    FieldOption(label: "United Kingdom", value: "uk")
                ]
            ),
            createTextField(
                uuid: "comments-field",
                name: "comments",
                label: "Comments",
                required: false
            )
        ]
        
        let sections = [
            createFormSection(
                uuid: "personal-info",
                title: "Personal Information",
                from: 0,
                to: 2,
                index: 0
            ),
            createFormSection(
                uuid: "additional-info",
                title: "Additional Information",
                from: 3,
                to: 4,
                index: 1
            )
        ]
        
        return DynamicForm(
            id: id,
            title: title,
            fields: fields,
            sections: sections
        )
    }
    
    // MARK: - FormEntry Factory Methods
    
    public static func createDraftEntry(
        id: String = "draft-\(UUID().uuidString)",
        formId: String = "test-form",
        fieldValues: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: nil,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isComplete: false,
            isDraft: true
        )
    }
    
    public static func createCompletedEntry(
        id: String = "entry-\(UUID().uuidString)",
        formId: String = "test-form",
        fieldValues: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: nil,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isComplete: true,
            isDraft: false
        )
    }
    
    public static func createEditDraftEntry(
        id: String = "edit-draft-\(UUID().uuidString)",
        formId: String = "test-form",
        sourceEntryId: String,
        fieldValues: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isComplete: false,
            isDraft: true
        )
    }
    
    public static func createEntryWithValidData(
        id: String = "valid-entry-\(UUID().uuidString)",
        formId: String = "test-form"
    ) -> FormEntry {
        let fieldValues = [
            "name-field": "John Doe",
            "email-field": "john.doe@example.com",
            "age-field": "30",
            "country-field": "us"
        ]
        
        return createCompletedEntry(
            id: id,
            formId: formId,
            fieldValues: fieldValues
        )
    }
    
    public static func createEntryWithIncompleteData(
        id: String = "incomplete-entry-\(UUID().uuidString)",
        formId: String = "test-form"
    ) -> FormEntry {
        let fieldValues = [
            "name-field": "John Doe",
            "email-field": "" // Missing required email
        ]
        
        return createDraftEntry(
            id: id,
            formId: formId,
            fieldValues: fieldValues
        )
    }
    
    // MARK: - Batch Data Factory Methods
    
    public static func createMultipleForms(count: Int = 3) -> [DynamicForm] {
        return (0..<count).map { index in
            createSimpleForm(
                id: "form-\(index)",
                title: "Test Form \(index + 1)",
                fieldCount: 2 + index
            )
        }
    }
    
    public static func createMultipleEntries(
        formId: String = "test-form",
        count: Int = 3,
        draftCount: Int = 1
    ) -> [FormEntry] {
        var entries: [FormEntry] = []
        
        // Create completed entries
        for i in 0..<(count - draftCount) {
            let entry = createCompletedEntry(
                id: "entry-\(i)",
                formId: formId,
                fieldValues: ["field-0": "Value \(i)"]
            )
            entries.append(entry)
        }
        
        // Create draft entries
        for i in 0..<draftCount {
            let entry = createDraftEntry(
                id: "draft-\(i)",
                formId: formId,
                fieldValues: ["field-0": "Draft Value \(i)"]
            )
            entries.append(entry)
        }
        
        return entries
    }
    
    // MARK: - Date Helper Methods
    
    public static func dateFromDaysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
    
    public static func dateFromHoursAgo(_ hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
    }
    
    public static func dateFromMinutesAgo(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: -minutes, to: Date()) ?? Date()
    }
    
    // MARK: - Validation Test Data
    
    public static func createFormWithValidationRules() -> DynamicForm {
        let fields = [
            createTextField(
                uuid: "required-text",
                name: "requiredText",
                label: "Required Text",
                required: true
            ),
            createEmailField(
                uuid: "email-validation",
                name: "email",
                label: "Email",
                required: true
            ),
            createNumberField(
                uuid: "number-validation",
                name: "age",
                label: "Age (1-120)",
                required: false
            ),
            createDropdownField(
                uuid: "dropdown-validation",
                name: "status",
                label: "Status",
                required: true,
                options: [
                    FieldOption(label: "Active", value: "active"),
                    FieldOption(label: "Inactive", value: "inactive")
                ]
            )
        ]
        
        let sections = [
            createFormSection(
                uuid: "validation-section",
                title: "Validation Test Section",
                from: 0,
                to: 3
            )
        ]
        
        return DynamicForm(
            id: "validation-form",
            title: "Validation Test Form",
            fields: fields,
            sections: sections
        )
    }
}

// MARK: - Test Assertion Helpers
public extension XCTestCase {
    
    /// Assert that a Result is successful
    func assertSuccess<T, E: Error>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> T? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)", file: file, line: line)
            return nil
        }
    }
    
    /// Assert that a Result is a failure
    func assertFailure<T, E: Error>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> E? {
        switch result {
        case .success(let value):
            XCTFail("Expected failure but got success: \(value)", file: file, line: line)
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// Assert that two dates are approximately equal (within tolerance)
    func assertDatesEqual(_ date1: Date, _ date2: Date, tolerance: TimeInterval = 1.0, file: StaticString = #file, line: UInt = #line) {
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(difference, tolerance, "Dates are not within tolerance", file: file, line: line)
    }
}

// MARK: - Import XCTest for test assertions
import XCTest
