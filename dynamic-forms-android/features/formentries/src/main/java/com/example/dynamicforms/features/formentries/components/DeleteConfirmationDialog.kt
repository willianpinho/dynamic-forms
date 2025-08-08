package com.example.dynamicforms.features.formentries.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@Composable
fun DeleteConfirmationDialog(
    modifier: Modifier = Modifier,
    onDeleteConfirm: () -> Unit,
    onDismiss: () -> Unit,
    title: String = "Delete Form Entry",
    message: String = "Are you sure you want to delete this form entry? This action cannot be undone.",
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        title = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = "Warning",
                    tint = DynamicFormsColors.Error
                )
                Text(
                    text = title,
                    style = DynamicFormsTypography.headlineSmall,
                    color = DynamicFormsColors.OnSurface
                )
            }
        },
        text = {
            Column {
                Text(
                    text = message,
                    style = DynamicFormsTypography.bodyMedium,
                    color = DynamicFormsColors.SectionHeader
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "This action is permanent and cannot be undone.",
                    style = DynamicFormsTypography.bodySmall,
                    color = DynamicFormsColors.Error
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onDeleteConfirm()
                    onDismiss()
                }
            ) {
                Text(
                    text = "Delete",
                    style = DynamicFormsTypography.labelLarge,
                    color = DynamicFormsColors.Error
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(
                    text = "Cancel",
                    style = DynamicFormsTypography.labelLarge,
                    color = DynamicFormsColors.Primary
                )
            }
        }
    )
}