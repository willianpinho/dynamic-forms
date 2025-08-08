import XCTest
import Combine
@testable import Domain

/// Comprehensive tests for ValidateFormEntryUseCase
/// Following Test-Driven Development and Clean Code principles
final class ValidateFormEntryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var useCase: ValidateFormEntryUseCase!
    private var testForm: DynamicForm!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        useCase = ValidateFormEntryUseCase()
        testForm = TestDataFactory.createFormWithValidationRules()
    }
    
    override func tearDown() {
        useCase = nil
        testForm = nil
        super.tearDown()
    }
    
    // MARK: - Test Execute Method
    
    func testExecute_WithValidEntry_ShouldReturnNoErrors() {
        // Given
        let validEntry = TestDataFactory.createCompletedEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "number-validation": "25",
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let errors = useCase.execute(form: testForm, entry: validEntry)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testExecute_WithMissingRequiredFields_ShouldReturnErrors() {
        // Given
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "", // Missing required field
                "email-validation": "user@example.com",
                "dropdown-validation": "" // Missing required field
            ]
        )
        
        // When
        let errors = useCase.execute(form: testForm, entry: invalidEntry)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        
        // Should have errors for missing required fields
        let errorFieldIds = errors.map { $0.fieldUuid }
        XCTAssertTrue(errorFieldIds.contains("required-text"))
        XCTAssertTrue(errorFieldIds.contains("dropdown-validation"))
        XCTAssertFalse(errorFieldIds.contains("email-validation")) // Valid email
    }
    
    func testExecute_WithInvalidFieldFormats_ShouldReturnErrors() {
        // Given
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "invalid-email-format", // Invalid email
                "number-validation": "not-a-number", // Invalid number
                "dropdown-validation": "invalid-option" // Invalid dropdown option
            ]
        )
        
        // When
        let errors = useCase.execute(form: testForm, entry: invalidEntry)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        
        // Should have errors for invalid formats
        let errorFieldIds = errors.map { $0.fieldUuid }
        XCTAssertTrue(errorFieldIds.contains("email-validation"))
        XCTAssertTrue(errorFieldIds.contains("dropdown-validation"))
        XCTAssertFalse(errorFieldIds.contains("required-text")) // Valid text
    }
    
    func testExecute_WithOptionalFieldsEmpty_ShouldNotReturnErrors() {
        // Given
        let entryWithEmptyOptionals = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "number-validation": "", // Optional field, empty is OK
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let errors = useCase.execute(form: testForm, entry: entryWithEmptyOptionals)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testExecute_WithOnlyFieldsInSections_ShouldValidateCorrectly() {
        // Given
        let formWithSections = TestDataFactory.createComplexForm()
        let validEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "name-field": "John Doe",
                "email-field": "john@example.com",
                "country-field": "us"
            ]
        )
        
        // When
        let errors = useCase.execute(form: formWithSections, entry: validEntry)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    // MARK: - Test Validate Field
    
    func testValidateField_WithValidTextField_ShouldReturnValid() {
        // Given
        let textField = TestDataFactory.createTextField(
            label: "Test Field",
            required: true
        )
        let validValue = "Valid text input"
        
        // When
        let result = useCase.validateField(textField, value: validValue)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateField_WithEmptyRequiredField_ShouldReturnInvalid() {
        // Given
        let requiredField = TestDataFactory.createTextField(
            label: "Required Field",
            required: true
        )
        let emptyValue = ""
        
        // When
        let result = useCase.validateField(requiredField, value: emptyValue)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("required") ?? false)
    }
    
    func testValidateField_WithEmptyOptionalField_ShouldReturnValid() {
        // Given
        let optionalField = TestDataFactory.createTextField(
            label: "Optional Field",
            required: false
        )
        let emptyValue = ""
        
        // When
        let result = useCase.validateField(optionalField, value: emptyValue)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateField_WithInvalidEmailFormat_ShouldReturnInvalid() {
        // Given
        let emailField = TestDataFactory.createEmailField(
            label: "Email Field",
            required: true
        )
        let invalidEmail = "not-an-email"
        
        // When
        let result = useCase.validateField(emailField, value: invalidEmail)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateField_WithValidEmailFormat_ShouldReturnValid() {
        // Given
        let emailField = TestDataFactory.createEmailField(
            label: "Email Field",
            required: true
        )
        let validEmail = "user@example.com"
        
        // When
        let result = useCase.validateField(emailField, value: validEmail)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateField_WithValidDropdownOption_ShouldReturnValid() {
        // Given
        let dropdownField = TestDataFactory.createDropdownField(
            options: [
                FieldOption(label: "Option 1", value: "option1"),
                FieldOption(label: "Option 2", value: "option2")
            ]
        )
        let validOption = "option1"
        
        // When
        let result = useCase.validateField(dropdownField, value: validOption)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateField_WithInvalidDropdownOption_ShouldReturnInvalid() {
        // Given
        let dropdownField = TestDataFactory.createDropdownField(
            options: [
                FieldOption(label: "Option 1", value: "option1"),
                FieldOption(label: "Option 2", value: "option2")
            ]
        )
        let invalidOption = "invalid-option"
        
        // When
        let result = useCase.validateField(dropdownField, value: invalidOption)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    // MARK: - Test Validate Batch
    
    func testValidateBatch_WithMixedValidAndInvalidEntries_ShouldReturnCorrectResults() {
        // Given
        let validEntry = TestDataFactory.createCompletedEntry(
            id: "valid-entry",
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "dropdown-validation": "active"
            ]
        )
        
        let invalidEntry = TestDataFactory.createDraftEntry(
            id: "invalid-entry",
            fieldValues: [
                "required-text": "", // Missing required
                "email-validation": "invalid-email",
                "dropdown-validation": "active"
            ]
        )
        
        let entries = [validEntry, invalidEntry]
        
        // When
        let results = useCase.validateBatch(form: testForm, entries: entries)
        
        // Then
        XCTAssertEqual(results.count, 1) // Only invalid entry should have errors
        XCTAssertTrue(results.keys.contains("invalid-entry"))
        XCTAssertFalse(results.keys.contains("valid-entry"))
        
        let invalidEntryErrors = results["invalid-entry"] ?? []
        XCTAssertFalse(invalidEntryErrors.isEmpty)
    }
    
    func testValidateBatch_WithAllValidEntries_ShouldReturnEmptyResults() {
        // Given
        let validEntries = [
            TestDataFactory.createCompletedEntry(
                id: "valid1",
                fieldValues: [
                    "required-text": "Valid text 1",
                    "email-validation": "user1@example.com",
                    "dropdown-validation": "active"
                ]
            ),
            TestDataFactory.createCompletedEntry(
                id: "valid2",
                fieldValues: [
                    "required-text": "Valid text 2",
                    "email-validation": "user2@example.com",
                    "dropdown-validation": "inactive"
                ]
            )
        ]
        
        // When
        let results = useCase.validateBatch(form: testForm, entries: validEntries)
        
        // Then
        XCTAssertTrue(results.isEmpty)
    }
    
    func testValidateBatch_WithEmptyArray_ShouldReturnEmptyResults() {
        // Given
        let entries: [FormEntry] = []
        
        // When
        let results = useCase.validateBatch(form: testForm, entries: entries)
        
        // Then
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Test Is Valid For Submission
    
    func testIsValidForSubmission_WithValidEntry_ShouldReturnTrue() {
        // Given
        let validEntry = TestDataFactory.createCompletedEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let isValid = useCase.isValidForSubmission(form: testForm, entry: validEntry)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testIsValidForSubmission_WithInvalidEntry_ShouldReturnFalse() {
        // Given
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "", // Missing required
                "email-validation": "user@example.com",
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let isValid = useCase.isValidForSubmission(form: testForm, entry: invalidEntry)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Test Get Validation Summary
    
    func testGetValidationSummary_WithValidEntry_ShouldReturnValidSummary() {
        // Given
        let validEntry = TestDataFactory.createCompletedEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let summary = useCase.getValidationSummary(form: testForm, entry: validEntry)
        
        // Then
        XCTAssertTrue(summary.isValid)
        XCTAssertEqual(summary.errorCount, 0)
        XCTAssertTrue(summary.canSubmit)
        XCTAssertEqual(summary.completionPercentage, 1.0)
        XCTAssertTrue(summary.errors.isEmpty)
        
        // Check field statuses
        XCTAssertFalse(summary.fieldStatuses.isEmpty)
        let validStatuses = summary.fieldStatuses.filter { $0.status == .valid }
        XCTAssertEqual(validStatuses.count, summary.fieldStatuses.filter { $0.hasValue }.count)
    }
    
    func testGetValidationSummary_WithInvalidEntry_ShouldReturnInvalidSummary() {
        // Given
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "", // Missing required
                "email-validation": "invalid-email",
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let summary = useCase.getValidationSummary(form: testForm, entry: invalidEntry)
        
        // Then
        XCTAssertFalse(summary.isValid)
        XCTAssertGreaterThan(summary.errorCount, 0)
        XCTAssertFalse(summary.canSubmit)
        XCTAssertLessThan(summary.completionPercentage, 1.0)
        XCTAssertFalse(summary.errors.isEmpty)
        
        // Check field statuses
        let invalidStatuses = summary.fieldStatuses.filter { $0.status == .invalid }
        XCTAssertGreaterThan(invalidStatuses.count, 0)
        
        let requiredEmptyStatuses = summary.fieldStatuses.filter { $0.status == .requiredEmpty }
        XCTAssertGreaterThan(requiredEmptyStatuses.count, 0)
    }
    
    func testGetValidationSummary_WithPartialEntry_ShouldReturnPartialCompletion() {
        // Given
        let partialEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "Valid text", // Required field filled
                "email-validation": "user@example.com", // Required field filled
                "dropdown-validation": "" // Required field empty
            ]
        )
        
        // When
        let summary = useCase.getValidationSummary(form: testForm, entry: partialEntry)
        
        // Then
        XCTAssertFalse(summary.isValid)
        XCTAssertGreaterThan(summary.completionPercentage, 0.0)
        XCTAssertLessThan(summary.completionPercentage, 1.0)
        XCTAssertTrue(summary.hasPartialCompletion)
    }
    
    // MARK: - Test Validate Field Real Time
    
    func testValidateFieldRealTime_WithPartialValidation_ShouldBeLenient() {
        // Given
        let requiredField = TestDataFactory.createTextField(
            label: "Required Field",
            required: true
        )
        let emptyValue = ""
        
        // When
        let result = useCase.validateFieldRealTime(
            requiredField,
            value: emptyValue,
            isPartial: true
        )
        
        // Then
        XCTAssertTrue(result.isValid) // Should be lenient during typing
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateFieldRealTime_WithCompleteValidation_ShouldBeStrict() {
        // Given
        let requiredField = TestDataFactory.createTextField(
            label: "Required Field",
            required: true
        )
        let emptyValue = ""
        
        // When
        let result = useCase.validateFieldRealTime(
            requiredField,
            value: emptyValue,
            isPartial: false
        )
        
        // Then
        XCTAssertFalse(result.isValid) // Should be strict when not partial
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateFieldRealTime_WithValidValue_ShouldReturnValid() {
        // Given
        let emailField = TestDataFactory.createEmailField(required: true)
        let validEmail = "user@example.com"
        
        // When
        let result = useCase.validateFieldRealTime(
            emailField,
            value: validEmail,
            isPartial: true
        )
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    // MARK: - Test Validate Section
    
    func testValidateSection_WithValidSectionFields_ShouldReturnNoErrors() {
        // Given
        let complexForm = TestDataFactory.createComplexForm()
        let personalInfoSection = complexForm.sections.first { $0.title == "Personal Information" }!
        
        let validEntry = TestDataFactory.createCompletedEntry(
            fieldValues: [
                "name-field": "John Doe",
                "email-field": "john@example.com",
                "age-field": "30"
            ]
        )
        
        // When
        let errors = useCase.validateSection(
            form: complexForm,
            entry: validEntry,
            section: personalInfoSection
        )
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testValidateSection_WithInvalidSectionFields_ShouldReturnErrors() {
        // Given
        let complexForm = TestDataFactory.createComplexForm()
        let personalInfoSection = complexForm.sections.first { $0.title == "Personal Information" }!
        
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "name-field": "", // Missing required field in section
                "email-field": "invalid-email",
                "age-field": "30"
            ]
        )
        
        // When
        let errors = useCase.validateSection(
            form: complexForm,
            entry: invalidEntry,
            section: personalInfoSection
        )
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        
        let errorFieldIds = errors.map { $0.fieldUuid }
        XCTAssertTrue(errorFieldIds.contains("name-field"))
        XCTAssertTrue(errorFieldIds.contains("email-field"))
    }
    
    // MARK: - Test Extensions - Get Field Errors
    
    func testGetFieldErrors_ShouldReturnMappedErrors() {
        // Given
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "",
                "email-validation": "invalid-email"
            ]
        )
        
        // When
        let fieldErrors = useCase.getFieldErrors(form: testForm, entry: invalidEntry)
        
        // Then
        XCTAssertFalse(fieldErrors.isEmpty)
        XCTAssertTrue(fieldErrors.keys.contains("required-text"))
        XCTAssertTrue(fieldErrors.keys.contains("email-validation"))
        
        // Check error messages
        XCTAssertNotNil(fieldErrors["required-text"])
        XCTAssertNotNil(fieldErrors["email-validation"])
    }
    
    // MARK: - Test Extensions - Is Field Valid
    
    func testIsFieldValid_WithValidField_ShouldReturnTrue() {
        // Given
        let validEntry = TestDataFactory.createCompletedEntry(
            fieldValues: ["required-text": "Valid text"]
        )
        
        // When
        let isValid = useCase.isFieldValid(
            fieldUuid: "required-text",
            form: testForm,
            entry: validEntry
        )
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testIsFieldValid_WithInvalidField_ShouldReturnFalse() {
        // Given
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: ["required-text": ""]
        )
        
        // When
        let isValid = useCase.isFieldValid(
            fieldUuid: "required-text",
            form: testForm,
            entry: invalidEntry
        )
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testIsFieldValid_WithNonExistentField_ShouldReturnTrue() {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        
        // When
        let isValid = useCase.isFieldValid(
            fieldUuid: "non-existent-field",
            form: testForm,
            entry: entry
        )
        
        // Then
        XCTAssertTrue(isValid) // Non-existent fields are considered valid
    }
    
    // MARK: - Test Extensions - Get Errors By Sections
    
    func testGetErrorsBySections_ShouldGroupErrorsBySection() {
        // Given
        let complexForm = TestDataFactory.createComplexForm()
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "name-field": "", // Personal Info section
                "email-field": "invalid-email", // Personal Info section
                "country-field": "", // Additional Info section
                "comments-field": "Valid comment" // Additional Info section, valid
            ]
        )
        
        // When
        let sectionErrors = useCase.getErrorsBySections(form: complexForm, entry: invalidEntry)
        
        // Then
        XCTAssertFalse(sectionErrors.isEmpty)
        
        // Should have errors grouped by sections
        let personalInfoSection = complexForm.sections.first { $0.title == "Personal Information" }
        let additionalInfoSection = complexForm.sections.first { $0.title == "Additional Information" }
        
        if let personalSection = personalInfoSection {
            XCTAssertTrue(sectionErrors.keys.contains(personalSection.uuid))
            let personalErrors = sectionErrors[personalSection.uuid] ?? []
            XCTAssertGreaterThan(personalErrors.count, 0)
        }
        
        if let additionalSection = additionalInfoSection {
            XCTAssertTrue(sectionErrors.keys.contains(additionalSection.uuid))
            let additionalErrors = sectionErrors[additionalSection.uuid] ?? []
            XCTAssertGreaterThan(additionalErrors.count, 0)
        }
    }
    
    // MARK: - Test Extensions - Get Section Progress
    
    func testGetSectionProgress_ShouldReturnProgressForAllSections() {
        // Given
        let complexForm = TestDataFactory.createComplexForm()
        let partialEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "name-field": "John Doe", // Required, filled
                "email-field": "john@example.com", // Required, filled
                "age-field": "", // Optional, empty
                "country-field": "", // Required, empty
                "comments-field": "Some comments" // Optional, filled
            ]
        )
        
        // When
        let sectionProgress = useCase.getSectionProgress(form: complexForm, entry: partialEntry)
        
        // Then
        XCTAssertEqual(sectionProgress.count, complexForm.sections.count)
        
        for progress in sectionProgress {
            XCTAssertGreaterThanOrEqual(progress.totalFields, 0)
            XCTAssertGreaterThanOrEqual(progress.completedFields, 0)
            XCTAssertLessThanOrEqual(progress.completedFields, progress.totalFields)
            XCTAssertGreaterThanOrEqual(progress.requiredFields, 0)
            XCTAssertGreaterThanOrEqual(progress.completedRequiredFields, 0)
            XCTAssertLessThanOrEqual(progress.completedRequiredFields, progress.requiredFields)
        }
    }
    
    // MARK: - Test Supporting Types
    
    func testValidationSummary_CanSubmitLogic() {
        // Test canSubmit property logic
        let validSummary = ValidationSummary(
            isValid: true,
            errorCount: 0,
            requiredFieldsCount: 3,
            completedRequiredFieldsCount: 3,
            completionPercentage: 1.0,
            errors: [],
            fieldStatuses: []
        )
        XCTAssertTrue(validSummary.canSubmit)
        
        let invalidSummary = ValidationSummary(
            isValid: false,
            errorCount: 1,
            requiredFieldsCount: 3,
            completedRequiredFieldsCount: 3,
            completionPercentage: 1.0,
            errors: [],
            fieldStatuses: []
        )
        XCTAssertFalse(invalidSummary.canSubmit)
        
        let incompleteSummary = ValidationSummary(
            isValid: true,
            errorCount: 0,
            requiredFieldsCount: 3,
            completedRequiredFieldsCount: 2,
            completionPercentage: 0.67,
            errors: [],
            fieldStatuses: []
        )
        XCTAssertFalse(incompleteSummary.canSubmit)
    }
    
    func testValidationSummary_HasPartialCompletionLogic() {
        // Test hasPartialCompletion property logic
        let noCompletionSummary = ValidationSummary(
            isValid: false,
            errorCount: 0,
            requiredFieldsCount: 3,
            completedRequiredFieldsCount: 0,
            completionPercentage: 0.0,
            errors: [],
            fieldStatuses: []
        )
        XCTAssertFalse(noCompletionSummary.hasPartialCompletion)
        
        let partialCompletionSummary = ValidationSummary(
            isValid: false,
            errorCount: 0,
            requiredFieldsCount: 3,
            completedRequiredFieldsCount: 1,
            completionPercentage: 0.33,
            errors: [],
            fieldStatuses: []
        )
        XCTAssertTrue(partialCompletionSummary.hasPartialCompletion)
        
        let fullCompletionSummary = ValidationSummary(
            isValid: true,
            errorCount: 0,
            requiredFieldsCount: 3,
            completedRequiredFieldsCount: 3,
            completionPercentage: 1.0,
            errors: [],
            fieldStatuses: []
        )
        XCTAssertFalse(fullCompletionSummary.hasPartialCompletion)
    }
    
    func testFieldValidationStatus_StatusLogic() {
        // Test status computation logic
        let requiredEmptyStatus = FieldValidationStatus(
            fieldUuid: "test",
            fieldLabel: "Test",
            isRequired: true,
            hasValue: false,
            isValid: true,
            errorMessage: nil
        )
        XCTAssertEqual(requiredEmptyStatus.status, .requiredEmpty)
        
        let optionalEmptyStatus = FieldValidationStatus(
            fieldUuid: "test",
            fieldLabel: "Test",
            isRequired: false,
            hasValue: false,
            isValid: true,
            errorMessage: nil
        )
        XCTAssertEqual(optionalEmptyStatus.status, .optionalEmpty)
        
        let validStatus = FieldValidationStatus(
            fieldUuid: "test",
            fieldLabel: "Test",
            isRequired: true,
            hasValue: true,
            isValid: true,
            errorMessage: nil
        )
        XCTAssertEqual(validStatus.status, .valid)
        
        let invalidStatus = FieldValidationStatus(
            fieldUuid: "test",
            fieldLabel: "Test",
            isRequired: true,
            hasValue: true,
            isValid: false,
            errorMessage: "Error"
        )
        XCTAssertEqual(invalidStatus.status, .invalid)
    }
    
    func testFieldStatus_DisplayNamesAndColors() {
        // Test all field status cases
        XCTAssertEqual(FieldStatus.requiredEmpty.displayName, "Required")
        XCTAssertEqual(FieldStatus.optionalEmpty.displayName, "Optional")
        XCTAssertEqual(FieldStatus.valid.displayName, "Valid")
        XCTAssertEqual(FieldStatus.invalid.displayName, "Invalid")
        
        XCTAssertEqual(FieldStatus.requiredEmpty.color, "red")
        XCTAssertEqual(FieldStatus.optionalEmpty.color, "gray")
        XCTAssertEqual(FieldStatus.valid.color, "green")
        XCTAssertEqual(FieldStatus.invalid.color, "red")
    }
    
    // MARK: - Test Performance
    
    func testExecute_WithLargeForm_ShouldPerformWell() {
        // Given
        let largeFieldCount = 100
        let largeForm = TestDataFactory.createSimpleForm(
            id: "large-form",
            title: "Large Form",
            fieldCount: largeFieldCount
        )
        
        var fieldValues: [String: String] = [:]
        for i in 0..<largeFieldCount {
            fieldValues["field-\(i)"] = "value-\(i)"
        }
        
        let largeEntry = TestDataFactory.createCompletedEntry(fieldValues: fieldValues)
        
        let startTime = Date()
        
        // When
        let errors = useCase.execute(form: largeForm, entry: largeEntry)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertTrue(errors.isEmpty) // Should be valid
        
        // Performance assertion (adjust threshold as needed)
        XCTAssertLessThan(duration, 1.0, "Validation should complete within reasonable time")
    }
    
    // MARK: - Test Edge Cases
    
    func testExecute_WithEmptyForm_ShouldHandleGracefully() {
        // Given
        let emptyForm = DynamicForm(
            id: "empty-form",
            title: "Empty Form",
            fields: [],
            sections: []
        )
        let entry = TestDataFactory.createDraftEntry()
        
        // When
        let errors = useCase.execute(form: emptyForm, entry: entry)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testExecute_WithEntryHavingExtraFields_ShouldIgnoreExtraFields() {
        // Given
        let entryWithExtraFields = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "dropdown-validation": "active",
                "extra-field": "Extra value", // Not in form
                "another-extra": "Another extra" // Not in form
            ]
        )
        
        // When
        let errors = useCase.execute(form: testForm, entry: entryWithExtraFields)
        
        // Then
        XCTAssertTrue(errors.isEmpty) // Should ignore extra fields and validate correctly
    }
    
    func testExecute_WithNullOrWhitespaceValues_ShouldHandleCorrectly() {
        // Given
        let entryWithWhitespace = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "   ", // Only whitespace
                "email-validation": "\t\n", // Tab and newline
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let errors = useCase.execute(form: testForm, entry: entryWithWhitespace)
        
        // Then
        XCTAssertFalse(errors.isEmpty) // Whitespace-only should be treated as empty
        
        let errorFieldIds = errors.map { $0.fieldUuid }
        XCTAssertTrue(errorFieldIds.contains("required-text"))
        XCTAssertTrue(errorFieldIds.contains("email-validation"))
    }
    
    // MARK: - Test Memory Management
    
    func testExecute_MultipleCallsSequentially_ShouldNotLeakMemory() {
        // Given
        let validEntry = TestDataFactory.createCompletedEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "dropdown-validation": "active"
            ]
        )
        
        // When - Multiple sequential validation calls
        for _ in 0..<100 {
            let errors = useCase.execute(form: testForm, entry: validEntry)
            XCTAssertTrue(errors.isEmpty)
        }
        
        // Then - No assertion needed, test passes if no memory issues occur
        // This test primarily exists to catch memory leaks during CI/automated testing
    }
}

// MARK: - Test SectionProgress
extension ValidateFormEntryUseCaseTests {
    
    func testSectionProgress_Initialization() {
        // When
        let progress = SectionProgress(
            sectionId: "test-section",
            completedFields: 3,
            totalFields: 5,
            requiredFields: 2,
            completedRequiredFields: 1,
            hasErrors: true
        )
        
        // Then
        XCTAssertEqual(progress.sectionId, "test-section")
        XCTAssertEqual(progress.completedFields, 3)
        XCTAssertEqual(progress.totalFields, 5)
        XCTAssertEqual(progress.requiredFields, 2)
        XCTAssertEqual(progress.completedRequiredFields, 1)
        XCTAssertTrue(progress.hasErrors)
    }
}
