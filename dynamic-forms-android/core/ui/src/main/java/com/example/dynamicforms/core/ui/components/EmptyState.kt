package com.example.dynamicforms.core.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.Icon

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.components.AppButton
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@Composable
fun EmptyState( 
    modifier: Modifier = Modifier,
    title: String,
    message: String,
    icon: ImageVector = Icons.Default.Home,
    action: (() -> Unit)? = null,
    actionText: String? = null
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = "Empty state",
                modifier = Modifier.size(72.dp),
                tint = DynamicFormsColors.OnSurface.copy(alpha = 0.6f)
            )
            
            Text(
                text = title,
                style = DynamicFormsTypography.headlineSmall,
                color = DynamicFormsColors.OnSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 16.dp)
            )
            
            Text(
                text = message,
                style = DynamicFormsTypography.bodyLarge,
                color = DynamicFormsColors.OnSurface.copy(alpha = 0.7f),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp)
            )
            
            if (action != null && actionText != null) {
                AppButton(
                    text = actionText,
                    onClick = action,
                    modifier = Modifier.padding(top = 24.dp)
                )
            }
        }
    }
}

@Composable
fun EmptyFormsList(
    onCreateForm: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyState(
        title = "No Forms Available",
        message = "There are no forms to display yet. Start by creating your first form.",
            icon = Icons.AutoMirrored.Filled.List,
        action = onCreateForm,
        actionText = "Create Form",
        modifier = modifier
    )
}

@Composable
fun EmptyFormEntries(
    onAddEntry: () -> Unit,
    modifier: Modifier = Modifier
) {
    EmptyState(
        title = "No Entries Yet",
        message = "This form doesn't have any entries. Add the first entry to get started.",
            icon = Icons.Default.Info,
        action = onAddEntry,
        actionText = "Add Entry",
        modifier = modifier
    )
}