import Foundation
import Utilities

/// Form field domain model representing individual form inputs
/// Following Clean Code principles with immutable design
public struct FormField: Identifiable, Equatable, Hashable, Codable, Sendable {
    
    // MARK: - Properties
    public let uuid: String
    public let type: FieldType
    public let name: String
    public let label: String
    public let required: Bool
    public let options: [FieldOption]
    public let value: String
    public let validationError: String?
    
    // MARK: - Computed Properties
    public var id: String { uuid }
    
    /// Check if field has a valid value (not empty for required fields)
    public var hasValidValue: Bool {
        if required {
            return !value.isBlank
        }
        return true
    }
    
    /// Check if field is in error state
    public var hasError: Bool {
        return validationError != nil
    }
    
    /// Check if field is a display-only field
    public var isDisplayOnly: Bool {
        return type == .description
    }
    
    /// Check if field requires user input
    public var requiresInput: Bool {
        return !isDisplayOnly
    }
    
    // MARK: - Initialization
    public init(
        uuid: String,
        type: FieldType,
        name: String,
        label: String,
        required: Bool = false,
        options: [FieldOption] = [],
        value: String = "",
        validationError: String? = nil
    ) {
        self.uuid = uuid
        self.type = type
        self.name = name
        self.label = label
        self.required = required
        self.options = options
        self.value = value
        self.validationError = validationError
    }
    
    // MARK: - Business Logic Methods
    
    /// Create a copy with updated value
    public func updateValue(_ newValue: String) -> FormField {
        return FormField(
            uuid: uuid,
            type: type,
            name: name,
            label: label,
            required: required,
            options: options,
            value: newValue,
            validationError: validationError
        )
    }
    
    /// Create a copy with updated validation error
    public func updateValidationError(_ error: String?) -> FormField {
        return FormField(
            uuid: uuid,
            type: type,
            name: name,
            label: label,
            required: required,
            options: options,
            value: value,
            validationError: error
        )
    }
    
    /// Create a copy with cleared validation error
    public func clearValidationError() -> FormField {
        return updateValidationError(nil)
    }
    
    /// Validate field value using built-in validation
    public func validate() -> FieldValidator.ValidationResult {
        return FieldValidator.validateField(
            value: value,
            fieldType: FieldValidator.FieldType.from(type.rawValue),
            isRequired: required,
            options: options.map { $0.value },
            fieldName: label
        )
    }
    
    /// Get display value for the field (useful for dropdowns)
    public func getDisplayValue() -> String {
        switch type {
        case .dropdown, .radio:
            return options.first { $0.value == value }?.label ?? value
        default:
            return value
        }
    }
    
    /// Check if value is one of the available options (for selection fields)
    public func isValueValidOption() -> Bool {
        switch type {
        case .dropdown, .radio:
            return options.contains { $0.value == value }
        case .checkbox:
            // For checkbox, value might be comma-separated list
            let selectedValues = value.components(separatedBy: ",").map { $0.trimmed }
            return selectedValues.allSatisfy { selectedValue in
                options.contains { $0.value == selectedValue }
            }
        default:
            return true
        }
    }
}

// MARK: - Field Type Enumeration
public enum FieldType: String, CaseIterable, Codable, Sendable {
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
    
    /// User-friendly display name
    public var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .number:
            return "Number"
        case .email:
            return "Email"
        case .password:
            return "Password"
        case .dropdown:
            return "Dropdown"
        case .description:
            return "Description"
        case .date:
            return "Date"
        case .radio:
            return "Radio Button"
        case .checkbox:
            return "Checkbox"
        case .textarea:
            return "Text Area"
        case .file:
            return "File"
        }
    }
    
    /// Check if field type supports multiple values
    public var supportsMultipleValues: Bool {
        return self == .checkbox
    }
    
    /// Check if field type requires options
    public var requiresOptions: Bool {
        switch self {
        case .dropdown, .radio, .checkbox:
            return true
        default:
            return false
        }
    }
    
    /// Create field type from string with fallback
    public static func from(_ string: String) -> FieldType {
        return FieldType(rawValue: string.lowercased()) ?? .text
    }
}

// MARK: - Field Option Model
public struct FieldOption: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let label: String
    public let value: String
    
    public var id: String { value }
    
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

// MARK: - Codable Implementation
extension FormField {
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case type
        case name
        case label
        case required
        case options
        case value
        case validationError
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(String.self, forKey: .uuid)
        
        // Handle type with fallback
        let typeString = try container.decode(String.self, forKey: .type)
        type = FieldType.from(typeString)
        
        name = try container.decode(String.self, forKey: .name)
        label = try container.decode(String.self, forKey: .label)
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
        options = try container.decodeIfPresent([FieldOption].self, forKey: .options) ?? []
        value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
        validationError = try container.decodeIfPresent(String.self, forKey: .validationError)
    }
}

// MARK: - Field Extensions
public extension FormField {
    
    /// Create text field
    static func textField(
        uuid: String,
        name: String,
        label: String,
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .text,
            name: name,
            label: label,
            required: required,
            value: value
        )
    }
    
    /// Create number field
    static func numberField(
        uuid: String,
        name: String,
        label: String,
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .number,
            name: name,
            label: label,
            required: required,
            value: value
        )
    }
    
    /// Create dropdown field
    static func dropdownField(
        uuid: String,
        name: String,
        label: String,
        options: [FieldOption],
        required: Bool = false,
        value: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .dropdown,
            name: name,
            label: label,
            required: required,
            options: options,
            value: value
        )
    }
    
    /// Create description field
    static func descriptionField(
        uuid: String,
        name: String,
        label: String,
        content: String = ""
    ) -> FormField {
        return FormField(
            uuid: uuid,
            type: .description,
            name: name,
            label: label,
            required: false,
            value: content
        )
    }
}