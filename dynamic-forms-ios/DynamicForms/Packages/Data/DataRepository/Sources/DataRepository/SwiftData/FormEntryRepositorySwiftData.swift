import Foundation
import SwiftData
import Combine
import Domain
import DataLocal
import Utilities

/// SwiftData implementation of FormEntryRepository
/// Following Repository Pattern with persistent storage for form entries and drafts
@available(iOS 17.0, macOS 14.0, *)
public final class FormEntryRepositorySwiftData: FormEntryRepository {
    
    // MARK: - Dependencies
    private let swiftDataStack: SwiftDataStack
    private let logger: Logger
    
    // MARK: - Cache and Publishers
    private var cachedEntries: [FormEntry] = []
    private let entriesSubject = CurrentValueSubject<[FormEntry], Never>([])
    
    // MARK: - Initialization
    public init(
        swiftDataStack: SwiftDataStack = SwiftDataStack.shared,
        logger: Logger = ConsoleLogger()
    ) {
        self.swiftDataStack = swiftDataStack
        self.logger = logger
        
        // Load existing entries on initialization
        Task {
            await loadCachedEntries()
        }
    }
    
    // MARK: - FormEntryRepository Implementation
    
    public func getEntriesForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        self.logger.debug("Getting entries for form: \(formId)")
        
        return Future<[FormEntry], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let entries = try await self.loadEntriesFromDatabase(formId: formId)
                    self.self.logger.debug("Loaded \(entries.count) entries for form \(formId)")
                    promise(.success(entries))
                } catch {
                    self.self.logger.error("Failed to load entries for form \(formId): \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getEntryById(_ id: String) -> AnyPublisher<FormEntry?, Error> {
        self.logger.debug("Getting entry by ID: \(id)")
        
        return Future<FormEntry?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let entry = try await self.loadEntryFromDatabase(id: id)
                    self.self.logger.debug("Found entry: \(entry != nil ? "Yes" : "No")")
                    promise(.success(entry))
                } catch {
                    self.self.logger.error("Failed to load entry \(id): \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func insertEntry(_ entry: FormEntry) async -> Result<String, Error> {
        self.logger.debug("FormEntryRepositorySwiftData: Inserting entry: \(entry.id) for form: \(entry.formId)")
        
        do {
            try await swiftDataStack.performBackgroundTask { context in
                // First, find the FormEntity for this entry
                let formDescriptor = FetchDescriptor<FormEntity>(
                    predicate: #Predicate { $0.id == entry.formId }
                )
                
                let formEntities = try context.fetch(formDescriptor)
                self.logger.debug("FormEntryRepositorySwiftData: Found \(formEntities.count) form entities for formId: \(entry.formId)")
                
                guard let formEntity = formEntities.first else {
                    self.logger.error("FormEntryRepositorySwiftData: Form with id \(entry.formId) not found in database")
                    throw FormEntryRepositoryError.persistenceError("Form with id \(entry.formId) not found")
                }
                
                self.logger.debug("FormEntryRepositorySwiftData: Found form entity: \(formEntity.title)")
                
                // Create the entry entity and link it to the form
                let entryEntity = FormEntryEntity.fromDomain(entry)
                entryEntity.form = formEntity
                context.insert(entryEntity)
                
                self.logger.debug("FormEntryRepositorySwiftData: Created and inserted FormEntryEntity")
                
                if context.hasChanges {
                    try context.save()
                    self.logger.debug("FormEntryRepositorySwiftData: Successfully saved context changes")
                } else {
                    self.logger.warning("FormEntryRepositorySwiftData: No changes to save")
                }
            }
            
            // Update cache
            if !cachedEntries.contains(where: { $0.id == entry.id }) {
                cachedEntries.append(entry)
                entriesSubject.send(cachedEntries)
                self.logger.debug("FormEntryRepositorySwiftData: Added entry to cache. Cache now has \(cachedEntries.count) entries")
            } else {
                self.logger.debug("FormEntryRepositorySwiftData: Entry already exists in cache")
            }
            
            self.logger.debug("FormEntryRepositorySwiftData: Entry \(entry.id) inserted successfully")
            return .success(entry.id)
            
        } catch {
            self.logger.error("FormEntryRepositorySwiftData: Failed to insert entry \(entry.id): \(error.localizedDescription)")
            return .failure(FormEntryRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func updateEntry(_ entry: FormEntry) async -> Result<Void, Error> {
        self.logger.debug("Updating entry: \(entry.id)")
        
        do {
            try await swiftDataStack.performBackgroundTask { context in
                let descriptor = FetchDescriptor<FormEntryEntity>(
                    predicate: #Predicate { $0.id == entry.id }
                )
                
                let existingEntities = try context.fetch(descriptor)
                guard let existingEntity = existingEntities.first else {
                    throw FormEntryRepositoryError.entryNotFound(entry.id)
                }
                
                // Update entity fields
                existingEntity.sourceEntryId = entry.sourceEntryId
                existingEntity.fieldValues = entry.fieldValues
                existingEntity.updatedAt = entry.updatedAt
                existingEntity.isComplete = entry.isComplete
                existingEntity.isDraft = entry.isDraft
                
                if context.hasChanges {
                    try context.save()
                }
            }
            
            // Update cache
            if let index = cachedEntries.firstIndex(where: { $0.id == entry.id }) {
                cachedEntries[index] = entry
                entriesSubject.send(cachedEntries)
            }
            
            self.logger.debug("Entry \(entry.id) updated successfully")
            return .success(())
            
        } catch {
            self.logger.error("Failed to update entry \(entry.id): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func deleteEntry(_ id: String) async -> Result<Void, Error> {
        self.logger.debug("Deleting entry: \(id)")
        
        do {
            try await swiftDataStack.performBackgroundTask { context in
                let descriptor = FetchDescriptor<FormEntryEntity>(
                    predicate: #Predicate { $0.id == id }
                )
                
                let entities = try context.fetch(descriptor)
                guard let entity = entities.first else {
                    throw FormEntryRepositoryError.entryNotFound(id)
                }
                
                context.delete(entity)
                if context.hasChanges {
                    try context.save()
                }
            }
            
            // Update cache
            cachedEntries.removeAll { $0.id == id }
            entriesSubject.send(cachedEntries)
            
            self.logger.debug("Entry \(id) deleted successfully")
            return .success(())
            
        } catch {
            self.logger.error("Failed to delete entry \(id): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // MARK: - Draft Operations
    
    public func saveEntryDraft(_ entry: FormEntry) async -> Result<Void, Error> {
        self.logger.debug("Saving draft entry: \(entry.id)")
        
        let draftEntry = entry.markAsDraft()
        
        do {
            // Check if entry already exists
            let existingEntry = try await loadEntryFromDatabase(id: draftEntry.id)
            
            if existingEntry != nil {
                // Update existing entry
                return await updateEntry(draftEntry)
            } else {
                // Insert new entry
                let insertResult = await insertEntry(draftEntry)
                return insertResult.map { _ in () }
            }
            
        } catch {
            self.logger.error("Failed to save draft entry \(entry.id): \(error.localizedDescription)")
            return .failure(FormEntryRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func getDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        self.logger.debug("Getting draft entry for form: \(formId)")
        
        return Future<FormEntry?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let draft = try await self.loadDraftFromDatabase(formId: formId)
                    self.self.logger.debug("Found draft for form \(formId): \(draft != nil ? "Yes" : "No")")
                    promise(.success(draft))
                } catch {
                    self.self.logger.error("Failed to load draft for form \(formId): \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func deleteDraftEntry(_ formId: String) async -> Result<Void, Error> {
        self.logger.debug("Deleting draft entry for form: \(formId)")
        
        do {
            let draftId = try await findDraftIdForForm(formId)
            guard let draftId = draftId else {
                self.logger.warning("No draft found for form \(formId)")
                return .failure(FormEntryRepositoryError.draftNotFound(formId))
            }
            
            return await deleteEntry(draftId)
            
        } catch {
            self.logger.error("Failed to delete draft for form \(formId): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func getNewDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        // For new drafts, we look for drafts with no sourceEntryId
        return Future<FormEntry?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let newDraft = try await self.loadNewDraftFromDatabase(formId: formId)
                    promise(.success(newDraft))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getEditDraftForEntry(_ entryId: String) -> AnyPublisher<FormEntry?, Error> {
        // For edit drafts, we look for drafts with the given sourceEntryId
        return Future<FormEntry?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let editDraft = try await self.loadEditDraftFromDatabase(entryId: entryId)
                    promise(.success(editDraft))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func entryExists(_ id: String) async -> Bool {
        do {
            let entry = try await loadEntryFromDatabase(id: id)
            return entry != nil
        } catch {
            self.logger.error("Failed to check if entry exists \(id): \(error.localizedDescription)")
            return false
        }
    }
    
    public func getEntriesByStatus(formId: String, isDraft: Bool?, isComplete: Bool?) -> AnyPublisher<[FormEntry], Error> {
        return Future<[FormEntry], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let entries = try await self.loadEntriesByStatus(formId: formId, isDraft: isDraft, isComplete: isComplete)
                    promise(.success(entries))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getAllDraftsForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        return getEntriesByStatus(formId: formId, isDraft: true, isComplete: nil)
    }
    
    public func deleteEditDraftsForEntry(_ entryId: String) async -> Result<Void, Error> {
        self.logger.debug("Deleting edit drafts for entry: \(entryId)")
        
        do {
            try await swiftDataStack.performBackgroundTask { context in
                let descriptor = FetchDescriptor<FormEntryEntity>(
                    predicate: #Predicate { entity in
                        entity.sourceEntryId == entryId && entity.isDraft == true
                    }
                )
                
                let entities = try context.fetch(descriptor)
                for entity in entities {
                    context.delete(entity)
                }
                if context.hasChanges {
                    try context.save()
                }
            }
            
            // Update cache
            cachedEntries.removeAll { $0.sourceEntryId == entryId && $0.isDraft }
            entriesSubject.send(cachedEntries)
            
            self.logger.debug("Edit drafts for entry \(entryId) deleted successfully")
            return .success(())
            
        } catch {
            self.logger.error("Failed to delete edit drafts for entry \(entryId): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func getEntriesInDateRange(formId: String, from startDate: Date, to endDate: Date) -> AnyPublisher<[FormEntry], Error> {
        return Future<[FormEntry], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let entries = try await self.loadEntriesInDateRange(formId: formId, from: startDate, to: endDate)
                    promise(.success(entries))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Database Operations
    
    private func loadCachedEntries() async {
        do {
            let entries = try await loadAllEntriesFromDatabase()
            cachedEntries = entries
            entriesSubject.send(cachedEntries)
            self.logger.debug("FormEntryRepositorySwiftData: Loaded \(entries.count) entries into cache on initialization")
            
            // Log detailed information for debugging
            for entry in entries {
                self.logger.debug("  - Entry \(entry.id) for form \(entry.formId), isDraft: \(entry.isDraft), isComplete: \(entry.isComplete)")
            }
        } catch {
            self.logger.error("FormEntryRepositorySwiftData: Failed to load cached entries: \(error.localizedDescription)")
        }
    }
    
    private func loadAllEntriesFromDatabase() async throws -> [FormEntry] {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }
    
    private func loadEntriesFromDatabase(formId: String) async throws -> [FormEntry] {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { entity in
                    entity.form?.id == formId
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }
    
    private func loadEntryFromDatabase(id: String) async throws -> FormEntry? {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { $0.id == id }
            )
            
            let entities = try context.fetch(descriptor)
            return entities.first?.toDomain()
        }
    }
    
    private func loadDraftFromDatabase(formId: String) async throws -> FormEntry? {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { entity in
                    entity.form?.id == formId && entity.isDraft == true
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.first?.toDomain()
        }
    }
    
    private func loadNewDraftFromDatabase(formId: String) async throws -> FormEntry? {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { entity in
                    entity.form?.id == formId && entity.isDraft == true && entity.sourceEntryId == nil
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.first?.toDomain()
        }
    }
    
    private func loadEditDraftFromDatabase(entryId: String) async throws -> FormEntry? {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { entity in
                    entity.sourceEntryId == entryId && entity.isDraft == true
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.first?.toDomain()
        }
    }
    
    private func loadEntriesByStatus(formId: String, isDraft: Bool?, isComplete: Bool?) async throws -> [FormEntry] {
        return try await swiftDataStack.performBackgroundTask { context in
            var predicate: Predicate<FormEntryEntity>
            
            if let isDraft = isDraft, let isComplete = isComplete {
                predicate = #Predicate { entity in
                    entity.form?.id == formId && entity.isDraft == isDraft && entity.isComplete == isComplete
                }
            } else if let isDraft = isDraft {
                predicate = #Predicate { entity in
                    entity.form?.id == formId && entity.isDraft == isDraft
                }
            } else if let isComplete = isComplete {
                predicate = #Predicate { entity in
                    entity.form?.id == formId && entity.isComplete == isComplete
                }
            } else {
                predicate = #Predicate { entity in
                    entity.form?.id == formId
                }
            }
            
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }
    
    private func findDraftIdForForm(_ formId: String) async throws -> String? {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { entity in
                    entity.form?.id == formId && entity.isDraft == true
                }
            )
            
            let entities = try context.fetch(descriptor)
            return entities.first?.id
        }
    }
    
    private func loadEntriesInDateRange(formId: String, from startDate: Date, to endDate: Date) async throws -> [FormEntry] {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntryEntity>(
                predicate: #Predicate { entity in
                    entity.form?.id == formId && entity.createdAt >= startDate && entity.createdAt <= endDate
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }
}

// MARK: - Extensions for SwiftDataStack Support

@available(iOS 17.0, macOS 14.0, *)
private extension SwiftDataStack {
    
    func performBackgroundTask<T>(_ block: @escaping (ModelContext) throws -> T) async throws -> T {
        let container = try modelContainer
        let context = ModelContext(container)
        
        return try block(context)
    }
}

// MARK: - FormEntryEntity Domain Conversion Extensions

@available(iOS 17.0, macOS 14.0, *)
private extension FormEntryEntity {
    
    static func fromDomain(_ entry: FormEntry) -> FormEntryEntity {
        let entity = FormEntryEntity(
            id: entry.id,
            sourceEntryId: entry.sourceEntryId,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            isComplete: entry.isComplete,
            isDraft: entry.isDraft
        )
        
        entity.fieldValues = entry.fieldValues
        return entity
    }
}
