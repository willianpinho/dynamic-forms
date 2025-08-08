import Foundation
import Utilities

/// Use case for auto-saving form entries in the background
/// Following Single Responsibility Principle and Clean Architecture
@available(iOS 13.0, macOS 10.15, *)
public final class AutoSaveFormEntryUseCase: AutoSaveFormEntryUseCaseProtocol {
    
    // MARK: - Dependencies
    private let formEntryRepository: FormEntryRepository
    private let logger: Logger
    
    // MARK: - Configuration
    private let autoSaveInterval: TimeInterval
    private let maxRetryAttempts: Int
    private let conflictResolutionStrategy: ConflictResolutionStrategy
    
    // MARK: - State
    private var pendingAutoSaves: [String: FormEntry] = [:]
    private var autoSaveTimers: [String: Timer] = [:]
    
    // MARK: - Initialization
    public init(
        formEntryRepository: FormEntryRepository,
        logger: Logger = ConsoleLogger(),
        autoSaveInterval: TimeInterval = 5.0,
        maxRetryAttempts: Int = 3,
        conflictResolutionStrategy: ConflictResolutionStrategy = .defaultAutoSave
    ) {
        self.formEntryRepository = formEntryRepository
        self.logger = logger
        self.autoSaveInterval = autoSaveInterval
        self.maxRetryAttempts = maxRetryAttempts
        self.conflictResolutionStrategy = conflictResolutionStrategy
    }
    
    // MARK: - Execution
    
    /// Auto-save form entry immediately
    /// - Parameter entry: FormEntry to auto-save
    /// - Returns: Result indicating success or failure
    public func execute(entry: FormEntry) async -> Result<Void, Error> {
        logger.debug("Auto-saving entry: \(entry.id)")
        
        do {
            // Mark as draft for auto-save
            let draftEntry = entry.markAsDraft()
            
            // Check for conflicts
            let conflictResult = await checkForConflicts(entry: draftEntry)
            let finalEntry: FormEntry
            
            switch conflictResult {
            case .success(let resolvedEntry):
                finalEntry = resolvedEntry
            case .failure(let error):
                logger.warning("Conflict resolution failed: \(error.localizedDescription)")
                finalEntry = draftEntry // Proceed with original entry
            }
            
            // Perform the auto-save
            let saveResult = await formEntryRepository.saveEntryDraft(finalEntry)
            
            switch saveResult {
            case .success:
                logger.debug("Auto-save completed successfully for entry: \(entry.id)")
                return .success(())
                
            case .failure(let error):
                logger.error("Auto-save failed for entry \(entry.id): \(error.localizedDescription)")
                return .failure(AutoSaveError.saveFailed(error.localizedDescription))
            }
            
        } catch {
            logger.error("Auto-save error for entry \(entry.id): \(error.localizedDescription)")
            return .failure(AutoSaveError.saveFailed(error.localizedDescription))
        }
    }
    
    /// Schedule auto-save for an entry
    /// - Parameter entry: FormEntry to schedule for auto-save
    public func scheduleAutoSave(for entry: FormEntry) {
        logger.debug("Scheduling auto-save for entry: \(entry.id)")
        
        // Cancel existing timer for this entry
        cancelScheduledAutoSave(for: entry.id)
        
        // Store pending entry
        pendingAutoSaves[entry.id] = entry
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: false) { [weak self] _ in
            Task {
                await self?.performScheduledAutoSave(entryId: entry.id)
            }
        }
        
        autoSaveTimers[entry.id] = timer
    }
    
    /// Cancel scheduled auto-save for an entry
    /// - Parameter entryId: Entry identifier
    public func cancelScheduledAutoSave(for entryId: String) {
        autoSaveTimers[entryId]?.invalidate()
        autoSaveTimers.removeValue(forKey: entryId)
        pendingAutoSaves.removeValue(forKey: entryId)
        
        logger.debug("Cancelled scheduled auto-save for entry: \(entryId)")
    }
    
    /// Auto-save with retry logic
    /// - Parameter entry: FormEntry to auto-save
    /// - Returns: Result indicating success or failure
    public func executeWithRetry(entry: FormEntry) async -> Result<Void, Error> {
        var attempt = 0
        var lastError: Error?
        
        while attempt < maxRetryAttempts {
            let result = await execute(entry: entry)
            
            switch result {
            case .success:
                logger.debug("Auto-save succeeded on attempt \(attempt + 1)")
                return .success(())
                
            case .failure(let error):
                lastError = error
                attempt += 1
                
                logger.warning("Auto-save attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Wait before retry (exponential backoff)
                if attempt < maxRetryAttempts {
                    let delay = min(pow(2.0, Double(attempt)), 30.0) // Max 30 seconds
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        logger.error("Auto-save failed after \(maxRetryAttempts) attempts")
        return .failure(lastError ?? AutoSaveError.maxRetriesExceeded)
    }
    
    /// Batch auto-save multiple entries
    /// - Parameter entries: Array of FormEntry objects to auto-save
    /// - Returns: Result containing array of successfully saved entry IDs
    public func batchAutoSave(entries: [FormEntry]) async -> Result<[String], Error> {
        var savedIds: [String] = []
        var errors: [String] = []
        
        for entry in entries {
            let result = await execute(entry: entry)
            
            switch result {
            case .success:
                savedIds.append(entry.id)
            case .failure(let error):
                errors.append("Entry \(entry.id): \(error.localizedDescription)")
            }
        }
        
        if !errors.isEmpty {
            let combinedError = errors.joined(separator: ", ")
            logger.error("Batch auto-save partial failure: \(combinedError)")
            return .failure(AutoSaveError.batchSaveFailed(combinedError))
        }
        
        logger.info("Batch auto-save completed for \(savedIds.count) entries")
        return .success(savedIds)
    }
    
    // MARK: - Private Methods
    
    private func performScheduledAutoSave(entryId: String) async {
        guard let entry = pendingAutoSaves[entryId] else {
            logger.warning("No pending auto-save found for entry: \(entryId)")
            return
        }
        
        let result = await executeWithRetry(entry: entry)
        
        switch result {
        case .success:
            logger.info("Scheduled auto-save completed for entry: \(entryId)")
        case .failure(let error):
            logger.error("Scheduled auto-save failed for entry \(entryId): \(error.localizedDescription)")
        }
        
        // Clean up
        pendingAutoSaves.removeValue(forKey: entryId)
        autoSaveTimers.removeValue(forKey: entryId)
    }
    
    private func checkForConflicts(entry: FormEntry) async -> Result<FormEntry, Error> {
        do {
            // Check if entry exists and has been modified
            let existingEntryPublisher = formEntryRepository.getEntryById(entry.id)
            let existingEntry = try await existingEntryPublisher.async()
            
            guard let existing = existingEntry else {
                // No existing entry, no conflict
                return .success(entry)
            }
            
            // Check if existing entry is newer
            if existing.updatedAt > entry.updatedAt {
                logger.warning("Conflict detected for entry \(entry.id)")
                
                switch conflictResolutionStrategy {
                case .overwrite:
                    logger.debug("Conflict resolution: overwrite")
                    return .success(entry)
                    
                case .merge:
                    logger.debug("Conflict resolution: merge")
                    let mergedEntry = mergeEntries(local: entry, remote: existing)
                    return .success(mergedEntry)
                    
                case .fail:
                    logger.debug("Conflict resolution: fail")
                    return .failure(AutoSaveError.conflictDetected(entry.id))
                    
                case .skip:
                    logger.debug("Conflict resolution: skip")
                    return .failure(AutoSaveError.saveSkipped(entry.id))
                    
                case .createNew:
                    logger.debug("Conflict resolution: create new")
                    let newEntry = entry.duplicate()
                    return .success(newEntry)
                }
            }
            
            // No conflict detected
            return .success(entry)
            
        } catch {
            logger.error("Error checking conflicts: \(error.localizedDescription)")
            return .success(entry) // Proceed with original entry
        }
    }
    
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
            isDraft: true // Always mark merged entries as drafts
        )
    }
}

// MARK: - Error Types
public enum AutoSaveError: Error, LocalizedError {
    case saveFailed(String)
    case conflictDetected(String)
    case saveSkipped(String)
    case maxRetriesExceeded
    case batchSaveFailed(String)
    case invalidEntry(String)
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return "Auto-save failed: \(reason)"
        case .conflictDetected(let entryId):
            return "Conflict detected for entry \(entryId)"
        case .saveSkipped(let entryId):
            return "Auto-save skipped for entry \(entryId) due to conflict"
        case .maxRetriesExceeded:
            return "Auto-save failed: maximum retry attempts exceeded"
        case .batchSaveFailed(let reason):
            return "Batch auto-save failed: \(reason)"
        case .invalidEntry(let reason):
            return "Invalid entry for auto-save: \(reason)"
        }
    }
}

// MARK: - Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension AutoSaveFormEntryUseCase {
    
    /// Get auto-save statistics
    /// - Returns: AutoSaveStatistics with current state information
    func getStatistics() -> AutoSaveStatistics {
        return AutoSaveStatistics(
            pendingAutoSaves: pendingAutoSaves.count,
            activeTimers: autoSaveTimers.count,
            autoSaveInterval: autoSaveInterval,
            maxRetryAttempts: maxRetryAttempts
        )
    }
    
    /// Cancel all pending auto-saves
    func cancelAllPendingAutoSaves() {
        for (entryId, _) in autoSaveTimers {
            cancelScheduledAutoSave(for: entryId)
        }
        
        logger.info("Cancelled all pending auto-saves")
    }
}

public struct AutoSaveStatistics {
    public let pendingAutoSaves: Int
    public let activeTimers: Int
    public let autoSaveInterval: TimeInterval
    public let maxRetryAttempts: Int
    
    public init(
        pendingAutoSaves: Int,
        activeTimers: Int,
        autoSaveInterval: TimeInterval,
        maxRetryAttempts: Int
    ) {
        self.pendingAutoSaves = pendingAutoSaves
        self.activeTimers = activeTimers
        self.autoSaveInterval = autoSaveInterval
        self.maxRetryAttempts = maxRetryAttempts
    }
}
