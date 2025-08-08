import Foundation
import SwiftData
import Combine
import Domain
import DataLocal
import Utilities

/// SwiftData implementation of FormRepository
/// Following Repository Pattern with modern SwiftData APIs
@available(iOS 17.0, macOS 14.0, *)
public final class FormRepositorySwiftData: FormRepository {
    
    // MARK: - Dependencies
    private let swiftDataStack: SwiftDataStack
    private let logger: Logger
    private let bundle: Bundle
    
    // MARK: - Cache and Publishers
    private var cachedForms: [DynamicForm] = []
    private var isDataInitialized = false
    private let formsSubject = CurrentValueSubject<[DynamicForm], Never>([])
    
    // MARK: - Initialization
    public init(
        swiftDataStack: SwiftDataStack = SwiftDataStack.shared,
        logger: Logger = ConsoleLogger(),
        bundle: Bundle = Bundle.main
    ) {
        self.swiftDataStack = swiftDataStack
        self.logger = logger
        self.bundle = bundle
    }
    
    // MARK: - FormRepository Implementation
    
    public func getAllForms() async throws -> [DynamicForm] {
        // If cache is empty, try to load from database first
        if cachedForms.isEmpty {
            do {
                let databaseForms = try await loadFormsFromDatabase()
                if !databaseForms.isEmpty {
                    cachedForms = databaseForms
                    formsSubject.send(cachedForms)
                    logger.debug("Loaded \(databaseForms.count) forms from database")
                    
                    // Log detailed form information for debugging
                    for form in databaseForms {
                        logger.debug("Database form: '\(form.title)' - \(form.fields.count) fields, created: \(form.createdAt), updated: \(form.updatedAt)")
                    }
                    
                    return cachedForms
                }
                
                // If database is empty, load from assets
                let assetResult = await loadFormsFromAssets()
                if case .success(let assetForms) = assetResult {
                    // Save to database for future loads
                    for form in assetForms {
                        _ = await insertForm(form)
                    }
                    logger.debug("Loaded \(assetForms.count) forms from assets and saved to database")
                    return assetForms
                }
            } catch {
                logger.error("Failed to load forms from database: \(error.localizedDescription)")
                
                // Fallback to assets
                let assetResult = await loadFormsFromAssets()
                if case .success(let assetForms) = assetResult {
                    logger.debug("Loaded \(assetForms.count) forms from assets as fallback")
                    return assetForms
                }
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
            try await swiftDataStack.performBackgroundTask { context in
                let formEntity = FormEntity.fromDomain(form)
                context.insert(formEntity)
                
                // Insert fields with correct sort index
                for (index, field) in form.fields.enumerated() {
                    let fieldEntity = FormFieldEntity.fromDomain(field, sortIndex: index)
                    fieldEntity.form = formEntity
                    context.insert(fieldEntity)
                    
                    // Insert field options
                    for option in field.options {
                        let optionEntity = FormFieldOptionEntity.fromDomain(option)
                        optionEntity.field = fieldEntity
                        context.insert(optionEntity)
                    }
                }
                
                // Insert sections
                for section in form.sections {
                    let sectionEntity = FormSectionEntity.fromDomain(section)
                    sectionEntity.form = formEntity
                    context.insert(sectionEntity)
                }
                
                try context.save()
            }
            
            // Update cache
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
            try await swiftDataStack.performBackgroundTask { context in
                let descriptor = FetchDescriptor<FormEntity>(
                    predicate: #Predicate { $0.id == form.id }
                )
                
                guard let formEntity = try context.fetch(descriptor).first else {
                    throw FormRepositoryError.formNotFound(form.id)
                }
                
                // Update form properties
                formEntity.title = form.title
                formEntity.updatedAt = form.updatedAt
                
                try context.save()
            }
            
            // Update cache
            if let index = cachedForms.firstIndex(where: { $0.id == form.id }) {
                cachedForms[index] = form
                formsSubject.send(cachedForms)
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
            try await swiftDataStack.performBackgroundTask { context in
                let descriptor = FetchDescriptor<FormEntity>(
                    predicate: #Predicate { $0.id == id }
                )
                
                guard let formEntity = try context.fetch(descriptor).first else {
                    throw FormRepositoryError.formNotFound(id)
                }
                
                context.delete(formEntity)
                try context.save()
            }
            
            // Update cache
            cachedForms.removeAll { $0.id == id }
            formsSubject.send(cachedForms)
            
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
    
    /// Clear all forms from database and reload from assets
    public func clearAndReloadForms() async -> Result<[DynamicForm], Error> {
        do {
            // Clear all forms from database
            try await swiftDataStack.performBackgroundTask { context in
                let descriptor = FetchDescriptor<FormEntity>()
                let allForms = try context.fetch(descriptor)
                for form in allForms {
                    context.delete(form)
                }
                try context.save()
            }
            
            // Clear cache
            cachedForms = []
            formsSubject.send(cachedForms)
            
            logger.debug("✅ Cleared all forms from database and cache")
            
            // Reload from assets
            let assetResult = await loadFormsFromAssets()
            if case .success(let assetForms) = assetResult {
                // Save to database
                for form in assetForms {
                    _ = await insertForm(form)
                }
                logger.debug("✅ Reloaded \(assetForms.count) forms from assets")
                return .success(assetForms)
            } else {
                return assetResult
            }
            
        } catch {
            logger.error("❌ Failed to clear and reload forms: \(error.localizedDescription)")
            return .failure(FormRepositoryError.persistenceError(error.localizedDescription))
        }
    }
    
    public func isFormsDataInitialized() async -> Bool {
        // Check if cache is populated first
        if !cachedForms.isEmpty {
            return true
        }
        
        do {
            let container = try swiftDataStack.modelContainer
            let context = ModelContext(container)
            
            let descriptor = FetchDescriptor<FormEntity>()
            let count = try context.fetchCount(descriptor)
            
            return count > 0
            
        } catch {
            logger.error("Failed to check initialization status: \(error.localizedDescription)")
            return false
        }
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
        let formFiles = ["200-form", "all-fields"]
        var loadedForms: [DynamicForm] = []
        
        logger.debug("Starting to load forms from bundle...")
        logger.debug("Bundle: \(bundle)")
        logger.debug("Form files to load: \(formFiles)")
        
        for fileName in formFiles {
            logger.debug("Attempting to load: \(fileName).json")
            
            guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
                logger.error("❌ Form file '\(fileName).json' not found in bundle")
                logger.debug("Bundle URLs: \(bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])")
                throw FormRepositoryError.assetLoadingFailed("Form file '\(fileName).json' not found in bundle")
            }
            
            logger.debug("✅ Found file at URL: \(url)")
            
            do {
                let data = try Data(contentsOf: url)
                logger.debug("✅ Read \(data.count) bytes from \(fileName).json")
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let form = try decoder.decode(DynamicForm.self, from: data)
                
                // Assign ID based on filename if not present and create different dates
                var formWithId = form
                if form.id.isEmpty {
                    // Create different dates for different forms to test sorting
                    let baseDate = Date()
                    let createdDate: Date
                    let updatedDate: Date
                    
                    if fileName == "200-form" {
                        // Make 200-form older
                        createdDate = baseDate.addingTimeInterval(-86400) // 1 day ago
                        updatedDate = baseDate.addingTimeInterval(-43200) // 12 hours ago
                    } else {
                        // Make all-fields newer
                        createdDate = baseDate.addingTimeInterval(-3600) // 1 hour ago
                        updatedDate = baseDate.addingTimeInterval(-1800) // 30 minutes ago
                    }
                    
                    formWithId = DynamicForm(
                        id: fileName,
                        title: form.title,
                        fields: form.fields,
                        sections: form.sections,
                        createdAt: createdDate,
                        updatedAt: updatedDate
                    )
                }
                
                loadedForms.append(formWithId)
                logger.info("✅ Successfully loaded form: '\(formWithId.title)' (ID: \(formWithId.id)) with \(formWithId.fields.count) fields, created: \(formWithId.createdAt), updated: \(formWithId.updatedAt)")
                
            } catch let decodingError {
                logger.error("❌ Failed to decode form from '\(fileName).json': \(decodingError)")
                if let jsonError = decodingError as? DecodingError {
                    logger.error("JSON Decoding Error Details: \(jsonError)")
                }
                throw FormRepositoryError.assetLoadingFailed("Failed to decode \(fileName).json: \(decodingError.localizedDescription)")
            }
        }
        
        if loadedForms.isEmpty {
            logger.error("❌ No forms were successfully loaded from bundle")
            throw FormRepositoryError.assetLoadingFailed("No forms found in bundle")
        }
        
        // Update cache and notify subscribers
        cachedForms = loadedForms
        isDataInitialized = true
        formsSubject.send(cachedForms)
        
        logger.info("🎉 Successfully loaded \(loadedForms.count) forms from assets:")
        for (index, form) in loadedForms.enumerated() {
            logger.info("  \(index + 1). \(form.title) (ID: \(form.id)) - \(form.fields.count) fields, \(form.sections.count) sections")
        }
        
        return loadedForms
    }
    
    private func loadFormsFromDatabase() async throws -> [DynamicForm] {
        return try await swiftDataStack.performBackgroundTask { context in
            let descriptor = FetchDescriptor<FormEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let formEntities = try context.fetch(descriptor)
            return formEntities.map { $0.toDomain() }
        }
    }
}

// MARK: - Extensions
@available(iOS 17.0, macOS 14.0, *)
public extension FormRepositorySwiftData {
    
    /// Reload forms from database and update cache
    func reloadFromDatabase() async -> Result<Void, Error> {
        do {
            let forms = try await loadFormsFromDatabase()
            cachedForms = forms
            formsSubject.send(cachedForms)
            logger.debug("Forms reloaded from database")
            return .success(())
        } catch {
            logger.error("Failed to reload forms from database: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// Get database statistics
    func getDatabaseStats() async -> (formCount: Int, fieldCount: Int) {
        do {
            let container = try swiftDataStack.modelContainer
            let context = ModelContext(container)
            
            let formDescriptor = FetchDescriptor<FormEntity>()
            let fieldDescriptor = FetchDescriptor<FormFieldEntity>()
            
            let formCount = try context.fetchCount(formDescriptor)
            let fieldCount = try context.fetchCount(fieldDescriptor)
            
            return (formCount, fieldCount)
        } catch {
            logger.error("Failed to get database stats: \(error.localizedDescription)")
            return (0, 0)
        }
    }
}
