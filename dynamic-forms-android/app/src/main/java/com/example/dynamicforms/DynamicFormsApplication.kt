package com.example.dynamicforms

import android.app.Application
import com.example.dynamicforms.core.utils.logging.AppLogger
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class DynamicFormsApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize AppLogger for logging
        AppLogger.init(false)
        
        AppLogger.d("DynamicFormsApplication initialized")
    }
}