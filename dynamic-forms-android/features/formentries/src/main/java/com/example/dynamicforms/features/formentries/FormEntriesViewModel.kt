package com.example.dynamicforms.features.formentries

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.dynamicforms.core.utils.logging.AppLogger
import com.example.dynamicforms.domain.usecase.DeleteFormEntryUseCase
import com.example.dynamicforms.domain.usecase.GetFormByIdUseCase
import com.example.dynamicforms.domain.usecase.GetFormEntriesUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FormEntriesViewModel @Inject constructor(
    private val getFormByIdUseCase: GetFormByIdUseCase,
    private val getFormEntriesUseCase: GetFormEntriesUseCase,
    private val deleteFormEntryUseCase: DeleteFormEntryUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(FormEntriesUiState())
    val uiState: StateFlow<FormEntriesUiState> = _uiState.asStateFlow()

    private var currentFormId: String? = null

    fun onEvent(event: FormEntriesEvent) {
        when (event) {
            is FormEntriesEvent.LoadFormAndEntries -> {
                currentFormId = event.formId
                loadFormAndEntries(event.formId)
            }
            is FormEntriesEvent.Retry -> {
                currentFormId?.let { formId ->
                    loadFormAndEntries(formId)
                }
            }
            is FormEntriesEvent.AddNewEntry -> {
                // Navigation will be handled by the UI layer
                AppLogger.d("Add new entry for form: $currentFormId")
            }
            is FormEntriesEvent.NavigateToFormDetail -> {
                // Navigation will be handled by the UI layer
                AppLogger.d("Navigate to form detail: ${event.formId}, entry: ${event.entryId}")
            }
            is FormEntriesEvent.ShowDeleteDialog -> {
                _uiState.value = _uiState.value.copy(
                    showDeleteDialog = true,
                    entryToDelete = event.entryId
                )
            }
            is FormEntriesEvent.DeleteEntry -> {
                deleteEntry(event.entryId)
            }
            is FormEntriesEvent.DismissDeleteDialog -> {
                _uiState.value = _uiState.value.copy(
                    showDeleteDialog = false,
                    entryToDelete = null
                )
            }
        }
    }

    private fun loadFormAndEntries(formId: String) {
        viewModelScope.launch {
            try {
                combine(
                    getFormByIdUseCase(formId),
                    getFormEntriesUseCase(formId)
                ) { form, entries ->
                    // Separate entries into submitted and drafts
                    val submittedEntries = entries.filter { it.isComplete && !it.isDraft }
                    val draftEntries = entries.filter { it.isDraft && !it.isComplete }
                    
                    AppLogger.d("Loaded ${entries.size} total entries")
                    AppLogger.d("Submitted entries: ${submittedEntries.size}")
                    AppLogger.d("Draft entries: ${draftEntries.size}")
                    
                    FormEntriesUiState(
                        isLoading = false,
                        form = form,
                        submittedEntries = submittedEntries,
                        draftEntries = draftEntries,
                        error = null
                    )
                }
                .onStart {
                    _uiState.value = _uiState.value.copy(
                        isLoading = true,
                        error = null
                    )
                }
                .catch { exception ->
                    AppLogger.e(exception, "Error loading form and entries")
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Failed to load data: ${exception.message}"
                    )
                }
                .collect { newState ->
                    AppLogger.d("Loaded form: ${newState.form?.title}, total entries: ${newState.totalEntries}")
                    AppLogger.d("Submitted: ${newState.submittedEntries.size}, Drafts: ${newState.draftEntries.size}")
                    _uiState.value = newState
                }
            } catch (e: Exception) {
                AppLogger.e(e, "Unexpected error loading form and entries")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Unexpected error: ${e.message}"
                )
            }
        }
    }

    private fun deleteEntry(entryId: String) {
        viewModelScope.launch {
            try {
                AppLogger.d("Deleting entry: $entryId")
                deleteFormEntryUseCase(entryId)
                    .onSuccess {
                        AppLogger.d("Entry deleted successfully: $entryId")
                        // Dismiss dialog and reload data to reflect the changes
                        _uiState.value = _uiState.value.copy(
                            showDeleteDialog = false,
                            entryToDelete = null
                        )
                        currentFormId?.let { formId ->
                            loadFormAndEntries(formId)
                        }
                    }
                    .onFailure { exception ->
                        AppLogger.e(exception, "Failed to delete entry: $entryId")
                        _uiState.value = _uiState.value.copy(
                            error = "Failed to delete entry: ${exception.message}"
                        )
                    }
            } catch (e: Exception) {
                AppLogger.e(e, "Unexpected error deleting entry: $entryId")
                _uiState.value = _uiState.value.copy(
                    error = "Unexpected error deleting entry: ${e.message}"
                )
            }
        }
    }
}