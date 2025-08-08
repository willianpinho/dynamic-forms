package com.example.dynamicforms.domain.repository

import com.example.dynamicforms.domain.model.FormEntry
import kotlinx.coroutines.flow.Flow

interface FormEntryRepository {
    
    suspend fun getEntriesForForm(formId: String): Flow<List<FormEntry>>
    
    suspend fun getEntryById(id: String): Flow<FormEntry?>
    
    suspend fun insertEntry(entry: FormEntry): Result<String>
    
    suspend fun updateEntry(entry: FormEntry): Result<Unit>
    
    suspend fun deleteEntry(id: String): Result<Unit>
    
    suspend fun saveEntryDraft(entry: FormEntry): Result<Unit>
    
    suspend fun getDraftEntry(formId: String): Flow<FormEntry?>
    
    suspend fun deleteDraftEntry(formId: String): Result<Unit>
    
    // New methods for draft linking
    suspend fun getNewDraftEntry(formId: String): Flow<FormEntry?>
    
    suspend fun getEditDraftForEntry(entryId: String): Flow<FormEntry?>
    
    suspend fun getAllDraftsForForm(formId: String): Flow<List<FormEntry>>
    
    suspend fun deleteEditDraftsForEntry(entryId: String): Result<Unit>
}