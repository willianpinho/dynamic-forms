import Foundation
import Domain

// MARK: - String Extensions
private extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Virtual form item for O(1) performance optimization
/// Flattens form structure into a single list for efficient scrolling
public enum VirtualFormItem: Identifiable {
    case editWarning(id: String = "edit_warning", editContext: EditContext)
    case sectionHeader(id: String, section: FormSection, progress: SectionProgress)
    case fieldItem(id: String, field: FormField, sectionId: String)
    case successMessage(id: String = "success_message", message: String)
    case autoSaveStatus(id: String = "autosave_status", timestamp: Date)
    
    public var id: String {
        switch self {
        case .editWarning(let id, _):
            return id
        case .sectionHeader(let id, _, _):
            return id
        case .fieldItem(let id, _, _):
            return id
        case .successMessage(let id, _):
            return id
        case .autoSaveStatus(let id, _):
            return id
        }
    }
}

/// Edit context for form editing scenarios
public enum EditContext: Equatable, Hashable {
    case newEntry
    case editingDraft
    case editingSubmitted
    
    public var displayMessage: String {
        switch self {
        case .newEntry:
            return ""
        case .editingDraft:
            return "Editing draft • Draft linking enabled to preserve all drafts"
        case .editingSubmitted:
            return "Editing submitted entry • Draft linking enabled to preserve all drafts"
        }
    }
    
    public var iconName: String {
        switch self {
        case .newEntry:
            return "doc.text"
        case .editingDraft:
            return "pencil.circle"
        case .editingSubmitted:
            return "arrow.triangle.2.circlepath"
        }
    }
}

/// Section progress tracking
public struct SectionProgress: Equatable {
    public let filledFields: Int
    public let totalFields: Int
    
    public init(filledFields: Int, totalFields: Int) {
        self.filledFields = filledFields
        self.totalFields = totalFields
    }
    
    public var percentage: Double {
        guard totalFields > 0 else { return 0.0 }
        return Double(filledFields) / Double(totalFields)
    }
    
    public var displayText: String {
        return "\(filledFields) of \(totalFields) completed"
    }
}

/// Virtual form item generator for O(1) performance
public final class VirtualFormItemGenerator {
    
    // MARK: - Configuration
    private static let prefetchFieldCount = 5 // Number of fields to prefetch within sections
    
    /// Generate flattened virtual items for optimal performance
    /// - Parameters:
    ///   - form: Dynamic form
    ///   - uiState: Current UI state
    ///   - fieldValues: Current field values
    ///   - validationErrors: Current validation errors
    /// - Returns: Array of virtual form items
    public static func generateVirtualItems(
        form: DynamicForm,
        editContext: EditContext,
        successMessage: String?,
        isAutoSaveEnabled: Bool,
        lastAutoSaveTime: Date?,
        fieldValues: [String: String]
    ) -> [VirtualFormItem] {
        var items: [VirtualFormItem] = []
        
        // Edit warning (if not new entry)
        if editContext != .newEntry {
            items.append(.editWarning(editContext: editContext))
        }
        
        // Get all field indices that are within sections (for prefetch calculation)
        let sectionFieldIndices = getAllSectionFieldIndices(form: form)
        
        // Form sections and fields (process in order) - ONLY fields within sections
        for section in form.sections {
            // Calculate section progress
            let sectionFields = form.getFieldsInSection(section)
            let filledFields = sectionFields.filter { field in
                let value = fieldValues[field.uuid] ?? ""
                return !value.isBlank
            }.count
            
            let progress = SectionProgress(
                filledFields: filledFields,
                totalFields: sectionFields.count
            )
            
            // Section header
            items.append(.sectionHeader(
                id: "section_\(section.uuid)",
                section: section,
                progress: progress
            ))
            
            // Section fields (maintain exact order from fields array)
            for index in section.from...min(section.to, form.fields.count - 1) {
                if index < form.fields.count {
                    let field = form.fields[index]
                    items.append(.fieldItem(
                        id: "field_\(field.uuid)",
                        field: field,
                        sectionId: section.uuid
                    ))
                }
            }
        }
        
        // Get already loaded field UUIDs to avoid duplication
        let loadedFieldUuids = Set(items.compactMap { item in
            if case .fieldItem(_, let field, _) = item {
                return field.uuid
            }
            return nil
        })
        
        // Add prefetched fields (only from sections, but not already loaded)
        let prefetchedFields = getPrefetchedFieldsWithinSections(
            form: form,
            sectionFieldIndices: sectionFieldIndices,
            loadedFieldUuids: loadedFieldUuids
        )
        
        for field in prefetchedFields {
            items.append(.fieldItem(
                id: "field_\(field.uuid)_prefetch",
                field: field,
                sectionId: "prefetch"
            ))
        }
        
        // Success message
        if let message = successMessage, !message.isEmpty {
            items.append(.successMessage(message: message))
        }
        
        // Auto-save status
        if isAutoSaveEnabled, let lastSave = lastAutoSaveTime {
            items.append(.autoSaveStatus(timestamp: lastSave))
        }
        
        return items
    }
    
    /// Generate virtual items for forms without sections (flat structure)
    /// - Parameters:
    ///   - fields: Array of form fields
    ///   - fieldValues: Current field values
    /// - Returns: Array of virtual form items
    public static func generateFlatVirtualItems(
        fields: [FormField],
        editContext: EditContext,
        successMessage: String?,
        isAutoSaveEnabled: Bool,
        lastAutoSaveTime: Date?,
        fieldValues: [String: String]
    ) -> [VirtualFormItem] {
        var items: [VirtualFormItem] = []
        
        // Edit warning (if not new entry)
        if editContext != .newEntry {
            items.append(.editWarning(editContext: editContext))
        }
        
        // All fields directly
        for field in fields {
            items.append(.fieldItem(
                id: "field_\(field.uuid)",
                field: field,
                sectionId: "default"
            ))
        }
        
        // Success message
        if let message = successMessage, !message.isEmpty {
            items.append(.successMessage(message: message))
        }
        
        // Auto-save status
        if isAutoSaveEnabled, let lastSave = lastAutoSaveTime {
            items.append(.autoSaveStatus(timestamp: lastSave))
        }
        
        return items
    }
    
    // MARK: - Private Helper Methods
    
    /// Get all field indices that are within any section
    private static func getAllSectionFieldIndices(form: DynamicForm) -> Set<Int> {
        var indices = Set<Int>()
        
        for section in form.sections {
            for index in section.from...min(section.to, form.fields.count - 1) {
                if index < form.fields.count {
                    indices.insert(index)
                }
            }
        }
        
        return indices
    }
    
    /// Get prefetched fields that are within section bounds but not yet loaded
    private static func getPrefetchedFieldsWithinSections(
        form: DynamicForm,
        sectionFieldIndices: Set<Int>,
        loadedFieldUuids: Set<String>
    ) -> [FormField] {
        var prefetchedFields: [FormField] = []
        
        // Get all indices that are within sections, sorted for consistent order
        let allSectionIndices = sectionFieldIndices.sorted()
        
        // Prefetch fields that are within sections but not already loaded
        for index in allSectionIndices {
            if prefetchedFields.count >= prefetchFieldCount { break }
            
            if index < form.fields.count {
                let field = form.fields[index]
                
                // Only prefetch if:
                // 1. Field requires input
                // 2. Field is not already loaded
                if field.requiresInput && !loadedFieldUuids.contains(field.uuid) {
                    prefetchedFields.append(field)
                }
            }
        }
        
        return prefetchedFields
    }
}

// MARK: - Extensions
public extension VirtualFormItem {
    
    /// Check if item is a field
    var isField: Bool {
        if case .fieldItem = self {
            return true
        }
        return false
    }
    
    /// Get field if this item is a field
    var field: FormField? {
        if case .fieldItem(_, let field, _) = self {
            return field
        }
        return nil
    }
    
    /// Check if item requires user interaction
    var isInteractive: Bool {
        switch self {
        case .fieldItem:
            return true
        case .editWarning, .sectionHeader, .successMessage, .autoSaveStatus:
            return false
        }
    }
}

// MARK: - Performance Metrics
public struct VirtualFormMetrics {
    public let totalItems: Int
    public let fieldCount: Int
    public let sectionCount: Int
    public let interactiveItems: Int
    
    public init(items: [VirtualFormItem]) {
        self.totalItems = items.count
        self.fieldCount = items.filter { $0.isField }.count
        self.sectionCount = items.filter { 
            if case .sectionHeader = $0 { return true }
            return false
        }.count
        self.interactiveItems = items.filter { $0.isInteractive }.count
    }
    
    public var debugDescription: String {
        return """
        VirtualForm Metrics:
        - Total Items: \(totalItems)
        - Fields: \(fieldCount)
        - Sections: \(sectionCount)
        - Interactive: \(interactiveItems)
        """
    }
}