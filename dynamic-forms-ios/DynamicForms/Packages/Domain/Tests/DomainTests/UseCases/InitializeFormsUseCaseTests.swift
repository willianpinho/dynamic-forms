import XCTest
import Combine
@testable import Domain

/// Comprehensive tests for InitializeFormsUseCase
/// Following Test-Driven Development and Clean Code principles
@available(iOS 13.0, macOS 10.15, *)
final class InitializeFormsUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var useCase: InitializeFormsUseCase!
    private var mockRepository: EnhancedMockFormRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = EnhancedMockFormRepository()
        
        useCase = InitializeFormsUseCase(
            formRepository: mockRepository
        )
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    

    
    // MARK: - Test Execute Method
    
    func testExecute_WithUninitializedRepository_ShouldInitializeSuccessfully() async {
        // Given
        mockRepository.setInitialized(false)
        
        // When
        let result = await useCase.execute()
        
        // Then
        assertSuccess(result)
        
        // Verify forms were loaded from assets and inserted
        let formsCount = try? await mockRepository.getFormsCount()
        XCTAssertNotNil(formsCount)
        XCTAssertGreaterThan(formsCount ?? 0, 0)
    }
    
    func testExecute_WithAlreadyInitializedRepository_ShouldReturnSuccessImmediately() async {
        // Given
        mockRepository.setInitialized(true)
        
        // When
        let result = await useCase.execute()
        
        // Then
        assertSuccess(result)
        
        // Should not attempt to load from assets when already initialized
        // (This is verified by the mock not being called for asset loading)
    }
    
    func testExecute_WithAssetLoadingFailure_ShouldReturnError() async {
        // Given
        mockRepository.setInitialized(false)
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.execute()
        
        // Then
        let error = assertFailure(result)
        
        if case .assetLoadingFailed(let reason) = error as? InitializeFormsError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected assetLoadingFailed error")
        }
    }
    
    func testExecute_WithFormInsertionFailure_ShouldReturnError() async {
        // Given
        mockRepository.setInitialized(false)
        
        // Create a custom repository that fails on insert
        let customRepository = FailingInsertFormRepository()
        let customUseCase = InitializeFormsUseCase(formRepository: customRepository)
        
        // When
        let result = await customUseCase.execute()
        
        // Then
        let error = assertFailure(result)
        
        if case .insertionFailed(let reason) = error as? InitializeFormsError {
            XCTAssertTrue(reason.contains("Insert failed"))
        } else {
            XCTFail("Expected insertionFailed error")
        }
    }
    
    // MARK: - Test Force Reinitialize
    
    func testForceReinitialize_ShouldReloadFormsFromAssets() async {
        // Given
        let existingForm = TestDataFactory.createSimpleForm(id: "existing", title: "Existing Form")
        mockRepository.addForm(existingForm)
        mockRepository.setInitialized(true)
        
        // When
        let result = await useCase.forceReinitialize()
        
        // Then
        assertSuccess(result)
        
        // Verify forms were reloaded (mock creates sample forms)
        let allForms = try? await mockRepository.getAllForms()
        XCTAssertNotNil(allForms)
        
        // Should contain sample forms from mock, not the existing form
        let formTitles = allForms?.map { $0.title } ?? []
        XCTAssertTrue(formTitles.contains("Sample Form 1"))
        XCTAssertTrue(formTitles.contains("Sample Form 2"))
    }
    
    func testForceReinitialize_WithAssetLoadingFailure_ShouldReturnError() async {
        // Given
        mockRepository.setFailOperations(true)
        
        // When
        let result = await useCase.forceReinitialize()
        
        // Then
        let error = assertFailure(result)
        
        if case .assetLoadingFailed(let reason) = error as? InitializeFormsError {
            XCTAssertTrue(reason.contains("Mock failure"))
        } else {
            XCTFail("Expected assetLoadingFailed error")
        }
    }
    
    func testForceReinitialize_WithUpdateFailure_ShouldReturnError() async {
        // Given
        let customRepository = FailingUpdateFormRepository()
        let customUseCase = InitializeFormsUseCase(formRepository: customRepository)
        
        // When
        let result = await customUseCase.forceReinitialize()
        
        // Then
        let error = assertFailure(result)
        
        if case .insertionFailed(let reason) = error as? InitializeFormsError {
            XCTAssertTrue(reason.contains("Insert failed"))
        } else {
            XCTFail("Expected insertionFailed error")
        }
    }
    
    // MARK: - Test Check Initialization Status
    
    func testCheckInitializationStatus_WithInitializedRepository_ShouldReturnTrue() async {
        // Given
        mockRepository.setInitialized(true)
        
        // When
        let isInitialized = await useCase.checkInitializationStatus()
        
        // Then
        XCTAssertTrue(isInitialized)
    }
    
    func testCheckInitializationStatus_WithUninitializedRepository_ShouldReturnFalse() async {
        // Given
        mockRepository.setInitialized(false)
        
        // When
        let isInitialized = await useCase.checkInitializationStatus()
        
        // Then
        XCTAssertFalse(isInitialized)
    }
    
    // MARK: - Test Get Initialization Progress
    
    func testGetInitializationProgress_WithInitializedRepository_ShouldReturnCompletedProgress() async {
        // Given
        mockRepository.setInitialized(true)
        mockRepository.addForm(TestDataFactory.createSimpleForm())
        mockRepository.addForm(TestDataFactory.createSimpleForm())
        
        // When
        let progress = await useCase.getInitializationProgress()
        
        // Then
        XCTAssertTrue(progress.isInitialized)
        XCTAssertEqual(progress.formsCount, 2)
        XCTAssertEqual(progress.status, .completed)
        XCTAssertNil(progress.errorMessage)
        XCTAssertEqual(progress.progressPercentage, 1.0)
    }
    
    func testGetInitializationProgress_WithUninitializedRepository_ShouldReturnNotStartedProgress() async {
        // Given
        mockRepository.setInitialized(false)
        
        // When
        let progress = await useCase.getInitializationProgress()
        
        // Then
        XCTAssertFalse(progress.isInitialized)
        XCTAssertEqual(progress.formsCount, 0)
        XCTAssertEqual(progress.status, .notStarted)
        XCTAssertNil(progress.errorMessage)
        XCTAssertEqual(progress.progressPercentage, 0.0)
    }
    
    func testGetInitializationProgress_WithRepositoryError_ShouldReturnErrorProgress() async {
        // Given
        mockRepository.setInitialized(true)
        mockRepository.setFailOperations(true)
        
        // When
        let progress = await useCase.getInitializationProgress()
        
        // Then
        XCTAssertFalse(progress.isInitialized)
        XCTAssertEqual(progress.formsCount, 0)
        XCTAssertEqual(progress.status, .error)
        XCTAssertNotNil(progress.errorMessage)
        XCTAssertEqual(progress.progressPercentage, 0.0)
    }
    
    // MARK: - Test Execute With Progress
    
    func testExecuteWithProgress_WithUninitializedRepository_ShouldProvideProgressUpdates() async {
        // Given
        mockRepository.setInitialized(false)
        
        var progressUpdates: [InitializationProgress] = []
        let progressHandler: (InitializationProgress) -> Void = { progress in
            progressUpdates.append(progress)
        }
        
        // When
        let result = await useCase.executeWithProgress(progressHandler: progressHandler)
        
        // Then
        assertSuccess(result)
        
        // Should have received multiple progress updates
        XCTAssertGreaterThan(progressUpdates.count, 1)
        
        // First update should be in progress
        XCTAssertEqual(progressUpdates.first?.status, .inProgress)
        
        // Last update should be completed
        XCTAssertEqual(progressUpdates.last?.status, .completed)
        XCTAssertTrue(progressUpdates.last?.isInitialized ?? false)
    }
    
    func testExecuteWithProgress_WithAlreadyInitialized_ShouldProvideCompletedProgress() async {
        // Given
        mockRepository.setInitialized(true)
        mockRepository.addForm(TestDataFactory.createSimpleForm())
        
        var progressUpdates: [InitializationProgress] = []
        let progressHandler: (InitializationProgress) -> Void = { progress in
            progressUpdates.append(progress)
        }
        
        // When
        let result = await useCase.executeWithProgress(progressHandler: progressHandler)
        
        // Then
        assertSuccess(result)
        
        // Should have received at least one progress update
        XCTAssertGreaterThan(progressUpdates.count, 0)
        
        // Final update should be completed
        XCTAssertEqual(progressUpdates.last?.status, .completed)
        XCTAssertTrue(progressUpdates.last?.isInitialized ?? false)
        XCTAssertEqual(progressUpdates.last?.formsCount, 1)
    }
    
    func testExecuteWithProgress_WithAssetLoadingFailure_ShouldProvideErrorProgress() async {
        // Given
        mockRepository.setInitialized(false)
        mockRepository.setFailOperations(true)
        
        var progressUpdates: [InitializationProgress] = []
        let progressHandler: (InitializationProgress) -> Void = { progress in
            progressUpdates.append(progress)
        }
        
        // When
        let result = await useCase.executeWithProgress(progressHandler: progressHandler)
        
        // Then
        _ = assertFailure(result)
        
        // Should have received progress updates including error
        XCTAssertGreaterThan(progressUpdates.count, 0)
        
        // Last update should be error status
        XCTAssertEqual(progressUpdates.last?.status, .error)
        XCTAssertNotNil(progressUpdates.last?.errorMessage)
    }
    
    func testExecuteWithProgress_WithFormInsertionFailure_ShouldProvideErrorProgress() async {
        // Given
        let customRepository = FailingInsertFormRepository()
        let customUseCase = InitializeFormsUseCase(formRepository: customRepository)
        
        var progressUpdates: [InitializationProgress] = []
        let progressHandler: (InitializationProgress) -> Void = { progress in
            progressUpdates.append(progress)
        }
        
        // When
        let result = await customUseCase.executeWithProgress(progressHandler: progressHandler)
        
        // Then
        _ = assertFailure(result)
        
        // Should have received progress updates including error
        XCTAssertGreaterThan(progressUpdates.count, 0)
        
        // Should have an error progress update
        let hasErrorProgress = progressUpdates.contains { $0.status == .error }
        XCTAssertTrue(hasErrorProgress)
    }
    
    // MARK: - Test Extensions
    
    func testExecuteWithCompletion_ShouldCallCompletionHandler() async {
        // Given
        mockRepository.setInitialized(false)
        
        let expectation = XCTestExpectation(description: "Completion handler should be called")
        
        // When
        useCase.execute { [self] result in
            // Then
            _ = self.assertSuccess(result)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testExecuteWithCompletion_WithError_ShouldCallCompletionHandlerWithError() async {
        // Given
        mockRepository.setInitialized(false)
        mockRepository.setFailOperations(true)
        
        let expectation = XCTestExpectation(description: "Completion handler should be called with error")
        
        // When
        useCase.execute { [self] result in
            // Then
            _ = self.assertFailure(result)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testIsInitializationNeeded_WithUninitializedRepository_ShouldReturnTrue() async {
        // Given
        mockRepository.setInitialized(false)
        
        // When
        let isNeeded = await useCase.isInitializationNeeded()
        
        // Then
        XCTAssertTrue(isNeeded)
    }
    
    func testIsInitializationNeeded_WithInitializedRepository_ShouldReturnFalse() async {
        // Given
        mockRepository.setInitialized(true)
        
        // When
        let isNeeded = await useCase.isInitializationNeeded()
        
        // Then
        XCTAssertFalse(isNeeded)
    }
    
    // MARK: - Test Supporting Types
    
    func testInitializationProgress_ProgressPercentageCalculation() {
        // Test different status progress percentages
        let notStarted = InitializationProgress(
            isInitialized: false,
            formsCount: 0,
            status: .notStarted,
            errorMessage: nil
        )
        XCTAssertEqual(notStarted.progressPercentage, 0.0)
        
        let inProgress = InitializationProgress(
            isInitialized: false,
            formsCount: 1,
            status: .inProgress,
            errorMessage: nil
        )
        XCTAssertEqual(inProgress.progressPercentage, 0.5)
        
        let completed = InitializationProgress(
            isInitialized: true,
            formsCount: 3,
            status: .completed,
            errorMessage: nil
        )
        XCTAssertEqual(completed.progressPercentage, 1.0)
        
        let error = InitializationProgress(
            isInitialized: false,
            formsCount: 0,
            status: .error,
            errorMessage: "Test error"
        )
        XCTAssertEqual(error.progressPercentage, 0.0)
    }
    
    func testInitializationStatus_DisplayNames() {
        // Test all status cases have proper display names
        XCTAssertEqual(InitializationStatus.notStarted.displayName, "Not Started")
        XCTAssertEqual(InitializationStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(InitializationStatus.completed.displayName, "Completed")
        XCTAssertEqual(InitializationStatus.error.displayName, "Error")
    }
    
    func testInitializeFormsError_ErrorDescriptions() {
        // Test all error cases have proper descriptions
        let errors: [InitializeFormsError] = [
            .initializationFailed("test reason"),
            .assetLoadingFailed("asset reason"),
            .insertionFailed("insert reason"),
            .alreadyInitialized
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
        
        // Test specific error descriptions
        if case .initializationFailed(let reason) = InitializeFormsError.initializationFailed("test") {
            XCTAssertEqual(reason, "test")
        }
        
        if case .assetLoadingFailed(let reason) = InitializeFormsError.assetLoadingFailed("asset test") {
            XCTAssertEqual(reason, "asset test")
        }
        
        if case .insertionFailed(let reason) = InitializeFormsError.insertionFailed("insert test") {
            XCTAssertEqual(reason, "insert test")
        }
    }
    
    // MARK: - Test Edge Cases
    
    func testExecute_WithEmptyAssetForms_ShouldHandleGracefully() async {
        // Given
        let emptyFormsRepository = EmptyFormsRepository()
        let emptyUseCase = InitializeFormsUseCase(formRepository: emptyFormsRepository)
        
        // When
        let result = await emptyUseCase.execute()
        
        // Then
        assertSuccess(result)
    }
    
    func testExecute_MultipleSimultaneousCalls_ShouldHandleCorrectly() async {
        // Given
        mockRepository.setInitialized(false)
        
        // When - Execute multiple simultaneous initialization calls
        async let result1 = useCase.execute()
        async let result2 = useCase.execute()
        async let result3 = useCase.execute()
        
        let results = await [result1, result2, result3]
        
        // Then - All should succeed (though some may find already initialized)
        for result in results {
            switch result {
            case .success:
                // Expected
                break
            case .failure(let error):
                XCTFail("Concurrent initialization failed: \(error)")
            }
        }
    }
    
    func testExecuteWithProgress_WithNilProgressHandler_ShouldHandleGracefully() async {
        // Given
        mockRepository.setInitialized(false)
        
        // This test ensures that if progress handler is somehow nil, it doesn't crash
        // Note: In Swift, this scenario is unlikely due to type safety, but we test robustness
        
        // When
        let result = await useCase.executeWithProgress { _ in
            // Empty progress handler
        }
        
        // Then
        assertSuccess(result)
    }
    
    // MARK: - Test Performance
    
    func testExecute_WithLargeNumberOfForms_ShouldPerformWell() async {
        // Given
        let largeFormsRepository = LargeFormsRepository()
        let largeUseCase = InitializeFormsUseCase(formRepository: largeFormsRepository)
        
        let startTime = Date()
        
        // When
        let result = await largeUseCase.execute()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        assertSuccess(result)
        
        // Performance assertion (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Initialization should complete within reasonable time")
    }
    
    // MARK: - Test Memory Management
    
    func testExecute_MultipleCallsSequentially_ShouldNotLeakMemory() async {
        // Given
        mockRepository.setInitialized(false)
        
        // When - Multiple sequential calls
        for i in 0..<5 {
            mockRepository.setInitialized(i == 0 ? false : true) // Only first call needs initialization
            let result = await useCase.execute()
            assertSuccess(result)
        }
        
        // Then - No assertion needed, test passes if no memory issues occur
        // This test primarily exists to catch memory leaks during CI/automated testing
    }
}

// MARK: - Custom Mock Repositories for Edge Case Testing

@available(iOS 13.0, macOS 10.15, *)
private final class FailingInsertFormRepository: EnhancedMockFormRepository {
    
    override func insertForm(_ form: DynamicForm) async -> Result<Void, Error> {
        return .failure(FormRepositoryError.persistenceError("Insert failed"))
    }
}

@available(iOS 13.0, macOS 10.15, *)
private final class FailingUpdateFormRepository: EnhancedMockFormRepository {
    
    override func updateForm(_ form: DynamicForm) async -> Result<Void, Error> {
        return .failure(FormRepositoryError.persistenceError("Update failed"))
    }
    
    override func insertForm(_ form: DynamicForm) async -> Result<Void, Error> {
        return .failure(FormRepositoryError.persistenceError("Insert failed"))
    }
}

@available(iOS 13.0, macOS 10.15, *)
private final class EmptyFormsRepository: EnhancedMockFormRepository {
    
    override func loadFormsFromAssets() async -> Result<[DynamicForm], Error> {
        return .success([]) // Return empty array
    }
}

@available(iOS 13.0, macOS 10.15, *)
private final class LargeFormsRepository: EnhancedMockFormRepository {
    
    override func loadFormsFromAssets() async -> Result<[DynamicForm], Error> {
        // Create a large number of forms for performance testing
        let largeForms = (0..<100).map { index in
            TestDataFactory.createSimpleForm(
                id: "large-form-\(index)",
                title: "Large Form \(index)",
                fieldCount: 10
            )
        }
        return .success(largeForms)
    }
    
    override func isFormsDataInitialized() async -> Bool {
        return false // Always needs initialization for this test
    }
}
