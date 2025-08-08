import Foundation
import Combine
import Domain
import Utilities

/// ViewModel for form detail feature following MVVM pattern
/// Manages form filling, validation, and auto-save using Combine
@MainActor
public final class FormDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var uiState: FormDetailUiState = .loading
    @Published public private(set) var form: DynamicForm
    @Published public private(set) var entry: FormEntry
    @Published public private(set) var validationErrors: [String: String] = [:]
    @Published public private(set) var currentSectionIndex: Int = 0
    @Published public private(set) var isAutoSaving: Bool = false
    @Published public private(set) var lastSavedAt: Date?
    @Published public private(set) var canSubmitState: Bool = false
    @Published public var focusedFieldUuid: String? = nil
    
    // MARK: - Virtual Scrolling Properties (O(1) Performance)
    @Published public private(set) var virtualItems: [VirtualFormItem] = []
    @Published public private(set) var editContext: EditContext = .newEntry
    @Published public private(set) var successMessage: String?
    @Published public private(set) var fieldValues: [String: String] = [:]
    
    // MARK: - Thread-Safe Containers (Performance Optimization)
    private let fieldValuesContainer: ThreadSafeContainer<[String: String]>
    private let validationErrorsContainer: ThreadSafeContainer<[String: String]>
    private let virtualItemsCache: VirtualItemsCache
    
    // MARK: - Dependencies
    private let saveFormEntryUseCase: SaveFormEntryUseCase
    private let validateFormEntryUseCase: ValidateFormEntryUseCase
    private let autoSaveFormEntryUseCase: FormDetailAutoSaveUseCase
    private let logger: Logger
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let autoSaveDebouncer = Debouncer(delay: 2.0) // 2 seconds auto-save delay
    private var hasUnsavedChanges = false
    
    // MARK: - Computed Properties
    public var currentSection: FormSection? {
        guard currentSectionIndex >= 0 && currentSectionIndex < form.sections.count else {
            return nil
        }
        return form.sections[currentSectionIndex]
    }
    
    public var isFirstSection: Bool {
        return currentSectionIndex == 0
    }
    
    public var isLastSection: Bool {
        return currentSectionIndex == form.sections.count - 1
    }
    
    public var completionPercentage: Double {
        return entry.completionPercentage(for: form)
    }
    
    public var canSubmit: Bool {
        return canSubmitState
    }
    
    // MARK: - Initialization
    public init(
        form: DynamicForm,
        entry: FormEntry? = nil,
        saveFormEntryUseCase: SaveFormEntryUseCase,
        validateFormEntryUseCase: ValidateFormEntryUseCase,
        autoSaveFormEntryUseCase: FormDetailAutoSaveUseCase,
        logger: Logger = ConsoleLogger()
    ) {
        self.form = form
        self.entry = entry ?? FormEntry.newDraft(formId: form.id)
        self.saveFormEntryUseCase = saveFormEntryUseCase
        self.validateFormEntryUseCase = validateFormEntryUseCase
        self.autoSaveFormEntryUseCase = autoSaveFormEntryUseCase
        self.logger = logger
        
        // Initialize thread-safe containers
        self.fieldValuesContainer = ThreadSafeContainer([:])
        self.validationErrorsContainer = ThreadSafeContainer([:])
        self.virtualItemsCache = VirtualItemsCache(logger: logger)
        
        // Determine edit context
        self.editContext = determineEditContext(entry: self.entry)
        
        setupForm()
        setupAutoSave()
        generateVirtualItems() // O(1) Performance optimization
    }
    
    // MARK: - Public Methods
    
    /// Update field value with O(1) performance optimization and thread safety
    public func updateFieldValue(fieldUuid: String, value: String) {
        // Special debug for terms checkbox
        if let field = form.getFieldByUuid(fieldUuid), field.name == "terms" {
            logger.debug("🔄 TERMS UPDATE: uuid=\(fieldUuid), value='\(value)', type=\(field.type)")
        } else {
            logger.debug("Updating field \(fieldUuid) with value: \(value)")
        }
        
        // Thread-safe field values update (O(1) operation)
        fieldValuesContainer.mutate { fieldValuesDict in
            fieldValuesDict[fieldUuid] = value
        }
        fieldValues[fieldUuid] = value
        
        // Update entry
        entry = entry.updateFieldValue(fieldUuid: fieldUuid, value: value)
        
        // Update form with new value
        form = form.updateFieldValue(fieldUuid: fieldUuid, value: value)
        
        // Thread-safe validation errors update
        validationErrorsContainer.mutate { errorsDict in
            errorsDict.removeValue(forKey: fieldUuid)
        }
        validationErrors.removeValue(forKey: fieldUuid)
        
        // Mark as having unsaved changes
        hasUnsavedChanges = true
        
        // Update submit button state
        updateCanSubmitState()
        
        // Trigger auto-save
        triggerAutoSave()
        
        // Real-time validation for this field
        validateField(fieldUuid: fieldUuid, value: value)
        
        // Regenerate virtual items only when necessary (optimized)
        regenerateVirtualItemsIfNeeded()
    }
    
    /// Validate specific field in real-time
    public func validateField(fieldUuid: String, value: String, isPartial: Bool = false) {
        guard let field = form.getFieldByUuid(fieldUuid) else { return }
        
        let validationResult = validateFormEntryUseCase.validateFieldRealTime(
            field,
            value: value,
            isPartial: isPartial
        )
        
        if validationResult.isValid {
            validationErrors.removeValue(forKey: fieldUuid)
        } else if let errorMessage = validationResult.errorMessage {
            validationErrors[fieldUuid] = errorMessage
        }
        
        // Update submit button state after validation
        updateCanSubmitState()
    }
    
    /// Validate entire form
    public func validateForm() {
        logger.debug("Validating entire form")
        
        let errors = validateFormEntryUseCase.execute(form: form, entry: entry)
        
        validationErrors = Dictionary(uniqueKeysWithValues: errors.map { ($0.fieldUuid, $0.message) })
        
        logger.info("Form validation completed with \(errors.count) errors")
    }
    
    /// Save as draft
    public func saveDraft() {
        logger.debug("Saving draft...")
        uiState = .saving
        
        Task {
            let result = await saveFormEntryUseCase.saveDraft(entry)
            
            switch result {
            case .success(let entryId):
                entry = entry.copy(id: entryId)
                hasUnsavedChanges = false
                lastSavedAt = Date()
                await updateUIState(.loaded)
                logger.info("Draft saved successfully")
                
            case .failure(let error):
                logger.error("Failed to save draft: \(error.localizedDescription)")
                await updateUIState(.error(error.localizedDescription))
            }
        }
    }
    
        /// Submit form
    public func submitForm() {
        logger.debug("Submitting form...")

        // Validate before submit
        validateForm()
        
        if !validationErrors.isEmpty {
            logger.warning("Cannot submit form with validation errors: \(validationErrors)")
            logger.warning("Validation errors details:")
            for (fieldUuid, error) in validationErrors {
                if let field = form.getFieldByUuid(fieldUuid) {
                    let value = fieldValues[fieldUuid] ?? ""
                    logger.warning("  - Field '\(field.label)' (\(field.name)): '\(value)' -> \(error)")
                }
            }
            uiState = .error("Please fix all validation errors before submitting")
            return
        }
        
        uiState = .saving
        
        Task {
            let result = await saveFormEntryUseCase.submit(entry)
            
            switch result {
            case .success(let entryId):
                entry = entry.copy(id: entryId).markAsComplete()
                hasUnsavedChanges = false
                lastSavedAt = Date()
                await updateUIState(.submitted)
                logger.info("Form submitted successfully")
                
            case .failure(let error):
                logger.error("Failed to submit form: \(error.localizedDescription)")
                await updateUIState(.error(error.localizedDescription))
            }
        }
    }
    
    /// Navigate to next section
    public func nextSection() {
        guard currentSectionIndex < form.sections.count - 1 else { return }
        
        // Validate current section before moving
        if let section = currentSection {
            let sectionErrors = validateFormEntryUseCase.validateSection(
                form: form,
                entry: entry,
                section: section
            )
            
            if !sectionErrors.isEmpty {
                logger.warning("Cannot proceed to next section with validation errors")
                // Update validation errors for current section
                for error in sectionErrors {
                    validationErrors[error.fieldUuid] = error.message
                }
                return
            }
        }
        
        currentSectionIndex += 1
        logger.debug("Moved to section \(currentSectionIndex)")
    }
    
    /// Navigate to previous section
    public func previousSection() {
        guard currentSectionIndex > 0 else { return }
        currentSectionIndex -= 1
        logger.debug("Moved to section \(currentSectionIndex)")
    }
    
    /// Navigate to specific section
    public func goToSection(_ index: Int) {
        guard index >= 0 && index < form.sections.count else { return }
        currentSectionIndex = index
        logger.debug("Navigated to section \(index)")
    }
    
    /// Get next field UUID for navigation (includes prefetched fields within sections)
    public func getNextFieldUuid(after currentFieldUuid: String) -> String? {
        // Get all loaded field items (sections + prefetch within section bounds)
        let fieldItems = virtualItems.compactMap { item -> FormField? in
            if case .fieldItem(_, let field, _) = item {
                return field
            }
            return nil
        }
        
        // Find current field index
        guard let currentIndex = fieldItems.firstIndex(where: { $0.uuid == currentFieldUuid }) else {
            return nil
        }
        
        // Get next field that requires input
        for index in (currentIndex + 1)..<fieldItems.count {
            let field = fieldItems[index]
            if field.requiresInput {
                return field.uuid
            }
        }
        
        return nil
    }
    
    /// Get previous field UUID for navigation
    public func getPreviousFieldUuid(before currentFieldUuid: String) -> String? {
        // Get all loaded field items (sections + prefetch within section bounds)
        let fieldItems = virtualItems.compactMap { item -> FormField? in
            if case .fieldItem(_, let field, _) = item {
                return field
            }
            return nil
        }
        
        // Find current field index
        guard let currentIndex = fieldItems.firstIndex(where: { $0.uuid == currentFieldUuid }) else {
            return nil
        }
        
        // Get previous field that requires input
        for index in stride(from: currentIndex - 1, through: 0, by: -1) {
            let field = fieldItems[index]
            if field.requiresInput {
                return field.uuid
            }
        }
        
        return nil
    }
    
    /// Navigate to next field (for keyboard navigation)
    public func moveToNextField(from currentFieldUuid: String) {
        if let nextFieldUuid = getNextFieldUuid(after: currentFieldUuid) {
            focusedFieldUuid = nextFieldUuid
            logger.debug("Moved focus to next field: \(nextFieldUuid)")
        } else {
            // No next field, defocus current field
            focusedFieldUuid = nil
            logger.debug("Reached end of form, defocusing field")
        }
    }
    
    /// Navigate to previous field (for keyboard navigation)
    public func moveToPreviousField(from currentFieldUuid: String) {
        if let previousFieldUuid = getPreviousFieldUuid(before: currentFieldUuid) {
            focusedFieldUuid = previousFieldUuid
            logger.debug("Moved focus to previous field: \(previousFieldUuid)")
        } else {
            // No previous field, defocus current field
            focusedFieldUuid = nil
            logger.debug("Reached beginning of form, defocusing field")
        }
    }
    
    /// Load form (if needed)
    public func loadForm() {
        logger.debug("Loading form detail...")
        uiState = .loading
        
        // Apply existing entry values to form
        if entry.hasData {
            form = form.withFieldValues(from: entry)
        }
        
        uiState = .loaded
        logger.info("Form loaded successfully")
    }
    
    /// Clear error state and return to form without losing field values
    public func clearErrorAndReturnToForm() {
        logger.debug("Clearing error and returning to form...")
        uiState = .loaded
        logger.info("Returned to form with preserved field values")
    }
    
    /// Auto-save current state
    private func performAutoSave() {
        guard hasUnsavedChanges else { return }
        
        logger.debug("Performing auto-save...")
        isAutoSaving = true
        
        Task {
            let result = await autoSaveFormEntryUseCase.execute(entry: entry)
            
            await MainActor.run {
                isAutoSaving = false
                
                switch result {
                case .success:
                    hasUnsavedChanges = false
                    lastSavedAt = Date()
                    logger.debug("Auto-save completed")
                    
                case .failure(let error):
                    logger.error("Auto-save failed: \(error.localizedDescription)")
                    // Don't show error to user for auto-save failures
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupForm() {
        // Initialize field values from entry
        fieldValues = entry.fieldValues
        
        // Apply existing entry values to form if editing
        if entry.hasData {
            form = form.withFieldValues(from: entry)
        }
        
        // Initialize submit button state
        updateCanSubmitState()
        
        uiState = .loaded
    }
    
    /// Update the submit button enabled state based on required fields completion
    private func updateCanSubmitState() {
        // Get only required fields that are in the loaded sections
        let requiredFields = getLoadedRequiredFields()
        
        logger.debug("Updating submit state - Loaded required fields: \(requiredFields.count)")
        
        // Check if all required fields are filled
        var filledRequiredFields: [FormField] = []
        var emptyRequiredFields: [FormField] = []
        
        for field in requiredFields {
            let value = fieldValues[field.uuid] ?? ""
            logger.debug("Required field '\(field.label)' (\(field.name)) type=\(field.type): '\(value)' - isEmpty: \(value.isEmpty), isBlank: \(value.isBlank)")
            
            // Special debug for terms checkbox
            if field.name == "terms" {
                logger.debug("🔍 TERMS DEBUG: uuid=\(field.uuid), value='\(value)', required=\(field.required)")
                logger.debug("🔍 All fieldValues: \(fieldValues)")
            }
            
            if !value.isBlank {
                filledRequiredFields.append(field)
            } else {
                emptyRequiredFields.append(field)
            }
        }
        
        let allRequiredFieldsFilled = emptyRequiredFields.isEmpty
        
        // Check for validation errors only on filled required fields
        var fieldsWithErrors: [FormField] = []
        for field in filledRequiredFields {
            if validationErrors[field.uuid] != nil {
                fieldsWithErrors.append(field)
            }
        }
        
        let hasValidationErrorsOnRequiredFields = !fieldsWithErrors.isEmpty
        
        let newCanSubmitState = allRequiredFieldsFilled && !hasValidationErrorsOnRequiredFields
        
        logger.debug("Submit state: filled=\(filledRequiredFields.count)/\(requiredFields.count), errors=\(fieldsWithErrors.count), canSubmit=\(newCanSubmitState)")
        
        if !emptyRequiredFields.isEmpty {
            logger.debug("Empty required fields: \(emptyRequiredFields.map { $0.label }.joined(separator: ", "))")
        }
        
        canSubmitState = newCanSubmitState
    }
    
    /// Get required fields that are in the currently loaded sections
    private func getLoadedRequiredFields() -> [FormField] {
        var loadedRequiredFields: [FormField] = []
        
        // Get fields from all sections
        for section in form.sections {
            let sectionFields = form.getFieldsInSection(section)
            let requiredFieldsInSection = sectionFields.filter { $0.required }
            loadedRequiredFields.append(contentsOf: requiredFieldsInSection)
            
            logger.debug("Section '\(section.title)' (range \(section.from)-\(section.to)): \(requiredFieldsInSection.count) required fields")
        }
        
        logger.debug("Total loaded required fields: \(loadedRequiredFields.count)")
        return loadedRequiredFields
    }
    
    private func setupAutoSave() {
        // Auto-save timer - every 30 seconds if there are changes
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performAutoSave()
            }
            .store(in: &cancellables)
    }
    
    private func triggerAutoSave() {
        autoSaveDebouncer.debounce {
            Task { @MainActor in
                self.performAutoSave()
            }
        }
    }
    
    private func updateFormUIState() {
        if uiState.isLoaded {
            // Keep in loaded state but trigger UI updates
            objectWillChange.send()
        }
    }
    
    private func updateUIState(_ newState: FormDetailUiState) async {
        await MainActor.run {
            self.uiState = newState
        }
    }
    
    // MARK: - O(1) Performance Optimization Methods
    
    /// Generate virtual items for optimal scrolling performance with smart caching
    private func generateVirtualItems() {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("Generating virtual items for O(1) performance")
        
        // Create cache key
        let cacheKey = VirtualItemsCacheKey(
            formId: form.id,
            fieldValues: fieldValues,
            sectionIndex: currentSectionIndex,
            editContext: editContext,
            hasSuccessMessage: successMessage != nil,
            isAutoSaveEnabled: true
        )
        
        // Try to get from cache first (O(1) operation)
        if let cachedItems = virtualItemsCache.getCachedItems(for: cacheKey) {
            virtualItems = cachedItems
            logger.debug("Using cached virtual items (\(cachedItems.count) items)")
            return
        }
        
        // Generate new items if not in cache
        let newItems = VirtualFormItemGenerator.generateVirtualItems(
            form: form,
            editContext: editContext,
            successMessage: successMessage,
            isAutoSaveEnabled: true,
            lastAutoSaveTime: lastSavedAt,
            fieldValues: fieldValues
        )
        
        // Cache the generated items
        virtualItemsCache.cacheItems(newItems, for: cacheKey)
        virtualItems = newItems
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        logger.debug("Generated \(newItems.count) virtual items in \(String(format: "%.2fms", executionTime * 1000))")
        
        // Performance monitoring
        if executionTime > 0.016 { // 16ms threshold for 60fps
            logger.warning("Virtual items generation exceeded 16ms threshold: \(String(format: "%.2fms", executionTime * 1000))")
        }
    }
    
    /// Regenerate virtual items only when necessary (performance optimization)
    private func regenerateVirtualItemsIfNeeded() {
        // Only regenerate if we have significant changes that affect structure
        // For individual field updates, we don't need to regenerate the entire list
        
        // Check if we need to regenerate based on state changes
        let shouldRegenerate = shouldRegenerateVirtualItems()
        
        if shouldRegenerate {
            generateVirtualItems()
        }
    }
    
    /// Determine if virtual items need regeneration
    private func shouldRegenerateVirtualItems() -> Bool {
        // Only regenerate for structural changes, not field value changes
        // This keeps field updates at O(1) performance
        
        // Check if success message changed
        if virtualItems.contains(where: { 
            if case .successMessage = $0 { return true }
            return false
        }) != (successMessage != nil) {
            return true
        }
        
        // Check if auto-save status changed significantly
        if virtualItems.contains(where: {
            if case .autoSaveStatus = $0 { return true }
            return false
        }) != (lastSavedAt != nil) {
            return true
        }
        
        // For field value changes, we don't need to regenerate
        // The virtual items structure remains the same
        return false
    }
    
    /// Force regenerate virtual items (used for major state changes)
    public func forceRegenerateVirtualItems() {
        generateVirtualItems()
    }
    
    /// Determine edit context from entry
    private func determineEditContext(entry: FormEntry) -> EditContext {
        if entry.id.isEmpty {
            return .newEntry
        } else if entry.isDraft {
            return .editingDraft
        } else if entry.isComplete {
            return .editingSubmitted
        } else {
            return .newEntry
        }
    }
    
    /// Update success message and regenerate items if needed
    public func showSuccessMessage(_ message: String) {
        successMessage = message
        generateVirtualItems() // Regenerate because structure changes
        
        // Auto-hide success message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.successMessage == message {
                self.clearSuccessMessage()
            }
        }
    }
    
    /// Clear success message
    public func clearSuccessMessage() {
        successMessage = nil
        generateVirtualItems() // Regenerate because structure changes
    }
    
    /// Get virtual form metrics for debugging
    public func getVirtualFormMetrics() -> VirtualFormMetrics {
        return VirtualFormMetrics(items: virtualItems)
    }
    
    /// Get comprehensive performance metrics
    public func getPerformanceMetrics() -> FormDetailPerformanceMetrics {
        let cacheStats = virtualItemsCache.getCacheStats()
        let virtualMetrics = getVirtualFormMetrics()
        
        return FormDetailPerformanceMetrics(
            cacheStats: cacheStats,
            virtualMetrics: virtualMetrics,
            fieldCount: form.fields.count,
            sectionCount: form.sections.count,
            validationErrorCount: validationErrors.count,
            fieldValueCount: fieldValues.count,
            hasUnsavedChanges: hasUnsavedChanges
        )
    }
    
    /// Clear all caches for memory optimization
    public func clearCaches() {
        virtualItemsCache.clearCache()
        fieldValuesContainer.setValue([:])
        validationErrorsContainer.setValue([:])
        logger.info("All caches cleared for memory optimization")
    }
}

// MARK: - Performance Extensions
public extension FormDetailViewModel {
    
    /// Get field value by UUID (O(1) operation)
    func getFieldValue(fieldUuid: String) -> String {
        return fieldValues[fieldUuid] ?? ""
    }
    
    /// Check if field has validation error (O(1) operation)
    func hasValidationError(fieldUuid: String) -> Bool {
        return validationErrors[fieldUuid] != nil
    }
    
    /// Get validation error for field (O(1) operation)
    func getValidationError(fieldUuid: String) -> String? {
        return validationErrors[fieldUuid]
    }
    
    /// Batch update field values (optimized for multiple updates)
    func batchUpdateFieldValues(_ updates: [String: String]) {
        logger.debug("Batch updating \(updates.count) field values")
        
        for (fieldUuid, value) in updates {
            fieldValues[fieldUuid] = value
            entry = entry.updateFieldValue(fieldUuid: fieldUuid, value: value)
            form = form.updateFieldValue(fieldUuid: fieldUuid, value: value)
        }
        
        hasUnsavedChanges = true
        triggerAutoSave()
        
        // Only regenerate once after all updates
        regenerateVirtualItemsIfNeeded()
        
        logger.debug("Batch update completed")
    }
}

// MARK: - UI State
public enum FormDetailUiState: Equatable {
    case loading
    case loaded
    case saving
    case submitted
    case error(String)
    
    public static func == (lhs: FormDetailUiState, rhs: FormDetailUiState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        case (.saving, .saving):
            return true
        case (.submitted, .submitted):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - UI State Extensions
public extension FormDetailUiState {
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
    
    var isSaving: Bool {
        if case .saving = self {
            return true
        }
        return false
    }
    
    var isSubmitted: Bool {
        if case .submitted = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Use Case Protocols
public protocol FormDetailAutoSaveUseCase: AutoSaveFormEntryUseCaseProtocol {
}

// MARK: - FormEntry Extensions
private extension FormEntry {
    func copy(id: String) -> FormEntry {
        return FormEntry(
            id: id,
            formId: formId,
            sourceEntryId: sourceEntryId,
            fieldValues: fieldValues,
            createdAt: createdAt,
            updatedAt: Date(),
            isComplete: isComplete,
            isDraft: isDraft
        )
    }
}

// MARK: - Performance Metrics
public struct FormDetailPerformanceMetrics {
    public let cacheStats: VirtualItemsCacheStats
    public let virtualMetrics: VirtualFormMetrics
    public let fieldCount: Int
    public let sectionCount: Int
    public let validationErrorCount: Int
    public let fieldValueCount: Int
    public let hasUnsavedChanges: Bool
    
    public var debugDescription: String {
        return """
        FormDetail Performance Metrics:
        - Fields: \(fieldCount)
        - Sections: \(sectionCount)
        - Field Values: \(fieldValueCount)
        - Validation Errors: \(validationErrorCount)
        - Has Unsaved Changes: \(hasUnsavedChanges)
        
        \(cacheStats.debugDescription)
        
        \(virtualMetrics.debugDescription)
        """
    }
}

// MARK: - Debouncer for Auto-save
private class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}