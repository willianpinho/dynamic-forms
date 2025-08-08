package com.example.dynamicforms.core.designsystem.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

@Composable
fun AppButton(
    modifier: Modifier = Modifier,
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    fullWidth: Boolean = false
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = if (fullWidth) modifier.fillMaxWidth() else modifier,
        shape = RoundedCornerShape(8.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = DynamicFormsColors.Primary,
            contentColor = DynamicFormsColors.OnPrimary,
            disabledContainerColor = DynamicFormsColors.Primary.copy(alpha = 0.38f),
            disabledContentColor = DynamicFormsColors.OnPrimary.copy(alpha = 0.38f)
        )
    ) {
        Text(
            text = text,
            style = DynamicFormsTypography.labelLarge,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(vertical = 4.dp)
        )
    }
}

@Composable
fun AppOutlinedButton(
    modifier: Modifier = Modifier,
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    fullWidth: Boolean = false
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = if (fullWidth) modifier.fillMaxWidth() else modifier,
        shape = RoundedCornerShape(8.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = DynamicFormsColors.Primary,
            disabledContentColor = DynamicFormsColors.Primary.copy(alpha = 0.38f)
        )
    ) {
        Text(
            text = text,
            style = DynamicFormsTypography.labelLarge,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(vertical = 4.dp)
        )
    }
}

@Composable
fun AppTextButton(
    modifier: Modifier = Modifier,
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    color: Color = DynamicFormsColors.Primary
) {
    TextButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier,
        colors = ButtonDefaults.textButtonColors(
            contentColor = color,
            disabledContentColor = color.copy(alpha = 0.38f)
        )
    ) {
        Text(
            text = text,
            style = DynamicFormsTypography.labelLarge,
            fontWeight = FontWeight.Medium
        )
    }
}