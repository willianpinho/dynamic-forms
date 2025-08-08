package com.example.dynamicforms.core.designsystem.theme

import androidx.compose.ui.graphics.Color

object DynamicFormsColors {
    val Primary = Color(0xFF2196F3)
    val PrimaryVariant = Color(0xFF1976D2)
    val Secondary = Color(0xFF03DAC6)
    val SecondaryVariant = Color(0xFF018786)
    
    val Background = Color(0xFFFFFBFE)
    val Surface = Color(0xFFFFFBFE)
    val Error = Color(0xFFB00020)
    
    val OnPrimary = Color(0xFFFFFFFF)
    val OnSecondary = Color(0xFF000000)
    val OnBackground = Color(0xFF1C1B1F)
    val OnSurface = Color(0xFF1C1B1F)
    val OnError = Color(0xFFFFFFFF)
    
    // Custom colors for forms
    val FormBackground = Color(0xFFF5F5F5)
    val FieldBackground = Color(0xFFFFFFFF)
    val FieldBorder = Color(0xFFE0E0E0)
    val FieldBorderFocused = Primary
    val RequiredFieldIndicator = Error
    val ValidationError = Error
    val ValidationSuccess = Color(0xFF4CAF50)
    
    // Section colors
    val SectionHeader = Color(0xFF37474F)
    val SectionBackground = Color(0xFFFAFAFA)
    val SectionDivider = Color(0xFFE0E0E0)
    
    // Dark theme colors
    val DarkPrimary = Color(0xFF82B1FF)
    val DarkBackground = Color(0xFF121212)
    val DarkSurface = Color(0xFF1E1E1E)
    val DarkOnBackground = Color(0xFFE1E2E1)
    val DarkOnSurface = Color(0xFFE1E2E1)
}