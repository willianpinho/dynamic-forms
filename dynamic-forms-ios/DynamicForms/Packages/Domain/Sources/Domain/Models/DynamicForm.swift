import Foundation
import Utilities

/// Dynamic form domain model representing a complete form structure
/// Following Clean Code principles with immutable design and single responsibility
public struct DynamicForm: Identifiable, Equatable, Hashable, Codable, Sendable {
    
    // MARK: - Properties
    public let id: String
    public let title: String
    public let fields: [FormField]
    public let sections: [FormSection]
    public let createdAt: Date
    public let updatedAt: Date
    
    // MARK: - Initialization
    public init(
        id: String,
        title: String,
        fields: [FormField],
        sections: [FormSection] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.fields = fields
        self.sections = sections
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Business Logic Methods
    
    /// Get fields that belong to a specific section
    public func getFieldsInSection(_ section: FormSection) -> [FormField] {
        let fromIndex = max(0, min(section.from, fields.count))
        let toIndex = max(fromIndex, min(section.to + 1, fields.count))
        
        guard fromIndex < fields.count && toIndex <= fields.count else {
            return []
        }
        
        return Array(fields[fromIndex..<toIndex])
    }
    
    /// Find field by UUID
    public func getFieldByUuid(_ uuid: String) -> FormField? {
        return fields.first { $0.uuid == uuid }
    }
    
    /// Update field value and clear validation error
    public func updateFieldValue(fieldUuid: String, value: String) -> DynamicForm {
        let updatedFields = fields.map { field in
            if field.uuid == fieldUuid {
                return field.updateValue(value).clearValidationError()
            }
            return field
        }
        
        return DynamicForm(
            id: id,
            title: title,
            fields: updatedFields,
            sections: sections,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    /// Update field validation error
    public func updateFieldValidation(fieldUuid: String, error: String?) -> DynamicForm {
        let updatedFields = fields.map { field in
            if field.uuid == fieldUuid {
                return field.updateValidationError(error)
            }
            return field
        }
        
        return DynamicForm(
            id: id,
            title: title,
            fields: updatedFields,
            sections: sections,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Check if all fields are valid (no validation errors)
    public func isValid() -> Bool {
        return fields.allSatisfy { $0.validationError == nil }
    }
    
    /// Get all required fields
    public func getRequiredFields() -> [FormField] {
        return fields.filter { $0.required }
    }
    
    /// Get all fields with validation errors
    public func getInvalidFields() -> [FormField] {
        return fields.filter { $0.validationError != nil }
    }
    
    /// Calculate form completion percentage
    public func completionPercentage() -> Double {
        let requiredFields = getRequiredFields()
        guard !requiredFields.isEmpty else { return 1.0 }
        
        let completedRequiredFields = requiredFields.filter { !$0.value.isBlank }
        return Double(completedRequiredFields.count) / Double(requiredFields.count)
    }
    
    /// Check if form has unsaved changes (basic check)
    public func hasUnsavedChanges() -> Bool {
        return fields.contains { !$0.value.isBlank }
    }
    
    /// Create a copy with field values from form entry
    public func withFieldValues(from entry: FormEntry) -> DynamicForm {
        let updatedFields = fields.map { field in
            let value = entry.getValueForField(field.uuid)
            return field.updateValue(value)
        }
        
        return DynamicForm(
            id: id,
            title: title,
            fields: updatedFields,
            sections: sections,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    /// Get section containing a specific field
    public func getSectionContaining(fieldUuid: String) -> FormSection? {
        guard let fieldIndex = fields.firstIndex(where: { $0.uuid == fieldUuid }) else {
            return nil
        }
        
        return sections.first { section in
            fieldIndex >= section.from && fieldIndex <= section.to
        }
    }
    
    /// Validate form with current field values
    public func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for field in fields {
            let validationResult = FieldValidator.validateField(
                value: field.value,
                fieldType: FieldValidator.FieldType.from(field.type.rawValue),
                isRequired: field.required,
                options: field.options.map { $0.value },
                fieldName: field.label
            )
            
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                errors.append(ValidationError(fieldUuid: field.uuid, message: errorMessage))
            }
        }
        
        return errors
    }
}

// MARK: - Codable Support
extension DynamicForm {
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case fields
        case sections
        case createdAt
        case updatedAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID is optional in JSON, generate if not present
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = id
        } else {
            // Generate ID from title
            let title = try container.decode(String.self, forKey: .title)
            self.id = title.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.fields = try container.decode([FormField].self, forKey: .fields)
        self.sections = try container.decodeIfPresent([FormSection].self, forKey: .sections) ?? []
        
        // Handle date decoding with fallback
        if let createdAtTimestamp = try? container.decode(TimeInterval.self, forKey: .createdAt) {
            self.createdAt = Date(timeIntervalSince1970: createdAtTimestamp / 1000) // Convert from milliseconds
        } else {
            self.createdAt = Date()
        }
        
        if let updatedAtTimestamp = try? container.decode(TimeInterval.self, forKey: .updatedAt) {
            self.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp / 1000) // Convert from milliseconds
        } else {
            self.updatedAt = Date()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(fields, forKey: .fields)
        try container.encode(sections, forKey: .sections)
        try container.encode(createdAt.timeIntervalSince1970 * 1000, forKey: .createdAt) // Convert to milliseconds
        try container.encode(updatedAt.timeIntervalSince1970 * 1000, forKey: .updatedAt) // Convert to milliseconds
    }
}

// MARK: - Helper Types
public struct ValidationError: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let fieldUuid: String
    public let message: String
    
    public init(fieldUuid: String, message: String) {
        self.fieldUuid = fieldUuid
        self.message = message
    }
}