package com.example.dynamicforms.data.repository

import android.content.Context
import com.example.dynamicforms.data.local.datasource.FormLocalDataSource
import com.example.dynamicforms.data.mapper.FormMapper
import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.repository.FormRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FormRepositoryImpl @Inject constructor(
    private val localDataSource: FormLocalDataSource,
    private val formMapper: FormMapper,
    @ApplicationContext private val context: Context
) : FormRepository {
    
    override suspend fun getAllForms(): Flow<List<DynamicForm>> {
        return localDataSource.getAllForms().map { entities ->
            entities.map { formMapper.toDomain(it) }
        }
    }
    
    override suspend fun getFormById(id: String): Flow<DynamicForm?> {
        return localDataSource.getFormById(id).map { entity ->
            entity?.let { formMapper.toDomain(it) }
        }
    }
    
    override suspend fun insertForm(form: DynamicForm): Result<Unit> {
        return try {
            val entity = formMapper.toEntity(form)
            localDataSource.insertForm(entity)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun updateForm(form: DynamicForm): Result<Unit> {
        return try {
            val entity = formMapper.toEntity(form)
            localDataSource.updateForm(entity)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun deleteForm(id: String): Result<Unit> {
        return try {
            localDataSource.deleteForm(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun loadFormsFromAssets(): Result<List<DynamicForm>> {
        return try {
            val forms = mutableListOf<DynamicForm>()
            
            // Load all-fields.json
            val allFieldsJson = loadJsonFromAssets("all-fields.json")
            if (allFieldsJson.isNotEmpty()) {
                val allFieldsForm = formMapper.fromJsonToDomain(allFieldsJson)
                forms.add(allFieldsForm)
            }
            
            // Load 200-form.json
            val largeFormJson = loadJsonFromAssets("200-form.json")
            if (largeFormJson.isNotEmpty()) {
                val largeForm = formMapper.fromJsonToDomain(largeFormJson)
                forms.add(largeForm)
            }
            
            Result.success(forms)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun isFormsDataInitialized(): Boolean {
        return localDataSource.isFormsDataInitialized()
    }
    
    private fun loadJsonFromAssets(fileName: String): String {
        return try {
            context.assets.open(fileName).bufferedReader().use { it.readText() }
        } catch (e: IOException) {
            ""
        }
    }
}