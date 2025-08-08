import Foundation

/// Form section domain model representing grouped form fields
/// Following Clean Code principles with immutable design
public struct FormSection: Identifiable, Equatable, Hashable, Codable, Sendable {
    
    // MARK: - Properties
    public let uuid: String
    public let title: String
    public let from: Int      // Start field index (inclusive)
    public let to: Int        // End field index (inclusive)
    public let index: Int     // Section order index
    public let fields: [FormField] // Associated fields (optional, can be computed)
    
    // MARK: - Computed Properties
    public var id: String { uuid }
    
    /// Check if section contains HTML content
    public var containsHTML: Bool {
        return title.containsHTML
    }
    
    /// Get plain text title (stripped of HTML)
    public var plainTitle: String {
        return title.strippingHTMLTags
    }
    
    /// Calculate section field count
    public var fieldCount: Int {
        return max(0, to - from + 1)
    }
    
    /// Check if section has valid field range
    public var hasValidRange: Bool {
        return from >= 0 && to >= from
    }
    
    // MARK: - Initialization
    public init(
        uuid: String,
        title: String,
        from: Int,
        to: Int,
        index: Int,
        fields: [FormField] = []
    ) {
        self.uuid = uuid
        self.title = title
        self.from = from
        self.to = to
        self.index = index
        self.fields = fields
    }
    
    // MARK: - Business Logic Methods
    
    /// Check if a field index is within this section's range
    public func containsFieldIndex(_ fieldIndex: Int) -> Bool {
        return fieldIndex >= from && fieldIndex <= to
    }
    
    /// Check if a field belongs to this section
    public func containsField(_ field: FormField) -> Bool {
        return fields.contains(field) || fields.contains { $0.uuid == field.uuid }
    }
    
    /// Get fields that match the section's index range
    public func getFieldsInRange(from allFields: [FormField]) -> [FormField] {
        let startIndex = max(0, min(from, allFields.count))
        let endIndex = max(startIndex, min(to + 1, allFields.count))
        
        guard startIndex < allFields.count && endIndex <= allFields.count else {
            return []
        }
        
        return Array(allFields[startIndex..<endIndex])
    }
    
    /// Calculate completion percentage for this section
    public func completionPercentage(with fieldValues: [String: String]) -> Double {
        guard !fields.isEmpty else { return 1.0 }
        
        let requiredFields = fields.filter { $0.required }
        guard !requiredFields.isEmpty else { return 1.0 }
        
        let completedRequiredFields = requiredFields.filter { field in
            let value = fieldValues[field.uuid] ?? ""
            return !value.isBlank
        }
        
        return Double(completedRequiredFields.count) / Double(requiredFields.count)
    }
    
    /// Check if section is completed (all required fields have values)
    public func isCompleted(with fieldValues: [String: String]) -> Bool {
        let requiredFields = fields.filter { $0.required }
        return requiredFields.allSatisfy { field in
            let value = fieldValues[field.uuid] ?? ""
            return !value.isBlank
        }
    }
    
    /// Get validation errors for fields in this section
    public func getValidationErrors(with fieldValues: [String: String]) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for field in fields where field.requiresInput {
            let validationResult = field.validate()
            
            if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                errors.append(ValidationError(fieldUuid: field.uuid, message: errorMessage))
            }
        }
        
        return errors
    }
    
    /// Create section with updated fields
    public func withFields(_ newFields: [FormField]) -> FormSection {
        return FormSection(
            uuid: uuid,
            title: title,
            from: from,
            to: to,
            index: index,
            fields: newFields
        )
    }
    
    /// Create section with updated title
    public func withTitle(_ newTitle: String) -> FormSection {
        return FormSection(
            uuid: uuid,
            title: newTitle,
            from: from,
            to: to,
            index: index,
            fields: fields
        )
    }
}

// MARK: - Section Progress
public struct SectionProgress: Identifiable {
    public let sectionId: String
    public let completedFields: Int
    public let totalFields: Int
    public let requiredFields: Int
    public let completedRequiredFields: Int
    public let hasErrors: Bool
    
    public var id: String { sectionId }
    
    public var completionPercentage: Double {
        guard requiredFields > 0 else { return 1.0 }
        return Double(completedRequiredFields) / Double(requiredFields)
    }
    
    public var isCompleted: Bool {
        return requiredFields == 0 || completedRequiredFields == requiredFields
    }
    
    public init(
        sectionId: String,
        completedFields: Int,
        totalFields: Int,
        requiredFields: Int,
        completedRequiredFields: Int,
        hasErrors: Bool
    ) {
        self.sectionId = sectionId
        self.completedFields = completedFields
        self.totalFields = totalFields
        self.requiredFields = requiredFields
        self.completedRequiredFields = completedRequiredFields
        self.hasErrors = hasErrors
    }
}

// MARK: - Factory Methods
public extension FormSection {
    
    /// Create section from index range
    static func create(
        uuid: String? = nil,
        title: String,
        from: Int,
        to: Int,
        index: Int
    ) -> FormSection {
        let sectionUuid = uuid ?? String.generateUUID()
        
        return FormSection(
            uuid: sectionUuid,
            title: title,
            from: from,
            to: to,
            index: index,
            fields: []
        )
    }
    
    /// Create section with fields
    static func createWithFields(
        uuid: String? = nil,
        title: String,
        fields: [FormField],
        index: Int
    ) -> FormSection {
        let sectionUuid = uuid ?? String.generateUUID()
        
        return FormSection(
            uuid: sectionUuid,
            title: title,
            from: 0,
            to: max(0, fields.count - 1),
            index: index,
            fields: fields
        )
    }
}

// MARK: - Codable Implementation
extension FormSection {
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case from
        case to
        case index
        case fields
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(String.self, forKey: .uuid)
        title = try container.decode(String.self, forKey: .title)
        from = try container.decode(Int.self, forKey: .from)
        to = try container.decode(Int.self, forKey: .to)
        index = try container.decode(Int.self, forKey: .index)
        fields = try container.decodeIfPresent([FormField].self, forKey: .fields) ?? []
    }
}

// MARK: - Section Utilities
public extension Array where Element == FormSection {
    
    /// Sort sections by index
    func sortedByIndex() -> [FormSection] {
        return sorted { $0.index < $1.index }
    }
    
    /// Find section containing field index
    func sectionContaining(fieldIndex: Int) -> FormSection? {
        return first { $0.containsFieldIndex(fieldIndex) }
    }
    
    /// Find section by UUID
    func section(withUuid uuid: String) -> FormSection? {
        return first { $0.uuid == uuid }
    }
    
    /// Calculate total progress across all sections
    func totalProgress(with fieldValues: [String: String]) -> Double {
        guard !isEmpty else { return 1.0 }
        
        let totalProgress = reduce(0.0) { result, section in
            return result + section.completionPercentage(with: fieldValues)
        }
        
        return totalProgress / Double(count)
    }
}