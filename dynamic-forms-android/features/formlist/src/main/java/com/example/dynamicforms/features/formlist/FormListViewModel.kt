package com.example.dynamicforms.features.formlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.dynamicforms.core.utils.logging.AppLogger
import com.example.dynamicforms.domain.usecase.GetAllFormsUseCase
import com.example.dynamicforms.domain.usecase.InitializeFormsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FormListViewModel @Inject constructor(
    private val getAllFormsUseCase: GetAllFormsUseCase,
    private val initializeFormsUseCase: InitializeFormsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(FormListUiState())
    val uiState: StateFlow<FormListUiState> = _uiState.asStateFlow()

    init {
        initializeForms()
    }

    fun onEvent(event: FormListEvent) {
        when (event) {
            is FormListEvent.LoadForms -> loadForms()
            is FormListEvent.Retry -> retry()
            is FormListEvent.NavigateToFormEntries -> {
                // Navigation will be handled by the UI layer
                AppLogger.d("Navigate to form entries: ${event.formId}")
            }
        }
    }

    private fun initializeForms() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isInitializing = true)
            
            try {
                val result = initializeFormsUseCase()
                if (result.isSuccess) {
                    loadForms()
                } else {
                    val error = result.exceptionOrNull()
                    error?.let { AppLogger.e(it, "Failed to initialize forms") }
                    _uiState.value = _uiState.value.copy(
                        isInitializing = false,
                        error = "Failed to load forms: ${error?.message ?: "Unknown error"}"
                    )
                }
            } catch (e: Exception) {
                AppLogger.e(e, "Error initializing forms")
                _uiState.value = _uiState.value.copy(
                    isInitializing = false,
                    error = "Failed to initialize forms: ${e.message}"
                )
            }
        }
    }

    private fun loadForms() {
        viewModelScope.launch {
            try {
                getAllFormsUseCase()
                    .onStart {
                        _uiState.value = _uiState.value.copy(
                            isLoading = true,
                            error = null,
                            isInitializing = false
                        )
                    }
                    .catch { exception ->
                        AppLogger.e(exception, "Error loading forms")
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = "Failed to load forms: ${exception.message}"
                        )
                    }
                    .collect { forms ->
                        AppLogger.d("Loaded ${forms.size} forms")
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            forms = forms,
                            error = null
                        )
                    }
            } catch (e: Exception) {
                AppLogger.e(e, "Unexpected error loading forms")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Unexpected error: ${e.message}"
                )
            }
        }
    }

    private fun retry() {
        _uiState.value = _uiState.value.copy(error = null)
        if (_uiState.value.forms.isEmpty()) {
            initializeForms()
        } else {
            loadForms()
        }
    }
}