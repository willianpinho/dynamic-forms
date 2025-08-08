import Foundation
import Domain
import DataRepository
import DataLocal
import Utilities

/// Dependency Injection Container following Dependency Inversion Principle
/// Manages object creation and dependency resolution
public final class DIContainer {
    
    // MARK: - Singleton
    public static let shared = DIContainer()
    
    // MARK: - Core Dependencies
    private lazy var logger: Logger = ConsoleLogger()
    
    // MARK: - SwiftData Dependencies (iOS 17+)
    @available(iOS 17.0, *)
    private lazy var swiftDataStack: SwiftDataStack = SwiftDataStack.shared
    
    // MARK: - Core Data Dependencies (Fallback)
    private lazy var coreDataStack: CoreDataStack = CoreDataStack.shared
    
    // MARK: - Repositories
    private lazy var formRepository: FormRepository = {
        if #available(iOS 17.0, *) {
            return FormRepositorySwiftData(
                swiftDataStack: swiftDataStack,
                logger: logger
            )
        } else {
            return FormRepositoryImpl(
                coreDataStack: coreDataStack,
                logger: logger
            )
        }
    }()
    
    private lazy var formEntryRepository: FormEntryRepository = {
        if #available(iOS 17.0, *) {
            return FormEntryRepositorySwiftData(
                swiftDataStack: swiftDataStack,
                logger: logger
            )
        } else {
            return FormEntryRepositoryImpl(
                coreDataStack: coreDataStack,
                logger: logger
            )
        }
    }()
    
    // MARK: - Use Cases
    private lazy var getAllFormsUseCase: GetAllFormsUseCase = GetAllFormsUseCase(
        formRepository: formRepository
    )
    
    private lazy var initializeFormsUseCase: InitializeFormsUseCase = InitializeFormsUseCase(
        formRepository: formRepository
    )
    
    private lazy var saveFormEntryUseCase: SaveFormEntryUseCase = SaveFormEntryUseCase(
        formEntryRepository: formEntryRepository
    )
    
    private lazy var validateFormEntryUseCase: ValidateFormEntryUseCase = ValidateFormEntryUseCase()
    
    private lazy var getFormEntriesUseCase: GetFormEntriesUseCase = GetFormEntriesUseCase(
        formEntryRepository: formEntryRepository
    )
    
    private lazy var deleteFormEntryUseCase: DeleteFormEntryUseCase = DeleteFormEntryUseCase(
        formEntryRepository: formEntryRepository
    )
    
    private lazy var autoSaveFormEntryUseCase: AutoSaveFormEntryUseCase = AutoSaveFormEntryUseCase(
        formEntryRepository: formEntryRepository,
        logger: logger
    )
    
    private lazy var testFormLoadingUseCase: TestFormLoadingUseCase = TestFormLoadingUseCase(
        formRepository: formRepository
    )
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Factory Methods
    
    /// Get Form Repository
    public func getFormRepository() -> FormRepository {
        return formRepository
    }
    
    /// Get Form Entry Repository
    public func getFormEntryRepository() -> FormEntryRepository {
        return formEntryRepository
    }
    
    /// Get All Forms Use Case
    public func getGetAllFormsUseCase() -> GetAllFormsUseCase {
        return getAllFormsUseCase
    }
    
    /// Get Initialize Forms Use Case
    public func getInitializeFormsUseCase() -> InitializeFormsUseCase {
        return initializeFormsUseCase
    }
    
    /// Get Save Form Entry Use Case
    public func getSaveFormEntryUseCase() -> SaveFormEntryUseCase {
        return saveFormEntryUseCase
    }
    
    /// Get Validate Form Entry Use Case
    public func getValidateFormEntryUseCase() -> ValidateFormEntryUseCase {
        return validateFormEntryUseCase
    }
    
    /// Get Form Entries Use Case
    public func getGetFormEntriesUseCase() -> GetFormEntriesUseCase {
        return getFormEntriesUseCase
    }
    
    /// Get Delete Form Entry Use Case
    public func getDeleteFormEntryUseCase() -> DeleteFormEntryUseCase {
        return deleteFormEntryUseCase
    }
    
    /// Get Auto Save Form Entry Use Case
    public func getAutoSaveFormEntryUseCase() -> AutoSaveFormEntryUseCase {
        return autoSaveFormEntryUseCase
    }
    
    /// Get Test Form Loading Use Case (Debug only)
    public func getTestFormLoadingUseCase() -> TestFormLoadingUseCase {
        return testFormLoadingUseCase
    }
    
    /// Get Logger
    public func getLogger() -> Logger {
        return logger
    }
    
    /// Get Core Data Stack
    public func getCoreDataStack() -> CoreDataStack {
        return coreDataStack
    }
}

// MARK: - Test Support
#if DEBUG
public extension DIContainer {
    
    /// Create test container with mock dependencies
    static func testContainer() -> DIContainer {
        let container = DIContainer()
        // In a real app, you would override dependencies with mocks here
        return container
    }
}
#endif