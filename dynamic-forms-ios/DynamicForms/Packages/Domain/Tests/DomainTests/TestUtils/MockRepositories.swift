import Foundation
import Combine
@preconcurrency @testable import Domain

// MARK: - Enhanced Mock Form Repository
@available(iOS 13.0, macOS 10.15, *)
public class EnhancedMockFormRepository: FormRepository, @unchecked Sendable {
    
    private var forms: [DynamicForm] = []
    private var isInitialized = false
    private var shouldFailOperations = false
    private var operationCounts: [String: Int] = [:]
    private let queue = DispatchQueue(label: "EnhancedMockFormRepository", attributes: .concurrent)
    
    public init(forms: [DynamicForm] = []) {
        self.forms = forms
    }
    
    // MARK: - Configuration Methods for Testing
    public func setFailOperations(_ shouldFail: Bool) {
        queue.async(flags: .barrier) {
            self.shouldFailOperations = shouldFail
        }
    }
    
    public func setInitialized(_ initialized: Bool) {
        queue.async(flags: .barrier) {
            self.isInitialized = initialized
        }
    }
    
    public func addForm(_ form: DynamicForm) {
        queue.sync(flags: .barrier) {
            self.forms.append(form)
        }
    }
    
    public func clearForms() {
        queue.sync(flags: .barrier) {
            self.forms.removeAll()
        }
    }
    
    public func getOperationCount(for operation: String) -> Int {
        return queue.sync {
            return operationCounts[operation] ?? 0
        }
    }
    
    private func incrementOperationCount(for operation: String) {
        queue.sync(flags: .barrier) {
            self.operationCounts[operation] = (self.operationCounts[operation] ?? 0) + 1
        }
    }
    
    private func checkShouldFail() throws {
        let shouldFail = queue.sync { shouldFailOperations }
        if shouldFail {
            throw FormRepositoryError.persistenceError("Mock failure")
        }
    }
    
    // MARK: - FormRepository Implementation
    
    public func getAllForms() async throws -> [DynamicForm] {
        incrementOperationCount(for: "getAllForms")
        try checkShouldFail()
        return queue.sync { forms }
    }
    
    public func getFormById(_ id: String) -> AnyPublisher<DynamicForm?, Error> {
        incrementOperationCount(for: "getFormById")
        
        let shouldFail = queue.sync { shouldFailOperations }
        if shouldFail {
            return Fail(error: FormRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let form = queue.sync { forms.first { $0.id == id } }
        return Just(form)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func insertForm(_ form: DynamicForm) async -> Result<Void, Error> {
        incrementOperationCount(for: "insertForm")
        
        do {
            try checkShouldFail()
            queue.sync(flags: .barrier) {
                self.forms.append(form)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    public func updateForm(_ form: DynamicForm) async -> Result<Void, Error> {
        incrementOperationCount(for: "updateForm")
        
        do {
            try checkShouldFail()
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    if let index = self.forms.firstIndex(where: { $0.id == form.id }) {
                        self.forms[index] = form
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(FormRepositoryError.formNotFound(form.id)))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func deleteForm(_ id: String) async -> Result<Void, Error> {
        incrementOperationCount(for: "deleteForm")
        
        do {
            try checkShouldFail()
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    if let index = self.forms.firstIndex(where: { $0.id == id }) {
                        self.forms.remove(at: index)
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(FormRepositoryError.formNotFound(id)))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func loadFormsFromAssets() async -> Result<[DynamicForm], Error> {
        incrementOperationCount(for: "loadFormsFromAssets")
        
        do {
            try checkShouldFail()
            let sampleForms = createSampleForms()
            return .success(sampleForms)
        } catch {
            return .failure(error)
        }
    }
    
    public func clearAndReloadForms() async -> Result<[DynamicForm], Error> {
        incrementOperationCount(for: "clearAndReloadForms")
        
        do {
            try checkShouldFail()
            let sampleForms = createSampleForms()
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    self.forms.removeAll()
                    self.forms = sampleForms
                    self.isInitialized = true
                    continuation.resume(returning: .success(sampleForms))
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func isFormsDataInitialized() async -> Bool {
        incrementOperationCount(for: "isFormsDataInitialized")
        return queue.sync { isInitialized }
    }
    
    public func searchForms(_ query: String) -> AnyPublisher<[DynamicForm], Error> {
        incrementOperationCount(for: "searchForms")
        
        let shouldFail = queue.sync { shouldFailOperations }
        if shouldFail {
            return Fail(error: FormRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let filteredForms = queue.sync { 
            forms.filter { form in
                form.title.localizedCaseInsensitiveContains(query)
            }
        }
        return Just(filteredForms)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getFormsInDateRange(from startDate: Date, to endDate: Date) -> AnyPublisher<[DynamicForm], Error> {
        incrementOperationCount(for: "getFormsInDateRange")
        
        let shouldFail = queue.sync { shouldFailOperations }
        if shouldFail {
            return Fail(error: FormRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let filteredForms = queue.sync { 
            forms.filter { form in
                form.createdAt >= startDate && form.createdAt <= endDate
            }
        }
        return Just(filteredForms)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func createSampleForms() -> [DynamicForm] {
        return [
            DynamicForm(
                id: "sample-form-1",
                title: "Sample Form 1",
                fields: []
            ),
            DynamicForm(
                id: "sample-form-2",
                title: "Sample Form 2",
                fields: []
            )
        ]
    }
}

// MARK: - Mock Form Entry Repository
@available(iOS 13.0, macOS 10.15, *)
public final class MockFormEntryRepository: FormEntryRepository, @unchecked Sendable {
    
    // MARK: - Properties
    private var entries: [FormEntry] = []
    private var shouldFailOperations = false
    private var specificFailingOperations: Set<String> = []
    private var delayDuration: TimeInterval = 0
    private var operationCounts: [String: Int] = [:]
    private let queue = DispatchQueue(label: "MockFormEntryRepository", attributes: .concurrent)
    
    // MARK: - Public API
    public init(entries: [FormEntry] = []) {
        self.entries = entries
    }
    
    // MARK: - Configuration Methods for Testing
    public func setFailOperations(_ shouldFail: Bool) {
        shouldFailOperations = shouldFail
    }
    
    public func setFailSpecificOperations(_ operations: Set<String>) {
        specificFailingOperations = operations
    }
    
    public func addFailingOperation(_ operation: String) {
        specificFailingOperations.insert(operation)
    }
    
    public func removeFailingOperation(_ operation: String) {
        specificFailingOperations.remove(operation)
    }
    
    public func clearFailingOperations() {
        specificFailingOperations.removeAll()
    }
    
    public func setOperationDelay(_ delay: TimeInterval) {
        delayDuration = delay
    }
    
    public func addEntry(_ entry: FormEntry) {
        queue.sync(flags: .barrier) {
            self.entries.append(entry)
        }
    }
    
    public func clearEntries() {
        queue.sync(flags: .barrier) {
            self.entries.removeAll()
        }
    }
    
    public func getOperationCount(for operation: String) -> Int {
        return queue.sync {
            return operationCounts[operation] ?? 0
        }
    }
    
    private func incrementOperationCount(for operation: String) {
        queue.sync(flags: .barrier) {
            self.operationCounts[operation] = (self.operationCounts[operation] ?? 0) + 1
        }
    }
    
    private func simulateDelay() async {
        if delayDuration > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
    }
    
    private func checkShouldFail() throws {
        if shouldFailOperations {
            throw FormEntryRepositoryError.persistenceError("Mock failure")
        }
    }
    
    private func checkShouldFailForOperation(_ operation: String) throws {
        if shouldFailOperations || specificFailingOperations.contains(operation) {
            throw FormEntryRepositoryError.persistenceError("Mock failure")
        }
    }
    
    // MARK: - FormEntryRepository Implementation
    
    public func insertEntry(_ entry: FormEntry) async -> Result<String, Error> {
        incrementOperationCount(for: "insertEntry")
        await simulateDelay()
        
        do {
            try checkShouldFail()
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    self.entries.append(entry)
                    continuation.resume(returning: .success(entry.id))
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func updateEntry(_ entry: FormEntry) async -> Result<Void, Error> {
        incrementOperationCount(for: "updateEntry")
        await simulateDelay()
        
        do {
            try checkShouldFail()
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                        self.entries[index] = entry
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(FormEntryRepositoryError.entryNotFound(entry.id)))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func deleteEntry(_ id: String) async -> Result<Void, Error> {
        incrementOperationCount(for: "deleteEntry")
        await simulateDelay()
        
        do {
            try checkShouldFailForOperation("deleteEntry")
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    if let index = self.entries.firstIndex(where: { $0.id == id }) {
                        self.entries.remove(at: index)
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(FormEntryRepositoryError.entryNotFound(id)))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func getEntryById(_ id: String) -> AnyPublisher<FormEntry?, Error> {
        incrementOperationCount(for: "getEntryById")
        incrementOperationCount(for: "entryExists") // Also count as entryExists since extension uses this
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let entry = queue.sync {
            return entries.first { $0.id == id }
        }
        return Just(entry)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getEntriesForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        incrementOperationCount(for: "getEntriesForForm")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let formEntries = entries.filter { $0.formId == formId }
        return Just(formEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // Override the protocol extension method explicitly
    public func entryExists(_ id: String) async -> Bool {
        incrementOperationCount(for: "entryExists")
        await simulateDelay()
        let exists = queue.sync {
            return entries.contains { $0.id == id }
        }
        return exists
    }
    
    public func saveEntryDraft(_ entry: FormEntry) async -> Result<Void, Error> {
        incrementOperationCount(for: "saveEntryDraft")
        await simulateDelay()
        
        do {
            try checkShouldFail()
            let draftEntry = entry.markAsDraft()
            return await withCheckedContinuation { continuation in
                queue.async(flags: .barrier) {
                    if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                        self.entries[index] = draftEntry
                    } else {
                        self.entries.append(draftEntry)
                    }
                    continuation.resume(returning: .success(()))
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func getEntriesByStatus(formId: String, isDraft: Bool?, isComplete: Bool?) -> AnyPublisher<[FormEntry], Error> {
        incrementOperationCount(for: "getEntriesByStatus")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        var filteredEntries = queue.sync {
            return entries.filter { $0.formId == formId }
        }
        
        if let isDraft = isDraft {
            filteredEntries = filteredEntries.filter { $0.isDraft == isDraft }
        }
        
        if let isComplete = isComplete {
            filteredEntries = filteredEntries.filter { $0.isComplete == isComplete }
        }
        
        return Just(filteredEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    

    
    public func deleteDraftEntry(_ formId: String) async -> Result<Void, Error> {
        incrementOperationCount(for: "deleteDraftEntry")
        await simulateDelay()
        
        do {
            try checkShouldFail()
            entries.removeAll { $0.formId == formId && $0.isDraft && !$0.isEditDraft }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    public func getEditDraftForEntry(_ entryId: String) -> AnyPublisher<FormEntry?, Error> {
        incrementOperationCount(for: "getEditDraftForEntry")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let editDraft = entries.first { $0.sourceEntryId == entryId && $0.isEditDraft }
        return Just(editDraft)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func deleteEditDraftsForEntry(_ entryId: String) async -> Result<Void, Error> {
        incrementOperationCount(for: "deleteEditDraftsForEntry")
        await simulateDelay()
        
        do {
            try checkShouldFail()
            entries.removeAll { $0.sourceEntryId == entryId && $0.isEditDraft }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    public func getAllDraftsForForm(_ formId: String) -> AnyPublisher<[FormEntry], Error> {
        incrementOperationCount(for: "getAllDraftsForForm")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let drafts = entries.filter { $0.formId == formId && $0.isDraft }
        return Just(drafts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getEntriesInDateRange(formId: String, from startDate: Date, to endDate: Date) -> AnyPublisher<[FormEntry], Error> {
        incrementOperationCount(for: "getEntriesInDateRange")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let filteredEntries = entries.filter { entry in
            entry.formId == formId &&
            entry.createdAt >= startDate &&
            entry.createdAt <= endDate
        }
        
        return Just(filteredEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getEntry(by id: String) async throws -> FormEntry? {
        incrementOperationCount(for: "getEntry")
        incrementOperationCount(for: "entryExists") // Also count as entryExists since extension uses this
        await simulateDelay()
        try checkShouldFail()
        
        let entry = queue.sync {
            return entries.first { $0.id == id }
        }
        return entry
    }
    
    public func getDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        incrementOperationCount(for: "getDraftEntry")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let draft = entries.first { $0.formId == formId && $0.isDraft && !$0.isEditDraft }
        return Just(draft)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getNewDraftEntry(_ formId: String) -> AnyPublisher<FormEntry?, Error> {
        incrementOperationCount(for: "getNewDraftEntry")
        
        if shouldFailOperations {
            return Fail(error: FormEntryRepositoryError.persistenceError("Mock failure"))
                .eraseToAnyPublisher()
        }
        
        let newDraft = entries.first { $0.formId == formId && $0.isDraft && $0.sourceEntryId == nil }
        return Just(newDraft)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}



// MARK: - Repository Error Extensions
public enum FormRepositoryError: Error, LocalizedError {
    case formNotFound(String)
    case persistenceError(String)
    case invalidData(String)
    case assetLoadingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .formNotFound(let id):
            return "Form with ID '\(id)' not found"
        case .persistenceError(let reason):
            return "Persistence error: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .assetLoadingFailed(let reason):
            return "Asset loading failed: \(reason)"
        }
    }
}

public enum FormEntryRepositoryError: Error, LocalizedError {
    case entryNotFound(String)
    case persistenceError(String)
    case invalidData(String)
    
    public var errorDescription: String? {
        switch self {
        case .entryNotFound(let id):
            return "Entry with ID '\(id)' not found"
        case .persistenceError(let reason):
            return "Persistence error: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }
}
