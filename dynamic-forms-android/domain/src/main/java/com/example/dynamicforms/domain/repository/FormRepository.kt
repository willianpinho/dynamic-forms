package com.example.dynamicforms.domain.repository

import com.example.dynamicforms.domain.model.DynamicForm
import kotlinx.coroutines.flow.Flow

interface FormRepository {
    
    suspend fun getAllForms(): Flow<List<DynamicForm>>
    
    suspend fun getFormById(id: String): Flow<DynamicForm?>
    
    suspend fun insertForm(form: DynamicForm): Result<Unit>
    
    suspend fun updateForm(form: DynamicForm): Result<Unit>
    
    suspend fun deleteForm(id: String): Result<Unit>
    
    suspend fun loadFormsFromAssets(): Result<List<DynamicForm>>
    
    suspend fun isFormsDataInitialized(): Boolean
}