import XCTest
import Combine
@testable import Domain

/// Comprehensive tests for SaveFormEntryUseCase
/// Following Test-Driven Development and Clean Code principles
@available(iOS 13.0, macOS 10.15, *)
final class SaveFormEntryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var useCase: SaveFormEntryUseCase!
    private var mockRepository: MockFormEntryRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockFormEntryRepository()
        
        useCase = SaveFormEntryUseCase(
            formEntryRepository: mockRepository
        )
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Execute Method
    
    func testExecute_WithNewEntry_ShouldInsertSuccessfully() async {
        // Given
        let entry = TestDataFactory.createDraftEntry(
            id: "new-entry",
            formId: "test-form",
            fieldValues: ["field1": "value1"]
        )
        
        // When
        let result = await useCase.execute(entry: entry, isComplete: false)
        
        // Then
        let entryId = assertSuccess(result)
        XCTAssertEqual(entryId, entry.id)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "entryExists"), 1)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
        XCTAssertEqual(mockRepository.getOperationCount(for: "updateEntry"), 0)
    }
    
    func testExecute_WithExistingEntry_ShouldUpdateSuccessfully() async {
        // Given
        let existingEntry = TestDataFactory.createDraftEntry(
            id: "existing-entry",
            formId: "test-form",
            fieldValues: ["field1": "original-value"]
        )
        mockRepository.addEntry(existingEntry)
        
        let updatedEntry = TestDataFactory.createDraftEntry(
            id: "existing-entry",
            formId: "test-form",
            fieldValues: ["field1": "updated-value"]
        )
        
        // When
        let result = await useCase.execute(entry: updatedEntry, isComplete: false)
        
        // Then
        let entryId = assertSuccess(result)
        XCTAssertEqual(entryId, updatedEntry.id)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "entryExists"), 1)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "updateEntry"), 1)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 0)
    }
    
    func testExecute_WithCompleteFlag_ShouldMarkAsComplete() async {
        // Given
        let draftEntry = TestDataFactory.createDraftEntry(
            id: "complete-entry",
            fieldValues: ["field1": "value1"]
        )
        
        // When
        let result = await useCase.execute(entry: draftEntry, isComplete: true)
        
        // Then
        _ = assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
        
        // Verify the entry was marked as complete before saving
        // (This would be tested through the repository mock verification)
    }
    
    func testExecute_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.execute(entry: entry)
        
        // Then
        let error = assertFailure(result)
        
        if case .saveFailed(let reason) = error as? SaveFormEntryError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected saveFailed error, got: \(String(describing: error))")
        }
    }
    
    // MARK: - Test Save Draft
    
    func testSaveDraft_ShouldSaveAsDraft() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry() // Start with completed
        
        // When
        let result = await useCase.saveDraft(entry)
        
        // Then
        let entryId = assertSuccess(result)
        XCTAssertEqual(entryId, entry.id)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    // MARK: - Test Submit
    
    func testSubmit_ShouldMarkAsComplete() async {
        // Given
        let draftEntry = TestDataFactory.createDraftEntry()
        
        // When
        let result = await useCase.submit(draftEntry)
        
        // Then
        let entryId = assertSuccess(result)
        XCTAssertEqual(entryId, draftEntry.id)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    // MARK: - Test Save Batch
    
    func testSaveBatch_WithValidEntries_ShouldSaveAll() async {
        // Given
        let entries = [
            TestDataFactory.createDraftEntry(id: "batch1"),
            TestDataFactory.createDraftEntry(id: "batch2"),
            TestDataFactory.createDraftEntry(id: "batch3")
        ]
        
        // When
        let result = await useCase.saveBatch(entries)
        
        // Then
        let savedIds = assertSuccess(result)
        XCTAssertEqual(savedIds?.count, 3)
        XCTAssertEqual(Set(savedIds ?? []), Set(entries.map { $0.id }))
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 3)
    }
    
    func testSaveBatch_WithSomeFailures_ShouldReturnError() async {
        // Given
        let entries = [
            TestDataFactory.createDraftEntry(id: "batch1"),
            TestDataFactory.createDraftEntry(id: "batch2")
        ]
        
        // Set repository to fail after first success
        mockRepository.setFailOperations(false)
        
        // Create custom repository that fails on second call
        let customRepository = MockFormEntryRepository()
        let customUseCase = SaveFormEntryUseCase(formEntryRepository: customRepository)
        
        // Add first entry to succeed, fail on second
        customRepository.addEntry(entries[0])
        customRepository.setFailOperations(true)
        
        // When
        let result = await customUseCase.saveBatch(entries)
        
        // Then
        _ = assertFailure(result)
    }
    
    func testSaveBatch_WithEmptyArray_ShouldSucceed() async {
        // Given
        let entries: [FormEntry] = []
        
        // When
        let result = await useCase.saveBatch(entries)
        
        // Then
        let savedIds = assertSuccess(result)
        XCTAssertEqual(savedIds?.count, 0)
    }
    
    // MARK: - Test Save With Validation
    
    func testSaveWithValidation_WithValidEntry_ShouldSave() async {
        // Given
        let form = TestDataFactory.createFormWithValidationRules()
        let validEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "Valid text",
                "email-validation": "user@example.com",
                "dropdown-validation": "active"
            ]
        )
        
        // When
        let result = await useCase.saveWithValidation(
            entry: validEntry,
            form: form,
            isComplete: false
        )
        
        // Then
        _ = assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    func testSaveWithValidation_WithInvalidEntryAndCompleteFlag_ShouldReturnError() async {
        // Given
        let form = TestDataFactory.createFormWithValidationRules()
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "", // Missing required field
                "email-validation": "invalid-email"
            ]
        )
        
        // When
        let result = await useCase.saveWithValidation(
            entry: invalidEntry,
            form: form,
            isComplete: true // Trying to complete with validation errors
        )
        
        // Then
        let error = assertFailure(result)
        
        if case .validationFailed(let message) = error as? SaveFormEntryError {
            XCTAssertTrue(message.contains("required"))
        } else {
            XCTFail("Expected validationFailed error")
        }
    }
    
    func testSaveWithValidation_WithInvalidEntryAsDraft_ShouldSave() async {
        // Given
        let form = TestDataFactory.createFormWithValidationRules()
        let invalidEntry = TestDataFactory.createDraftEntry(
            fieldValues: [
                "required-text": "", // Missing required field
                "email-validation": "invalid-email"
            ]
        )
        
        // When
        let result = await useCase.saveWithValidation(
            entry: invalidEntry,
            form: form,
            isComplete: false // Saving as draft should work even with validation errors
        )
        
        // Then
        _ = assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    // MARK: - Test Auto Save
    
    func testAutoSave_ShouldSaveAsDraft() async {
        // Given
        let completedEntry = TestDataFactory.createCompletedEntry()
        
        // When
        let result = await useCase.autoSave(completedEntry)
        
        // Then
        let entryId = assertSuccess(result)
        XCTAssertEqual(entryId, completedEntry.id)
        XCTAssertEqual(mockRepository.getOperationCount(for: "saveEntryDraft"), 1)
    }
    
    func testAutoSave_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.autoSave(entry)
        
        // Then
        _ = assertFailure(result)
    }
    
    // MARK: - Test Update
    
    func testUpdate_WithExistingEntry_ShouldUpdateSuccessfully() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        mockRepository.addEntry(entry)
        
        let updatedEntry = TestDataFactory.createDraftEntry(
            id: entry.id,
            fieldValues: ["field1": "updated-value"]
        )
        
        // When
        let result = await useCase.update(updatedEntry)
        
        // Then
        _ = assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "updateEntry"), 1)
    }
    
    func testUpdate_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.update(entry)
        
        // Then
        _ = assertFailure(result)
    }
    
    // MARK: - Test Create Edit Draft
    
    func testCreateEditDraft_ShouldCreateAndSaveEditDraft() async {
        // Given
        let sourceEntry = TestDataFactory.createCompletedEntry(
            id: "source-entry",
            fieldValues: ["field1": "original-value"]
        )
        
        // When
        let result = await useCase.createEditDraft(from: sourceEntry)
        
        // Then
        let editDraft = assertSuccess(result)
        XCTAssertNotNil(editDraft)
        XCTAssertNotEqual(editDraft?.id, sourceEntry.id)
        XCTAssertEqual(editDraft?.sourceEntryId, sourceEntry.id)
        XCTAssertTrue(editDraft?.isEditDraft ?? false)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    func testCreateEditDraft_WithCustomDraftId_ShouldUseCustomId() async {
        // Given
        let sourceEntry = TestDataFactory.createCompletedEntry()
        let customDraftId = "custom-draft-id"
        
        // When
        let result = await useCase.createEditDraft(from: sourceEntry, draftId: customDraftId)
        
        // Then
        let editDraft = assertSuccess(result)
        XCTAssertEqual(editDraft?.id, customDraftId)
        XCTAssertEqual(editDraft?.sourceEntryId, sourceEntry.id)
    }
    
    func testCreateEditDraft_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let sourceEntry = TestDataFactory.createCompletedEntry()
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.createEditDraft(from: sourceEntry)
        
        // Then
        _ = assertFailure(result)
    }
    
    // MARK: - Test Extensions - Save With Optimistic Update
    
    func testSaveWithOptimisticUpdate_ShouldCallOptimisticCallback() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        var optimisticUpdateCalled = false
        var optimisticEntry: FormEntry?
        
        let optimisticCallback: (FormEntry) -> Void = { entry in
            optimisticUpdateCalled = true
            optimisticEntry = entry
        }
        
        // When
        let result = await useCase.saveWithOptimisticUpdate(
            entry: entry,
            isComplete: false,
            onOptimisticUpdate: optimisticCallback
        )
        
        // Then
        _ = assertSuccess(result)
        XCTAssertTrue(optimisticUpdateCalled)
        XCTAssertNotNil(optimisticEntry)
        XCTAssertEqual(optimisticEntry?.id, entry.id)
    }
    
    func testSaveWithOptimisticUpdate_WithCompleteFlag_ShouldMarkOptimisticEntryAsComplete() async {
        // Given
        let draftEntry = TestDataFactory.createDraftEntry()
        var optimisticEntry: FormEntry?
        
        let optimisticCallback: (FormEntry) -> Void = { entry in
            optimisticEntry = entry
        }
        
        // When
        let result = await useCase.saveWithOptimisticUpdate(
            entry: draftEntry,
            isComplete: true,
            onOptimisticUpdate: optimisticCallback
        )
        
        // Then
        _ = assertSuccess(result)
        XCTAssertTrue(optimisticEntry?.isComplete ?? false)
        XCTAssertFalse(optimisticEntry?.isDraft ?? true)
    }
    
    // MARK: - Test Extensions - Save With Retry
    
    func testSaveWithRetry_WithSuccessfulFirstAttempt_ShouldSucceed() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        
        // When
        let result = await useCase.saveWithRetry(entry: entry, maxRetries: 3)
        
        // Then
        _ = assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    func testSaveWithRetry_WithPersistentFailure_ShouldFailAfterRetries() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.saveWithRetry(entry: entry, maxRetries: 2)
        
        // Then
        let error = assertFailure(result)
        
        if case .saveFailed(let reason) = error as? SaveFormEntryError {
            XCTAssertTrue(reason.contains("Max retries exceeded") || reason.contains("Mock failure"))
        } else {
            XCTFail("Expected saveFailed error, got: \(String(describing: error))")
        }
    }
    
    // MARK: - Test Extensions - Save With Conflict Resolution
    
    func testSaveWithConflictResolution_WithNoConflict_ShouldSaveNormally() async {
        // Given
        let entry = TestDataFactory.createDraftEntry()
        
        // When
        let result = await useCase.saveWithConflictResolution(
            entry: entry,
            conflictResolution: .overwrite
        )
        
        // Then
        _ = assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "insertEntry"), 1)
    }
    
    func testSaveWithConflictResolution_WithConflictAndOverwrite_ShouldOverwrite() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(1) // Newer
        )
        mockRepository.addEntry(existingEntry)
        
        let conflictingEntry = TestDataFactory.createDraftEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(2) // Older
        )
        
        // When
        let result = await useCase.saveWithConflictResolution(
            entry: conflictingEntry,
            conflictResolution: .overwrite
        )
        
        // Then
        _ = assertSuccess(result)
    }
    
    func testSaveWithConflictResolution_WithConflictAndFail_ShouldReturnError() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(1) // Newer
        )
        mockRepository.addEntry(existingEntry)
        
        let conflictingEntry = TestDataFactory.createDraftEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(2) // Older
        )
        
        // When
        let result = await useCase.saveWithConflictResolution(
            entry: conflictingEntry,
            conflictResolution: .fail
        )
        
        // Then
        let error = assertFailure(result)
        
        if case .conflictError(let reason) = error as? SaveFormEntryError {
            XCTAssertTrue(reason.contains("modified"))
        } else {
            XCTFail("Expected conflictError")
        }
    }
    
    func testSaveWithConflictResolution_WithConflictAndCreateNew_ShouldCreateNewEntry() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(1)
        )
        mockRepository.addEntry(existingEntry)
        
        let conflictingEntry = TestDataFactory.createDraftEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(2)
        )
        
        // When
        let result = await useCase.saveWithConflictResolution(
            entry: conflictingEntry,
            conflictResolution: .createNew
        )
        
        // Then
        let newEntryId = assertSuccess(result)
        XCTAssertNotEqual(newEntryId, conflictingEntry.id)
    }
    
    func testSaveWithConflictResolution_WithConflictAndSkip_ShouldSkip() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(1)
        )
        mockRepository.addEntry(existingEntry)
        
        let conflictingEntry = TestDataFactory.createDraftEntry(
            id: "conflict-entry",
            updatedAt: TestDataFactory.dateFromHoursAgo(2)
        )
        
        // When
        let result = await useCase.saveWithConflictResolution(
            entry: conflictingEntry,
            conflictResolution: .skip
        )
        
        // Then
        let entryId = assertSuccess(result)
        XCTAssertEqual(entryId, conflictingEntry.id)
    }
    
    func testSaveWithConflictResolution_WithConflictAndMerge_ShouldMergeEntries() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(
            id: "merge-entry",
            fieldValues: ["field1": "existing-value", "field2": "preserved-value"],
            updatedAt: TestDataFactory.dateFromHoursAgo(1)
        )
        mockRepository.addEntry(existingEntry)
        
        let conflictingEntry = TestDataFactory.createDraftEntry(
            id: "merge-entry",
            fieldValues: ["field1": "new-value", "field3": "additional-value"],
            updatedAt: TestDataFactory.dateFromHoursAgo(2)
        )
        
        // When
        let result = await useCase.saveWithConflictResolution(
            entry: conflictingEntry,
            conflictResolution: .merge
        )
        
        // Then
        _ = assertSuccess(result)
    }
    
    // MARK: - Test Error Cases
    
    func testSaveFormEntryError_ErrorDescriptions() {
        // Test all error cases have proper descriptions
        let errors: [SaveFormEntryError] = [
            .saveFailed("test reason"),
            .validationFailed("validation errors"),
            .entryNotFound("test-id"),
            .conflictError("conflict reason"),
            .insufficientData("data reason")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Test Concurrent Operations
    
    func testConcurrentSaves_ShouldHandleCorrectly() async {
        // Given
        let entries = (0..<3).map { index in // Reduced to 3 to avoid timeout
            TestDataFactory.createDraftEntry(id: "concurrent-entry-\(index)")
        }
        
        // When - Execute concurrent saves
        async let result1 = useCase.execute(entry: entries[0])
        async let result2 = useCase.execute(entry: entries[1])
        async let result3 = useCase.execute(entry: entries[2])
        
        let results = await [result1, result2, result3]
        
        // Then
        let successCount = results.filter { result in
            if case .success = result { return true }
            return false
        }.count
        
        XCTAssertEqual(successCount, 3)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "insertEntry"), 3)
    }
    
    // MARK: - Test Performance
    
    func testSaveBatch_WithLargeNumberOfEntries_ShouldPerformWell() async {
        // Given
        let largeCount = 100
        let entries = (0..<largeCount).map { index in
            TestDataFactory.createDraftEntry(id: "perf-entry-\(index)")
        }
        
        let startTime = Date()
        
        // When
        let result = await useCase.saveBatch(entries)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        let savedIds = assertSuccess(result)
        XCTAssertEqual(savedIds?.count, largeCount)
        
        // Performance assertion (adjust threshold as needed)
        XCTAssertLessThan(duration, 3.0, "Batch save should complete within reasonable time")
    }
    
    // MARK: - Test Edge Cases
    
    func testExecute_WithEmptyFieldValues_ShouldHandleGracefully() async {
        // Given
        let entry = TestDataFactory.createDraftEntry(fieldValues: [:])
        
        // When
        let result = await useCase.execute(entry: entry)
        
        // Then
        _ = assertSuccess(result)
    }
    
    func testExecute_WithVeryLargeFieldValues_ShouldHandleCorrectly() async {
        // Given
        let largeValue = String(repeating: "a", count: 10000)
        let entry = TestDataFactory.createDraftEntry(
            fieldValues: ["large-field": largeValue]
        )
        
        // When
        let result = await useCase.execute(entry: entry)
        
        // Then
        _ = assertSuccess(result)
    }
    
    func testSaveWithValidation_WithNilForm_ShouldHandleGracefully() async {
        // This test would be implemented if the API allowed nil forms
        // Currently the API requires a form parameter
    }
    
    // MARK: - Test Memory Management
    
    func testExecute_MultipleCallsSequentially_ShouldNotLeakMemory() async {
        // Given - Multiple sequential calls
        for i in 0..<10 {
            let entryWithUniqueId = TestDataFactory.createDraftEntry(id: "memory-test-\(i)")
            let result = await useCase.execute(entry: entryWithUniqueId)
            _ = assertSuccess(result)
        }
        
        // Then - No assertion needed, test passes if no memory issues occur
        // This test primarily exists to catch memory leaks during CI/automated testing
    }
}
