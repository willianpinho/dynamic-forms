package com.example.dynamicforms.core.designsystem.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = DynamicFormsColors.DarkPrimary,
    secondary = DynamicFormsColors.Secondary,
    background = DynamicFormsColors.DarkBackground,
    surface = DynamicFormsColors.DarkSurface,
    onPrimary = DynamicFormsColors.OnPrimary,
    onSecondary = DynamicFormsColors.OnSecondary,
    onBackground = DynamicFormsColors.DarkOnBackground,
    onSurface = DynamicFormsColors.DarkOnSurface,
    error = DynamicFormsColors.Error,
    onError = DynamicFormsColors.OnError
)

private val LightColorScheme = lightColorScheme(
    primary = DynamicFormsColors.Primary,
    secondary = DynamicFormsColors.Secondary,
    background = DynamicFormsColors.Background,
    surface = DynamicFormsColors.Surface,
    onPrimary = DynamicFormsColors.OnPrimary,
    onSecondary = DynamicFormsColors.OnSecondary,
    onBackground = DynamicFormsColors.OnBackground,
    onSurface = DynamicFormsColors.OnSurface,
    error = DynamicFormsColors.Error,
    onError = DynamicFormsColors.OnError
)

@Composable
fun DynamicFormsTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.setDecorFitsSystemWindows(window, false)
            val insetsController = WindowCompat.getInsetsController(window, view)
            insetsController.isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = DynamicFormsTypography,
        content = content
    )
}