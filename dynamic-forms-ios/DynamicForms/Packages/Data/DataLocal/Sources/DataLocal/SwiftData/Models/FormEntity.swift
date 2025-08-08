import Foundation
import SwiftData
import Domain

/// SwiftData model for DynamicForm persistence
/// Following SwiftData best practices with relationships
@available(iOS 17.0, macOS 14.0, *)
@Model
public final class FormEntity {
    
    // MARK: - Properties
    @Attribute(.unique) public var id: String
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \FormFieldEntity.form)
    public var fields: [FormFieldEntity] = []
    
    @Relationship(deleteRule: .cascade, inverse: \FormSectionEntity.form)
    public var sections: [FormSectionEntity] = []
    
    @Relationship(deleteRule: .cascade, inverse: \FormEntryEntity.form)
    public var entries: [FormEntryEntity] = []
    
    // MARK: - Initialization
    public init(
        id: String,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Domain Conversion
    public func toDomain() -> DynamicForm {
        return DynamicForm(
            id: id,
            title: title,
            fields: fields.sorted { $0.sortIndex < $1.sortIndex }.map { $0.toDomain() },
            sections: sections.map { $0.toDomain() }.sorted { $0.index < $1.index },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    public static func fromDomain(_ domain: DynamicForm) -> FormEntity {
        let entity = FormEntity(
            id: domain.id,
            title: domain.title,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
        
        // Fields will be created separately to avoid circular references
        return entity
    }
}

/// SwiftData model for FormField persistence
@available(iOS 17.0, macOS 14.0, *)
@Model
public final class FormFieldEntity {
    
    // MARK: - Properties
    @Attribute(.unique) public var uuid: String
    public var type: String
    public var name: String
    public var label: String
    public var required: Bool
    public var value: String
    public var validationError: String?
    public var sortIndex: Int = 0
    
    // MARK: - Relationships
    public var form: FormEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \FormFieldOptionEntity.field)
    public var options: [FormFieldOptionEntity] = []
    
    // MARK: - Initialization
    public init(
        uuid: String,
        type: String,
        name: String,
        label: String,
        required: Bool = false,
        value: String = "",
        validationError: String? = nil,
        sortIndex: Int = 0
    ) {
        self.uuid = uuid
        self.type = type
        self.name = name
        self.label = label
        self.required = required
        self.value = value
        self.validationError = validationError
        self.sortIndex = sortIndex
    }
    
    // MARK: - Domain Conversion
    public func toDomain() -> FormField {
        return FormField(
            uuid: uuid,
            type: FieldType.from(type),
            name: name,
            label: label,
            required: required,
            options: options.map { $0.toDomain() },
            value: value,
            validationError: validationError
        )
    }
    
    public static func fromDomain(_ domain: FormField, sortIndex: Int = 0) -> FormFieldEntity {
        return FormFieldEntity(
            uuid: domain.uuid,
            type: domain.type.rawValue,
            name: domain.name,
            label: domain.label,
            required: domain.required,
            value: domain.value,
            validationError: domain.validationError,
            sortIndex: sortIndex
        )
    }
}

/// SwiftData model for FormFieldOption persistence
@available(iOS 17.0, macOS 14.0, *)
@Model
public final class FormFieldOptionEntity {
    
    // MARK: - Properties
    public var label: String
    public var value: String
    
    // MARK: - Relationships
    public var field: FormFieldEntity?
    
    // MARK: - Initialization
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    // MARK: - Domain Conversion
    public func toDomain() -> FieldOption {
        return FieldOption(label: label, value: value)
    }
    
    public static func fromDomain(_ domain: FieldOption) -> FormFieldOptionEntity {
        return FormFieldOptionEntity(label: domain.label, value: domain.value)
    }
}

/// SwiftData model for FormSection persistence
@available(iOS 17.0, macOS 14.0, *)
@Model
public final class FormSectionEntity {
    
    // MARK: - Properties
    @Attribute(.unique) public var uuid: String
    public var title: String
    public var fromIndex: Int
    public var toIndex: Int
    public var index: Int
    
    // MARK: - Relationships
    public var form: FormEntity?
    
    // MARK: - Initialization
    public init(
        uuid: String,
        title: String,
        fromIndex: Int,
        toIndex: Int,
        index: Int
    ) {
        self.uuid = uuid
        self.title = title
        self.fromIndex = fromIndex
        self.toIndex = toIndex
        self.index = index
    }
    
    // MARK: - Domain Conversion
    public func toDomain() -> FormSection {
        return FormSection(
            uuid: uuid,
            title: title,
            from: fromIndex,
            to: toIndex,
            index: index,
            fields: [] // Fields will be populated from form relationship
        )
    }
    
    public static func fromDomain(_ domain: FormSection) -> FormSectionEntity {
        return FormSectionEntity(
            uuid: domain.uuid,
            title: domain.title,
            fromIndex: domain.from,
            toIndex: domain.to,
            index: domain.index
        )
    }
}

/// SwiftData model for FormEntry persistence
@available(iOS 17.0, macOS 14.0, *)
@Model
public final class FormEntryEntity {
    
    // MARK: - Properties
    @Attribute(.unique) public var id: String
    public var sourceEntryId: String?
    public var fieldValuesData: Data // JSON serialized [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var isComplete: Bool
    public var isDraft: Bool
    
    // MARK: - Relationships
    public var form: FormEntity?
    
    // MARK: - Initialization
    public init(
        id: String,
        sourceEntryId: String? = nil,
        fieldValuesData: Data = Data(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isComplete: Bool = false,
        isDraft: Bool = true
    ) {
        self.id = id
        self.sourceEntryId = sourceEntryId
        self.fieldValuesData = fieldValuesData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isComplete = isComplete
        self.isDraft = isDraft
    }
    
    // MARK: - Field Values Handling
    public var fieldValues: [String: String] {
        get {
            do {
                return try JSONDecoder().decode([String: String].self, from: fieldValuesData)
            } catch {
                return [:]
            }
        }
        set {
            do {
                fieldValuesData = try JSONEncoder().encode(newValue)
            } catch {
                fieldValuesData = Data()
            }
        }
    }
    
    // MARK: - Domain Conversion
    public func toDomain() -> FormEntry {
        return FormEntry(
            id: id,
            formId: form?.id ?? "",
            sourceEntryId: sourceEntryId,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isComplete: isComplete,
            isDraft: isDraft
        )
    }
    
    public static func fromDomain(_ domain: FormEntry) -> FormEntryEntity {
        let entity = FormEntryEntity(
            id: domain.id,
            sourceEntryId: domain.sourceEntryId,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt,
            isComplete: domain.isComplete,
            isDraft: domain.isDraft
        )
        
        entity.fieldValues = domain.fieldValues
        return entity
    }
}