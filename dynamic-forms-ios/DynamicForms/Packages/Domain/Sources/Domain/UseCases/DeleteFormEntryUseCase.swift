import Foundation

/// Use case for deleting form entries
/// Following Single Responsibility Principle and Clean Architecture
@available(iOS 13.0, macOS 10.15, *)
public final class DeleteFormEntryUseCase {
    
    // MARK: - Dependencies
    private let formEntryRepository: FormEntryRepository
    
    // MARK: - Initialization
    public init(formEntryRepository: FormEntryRepository) {
        self.formEntryRepository = formEntryRepository
    }
    
    // MARK: - Execution
    
    /// Delete a form entry by ID
    /// - Parameter entryId: Entry identifier to delete
    /// - Returns: Result indicating success or failure
    public func execute(entryId: String) async -> Result<Void, Error> {
        do {
            // Check if entry exists first
            let entryExists = await formEntryRepository.entryExists(entryId)
            guard entryExists else {
                return .failure(DeleteFormEntryError.entryNotFound(entryId))
            }
            
            // Delete the entry
            let result = await formEntryRepository.deleteEntry(entryId)
            
            switch result {
            case .success:
                return .success(())
            case .failure(let error):
                return .failure(DeleteFormEntryError.deletionFailed(error.localizedDescription))
            }
            
        } catch {
            return .failure(DeleteFormEntryError.deletionFailed(error.localizedDescription))
        }
    }
    
    /// Delete multiple entries in batch
    /// - Parameter entryIds: Array of entry identifiers to delete
    /// - Returns: Result containing array of successfully deleted IDs or error
    public func deleteBatch(entryIds: [String]) async -> Result<[String], Error> {
        var deletedIds: [String] = []
        var errors: [String] = []
        
        for entryId in entryIds {
            let result = await execute(entryId: entryId)
            
            switch result {
            case .success:
                deletedIds.append(entryId)
            case .failure(let error):
                errors.append("Failed to delete \(entryId): \(error.localizedDescription)")
            }
        }
        
        if !errors.isEmpty {
            let combinedError = errors.joined(separator: ", ")
            return .failure(DeleteFormEntryError.batchDeletionFailed(combinedError))
        }
        
        return .success(deletedIds)
    }
    
    /// Delete draft entry for a form
    /// - Parameter formId: Form identifier
    /// - Returns: Result indicating success or failure
    public func deleteDraftEntry(formId: String) async -> Result<Void, Error> {
        let result = await formEntryRepository.deleteDraftEntry(formId)
        
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(DeleteFormEntryError.draftDeletionFailed(error.localizedDescription))
        }
    }
    
    /// Delete all edit drafts for a specific entry
    /// - Parameter entryId: Original entry identifier
    /// - Returns: Result indicating success or failure
    public func deleteEditDrafts(for entryId: String) async -> Result<Void, Error> {
        let result = await formEntryRepository.deleteEditDraftsForEntry(entryId)
        
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(DeleteFormEntryError.editDraftDeletionFailed(error.localizedDescription))
        }
    }
    
    /// Delete entry with confirmation and safety checks
    /// - Parameters:
    ///   - entryId: Entry identifier to delete
    ///   - confirmationCallback: Callback to confirm deletion
    /// - Returns: Result indicating success or failure
    public func deleteWithConfirmation(
        entryId: String,
        confirmationCallback: @escaping () async -> Bool
    ) async -> Result<Void, Error> {
        do {
            // Get entry details for confirmation
            let entryPublisher = formEntryRepository.getEntryById(entryId)
            let entry = try await entryPublisher.async()
            
            guard let entry = entry else {
                return .failure(DeleteFormEntryError.entryNotFound(entryId))
            }
            
            // Check if it's safe to delete
            let safetyResult = await checkDeletionSafety(entry: entry)
            if case .failure(let error) = safetyResult {
                return .failure(error)
            }
            
            // Ask for confirmation
            let confirmed = await confirmationCallback()
            guard confirmed else {
                return .failure(DeleteFormEntryError.deletionCancelled)
            }
            
            // Proceed with deletion
            return await execute(entryId: entryId)
            
        } catch {
            return .failure(DeleteFormEntryError.deletionFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Private Methods
    
    private func checkDeletionSafety(entry: FormEntry) async -> Result<Void, Error> {
        // Check if this is a source entry for edit drafts
        if !entry.isDraft {
            // Check if there are any edit drafts based on this entry
            let editDraftsPublisher = formEntryRepository.getEditDraftForEntry(entry.id)
            
            do {
                let editDraft = try await editDraftsPublisher.async()
                if editDraft != nil {
                    return .failure(DeleteFormEntryError.hasActiveEditDrafts(entry.id))
                }
            } catch {
                // If we can't check, proceed with caution
            }
        }
        
        return .success(())
    }
}

// MARK: - Error Types
public enum DeleteFormEntryError: Error, LocalizedError {
    case entryNotFound(String)
    case deletionFailed(String)
    case batchDeletionFailed(String)
    case draftDeletionFailed(String)
    case editDraftDeletionFailed(String)
    case deletionCancelled
    case hasActiveEditDrafts(String)
    case insufficientPermissions
    
    public var errorDescription: String? {
        switch self {
        case .entryNotFound(let id):
            return "Entry with ID '\(id)' not found"
        case .deletionFailed(let reason):
            return "Failed to delete entry: \(reason)"
        case .batchDeletionFailed(let reason):
            return "Batch deletion failed: \(reason)"
        case .draftDeletionFailed(let reason):
            return "Failed to delete draft: \(reason)"
        case .editDraftDeletionFailed(let reason):
            return "Failed to delete edit drafts: \(reason)"
        case .deletionCancelled:
            return "Deletion was cancelled by user"
        case .hasActiveEditDrafts(let id):
            return "Cannot delete entry '\(id)' because it has active edit drafts"
        case .insufficientPermissions:
            return "Insufficient permissions to delete this entry"
        }
    }
}

// MARK: - Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension DeleteFormEntryUseCase {
    
    /// Delete entry with retry logic
    /// - Parameters:
    ///   - entryId: Entry identifier to delete
    ///   - maxRetries: Maximum number of retry attempts
    /// - Returns: Result indicating success or failure
    func deleteWithRetry(entryId: String, maxRetries: Int = 3) async -> Result<Void, Error> {
        var attempt = 0
        var lastError: Error?
        
        while attempt < maxRetries {
            let result = await execute(entryId: entryId)
            
            switch result {
            case .success:
                return .success(())
            case .failure(let error):
                lastError = error
                attempt += 1
                
                // Wait before retry (exponential backoff)
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) // 2^attempt seconds
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        return .failure(lastError ?? DeleteFormEntryError.deletionFailed("Max retries exceeded"))
    }
    
    /// Delete entries older than specified date
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - olderThan: Date threshold
    /// - Returns: Result containing number of deleted entries
    func deleteOldEntries(formId: String, olderThan date: Date) async -> Result<Int, Error> {
        do {
            // Get entries older than the specified date
            let entriesPublisher = formEntryRepository.getEntriesInDateRange(
                formId: formId,
                from: Date.distantPast,
                to: date
            )
            
            let oldEntries = try await entriesPublisher.async()
            let entryIds = oldEntries.map { $0.id }
            
            guard !entryIds.isEmpty else {
                return .success(0)
            }
            
            // Delete in batch
            let batchResult = await deleteBatch(entryIds: entryIds)
            
            switch batchResult {
            case .success(let deletedIds):
                return .success(deletedIds.count)
            case .failure(let error):
                return .failure(error)
            }
            
        } catch {
            return .failure(DeleteFormEntryError.deletionFailed(error.localizedDescription))
        }
    }
}