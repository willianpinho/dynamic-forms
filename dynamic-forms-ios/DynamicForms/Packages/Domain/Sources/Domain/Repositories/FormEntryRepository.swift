import Foundation
import Combine

/// Form entry repository interface defining data access operations for form entries
/// Following Repository Pattern and Dependency Inversion Principle
@available(iOS 13.0, macOS 10.15, *)
public protocol FormEntryRepository {
    
    // MARK: - Entry Operations
    
    /// Get all entries for a specific form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting array of FormEntry objects
    func getEntriesForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error>
    
    /// Get entry by ID
    /// - Parameter id: Entry identifier
    /// - Returns: Publisher emitting optional FormEntry
    func getEntryById(_ id: String) -> AnyPublisher<FormEntry?, Error>
    
    /// Insert new entry
    /// - Parameter entry: FormEntry to insert
    /// - Returns: Result containing entry ID or error
    func insertEntry(_ entry: FormEntry) async -> Result<String, Error>
    
    /// Update existing entry
    /// - Parameter entry: FormEntry to update
    /// - Returns: Result indicating success or failure
    func updateEntry(_ entry: FormEntry) async -> Result<Void, Error>
    
    /// Delete entry by ID
    /// - Parameter id: Entry identifier to delete
    /// - Returns: Result indicating success or failure
    func deleteEntry(_ id: String) async -> Result<Void, Error>
    
    // MARK: - Draft Operations
    
    /// Save entry as draft
    /// - Parameter entry: FormEntry to save as draft
    /// - Returns: Result indicating success or failure
    func saveEntryDraft(_ entry: FormEntry) async -> Result<Void, Error>
    
    /// Get current draft entry for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting optional draft FormEntry
    func getDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error>
    
    /// Delete draft entry for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Result indicating success or failure
    func deleteDraftEntry(_ formId: String) async -> Result<Void, Error>
    
    /// Get new draft entry for a form (not based on existing entry)
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting optional new draft FormEntry
    func getNewDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error>
    
    /// Get edit draft for an existing entry
    /// - Parameter entryId: Original entry identifier
    /// - Returns: Publisher emitting optional edit draft FormEntry
    func getEditDraftForEntry(_ entryId: String) -> AnyPublisher<FormEntry?, Error>
    
    /// Get all drafts for a form (both new and edit drafts)
    /// - Parameter formId: Form identifier
    /// - Returns: Publisher emitting array of draft FormEntry objects
    func getAllDraftsForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error>
    
    /// Delete all edit drafts for an entry
    /// - Parameter entryId: Original entry identifier
    /// - Returns: Result indicating success or failure
    func deleteEditDraftsForEntry(_ entryId: String) async -> Result<Void, Error>
    
    // MARK: - Search and Filtering
    
    /// Get entries by status
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - isDraft: Filter by draft status
    ///   - isComplete: Filter by completion status
    /// - Returns: Publisher emitting filtered entries
    func getEntriesByStatus(formId: String, isDraft: Bool?, isComplete: Bool?) -> AnyPublisher<[FormEntry], Error>
    
    /// Get entries created within date range
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - startDate: Start date for range
    ///   - endDate: End date for range
    /// - Returns: Publisher emitting filtered entries
    func getEntriesInDateRange(formId: String, from startDate: Date, to endDate: Date) -> AnyPublisher<[FormEntry], Error>
}

// MARK: - Repository Error Types
public enum FormEntryRepositoryError: Error, LocalizedError {
    case entryNotFound(String)
    case invalidEntryData(String)
    case persistenceError(String)
    case draftNotFound(String)
    case conflictError(String)
    
    public var errorDescription: String? {
        switch self {
        case .entryNotFound(let id):
            return "Entry with ID '\(id)' not found"
        case .invalidEntryData(let reason):
            return "Invalid entry data: \(reason)"
        case .persistenceError(let reason):
            return "Persistence error: \(reason)"
        case .draftNotFound(let formId):
            return "Draft for form '\(formId)' not found"
        case .conflictError(let reason):
            return "Conflict error: \(reason)"
        }
    }
}

// MARK: - Repository Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension FormEntryRepository {
    
    /// Get entry by ID with async/await
    /// - Parameter id: Entry identifier
    /// - Returns: Optional FormEntry
    func getEntry(by id: String) async throws -> FormEntry? {
        return try await getEntryById(id)
            .async()
    }
    
    /// Get entries for form with async/await
    /// - Parameter formId: Form identifier
    /// - Returns: Array of FormEntry objects
    func getEntries(for formId: String) async throws -> [FormEntry] {
        return try await getEntriesForForm(formId)
            .async()
    }
    
    /// Get draft entry with async/await
    /// - Parameter formId: Form identifier
    /// - Returns: Optional draft FormEntry
    func getDraft(for formId: String) async throws -> FormEntry? {
        return try await getDraftEntry(formId)
            .async()
    }
    
    /// Check if entry exists
    /// - Parameter id: Entry identifier
    /// - Returns: Boolean indicating existence
    func entryExists(_ id: String) async -> Bool {
        do {
            let entry = try await getEntry(by: id)
            return entry != nil
        } catch {
            return false
        }
    }
    
    /// Check if draft exists for form
    /// - Parameter formId: Form identifier
    /// - Returns: Boolean indicating existence
    func draftExists(for formId: String) async -> Bool {
        do {
            let draft = try await getDraft(for: formId)
            return draft != nil
        } catch {
            return false
        }
    }
    
    /// Get entries count for form
    /// - Parameter formId: Form identifier
    /// - Returns: Total number of entries
    func getEntriesCount(for formId: String) async throws -> Int {
        let entries = try await getEntries(for: formId)
        return entries.count
    }
    
    /// Get completed entries for form
    /// - Parameter formId: Form identifier
    /// - Returns: Array of completed FormEntry objects
    func getCompletedEntries(for formId: String) async throws -> [FormEntry] {
        return try await getEntriesByStatus(formId: formId, isDraft: false, isComplete: true)
            .async()
    }
    
    /// Get draft entries for form
    /// - Parameter formId: Form identifier
    /// - Returns: Array of draft FormEntry objects
    func getDraftEntries(for formId: String) async throws -> [FormEntry] {
        return try await getEntriesByStatus(formId: formId, isDraft: true, isComplete: nil)
            .async()
    }
}

// MARK: - Mock Repository for Testing Only
// Note: Production code now uses FormEntryRepositorySwiftData or FormEntryRepositoryImpl
// This mock is kept only for unit tests
#if DEBUG
@available(iOS 13.0, macOS 10.15, *)
public final class MockFormEntryRepository: FormEntryRepository {
    
    private var entries: [FormEntry] = []
    
    public init(entries: [FormEntry] = []) {
        self.entries = entries
    }
    
    public func getEntriesForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        let formEntries = entries.filter { $0.formId == formId }
        return Just(formEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getEntryById(_ id: String) -> AnyPublisher<FormEntry?, Error> {
        let entry = entries.first { $0.id == id }
        return Just(entry)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func insertEntry(_ entry: FormEntry) async -> Result<String, Error> {
        entries.append(entry)
        return .success(entry.id)
    }
    
    public func updateEntry(_ entry: FormEntry) async -> Result<Void, Error> {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            return .success(())
        } else {
            return .failure(FormEntryRepositoryError.entryNotFound(entry.id))
        }
    }
    
    public func deleteEntry(_ id: String) async -> Result<Void, Error> {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries.remove(at: index)
            return .success(())
        } else {
            return .failure(FormEntryRepositoryError.entryNotFound(id))
        }
    }
    
    public func saveEntryDraft(_ entry: FormEntry) async -> Result<Void, Error> {
        let draftEntry = entry.markAsDraft()
        
        // Check if entry already exists
        if let existingIndex = entries.firstIndex(where: { $0.id == draftEntry.id }) {
            // Update existing entry
            entries[existingIndex] = draftEntry
            return .success(())
        } else {
            // Insert new entry
            entries.append(draftEntry)
            return .success(())
        }
    }
    
    public func getDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        let draft = entries.first { $0.formId == formId && $0.isDraft }
        return Just(draft)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func deleteDraftEntry(_ formId: String) async -> Result<Void, Error> {
        if let index = entries.firstIndex(where: { $0.formId == formId && $0.isDraft }) {
            entries.remove(at: index)
            return .success(())
        } else {
            return .failure(FormEntryRepositoryError.draftNotFound(formId))
        }
    }
    
    public func getNewDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        let newDraft = entries.first { $0.formId == formId && $0.isNewDraft }
        return Just(newDraft)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getEditDraftForEntry(_ entryId: String) -> AnyPublisher<FormEntry?, Error> {
        let editDraft = entries.first { $0.sourceEntryId == entryId && $0.isEditDraft }
        return Just(editDraft)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getAllDraftsForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        let drafts = entries.filter { $0.formId == formId && $0.isDraft }
        return Just(drafts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func deleteEditDraftsForEntry(_ entryId: String) async -> Result<Void, Error> {
        entries.removeAll { $0.sourceEntryId == entryId && $0.isEditDraft }
        return .success(())
    }
    
    public func getEntriesByStatus(formId: String, isDraft: Bool?, isComplete: Bool?) -> AnyPublisher<[FormEntry], Error> {
        let filteredEntries = entries.filter { entry in
            guard entry.formId == formId else { return false }
            
            if let isDraft = isDraft, entry.isDraft != isDraft {
                return false
            }
            
            if let isComplete = isComplete, entry.isComplete != isComplete {
                return false
            }
            
            return true
        }
        
        return Just(filteredEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getEntriesInDateRange(formId: String, from startDate: Date, to endDate: Date) -> AnyPublisher<[FormEntry], Error> {
        let filteredEntries = entries.filter { entry in
            entry.formId == formId && 
            entry.createdAt >= startDate && 
            entry.createdAt <= endDate
        }
        
        return Just(filteredEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Test Helpers
    public func addEntry(_ entry: FormEntry) {
        entries.append(entry)
    }
    
    public func clearEntries() {
        entries.removeAll()
    }
    
    public func getEntriesCount() -> Int {
        return entries.count
    }
}
#endif