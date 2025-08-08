import Foundation
import Combine
import Domain
import Utilities
import DataRepository

/// ViewModel for form list feature following MVVM pattern
/// Manages form list state and business logic using Combine
@MainActor
public final class FormListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var uiState: FormListUiState = .loading
    @Published public var searchText: String = ""
    @Published public var sortOption: FormSortOption = .titleAscending
    
    // MARK: - Dependencies
    private let getAllFormsUseCase: GetAllFormsUseCase
    private let initializeFormsUseCase: InitializeFormsUseCase
    private let formRepository: FormRepository
    private let logger: Logger
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var allForms: [DynamicForm] = []
    
    // MARK: - Initialization
    public init(
        getAllFormsUseCase: GetAllFormsUseCase,
        initializeFormsUseCase: InitializeFormsUseCase,
        formRepository: FormRepository,
        logger: Logger = ConsoleLogger()
    ) {
        self.getAllFormsUseCase = getAllFormsUseCase
        self.initializeFormsUseCase = initializeFormsUseCase
        self.formRepository = formRepository
        self.logger = logger
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Load forms data
    public func loadForms() {
        logger.debug("Loading forms...")
        uiState = .loading
        
        Task {
            do {
                logger.debug("Starting forms initialization...")
                // Initialize forms data if needed
                let initResult = await initializeFormsUseCase.execute()
                if case .failure(let error) = initResult {
                    logger.error("Failed to initialize forms: \(error.localizedDescription)")
                    await updateUIState(.error(error.localizedDescription))
                    return
                }
                
                logger.debug("Forms initialization completed successfully")
                
                // Get all forms
                logger.debug("Fetching all forms...")
                let forms = try await getAllFormsUseCase.execute()
                logger.debug("Retrieved \(forms.count) forms from repository")
                
                allForms = forms
                
                if forms.isEmpty {
                    logger.warning("No forms found after initialization")
                    await updateUIState(.empty)
                } else {
                    logger.info("Successfully loaded \(forms.count) forms")
                    // Apply current filtering and sorting
                    updateFilteredForms()
                }
                
            } catch {
                logger.error("Failed to load forms: \(error.localizedDescription)")
                await updateUIState(.error(error.localizedDescription))
            }
        }
    }
    
    /// Refresh forms data
    public func refreshForms() {
        logger.debug("Refreshing forms...")
        loadForms()
    }
    
    /// Retry loading forms after error
    public func retryLoading() {
        logger.debug("Retrying forms load...")
        loadForms()
    }
    
    /// Clear all forms and reload from assets (for debugging)
    @available(iOS 17.0, *)
    public func clearAndReloadForms() {
        logger.debug("Clearing and reloading forms...")
        uiState = .loading
        
        Task {
            // Check if repository supports clear and reload
            if let swiftDataRepo = formRepository as? FormRepositorySwiftData {
                let result = await swiftDataRepo.clearAndReloadForms()
                switch result {
                case .success(let forms):
                    logger.info("✅ Successfully cleared and reloaded \(forms.count) forms")
                    allForms = forms
                    updateFilteredForms()
                case .failure(let error):
                    logger.error("❌ Failed to clear and reload forms: \(error.localizedDescription)")
                    await updateUIState(.error(error.localizedDescription))
                }
            } else {
                // Fallback to regular load
                loadForms()
            }
        }
    }
    
    /// Select a form
    public func selectForm(_ form: DynamicForm) {
        logger.debug("Form selected: \(form.title)")
        // Navigation will be handled by the parent coordinator
    }
    
    /// Search forms
    public func searchForms() {
        updateFilteredForms()
    }
    
    /// Clear search
    public func clearSearch() {
        logger.debug("Clearing search text")
        searchText = ""
        // The binding will automatically trigger updateFilteredForms()
    }
    
    /// Update sort option
    public func updateSortOption(_ option: FormSortOption) {
        sortOption = option
        updateFilteredForms()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Search text binding with debouncing
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateFilteredForms()
            }
            .store(in: &cancellables)
        
        // Sort option binding - immediate response to changes
        $sortOption
            .dropFirst() // Skip initial value
            .removeDuplicates()
            .sink { [weak self] newSortOption in
                self?.logger.debug("Sort option changed to: \(newSortOption.displayName)")
                self?.updateFilteredForms()
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredForms() {
        logger.debug("Updating filtered forms. Total forms: \(allForms.count), Search text: '\(searchText)', Sort option: \(sortOption.displayName)")
        
        // Ensure we have forms to work with
        guard !allForms.isEmpty else {
            logger.debug("No forms available to filter")
            Task { @MainActor in
                self.uiState = .empty
            }
            return
        }
        
        var forms = allForms
        
        // Apply search filter
        if !searchText.isEmpty {
            let originalCount = forms.count
            forms = forms.filter { form in
                form.title.localizedCaseInsensitiveContains(searchText) ||
                form.fields.contains { field in
                    field.label.localizedCaseInsensitiveContains(searchText)
                }
            }
            logger.debug("Search filter applied. Filtered from \(originalCount) to \(forms.count) forms")
        }
        
        // Apply sorting
        let sortedForms = sortForms(forms)
        logger.debug("Final sorted forms count: \(sortedForms.count)")
        
        // Update UI state on main actor
        Task { @MainActor in
            if sortedForms.isEmpty && !self.allForms.isEmpty {
                self.uiState = .empty
                self.logger.debug("UI State set to .empty")
            } else if !sortedForms.isEmpty {
                self.uiState = .loaded(sortedForms)
                self.logger.debug("UI State set to .loaded with \(sortedForms.count) forms")
            } else {
                // Handle case where we have no forms at all
                self.uiState = .empty
                self.logger.debug("UI State set to .empty (no forms)")
            }
        }
    }
    
    private func sortForms(_ forms: [DynamicForm]) -> [DynamicForm] {
        logger.debug("Sorting \(forms.count) forms using option: \(sortOption.displayName)")
        
        let sortedForms: [DynamicForm]
        
        switch sortOption {
        case .titleAscending:
            sortedForms = forms.sorted { 
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending 
            }
        case .titleDescending:
            sortedForms = forms.sorted { 
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending 
            }
        case .createdDateAscending:
            sortedForms = forms.sorted { 
                logger.debug("Comparing created dates: '\($0.title)' (\($0.createdAt)) < '\($1.title)' (\($1.createdAt)) = \($0.createdAt < $1.createdAt)")
                return $0.createdAt < $1.createdAt 
            }
        case .createdDateDescending:
            sortedForms = forms.sorted { 
                logger.debug("Comparing created dates: '\($0.title)' (\($0.createdAt)) > '\($1.title)' (\($1.createdAt)) = \($0.createdAt > $1.createdAt)")
                return $0.createdAt > $1.createdAt 
            }
        case .updatedDateAscending:
            sortedForms = forms.sorted { 
                logger.debug("Comparing updated dates: '\($0.title)' (\($0.updatedAt)) < '\($1.title)' (\($1.updatedAt)) = \($0.updatedAt < $1.updatedAt)")
                return $0.updatedAt < $1.updatedAt 
            }
        case .updatedDateDescending:
            sortedForms = forms.sorted { 
                logger.debug("Comparing updated dates: '\($0.title)' (\($0.updatedAt)) > '\($1.title)' (\($1.updatedAt)) = \($0.updatedAt > $1.updatedAt)")
                return $0.updatedAt > $1.updatedAt 
            }
        case .fieldCountAscending:
            sortedForms = forms.sorted { 
                logger.debug("Comparing fields: '\($0.title)' (\($0.fields.count)) < '\($1.title)' (\($1.fields.count)) = \($0.fields.count < $1.fields.count)")
                return $0.fields.count < $1.fields.count 
            }
        case .fieldCountDescending:
            sortedForms = forms.sorted { 
                logger.debug("Comparing fields: '\($0.title)' (\($0.fields.count)) > '\($1.title)' (\($1.fields.count)) = \($0.fields.count > $1.fields.count)")
                return $0.fields.count > $1.fields.count 
            }
        }
        
        logger.debug("Sorted forms order: \(sortedForms.map { $0.title }.joined(separator: ", "))")
        return sortedForms
    }
    
    private func updateUIState(_ newState: FormListUiState) async {
        await MainActor.run {
            self.uiState = newState
        }
    }
}

// MARK: - UI State
public enum FormListUiState: Equatable {
    case loading
    case loaded([DynamicForm])
    case empty
    case error(String)
    
    public static func == (lhs: FormListUiState, rhs: FormListUiState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded(let lhsForms), .loaded(let rhsForms)):
            return lhsForms.map(\.id) == rhsForms.map(\.id)
        case (.empty, .empty):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - UI State Extensions
public extension FormListUiState {
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var forms: [DynamicForm] {
        if case .loaded(let forms) = self {
            return forms
        }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
    
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
}
