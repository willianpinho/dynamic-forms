package com.example.dynamicforms.features.formdetail
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.dynamicforms.core.designsystem.components.AppText
import com.example.dynamicforms.core.designsystem.components.AppTextButton
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography
import com.example.dynamicforms.core.ui.components.ErrorCard
import com.example.dynamicforms.core.ui.components.LoadingView
import com.example.dynamicforms.core.utils.logging.AppLogger
import com.example.dynamicforms.features.formdetail.components.DynamicFormField
import com.example.dynamicforms.features.formdetail.components.HtmlText

// Performance optimization data class
private data class ProgressStats(
    val filledFields: Int,
    val totalFields: Int,
    val requiredFields: Int,
    val filledRequiredFields: Int
)
// Virtual Scrolling data structures for maximum performance
private sealed class VirtualFormItem {
    abstract val id: String
    
    data class EditWarning(
        override val id: String = "edit_warning",
        val editContext: EditContext
    ) : VirtualFormItem()
    
    data class SectionHeader(
        override val id: String,
        val section: com.example.dynamicforms.domain.model.FormSection,
        val progress: Pair<Int, Int> // filled, total
    ) : VirtualFormItem()
    
    data class FieldItem(
        override val id: String,
        val field: com.example.dynamicforms.domain.model.FormField,
        val sectionId: String
    ) : VirtualFormItem()
    
    data class SuccessMessage(
        override val id: String = "success_message",
        val message: String
    ) : VirtualFormItem()
    
    data class AutoSaveStatus(
        override val id: String = "autosave_status",
        val timestamp: Long
    ) : VirtualFormItem()
    
    data class FormActions(
        override val id: String = "form_actions"
    ) : VirtualFormItem()
}
// Virtual Scrolling: Generate flattened list for maximum performance
@Composable
private fun generateVirtualFormItems(
    uiState: FormDetailUiState
): List<VirtualFormItem> {
    val form = uiState.form ?: return emptyList()
    
    return remember(
        uiState.editContext,
        uiState.successMessage,
        uiState.autosaveEnabled,
        uiState.lastAutosaveTime,
        form.sections,
        uiState.fieldValues
    ) {
        buildList {
            // Edit mode warning
            if (uiState.editContext != EditContext.NEW_ENTRY) {
                add(VirtualFormItem.EditWarning(editContext = uiState.editContext))
            }
            
            // Form sections and fields
            form.sections.forEach { section ->
                // Section header with progress
                val sectionProgress = section.fields.count { field ->
                    uiState.fieldValues[field.uuid]?.isNotBlank() == true
                } to section.fields.size
                
                add(VirtualFormItem.SectionHeader(
                    id = "section_${section.title.hashCode()}",
                    section = section,
                    progress = sectionProgress
                ))
                
                // Section fields
                section.fields.forEach { field ->
                    add(VirtualFormItem.FieldItem(
                        id = "field_${field.uuid}",
                        field = field,
                        sectionId = section.title.hashCode().toString()
                    ))
                }
            }
            
            // Success message
            uiState.successMessage?.let { message ->
                add(VirtualFormItem.SuccessMessage(message = message))
            }
            
            // Auto-save status
            if (uiState.autosaveEnabled && uiState.lastAutosaveTime > 0) {
                add(VirtualFormItem.AutoSaveStatus(timestamp = uiState.lastAutosaveTime))
            }
            
            // Form actions
            add(VirtualFormItem.FormActions())
        }
    }
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FormDetailScreen(
    modifier: Modifier = Modifier,
    formId: String,
    entryId: String? = null,
    onBackClick: () -> Unit,
    onSaveSuccess: () -> Unit,
    viewModel: FormDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    // Initialize form when composable is created
    LaunchedEffect(formId, entryId) {
        viewModel.loadForm(formId, entryId)
    }
    // Handle save success
    LaunchedEffect(uiState.showSuccessMessage) {
        if (uiState.showSuccessMessage) {
            onSaveSuccess()
        }
    }
    // Handle success messages (for drafts) - Optimized for performance
    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let { message ->
            AppLogger.d("FormDetailScreen", "Success message detected: $message")
            // Use background thread for delay to avoid blocking UI thread
            kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) {
                kotlinx.coroutines.delay(3000) // Show for 3 seconds on background thread
            }
            // Clear messages back on main thread
            viewModel.clearMessages()
        }
    }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    AppText(
                        text = uiState.form?.title ?: "Loading Form...",
                        style = DynamicFormsTypography.titleLarge,
                        maxLines = 1,
                        overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        },
        modifier = modifier
    ) { paddingValues ->
        when {
            uiState.isLoading -> {
                LoadingView(
                    message = "Loading form...",
                    modifier = Modifier.padding(paddingValues)
                )
            }
            
            uiState.errorMessage != null -> {
                val errorMessage = uiState.errorMessage
                ErrorCard(
                    message = errorMessage ?: "Unknown error",
                    onRetry = { viewModel.loadForm(formId, entryId) },
                    modifier = Modifier
                        .padding(paddingValues)
                        .padding(16.dp)
                )
            }
            
            uiState.form != null -> {
                FormContent(
                    uiState = uiState,
                    onFieldValueChange = { fieldId, value ->
                        viewModel.updateFieldValue(fieldId, value)
                    },
                    onSaveAsDraft = { viewModel.saveAsDraft() },
                    onSubmitForm = { viewModel.submitForm() },
                    onClearMessages = { viewModel.clearMessages() },
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }
}
@Composable
private fun FormContent(
    uiState: FormDetailUiState,
    onFieldValueChange: (String, String) -> Unit,
    onSaveAsDraft: () -> Unit,
    onSubmitForm: () -> Unit,
    onClearMessages: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Virtual Scrolling: Generate flattened item list for maximum performance
    val virtualItems = generateVirtualFormItems(uiState)
    
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(
            items = virtualItems,
            key = { item -> item.id }
        ) { item ->
            when (item) {
                is VirtualFormItem.EditWarning -> {
                    VirtualEditWarningItem(editContext = item.editContext)
                }
                
                is VirtualFormItem.SectionHeader -> {
                    VirtualSectionHeaderItem(
                        section = item.section,
                        progress = item.progress
                    )
                }
                
                is VirtualFormItem.FieldItem -> {
                    VirtualFieldItem(
                        field = item.field,
                        value = uiState.fieldValues[item.field.uuid] ?: "",
                        errorMessage = uiState.validationErrors[item.field.uuid],
                        onValueChange = { value ->
                            onFieldValueChange(item.field.uuid, value)
                        }
                    )
                }
                
                is VirtualFormItem.SuccessMessage -> {
                    VirtualSuccessMessageItem(
                        message = item.message,
                        onDismiss = onClearMessages
                    )
                }
                
                is VirtualFormItem.AutoSaveStatus -> {
                    VirtualAutoSaveStatusItem(timestamp = item.timestamp)
                }
                
                is VirtualFormItem.FormActions -> {
                    VirtualFormActionsItem(
                        uiState = uiState,
                        onSaveAsDraft = onSaveAsDraft,
                        onSubmitForm = onSubmitForm
                    )
                }
            }
        }
    }
}
// Virtual Item Components for maximum performance and reusability
@Composable
private fun VirtualEditWarningItem(
    editContext: EditContext,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = DynamicFormsColors.Secondary.copy(alpha = 0.1f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Edit,
                contentDescription = null,
                tint = DynamicFormsColors.Secondary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            AppText(
                text = when (editContext) {
                    EditContext.EDITING_DRAFT -> "Editing draft • Draft linking enabled to preserve all drafts"
                    EditContext.EDITING_SUBMITTED -> "Editing submitted entry • Draft linking enabled to preserve all drafts"
                    EditContext.NEW_ENTRY -> ""
                },
                style = DynamicFormsTypography.bodyMedium,
                color = DynamicFormsColors.Secondary,
                modifier = Modifier.weight(1f)
            )
        }
    }
}
@Composable
private fun VirtualSectionHeaderItem(
    section: com.example.dynamicforms.domain.model.FormSection,
    progress: Pair<Int, Int>,
    modifier: Modifier = Modifier
) {
    if (section.title.isNotEmpty()) {
        Card(
            modifier = modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
            colors = CardDefaults.cardColors(
                containerColor = DynamicFormsColors.FieldBackground
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        HtmlText(
                            html = section.title,
                            modifier = Modifier.fillMaxWidth(),
                            color = DynamicFormsColors.Primary
                        )
                        
                        if (progress.second > 0) {
                            Text(
                                text = "${progress.first} of ${progress.second} completed",
                                style = DynamicFormsTypography.bodySmall,
                                color = DynamicFormsColors.SectionHeader
                            )
                        }
                    }
                }
            }
        }
    }
}
@Composable
private fun VirtualFieldItem(
    field: com.example.dynamicforms.domain.model.FormField,
    value: String,
    errorMessage: String?,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    DynamicFormField(
        modifier = modifier,
        field = field,
        value = value,
        onValueChange = onValueChange,
        errorMessage = errorMessage
    )
}
@Composable
private fun VirtualSuccessMessageItem(
    message: String,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 16.dp),
        colors = CardDefaults.cardColors(
            containerColor = DynamicFormsColors.ValidationSuccess.copy(alpha = 0.1f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = DynamicFormsColors.ValidationSuccess,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            AppText(
                text = message,
                style = DynamicFormsTypography.bodyLarge,
                color = DynamicFormsColors.ValidationSuccess,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )
            AppTextButton(
                text = "Dismiss",
                onClick = onDismiss
            )
        }
    }
}
@Composable
private fun VirtualAutoSaveStatusItem(
    timestamp: Long,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = DynamicFormsColors.FormBackground
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = DynamicFormsColors.SectionHeader,
                modifier = Modifier.size(12.dp)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "Auto-saved at ${java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp))}",
                style = DynamicFormsTypography.bodySmall,
                color = DynamicFormsColors.SectionHeader
            )
        }
    }
}

@Composable
private fun VirtualFormActionsItem(
    uiState: FormDetailUiState,
    onSaveAsDraft: () -> Unit,
    onSubmitForm: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Progress summary
        Card(
            colors = CardDefaults.cardColors(
                containerColor = DynamicFormsColors.FormBackground
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Performance optimization: Cache progress calculations
                val progressStats = remember(uiState.fieldValues, uiState.form?.fields) {
                    val form = uiState.form
                    if (form != null) {
                        val filledFields = uiState.fieldValues.values.count { it.isNotBlank() }
                        val totalFields = form.fields.size
                        val requiredFields = form.fields.count { it.required }
                        val filledRequiredFields = form.fields.count { field ->
                            field.required && uiState.fieldValues[field.uuid]?.isNotBlank() == true
                        }
                        ProgressStats(filledFields, totalFields, requiredFields, filledRequiredFields)
                    } else {
                        ProgressStats(0, 0, 0, 0)
                    }
                }
                val (filledFields, totalFields, requiredFields, filledRequiredFields) = progressStats
                
                Column {
                    Text(
                        text = "Form Progress",
                        style = DynamicFormsTypography.titleSmall,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Text(
                        text = "$filledFields of $totalFields fields completed",
                        style = DynamicFormsTypography.bodyMedium,
                        color = DynamicFormsColors.SectionHeader
                    )
                    
                    if (requiredFields > 0) {
                        Text(
                            text = "$filledRequiredFields of $requiredFields required completed",
                            style = DynamicFormsTypography.bodySmall,
                            color = DynamicFormsColors.SectionHeader
                        )
                    }
                }
                
                // Completion percentage
                val completionPercentage = if (totalFields > 0) {
                    (filledFields * 100) / totalFields
                } else 0
                
                AppText(
                    text = "$completionPercentage%",
                    style = DynamicFormsTypography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = DynamicFormsColors.Primary
                )
            }
        }
        
        // Action buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Save as Draft button
            AppTextButton(
                text = "Save as Draft",
                onClick = onSaveAsDraft,
                modifier = Modifier.weight(1f)
            )
            
            // Submit button  
            Button(
                onClick = onSubmitForm,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = DynamicFormsColors.Primary
                )
            ) {
                AppText(
                    text = "Submit",
                    style = DynamicFormsTypography.labelLarge
                )
            }
        }
    }
}
