package com.example.dynamicforms.features.formdetail.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.domain.model.FormField
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography
import com.example.dynamicforms.core.utils.logging.AppLogger

@Composable
fun DynamicFormField(
    modifier: Modifier = Modifier,
    field: FormField,
    value: String,
    onValueChange: (String) -> Unit,
    errorMessage: String? = null,
) {
    // Remove excessive logging in Composable - causes performance issues during recomposition
    // AppLogger.dv("DynamicFormField", "Rendering field: ${field.label} (${field.uuid}) - Type: ${field.type} - Value: '$value'")
    
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        when (field.type) {
            com.example.dynamicforms.domain.model.FieldType.TEXT -> {
                DynamicTextField(
                    field = field,
                    value = value,
                    onValueChange = onValueChange,
                    isError = errorMessage != null
                )
            }
            com.example.dynamicforms.domain.model.FieldType.NUMBER -> {
                DynamicNumberField(
                    field = field,
                    value = value,
                    onValueChange = onValueChange,
                    isError = errorMessage != null
                )
            }
            com.example.dynamicforms.domain.model.FieldType.DROPDOWN -> {
                DynamicDropdownField(
                    field = field,
                    value = value,
                    onValueChange = onValueChange,
                    isError = errorMessage != null
                )
            }
            com.example.dynamicforms.domain.model.FieldType.DESCRIPTION -> {
                DynamicDescriptionField(
                    field = field
                )
            }

            else -> {
                // Fallback to text field for unknown types
                DynamicTextField(
                    field = field,
                    value = value,
                    onValueChange = onValueChange,
                    isError = errorMessage != null
                )
            }
        }
        
        // Show error message if present
        if (errorMessage != null) {
            Text(
                text = errorMessage,
                color = DynamicFormsColors.ValidationError,
                style = DynamicFormsTypography.bodySmall,
                modifier = Modifier.padding(start = 16.dp)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DynamicTextField(
    field: FormField,
    value: String,
    onValueChange: (String) -> Unit,
    isError: Boolean
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = {
            Row {
                Text(field.label)
                if (field.required) {
                    Text(
                        text = " *",
                        color = DynamicFormsColors.RequiredFieldIndicator
                    )
                }
            }
        },
        placeholder = { Text("Enter ${field.label.lowercase()}") },
        isError = isError,
        singleLine = true,
        modifier = Modifier.fillMaxWidth()
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DynamicNumberField(
    field: FormField,
    value: String,
    onValueChange: (String) -> Unit,
    isError: Boolean
) {
    OutlinedTextField(
        value = value,
        onValueChange = { input ->
            // Only allow numeric input
            if (input.isEmpty() || input.matches(Regex("^\\d*\\.?\\d*\$"))) {
                onValueChange(input)
            }
        },
        label = {
            Row {
                Text(field.label)
                if (field.required) {
                    Text(
                        text = " *",
                        color = DynamicFormsColors.RequiredFieldIndicator
                    )
                }
            }
        },
        placeholder = { Text("Enter ${field.label.lowercase()}") },
        isError = isError,
        singleLine = true,
        modifier = Modifier.fillMaxWidth()
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DynamicDropdownField(
    field: FormField,
    value: String,
    onValueChange: (String) -> Unit,
    isError: Boolean
) {
    var expanded by remember { mutableStateOf(false) }
    val options = field.options

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = !expanded }
    ) {
        OutlinedTextField(
            value = value,
            onValueChange = { },
            readOnly = true,
            label = {
                Row {
                    Text(field.label)
                    if (field.required) {
                        Text(
                            text = " *",
                            color = DynamicFormsColors.RequiredFieldIndicator
                        )
                    }
                }
            },
            placeholder = { Text("Select an option") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            isError = isError,
            modifier = Modifier
                .menuAnchor()
                .fillMaxWidth()
        )
        
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option.label) },
                    onClick = {
                        onValueChange(option.value)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
private fun DynamicDescriptionField(
    field: FormField
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = DynamicFormsColors.SectionBackground
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (field.label.isNotEmpty()) {
                Text(
                    text = field.label,
                    style = DynamicFormsTypography.titleMedium,
                    color = DynamicFormsColors.SectionHeader
                )
            }
            
            // Render HTML content using HtmlText component  
            // For description fields, use the value field as content
            val content = field.value
            
            if (content.isNotEmpty()) {
                HtmlText(
                    html = content,
                    modifier = Modifier.fillMaxWidth(),
                    color = DynamicFormsColors.SectionHeader
                )
            }
        }
    }
}

