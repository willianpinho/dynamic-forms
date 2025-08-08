import Foundation
import Combine

/// Form repository interface defining data access operations for forms
/// Following Repository Pattern and Dependency Inversion Principle
@available(iOS 13.0, macOS 10.15, *)
public protocol FormRepository {
    
    // MARK: - Form Operations
    
    /// Get all available forms
    /// - Returns: Array of DynamicForm objects
    func getAllForms() async throws -> [DynamicForm]
    
    /// Get form by ID
    /// - Parameter id: Form identifier
    /// - Returns: Publisher emitting optional DynamicForm
    func getFormById(_ id: String) -> AnyPublisher<DynamicForm?, Error>
    
    /// Insert new form
    /// - Parameter form: DynamicForm to insert
    /// - Returns: Result indicating success or failure
    func insertForm(_ form: DynamicForm) async -> Result<Void, Error>
    
    /// Update existing form
    /// - Parameter form: DynamicForm to update
    /// - Returns: Result indicating success or failure
    func updateForm(_ form: DynamicForm) async -> Result<Void, Error>
    
    /// Delete form by ID
    /// - Parameter id: Form identifier to delete
    /// - Returns: Result indicating success or failure
    func deleteForm(_ id: String) async -> Result<Void, Error>
    
    // MARK: - Data Initialization
    
    /// Load forms from bundled assets
    /// - Returns: Result containing array of loaded forms
    func loadFormsFromAssets() async -> Result<[DynamicForm], Error>
    
    /// Clear all forms from database and reload from assets
    /// - Returns: Result containing array of reloaded forms
    func clearAndReloadForms() async -> Result<[DynamicForm], Error>
    
    /// Check if forms data has been initialized
    /// - Returns: Boolean indicating initialization status
    func isFormsDataInitialized() async -> Bool
    
    // MARK: - Search and Filtering
    
    /// Search forms by title or content
    /// - Parameter query: Search query string
    /// - Returns: Publisher emitting filtered forms
    func searchForms(_ query: String) -> AnyPublisher<[DynamicForm], Error>
    
    /// Get forms created within date range
    /// - Parameters:
    ///   - startDate: Start date for range
    ///   - endDate: End date for range
    /// - Returns: Publisher emitting filtered forms
    func getFormsInDateRange(from startDate: Date, to endDate: Date) -> AnyPublisher<[DynamicForm], Error>
}

// MARK: - Repository Error Types
public enum FormRepositoryError: Error, LocalizedError {
    case formNotFound(String)
    case invalidFormData(String)
    case persistenceError(String)
    case initializationFailed(String)
    case assetLoadingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .formNotFound(let id):
            return "Form with ID '\(id)' not found"
        case .invalidFormData(let reason):
            return "Invalid form data: \(reason)"
        case .persistenceError(let reason):
            return "Persistence error: \(reason)"
        case .initializationFailed(let reason):
            return "Initialization failed: \(reason)"
        case .assetLoadingFailed(let reason):
            return "Asset loading failed: \(reason)"
        }
    }
}

// MARK: - Repository Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension FormRepository {
    
    /// Check if form exists
    /// - Parameter id: Form identifier
    /// - Returns: Boolean indicating existence
    func formExists(_ id: String) async -> Bool {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let cancellable = getFormById(id)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(_) = completion {
                                continuation.resume(returning: false)
                            }
                        },
                        receiveValue: { form in
                            continuation.resume(returning: form != nil)
                        }
                    )
                _ = cancellable
            }
        } catch {
            return false
        }
    }
    
    /// Get forms count
    /// - Returns: Total number of forms
    func getFormsCount() async throws -> Int {
        let forms = try await getAllForms()
        return forms.count
    }
}

// MARK: - Mock Repository for Testing
#if DEBUG
@available(iOS 13.0, macOS 10.15, *)
public final class MockFormRepository: FormRepository {
    
    private var forms: [DynamicForm] = []
    private var isInitialized = false
    
    public init(forms: [DynamicForm] = []) {
        self.forms = forms
    }
    
    public func getAllForms() async throws -> [DynamicForm] {
        return forms
    }
    
    public func getFormById(_ id: String) -> AnyPublisher<DynamicForm?, Error> {
        let form = forms.first { $0.id == id }
        return Just(form)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func insertForm(_ form: DynamicForm) async -> Result<Void, Error> {
        forms.append(form)
        return .success(())
    }
    
    public func updateForm(_ form: DynamicForm) async -> Result<Void, Error> {
        if let index = forms.firstIndex(where: { $0.id == form.id }) {
            forms[index] = form
            return .success(())
        } else {
            return .failure(FormRepositoryError.formNotFound(form.id))
        }
    }
    
    public func deleteForm(_ id: String) async -> Result<Void, Error> {
        if let index = forms.firstIndex(where: { $0.id == id }) {
            forms.remove(at: index)
            return .success(())
        } else {
            return .failure(FormRepositoryError.formNotFound(id))
        }
    }
    
    public func loadFormsFromAssets() async -> Result<[DynamicForm], Error> {
        // Mock implementation - return sample forms
        let sampleForms = createSampleForms()
        return .success(sampleForms)
    }
    
    public func clearAndReloadForms() async -> Result<[DynamicForm], Error> {
        // Mock implementation - clear and reload sample forms
        forms.removeAll()
        let sampleForms = createSampleForms()
        forms = sampleForms
        isInitialized = true
        return .success(sampleForms)
    }
    
    public func isFormsDataInitialized() async -> Bool {
        return isInitialized
    }
    
    public func searchForms(_ query: String) -> AnyPublisher<[DynamicForm], Error> {
        let filteredForms = forms.filter { form in
            form.title.localizedCaseInsensitiveContains(query)
        }
        return Just(filteredForms)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getFormsInDateRange(from startDate: Date, to endDate: Date) -> AnyPublisher<[DynamicForm], Error> {
        let filteredForms = forms.filter { form in
            form.createdAt >= startDate && form.createdAt <= endDate
        }
        return Just(filteredForms)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Test Helpers
    public func setInitialized(_ initialized: Bool) {
        isInitialized = initialized
    }
    
    public func addForm(_ form: DynamicForm) {
        forms.append(form)
    }
    
    public func clearForms() {
        forms.removeAll()
    }
    
    private func createSampleForms() -> [DynamicForm] {
        return [
            DynamicForm(
                id: "sample-form-1",
                title: "Sample Form 1",
                fields: [
                    FormField.textField(uuid: "field-1", name: "name", label: "Name", required: true),
                    FormField.numberField(uuid: "field-2", name: "age", label: "Age")
                ]
            ),
            DynamicForm(
                id: "sample-form-2",
                title: "Sample Form 2",
                fields: [
                    FormField.textField(uuid: "field-3", name: "email", label: "Email", required: true),
                    FormField.dropdownField(
                        uuid: "field-4",
                        name: "country",
                        label: "Country",
                        options: [
                            FieldOption(label: "USA", value: "us"),
                            FieldOption(label: "Canada", value: "ca")
                        ]
                    )
                ]
            )
        ]
    }
}
#endif