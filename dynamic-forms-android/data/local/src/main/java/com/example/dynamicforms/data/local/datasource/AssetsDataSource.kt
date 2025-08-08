package com.example.dynamicforms.data.local.datasource

import android.content.Context
import com.example.dynamicforms.core.utils.result.Resource
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import android.util.Log
import com.example.dynamicforms.core.utils.logging.AppLogger
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AssetsDataSource @Inject constructor(
    @ApplicationContext private val context: Context,
    private val gson: Gson
) {
    
    private suspend fun loadFormFromAssets(fileName: String): Resource<Map<String, Any>> = withContext(Dispatchers.IO) {
        try {
            AppLogger.d("[AssetsDataSource] Loading form from assets: $fileName")
            
            val json = context.assets.open(fileName).bufferedReader().use { it.readText() }
            val type = object : TypeToken<Map<String, Any>>() {}.type
            val formData = gson.fromJson<Map<String, Any>>(json, type)

            AppLogger.d("[AssetsDataSource] Successfully loaded form: ${formData["title"]}")
            Resource.Success(formData)
        } catch (e: Exception) {
            AppLogger.e(e, "[AssetsDataSource] Error loading form from assets: $fileName")
            Resource.Error(e)
        }
    }
    
    suspend fun loadAllFormsFromAssets(): Resource<List<Map<String, Any>>> = withContext(Dispatchers.IO) {
        try {
            AppLogger.d("[AssetsDataSource] Loading all forms from assets")
            
            val formFiles = listOf("all-fields.json", "200-form.json")
            val forms = mutableListOf<Map<String, Any>>()
            
            formFiles.forEach { fileName ->
                when (val result = loadFormFromAssets(fileName)) {
                    is Resource.Success -> forms.add(result.data)
                    is Resource.Error -> {
                        AppLogger.w("[AssetsDataSource] Failed to load form: $fileName - ${result.message}")
                        // Continue loading other forms even if one fails
                    }
                    is Resource.Loading -> {
                        // This shouldn't happen in our synchronous implementation
                    }
                }
            }
            
            if (forms.isNotEmpty()) {
                AppLogger.d("[AssetsDataSource] Successfully loaded ${forms.size} forms")
                Resource.Success(forms)
            } else {
                val message = "No forms could be loaded from assets"
                AppLogger.e("[AssetsDataSource] $message")
                Resource.Error(Exception(message))
            }
        } catch (e: Exception) {
            AppLogger.e(e, "[AssetsDataSource] Error loading forms from assets")
            Resource.Error(e)
        }
    }
}