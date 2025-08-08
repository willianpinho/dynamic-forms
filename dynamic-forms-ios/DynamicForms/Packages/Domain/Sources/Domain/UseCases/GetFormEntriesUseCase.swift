import Foundation
import Combine

/// Use case for retrieving form entries for a specific form
/// Following Single Responsibility Principle and Clean Architecture
@available(iOS 13.0, macOS 10.15, *)
public final class GetFormEntriesUseCase {
    
    // MARK: - Dependencies
    private let formEntryRepository: FormEntryRepository
    
    // MARK: - Initialization
    public init(formEntryRepository: FormEntryRepository) {
        self.formEntryRepository = formEntryRepository
    }
    
    // MARK: - Execution
    
    /// Execute use case to get entries for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting array of FormEntry objects
    public func execute(formId: String) -> AnyPublisher<[FormEntry], Error> {
        return formEntryRepository.getEntriesForForm(formId)
            .map { entries in
                // Sort entries by updated date (newest first)
                entries.sorted { $0.updatedAt > $1.updatedAt }
            }
            .eraseToAnyPublisher()
    }
    
    /// Execute use case with async/await
    /// - Parameter formId: Form identifier
    /// - Returns: Array of FormEntry objects
    public func execute(formId: String) async throws -> [FormEntry] {
        let entries = try await formEntryRepository.getEntriesForForm(formId).async()
        // Sort entries by updated date (newest first)
        return entries.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// Execute use case with filtering options
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - filter: Entry filter options
    /// - Returns: Publisher emitting filtered array of FormEntry objects
    public func execute(formId: String, filter: EntryFilterOptions) -> AnyPublisher<[FormEntry], Error> {
        return formEntryRepository.getEntriesForForm(formId)
            .map { entries in
                self.applyFilter(entries, filter: filter)
            }
            .eraseToAnyPublisher()
    }
    
    /// Get entries by status
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - isDraft: Filter by draft status
    ///   - isComplete: Filter by completion status
    /// - Returns: Publisher emitting filtered entries
    public func getEntriesByStatus(
        formId: String,
        isDraft: Bool? = nil,
        isComplete: Bool? = nil
    ) -> AnyPublisher<[FormEntry], Error> {
        return formEntryRepository.getEntriesByStatus(
            formId: formId,
            isDraft: isDraft,
            isComplete: isComplete
        )
        .map { entries in
            entries.sorted { $0.updatedAt > $1.updatedAt }
        }
        .eraseToAnyPublisher()
    }
    
    /// Get draft entries for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting draft entries
    public func getDraftEntries(formId: String) -> AnyPublisher<[FormEntry], Error> {
        return getEntriesByStatus(formId: formId, isDraft: true)
    }
    
    /// Get completed entries for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting completed entries
    public func getCompletedEntries(formId: String) -> AnyPublisher<[FormEntry], Error> {
        return getEntriesByStatus(formId: formId, isDraft: false, isComplete: true)
    }
    
    /// Get edit drafts for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting edit draft entries
    public func getEditDrafts(formId: String) -> AnyPublisher<[FormEntry], Error> {
        return formEntryRepository.getAllDraftsForForm(formId)
            .map { entries in
                entries.filter { $0.isEditDraft }
                    .sorted { $0.updatedAt > $1.updatedAt }
            }
            .eraseToAnyPublisher()
    }
    
    /// Get entries in date range
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - startDate: Start date for range
    ///   - endDate: End date for range
    /// - Returns: Publisher emitting filtered entries
    public func getEntriesInDateRange(
        formId: String,
        from startDate: Date,
        to endDate: Date
    ) -> AnyPublisher<[FormEntry], Error> {
        return formEntryRepository.getEntriesInDateRange(
            formId: formId,
            from: startDate,
            to: endDate
        )
        .map { entries in
            entries.sorted { $0.updatedAt > $1.updatedAt }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func applyFilter(_ entries: [FormEntry], filter: EntryFilterOptions) -> [FormEntry] {
        var filteredEntries = entries
        
        // Apply status filter
        if let statusFilter = filter.status {
            switch statusFilter {
            case .draft:
                filteredEntries = filteredEntries.filter { $0.isDraft && !$0.isEditDraft }
            case .editDraft:
                filteredEntries = filteredEntries.filter { $0.isEditDraft }
            case .completed:
                filteredEntries = filteredEntries.filter { $0.isComplete && !$0.isDraft }
            case .all:
                break // No filtering
            }
        }
        
        // Apply date range filter
        if let dateRange = filter.dateRange {
            filteredEntries = filteredEntries.filter { entry in
                entry.createdAt >= dateRange.start && entry.createdAt <= dateRange.end
            }
        }
        
        // Apply search filter
        if let searchText = filter.searchText, !searchText.isEmpty {
            filteredEntries = filteredEntries.filter { entry in
                entry.fieldValues.values.contains { value in
                    value.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply sorting
        switch filter.sortOption {
        case .updatedDateDescending:
            filteredEntries = filteredEntries.sorted { $0.updatedAt > $1.updatedAt }
        case .updatedDateAscending:
            filteredEntries = filteredEntries.sorted { $0.updatedAt < $1.updatedAt }
        case .createdDateDescending:
            filteredEntries = filteredEntries.sorted { $0.createdAt > $1.createdAt }
        case .createdDateAscending:
            filteredEntries = filteredEntries.sorted { $0.createdAt < $1.createdAt }
        }
        
        return filteredEntries
    }
}

// MARK: - Filter Options
public struct EntryFilterOptions {
    public let status: EntryStatusFilter?
    public let dateRange: DateRange?
    public let searchText: String?
    public let sortOption: EntrySortOption
    
    public init(
        status: EntryStatusFilter? = nil,
        dateRange: DateRange? = nil,
        searchText: String? = nil,
        sortOption: EntrySortOption = .updatedDateDescending
    ) {
        self.status = status
        self.dateRange = dateRange
        self.searchText = searchText
        self.sortOption = sortOption
    }
}

public enum EntryStatusFilter: String, CaseIterable {
    case all = "all"
    case draft = "draft"
    case editDraft = "edit_draft"
    case completed = "completed"
    
    public var displayName: String {
        switch self {
        case .all:
            return "All"
        case .draft:
            return "Drafts"
        case .editDraft:
            return "Edit Drafts"
        case .completed:
            return "Completed"
        }
    }
}

public enum EntrySortOption: String, CaseIterable {
    case updatedDateDescending = "updated_desc"
    case updatedDateAscending = "updated_asc"
    case createdDateDescending = "created_desc"
    case createdDateAscending = "created_asc"
    
    public var displayName: String {
        switch self {
        case .updatedDateDescending:
            return "Recently Updated"
        case .updatedDateAscending:
            return "Least Recently Updated"
        case .createdDateDescending:
            return "Newest First"
        case .createdDateAscending:
            return "Oldest First"
        }
    }
}

public struct DateRange {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

// MARK: - Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension GetFormEntriesUseCase {
    
    /// Get entry statistics for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting entry statistics
    func getEntryStatistics(formId: String) -> AnyPublisher<EntryStatistics, Error> {
        return formEntryRepository.getEntriesForForm(formId)
            .map { entries in
                EntryStatistics(
                    totalEntries: entries.count,
                    draftEntries: entries.filter { $0.isDraft && !$0.isEditDraft }.count,
                    editDraftEntries: entries.filter { $0.isEditDraft }.count,
                    completedEntries: entries.filter { $0.isComplete && !$0.isDraft }.count,
                    lastUpdated: entries.max(by: { $0.updatedAt < $1.updatedAt })?.updatedAt
                )
            }
            .eraseToAnyPublisher()
    }
}

public struct EntryStatistics {
    public let totalEntries: Int
    public let draftEntries: Int
    public let editDraftEntries: Int
    public let completedEntries: Int
    public let lastUpdated: Date?
    
    public init(
        totalEntries: Int,
        draftEntries: Int,
        editDraftEntries: Int,
        completedEntries: Int,
        lastUpdated: Date?
    ) {
        self.totalEntries = totalEntries
        self.draftEntries = draftEntries
        self.editDraftEntries = editDraftEntries
        self.completedEntries = completedEntries
        self.lastUpdated = lastUpdated
    }
}