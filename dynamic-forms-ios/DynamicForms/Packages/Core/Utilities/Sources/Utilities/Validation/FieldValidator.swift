import Foundation

/// Field validation utility following Clean Code principles
/// Single responsibility for validating form field values
public struct FieldValidator {
    
    // MARK: - Validation Result
    public struct ValidationResult {
        public let isValid: Bool
        public let errorMessage: String?
        
        public init(isValid: Bool, errorMessage: String? = nil) {
            self.isValid = isValid
            self.errorMessage = errorMessage
        }
    }
    
    // MARK: - Field Types
    public enum FieldType: String, CaseIterable {
        case text = "text"
        case number = "number"
        case email = "email"
        case password = "password"
        case dropdown = "dropdown"
        case description = "description"
        case date = "date"
        case radio = "radio"
        case checkbox = "checkbox"
        case textarea = "textarea"
        case file = "file"
        
        /// Convert string to FieldType with fallback
        public static func from(_ string: String) -> FieldType {
            return FieldType(rawValue: string.lowercased()) ?? .text
        }
    }
    
    // MARK: - Validation Rules
    public static func validateField(
        value: String,
        fieldType: FieldType,
        isRequired: Bool = false,
        options: [String] = [],
        fieldName: String = "Field"
    ) -> ValidationResult {
        
        // Check required validation first
        if isRequired && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) is required"
            )
        }
        
        // If field is empty and not required, it's valid
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRequired {
            return ValidationResult(isValid: true)
        }
        
        // Type-specific validation
        switch fieldType {
        case .text, .textarea:
            return validateText(value: value, fieldName: fieldName)
            
        case .number:
            return validateNumber(value: value, fieldName: fieldName)
            
        case .email:
            return validateEmail(value: value, fieldName: fieldName)
            
        case .password:
            return validatePassword(value: value, fieldName: fieldName)
            
        case .dropdown, .radio:
            return validateSelection(value: value, options: options, fieldName: fieldName)
            
        case .date:
            return validateDate(value: value, fieldName: fieldName)
            
        case .checkbox:
            return validateCheckbox(value: value, fieldName: fieldName)
            
        case .description:
            // Description fields are display-only, always valid
            return ValidationResult(isValid: true)
            
        case .file:
            // File fields are treated as text fields for validation
            return validateText(value: value, fieldName: fieldName)
        }
    }
    
    // MARK: - Private Validation Methods
    private static func validateText(value: String, fieldName: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic text validation - no special characters for names, reasonable length
        if trimmedValue.count > 255 {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be less than 255 characters"
            )
        }
        
        return ValidationResult(isValid: true)
    }
    
    private static func validateNumber(value: String, fieldName: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's a valid number
        if Double(trimmedValue) == nil {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be a valid number"
            )
        }
        
        return ValidationResult(isValid: true)
    }
    
    private static func validateEmail(value: String, fieldName: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Email regex pattern
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedValue) {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be a valid email address"
            )
        }
        
        return ValidationResult(isValid: true)
    }
    
    private static func validatePassword(value: String, fieldName: String) -> ValidationResult {
        // Basic password validation - minimum 6 characters
        if value.count < 6 {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be at least 6 characters long"
            )
        }
        
        return ValidationResult(isValid: true)
    }
    
    private static func validateSelection(value: String, options: [String], fieldName: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the selected value is in the available options
        if !options.contains(trimmedValue) {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) must be one of the available options"
            )
        }
        
        return ValidationResult(isValid: true)
    }
    
    private static func validateDate(value: String, fieldName: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to parse the date using ISO 8601 format or common formats
        let formatters = [
            ISO8601DateFormatter(),
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "dd/MM/yyyy")
        ]
        
        for formatter in formatters {
            if let _ = parseDate(from: trimmedValue, using: formatter) {
                return ValidationResult(isValid: true)
            }
        }
        
        return ValidationResult(
            isValid: false,
            errorMessage: "\(fieldName) must be a valid date (YYYY-MM-DD)"
        )
    }
    
    private static func validateCheckbox(value: String, fieldName: String) -> ValidationResult {
        // Checkbox values are typically "true" or "false" strings, or comma-separated values
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Helper Methods
    private static func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    private static func parseDate(from string: String, using formatter: Any) -> Date? {
        if let isoFormatter = formatter as? ISO8601DateFormatter {
            return isoFormatter.date(from: string)
        } else if let dateFormatter = formatter as? DateFormatter {
            return dateFormatter.date(from: string)
        }
        return nil
    }
}

// MARK: - Validation Extensions
public extension FieldValidator {
    
    /// Batch validate multiple fields
    static func validateFields(_ validations: [(value: String, type: FieldType, required: Bool, options: [String], name: String)]) -> [ValidationResult] {
        return validations.map { validation in
            validateField(
                value: validation.value,
                fieldType: validation.type,
                isRequired: validation.required,
                options: validation.options,
                fieldName: validation.name
            )
        }
    }
    
    /// Check if all validations in a batch are valid
    static func areAllValid(_ results: [ValidationResult]) -> Bool {
        return results.allSatisfy { $0.isValid }
    }
    
    /// Get all error messages from validation results
    static func getErrorMessages(_ results: [ValidationResult]) -> [String] {
        return results.compactMap { $0.errorMessage }
    }
}