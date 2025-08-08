import Foundation
import Utilities

/// Use case for validating form entries against form definitions
/// Following Single Responsibility Principle and Clean Architecture
public final class ValidateFormEntryUseCase {
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Execution
    
    /// Validate form entry against form definition
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to validate
    /// - Returns: Array of ValidationError objects
    public func execute(form: DynamicForm, entry: FormEntry) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Only validate fields that are within the loaded sections
        let fieldsInSections = getFieldsInSections(form: form)
        
        for field in fieldsInSections where field.requiresInput {
            let value = entry.getValueForField(field.uuid)
            let validationResult = validateField(field, value: value)
            
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                errors.append(ValidationError(fieldUuid: field.uuid, message: errorMessage))
            }
        }
        
        return errors
    }
    
    /// Validate specific field value
    /// - Parameters:
    ///   - field: FormField to validate
    ///   - value: Value to validate
    /// - Returns: ValidationError if validation fails, nil if valid
    public func validateField(_ field: FormField, value: String) -> FieldValidator.ValidationResult {
        return FieldValidator.validateField(
            value: value,
            fieldType: FieldValidator.FieldType.from(field.type.rawValue),
            isRequired: field.required,
            options: field.options.map { $0.value },
            fieldName: field.label
        )
    }
    
    /// Validate multiple entries in batch
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entries: Array of FormEntry objects to validate
    /// - Returns: Dictionary mapping entry ID to validation errors
    public func validateBatch(form: DynamicForm, entries: [FormEntry]) -> [String: [ValidationError]] {
        var batchResults: [String: [ValidationError]] = [:]
        
        for entry in entries {
            let errors = execute(form: form, entry: entry)
            if !errors.isEmpty {
                batchResults[entry.id] = errors
            }
        }
        
        return batchResults
    }
    
    /// Check if entry is valid for submission
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to check
    /// - Returns: Boolean indicating if entry can be submitted
    public func isValidForSubmission(form: DynamicForm, entry: FormEntry) -> Bool {
        let errors = execute(form: form, entry: entry)
        return errors.isEmpty
    }
    
    /// Get validation summary for entry
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to analyze
    /// - Returns: ValidationSummary with detailed information
    public func getValidationSummary(form: DynamicForm, entry: FormEntry) -> ValidationSummary {
        let errors = execute(form: form, entry: entry)
        let requiredFields = form.getRequiredFields()
        let completedRequiredFields = requiredFields.filter { field in
            !entry.getValueForField(field.uuid).isBlank
        }
        
        let fieldStatuses = form.fields.map { field -> FieldValidationStatus in
            let value = entry.getValueForField(field.uuid)
            let validationResult = validateField(field, value: value)
            
            return FieldValidationStatus(
                fieldUuid: field.uuid,
                fieldLabel: field.label,
                isRequired: field.required,
                hasValue: !value.isBlank,
                isValid: validationResult.isValid,
                errorMessage: validationResult.errorMessage
            )
        }
        
        return ValidationSummary(
            isValid: errors.isEmpty,
            errorCount: errors.count,
            requiredFieldsCount: requiredFields.count,
            completedRequiredFieldsCount: completedRequiredFields.count,
            completionPercentage: entry.completionPercentage(for: form),
            errors: errors,
            fieldStatuses: fieldStatuses
        )
    }
    
    /// Validate field in real-time (with debouncing considerations)
    /// - Parameters:
    ///   - field: FormField to validate
    ///   - value: Current field value
    ///   - isPartial: Whether this is a partial validation (while typing)
    /// - Returns: ValidationResult with appropriate messaging
    public func validateFieldRealTime(
        _ field: FormField,
        value: String,
        isPartial: Bool = false
    ) -> FieldValidator.ValidationResult {
        // For partial validation, be more lenient
        if isPartial && value.isBlank && field.required {
            // Don't show required error while user is still typing
            return FieldValidator.ValidationResult(isValid: true)
        }
        
        return validateField(field, value: value)
    }
    
    /// Get validation errors for specific section
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to validate
    ///   - section: FormSection to focus validation on
    /// - Returns: Array of ValidationError objects for the section
    public func validateSection(
        form: DynamicForm,
        entry: FormEntry,
        section: FormSection
    ) -> [ValidationError] {
        let sectionFields = form.getFieldsInSection(section)
        var errors: [ValidationError] = []
        
        for field in sectionFields where field.requiresInput {
            let value = entry.getValueForField(field.uuid)
            let validationResult = validateField(field, value: value)
            
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                errors.append(ValidationError(fieldUuid: field.uuid, message: errorMessage))
            }
        }
        
        return errors
    }
}

// MARK: - Supporting Types
public struct ValidationSummary {
    public let isValid: Bool
    public let errorCount: Int
    public let requiredFieldsCount: Int
    public let completedRequiredFieldsCount: Int
    public let completionPercentage: Double
    public let errors: [ValidationError]
    public let fieldStatuses: [FieldValidationStatus]
    
    public var canSubmit: Bool {
        return isValid && completedRequiredFieldsCount == requiredFieldsCount
    }
    
    public var hasPartialCompletion: Bool {
        return completionPercentage > 0 && completionPercentage < 1.0
    }
    
    public init(
        isValid: Bool,
        errorCount: Int,
        requiredFieldsCount: Int,
        completedRequiredFieldsCount: Int,
        completionPercentage: Double,
        errors: [ValidationError],
        fieldStatuses: [FieldValidationStatus]
    ) {
        self.isValid = isValid
        self.errorCount = errorCount
        self.requiredFieldsCount = requiredFieldsCount
        self.completedRequiredFieldsCount = completedRequiredFieldsCount
        self.completionPercentage = completionPercentage
        self.errors = errors
        self.fieldStatuses = fieldStatuses
    }
}

public struct FieldValidationStatus {
    public let fieldUuid: String
    public let fieldLabel: String
    public let isRequired: Bool
    public let hasValue: Bool
    public let isValid: Bool
    public let errorMessage: String?
    
    public var status: FieldStatus {
        if !hasValue && isRequired {
            return .requiredEmpty
        } else if !hasValue {
            return .optionalEmpty
        } else if isValid {
            return .valid
        } else {
            return .invalid
        }
    }
    
    public init(
        fieldUuid: String,
        fieldLabel: String,
        isRequired: Bool,
        hasValue: Bool,
        isValid: Bool,
        errorMessage: String?
    ) {
        self.fieldUuid = fieldUuid
        self.fieldLabel = fieldLabel
        self.isRequired = isRequired
        self.hasValue = hasValue
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

public enum FieldStatus {
    case requiredEmpty
    case optionalEmpty
    case valid
    case invalid
    
    public var displayName: String {
        switch self {
        case .requiredEmpty:
            return "Required"
        case .optionalEmpty:
            return "Optional"
        case .valid:
            return "Valid"
        case .invalid:
            return "Invalid"
        }
    }
    
    public var color: String {
        switch self {
        case .requiredEmpty, .invalid:
            return "red"
        case .valid:
            return "green"
        case .optionalEmpty:
            return "gray"
        }
    }
}

// MARK: - Extensions
public extension ValidateFormEntryUseCase {
    
    /// Get field-specific validation errors
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to validate
    /// - Returns: Dictionary mapping field UUID to error message
    func getFieldErrors(form: DynamicForm, entry: FormEntry) -> [String: String] {
        let errors = execute(form: form, entry: entry)
        var fieldErrors: [String: String] = [:]
        
        for error in errors {
            fieldErrors[error.fieldUuid] = error.message
        }
        
        return fieldErrors
    }
    
    /// Check if specific field is valid
    /// - Parameters:
    ///   - fieldUuid: Field identifier
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to check
    /// - Returns: Boolean indicating field validity
    func isFieldValid(fieldUuid: String, form: DynamicForm, entry: FormEntry) -> Bool {
        guard let field = form.getFieldByUuid(fieldUuid) else { return true }
        let value = entry.getValueForField(fieldUuid)
        let result = validateField(field, value: value)
        return result.isValid
    }
    
    /// Get validation errors grouped by section
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to validate
    /// - Returns: Dictionary mapping section UUID to validation errors
    func getErrorsBySections(form: DynamicForm, entry: FormEntry) -> [String: [ValidationError]] {
        let allErrors = execute(form: form, entry: entry)
        var sectionErrors: [String: [ValidationError]] = [:]
        
        for error in allErrors {
            if let section = form.getSectionContaining(fieldUuid: error.fieldUuid) {
                if sectionErrors[section.uuid] == nil {
                    sectionErrors[section.uuid] = []
                }
                sectionErrors[section.uuid]?.append(error)
            }
        }
        
        return sectionErrors
    }
    
    /// Get completion status for each section
    /// - Parameters:
    ///   - form: DynamicForm containing field definitions
    ///   - entry: FormEntry to analyze
    /// - Returns: Array of SectionProgress objects
    func getSectionProgress(form: DynamicForm, entry: FormEntry) -> [SectionProgress] {
        return form.sections.map { section in
            let sectionFields = form.getFieldsInSection(section)
            let requiredFields = sectionFields.filter { $0.required }
            let completedRequiredFields = requiredFields.filter { field in
                !entry.getValueForField(field.uuid).isBlank
            }
            let sectionErrors = validateSection(form: form, entry: entry, section: section)
            
            return SectionProgress(
                sectionId: section.uuid,
                completedFields: sectionFields.filter { !entry.getValueForField($0.uuid).isBlank }.count,
                totalFields: sectionFields.count,
                requiredFields: requiredFields.count,
                completedRequiredFields: completedRequiredFields.count,
                hasErrors: !sectionErrors.isEmpty
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Get all fields that are within the defined sections
    /// - Parameter form: DynamicForm containing field definitions and sections
    /// - Returns: Array of FormField objects that are within sections
    private func getFieldsInSections(form: DynamicForm) -> [FormField] {
        var fieldsInSections: [FormField] = []
        
        for section in form.sections {
            let sectionFields = form.getFieldsInSection(section)
            fieldsInSections.append(contentsOf: sectionFields)
        }
        
        return fieldsInSections
    }
}