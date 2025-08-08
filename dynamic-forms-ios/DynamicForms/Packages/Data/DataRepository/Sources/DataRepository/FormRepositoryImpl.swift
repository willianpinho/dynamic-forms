import Foundation
import Combine
import Domain
import DataLocal
import Utilities

/// Form repository implementation using JSON assets and Core Data
/// Following Repository Pattern and Dependency Inversion Principle
public final class FormRepositoryImpl: FormRepository {
    
    // MARK: - Dependencies
    private let coreDataStack: CoreDataStack
    private let logger: Logger
    private let bundle: Bundle
    
    // MARK: - Cache
    private var cachedForms: [DynamicForm] = []
    private var isDataInitialized = false
    
    // MARK: - Publishers
    private let formsSubject = CurrentValueSubject<[DynamicForm], Never>([])
    
    // MARK: - Initialization
    public init(
        coreDataStack: CoreDataStack = CoreDataStack.shared,
        logger: Logger = ConsoleLogger(),
        bundle: Bundle = Bundle.main
    ) {
        self.coreDataStack = coreDataStack
        self.logger = logger
        self.bundle = bundle
        
        // Initialize with empty array and log
        logger.debug("FormRepositoryImpl initialized with empty forms cache")
    }
    
    // MARK: - FormRepository Implementation
    
    public func getAllForms() async throws -> [DynamicForm] {
        logger.debug("getAllForms() called, current cache has \(cachedForms.count) forms")
        
        // If cache is empty, try to load from assets
        if cachedForms.isEmpty && !isDataInitialized {
            logger.debug("Cache is empty, attempting to load forms from assets...")
            let result = await loadFormsFromAssets()
            switch result {
            case .success(let forms):
                logger.debug("Successfully loaded \(forms.count) forms from assets")
                return forms
            case .failure(let error):
                logger.error("Failed to load forms from assets: \(error.localizedDescription)")
                throw error
            }
        }
        
        return cachedForms
    }
    
    public func getFormById(_ id: String) -> AnyPublisher<DynamicForm?, Error> {
        return formsSubject
            .map { forms in forms.first { $0.id == id } }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func insertForm(_ form: DynamicForm) async -> Result<Void, Error> {
        do {
            // Add to cache
            if !cachedForms.contains(where: { $0.id == form.id }) {
                cachedForms.append(form)
                formsSubject.send(cachedForms)
            }
            
            logger.debug("Form '\(form.title)' inserted successfully")
            return .success(())
            
        } catch {
            logger.error("Failed to insert form: \(error.localizedDescription)")
            return .failure(FormRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func updateForm(_ form: DynamicForm) async -> Result<Void, Error> {
        do {
            // Update in cache
            if let index = cachedForms.firstIndex(where: { $0.id == form.id }) {
                cachedForms[index] = form
                formsSubject.send(cachedForms)
            } else {
                return .failure(FormRepositoryError.formNotFound(form.id))
            }
            
            logger.debug("Form '\(form.title)' updated successfully")
            return .success(())
            
        } catch {
            logger.error("Failed to update form: \(error.localizedDescription)")
            return .failure(FormRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func deleteForm(_ id: String) async -> Result<Void, Error> {
        do {
            // Remove from cache
            if let index = cachedForms.firstIndex(where: { $0.id == id }) {
                cachedForms.remove(at: index)
                formsSubject.send(cachedForms)
            } else {
                return .failure(FormRepositoryError.formNotFound(id))
            }
            
            logger.debug("Form with ID '\(id)' deleted successfully")
            return .success(())
            
        } catch {
            logger.error("Failed to delete form: \(error.localizedDescription)")
            return .failure(FormRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func loadFormsFromAssets() async -> Result<[DynamicForm], Error> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let forms = try self.loadFormsFromBundle()
                    continuation.resume(returning: .success(forms))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    public func clearAndReloadForms() async -> Result<[DynamicForm], Error> {
        // For CoreData implementation, we'd clear the store here
        // For now, just clear cache and reload from assets
        cachedForms = []
        isDataInitialized = false
        formsSubject.send(cachedForms)
        
        logger.debug("✅ Cleared forms cache")
        
        let result = await loadFormsFromAssets()
        if case .success(let forms) = result {
            cachedForms = forms
            isDataInitialized = true
            formsSubject.send(cachedForms)
            logger.debug("✅ Reloaded \(forms.count) forms from assets")
        }
        
        return result
    }
    
    public func isFormsDataInitialized() async -> Bool {
        return isDataInitialized && !cachedForms.isEmpty
    }
    
    public func searchForms(_ query: String) -> AnyPublisher<[DynamicForm], Error> {
        return formsSubject
            .map { forms in
                forms.filter { form in
                    form.title.localizedCaseInsensitiveContains(query) ||
                    form.fields.contains { field in
                        field.label.localizedCaseInsensitiveContains(query)
                    }
                }
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getFormsInDateRange(from startDate: Date, to endDate: Date) -> AnyPublisher<[DynamicForm], Error> {
        return formsSubject
            .map { forms in
                forms.filter { form in
                    form.createdAt >= startDate && form.createdAt <= endDate
                }
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func loadFormsFromBundle() throws -> [DynamicForm] {
        // Load forms from bundle assets
        let formFiles = ["200-form", "all-fields"]
        var loadedForms: [DynamicForm] = []
        
        logger.debug("Starting to load forms from bundle...")
        logger.debug("Bundle: \(bundle)")
        logger.debug("Form files to load: \(formFiles)")
        
        for fileName in formFiles {
            logger.debug("Attempting to load: \(fileName).json")
            
            guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
                logger.warning("Form file '\(fileName).json' not found in bundle")
                continue
            }
            
            logger.debug("✅ Found file at URL: \(url)")
            
            do {
                logger.debug("Reading data from file...")
                let data = try Data(contentsOf: url)
                logger.debug("✅ Read \(data.count) bytes from file")
                
                logger.debug("Decoding JSON...")
                let form = try JSONDecoder().decode(DynamicForm.self, from: data)
                loadedForms.append(form)
                logger.debug("✅ Loaded form: \(form.title) with \(form.fields.count) fields")
            } catch {
                logger.error("❌ Failed to decode form from '\(fileName).json': \(error.localizedDescription)")
                throw FormRepositoryError.assetLoadingFailed("Failed to decode \(fileName).json: \(error.localizedDescription)")
            }
        }
        
        if loadedForms.isEmpty {
            logger.error("❌ No forms found in bundle")
            throw FormRepositoryError.assetLoadingFailed("No forms found in bundle")
        }
        
        logger.debug("Updating cache and notifying subscribers...")
        // Update cache and notify subscribers
        cachedForms = loadedForms
        isDataInitialized = true
        formsSubject.send(cachedForms)
        
        logger.info("✅ Successfully loaded \(loadedForms.count) forms from assets")
        return loadedForms
    }
}

// MARK: - Extensions
public extension FormRepositoryImpl {
    
    /// Reload forms from assets
    func reloadFromAssets() async -> Result<Void, Error> {
        let result = await loadFormsFromAssets()
        return result.map { _ in () }
    }
    
    /// Clear all cached forms
    func clearCache() {
        cachedForms.removeAll()
        isDataInitialized = false
        formsSubject.send([])
        logger.debug("Forms cache cleared")
    }
    
    /// Get cache statistics
    func getCacheInfo() -> (count: Int, isInitialized: Bool) {
        return (cachedForms.count, isDataInitialized)
    }
}