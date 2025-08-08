package com.example.dynamicforms.data.local.datasource

import android.content.Context
import com.example.dynamicforms.core.utils.result.Resource
import com.example.dynamicforms.data.local.dao.FormDao
import com.example.dynamicforms.data.local.entity.FormEntity
import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import com.example.dynamicforms.core.utils.logging.AppLogger
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DatabaseInitializer @Inject constructor(
    @ApplicationContext private val context: Context,
    private val formDao: FormDao,
    private val assetsDataSource: AssetsDataSource,
    private val gson: Gson
) {

    /**
     * Initialize database with forms from assets if it's empty
     */
    suspend fun initializeDatabase(): Resource<Unit> = withContext(Dispatchers.IO) {
        try {
            AppLogger.d("DatabaseInitializer: Starting database initialization")

            val existingFormCount = formDao.getFormCount()
            if (existingFormCount > 0) {
                AppLogger.d("DatabaseInitializer: Database already contains $existingFormCount forms, skipping initialization")
                return@withContext Resource.Success(Unit)
            }

            AppLogger.d("DatabaseInitializer: Database is empty, loading forms from assets")
            
            when (val result = assetsDataSource.loadAllFormsFromAssets()) {
                is Resource.Success -> {
                    val formEntities = result.data.mapNotNull { formData ->
                        parseFormDataToEntity(formData)
                    }

                    if (formEntities.isNotEmpty()) {
                        formDao.insertForms(formEntities)
                        AppLogger.d("DatabaseInitializer: Successfully inserted ${formEntities.size} forms into database")
                        Resource.Success(Unit)
                    } else {
                        val message = "No valid forms found in assets"
                        AppLogger.e("DatabaseInitializer: $message")
                        Resource.Error(Exception(message))
                    }
                }
                is Resource.Error -> {
                    AppLogger.e(result.exception, "DatabaseInitializer: Failed to load forms from assets")
                    Resource.Error(result.exception)
                }
                is Resource.Loading -> {
                    // This shouldn't happen in our implementation
                    Resource.Error(Exception("Unexpected loading state"))
                }
            }
        } catch (e: Exception) {
            AppLogger.e(e, "DatabaseInitializer: Error during database initialization")
            Resource.Error(e)
        }
    }

    /**
     * Force reload all forms from assets (for testing/development)
     */
    suspend fun forceReloadForms(): Resource<Unit> = withContext(Dispatchers.IO) {
        try {
            AppLogger.d("DatabaseInitializer: Force reloading forms from assets")
            
            // Clear existing forms
            formDao.deleteAllForms()
            
            // Load fresh forms
            return@withContext initializeDatabase()
        } catch (e: Exception) {
            AppLogger.e(e, "DatabaseInitializer: Error during force reload")
            Resource.Error(e)
        }
    }

    /**
     * Parse form data from JSON to FormEntity
     */
    private fun parseFormDataToEntity(formData: Map<String, Any>): FormEntity? {
        return try {
            val title = formData["title"] as? String ?: return null
            val fields = formData["fields"] as? List<*> ?: return null
            val sections = formData["sections"] as? List<*> ?: return null

            // Generate a consistent ID based on the title
            val formId = generateFormId(title)

            // Convert fields and sections to JSON strings
            val fieldsJson = gson.toJson(fields)
            val sectionsJson = gson.toJson(sections)

            val currentTime = System.currentTimeMillis()

            FormEntity(
                id = formId,
                title = title,
                fieldsJson = fieldsJson,
                sectionsJson = sectionsJson,
                createdAt = currentTime,
                updatedAt = currentTime
            )
        } catch (e: Exception) {
            AppLogger.e(e, "DatabaseInitializer: Error parsing form data: ${formData["title"]}")
            null
        }
    }

    /**
     * Generate a consistent form ID from the title
     */
    private fun generateFormId(title: String): String {
        return title.lowercase()
            .replace(Regex("[^a-z0-9\\s]"), "")
            .replace(Regex("\\s+"), "-")
            .trim('-')
            .takeIf { it.isNotEmpty() }
            ?: UUID.randomUUID().toString()
    }

    /**
     * Validate form data structure
     */
    private fun validateFormData(formData: Map<String, Any>): Boolean {
        val requiredFields = listOf("title", "fields", "sections")
        
        return requiredFields.all { field ->
            formData.containsKey(field) && formData[field] != null
        }
    }

    /**
     * Create sample form entries for testing
     */
    suspend fun createSampleEntries(formId: String, count: Int = 5): Resource<Unit> = withContext(Dispatchers.IO) {
        try {
            AppLogger.d("DatabaseInitializer: Creating $count sample entries for form $formId")
            
            // This would typically be implemented with FormEntryDao
            // For now, just log the action
            AppLogger.d("DatabaseInitializer: Sample entries creation completed")
            Resource.Success(Unit)
        } catch (e: Exception) {
            AppLogger.e(e, "DatabaseInitializer: Error creating sample entries")
            Resource.Error(e)
        }
    }

    /**
     * Get database statistics
     */
    suspend fun getDatabaseStats(): DatabaseStats = withContext(Dispatchers.IO) {
        try {
            val formCount = formDao.getFormCount()
            
            DatabaseStats(
                formCount = formCount,
                lastInitialized = System.currentTimeMillis()
            )
        } catch (e: Exception) {
            AppLogger.e(e, "DatabaseInitializer: Error getting database stats")
            DatabaseStats(
                formCount = 0,
                lastInitialized = 0L
            )
        }
    }
}

data class DatabaseStats(
    val formCount: Int,
    val lastInitialized: Long
)