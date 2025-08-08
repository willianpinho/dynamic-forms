package com.example.dynamicforms.core.designsystem.components

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

/**
 * Application Text component using DynamicForms Design System
 * Always uses DynamicFormsTypography and DynamicFormsColors
 */
@Composable
fun AppText(
    text: String,
    modifier: Modifier = Modifier,
    style: TextStyle = DynamicFormsTypography.bodyMedium,
    color: Color = DynamicFormsColors.OnSurface,
    fontWeight: FontWeight? = null,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
    overflow: TextOverflow = TextOverflow.Clip
) {
    Text(
        text = text,
        modifier = modifier,
        style = style.let { baseStyle ->
            fontWeight?.let { baseStyle.copy(fontWeight = it) } ?: baseStyle
        },
        color = color,
        textAlign = textAlign,
        maxLines = maxLines,
        overflow = overflow
    )
}

// Convenience functions for common text styles
@Composable
fun HeadlineLargeText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface,
    fontWeight: FontWeight = FontWeight.Bold
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.headlineLarge,
        color = color,
        fontWeight = fontWeight
    )
}

@Composable
fun HeadlineMediumText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface,
    fontWeight: FontWeight = FontWeight.Bold
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.headlineMedium,
        color = color,
        fontWeight = fontWeight
    )
}

@Composable
fun TitleLargeText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface,
    fontWeight: FontWeight = FontWeight.Medium
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.titleLarge,
        color = color,
        fontWeight = fontWeight
    )
}

@Composable
fun TitleMediumText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface,
    fontWeight: FontWeight = FontWeight.Medium
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.titleMedium,
        color = color,
        fontWeight = fontWeight
    )
}

@Composable
fun BodyLargeText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.bodyLarge,
        color = color
    )
}

@Composable
fun BodyMediumText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.bodyMedium,
        color = color
    )
}

@Composable
fun BodySmallText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = DynamicFormsColors.OnSurface
) {
    AppText(
        text = text,
        modifier = modifier,
        style = DynamicFormsTypography.bodySmall,
        color = color
    )
}