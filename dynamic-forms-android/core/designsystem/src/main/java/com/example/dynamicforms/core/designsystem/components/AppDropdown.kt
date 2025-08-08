package com.example.dynamicforms.core.designsystem.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

data class DropdownOption(
    val label: String,
    val value: String
)

@Composable
fun AppDropdown(
    modifier: Modifier = Modifier,
    value: String,
    onValueChange: (String) -> Unit,
    options: List<DropdownOption>,
    label: String,
    placeholder: String? = null,
    isError: Boolean = false,
    errorMessage: String? = null,
    enabled: Boolean = true
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedOption = options.find { it.value == value }
    
    Column(modifier = modifier) {
        Box {
            OutlinedTextField(
                value = selectedOption?.label ?: "",
                onValueChange = { },
                label = { Text(label) },
                placeholder = placeholder?.let { { Text(it) } },
                isError = isError,
                enabled = enabled,
                readOnly = true,
                trailingIcon = {
                    Icon(
                        imageVector = Icons.Default.ArrowDropDown,
                        contentDescription = "Dropdown arrow"
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = enabled) { expanded = true },
                shape = RoundedCornerShape(8.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = DynamicFormsColors.FieldBorderFocused,
                    unfocusedBorderColor = DynamicFormsColors.FieldBorder,
                    errorBorderColor = DynamicFormsColors.ValidationError,
                    focusedLabelColor = DynamicFormsColors.FieldBorderFocused,
                    unfocusedLabelColor = DynamicFormsColors.SectionHeader,
                    errorLabelColor = DynamicFormsColors.ValidationError,
                    disabledBorderColor = DynamicFormsColors.FieldBorder.copy(alpha = 0.38f),
                    disabledLabelColor = DynamicFormsColors.OnSurface.copy(alpha = 0.38f),
                    disabledTextColor = DynamicFormsColors.OnSurface.copy(alpha = 0.38f)
                )
            )
            
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                modifier = Modifier.fillMaxWidth()
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
        
        if (isError && errorMessage != null) {
            Text(
                text = errorMessage,
                color = DynamicFormsColors.ValidationError,
                style = DynamicFormsTypography.bodySmall,
                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
            )
        }
    }
}