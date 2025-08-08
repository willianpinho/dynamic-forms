import Foundation

/// Use case for initializing forms data from bundled assets
/// Following Single Responsibility Principle and Clean Architecture
@available(iOS 13.0, macOS 10.15, *)
public final class InitializeFormsUseCase {
    
    // MARK: - Dependencies
    private let formRepository: FormRepository
    
    // MARK: - Initialization
    public init(formRepository: FormRepository) {
        self.formRepository = formRepository
    }
    
    // MARK: - Execution
    
    /// Initialize forms data if not already done
    /// - Returns: Result indicating success or failure
    public func execute() async -> Result<Void, Error> {
        do {
            // Check if forms data is already initialized
            let isInitialized = await formRepository.isFormsDataInitialized()
            
            if isInitialized {
                return .success(())
            }
            
            // Load forms from assets
            let formsResult = await formRepository.loadFormsFromAssets()
            
            switch formsResult {
            case .success(let forms):
                // Insert each form into the repository
                for form in forms {
                    let insertResult = await formRepository.insertForm(form)
                    if case .failure(let error) = insertResult {
                        return .failure(InitializeFormsError.insertionFailed(error.localizedDescription))
                    }
                }
                
                return .success(())
                
            case .failure(let error):
                return .failure(InitializeFormsError.assetLoadingFailed(error.localizedDescription))
            }
            
        } catch {
            return .failure(InitializeFormsError.initializationFailed(error.localizedDescription))
        }
    }
    
    /// Force re-initialization of forms data
    /// - Returns: Result indicating success or failure
    public func forceReinitialize() async -> Result<Void, Error> {
        do {
            // Load forms from assets
            let formsResult = await formRepository.loadFormsFromAssets()
            
            switch formsResult {
            case .success(let forms):
                // Clear existing forms and insert new ones
                // Note: This is a simple implementation. In a real app, you might want to be more careful about this.
                for form in forms {
                    // Try to update first, then insert if not exists
                    let updateResult = await formRepository.updateForm(form)
                    if case .failure = updateResult {
                        let insertResult = await formRepository.insertForm(form)
                        if case .failure(let error) = insertResult {
                            return .failure(InitializeFormsError.insertionFailed(error.localizedDescription))
                        }
                    }
                }
                
                return .success(())
                
            case .failure(let error):
                return .failure(InitializeFormsError.assetLoadingFailed(error.localizedDescription))
            }
            
        } catch {
            return .failure(InitializeFormsError.initializationFailed(error.localizedDescription))
        }
    }
    
    /// Check initialization status
    /// - Returns: Boolean indicating if forms are initialized
    public func checkInitializationStatus() async -> Bool {
        return await formRepository.isFormsDataInitialized()
    }
    
    /// Get initialization progress information
    /// - Returns: InitializationProgress with details
    public func getInitializationProgress() async -> InitializationProgress {
        let isInitialized = await formRepository.isFormsDataInitialized()
        
        if isInitialized {
            do {
                let formsCount = try await formRepository.getFormsCount()
                return InitializationProgress(
                    isInitialized: true,
                    formsCount: formsCount,
                    status: .completed,
                    errorMessage: nil
                )
            } catch {
                return InitializationProgress(
                    isInitialized: false,
                    formsCount: 0,
                    status: .error,
                    errorMessage: error.localizedDescription
                )
            }
        } else {
            return InitializationProgress(
                isInitialized: false,
                formsCount: 0,
                status: .notStarted,
                errorMessage: nil
            )
        }
    }
    
    /// Initialize with progress tracking
    /// - Parameter progressHandler: Closure called with progress updates
    /// - Returns: Result indicating success or failure
    public func executeWithProgress(
        progressHandler: @escaping (InitializationProgress) -> Void
    ) async -> Result<Void, Error> {
        
        // Initial progress
        progressHandler(InitializationProgress(
            isInitialized: false,
            formsCount: 0,
            status: .inProgress,
            errorMessage: nil
        ))
        
        do {
            // Check if already initialized
            let isInitialized = await formRepository.isFormsDataInitialized()
            
            if isInitialized {
                let formsCount = try await formRepository.getFormsCount()
                progressHandler(InitializationProgress(
                    isInitialized: true,
                    formsCount: formsCount,
                    status: .completed,
                    errorMessage: nil
                ))
                return .success(())
            }
            
            // Load forms from assets
            let formsResult = await formRepository.loadFormsFromAssets()
            
            switch formsResult {
            case .success(let forms):
                // Insert forms with progress updates
                for (index, form) in forms.enumerated() {
                    let insertResult = await formRepository.insertForm(form)
                    
                    if case .failure(let error) = insertResult {
                        let errorProgress = InitializationProgress(
                            isInitialized: false,
                            formsCount: index,
                            status: .error,
                            errorMessage: error.localizedDescription
                        )
                        progressHandler(errorProgress)
                        return .failure(InitializeFormsError.insertionFailed(error.localizedDescription))
                    }
                    
                    // Update progress
                    let currentProgress = InitializationProgress(
                        isInitialized: false,
                        formsCount: index + 1,
                        status: .inProgress,
                        errorMessage: nil
                    )
                    progressHandler(currentProgress)
                }
                
                // Final success progress
                progressHandler(InitializationProgress(
                    isInitialized: true,
                    formsCount: forms.count,
                    status: .completed,
                    errorMessage: nil
                ))
                
                return .success(())
                
            case .failure(let error):
                let errorProgress = InitializationProgress(
                    isInitialized: false,
                    formsCount: 0,
                    status: .error,
                    errorMessage: error.localizedDescription
                )
                progressHandler(errorProgress)
                return .failure(InitializeFormsError.assetLoadingFailed(error.localizedDescription))
            }
            
        } catch {
            let errorProgress = InitializationProgress(
                isInitialized: false,
                formsCount: 0,
                status: .error,
                errorMessage: error.localizedDescription
            )
            progressHandler(errorProgress)
            return .failure(InitializeFormsError.initializationFailed(error.localizedDescription))
        }
    }
}

// MARK: - Error Types
public enum InitializeFormsError: Error, LocalizedError {
    case initializationFailed(String)
    case assetLoadingFailed(String)
    case insertionFailed(String)
    case alreadyInitialized
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Initialization failed: \(reason)"
        case .assetLoadingFailed(let reason):
            return "Asset loading failed: \(reason)"
        case .insertionFailed(let reason):
            return "Form insertion failed: \(reason)"
        case .alreadyInitialized:
            return "Forms data is already initialized"
        }
    }
}

// MARK: - Supporting Types
public struct InitializationProgress {
    public let isInitialized: Bool
    public let formsCount: Int
    public let status: InitializationStatus
    public let errorMessage: String?
    
    public var progressPercentage: Double {
        // This is a simple example. In a real app, you might have more sophisticated progress tracking
        switch status {
        case .notStarted:
            return 0.0
        case .inProgress:
            return 0.5
        case .completed:
            return 1.0
        case .error:
            return 0.0
        }
    }
    
    public init(isInitialized: Bool, formsCount: Int, status: InitializationStatus, errorMessage: String?) {
        self.isInitialized = isInitialized
        self.formsCount = formsCount
        self.status = status
        self.errorMessage = errorMessage
    }
}

public enum InitializationStatus {
    case notStarted
    case inProgress
    case completed
    case error
    
    public var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .error:
            return "Error"
        }
    }
}

// MARK: - Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension InitializeFormsUseCase {
    
    /// Execute with simple completion handler
    /// - Parameter completion: Closure called when initialization completes
    func execute(completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            let result = await execute()
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    /// Check if initialization is needed
    /// - Returns: Boolean indicating if initialization is required
    func isInitializationNeeded() async -> Bool {
        let isInitialized = await formRepository.isFormsDataInitialized()
        return !isInitialized
    }
}