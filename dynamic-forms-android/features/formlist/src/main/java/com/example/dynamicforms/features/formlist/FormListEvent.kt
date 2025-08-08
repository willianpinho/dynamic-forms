package com.example.dynamicforms.features.formlist

sealed interface FormListEvent {
    data object LoadForms : FormListEvent
    data object Retry : FormListEvent
    data class NavigateToFormEntries(val formId: String) : FormListEvent
}