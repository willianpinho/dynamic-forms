import Foundation
import Utilities

/// Form entry domain model representing a user's form submission or draft
/// Following Clean Code principles with immutable design
public struct FormEntry: Identifiable, Equatable, Hashable, Codable, Sendable {
    
    // MARK: - Properties
    public let id: String
    public let formId: String
    public let sourceEntryId: String? // ID of the original entry this draft is based on (for edit drafts)
    public let fieldValues: [String: String] // fieldUuid -> value
    public let createdAt: Date
    public let updatedAt: Date
    public let isComplete: Bool
    public let isDraft: Bool
    
    // MARK: - Computed Properties
    
    /// Check if this entry is a draft created for editing an existing submitted entry
    public var isEditDraft: Bool {
        return isDraft && sourceEntryId != nil
    }
    
    /// Check if this entry is a new draft (not based on an existing entry)
    public var isNewDraft: Bool {
        return isDraft && sourceEntryId == nil
    }
    
    /// Get entry status for display
    public var status: EntryStatus {
        if isComplete {
            return .completed
        } else if isDraft {
            return isEditDraft ? .editDraft : .draft
        } else {
            return .submitted
        }
    }
    
    /// Check if entry has any field values
    public var hasData: Bool {
        return !fieldValues.isEmpty && fieldValues.values.contains { !$0.isBlank }
    }
    
    /// Calculate completion percentage for a form
    public func completionPercentage(for form: DynamicForm) -> Double {
        let requiredFields = form.fields.filter { $0.required }
        guard !requiredFields.isEmpty else { return 1.0 }
        
        let filledRequiredFields = requiredFields.filter { field in
            let value = fieldValues[field.uuid] ?? ""
            return !value.isBlank
        }
        
        return Double(filledRequiredFields.count) / Double(requiredFields.count)
    }
    
    /// Get non-empty field values for display
    public func getNonEmptyFieldValues() -> [String: String] {
        return fieldValues.filter { !$0.value.isBlank }
    }
    
    /// Generate a user-friendly title for display in lists
    public func generateDisplayTitle() -> String {
        // For edit drafts, show it's based on another entry
        if isEditDraft {
            return "Edit Draft"
        }
        
        // For new drafts, try to use first meaningful field value
        if isDraft {
            let nonEmptyValues = getNonEmptyFieldValues()
            if let firstValue = nonEmptyValues.first {
                // Truncate long values
                let truncatedValue = firstValue.value.count > 25 
                    ? String(firstValue.value.prefix(22)) + "..."
                    : firstValue.value
                return "Draft: \(truncatedValue)"
            } else {
                // Show creation time for empty drafts
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, HH:mm"
                return "New Draft (\(formatter.string(from: createdAt)))"
            }
        }
        
        // For completed entries, try to use first meaningful field value
        let nonEmptyValues = getNonEmptyFieldValues()
        if let firstValue = nonEmptyValues.first {
            let truncatedValue = firstValue.value.count > 25 
                ? String(firstValue.value.prefix(22)) + "..."
                : firstValue.value
            return truncatedValue
        }
        
        // Fallback to ID prefix
        return "Entry \(id.prefix(8))"
    }
    
    /// Generate a subtitle with additional context
    public func generateDisplaySubtitle() -> String {
        if isEditDraft, let sourceId = sourceEntryId {
            return "Based on \(sourceId.prefix(8))"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • HH:mm"
        
        if isDraft {
            return "Created \(formatter.string(from: createdAt))"
        } else {
            return "Submitted \(formatter.string(from: updatedAt))"
        }
    }
    
    // MARK: - Initialization
    public init(
        id: String,
        formId: String,
        sourceEntryId: String? = nil,
        fieldValues: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isComplete: Bool = false,
        isDraft: Bool = true
    ) {
        self.id = id
        self.formId = formId
        self.sourceEntryId = sourceEntryId
        self.fieldValues = fieldValues
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isComplete = isComplete
        self.isDraft = isDraft
    }
    
    // MARK: - Business Logic Methods
    
    /// Get value for a specific field
    public func getValueForField(_ fieldUuid: String) -> String {
        return fieldValues[fieldUuid] ?? ""
    }
    
    /// Update field value and return new entry
    public func updateFieldValue(fieldUuid: String, value: String) -> FormEntry {
        var updatedValues = fieldValues
        updatedValues[fieldUuid] = value
        
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: updatedValues,
            createdAt: createdAt,
            updatedAt: Date(),
            isComplete: isComplete,
            isDraft: true // Mark as draft when updating
        )
    }
    
    /// Mark entry as complete (submitted)
    public func markAsComplete() -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: Date(),
            isComplete: true,
            isDraft: false
        )
    }
    
    /// Mark entry as draft
    public func markAsDraft() -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: Date(),
            isComplete: false,
            isDraft: true
        )
    }
    
    /// Validate entry against form definition
    public func validateAgainstForm(_ form: DynamicForm) -> [String: String] {
        var errors: [String: String] = [:]
        
        form.getRequiredFields().forEach { field in
            let value = getValueForField(field.uuid)
            if value.isBlank {
                errors[field.uuid] = "\(field.label) is required"
            }
        }
        
        // Additional type-specific validation
        form.fields.forEach { field in
            let value = getValueForField(field.uuid)
            if !value.isBlank {
                let validationResult = FieldValidator.validateField(
                    value: value,
                    fieldType: FieldValidator.FieldType.from(field.type.rawValue),
                    isRequired: field.required,
                    options: field.options.map { $0.value },
                    fieldName: field.label
                )
                
                if !validationResult.isValid, let errorMessage = validationResult.errorMessage {
                    errors[field.uuid] = errorMessage
                }
            }
        }
        
        return errors
    }
    
    /// Create an edit draft based on this entry
    public func createEditDraft(draftId: String? = nil) -> FormEntry {
        let newDraftId = draftId ?? "draft_edit_\(id)_\(Date().timeIntervalSince1970)"
        
        return FormEntry(
            id: newDraftId,
            formId: formId,
            sourceEntryId: id,
            fieldValues: fieldValues,
            createdAt: Date(),
            updatedAt: Date(),
            isComplete: false,
            isDraft: true
        )
    }
    
    /// Update multiple field values at once
    public func updateFieldValues(_ updates: [String: String]) -> FormEntry {
        var updatedValues = fieldValues
        
        for (fieldUuid, value) in updates {
            updatedValues[fieldUuid] = value
        }
        
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: updatedValues,
            createdAt: createdAt,
            updatedAt: Date(),
            isComplete: isComplete,
            isDraft: isDraft
        )
    }
    
    /// Create a copy with new ID (for duplicating entries)
    public func duplicate(newId: String? = nil) -> FormEntry {
        let duplicateId = newId ?? "copy_\(id)_\(Date().timeIntervalSince1970)"
        
        return FormEntry(
            id: duplicateId,
            formId: formId,
            sourceEntryId: nil, // New entry, not an edit
            fieldValues: fieldValues,
            createdAt: Date(),
            updatedAt: Date(),
            isComplete: false,
            isDraft: true
        )
    }
}

// MARK: - Entry Status Enumeration
public enum EntryStatus: String, CaseIterable, Sendable {
    case draft = "draft"
    case editDraft = "edit_draft"
    case submitted = "submitted"
    case completed = "completed"
    
    public var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .editDraft:
            return "Edit Draft"
        case .submitted:
            return "Submitted"
        case .completed:
            return "Completed"
        }
    }
    
    public var color: String {
        switch self {
        case .draft, .editDraft:
            return "orange"
        case .submitted, .completed:
            return "green"
        }
    }
}

// MARK: - Codable Implementation
extension FormEntry {
    
    enum CodingKeys: String, CodingKey {
        case id
        case formId
        case sourceEntryId
        case fieldValues
        case createdAt
        case updatedAt
        case isComplete
        case isDraft
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        formId = try container.decode(String.self, forKey: .formId)
        sourceEntryId = try container.decodeIfPresent(String.self, forKey: .sourceEntryId)
        fieldValues = try container.decodeIfPresent([String: String].self, forKey: .fieldValues) ?? [:]
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
        isDraft = try container.decodeIfPresent(Bool.self, forKey: .isDraft) ?? true
        
        // Handle date decoding with fallback
        if let createdAtTimestamp = try? container.decode(TimeInterval.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: createdAtTimestamp / 1000) // Convert from milliseconds
        } else {
            createdAt = Date()
        }
        
        if let updatedAtTimestamp = try? container.decode(TimeInterval.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp / 1000) // Convert from milliseconds
        } else {
            updatedAt = Date()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(formId, forKey: .formId)
        try container.encodeIfPresent(sourceEntryId, forKey: .sourceEntryId)
        try container.encode(fieldValues, forKey: .fieldValues)
        try container.encode(createdAt.timeIntervalSince1970 * 1000, forKey: .createdAt) // Convert to milliseconds
        try container.encode(updatedAt.timeIntervalSince1970 * 1000, forKey: .updatedAt) // Convert to milliseconds
        try container.encode(isComplete, forKey: .isComplete)
        try container.encode(isDraft, forKey: .isDraft)
    }
}

// MARK: - Factory Methods
public extension FormEntry {
    
    /// Create new draft entry
    static func newDraft(
        formId: String,
        id: String? = nil
    ) -> FormEntry {
        let entryId = id ?? "draft_\(formId)_\(Date().timeIntervalSince1970)"
        
        return FormEntry(
            id: entryId,
            formId: formId,
            sourceEntryId: nil,
            fieldValues: [:],
            createdAt: Date(),
            updatedAt: Date(),
            isComplete: false,
            isDraft: true
        )
    }
    
    /// Create completed entry
    static func completed(
        id: String,
        formId: String,
        fieldValues: [String: String]
    ) -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: nil,
            fieldValues: fieldValues,
            createdAt: Date(),
            updatedAt: Date(),
            isComplete: true,
            isDraft: false
        )
    }
}