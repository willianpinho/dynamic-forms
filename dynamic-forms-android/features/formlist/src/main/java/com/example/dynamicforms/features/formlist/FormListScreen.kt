package com.example.dynamicforms.features.formlist

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api

import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.dynamicforms.core.ui.components.EmptyFormsList
import com.example.dynamicforms.core.ui.components.ErrorCard
import com.example.dynamicforms.core.ui.components.LoadingView
import com.example.dynamicforms.features.formlist.components.FormListItem
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FormListScreen(
    modifier: Modifier = Modifier,
    onNavigateToFormEntries: (String) -> Unit,
    viewModel: FormListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    LaunchedEffect(Unit) {
        viewModel.onEvent(FormListEvent.LoadForms)
    }

    Scaffold(
        modifier = modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Dynamic Forms",
                        style = DynamicFormsTypography.headlineMedium
                    )
                },
                scrollBehavior = scrollBehavior
            )
        }
    ) { paddingValues ->
        FormListContent(
            uiState = uiState,
            onEvent = viewModel::onEvent,
            onNavigateToFormEntries = onNavigateToFormEntries,
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        )
    }
}

@Composable
private fun FormListContent(
    modifier: Modifier = Modifier,
    uiState: FormListUiState,
    onEvent: (FormListEvent) -> Unit,
    onNavigateToFormEntries: (String) -> Unit,
) {
    Box(modifier = modifier) {
        when {
            uiState.isLoading || uiState.isInitializing -> {
                LoadingView(
                    message = if (uiState.isInitializing) {
                        "Initializing forms..."
                    } else {
                        "Loading forms..."
                    }
                )
            }
            
            uiState.hasError -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    ErrorCard(
                        title = "Unable to Load Forms",
                        message = uiState.error ?: "An unexpected error occurred",
                        onRetry = { onEvent(FormListEvent.Retry) }
                    )
                }
            }
            
            uiState.isEmpty -> {
                EmptyFormsList(
                    onCreateForm = {
                        // For now, just retry to load forms
                        onEvent(FormListEvent.Retry)
                    }
                )
            }
            
            else -> {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(
                        items = uiState.forms,
                        key = { form -> form.id }
                    ) { form ->
                        FormListItem(
                            form = form,
                            onClick = {
                                onEvent(FormListEvent.NavigateToFormEntries(form.id))
                                onNavigateToFormEntries(form.id)
                            }
                        )
                    }
                }
            }
        }
    }
}