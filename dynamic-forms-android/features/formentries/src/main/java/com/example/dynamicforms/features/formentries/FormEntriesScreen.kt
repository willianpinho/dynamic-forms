package com.example.dynamicforms.features.formentries

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.dynamicforms.core.ui.components.EmptyFormEntries
import com.example.dynamicforms.core.ui.components.ErrorCard
import com.example.dynamicforms.core.ui.components.LoadingView
import com.example.dynamicforms.core.utils.formatters.TextFormatter
import com.example.dynamicforms.features.formentries.components.DeleteConfirmationDialog
import com.example.dynamicforms.features.formentries.components.FormEntryItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FormEntriesScreen(
    modifier: Modifier = Modifier,
    formId: String,
    onNavigateBack: () -> Unit,
    onNavigateToFormDetail: (String, String?) -> Unit,
    viewModel: FormEntriesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    LaunchedEffect(formId) {
        viewModel.onEvent(FormEntriesEvent.LoadFormAndEntries(formId))
    }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = uiState.form?.let { TextFormatter.formatFormTitle(it.title) } ?: "Form Entries",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            if (uiState.form != null && !uiState.isLoading) {
                FloatingActionButton(
                    onClick = {
                        viewModel.onEvent(FormEntriesEvent.AddNewEntry)
                        onNavigateToFormDetail(formId, null)
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add Entry"
                    )
                }
            }
        }
    ) { paddingValues ->
        FormEntriesContent(
            uiState = uiState,
            onEvent = viewModel::onEvent,
            onNavigateToFormDetail = onNavigateToFormDetail,
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        )
    }
}

@Composable
private fun FormEntriesContent(
    uiState: FormEntriesUiState,
    onEvent: (FormEntriesEvent) -> Unit,
    onNavigateToFormDetail: (String, String?) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier) {
        when {
            uiState.isLoading -> {
                LoadingView(message = "Loading entries...")
            }
            
            uiState.hasError -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    ErrorCard(
                        title = "Unable to Load Entries",
                        message = uiState.error ?: "An unexpected error occurred",
                        onRetry = { onEvent(FormEntriesEvent.Retry) }
                    )
                }
            }
            
            uiState.isEmpty -> {
                EmptyFormEntries(
                    onAddEntry = {
                        uiState.form?.let { form ->
                            onEvent(FormEntriesEvent.AddNewEntry)
                            onNavigateToFormDetail(form.id, null)
                        }
                    }
                )
            }
            
            else -> {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Submitted Entries Section
                    if (uiState.submittedEntries.isNotEmpty()) {
                        item {
                            SectionHeader(
                                title = "Submitted Entries",
                                count = uiState.submittedEntries.size,
                                icon = Icons.Default.Check
                            )
                        }
                        
                        items(
                            items = uiState.submittedEntries,
                            key = { entry -> "submitted_${entry.id}" }
                        ) { entry ->
                            FormEntryItem(
                                entry = entry,
                                form = uiState.form,
                                onClick = {
                                    onEvent(FormEntriesEvent.NavigateToFormDetail(entry.formId, entry.id))
                                    onNavigateToFormDetail(entry.formId, entry.id)
                                },
                                onDelete = {
                                    onEvent(FormEntriesEvent.ShowDeleteDialog(entry.id))
                                }
                            )
                        }
                    }
                    
                    // Draft Entries Section
                    if (uiState.draftEntries.isNotEmpty()) {
                        item {
                            SectionHeader(
                                title = "Draft Entries",
                                count = uiState.draftEntries.size,
                                icon = Icons.Default.Edit
                            )
                        }
                        
                        items(
                            items = uiState.draftEntries,
                            key = { entry -> "draft_${entry.id}" }
                        ) { entry ->
                            FormEntryItem(
                                entry = entry,
                                form = uiState.form,
                                onClick = {
                                    onEvent(FormEntriesEvent.NavigateToFormDetail(entry.formId, entry.id))
                                    onNavigateToFormDetail(entry.formId, entry.id)
                                },
                                onDelete = {
                                    onEvent(FormEntriesEvent.DeleteEntry(entry.id))
                                }
                            )
                        }
                    }
                    
                    // Add spacing at the bottom
                    item {
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                }
            }
        }
    }

    // Delete confirmation dialog
    uiState.entryToDelete?.let { entryId ->
        if (uiState.showDeleteDialog) {
            DeleteConfirmationDialog(
                onDeleteConfirm = {
                    onEvent(FormEntriesEvent.DeleteEntry(entryId))
                },
                onDismiss = {
                    onEvent(FormEntriesEvent.DismissDeleteDialog)
                }
            )
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    count: Int,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = DynamicFormsColors.Primary,
            modifier = Modifier.size(20.dp)
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Text(
            text = title,
            style = DynamicFormsTypography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = DynamicFormsColors.SectionHeader
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Text(
            text = "($count)",
            style = DynamicFormsTypography.bodyMedium,
            color = DynamicFormsColors.SectionHeader
        )
    }
}