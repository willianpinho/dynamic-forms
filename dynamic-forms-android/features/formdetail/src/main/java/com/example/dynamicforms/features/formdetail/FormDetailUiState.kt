package com.example.dynamicforms.features.formdetail

import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.model.FormEntry

data class FormDetailUiState(
    val isLoading: Boolean = false,
    val form: DynamicForm? = null,
    val entry: FormEntry? = null,
    val fieldValues: Map<String, String> = emptyMap(),
    val validationErrors: Map<String, String> = emptyMap(),
    val isSaving: Boolean = false,
    val errorMessage: String? = null,
    val showSuccessMessage: Boolean = false,
    val isAutoSaveEnabled: Boolean = true,
    val lastAutoSaveTime: Long? = null,
    val successMessage: String? = null,
    val autosaveEnabled: Boolean = true,
    val lastAutosaveTime: Long = lastAutoSaveTime ?: 0L,
    val isEditingExistingEntry: Boolean = false,
    val editContext: EditContext = EditContext.NEW_ENTRY
)

enum class EditContext {
    NEW_ENTRY,          // Creating a new entry
    EDITING_DRAFT,      // Editing an existing draft
    EDITING_SUBMITTED   // Editing a submitted entry
}

sealed class FormDetailEvent {
    data object LoadForm : FormDetailEvent()
    data class UpdateField(val fieldUuid: String, val value: String) : FormDetailEvent()
    data object SaveEntry : FormDetailEvent()
    data object SaveDraft : FormDetailEvent()
    data object DeleteEntry : FormDetailEvent()
    data object ClearError : FormDetailEvent()
    data object ToggleAutoSave : FormDetailEvent()
    data object ValidateForm : FormDetailEvent()
}