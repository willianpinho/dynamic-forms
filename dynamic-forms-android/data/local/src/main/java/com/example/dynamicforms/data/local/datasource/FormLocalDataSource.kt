package com.example.dynamicforms.data.local.datasource

import com.example.dynamicforms.data.local.dao.FormDao
import com.example.dynamicforms.data.local.entity.FormEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FormLocalDataSource @Inject constructor(
    private val formDao: FormDao
) {
    fun getAllForms(): Flow<List<FormEntity>> = formDao.getAllForms()
    
    fun getFormById(id: String): Flow<FormEntity?> = formDao.getFormById(id)
    
    suspend fun insertForm(form: FormEntity) = formDao.insertForm(form)
    
    suspend fun insertForms(forms: List<FormEntity>) = formDao.insertForms(forms)
    
    suspend fun updateForm(form: FormEntity) = formDao.updateForm(form)
    
    suspend fun deleteForm(id: String) = formDao.deleteForm(id)
    
    private suspend fun getFormCount(): Int = formDao.getFormCount()
    
    suspend fun isFormsDataInitialized(): Boolean = getFormCount() > 0
}