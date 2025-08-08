package com.example.dynamicforms.features.formlist

import com.example.dynamicforms.domain.model.DynamicForm

data class FormListUiState(
    val isLoading: Boolean = false,
    val forms: List<DynamicForm> = emptyList(),
    val error: String? = null,
    val isInitializing: Boolean = false
) {
    val isEmpty: Boolean get() = forms.isEmpty() && !isLoading && error == null
    val hasError: Boolean get() = error != null
}