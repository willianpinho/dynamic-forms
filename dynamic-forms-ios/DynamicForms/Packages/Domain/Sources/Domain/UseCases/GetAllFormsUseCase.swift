import Foundation
import Combine

/// Use case for retrieving all available forms
/// Following Single Responsibility Principle and Clean Architecture
@available(iOS 13.0, macOS 10.15, *)
public final class GetAllFormsUseCase {
    
    // MARK: - Dependencies
    private let formRepository: FormRepository
    
    // MARK: - Initialization
    public init(formRepository: FormRepository) {
        self.formRepository = formRepository
    }
    
    // MARK: - Execution
    

    
    /// Execute use case with async/await
    /// - Returns: Array of DynamicForm objects
    public func execute() async throws -> [DynamicForm] {
        let forms = try await formRepository.getAllForms()
        // Sort forms by creation date (newest first)
        return forms.sorted { $0.createdAt > $1.createdAt }
    }
    

    
    // MARK: - Private Methods
    
    private func sortForms(_ forms: [DynamicForm], by sortOption: FormSortOption) -> [DynamicForm] {
        switch sortOption {
        case .titleAscending:
            return forms.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDescending:
            return forms.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .createdDateAscending:
            return forms.sorted { $0.createdAt < $1.createdAt }
        case .createdDateDescending:
            return forms.sorted { $0.createdAt > $1.createdAt }
        case .updatedDateAscending:
            return forms.sorted { $0.updatedAt < $1.updatedAt }
        case .updatedDateDescending:
            return forms.sorted { $0.updatedAt > $1.updatedAt }
        case .fieldCountAscending:
            return forms.sorted { $0.fields.count < $1.fields.count }
        case .fieldCountDescending:
            return forms.sorted { $0.fields.count > $1.fields.count }
        }
    }
}

// MARK: - Sort Options
public enum FormSortOption: String, CaseIterable, Hashable {
    case titleAscending = "title_asc"
    case titleDescending = "title_desc"
    case createdDateAscending = "created_asc"
    case createdDateDescending = "created_desc"
    case updatedDateAscending = "updated_asc"
    case updatedDateDescending = "updated_desc"
    case fieldCountAscending = "fields_asc"
    case fieldCountDescending = "fields_desc"
    
    public var displayName: String {
        switch self {
        case .titleAscending:
            return "Title (A-Z)"
        case .titleDescending:
            return "Title (Z-A)"
        case .createdDateAscending:
            return "Oldest First"
        case .createdDateDescending:
            return "Newest First"
        case .updatedDateAscending:
            return "Least Recently Updated"
        case .updatedDateDescending:
            return "Most Recently Updated"
        case .fieldCountAscending:
            return "Fewest Fields"
        case .fieldCountDescending:
            return "Most Fields"
        }
    }
}



// MARK: - Supporting Types
public struct FormsWithStatistics {
    public let forms: [DynamicForm]
    public let statistics: FormsStatistics
    
    public init(forms: [DynamicForm], statistics: FormsStatistics) {
        self.forms = forms
        self.statistics = statistics
    }
}

public struct FormsStatistics {
    public let totalForms: Int
    public let totalFields: Int
    public let averageFieldsPerForm: Double
    public let formsWithSections: Int
    
    public init(totalForms: Int, totalFields: Int, averageFieldsPerForm: Double, formsWithSections: Int) {
        self.totalForms = totalForms
        self.totalFields = totalFields
        self.averageFieldsPerForm = averageFieldsPerForm
        self.formsWithSections = formsWithSections
    }
}