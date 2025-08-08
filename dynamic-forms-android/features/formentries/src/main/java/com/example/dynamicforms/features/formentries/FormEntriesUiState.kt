package com.example.dynamicforms.features.formentries

import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.model.FormEntry

data class FormEntriesUiState(
    val isLoading: Boolean = false,
    val form: DynamicForm? = null,
    val submittedEntries: List<FormEntry> = emptyList(),
    val draftEntries: List<FormEntry> = emptyList(),
    val error: String? = null,
    val entryToDelete: String? = null,
    val showDeleteDialog: Boolean = false
) {
    val isEmpty: Boolean get() = submittedEntries.isEmpty() && draftEntries.isEmpty() && !isLoading && error == null && form != null
    val hasError: Boolean get() = error != null
    val totalEntries: Int get() = submittedEntries.size + draftEntries.size
}