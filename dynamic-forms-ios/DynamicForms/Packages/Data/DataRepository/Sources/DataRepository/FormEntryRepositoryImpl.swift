import Foundation
import CoreData
import Combine
import Domain
import DataLocal
import Utilities

/// CoreData implementation of FormEntryRepository
/// Following Repository Pattern with persistent storage for form entries and drafts
@available(iOS 13.0, macOS 10.15, *)
public final class FormEntryRepositoryImpl: FormEntryRepository {
    
    // MARK: - Dependencies
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    
    // MARK: - Cache and Publishers
    private var cachedEntries: [FormEntry] = []
    private let entriesSubject = CurrentValueSubject<[FormEntry], Never>([])
    
    // MARK: - Initialization
    public init(
        coreDataStack: CoreDataStack = CoreDataStack.shared,
        logger: Logger = ConsoleLogger()
    ) {
        self.coreDataStack = coreDataStack
        self.logger = logger
        
        // Load existing entries on initialization
        Task {
            await loadCachedEntries()
        }
    }
    
    // MARK: - FormEntryRepository Implementation
    
    public func getEntriesForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        logger.debug("Getting entries for form: \(formId)")
        
        return Future<[FormEntry], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let entries = try await self.loadEntriesFromDatabase(formId: formId)
                    self.logger.debug("Loaded \(entries.count) entries for form \(formId)")
                    promise(.success(entries))
                } catch {
                    self.logger.error("Failed to load entries for form \(formId): \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getEntryById(_ id: String) -> AnyPublisher<FormEntry?, Error> {
        logger.debug("Getting entry by ID: \(id)")
        
        return Future<FormEntry?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let entry = try await self.loadEntryFromDatabase(id: id)
                    self.logger.debug("Found entry: \(entry != nil ? "Yes" : "No")")
                    promise(.success(entry))
                } catch {
                    self.logger.error("Failed to load entry \(id): \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func insertEntry(_ entry: FormEntry) async -> Result<String, Error> {
        logger.debug("Inserting entry: \(entry.id)")
        
        do {
            try await coreDataStack.performBackgroundTask { context in
                // Note: For this demo, we'll store entry data as JSON in a simple entity
                // In a real app, you'd create proper CoreData entities
                let entryEntity = NSEntityDescription.entity(forEntityName: "FormEntryEntity", in: context)!
                let managedObject = NSManagedObject(entity: entryEntity, insertInto: context)
                
                managedObject.setValue(entry.id, forKey: "id")
                managedObject.setValue(entry.formId, forKey: "formId")
                managedObject.setValue(entry.sourceEntryId, forKey: "sourceEntryId")
                managedObject.setValue(entry.createdAt, forKey: "createdAt")
                managedObject.setValue(entry.updatedAt, forKey: "updatedAt")
                managedObject.setValue(entry.isComplete, forKey: "isComplete")
                managedObject.setValue(entry.isDraft, forKey: "isDraft")
                
                // Serialize fieldValues as JSON Data
                let fieldValuesData = try JSONEncoder().encode(entry.fieldValues)
                managedObject.setValue(fieldValuesData, forKey: "fieldValuesData")
                
                try context.save()
            }
            
            // Update cache
            if !cachedEntries.contains(where: { $0.id == entry.id }) {
                cachedEntries.append(entry)
                entriesSubject.send(cachedEntries)
            }
            
            logger.debug("Entry \(entry.id) inserted successfully")
            return .success(entry.id)
            
        } catch {
            logger.error("Failed to insert entry \(entry.id): \(error.localizedDescription)")
            return .failure(FormEntryRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func updateEntry(_ entry: FormEntry) async -> Result<Void, Error> {
        logger.debug("Updating entry: \(entry.id)")
        
        do {
            try await coreDataStack.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
                fetchRequest.predicate = NSPredicate(format: "id == %@", entry.id)
                
                let results = try context.fetch(fetchRequest)
                guard let existingObject = results.first else {
                    throw FormEntryRepositoryError.entryNotFound(entry.id)
                }
                
                // Update fields
                existingObject.setValue(entry.sourceEntryId, forKey: "sourceEntryId")
                existingObject.setValue(entry.updatedAt, forKey: "updatedAt")
                existingObject.setValue(entry.isComplete, forKey: "isComplete")
                existingObject.setValue(entry.isDraft, forKey: "isDraft")
                
                // Update serialized fieldValues
                let fieldValuesData = try JSONEncoder().encode(entry.fieldValues)
                existingObject.setValue(fieldValuesData, forKey: "fieldValuesData")
                
                try context.save()
            }
            
            // Update cache
            if let index = cachedEntries.firstIndex(where: { $0.id == entry.id }) {
                cachedEntries[index] = entry
                entriesSubject.send(cachedEntries)
            }
            
            logger.debug("Entry \(entry.id) updated successfully")
            return .success(())
            
        } catch {
            logger.error("Failed to update entry \(entry.id): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func deleteEntry(_ id: String) async -> Result<Void, Error> {
        logger.debug("Deleting entry: \(id)")
        
        do {
            try await coreDataStack.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
                fetchRequest.predicate = NSPredicate(format: "id == %@", id)
                
                let results = try context.fetch(fetchRequest)
                guard let objectToDelete = results.first else {
                    throw FormEntryRepositoryError.entryNotFound(id)
                }
                
                context.delete(objectToDelete)
                try context.save()
            }
            
            // Update cache
            cachedEntries.removeAll { $0.id == id }
            entriesSubject.send(cachedEntries)
            
            logger.debug("Entry \(id) deleted successfully")
            return .success(())
            
        } catch {
            logger.error("Failed to delete entry \(id): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // MARK: - Draft Operations
    
    public func saveEntryDraft(_ entry: FormEntry) async -> Result<Void, Error> {
        logger.debug("Saving draft entry: \(entry.id)")
        
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
            logger.error("Failed to save draft entry \(entry.id): \(error.localizedDescription)")
            return .failure(FormEntryRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func getDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        logger.debug("Getting draft entry for form: \(formId)")
        
        return Future<FormEntry?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FormEntryRepositoryError.persistenceError("Repository deallocated")))
                return
            }
            
            Task {
                do {
                    let draft = try await self.loadDraftFromDatabase(formId: formId)
                    self.logger.debug("Found draft for form \(formId): \(draft != nil ? "Yes" : "No")")
                    promise(.success(draft))
                } catch {
                    self.logger.error("Failed to load draft for form \(formId): \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func deleteDraftEntry(_ formId: String) async -> Result<Void, Error> {
        logger.debug("Deleting draft entry for form: \(formId)")
        
        do {
            let draftId = try await findDraftIdForForm(formId)
            guard let draftId = draftId else {
                logger.warning("No draft found for form \(formId)")
                return .failure(FormEntryRepositoryError.draftNotFound(formId))
            }
            
            return await deleteEntry(draftId)
            
        } catch {
            logger.error("Failed to delete draft for form \(formId): \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func getNewDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
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
            logger.error("Failed to check if entry exists \(id): \(error.localizedDescription)")
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
        logger.debug("Deleting edit drafts for entry: \(entryId)")
        
        do {
            try await coreDataStack.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
                fetchRequest.predicate = NSPredicate(format: "sourceEntryId == %@ AND isDraft == TRUE", entryId)
                
                let results = try context.fetch(fetchRequest)
                for object in results {
                    context.delete(object)
                }
                try context.save()
            }
            
            // Update cache
            cachedEntries.removeAll { $0.sourceEntryId == entryId && $0.isDraft }
            entriesSubject.send(cachedEntries)
            
            logger.debug("Edit drafts for entry \(entryId) deleted successfully")
            return .success(())
            
        } catch {
            logger.error("Failed to delete edit drafts for entry \(entryId): \(error.localizedDescription)")
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
            logger.debug("Loaded \(entries.count) entries into cache")
        } catch {
            logger.error("Failed to load cached entries: \(error.localizedDescription)")
        }
    }
    
    private func loadAllEntriesFromDatabase() async throws -> [FormEntry] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            return try results.compactMap { try self.managedObjectToFormEntry($0) }
        }
    }
    
    private func loadEntriesFromDatabase(formId: String) async throws -> [FormEntry] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "formId == %@", formId)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            return try results.compactMap { try self.managedObjectToFormEntry($0) }
        }
    }
    
    private func loadEntryFromDatabase(id: String) async throws -> FormEntry? {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let results = try context.fetch(fetchRequest)
            guard let managedObject = results.first else { return nil }
            
            return try self.managedObjectToFormEntry(managedObject)
        }
    }
    
    private func loadDraftFromDatabase(formId: String) async throws -> FormEntry? {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "formId == %@ AND isDraft == TRUE", formId)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            guard let managedObject = results.first else { return nil }
            
            return try self.managedObjectToFormEntry(managedObject)
        }
    }
    
    private func loadNewDraftFromDatabase(formId: String) async throws -> FormEntry? {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "formId == %@ AND isDraft == TRUE AND sourceEntryId == nil", formId)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            guard let managedObject = results.first else { return nil }
            
            return try self.managedObjectToFormEntry(managedObject)
        }
    }
    
    private func loadEditDraftFromDatabase(entryId: String) async throws -> FormEntry? {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "sourceEntryId == %@ AND isDraft == TRUE", entryId)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            guard let managedObject = results.first else { return nil }
            
            return try self.managedObjectToFormEntry(managedObject)
        }
    }
    
    private func loadEntriesByStatus(formId: String, isDraft: Bool?, isComplete: Bool?) async throws -> [FormEntry] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            
            var predicateFormat = "formId == %@"
            var predicateArgs: [Any] = [formId]
            
            if let isDraft = isDraft {
                predicateFormat += " AND isDraft == %@"
                predicateArgs.append(isDraft)
            }
            
            if let isComplete = isComplete {
                predicateFormat += " AND isComplete == %@"
                predicateArgs.append(isComplete)
            }
            
            fetchRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            return try results.compactMap { try self.managedObjectToFormEntry($0) }
        }
    }
    
    private func findDraftIdForForm(_ formId: String) async throws -> String? {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "formId == %@ AND isDraft == TRUE", formId)
            
            let results = try context.fetch(fetchRequest)
            guard let managedObject = results.first else { return nil }
            
            return managedObject.value(forKey: "id") as? String
        }
    }
    
    private func loadEntriesInDateRange(formId: String, from startDate: Date, to endDate: Date) async throws -> [FormEntry] {
        return try await coreDataStack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FormEntryEntity")
            fetchRequest.predicate = NSPredicate(format: "formId == %@ AND createdAt >= %@ AND createdAt <= %@", formId, startDate as NSDate, endDate as NSDate)
            let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            let results = try context.fetch(fetchRequest)
            return try results.compactMap { try self.managedObjectToFormEntry($0) }
        }
    }
    
    // MARK: - Helper Methods
    
    private func managedObjectToFormEntry(_ managedObject: NSManagedObject) throws -> FormEntry {
        guard let id = managedObject.value(forKey: "id") as? String,
              let formId = managedObject.value(forKey: "formId") as? String,
              let createdAt = managedObject.value(forKey: "createdAt") as? Date,
              let updatedAt = managedObject.value(forKey: "updatedAt") as? Date,
              let isComplete = managedObject.value(forKey: "isComplete") as? Bool,
              let isDraft = managedObject.value(forKey: "isDraft") as? Bool else {
            throw FormEntryRepositoryError.persistenceError("Invalid managed object data")
        }
        
        let sourceEntryId = managedObject.value(forKey: "sourceEntryId") as? String
        
        // Deserialize fieldValues
        var fieldValues: [String: String] = [:]
        if let fieldValuesData = managedObject.value(forKey: "fieldValuesData") as? Data {
            fieldValues = (try? JSONDecoder().decode([String: String].self, from: fieldValuesData)) ?? [:]
        }
        
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
}