package com.example.dynamicforms.features.formentries.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.utils.formatters.TextFormatter
import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@Composable
fun FormEntryItem(
    entry: FormEntry,
    form: DynamicForm?,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    showDeleteButton: Boolean = !entry.isDraft
) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (entry.isDraft) {
                DynamicFormsColors.FormBackground
            } else {
                DynamicFormsColors.FieldBackground
            }
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp,
            pressedElevation = 4.dp
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = if (entry.isDraft) Icons.Default.Edit else Icons.Default.Info,
                contentDescription = if (entry.isDraft) "Draft" else "Entry",
                tint = if (entry.isDraft) {
                    DynamicFormsColors.FieldBorder
                } else {
                    DynamicFormsColors.Primary
                }
            )
            
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = if (entry.isDraft) "Draft Entry" else "Form Entry",
                    style = DynamicFormsTypography.titleMedium,
                    color = DynamicFormsColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                if (entry.fieldValues.isNotEmpty()) {
                    val sampleValue = entry.fieldValues.values.firstOrNull { it.isNotEmpty() }
                    if (sampleValue != null) {
                        Text(
                            text = sampleValue,
                            style = DynamicFormsTypography.bodyMedium,
                            color = DynamicFormsColors.SectionHeader,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                
                Text(
                    text = if (entry.isDraft) {
                        "Last saved ${TextFormatter.formatTimestamp(entry.updatedAt)}"
                    } else {
                        "Completed ${TextFormatter.formatTimestamp(entry.createdAt)}"
                    },
                    style = DynamicFormsTypography.bodySmall,
                    color = DynamicFormsColors.SectionHeader
                )
                
                if (form != null) {
                    val filledFields = entry.fieldValues.values.count { it.isNotEmpty() }
                    val totalFields = form.fields.size
                    Text(
                        text = "$filledFields of $totalFields fields filled",
                        style = DynamicFormsTypography.bodySmall,
                        color = DynamicFormsColors.SectionHeader
                    )
                }
            }
            
            if (showDeleteButton) {
                IconButton(
                    onClick = onDelete,
                    modifier = Modifier.padding(4.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete Entry",
                        tint = DynamicFormsColors.Error
                    )
                }
            }
            
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                contentDescription = "Navigate",
                tint = DynamicFormsColors.SectionHeader
            )
        }
    }
}