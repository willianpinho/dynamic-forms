import Foundation
import Combine

/// Use case for saving form entries (both drafts and completed entries)
/// Following Single Responsibility Principle and Clean Architecture
@available(iOS 13.0, macOS 10.15, *)
public final class SaveFormEntryUseCase {
    
    // MARK: - Dependencies
    private let formEntryRepository: FormEntryRepository
    
    // MARK: - Initialization
    public init(formEntryRepository: FormEntryRepository) {
        self.formEntryRepository = formEntryRepository
    }
    
    // MARK: - Execution
    
    /// Save form entry
    /// - Parameters:
    ///   - entry: FormEntry to save
    ///   - isComplete: Whether to mark entry as complete/submitted
    /// - Returns: Result containing entry ID or error
    public func execute(entry: FormEntry, isComplete: Bool = false) async -> Result<String, Error> {
        let finalEntry = isComplete ? entry.markAsComplete() : entry
        
        // Check if this is a new entry or an update
        if await formEntryRepository.entryExists(entry.id) {
            let updateResult = await formEntryRepository.updateEntry(finalEntry)
            return updateResult.mapError { error in
                SaveFormEntryError.saveFailed(error.localizedDescription)
            }.map { entry.id }
        } else {
            let insertResult = await formEntryRepository.insertEntry(finalEntry)
            return insertResult.mapError { error in
                SaveFormEntryError.saveFailed(error.localizedDescription)
            }
        }
    }
    
    /// Save entry as draft
    /// - Parameter entry: FormEntry to save as draft
    /// - Returns: Result containing entry ID or error
    public func saveDraft(_ entry: FormEntry) async -> Result<String, Error> {
        return await execute(entry: entry, isComplete: false)
    }
    
    /// Submit entry (mark as complete)
    /// - Parameter entry: FormEntry to submit
    /// - Returns: Result containing entry ID or error
    public func submit(_ entry: FormEntry) async -> Result<String, Error> {
        return await execute(entry: entry, isComplete: true)
    }
    
    /// Save multiple entries in batch
    /// - Parameter entries: Array of FormEntry objects to save
    /// - Returns: Result containing array of entry IDs or error
    public func saveBatch(_ entries: [FormEntry]) async -> Result<[String], Error> {
        var savedIds: [String] = []
        
        for entry in entries {
            let result = await execute(entry: entry)
            switch result {
            case .success(let id):
                savedIds.append(id)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(savedIds)
    }
    
    /// Save entry with validation
    /// - Parameters:
    ///   - entry: FormEntry to save
    ///   - form: DynamicForm for validation
    ///   - isComplete: Whether to mark entry as complete
    /// - Returns: Result containing entry ID or validation errors
    public func saveWithValidation(
        entry: FormEntry,
        form: DynamicForm,
        isComplete: Bool = false
    ) async -> Result<String, Error> {
        // Validate entry against form
        let validationErrors = entry.validateAgainstForm(form)
        
        // If trying to submit and there are validation errors, fail
        if isComplete && !validationErrors.isEmpty {
            let errorMessages = validationErrors.values.joined(separator: ", ")
            return .failure(SaveFormEntryError.validationFailed(errorMessages))
        }
        
        // Save the entry
        return await execute(entry: entry, isComplete: isComplete)
    }
    
    /// Auto-save entry (save as draft without validation)
    /// - Parameter entry: FormEntry to auto-save
    /// - Returns: Result containing entry ID or error
    public func autoSave(_ entry: FormEntry) async -> Result<String, Error> {
        // Auto-save should always be a draft and shouldn't fail on validation
        let draftEntry = entry.markAsDraft()
        return await formEntryRepository.saveEntryDraft(draftEntry)
            .map { draftEntry.id }
    }
    
    /// Update existing entry
    /// - Parameter entry: FormEntry to update
    /// - Returns: Result indicating success or failure
    public func update(_ entry: FormEntry) async -> Result<Void, Error> {
        return await formEntryRepository.updateEntry(entry)
    }
    
    /// Create and save edit draft from existing entry
    /// - Parameters:
    ///   - sourceEntry: Original entry to create edit draft from
    ///   - draftId: Optional custom draft ID
    /// - Returns: Result containing edit draft entry or error
    public func createEditDraft(
        from sourceEntry: FormEntry,
        draftId: String? = nil
    ) async -> Result<FormEntry, Error> {
        let editDraft = sourceEntry.createEditDraft(draftId: draftId)
        
        let saveResult = await formEntryRepository.insertEntry(editDraft)
        return saveResult.map { _ in editDraft }
    }
}

// MARK: - Error Types
public enum SaveFormEntryError: Error, LocalizedError {
    case saveFailed(String)
    case validationFailed(String)
    case entryNotFound(String)
    case conflictError(String)
    case insufficientData(String)
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return "Failed to save entry: \(reason)"
        case .validationFailed(let errors):
            return "Validation failed: \(errors)"
        case .entryNotFound(let id):
            return "Entry with ID '\(id)' not found"
        case .conflictError(let reason):
            return "Conflict error: \(reason)"
        case .insufficientData(let reason):
            return "Insufficient data: \(reason)"
        }
    }
}

// MARK: - Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension SaveFormEntryUseCase {
    
    /// Save entry with optimistic updates
    /// - Parameters:
    ///   - entry: FormEntry to save
    ///   - isComplete: Whether to mark entry as complete
    ///   - onOptimisticUpdate: Closure called immediately for optimistic UI updates
    /// - Returns: Result containing entry ID or error
    func saveWithOptimisticUpdate(
        entry: FormEntry,
        isComplete: Bool = false,
        onOptimisticUpdate: @escaping (FormEntry) -> Void
    ) async -> Result<String, Error> {
        // Perform optimistic update immediately
        let optimisticEntry = isComplete ? entry.markAsComplete() : entry
        onOptimisticUpdate(optimisticEntry)
        
        // Perform actual save
        return await execute(entry: entry, isComplete: isComplete)
    }
    
    /// Save entry with retry logic
    /// - Parameters:
    ///   - entry: FormEntry to save
    ///   - isComplete: Whether to mark entry as complete
    ///   - maxRetries: Maximum number of retry attempts
    /// - Returns: Result containing entry ID or error
    func saveWithRetry(
        entry: FormEntry,
        isComplete: Bool = false,
        maxRetries: Int = 3
    ) async -> Result<String, Error> {
        var attempt = 0
        var lastError: Error?
        
        while attempt < maxRetries {
            let result = await execute(entry: entry, isComplete: isComplete)
            
            switch result {
            case .success(let id):
                return .success(id)
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
        
        if let lastError = lastError {
            return .failure(SaveFormEntryError.saveFailed(lastError.localizedDescription))
        } else {
            return .failure(SaveFormEntryError.saveFailed("Max retries exceeded"))
        }
    }
    
    /// Save entry with conflict resolution
    /// - Parameters:
    ///   - entry: FormEntry to save
    ///   - conflictResolution: Strategy for resolving conflicts
    /// - Returns: Result containing entry ID or error
    func saveWithConflictResolution(
        entry: FormEntry,
        conflictResolution: ConflictResolutionStrategy = .defaultSave
    ) async -> Result<String, Error> {
        // Check if entry exists and has been modified
        if let existingEntry = try? await formEntryRepository.getEntry(by: entry.id),
           existingEntry.updatedAt > entry.updatedAt {
            
            switch conflictResolution {
            case .overwrite:
                // Proceed with save, overwriting existing entry
                return await execute(entry: entry)
                
            case .merge:
                // Merge changes (simple strategy: keep non-empty values from both)
                let mergedEntry = mergeEntries(local: entry, remote: existingEntry)
                return await execute(entry: mergedEntry)
                
            case .fail:
                // Fail with conflict error
                return .failure(SaveFormEntryError.conflictError("Entry has been modified by another source"))
                
            case .createNew:
                // Create a new entry with a different ID
                let newEntry = entry.duplicate()
                return await formEntryRepository.insertEntry(newEntry)
                
            case .skip:
                // Skip the save operation
                return .success(entry.id)
            }
        } else {
            // No conflict, proceed with normal save
            return await execute(entry: entry)
        }
    }
    
    // MARK: - Private Helpers
    
    private func mergeEntries(local: FormEntry, remote: FormEntry) -> FormEntry {
        var mergedValues = remote.fieldValues
        
        // Override with local values that are not empty
        for (key, value) in local.fieldValues {
            if !value.isBlank {
                mergedValues[key] = value
            }
        }
        
        return FormEntry(
            id: local.id,
            formId: local.formId,
            sourceEntryId: local.sourceEntryId,
            fieldValues: mergedValues,
            createdAt: remote.createdAt, // Keep original creation date
            updatedAt: Date(), // Update to current time
            isComplete: local.isComplete,
            isDraft: local.isDraft
        )
    }
}