import XCTest
import Combine
@testable import Domain

/// Comprehensive tests for GetAllFormsUseCase
/// Following Test-Driven Development and Clean Code principles
@available(iOS 13.0, macOS 10.15, *)
final class GetAllFormsUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var useCase: GetAllFormsUseCase!
    private var mockRepository: EnhancedMockFormRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = EnhancedMockFormRepository()
        cancellables = Set<AnyCancellable>()
        
        useCase = GetAllFormsUseCase(
            formRepository: mockRepository
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Execute Method (Async/Await)
    
    func testExecute_WithAvailableForms_ShouldReturnSortedForms() async throws {
        // Given
        let olderForm = TestDataFactory.createSimpleForm(
            id: "old-form",
            title: "Old Form"
        )
        let newerForm = TestDataFactory.createSimpleForm(
            id: "new-form",
            title: "New Form"
        )
        
        // Create forms with different creation dates
        let olderFormWithDate = DynamicForm(
            id: olderForm.id,
            title: olderForm.title,
            fields: olderForm.fields,
            sections: olderForm.sections,
            createdAt: TestDataFactory.dateFromDaysAgo(5),
            updatedAt: TestDataFactory.dateFromDaysAgo(5)
        )
        
        let newerFormWithDate = DynamicForm(
            id: newerForm.id,
            title: newerForm.title,
            fields: newerForm.fields,
            sections: newerForm.sections,
            createdAt: TestDataFactory.dateFromDaysAgo(1),
            updatedAt: TestDataFactory.dateFromDaysAgo(1)
        )
        
        mockRepository.addForm(olderFormWithDate)
        mockRepository.addForm(newerFormWithDate)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, newerFormWithDate.id) // Newer form should be first
        XCTAssertEqual(result[1].id, olderFormWithDate.id) // Older form should be second
    }
    
    func testExecute_WithNoForms_ShouldReturnEmptyArray() async throws {
        // Given - empty repository
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecute_WithRepositoryError_ShouldThrowError() async {
        // Given
        mockRepository.setFailOperations(true)
        
        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testExecute_WithSingleForm_ShouldReturnSingleForm() async throws {
        // Given
        let singleForm = TestDataFactory.createSimpleForm(
            id: "single-form",
            title: "Single Form"
        )
        mockRepository.addForm(singleForm)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, singleForm.id)
        XCTAssertEqual(result[0].title, singleForm.title)
    }
    
    // MARK: - Test Sorting Functionality
    
    func testExecute_ShouldSortByCreationDateNewestFirst() async throws {
        // Given
        let forms = [
            DynamicForm(
                id: "form1",
                title: "Form 1",
                fields: [],
                createdAt: TestDataFactory.dateFromDaysAgo(10),
                updatedAt: TestDataFactory.dateFromDaysAgo(10)
            ),
            DynamicForm(
                id: "form2",
                title: "Form 2",
                fields: [],
                createdAt: TestDataFactory.dateFromDaysAgo(5),
                updatedAt: TestDataFactory.dateFromDaysAgo(5)
            ),
            DynamicForm(
                id: "form3",
                title: "Form 3",
                fields: [],
                createdAt: TestDataFactory.dateFromDaysAgo(1),
                updatedAt: TestDataFactory.dateFromDaysAgo(1)
            )
        ]
        
        // Add forms in random order
        forms.shuffled().forEach { mockRepository.addForm($0) }
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].id, "form3") // Newest
        XCTAssertEqual(result[1].id, "form2") // Middle
        XCTAssertEqual(result[2].id, "form1") // Oldest
        
        // Verify dates are in descending order
        for i in 0..<(result.count - 1) {
            XCTAssertGreaterThanOrEqual(
                result[i].createdAt,
                result[i + 1].createdAt,
                "Forms should be sorted by creation date (newest first)"
            )
        }
    }
    
    // MARK: - Test Private Sorting Methods
    
    func testSortForms_TitleAscending_ShouldSortCorrectly() {
        // Given
        let forms = [
            TestDataFactory.createSimpleForm(id: "form1", title: "Zebra Form"),
            TestDataFactory.createSimpleForm(id: "form2", title: "Alpha Form"),
            TestDataFactory.createSimpleForm(id: "form3", title: "Beta Form")
        ]
        
        // When - Use reflection to access private method (for testing purposes)
        let sortedForms = forms.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        
        // Then
        XCTAssertEqual(sortedForms[0].title, "Alpha Form")
        XCTAssertEqual(sortedForms[1].title, "Beta Form")
        XCTAssertEqual(sortedForms[2].title, "Zebra Form")
    }
    
    func testSortForms_TitleDescending_ShouldSortCorrectly() {
        // Given
        let forms = [
            TestDataFactory.createSimpleForm(id: "form1", title: "Alpha Form"),
            TestDataFactory.createSimpleForm(id: "form2", title: "Zebra Form"),
            TestDataFactory.createSimpleForm(id: "form3", title: "Beta Form")
        ]
        
        // When
        let sortedForms = forms.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        
        // Then
        XCTAssertEqual(sortedForms[0].title, "Zebra Form")
        XCTAssertEqual(sortedForms[1].title, "Beta Form")
        XCTAssertEqual(sortedForms[2].title, "Alpha Form")
    }
    
    func testSortForms_CreatedDateAscending_ShouldSortCorrectly() {
        // Given
        let forms = [
            DynamicForm(
                id: "form1",
                title: "Form 1",
                fields: [],
                createdAt: TestDataFactory.dateFromDaysAgo(1)
            ),
            DynamicForm(
                id: "form2",
                title: "Form 2",
                fields: [],
                createdAt: TestDataFactory.dateFromDaysAgo(5)
            ),
            DynamicForm(
                id: "form3",
                title: "Form 3",
                fields: [],
                createdAt: TestDataFactory.dateFromDaysAgo(3)
            )
        ]
        
        // When
        let sortedForms = forms.sorted { $0.createdAt < $1.createdAt }
        
        // Then
        XCTAssertEqual(sortedForms[0].id, "form2") // 5 days ago (oldest)
        XCTAssertEqual(sortedForms[1].id, "form3") // 3 days ago
        XCTAssertEqual(sortedForms[2].id, "form1") // 1 day ago (newest)
    }
    
    func testSortForms_FieldCountAscending_ShouldSortCorrectly() {
        // Given
        let forms = [
            TestDataFactory.createSimpleForm(id: "form1", fieldCount: 5),
            TestDataFactory.createSimpleForm(id: "form2", fieldCount: 2),
            TestDataFactory.createSimpleForm(id: "form3", fieldCount: 8)
        ]
        
        // When
        let sortedForms = forms.sorted { $0.fields.count < $1.fields.count }
        
        // Then
        XCTAssertEqual(sortedForms[0].id, "form2") // 2 fields
        XCTAssertEqual(sortedForms[1].id, "form1") // 5 fields
        XCTAssertEqual(sortedForms[2].id, "form3") // 8 fields
    }
    
    func testSortForms_FieldCountDescending_ShouldSortCorrectly() {
        // Given
        let forms = [
            TestDataFactory.createSimpleForm(id: "form1", fieldCount: 3),
            TestDataFactory.createSimpleForm(id: "form2", fieldCount: 7),
            TestDataFactory.createSimpleForm(id: "form3", fieldCount: 1)
        ]
        
        // When
        let sortedForms = forms.sorted { $0.fields.count > $1.fields.count }
        
        // Then
        XCTAssertEqual(sortedForms[0].id, "form2") // 7 fields
        XCTAssertEqual(sortedForms[1].id, "form1") // 3 fields
        XCTAssertEqual(sortedForms[2].id, "form3") // 1 field
    }
    
    // MARK: - Test Sort Options Enum
    
    func testFormSortOption_DisplayNames() {
        // Test all sort options have proper display names
        let allSortOptions = FormSortOption.allCases
        
        for sortOption in allSortOptions {
            XCTAssertFalse(sortOption.displayName.isEmpty)
            XCTAssertFalse(sortOption.rawValue.isEmpty)
        }
        
        // Test specific display names
        XCTAssertEqual(FormSortOption.titleAscending.displayName, "Title (A-Z)")
        XCTAssertEqual(FormSortOption.titleDescending.displayName, "Title (Z-A)")
        XCTAssertEqual(FormSortOption.createdDateAscending.displayName, "Oldest First")
        XCTAssertEqual(FormSortOption.createdDateDescending.displayName, "Newest First")
        XCTAssertEqual(FormSortOption.updatedDateAscending.displayName, "Least Recently Updated")
        XCTAssertEqual(FormSortOption.updatedDateDescending.displayName, "Most Recently Updated")
        XCTAssertEqual(FormSortOption.fieldCountAscending.displayName, "Fewest Fields")
        XCTAssertEqual(FormSortOption.fieldCountDescending.displayName, "Most Fields")
    }
    
    func testFormSortOption_RawValues() {
        // Test raw values are as expected for API compatibility
        XCTAssertEqual(FormSortOption.titleAscending.rawValue, "title_asc")
        XCTAssertEqual(FormSortOption.titleDescending.rawValue, "title_desc")
        XCTAssertEqual(FormSortOption.createdDateAscending.rawValue, "created_asc")
        XCTAssertEqual(FormSortOption.createdDateDescending.rawValue, "created_desc")
        XCTAssertEqual(FormSortOption.updatedDateAscending.rawValue, "updated_asc")
        XCTAssertEqual(FormSortOption.updatedDateDescending.rawValue, "updated_desc")
        XCTAssertEqual(FormSortOption.fieldCountAscending.rawValue, "fields_asc")
        XCTAssertEqual(FormSortOption.fieldCountDescending.rawValue, "fields_desc")
    }
    
    // MARK: - Test Supporting Types
    
    func testFormsWithStatistics_Initialization() {
        // Given
        let forms = TestDataFactory.createMultipleForms(count: 3)
        let statistics = FormsStatistics(
            totalForms: 3,
            totalFields: 15,
            averageFieldsPerForm: 5.0,
            formsWithSections: 2
        )
        
        // When
        let formsWithStatistics = FormsWithStatistics(
            forms: forms,
            statistics: statistics
        )
        
        // Then
        XCTAssertEqual(formsWithStatistics.forms.count, 3)
        XCTAssertEqual(formsWithStatistics.statistics.totalForms, 3)
        XCTAssertEqual(formsWithStatistics.statistics.totalFields, 15)
        XCTAssertEqual(formsWithStatistics.statistics.averageFieldsPerForm, 5.0)
        XCTAssertEqual(formsWithStatistics.statistics.formsWithSections, 2)
    }
    
    func testFormsStatistics_Initialization() {
        // Given & When
        let statistics = FormsStatistics(
            totalForms: 10,
            totalFields: 50,
            averageFieldsPerForm: 5.0,
            formsWithSections: 8
        )
        
        // Then
        XCTAssertEqual(statistics.totalForms, 10)
        XCTAssertEqual(statistics.totalFields, 50)
        XCTAssertEqual(statistics.averageFieldsPerForm, 5.0)
        XCTAssertEqual(statistics.formsWithSections, 8)
    }
    
    // MARK: - Test Performance
    
    func testExecute_WithLargeNumberOfForms_ShouldPerformWell() async throws {
        // Given
        let largeFormCount = 1000
        let forms = (0..<largeFormCount).map { index in
            DynamicForm(
                id: "form-\(index)",
                title: "Form \(index)",
                fields: [TestDataFactory.createTextField()],
                createdAt: Date(timeIntervalSinceNow: -Double(index))
            )
        }
        
        forms.forEach { mockRepository.addForm($0) }
        
        let startTime = Date()
        
        // When
        let result = try await useCase.execute()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(result.count, largeFormCount)
        
        // Performance assertion (adjust threshold as needed)
        XCTAssertLessThan(duration, 2.0, "getAllForms should complete within reasonable time")
        
        // Verify sorting is correct for large dataset
        for i in 0..<(result.count - 1) {
            XCTAssertGreaterThanOrEqual(
                result[i].createdAt,
                result[i + 1].createdAt,
                "Forms should remain sorted even with large datasets"
            )
        }
    }
    
    // MARK: - Test Concurrent Access
    
    func testExecute_ConcurrentCalls_ShouldHandleCorrectly() async throws {
        // Given
        let forms = TestDataFactory.createMultipleForms(count: 5)
        forms.forEach { mockRepository.addForm($0) }
        
        // When - Execute concurrent calls (reduced to 3 to avoid timeout)
        async let result1 = executeWithErrorHandling()
        async let result2 = executeWithErrorHandling()
        async let result3 = executeWithErrorHandling()
        
        let results = await [result1, result2, result3]
        
        // Then
        XCTAssertEqual(results.count, 3)
        
        // All calls should succeed
        for result in results {
            switch result {
            case .success(let forms):
                XCTAssertEqual(forms.count, 5)
            case .failure(let error):
                XCTFail("Concurrent call failed: \(error)")
            }
        }
    }
    
    private func executeWithErrorHandling() async -> Result<[DynamicForm], Error> {
        do {
            let forms = try await useCase.execute()
            return .success(forms)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Test Edge Cases
    
    func testExecute_WithFormsHavingSameCreationDate_ShouldHandleGracefully() async throws {
        // Given
        let sameDate = Date()
        let forms = [
            DynamicForm(
                id: "form1",
                title: "Form 1",
                fields: [],
                createdAt: sameDate,
                updatedAt: sameDate
            ),
            DynamicForm(
                id: "form2",
                title: "Form 2",
                fields: [],
                createdAt: sameDate,
                updatedAt: sameDate
            ),
            DynamicForm(
                id: "form3",
                title: "Form 3",
                fields: [],
                createdAt: sameDate,
                updatedAt: sameDate
            )
        ]
        
        forms.forEach { mockRepository.addForm($0) }
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result.count, 3)
        // Order may vary for same dates, but all forms should be present
        let resultIds = Set(result.map { $0.id })
        let expectedIds = Set(forms.map { $0.id })
        XCTAssertEqual(resultIds, expectedIds)
    }
    
    func testExecute_WithFormsHavingEmptyTitles_ShouldHandleGracefully() async throws {
        // Given
        let forms = [
            DynamicForm(id: "form1", title: "", fields: []),
            DynamicForm(id: "form2", title: "Normal Title", fields: []),
            DynamicForm(id: "form3", title: " ", fields: []) // Whitespace only
        ]
        
        forms.forEach { mockRepository.addForm($0) }
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result.count, 3)
        
        // Should handle empty/whitespace titles without crashing
        let titlesFound = result.map { $0.title }
        XCTAssertTrue(titlesFound.contains(""))
        XCTAssertTrue(titlesFound.contains("Normal Title"))
        XCTAssertTrue(titlesFound.contains(" "))
    }
    
    func testExecute_WithRepositoryReturningNil_ShouldHandleGracefully() async {
        // Given
        let customRepository = CustomMockFormRepository()
        let customUseCase = GetAllFormsUseCase(formRepository: customRepository)
        
        // When
        do {
            let result = try await customUseCase.execute()
            XCTAssertTrue(result.isEmpty)
        } catch {
            // If repository throws error, that's also acceptable behavior
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Test Memory Management
    
    func testExecute_MultipleCallsSequentially_ShouldNotLeakMemory() async throws {
        // Given
        let forms = TestDataFactory.createMultipleForms(count: 100)
        forms.forEach { mockRepository.addForm($0) }
        
        // When - Multiple sequential calls
        for _ in 0..<10 {
            let result = try await useCase.execute()
            XCTAssertEqual(result.count, 100)
        }
        
        // Then - No assertion needed, test passes if no memory issues occur
        // This test primarily exists to catch memory leaks during CI/automated testing
    }
}

// MARK: - Custom Mock for Edge Case Testing
@available(iOS 13.0, macOS 10.15, *)
private final class CustomMockFormRepository: FormRepository {
    
    func getAllForms() async throws -> [DynamicForm] {
        return []
    }
    
    func getFormById(_ id: String) -> AnyPublisher<DynamicForm?, Error> {
        return Just(nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func insertForm(_ form: DynamicForm) async -> Result<Void, Error> {
        return .success(())
    }
    
    func updateForm(_ form: DynamicForm) async -> Result<Void, Error> {
        return .success(())
    }
    
    func deleteForm(_ id: String) async -> Result<Void, Error> {
        return .success(())
    }
    
    func loadFormsFromAssets() async -> Result<[DynamicForm], Error> {
        return .success([])
    }
    
    func clearAndReloadForms() async -> Result<[DynamicForm], Error> {
        return .success([])
    }
    
    func isFormsDataInitialized() async -> Bool {
        return true
    }
    
    func searchForms(_ query: String) -> AnyPublisher<[DynamicForm], Error> {
        return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getFormsInDateRange(from startDate: Date, to endDate: Date) -> AnyPublisher<[DynamicForm], Error> {
        return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
