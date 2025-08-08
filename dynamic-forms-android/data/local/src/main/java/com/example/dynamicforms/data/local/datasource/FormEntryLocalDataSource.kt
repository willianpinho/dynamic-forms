package com.example.dynamicforms.data.local.datasource

import com.example.dynamicforms.data.local.dao.FormEntryDao
import com.example.dynamicforms.data.local.entity.FormEntryEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FormEntryLocalDataSource @Inject constructor(
    private val formEntryDao: FormEntryDao
) {
    fun getEntriesForForm(formId: String): Flow<List<FormEntryEntity>> = 
        formEntryDao.getEntriesForForm(formId)
        
    fun getSubmittedEntriesForForm(formId: String): Flow<List<FormEntryEntity>> = 
        formEntryDao.getSubmittedEntriesForForm(formId)
    
    fun getEntryById(id: String): Flow<FormEntryEntity?> = 
        formEntryDao.getEntryById(id)
    
    suspend fun insertEntry(entry: FormEntryEntity): Long = 
        formEntryDao.insertEntry(entry)
    
    suspend fun updateEntry(entry: FormEntryEntity) = 
        formEntryDao.updateEntry(entry)
    
    suspend fun deleteEntry(id: String) = 
        formEntryDao.deleteEntry(id)
    
    fun getDraftEntry(formId: String): Flow<FormEntryEntity?> = 
        formEntryDao.getDraftEntry(formId)
    
    suspend fun deleteDraftEntry(formId: String) = 
        formEntryDao.deleteDraftEntry(formId)
    
    suspend fun saveDraftEntry(entry: FormEntryEntity) {
        if (entry.sourceEntryId != null) {
            // This is an edit draft - use intelligent cleanup
            saveEditDraftEntry(entry)
        } else {
            // This is a new draft - use traditional cleanup
            saveNewDraftEntry(entry)
        }
    }
    
    private suspend fun saveEditDraftEntry(entry: FormEntryEntity) {
        // Save the edit draft
        formEntryDao.saveDraftEntry(entry)
        // Only clean other edit drafts for the same source entry, preserve new drafts
        formEntryDao.deleteEditDraftsForEntry(entry.sourceEntryId!!)
        formEntryDao.saveDraftEntry(entry) // Re-insert after cleanup
    }
    
    private suspend fun saveNewDraftEntry(entry: FormEntryEntity) {
        // Save the new draft
        formEntryDao.saveDraftEntry(entry)
        // Clean old new drafts to keep only the latest one, preserve edit drafts
        formEntryDao.deleteNewDraftsForForm(entry.formId)
        formEntryDao.saveDraftEntry(entry) // Re-insert after cleanup
    }
    
    // New methods for draft linking
    fun getNewDraftEntry(formId: String): Flow<FormEntryEntity?> = 
        formEntryDao.getNewDraftEntry(formId)
        
    fun getEditDraftForEntry(entryId: String): Flow<FormEntryEntity?> = 
        formEntryDao.getEditDraftForEntry(entryId)
        
    fun getAllDraftsForForm(formId: String): Flow<List<FormEntryEntity>> = 
        formEntryDao.getAllDraftsForForm(formId)
        
    suspend fun deleteEditDraftsForEntry(entryId: String) = 
        formEntryDao.deleteEditDraftsForEntry(entryId)
    
    suspend fun getEntryCountForForm(formId: String): Int = 
        formEntryDao.getEntryCountForForm(formId)
}