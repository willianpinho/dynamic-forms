import Foundation
import Combine
import Domain
import Utilities

/// ViewModel for form entries feature following MVVM pattern
/// Manages entry list state and business logic using Combine
@MainActor
public final class FormEntriesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var uiState: FormEntriesUiState = .loading
    @Published public var selectedFilter: EntryFilter = .all
    @Published public var searchText: String = ""
    @Published public var isSelectionMode: Bool = false
    @Published public var selectedEntries: Set<String> = []
    @Published public var showingBulkActionSheet: Bool = false
    @Published public var selectedSortOption: EntrySortOption = .updatedDateDescending
    @Published public var showingSortOptions: Bool = false
    
    // MARK: - Dependencies
    private let form: DynamicForm
    private let getFormEntriesUseCase: GetFormEntriesUseCase
    private let deleteFormEntryUseCase: DeleteFormEntryUseCase
    private let logger: Logger
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var allEntries: [FormEntry] = []
    
    // MARK: - Initialization
    public init(
        form: DynamicForm,
        getFormEntriesUseCase: GetFormEntriesUseCase,
        deleteFormEntryUseCase: DeleteFormEntryUseCase,
        logger: Logger = ConsoleLogger()
    ) {
        self.form = form
        self.getFormEntriesUseCase = getFormEntriesUseCase
        self.deleteFormEntryUseCase = deleteFormEntryUseCase
        self.logger = logger
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Get the form title
    public var formTitle: String {
        return form.title
    }
    
    /// Load entries for the form
    public func loadEntries() {
        logger.debug("Loading entries for form: \(form.title)")
        uiState = .loading
        
        Task {
            do {
                let entries = try await getFormEntriesUseCase.execute(formId: form.id)
                allEntries = entries.sorted { $0.updatedAt > $1.updatedAt }
                
                if entries.isEmpty {
                    await updateUIState(.empty)
                } else {
                    await updateUIState(.loaded(entries))
                }
                
                logger.info("Successfully loaded \(entries.count) entries")
                
            } catch {
                logger.error("Failed to load entries: \(error.localizedDescription)")
                await updateUIState(.error(error.localizedDescription))
            }
        }
    }
    
    /// Refresh entries
    public func refreshEntries() {
        logger.debug("Refreshing entries...")
        loadEntries()
    }
    
    /// Delete entry
    public func deleteEntry(_ entry: FormEntry) {
        logger.debug("Deleting entry: \(entry.id)")
        
        Task {
            do {
                let result = await deleteFormEntryUseCase.execute(entryId: entry.id)
                
                switch result {
                case .success:
                    // Remove from local cache
                    allEntries.removeAll { $0.id == entry.id }
                    await applyFilters()
                    logger.info("Entry deleted successfully")
                    
                case .failure(let error):
                    logger.error("Failed to delete entry: \(error.localizedDescription)")
                    await updateUIState(.error(error.localizedDescription))
                }
                
            } catch {
                logger.error("Error deleting entry: \(error.localizedDescription)")
                await updateUIState(.error(error.localizedDescription))
            }
        }
    }
    
    /// Create new entry
    public func createNewEntry() {
        logger.debug("Creating new entry for form: \(form.title)")
        // Navigation will be handled by coordinator
    }
    
    /// Edit existing entry
    public func editEntry(_ entry: FormEntry) {
        logger.debug("Editing entry: \(entry.id)")
        // Navigation will be handled by coordinator
    }
    
    /// Create edit draft from completed entry
    public func createEditDraft(from entry: FormEntry) {
        logger.debug("Creating edit draft from entry: \(entry.id)")
        // This will create a new draft based on the completed entry
        // Navigation will be handled by coordinator
    }
    
    /// Update filter
    public func updateFilter(_ filter: EntryFilter) {
        selectedFilter = filter
        applyFilters()
    }
    
    /// Update sort option
    public func updateSortOption(_ sortOption: EntrySortOption) {
        selectedSortOption = sortOption
        applyFilters()
    }
    
    /// Show sort options
    public func showSortOptions() {
        showingSortOptions = true
    }
    
    /// Hide sort options
    public func hideSortOptions() {
        showingSortOptions = false
    }
    
    /// Clear search
    public func clearSearch() {
        searchText = ""
        applyFilters()
    }
    
    /// Retry loading after error
    public func retryLoading() {
        logger.debug("Retrying entries load...")
        loadEntries()
    }
    
    // MARK: - Selection Mode Methods
    
    /// Toggle selection mode
    public func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedEntries.removeAll()
        }
        logger.debug("Selection mode: \(isSelectionMode)")
    }
    
    /// Toggle entry selection
    public func toggleEntrySelection(_ entryId: String) {
        if selectedEntries.contains(entryId) {
            selectedEntries.remove(entryId)
        } else {
            selectedEntries.insert(entryId)
        }
        logger.debug("Selected entries: \(selectedEntries.count)")
    }
    
    /// Select all visible entries
    public func selectAllEntries() {
        if case .loaded(let entries) = uiState {
            selectedEntries = Set(entries.map { $0.id })
            logger.debug("Selected all \(entries.count) entries")
        }
    }
    
    /// Deselect all entries
    public func deselectAllEntries() {
        selectedEntries.removeAll()
        logger.debug("Deselected all entries")
    }
    
    /// Show bulk action sheet
    public func showBulkActions() {
        guard !selectedEntries.isEmpty else { return }
        showingBulkActionSheet = true
    }
    
    /// Hide bulk action sheet
    public func hideBulkActions() {
        showingBulkActionSheet = false
    }
    
    /// Bulk export selected entries
    public func bulkExportEntries() {
        guard !selectedEntries.isEmpty else { return }
        
        let entriesToExport = allEntries.filter { selectedEntries.contains($0.id) }
        let exportData = exportEntries(entriesToExport)
        
        logger.info("Exported \(entriesToExport.count) entries")
        
        // In a real app, you would use sharing functionality here
        // For now, we'll just log the data
        print("Export Data:", exportData)
        
        // Reset selection
        selectedEntries.removeAll()
        isSelectionMode = false
        showingBulkActionSheet = false
    }
    
    /// Bulk delete selected entries
    public func bulkDeleteSelectedEntries() {
        guard !selectedEntries.isEmpty else { return }
        
        let entriesToDelete = allEntries.filter { selectedEntries.contains($0.id) }
        bulkDeleteEntries(entriesToDelete)
        
        // Reset selection
        selectedEntries.removeAll()
        isSelectionMode = false
        showingBulkActionSheet = false
    }
    
    /// Export entries to JSON
    private func exportEntries(_ entries: [FormEntry]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(entries)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            logger.error("Failed to export entries: \(error.localizedDescription)")
            return ""
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Search text binding with debouncing
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Filter binding
        $selectedFilter
            .dropFirst()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var filteredEntries = allEntries
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break // No filtering
        case .drafts:
            filteredEntries = filteredEntries.filter { $0.isDraft }
        case .completed:
            filteredEntries = filteredEntries.filter { !$0.isDraft && $0.isComplete }
        case .editDrafts:
            filteredEntries = filteredEntries.filter { $0.isEditDraft }
        }
        
        // Apply enhanced search filter
        if !searchText.isEmpty {
            filteredEntries = filteredEntries.filter { entry in
                searchInEntry(entry, searchText: searchText)
            }
        }
        
        // Apply sorting
        filteredEntries = applySorting(to: filteredEntries, using: selectedSortOption)
        
        if filteredEntries.isEmpty && !allEntries.isEmpty {
            uiState = .empty
        } else if !filteredEntries.isEmpty {
            uiState = .loaded(filteredEntries)
        }
    }
    
    private func updateUIState(_ newState: FormEntriesUiState) async {
        await MainActor.run {
            self.uiState = newState
        }
    }
    
    /// Enhanced search function that searches across multiple entry properties
    private func searchInEntry(_ entry: FormEntry, searchText: String) -> Bool {
        let lowercaseSearchText = searchText.lowercased()
        
        // Search in generated display title
        if entry.generateDisplayTitle().lowercased().contains(lowercaseSearchText) {
            return true
        }
        
        // Search in generated display subtitle
        if entry.generateDisplaySubtitle().lowercased().contains(lowercaseSearchText) {
            return true
        }
        
        // Search in entry ID
        if entry.id.lowercased().contains(lowercaseSearchText) {
            return true
        }
        
        // Search in source entry ID (for edit drafts)
        if let sourceId = entry.sourceEntryId,
           sourceId.lowercased().contains(lowercaseSearchText) {
            return true
        }
        
        // Search in status
        if entry.status.displayName.lowercased().contains(lowercaseSearchText) {
            return true
        }
        
        // Search in field values (existing functionality)
        if entry.fieldValues.values.contains(where: { value in
            value.localizedCaseInsensitiveContains(searchText)
        }) {
            return true
        }
        
        // Search in field keys (field names/UUIDs)
        if entry.fieldValues.keys.contains(where: { key in
            key.localizedCaseInsensitiveContains(searchText)
        }) {
            return true
        }
        
        // Search in formatted dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        if dateFormatter.string(from: entry.createdAt).lowercased().contains(lowercaseSearchText) ||
           dateFormatter.string(from: entry.updatedAt).lowercased().contains(lowercaseSearchText) {
            return true
        }
        
        return false
    }
    
    /// Apply sorting to entries
    private func applySorting(to entries: [FormEntry], using sortOption: EntrySortOption) -> [FormEntry] {
        switch sortOption {
        case .updatedDateDescending:
            return entries.sorted { $0.updatedAt > $1.updatedAt }
        case .updatedDateAscending:
            return entries.sorted { $0.updatedAt < $1.updatedAt }
        case .createdDateDescending:
            return entries.sorted { $0.createdAt > $1.createdAt }
        case .createdDateAscending:
            return entries.sorted { $0.createdAt < $1.createdAt }
        }
    }
}

// MARK: - UI State
public enum FormEntriesUiState: Equatable {
    case loading
    case loaded([FormEntry])
    case empty
    case error(String)
    
    public static func == (lhs: FormEntriesUiState, rhs: FormEntriesUiState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded(let lhsEntries), .loaded(let rhsEntries)):
            return lhsEntries.map(\.id) == rhsEntries.map(\.id)
        case (.empty, .empty):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Entry Filter
public enum EntryFilter: String, CaseIterable {
    case all = "all"
    case drafts = "drafts"
    case completed = "completed"
    case editDrafts = "edit_drafts"
    
    public var displayName: String {
        switch self {
        case .all:
            return "All Entries"
        case .drafts:
            return "Drafts"
        case .completed:
            return "Completed"
        case .editDrafts:
            return "Edit Drafts"
        }
    }
    
    public var iconName: String {
        switch self {
        case .all:
            return "list.bullet"
        case .drafts:
            return "doc.text"
        case .completed:
            return "checkmark.circle"
        case .editDrafts:
            return "pencil.circle"
        }
    }
}

// MARK: - UI State Extensions
public extension FormEntriesUiState {
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var entries: [FormEntry] {
        if case .loaded(let entries) = self {
            return entries
        }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
    
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
}

// MARK: - Statistics and Advanced Features
public extension FormEntriesViewModel {
    
    /// Get entry statistics for the current form
    func getEntryStatistics() -> EntryStatistics {
        let draftCount = allEntries.filter { $0.isDraft && !$0.isEditDraft }.count
        let editDraftCount = allEntries.filter { $0.isEditDraft }.count
        let completedCount = allEntries.filter { $0.isComplete }.count
        let submittedCount = allEntries.filter { !$0.isDraft && !$0.isComplete }.count
        
        return EntryStatistics(
            totalEntries: allEntries.count,
            draftEntries: draftCount,
            editDraftEntries: editDraftCount,
            completedEntries: completedCount,
            submittedEntries: submittedCount,
            lastUpdated: allEntries.max(by: { $0.updatedAt < $1.updatedAt })?.updatedAt
        )
    }
    
    /// Bulk delete selected entries
    func bulkDeleteEntries(_ entries: [FormEntry]) {
        logger.debug("Bulk deleting \(entries.count) entries")
        
        Task {
            for entry in entries {
                let result = await deleteFormEntryUseCase.execute(entryId: entry.id)
                
                switch result {
                case .success:
                    // Remove from local cache
                    allEntries.removeAll { $0.id == entry.id }
                case .failure(let error):
                    logger.error("Failed to delete entry \(entry.id): \(error.localizedDescription)")
                }
            }
            
            await applyFilters()
            logger.info("Bulk delete completed")
        }
    }
    
    /// Archive old entries (mark them as archived instead of deleting)
    func archiveOldEntries(olderThan days: Int) {
        logger.debug("Archiving entries older than \(days) days")
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oldEntries = allEntries.filter { $0.createdAt < cutoffDate }
        
        Task {
            for entry in oldEntries {
                // In a real implementation, you would call an archive use case
                logger.debug("Would archive entry: \(entry.id)")
            }
        }
    }
    
    /// Export entries data (for backup or analysis)
    func exportEntriesData() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(allEntries)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            logger.error("Failed to export entries: \(error.localizedDescription)")
            return ""
        }
    }
}

// MARK: - Entry Statistics
public struct EntryStatistics {
    public let totalEntries: Int
    public let draftEntries: Int
    public let editDraftEntries: Int
    public let completedEntries: Int
    public let submittedEntries: Int
    public let lastUpdated: Date?
    
    public init(
        totalEntries: Int,
        draftEntries: Int,
        editDraftEntries: Int,
        completedEntries: Int,
        submittedEntries: Int,
        lastUpdated: Date?
    ) {
        self.totalEntries = totalEntries
        self.draftEntries = draftEntries
        self.editDraftEntries = editDraftEntries
        self.completedEntries = completedEntries
        self.submittedEntries = submittedEntries
        self.lastUpdated = lastUpdated
    }
    
    public var completionRate: Double {
        guard totalEntries > 0 else { return 0.0 }
        return Double(completedEntries) / Double(totalEntries)
    }
    
    public var draftRate: Double {
        guard totalEntries > 0 else { return 0.0 }
        return Double(draftEntries + editDraftEntries) / Double(totalEntries)
    }
}