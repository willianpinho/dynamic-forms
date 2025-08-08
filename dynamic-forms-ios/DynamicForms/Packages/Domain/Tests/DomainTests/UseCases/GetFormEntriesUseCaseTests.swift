import XCTest
import Combine
@testable import Domain

/// Comprehensive tests for GetFormEntriesUseCase
/// Following Test-Driven Development and Clean Code principles
@available(iOS 13.0, macOS 10.15, *)
final class GetFormEntriesUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var useCase: GetFormEntriesUseCase!
    private var mockRepository: MockFormEntryRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockFormEntryRepository()
        cancellables = Set<AnyCancellable>()
        
        useCase = GetFormEntriesUseCase(
            formEntryRepository: mockRepository
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Execute Method (Publisher)
    
    func testExecute_WithAvailableEntries_ShouldReturnSortedEntries() {
        // Given
        let formId = "test-form"
        let entries = [
            TestDataFactory.createCompletedEntry(
                id: "entry1",
                formId: formId,
                updatedAt: TestDataFactory.dateFromHoursAgo(5)
            ),
            TestDataFactory.createCompletedEntry(
                id: "entry2",
                formId: formId,
                updatedAt: TestDataFactory.dateFromHoursAgo(1) // More recent
            ),
            TestDataFactory.createCompletedEntry(
                id: "entry3",
                formId: formId,
                updatedAt: TestDataFactory.dateFromHoursAgo(3)
            )
        ]
        
        entries.forEach { mockRepository.addEntry($0) }
        
        let expectation = XCTestExpectation(description: "Should receive sorted entries")
        
        // When
        useCase.execute(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 3)
                    XCTAssertEqual(result[0].id, "entry2") // Most recent
                    XCTAssertEqual(result[1].id, "entry3") // Middle
                    XCTAssertEqual(result[2].id, "entry1") // Oldest
                    
                    // Verify dates are in descending order
                    for i in 0..<(result.count - 1) {
                        XCTAssertGreaterThanOrEqual(
                            result[i].updatedAt,
                            result[i + 1].updatedAt,
                            "Entries should be sorted by updated date (newest first)"
                        )
                    }
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testExecute_WithNoEntries_ShouldReturnEmptyArray() {
        // Given
        let formId = "empty-form"
        let expectation = XCTestExpectation(description: "Should receive empty array")
        
        // When
        useCase.execute(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.isEmpty)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testExecute_WithRepositoryError_ShouldPropagateError() {
        // Given
        let formId = "error-form"
        mockRepository.setFailOperations(true)
        
        let expectation = XCTestExpectation(description: "Should receive error")
        
        // When
        useCase.execute(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertNotNil(error)
                        expectation.fulfill()
                    }
                },
                receiveValue: { result in
                    XCTFail("Should not receive value when repository fails")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Execute Method (Async/Await)
    
    func testExecuteAsync_WithAvailableEntries_ShouldReturnSortedEntries() async throws {
        // Given
        let formId = "test-form-async"
        let entries = [
            TestDataFactory.createCompletedEntry(
                id: "async-entry1",
                formId: formId,
                updatedAt: TestDataFactory.dateFromHoursAgo(2)
            ),
            TestDataFactory.createCompletedEntry(
                id: "async-entry2",
                formId: formId,
                updatedAt: TestDataFactory.dateFromHoursAgo(1)
            )
        ]
        
        entries.forEach { mockRepository.addEntry($0) }
        
        // When
        let result = try await useCase.execute(formId: formId)
        
        // Then
        XCTAssertEqual(result.count, 2)
        // The results should be sorted by updated date (newest first)
        XCTAssertEqual(result[0].id, "async-entry2") // More recent (1 hour ago)
        XCTAssertEqual(result[1].id, "async-entry1") // Older (2 hours ago)
    }
    
    func testExecuteAsync_WithRepositoryError_ShouldThrowError() async {
        // Given
        let formId = "error-form-async"
        mockRepository.setFailOperations(true)
        
        // When & Then
        do {
            _ = try await useCase.execute(formId: formId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Test Execute With Filter
    
    func testExecuteWithFilter_WithStatusFilter_ShouldFilterCorrectly() {
        // Given
        let formId = "filtered-form"
        let draftEntry = TestDataFactory.createDraftEntry(id: "draft", formId: formId)
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed", formId: formId)
        let editDraftEntry = TestDataFactory.createEditDraftEntry(
            id: "edit-draft",
            formId: formId,
            sourceEntryId: "source"
        )
        
        mockRepository.addEntry(draftEntry)
        mockRepository.addEntry(completedEntry)
        mockRepository.addEntry(editDraftEntry)
        
        let filterOptions = EntryFilterOptions(status: .draft)
        let expectation = XCTestExpectation(description: "Should receive filtered entries")
        
        // When
        useCase.execute(formId: formId, filter: filterOptions)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "draft")
                    XCTAssertTrue(result[0].isDraft)
                    XCTAssertFalse(result[0].isEditDraft)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testExecuteWithFilter_WithDateRangeFilter_ShouldFilterCorrectly() {
        // Given
        let formId = "date-filtered-form"
        let oldEntry = TestDataFactory.createCompletedEntry(
            id: "old",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(10)
        )
        let recentEntry = TestDataFactory.createCompletedEntry(
            id: "recent",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(2)
        )
        
        mockRepository.addEntry(oldEntry)
        mockRepository.addEntry(recentEntry)
        
        let dateRange = DateRange(
            start: TestDataFactory.dateFromDaysAgo(5),
            end: Date()
        )
        let filterOptions = EntryFilterOptions(dateRange: dateRange)
        let expectation = XCTestExpectation(description: "Should receive date filtered entries")
        
        // When
        useCase.execute(formId: formId, filter: filterOptions)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "recent")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testExecuteWithFilter_WithSearchTextFilter_ShouldFilterCorrectly() {
        // Given
        let formId = "search-filtered-form"
        let entry1 = TestDataFactory.createCompletedEntry(
            id: "entry1",
            formId: formId,
            fieldValues: ["field1": "John Doe", "field2": "Engineer"]
        )
        let entry2 = TestDataFactory.createCompletedEntry(
            id: "entry2",
            formId: formId,
            fieldValues: ["field1": "Jane Smith", "field2": "Designer"]
        )
        
        mockRepository.addEntry(entry1)
        mockRepository.addEntry(entry2)
        
        let filterOptions = EntryFilterOptions(searchText: "John")
        let expectation = XCTestExpectation(description: "Should receive search filtered entries")
        
        // When
        useCase.execute(formId: formId, filter: filterOptions)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "entry1")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testExecuteWithFilter_WithSortOption_ShouldSortCorrectly() {
        // Given
        let formId = "sort-test-form"
        let entries = [
            TestDataFactory.createCompletedEntry(
                id: "entry1",
                formId: formId,
                createdAt: TestDataFactory.dateFromDaysAgo(1),
                updatedAt: TestDataFactory.dateFromHoursAgo(5)
            ),
            TestDataFactory.createCompletedEntry(
                id: "entry2",
                formId: formId,
                createdAt: TestDataFactory.dateFromDaysAgo(3),
                updatedAt: TestDataFactory.dateFromHoursAgo(1)
            )
        ]
        
        entries.forEach { mockRepository.addEntry($0) }
        
        let filterOptions = EntryFilterOptions(sortOption: .createdDateAscending)
        let expectation = XCTestExpectation(description: "Should receive sorted entries")
        
        // When
        useCase.execute(formId: formId, filter: filterOptions)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 2)
                    XCTAssertEqual(result[0].id, "entry2") // Created 3 days ago (older)
                    XCTAssertEqual(result[1].id, "entry1") // Created 1 day ago (newer)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Get Entries By Status
    
    func testGetEntriesByStatus_WithDraftFilter_ShouldReturnOnlyDrafts() {
        // Given
        let formId = "status-test-form"
        let draftEntry = TestDataFactory.createDraftEntry(id: "draft", formId: formId)
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed", formId: formId)
        
        mockRepository.addEntry(draftEntry)
        mockRepository.addEntry(completedEntry)
        
        let expectation = XCTestExpectation(description: "Should receive only draft entries")
        
        // When
        useCase.getEntriesByStatus(formId: formId, isDraft: true)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "draft")
                    XCTAssertTrue(result[0].isDraft)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetEntriesByStatus_WithCompletedFilter_ShouldReturnOnlyCompleted() {
        // Given
        let formId = "completed-test-form"
        let draftEntry = TestDataFactory.createDraftEntry(id: "draft", formId: formId)
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed", formId: formId)
        
        mockRepository.addEntry(draftEntry)
        mockRepository.addEntry(completedEntry)
        
        let expectation = XCTestExpectation(description: "Should receive only completed entries")
        
        // When
        useCase.getEntriesByStatus(formId: formId, isDraft: false, isComplete: true)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "completed")
                    XCTAssertTrue(result[0].isComplete)
                    XCTAssertFalse(result[0].isDraft)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Get Draft Entries
    
    func testGetDraftEntries_ShouldReturnOnlyDrafts() {
        // Given
        let formId = "draft-only-form"
        let draftEntry = TestDataFactory.createDraftEntry(id: "draft", formId: formId)
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed", formId: formId)
        
        mockRepository.addEntry(draftEntry)
        mockRepository.addEntry(completedEntry)
        
        let expectation = XCTestExpectation(description: "Should receive only draft entries")
        
        // When
        useCase.getDraftEntries(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "draft")
                    XCTAssertTrue(result[0].isDraft)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Get Completed Entries
    
    func testGetCompletedEntries_ShouldReturnOnlyCompleted() {
        // Given
        let formId = "completed-only-form"
        let draftEntry = TestDataFactory.createDraftEntry(id: "draft", formId: formId)
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed", formId: formId)
        
        mockRepository.addEntry(draftEntry)
        mockRepository.addEntry(completedEntry)
        
        let expectation = XCTestExpectation(description: "Should receive only completed entries")
        
        // When
        useCase.getCompletedEntries(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "completed")
                    XCTAssertTrue(result[0].isComplete)
                    XCTAssertFalse(result[0].isDraft)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Get Edit Drafts
    
    func testGetEditDrafts_ShouldReturnOnlyEditDrafts() {
        // Given
        let formId = "edit-draft-form"
        let normalDraft = TestDataFactory.createDraftEntry(id: "normal-draft", formId: formId)
        let editDraft = TestDataFactory.createEditDraftEntry(
            id: "edit-draft",
            formId: formId,
            sourceEntryId: "source"
        )
        let completedEntry = TestDataFactory.createCompletedEntry(id: "completed", formId: formId)
        
        mockRepository.addEntry(normalDraft)
        mockRepository.addEntry(editDraft)
        mockRepository.addEntry(completedEntry)
        
        let expectation = XCTestExpectation(description: "Should receive only edit draft entries")
        
        // When
        useCase.getEditDrafts(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "edit-draft")
                    XCTAssertTrue(result[0].isEditDraft)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Get Entries In Date Range
    
    func testGetEntriesInDateRange_ShouldFilterByDateRange() {
        // Given
        let formId = "date-range-form"
        let oldEntry = TestDataFactory.createCompletedEntry(
            id: "old",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(10)
        )
        let middleEntry = TestDataFactory.createCompletedEntry(
            id: "middle",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(3)
        )
        let recentEntry = TestDataFactory.createCompletedEntry(
            id: "recent",
            formId: formId,
            createdAt: TestDataFactory.dateFromDaysAgo(1)
        )
        
        mockRepository.addEntry(oldEntry)
        mockRepository.addEntry(middleEntry)
        mockRepository.addEntry(recentEntry)
        
        let startDate = TestDataFactory.dateFromDaysAgo(5)
        let endDate = Date()
        
        let expectation = XCTestExpectation(description: "Should receive entries in date range")
        
        // When
        useCase.getEntriesInDateRange(formId: formId, from: startDate, to: endDate)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 2)
                    let resultIds = Set(result.map { $0.id })
                    XCTAssertTrue(resultIds.contains("middle"))
                    XCTAssertTrue(resultIds.contains("recent"))
                    XCTAssertFalse(resultIds.contains("old"))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Get Entry Statistics Extension
    
    func testGetEntryStatistics_ShouldReturnCorrectCounts() {
        // Given
        let formId = "statistics-form"
        let normalDraft = TestDataFactory.createDraftEntry(
            id: "normal-draft",
            formId: formId,
            updatedAt: TestDataFactory.dateFromHoursAgo(1)
        )
        let editDraft = TestDataFactory.createEditDraftEntry(
            id: "edit-draft",
            formId: formId,
            sourceEntryId: "source",
            updatedAt: TestDataFactory.dateFromHoursAgo(2)
        )
        let completedEntry = TestDataFactory.createCompletedEntry(
            id: "completed",
            formId: formId,
            updatedAt: TestDataFactory.dateFromHoursAgo(3) // Oldest
        )
        
        mockRepository.addEntry(normalDraft)
        mockRepository.addEntry(editDraft)
        mockRepository.addEntry(completedEntry)
        
        let expectation = XCTestExpectation(description: "Should receive correct statistics")
        
        // When
        useCase.getEntryStatistics(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { statistics in
                    // Then
                    XCTAssertEqual(statistics.totalEntries, 3)
                    XCTAssertEqual(statistics.draftEntries, 1) // Only normal draft
                    XCTAssertEqual(statistics.editDraftEntries, 1)
                    XCTAssertEqual(statistics.completedEntries, 1)
                    
                    // Most recent should be normal draft
                    XCTAssertNotNil(statistics.lastUpdated)
                    self.assertDatesEqual(statistics.lastUpdated!, normalDraft.updatedAt)
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetEntryStatistics_WithNoEntries_ShouldReturnZeroCounts() {
        // Given
        let formId = "empty-statistics-form"
        let expectation = XCTestExpectation(description: "Should receive zero statistics")
        
        // When
        useCase.getEntryStatistics(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { statistics in
                    // Then
                    XCTAssertEqual(statistics.totalEntries, 0)
                    XCTAssertEqual(statistics.draftEntries, 0)
                    XCTAssertEqual(statistics.editDraftEntries, 0)
                    XCTAssertEqual(statistics.completedEntries, 0)
                    XCTAssertNil(statistics.lastUpdated)
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Filter Options
    
    func testEntryFilterOptions_DefaultValues() {
        // When
        let filterOptions = EntryFilterOptions()
        
        // Then
        XCTAssertNil(filterOptions.status)
        XCTAssertNil(filterOptions.dateRange)
        XCTAssertNil(filterOptions.searchText)
        XCTAssertEqual(filterOptions.sortOption, .updatedDateDescending)
    }
    
    func testEntryFilterOptions_CustomValues() {
        // Given
        let dateRange = DateRange(start: Date(), end: Date())
        
        // When
        let filterOptions = EntryFilterOptions(
            status: .completed,
            dateRange: dateRange,
            searchText: "test search",
            sortOption: .createdDateAscending
        )
        
        // Then
        XCTAssertEqual(filterOptions.status, .completed)
        XCTAssertNotNil(filterOptions.dateRange)
        XCTAssertEqual(filterOptions.searchText, "test search")
        XCTAssertEqual(filterOptions.sortOption, .createdDateAscending)
    }
    
    func testEntryStatusFilter_DisplayNames() {
        // Test all status filters have proper display names
        let allStatusFilters = EntryStatusFilter.allCases
        
        for statusFilter in allStatusFilters {
            XCTAssertFalse(statusFilter.displayName.isEmpty)
            XCTAssertFalse(statusFilter.rawValue.isEmpty)
        }
        
        // Test specific display names
        XCTAssertEqual(EntryStatusFilter.all.displayName, "All")
        XCTAssertEqual(EntryStatusFilter.draft.displayName, "Drafts")
        XCTAssertEqual(EntryStatusFilter.editDraft.displayName, "Edit Drafts")
        XCTAssertEqual(EntryStatusFilter.completed.displayName, "Completed")
    }
    
    func testEntrySortOption_DisplayNames() {
        // Test all sort options have proper display names
        let allSortOptions = EntrySortOption.allCases
        
        for sortOption in allSortOptions {
            XCTAssertFalse(sortOption.displayName.isEmpty)
            XCTAssertFalse(sortOption.rawValue.isEmpty)
        }
        
        // Test specific display names
        XCTAssertEqual(EntrySortOption.updatedDateDescending.displayName, "Recently Updated")
        XCTAssertEqual(EntrySortOption.updatedDateAscending.displayName, "Least Recently Updated")
        XCTAssertEqual(EntrySortOption.createdDateDescending.displayName, "Newest First")
        XCTAssertEqual(EntrySortOption.createdDateAscending.displayName, "Oldest First")
    }
    
    func testDateRange_Initialization() {
        // Given
        let startDate = TestDataFactory.dateFromDaysAgo(5)
        let endDate = Date()
        
        // When
        let dateRange = DateRange(start: startDate, end: endDate)
        
        // Then
        XCTAssertEqual(dateRange.start, startDate)
        XCTAssertEqual(dateRange.end, endDate)
    }
    
    // MARK: - Test Entry Statistics
    
    func testEntryStatistics_Initialization() {
        // Given
        let lastUpdated = Date()
        
        // When
        let statistics = EntryStatistics(
            totalEntries: 10,
            draftEntries: 3,
            editDraftEntries: 2,
            completedEntries: 5,
            lastUpdated: lastUpdated
        )
        
        // Then
        XCTAssertEqual(statistics.totalEntries, 10)
        XCTAssertEqual(statistics.draftEntries, 3)
        XCTAssertEqual(statistics.editDraftEntries, 2)
        XCTAssertEqual(statistics.completedEntries, 5)
        XCTAssertEqual(statistics.lastUpdated, lastUpdated)
    }
    
    // MARK: - Test Performance
    
    func testExecute_WithLargeNumberOfEntries_ShouldPerformWell() {
        // Given
        let formId = "performance-test-form"
        let largeEntryCount = 1000
        
        let entries = (0..<largeEntryCount).map { index in
            TestDataFactory.createCompletedEntry(
                id: "entry-\(index)",
                formId: formId,
                updatedAt: Date(timeIntervalSinceNow: -Double(index))
            )
        }
        
        entries.forEach { mockRepository.addEntry($0) }
        
        let expectation = XCTestExpectation(description: "Should handle large dataset efficiently")
        let startTime = Date()
        
        // When
        useCase.execute(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    
                    // Then
                    XCTAssertEqual(result.count, largeEntryCount)
                    
                    // Performance assertion (adjust threshold as needed)
                    XCTAssertLessThan(duration, 2.0, "getFormEntries should complete within reasonable time")
                    
                    // Verify sorting is correct for large dataset
                    for i in 0..<(result.count - 1) {
                        XCTAssertGreaterThanOrEqual(
                            result[i].updatedAt,
                            result[i + 1].updatedAt,
                            "Entries should remain sorted even with large datasets"
                        )
                    }
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Test Concurrent Operations
    
    func testExecute_ConcurrentCalls_ShouldHandleCorrectly() {
        // Given
        let formId = "concurrent-test-form"
        let entries = TestDataFactory.createMultipleEntries(formId: formId, count: 10)
        entries.forEach { mockRepository.addEntry($0) }
        
        let expectations = (0..<5).map { index in
            XCTestExpectation(description: "Concurrent call \(index) should complete")
        }
        
        // When - Execute multiple concurrent calls
        for (index, expectation) in expectations.enumerated() {
            useCase.execute(formId: formId)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            XCTFail("Concurrent call \(index) failed: \(error)")
                        }
                    },
                    receiveValue: { result in
                        XCTAssertEqual(result.count, 10)
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)
        }
        
        // Then
        wait(for: expectations, timeout: 2.0)
    }
    
    // MARK: - Test Edge Cases
    
    func testExecute_WithEntriesFromDifferentForms_ShouldFilterCorrectly() {
        // Given
        let targetFormId = "target-form"
        let otherFormId = "other-form"
        
        let targetEntry = TestDataFactory.createCompletedEntry(id: "target", formId: targetFormId)
        let otherEntry = TestDataFactory.createCompletedEntry(id: "other", formId: otherFormId)
        
        mockRepository.addEntry(targetEntry)
        mockRepository.addEntry(otherEntry)
        
        let expectation = XCTestExpectation(description: "Should filter by form ID")
        
        // When
        useCase.execute(formId: targetFormId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 1)
                    XCTAssertEqual(result[0].id, "target")
                    XCTAssertEqual(result[0].formId, targetFormId)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testExecute_WithEntriesHavingSameUpdatedDate_ShouldHandleGracefully() {
        // Given
        let formId = "same-date-form"
        let sameDate = Date()
        
        let entries = [
            TestDataFactory.createCompletedEntry(
                id: "entry1",
                formId: formId,
                updatedAt: sameDate
            ),
            TestDataFactory.createCompletedEntry(
                id: "entry2",
                formId: formId,
                updatedAt: sameDate
            ),
            TestDataFactory.createCompletedEntry(
                id: "entry3",
                formId: formId,
                updatedAt: sameDate
            )
        ]
        
        entries.forEach { mockRepository.addEntry($0) }
        
        let expectation = XCTestExpectation(description: "Should handle same updated dates")
        
        // When
        useCase.execute(formId: formId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.count, 3)
                    // Order may vary for same dates, but all entries should be present
                    let resultIds = Set(result.map { $0.id })
                    let expectedIds = Set(entries.map { $0.id })
                    XCTAssertEqual(resultIds, expectedIds)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
