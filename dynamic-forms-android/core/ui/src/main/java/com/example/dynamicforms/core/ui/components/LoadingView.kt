package com.example.dynamicforms.core.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@Composable
fun LoadingView(
    modifier: Modifier = Modifier,
    message: String = "Loading..."
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(48.dp),
                color = DynamicFormsColors.Primary
            )
            
            if (message.isNotEmpty()) {
                Text(
                    text = message,
                    style = DynamicFormsTypography.bodyMedium,
                    color = DynamicFormsColors.OnSurface,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 32.dp, end = 32.dp, top = 16.dp)
                )
            }
        }
    }
}

@Composable
fun InlineLoadingView(
    modifier: Modifier = Modifier,
    message: String? = null
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(24.dp),
            color = DynamicFormsColors.Primary,
            strokeWidth = 2.dp
        )
        
        message?.let {
            Text(
                text = it,
                style = DynamicFormsTypography.bodySmall,
                color = DynamicFormsColors.OnSurface,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}