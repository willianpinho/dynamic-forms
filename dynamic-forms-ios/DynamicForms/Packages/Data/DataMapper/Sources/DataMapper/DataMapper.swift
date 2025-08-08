import Foundation
import Domain
import Utilities

/// Data mapper for Dynamic Forms
/// Handles conversion between different data representations
public struct DataMapper {
    
    /// DataMapper version
    public static let version = "1.0.0"
    
    /// Initialize data mapper
    public static func configure() {
        setupMappers()
    }
    
    private static func setupMappers() {
        // Configure data mappers
    }
}

// MARK: - Form Mappers
public protocol FormMapper {
    func mapToDomain(_ data: [String: Any]) throws -> DynamicForm
    func mapFromDomain(_ form: DynamicForm) -> [String: Any]
}

public struct FormMapperImpl: FormMapper {
    
    private let logger: Logger
    
    public init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
    }
    
    public func mapToDomain(_ data: [String: Any]) throws -> DynamicForm {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String else {
            throw DataMapperError.invalidData("Missing required form fields")
        }
        
        let fieldsData = data["fields"] as? [[String: Any]] ?? []
        let sectionsData = data["sections"] as? [[String: Any]] ?? []
        
        let fields = try fieldsData.map { try mapFieldToDomain($0) }
        let sections = try sectionsData
            .map { try mapSectionToDomain($0) }
            .sorted { $0.index < $1.index }
        
        return DynamicForm(
            id: id,
            title: title,
            fields: fields,
            sections: sections
        )
    }
    
    public func mapFromDomain(_ form: DynamicForm) -> [String: Any] {
        return [
            "id": form.id,
            "title": form.title,
            "fields": form.fields.map { mapFieldFromDomain($0) },
            "sections": form.sections.map { mapSectionFromDomain($0) }
        ]
    }
    
    private func mapFieldToDomain(_ data: [String: Any]) throws -> FormField {
        guard let uuid = data["uuid"] as? String,
              let typeString = data["type"] as? String,
              let name = data["name"] as? String,
              let label = data["label"] as? String else {
            throw DataMapperError.invalidData("Missing required field data")
        }
        
        let type = FieldType.from(typeString)
        let required = data["required"] as? Bool ?? false
        let value = data["value"] as? String ?? ""
        let optionsData = data["options"] as? [[String: Any]] ?? []
        
        let options = optionsData.compactMap { optionData -> FieldOption? in
            guard let label = optionData["label"] as? String,
                  let value = optionData["value"] as? String else {
                return nil
            }
            return FieldOption(label: label, value: value)
        }
        
        return FormField(
            uuid: uuid,
            type: type,
            name: name,
            label: label,
            required: required,
            options: options,
            value: value
        )
    }
    
    private func mapFieldFromDomain(_ field: FormField) -> [String: Any] {
        var data: [String: Any] = [
            "uuid": field.uuid,
            "type": field.type.rawValue,
            "name": field.name,
            "label": field.label,
            "required": field.required,
            "value": field.value
        ]
        
        if !field.options.isEmpty {
            data["options"] = field.options.map { option in
                [
                    "label": option.label,
                    "value": option.value
                ]
            }
        }
        
        return data
    }
    
    private func mapSectionToDomain(_ data: [String: Any]) throws -> FormSection {
        guard let uuid = data["uuid"] as? String,
              let title = data["title"] as? String,
              let from = data["from"] as? Int,
              let to = data["to"] as? Int,
              let index = data["index"] as? Int else {
            throw DataMapperError.invalidData("Missing required section data")
        }
        
        return FormSection(
            uuid: uuid,
            title: title,
            from: from,
            to: to,
            index: index
        )
    }
    
    private func mapSectionFromDomain(_ section: FormSection) -> [String: Any] {
        return [
            "uuid": section.uuid,
            "title": section.title,
            "from": section.from,
            "to": section.to,
            "index": section.index
        ]
    }
}

// MARK: - Form Entry Mappers
public protocol FormEntryMapper {
    func mapToDomain(_ data: [String: Any]) throws -> FormEntry
    func mapFromDomain(_ entry: FormEntry) -> [String: Any]
}

public struct FormEntryMapperImpl: FormEntryMapper {
    
    private let logger: Logger
    
    public init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
    }
    
    public func mapToDomain(_ data: [String: Any]) throws -> FormEntry {
        guard let id = data["id"] as? String,
              let formId = data["formId"] as? String else {
            throw DataMapperError.invalidData("Missing required entry fields")
        }
        
        let sourceEntryId = data["sourceEntryId"] as? String
        let fieldValues = data["fieldValues"] as? [String: String] ?? [:]
        let isComplete = data["isComplete"] as? Bool ?? false
        let isDraft = data["isDraft"] as? Bool ?? false
        
        let createdAtString = data["createdAt"] as? String
        let updatedAtString = data["updatedAt"] as? String
        
        let createdAt = createdAtString?.toDate ?? Date()
        let updatedAt = updatedAtString?.toDate ?? Date()
        
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isComplete: isComplete,
            isDraft: isDraft
        )
    }
    
    public func mapFromDomain(_ entry: FormEntry) -> [String: Any] {
        var data: [String: Any] = [
            "id": entry.id,
            "formId": entry.formId,
            "fieldValues": entry.fieldValues,
            "createdAt": DateFormatter.iso8601.string(from: entry.createdAt),
            "updatedAt": DateFormatter.iso8601.string(from: entry.updatedAt),
            "isComplete": entry.isComplete,
            "isDraft": entry.isDraft
        ]
        
        if let sourceEntryId = entry.sourceEntryId {
            data["sourceEntryId"] = sourceEntryId
        }
        
        return data
    }
}

// MARK: - Errors
public enum DataMapperError: Error, LocalizedError {
    case invalidData(String)
    case mappingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .mappingFailed(let message):
            return "Mapping failed: \(message)"
        }
    }
}