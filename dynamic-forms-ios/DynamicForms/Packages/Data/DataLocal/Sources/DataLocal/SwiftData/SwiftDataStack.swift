import Foundation
import SwiftData
import Domain
import Utilities

/// SwiftData stack following modern iOS development practices
/// Manages SwiftData persistence layer with type safety
@available(iOS 17.0, macOS 14.0, *)
public final class SwiftDataStack {
    
    // MARK: - Properties
    public static let shared = SwiftDataStack()
    
    private let logger: Logger
    private var _modelContainer: ModelContainer?
    
    // MARK: - Model Container
    public var modelContainer: ModelContainer {
        get throws {
            if let container = _modelContainer {
                return container
            }
            
            let container = try createModelContainer()
            _modelContainer = container
            return container
        }
    }
    
    // MARK: - Initialization
    public init() {
        self.logger = ConsoleLogger()
    }
    
    // MARK: - Container Creation
    private func createModelContainer() throws -> ModelContainer {
        do {
            let schema = Schema([
                FormEntity.self,
                FormFieldEntity.self,
                FormSectionEntity.self,
                FormEntryEntity.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none // Can be configured for CloudKit sync
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            logger.info("SwiftData container created successfully")
            return container
            
        } catch {
            logger.error("Failed to create SwiftData container: \(error.localizedDescription)")
            throw SwiftDataError.containerCreationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Context Operations
    @MainActor
    @available(iOS 17.0, macOS 14.0, *)
    public func save(context: ModelContext) throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            logger.debug("SwiftData context saved successfully")
        } catch {
            logger.error("Failed to save SwiftData context: \(error.localizedDescription)")
            throw SwiftDataError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Background Operations
    public func performBackgroundTask<T>(_ operation: @escaping (ModelContext) throws -> T) async throws -> T {
        let container = try modelContainer
        
        return try await Task.detached {
            let context = ModelContext(container)
            let result = try operation(context)
            
            if context.hasChanges {
                try context.save()
                self.logger.debug("Background SwiftData operation completed")
            }
            
            return result
        }.value
    }
}

// MARK: - SwiftData Error Types
public enum SwiftDataError: Error, LocalizedError {
    case containerCreationFailed(String)
    case saveFailed(String)
    case fetchFailed(String)
    case modelNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let message):
            return "Container creation failed: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .modelNotFound(let message):
            return "Model not found: \(message)"
        }
    }
}

// MARK: - Test Support
#if DEBUG
@available(iOS 17.0, macOS 14.0, *)
public extension SwiftDataStack {
    
    /// Create in-memory stack for testing
    static func inMemoryStack() throws -> SwiftDataStack {
        let stack = SwiftDataStack()
        
        let schema = Schema([
            FormEntity.self,
            FormFieldEntity.self,
            FormSectionEntity.self,
            FormEntryEntity.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        stack._modelContainer = container
        return stack
    }
}
#endif