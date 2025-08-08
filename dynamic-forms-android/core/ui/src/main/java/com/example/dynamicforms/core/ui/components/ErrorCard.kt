package com.example.dynamicforms.core.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.components.AppButton
import com.example.dynamicforms.core.designsystem.components.AppTextButton
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@Composable
fun ErrorCard(
    modifier: Modifier = Modifier,
    message: String,
    title: String = "Error",
    onRetry: (() -> Unit)? = null,
    retryText: String = "Retry"
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = DynamicFormsColors.ValidationError.copy(alpha = 0.1f),
            contentColor = DynamicFormsColors.OnSurface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = "Error",
                modifier = Modifier.size(48.dp),
                tint = DynamicFormsColors.ValidationError
            )
            
            Text(
                text = title,
                style = DynamicFormsTypography.titleMedium,
                color = DynamicFormsColors.ValidationError,
                modifier = Modifier.padding(top = 8.dp)
            )
            
            Text(
                text = message,
                style = DynamicFormsTypography.bodyMedium,
                color = DynamicFormsColors.OnSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp)
            )
            
            if (onRetry != null) {
                AppTextButton(
                    text = retryText,
                    onClick = onRetry,
                    modifier = Modifier.padding(top = 8.dp),
                    color = DynamicFormsColors.ValidationError
                )
            }
        }
    }
}

@Composable
fun FullScreenError(
    modifier: Modifier = Modifier,
    message: String,
    title: String = "Something went wrong",
    onRetry: (() -> Unit)? = null,
    retryText: String = "Try Again"
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
                imageVector = Icons.Default.Warning,
                contentDescription = "Error",
                modifier = Modifier.size(72.dp),
                tint = DynamicFormsColors.ValidationError
            )
            
            Text(
                text = title,
                style = DynamicFormsTypography.headlineSmall,
                color = DynamicFormsColors.ValidationError,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 16.dp)
            )
            
            Text(
                text = message,
                style = DynamicFormsTypography.bodyLarge,
                color = DynamicFormsColors.OnSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp)
            )
            
            if (onRetry != null) {
                AppButton(
                    text = retryText,
                    onClick = onRetry,
                    modifier = Modifier.padding(top = 24.dp)
                )
            }
        }
    }
}