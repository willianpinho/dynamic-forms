import Foundation
import CoreData
import Utilities

/// Core Data stack following Single Responsibility Principle
/// Manages the Core Data persistence layer
@available(iOS 13.0, macOS 12.0, *)
public final class CoreDataStack {
    
    // MARK: - Properties
    public static let shared = CoreDataStack()
    
    private let modelName: String
    private let logger: Logger
    
    // MARK: - Core Data Stack
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                self.logger.error("Core Data failed to load store: \(error.localizedDescription)")
                fatalError("Core Data failed to load store: \(error)")
            } else {
                self.logger.info("Core Data store loaded successfully")
            }
        }
        
        // Configure automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Initialization
    public init(modelName: String = "DynamicForms") {
        self.modelName = modelName
        self.logger = ConsoleLogger()
    }
    
    // MARK: - Save Context
    public func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                logger.debug("Main context saved successfully")
            } catch {
                logger.error("Failed to save main context: \(error.localizedDescription)")
                // In a production app, you might want to handle this more gracefully
                fatalError("Failed to save main context: \(error)")
            }
        }
    }
    
    @available(iOS 13.0, macOS 12.0, *)
    public func saveBackgroundContext(_ context: NSManagedObjectContext) async throws {
        try await context.perform {
            if context.hasChanges {
                try context.save()
                self.logger.debug("Background context saved successfully")
            }
        }
    }
    
    // MARK: - Background Operations
    @available(iOS 13.0, macOS 12.0, *)
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = backgroundContext
        
        return try await context.perform {
            let result = try block(context)
            
            if context.hasChanges {
                try context.save()
                self.logger.debug("Background task completed and saved")
            }
            
            return result
        }
    }
    
    // MARK: - Fetch Operations
    @available(iOS 13.0, macOS 12.0, *)
    public func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await viewContext.perform {
            try self.viewContext.fetch(request)
        }
    }
    
    @available(iOS 13.0, macOS 12.0, *)
    public func fetchBackground<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        let context = backgroundContext
        return try await context.perform {
            try context.fetch(request)
        }
    }
    
    // MARK: - Count Operations
    @available(iOS 13.0, macOS 12.0, *)
    public func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int {
        return try await viewContext.perform {
            try self.viewContext.count(for: request)
        }
    }
    
    // MARK: - Delete Operations
    public func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
    }
    
    public func deleteAll<T: NSManagedObject>(_ type: T.Type) async throws {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        let objects = try await fetch(request)
        
        for object in objects {
            delete(object)
        }
        
        saveContext()
    }
    
    // MARK: - Batch Operations
    @available(iOS 13.0, macOS 12.0, *)
    public func batchDelete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) async throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        fetchRequest.predicate = predicate
        
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        request.resultType = .resultTypeObjectIDs
        
        let result = try await viewContext.perform {
            try self.viewContext.execute(request) as? NSBatchDeleteResult
        }
        
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        }
    }
    
    // MARK: - Memory Management
    public func refresh(_ object: NSManagedObject, mergeChanges: Bool = true) {
        viewContext.refresh(object, mergeChanges: mergeChanges)
    }
    
    public func reset() {
        viewContext.reset()
        logger.info("Core Data context reset")
    }
}

// MARK: - Core Data Error Types
public enum CoreDataError: Error, LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case objectNotFound(String)
    case invalidContext
    
    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .objectNotFound(let message):
            return "Object not found: \(message)"
        case .invalidContext:
            return "Invalid Core Data context"
        }
    }
}

// MARK: - Extensions
public extension NSManagedObjectContext {
    
    /// Save context with error handling
    func saveWithErrorHandling() throws {
        guard hasChanges else { return }
        
        do {
            try save()
        } catch {
            throw CoreDataError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Fetch with error handling
    func fetchWithErrorHandling<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        do {
            return try fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error.localizedDescription)
        }
    }
}

// MARK: - Test Support
#if DEBUG
@available(iOS 13.0, macOS 12.0, *)
public extension CoreDataStack {
    
    /// Create in-memory stack for testing
    static func inMemoryStack() -> CoreDataStack {
        let stack = CoreDataStack()
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        stack.persistentContainer.persistentStoreDescriptions = [description]
        
        return stack
    }
}
#endif