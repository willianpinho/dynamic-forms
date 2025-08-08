package com.example.dynamicforms.features.formentries

sealed interface FormEntriesEvent {
    data class LoadFormAndEntries(val formId: String) : FormEntriesEvent
    data object Retry : FormEntriesEvent
    data object AddNewEntry : FormEntriesEvent
    data class NavigateToFormDetail(val formId: String, val entryId: String? = null) : FormEntriesEvent
    data class ShowDeleteDialog(val entryId: String) : FormEntriesEvent
    data class DeleteEntry(val entryId: String) : FormEntriesEvent
    data object DismissDeleteDialog : FormEntriesEvent
}