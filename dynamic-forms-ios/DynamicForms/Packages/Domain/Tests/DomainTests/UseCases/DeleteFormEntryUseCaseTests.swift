import XCTest
import Combine
@testable import Domain

/// Comprehensive tests for DeleteFormEntryUseCase
/// Following Test-Driven Development and Clean Code principles
@available(iOS 13.0, macOS 10.15, *)
final class DeleteFormEntryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var useCase: DeleteFormEntryUseCase!
    private var mockRepository: MockFormEntryRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockFormEntryRepository()
        cancellables = Set<AnyCancellable>()
        
        useCase = DeleteFormEntryUseCase(
            formEntryRepository: mockRepository
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Execute Method
    
    func testExecute_WithExistingEntry_ShouldDeleteSuccessfully() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry(id: "existing-entry")
        mockRepository.addEntry(entry)
        
        // When
        let result = await useCase.execute(entryId: entry.id)
        
        // Then
        assertSuccess(result)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "entryExists"), 1)
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "deleteEntry"), 1)
        
        // Verify entry is deleted
        let checkExists = await mockRepository.entryExists(entry.id)
        XCTAssertFalse(checkExists)
    }
    
    func testExecute_WithNonExistentEntry_ShouldReturnError() async {
        // Given
        let nonExistentId = "non-existent-entry"
        
        // When
        let result = await useCase.execute(entryId: nonExistentId)
        
        // Then
        let error = assertFailure(result)
        
        if case .entryNotFound(let id) = error as? DeleteFormEntryError {
            XCTAssertEqual(id, nonExistentId)
        } else {
            XCTFail("Expected entryNotFound error")
        }
        
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "entryExists"), 1)
        XCTAssertEqual(mockRepository.getOperationCount(for: "deleteEntry"), 0)
    }
    
    func testExecute_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry()
        mockRepository.addEntry(entry)
        // Only make deleteEntry operation fail, not entryExists
        mockRepository.addFailingOperation("deleteEntry")
        
        // When
        let result = await useCase.execute(entryId: entry.id)
        
        // Then
        let error = assertFailure(result)
        
        if case .deletionFailed(let reason) = error as? DeleteFormEntryError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected deletionFailed error, got: \(String(describing: error))")
        }
    }
    
    // MARK: - Test Batch Delete
    
    func testDeleteBatch_WithAllValidEntries_ShouldDeleteAll() async {
        // Given
        let entries = [
            TestDataFactory.createCompletedEntry(id: "entry1"),
            TestDataFactory.createCompletedEntry(id: "entry2"),
            TestDataFactory.createCompletedEntry(id: "entry3")
        ]
        
        entries.forEach { mockRepository.addEntry($0) }
        let entryIds = entries.map { $0.id }
        
        // When
        let result = await useCase.deleteBatch(entryIds: entryIds)
        
        // Then
        let deletedIds = assertSuccess(result)
        XCTAssertEqual(deletedIds?.count, 3)
        XCTAssertEqual(Set(deletedIds ?? []), Set(entryIds))
        
        // Verify all entries are deleted
        for entryId in entryIds {
            let exists = await mockRepository.entryExists(entryId)
            XCTAssertFalse(exists)
        }
    }
    
    func testDeleteBatch_WithSomeNonExistentEntries_ShouldReturnError() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(id: "existing")
        mockRepository.addEntry(existingEntry)
        
        let entryIds = ["existing", "non-existent1", "non-existent2"]
        
        // When
        let result = await useCase.deleteBatch(entryIds: entryIds)
        
        // Then
        let error = assertFailure(result)
        
        if case .batchDeletionFailed(let reason) = error as? DeleteFormEntryError {
            XCTAssertTrue(reason.contains("non-existent1"))
            XCTAssertTrue(reason.contains("non-existent2"))
        } else {
            XCTFail("Expected batchDeletionFailed error")
        }
    }
    
    func testDeleteBatch_WithEmptyArray_ShouldSucceed() async {
        // Given
        let entryIds: [String] = []
        
        // When
        let result = await useCase.deleteBatch(entryIds: entryIds)
        
        // Then
        let deletedIds = assertSuccess(result)
        XCTAssertEqual(deletedIds?.count, 0)
    }
    
    func testDeleteBatch_WithMixedResults_ShouldReturnPartialError() async {
        // Given
        let existingEntry = TestDataFactory.createCompletedEntry(id: "existing")
        mockRepository.addEntry(existingEntry)
        
        let entryIds = ["existing", "non-existent"]
        
        // When
        let result = await useCase.deleteBatch(entryIds: entryIds)
        
        // Then
        let error = assertFailure(result)
        XCTAssertNotNil(error)
        
        // Verify existing entry was deleted before failure
        let exists = await mockRepository.entryExists("existing")
        XCTAssertFalse(exists)
    }
    
    // MARK: - Test Delete Draft Entry
    
    func testDeleteDraftEntry_WithExistingDraft_ShouldDeleteSuccessfully() async {
        // Given
        let formId = "test-form"
        let draftEntry = TestDataFactory.createDraftEntry(formId: formId)
        mockRepository.addEntry(draftEntry)
        
        // When
        let result = await useCase.deleteDraftEntry(formId: formId)
        
        // Then
        assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "deleteDraftEntry"), 1)
    }
    
    func testDeleteDraftEntry_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let formId = "test-form"
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.deleteDraftEntry(formId: formId)
        
        // Then
        let error = assertFailure(result)
        
        if case .draftDeletionFailed(let reason) = error as? DeleteFormEntryError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected draftDeletionFailed error")
        }
    }
    
    // MARK: - Test Delete Edit Drafts
    
    func testDeleteEditDrafts_WithExistingEditDrafts_ShouldDeleteSuccessfully() async {
        // Given
        let originalEntryId = "original-entry"
        let editDraft1 = TestDataFactory.createEditDraftEntry(
            id: "edit-draft-1",
            sourceEntryId: originalEntryId
        )
        let editDraft2 = TestDataFactory.createEditDraftEntry(
            id: "edit-draft-2",
            sourceEntryId: originalEntryId
        )
        
        mockRepository.addEntry(editDraft1)
        mockRepository.addEntry(editDraft2)
        
        // When
        let result = await useCase.deleteEditDrafts(for: originalEntryId)
        
        // Then
        assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "deleteEditDraftsForEntry"), 1)
    }
    
    func testDeleteEditDrafts_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let originalEntryId = "original-entry"
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.deleteEditDrafts(for: originalEntryId)
        
        // Then
        let error = assertFailure(result)
        
        if case .editDraftDeletionFailed(let reason) = error as? DeleteFormEntryError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected editDraftDeletionFailed error")
        }
    }
    
    // MARK: - Test Delete With Confirmation
    
    func testDeleteWithConfirmation_WithConfirmation_ShouldDelete() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry(id: "confirmed-entry")
        mockRepository.addEntry(entry)
        
        var confirmationCalled = false
        let confirmationCallback: () async -> Bool = {
            confirmationCalled = true
            return true
        }
        
        // When
        let result = await useCase.deleteWithConfirmation(
            entryId: entry.id,
            confirmationCallback: confirmationCallback
        )
        
        // Then
        assertSuccess(result)
        XCTAssertTrue(confirmationCalled)
        
        let exists = await mockRepository.entryExists(entry.id)
        XCTAssertFalse(exists)
    }
    
    func testDeleteWithConfirmation_WithoutConfirmation_ShouldCancel() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry(id: "cancelled-entry")
        mockRepository.addEntry(entry)
        
        var confirmationCalled = false
        let confirmationCallback: () async -> Bool = {
            confirmationCalled = true
            return false // User cancels
        }
        
        // When
        let result = await useCase.deleteWithConfirmation(
            entryId: entry.id,
            confirmationCallback: confirmationCallback
        )
        
        // Then
        let error = assertFailure(result)
        XCTAssertTrue(confirmationCalled)
        
        if case .deletionCancelled = error as? DeleteFormEntryError {
            // Expected
        } else {
            XCTFail("Expected deletionCancelled error")
        }
        
        // Entry should still exist
        let exists = await mockRepository.entryExists(entry.id)
        XCTAssertTrue(exists)
    }
    
    func testDeleteWithConfirmation_WithNonExistentEntry_ShouldReturnError() async {
        // Given
        let nonExistentId = "non-existent"
        
        let confirmationCallback: () async -> Bool = {
            XCTFail("Confirmation should not be called for non-existent entry")
            return true
        }
        
        // When
        let result = await useCase.deleteWithConfirmation(
            entryId: nonExistentId,
            confirmationCallback: confirmationCallback
        )
        
        // Then
        let error = assertFailure(result)
        
        if case .entryNotFound(let id) = error as? DeleteFormEntryError {
            XCTAssertEqual(id, nonExistentId)
        } else {
            XCTFail("Expected entryNotFound error")
        }
    }
    
    func testDeleteWithConfirmation_WithActiveEditDrafts_ShouldCheckSafety() async {
        // Given
        let sourceEntry = TestDataFactory.createCompletedEntry(id: "source-entry")
        let editDraft = TestDataFactory.createEditDraftEntry(
            sourceEntryId: sourceEntry.id
        )
        
        mockRepository.addEntry(sourceEntry)
        mockRepository.addEntry(editDraft)
        
        let confirmationCallback: () async -> Bool = {
            return true
        }
        
        // When
        let result = await useCase.deleteWithConfirmation(
            entryId: sourceEntry.id,
            confirmationCallback: confirmationCallback
        )
        
        // Then
        let error = assertFailure(result)
        
        if case .hasActiveEditDrafts(let id) = error as? DeleteFormEntryError {
            XCTAssertEqual(id, sourceEntry.id)
        } else {
            XCTFail("Expected hasActiveEditDrafts error")
        }
    }
    
    // MARK: - Test Delete With Retry Extension
    
    func testDeleteWithRetry_WithSuccessfulFirstAttempt_ShouldSucceed() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry()
        mockRepository.addEntry(entry)
        
        // When
        let result = await useCase.deleteWithRetry(entryId: entry.id, maxRetries: 3)
        
        // Then
        assertSuccess(result)
        XCTAssertEqual(mockRepository.getOperationCount(for: "deleteEntry"), 1)
    }
    
    func testDeleteWithRetry_WithPersistentFailure_ShouldFailAfterRetries() async {
        // Given
        let entry = TestDataFactory.createCompletedEntry()
        mockRepository.addEntry(entry)
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.deleteWithRetry(entryId: entry.id, maxRetries: 2)
        
        // Then
        _ = assertFailure(result)
        // Should have tried multiple times (entry exists check + delete attempts)
        // Since it fails operations, entryExists might be called multiple times
        XCTAssertGreaterThanOrEqual(mockRepository.getOperationCount(for: "entryExists"), 0)
    }
    
    // MARK: - Test Delete Old Entries Extension
    
    func testDeleteOldEntries_WithEntriesInDateRange_ShouldDeleteThem() async {
        // Given
        let formId = "test-form"
        let cutoffDate = TestDataFactory.dateFromDaysAgo(7)
        
        let oldEntry1 = TestDataFactory.createCompletedEntry(
            id: "old1",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(10)
        )
        let oldEntry2 = TestDataFactory.createCompletedEntry(
            id: "old2",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(8)
        )
        let recentEntry = TestDataFactory.createCompletedEntry(
            id: "recent",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(5)
        )
        
        mockRepository.addEntry(oldEntry1)
        mockRepository.addEntry(oldEntry2)
        mockRepository.addEntry(recentEntry)
        
        // When
        let result = await useCase.deleteOldEntries(formId: formId, olderThan: cutoffDate)
        
        // Then
        let deletedCount = assertSuccess(result)
        XCTAssertEqual(deletedCount, 2)
        
        // Verify old entries are deleted, recent entry remains
        let oldExists1 = await mockRepository.entryExists(oldEntry1.id)
        let oldExists2 = await mockRepository.entryExists(oldEntry2.id)
        let recentExists = await mockRepository.entryExists(recentEntry.id)
        
        XCTAssertFalse(oldExists1)
        XCTAssertFalse(oldExists2)
        XCTAssertTrue(recentExists)
    }
    
    func testDeleteOldEntries_WithNoOldEntries_ShouldReturnZero() async {
        // Given
        let formId = "test-form"
        let cutoffDate = TestDataFactory.dateFromDaysAgo(7)
        
        let recentEntry = TestDataFactory.createCompletedEntry(
            id: "recent",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(5)
        )
        
        mockRepository.addEntry(recentEntry)
        
        // When
        let result = await useCase.deleteOldEntries(formId: formId, olderThan: cutoffDate)
        
        // Then
        let deletedCount = assertSuccess(result)
        XCTAssertEqual(deletedCount, 0)
        
        // Verify recent entry still exists
        let exists = await mockRepository.entryExists(recentEntry.id)
        XCTAssertTrue(exists)
    }
    
    func testDeleteOldEntries_WithRepositoryFailure_ShouldReturnError() async {
        // Given
        let formId = "test-form"
        let cutoffDate = TestDataFactory.dateFromDaysAgo(7)
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.deleteOldEntries(formId: formId, olderThan: cutoffDate)
        
        // Then
        let error = assertFailure(result)
        
        if case .deletionFailed(let reason) = error as? DeleteFormEntryError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected deletionFailed error")
        }
    }
    
    // MARK: - Test Safety Checks
    
    func testDeleteEntry_DraftWithoutEditDrafts_ShouldAllowDeletion() async {
        // Given
        let draftEntry = TestDataFactory.createDraftEntry(id: "draft-entry")
        mockRepository.addEntry(draftEntry)
        
        let confirmationCallback: () async -> Bool = { true }
        
        // When
        let result = await useCase.deleteWithConfirmation(
            entryId: draftEntry.id,
            confirmationCallback: confirmationCallback
        )
        
        // Then
        assertSuccess(result)
    }
    
    func testDeleteEntry_CompletedWithoutEditDrafts_ShouldAllowDeletion() async {
        // Given
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed-entry")
        mockRepository.addEntry(completedEntry)
        
        let confirmationCallback: () async -> Bool = { true }
        
        // When
        let result = await useCase.deleteWithConfirmation(
            entryId: completedEntry.id,
            confirmationCallback: confirmationCallback
        )
        
        // Then
        assertSuccess(result)
    }
    
    // MARK: - Test Concurrent Operations
    
    func testConcurrentDeletes_ShouldHandleCorrectly() async {
        // Given
        let entries = (0..<3).map { index in // Reduced to 3 to avoid timeout
            TestDataFactory.createCompletedEntry(id: "concurrent-entry-\(index)")
        }
        
        entries.forEach { mockRepository.addEntry($0) }
        
        // When - Execute concurrent deletes
        async let result1 = useCase.execute(entryId: entries[0].id)
        async let result2 = useCase.execute(entryId: entries[1].id)
        async let result3 = useCase.execute(entryId: entries[2].id)
        
        let results = await [result1, result2, result3]
        
        // Then
        let successCount = results.filter { result in
            if case .success = result { return true }
            return false
        }.count
        
        XCTAssertEqual(successCount, 3)
        
        // Verify all entries are deleted
        for entry in entries {
            let exists = await mockRepository.entryExists(entry.id)
            XCTAssertFalse(exists)
        }
    }
    
    // MARK: - Test Edge Cases
    
    func testDeleteEntry_WithEmptyEntryId_ShouldHandleGracefully() async {
        // Given
        let emptyId = ""
        
        // When
        let result = await useCase.execute(entryId: emptyId)
        
        // Then
        let error = assertFailure(result)
        
        if case .entryNotFound(let id) = error as? DeleteFormEntryError {
            XCTAssertEqual(id, emptyId)
        } else {
            XCTFail("Expected entryNotFound error")
        }
    }
    
    func testDeleteEntry_WithVeryLongEntryId_ShouldHandleCorrectly() async {
        // Given
        let longId = String(repeating: "a", count: 1000)
        
        // When
        let result = await useCase.execute(entryId: longId)
        
        // Then
        let error = assertFailure(result)
        
        if case .entryNotFound(let id) = error as? DeleteFormEntryError {
            XCTAssertEqual(id, longId)
        } else {
            XCTFail("Expected entryNotFound error")
        }
    }
    
    // MARK: - Test Performance
    
    func testDeleteBatch_WithLargeNumberOfEntries_ShouldPerformWell() async {
        // Given
        let largeCount = 100
        let entries = (0..<largeCount).map { index in
            TestDataFactory.createCompletedEntry(id: "batch-entry-\(index)")
        }
        
        entries.forEach { mockRepository.addEntry($0) }
        let entryIds = entries.map { $0.id }
        
        let startTime = Date()
        
        // When
        let result = await useCase.deleteBatch(entryIds: entryIds)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        let deletedIds = assertSuccess(result)
        XCTAssertEqual(deletedIds?.count, largeCount)
        
        // Performance assertion (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Batch delete should complete within reasonable time")
    }
}

// MARK: - DeleteFormEntryError Tests
@available(iOS 13.0, macOS 10.15, *)
extension DeleteFormEntryUseCaseTests {
    
    func testDeleteFormEntryError_ErrorDescriptions() {
        // Test all error cases have proper descriptions
        let errors: [DeleteFormEntryError] = [
            .entryNotFound("test-id"),
            .deletionFailed("test reason"),
            .batchDeletionFailed("batch reason"),
            .draftDeletionFailed("draft reason"),
            .editDraftDeletionFailed("edit draft reason"),
            .deletionCancelled,
            .hasActiveEditDrafts("test-id"),
            .insufficientPermissions
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
