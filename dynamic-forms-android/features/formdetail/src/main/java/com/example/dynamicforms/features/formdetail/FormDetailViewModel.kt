package com.example.dynamicforms.features.formdetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.dynamicforms.core.utils.logging.AppLogger
import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.usecase.AutoSaveFormEntryUseCase
import com.example.dynamicforms.domain.usecase.GetEditDraftForEntryUseCase
import com.example.dynamicforms.domain.usecase.GetEntryByIdUseCase
import com.example.dynamicforms.domain.usecase.GetFormByIdUseCase
import com.example.dynamicforms.domain.usecase.GetNewDraftEntryUseCase
import com.example.dynamicforms.domain.usecase.SaveFormEntryUseCase
import com.example.dynamicforms.domain.usecase.ValidateFormEntryUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FormDetailViewModel @Inject constructor(
    private val getFormByIdUseCase: GetFormByIdUseCase,
    private val getNewDraftEntryUseCase: GetNewDraftEntryUseCase,
    private val getEditDraftForEntryUseCase: GetEditDraftForEntryUseCase,
    private val getEntryByIdUseCase: GetEntryByIdUseCase,
    private val saveFormEntryUseCase: SaveFormEntryUseCase,
    private val autoSaveFormEntryUseCase: AutoSaveFormEntryUseCase,
    private val validateFormEntryUseCase: ValidateFormEntryUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(FormDetailUiState())
    val uiState: StateFlow<FormDetailUiState> = _uiState.asStateFlow()

    private var autoSaveJob: Job? = null
    private var formId: String = ""
    private var entryId: String? = null
    private var draftId: String? = null
    private var isEditingExistingEntry: Boolean = false
    
    companion object {
        private const val AUTO_SAVE_DELAY_MS = 5000L // 5 seconds - increased for better performance
    }

    private fun initialize(formId: String, entryId: String? = null) {
        this.formId = formId
        this.entryId = entryId
        this.isEditingExistingEntry = entryId != null
        this.draftId = null // Reset draft ID on initialization
        
        // Update UI state to reflect editing mode
        _uiState.value = _uiState.value.copy(isEditingExistingEntry = isEditingExistingEntry)
        
        AppLogger.d("FormDetailViewModel", "Initializing with formId: $formId, entryId: $entryId, isEditingExistingEntry: $isEditingExistingEntry")
        
        loadForm()
        loadEntryIfExists()
    }

    fun onEvent(event: FormDetailEvent) {
        when (event) {
            FormDetailEvent.LoadForm -> loadForm()
            is FormDetailEvent.UpdateField -> updateField(event.fieldUuid, event.value)
            FormDetailEvent.SaveEntry -> saveEntry()
            FormDetailEvent.SaveDraft -> saveDraft()
            FormDetailEvent.DeleteEntry -> deleteEntry()
            FormDetailEvent.ClearError -> clearError()
            FormDetailEvent.ToggleAutoSave -> toggleAutoSave()
            FormDetailEvent.ValidateForm -> validateForm()
        }
    }

    private fun loadForm() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            
            try {
                getFormByIdUseCase(formId)
                    .take(1) // Only take the first emission to avoid repeated processing
                    .catch { e ->
                        AppLogger.e("FormDetailViewModel", "Error loading form: ${e.message}", e)
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            errorMessage = "Failed to load form: ${e.message}"
                        )
                    }
                    .collect { form ->
                        AppLogger.d("FormDetailViewModel", "Form loaded: ${form?.title}")
                        form?.let { loadedForm ->
                            AppLogger.d("FormDetailViewModel", "Form structure: ${loadedForm.sections.size} sections, ${loadedForm.fields.size} total fields")
                        }
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            form = form,
                            errorMessage = if (form == null) "Form not found" else null
                        )
                    }
            } catch (e: Exception) {
                AppLogger.e("FormDetailViewModel", "Error loading form", e)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Failed to load form: ${e.message}"
                )
            }
        }
    }

    private fun loadEntryIfExists() {
        viewModelScope.launch {
            try {
                if (entryId != null) {
                    // Load specific entry by ID (for existing submitted entries)
                    AppLogger.d("FormDetailViewModel", "Loading specific entry: $entryId")
                    getEntryByIdUseCase(entryId!!)
                        .catch { e ->
                            AppLogger.e("FormDetailViewModel", "Error loading specific entry: ${e.message}", e)
                        }
                        .take(1)
                        .collect { entry ->
                            entry?.let {
                                AppLogger.d("FormDetailViewModel", "Loaded entry by ID with ${it.fieldValues.size} field values")
                                AppLogger.d("FormDetailViewModel", "Entry field values: ${it.fieldValues}")
                                AppLogger.d("FormDetailViewModel", "Entry is draft: ${it.isDraft}, is complete: ${it.isComplete}")
                                
                                // Determine edit context based on entry type
                                val editContext = if (it.isDraft) {
                                    EditContext.EDITING_DRAFT
                                } else {
                                    EditContext.EDITING_SUBMITTED
                                }
                                
                                _uiState.value = _uiState.value.copy(
                                    entry = it,
                                    fieldValues = it.fieldValues,
                                    editContext = editContext
                                )
                                AppLogger.d("FormDetailViewModel", "Entry loaded into UI state with context: $editContext")
                            } ?: run {
                                AppLogger.w("FormDetailViewModel", "No entry found with ID: $entryId")
                            }
                        }
                } else {
                    // Load new draft for new entries (no specific entryId)
                    AppLogger.d("FormDetailViewModel", "Loading new draft entry for form: $formId")
                    getNewDraftEntryUseCase(formId)
                        .catch { e ->
                            AppLogger.e("FormDetailViewModel", "Error loading new draft entry: ${e.message}", e)
                        }
                        .take(1)
                        .collect { entry ->
                            entry?.let {
                                AppLogger.d("FormDetailViewModel", "New draft entry loaded with ${it.fieldValues.size} field values")
                                AppLogger.d("FormDetailViewModel", "New draft field values: ${it.fieldValues}")
                                
                                // Store draft ID separately - don't overwrite entryId when creating new forms
                                draftId = it.id
                                AppLogger.d("FormDetailViewModel", "Stored new draftId: ${it.id}")
                                
                                // Only load if we don't have field values yet (avoid overwriting user input)
                                if (_uiState.value.fieldValues.isEmpty()) {
                                    _uiState.value = _uiState.value.copy(
                                        entry = it,
                                        fieldValues = it.fieldValues,
                                        editContext = EditContext.EDITING_DRAFT
                                    )
                                    AppLogger.d("FormDetailViewModel", "New draft loaded into UI state")
                                } else {
                                    AppLogger.d("FormDetailViewModel", "Skipping new draft load - user already has input")
                                }
                            } ?: run {
                                AppLogger.d("FormDetailViewModel", "No new draft found for form: $formId")
                                // No draft found, so we're creating a new entry
                                _uiState.value = _uiState.value.copy(editContext = EditContext.NEW_ENTRY)
                            }
                        }
                }
                
                // Additionally, when editing an existing entry, check for edit drafts
                if (isEditingExistingEntry) {
                    entryId?.let { currentEntryId ->
                        AppLogger.d("FormDetailViewModel", "Checking for edit draft for entry: $currentEntryId")
                        getEditDraftForEntryUseCase(currentEntryId)
                            .catch { e ->
                                AppLogger.e("FormDetailViewModel", "Error loading edit draft: ${e.message}", e)
                            }
                            .take(1)
                            .collect { editDraft ->
                                editDraft?.let {
                                    AppLogger.d("FormDetailViewModel", "Edit draft found with ${it.fieldValues.size} field values")
                                    AppLogger.d("FormDetailViewModel", "Edit draft field values: ${it.fieldValues}")
                                    
                                    // Store edit draft ID
                                    draftId = it.id
                                    AppLogger.d("FormDetailViewModel", "Stored edit draftId: ${it.id}")
                                    
                                    // Load edit draft values if no current input
                                    if (_uiState.value.fieldValues.isEmpty()) {
                                        _uiState.value = _uiState.value.copy(
                                            entry = it,
                                            fieldValues = it.fieldValues,
                                            editContext = EditContext.EDITING_SUBMITTED // We know we're editing a submitted entry
                                        )
                                        AppLogger.d("FormDetailViewModel", "Edit draft loaded into UI state")
                                    }
                                } ?: run {
                                    AppLogger.d("FormDetailViewModel", "No edit draft found for entry: $currentEntryId")
                                }
                            }
                    }
                }
            } catch (e: Exception) {
                AppLogger.e("FormDetailViewModel", "Error loading entry", e)
            }
        }
    }

    private fun updateField(fieldUuid: String, value: String) {
        val currentValues = _uiState.value.fieldValues.toMutableMap()
        currentValues[fieldUuid] = value
        
        _uiState.value = _uiState.value.copy(
            fieldValues = currentValues,
            validationErrors = _uiState.value.validationErrors - fieldUuid // Clear validation error for this field
        )
        
        // Trigger auto-save if enabled
        if (_uiState.value.isAutoSaveEnabled) {
            scheduleAutoSave()
        }
        
        AppLogger.d("FormDetailViewModel", "Updated field $fieldUuid with value: $value")
    }

    private fun scheduleAutoSave() {
        val currentState = _uiState.value
        
        // Performance optimization: Only schedule save if form is loaded and has field values
        if (currentState.form == null || currentState.fieldValues.isEmpty()) {
            AppLogger.d("FormDetailViewModel", "Skipping auto-save: form not ready")
            return
        }
        
        // Cancel any pending auto-save to avoid multiple concurrent operations
        autoSaveJob?.cancel()
        
        AppLogger.d("FormDetailViewModel", "Scheduling auto-save in ${AUTO_SAVE_DELAY_MS}ms")
        
        autoSaveJob = viewModelScope.launch {
            try {
                delay(AUTO_SAVE_DELAY_MS)
                AppLogger.d("FormDetailViewModel", "Executing scheduled auto-save")
                saveDraft()
            } catch (e: Exception) {
                AppLogger.e("FormDetailViewModel", "Auto-save failed: ${e.message}", e)
            }
        }
    }

    private fun saveEntry() {
        val currentState = _uiState.value
        val form = currentState.form ?: return
        
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSaving = true, errorMessage = null)
            
            try {
                // Create a temporary entry for validation
                val tempEntry = FormEntry(
                    id = this@FormDetailViewModel.entryId ?: "temp",
                    formId = formId,
                    fieldValues = currentState.fieldValues
                )
                
                // Validate form first
                AppLogger.d("FormDetailViewModel", "Validating form with ${currentState.fieldValues.size} values: ${currentState.fieldValues}")
                AppLogger.d("FormDetailViewModel", "Form has ${form.fields.size} fields")
                
                // Log all form fields and their requirements
                form.fields.forEach { field ->
                    val value = currentState.fieldValues[field.uuid] ?: ""
                    AppLogger.d("FormDetailViewModel", "Field: ${field.label} (${field.uuid}) - Type: ${field.type} - Required: ${field.required} - Value: '$value'")
                }
                
                val validationErrors = validateFormEntryUseCase(form, tempEntry)
                
                AppLogger.d("FormDetailViewModel", "Validation completed. Found ${validationErrors.size} errors")
                validationErrors.forEach { error ->
                    AppLogger.d("FormDetailViewModel", "Validation error: ${error.fieldUuid} -> ${error.message}")
                }

                if (validationErrors.isNotEmpty()) {
                    AppLogger.w("FormDetailViewModel", "DEBUG MODE: Proceeding with ${validationErrors.size} validation errors")
                    val errorMap = validationErrors.associate { it.fieldUuid to it.message }
                    _uiState.value = _uiState.value.copy(validationErrors = errorMap)
                }
                
                // Create or update entry - use proper ID based on context
                val finalEntryId = when (currentState.editContext) {
                    EditContext.EDITING_SUBMITTED -> {
                        // When editing an existing submitted entry, preserve its ID
                        this@FormDetailViewModel.entryId ?: throw IllegalStateException("EntryId should not be null when editing existing submitted entry")
                    }
                    EditContext.EDITING_DRAFT -> {
                        // When converting a draft to submitted, use the draft's ID
                        draftId ?: currentState.entry?.id ?: throw IllegalStateException("DraftId should not be null when converting draft to submitted")
                    }
                    EditContext.NEW_ENTRY -> {
                        // When creating new submission, generate new ID
                        generateEntryId()
                    }
                }
                
                val entry = FormEntry(
                    id = finalEntryId,
                    formId = formId,
                    sourceEntryId = null, // Submitted entries don't have sourceEntryId
                    fieldValues = currentState.fieldValues,
                    isDraft = false,
                    isComplete = true,
                    createdAt = currentState.entry?.createdAt ?: System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis()
                )
                
                AppLogger.d("FormDetailViewModel", "About to save entry: isDraft=${entry.isDraft}, isComplete=${entry.isComplete}, ID=${entry.id}")
                AppLogger.d("FormDetailViewModel", "Current editContext: ${currentState.editContext}")
                
                val result = saveFormEntryUseCase(entry)

                if (result.isSuccess) {
                    AppLogger.d("FormDetailViewModel", "Entry saved successfully with ID: ${entry.id}")
                    AppLogger.d("FormDetailViewModel", "editContext: ${currentState.editContext}, originalEntryId: $entryId, draftId: $draftId")
                    
                    // If we converted a draft to submitted, update our internal state
                    if (currentState.editContext == EditContext.EDITING_DRAFT) {
                        // We've now converted the draft to a submitted entry
                        entryId = entry.id
                        isEditingExistingEntry = true
                        draftId = null // Clear draft ID since it's now submitted
                        AppLogger.d("FormDetailViewModel", "Converted draft to submitted entry. Updated entryId: $entryId")
                    }
                    
                    _uiState.value = _uiState.value.copy(
                        isSaving = false,
                        showSuccessMessage = true,
                        entry = entry,
                        editContext = EditContext.EDITING_SUBMITTED,
                        isEditingExistingEntry = true
                    )
                } else {
                    val error = result.exceptionOrNull()
                    AppLogger.e("FormDetailViewModel", "Error saving entry: ${error?.message}", error)
                    _uiState.value = _uiState.value.copy(
                        isSaving = false,
                        errorMessage = "Failed to save entry: ${error?.message}"
                    )
                }
            } catch (e: Exception) {
                AppLogger.e("FormDetailViewModel", "Error saving entry", e)
                _uiState.value = _uiState.value.copy(
                    isSaving = false,
                    errorMessage = "Failed to save entry: ${e.message}"
                )
            }
        }
    }

    private fun saveDraft() {
        val currentState = _uiState.value

        // Performance optimization: Skip save if data hasn't changed
        val existingEntry = currentState.entry
        if (existingEntry != null && existingEntry.fieldValues == currentState.fieldValues) {
            AppLogger.d("FormDetailViewModel", "Skipping draft save: no changes detected")
            return
        }
        
        // Skip save if already saving to prevent concurrent operations
        if (currentState.isSaving) {
            AppLogger.d("FormDetailViewModel", "Skipping draft save: already saving")
            return
        }
        
        AppLogger.d("FormDetailViewModel", "Saving draft with ${currentState.fieldValues.size} field values")
        AppLogger.d("FormDetailViewModel", "Field values: ${currentState.fieldValues}")
        
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSaving = true, errorMessage = null)
            
            try {
                // Determine draft ID and source entry ID based on context
                val finalDraftId = draftId ?: generateEntryId()
                val sourceEntryId = if (isEditingExistingEntry) this@FormDetailViewModel.entryId else null
                
                val entry = FormEntry(
                    id = finalDraftId,
                    formId = formId,
                    sourceEntryId = sourceEntryId,
                    fieldValues = currentState.fieldValues,
                    isDraft = true,
                    isComplete = false,
                    createdAt = currentState.entry?.createdAt ?: System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis()
                )
                
                AppLogger.d("FormDetailViewModel", "Attempting to save draft entry: $entry")
                
                val result = autoSaveFormEntryUseCase(entry)
                
                if (result.isSuccess) {
                    AppLogger.d("FormDetailViewModel", "Draft saved successfully")
                    _uiState.value = _uiState.value.copy(
                        isSaving = false,
                        lastAutoSaveTime = System.currentTimeMillis(),
                        lastAutosaveTime = System.currentTimeMillis(), // Fix compatibility
                        entry = entry,
                        successMessage = "Draft saved successfully"
                    )
                    
                    // Update draftId if this was a new draft (don't modify entryId for drafts)
                    if (draftId == null) {
                        draftId = entry.id
                        AppLogger.d("FormDetailViewModel", "Updated draftId to: ${entry.id}")
                    }
                } else {
                    val error = result.exceptionOrNull()
                    AppLogger.e("FormDetailViewModel", "Error saving draft: ${error?.message}", error)
                    _uiState.value = _uiState.value.copy(
                        isSaving = false,
                        errorMessage = "Failed to save draft: ${error?.message}"
                    )
                }
            } catch (e: Exception) {
                AppLogger.e("FormDetailViewModel", "Error saving draft", e)
                _uiState.value = _uiState.value.copy(
                    isSaving = false,
                    errorMessage = "Failed to save draft: ${e.message}"
                )
            }
        }
    }

    private fun deleteEntry() {
        // TODO: Implement delete functionality
        AppLogger.d("FormDetailViewModel", "Delete entry requested")
    }

    private fun validateForm() {
        val currentState = _uiState.value
        val form = currentState.form ?: return
        
        val tempEntry = FormEntry(
            id = this@FormDetailViewModel.entryId ?: "temp",
            formId = formId,
            fieldValues = currentState.fieldValues
        )
        
        val validationErrors = validateFormEntryUseCase(form, tempEntry)
        
        val errorMap = validationErrors.associate { it.fieldUuid to it.message }
        _uiState.value = _uiState.value.copy(validationErrors = errorMap)
        
        AppLogger.d("FormDetailViewModel", "Form validation completed. ${validationErrors.size} errors found")
    }

    private fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null, showSuccessMessage = false)
    }

    private fun toggleAutoSave() {
        val newState = !_uiState.value.isAutoSaveEnabled
        _uiState.value = _uiState.value.copy(isAutoSaveEnabled = newState)
        
        if (!newState) {
            autoSaveJob?.cancel()
        }
        
        AppLogger.d("FormDetailViewModel", "Auto-save toggled: $newState")
    }

    private fun generateEntryId(): String {
        return "entry_${formId}_${System.currentTimeMillis()}"
    }

    fun loadForm(formId: String, entryId: String? = null) {
        this.formId = formId
        this.entryId = entryId
        this.isEditingExistingEntry = entryId != null
        this.draftId = null // Reset draft ID when loading a different form
        
        // Update UI state to reflect editing mode
        _uiState.value = _uiState.value.copy(isEditingExistingEntry = isEditingExistingEntry)
        
        initialize(formId, entryId)
    }
    
    fun updateFieldValue(fieldId: String, value: String) {
        updateField(fieldId, value)
    }
    
    fun saveAsDraft() {
        saveDraft()
    }
    
    fun submitForm() {
        saveEntry()
    }
    
    fun clearMessages() {
        _uiState.value = _uiState.value.copy(
            successMessage = null,
            errorMessage = null,
            showSuccessMessage = false
        )
    }
    
    override fun onCleared() {
        super.onCleared()
        autoSaveJob?.cancel()
        AppLogger.d("FormDetailViewModel", "ViewModel cleared")
    }
}