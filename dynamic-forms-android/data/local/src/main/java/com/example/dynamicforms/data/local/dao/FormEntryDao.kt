package com.example.dynamicforms.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.dynamicforms.data.local.entity.FormEntryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface FormEntryDao {
    
    @Query("SELECT * FROM form_entries WHERE formId = :formId ORDER BY updatedAt DESC")
    fun getEntriesForForm(formId: String): Flow<List<FormEntryEntity>>
    
    @Query("SELECT * FROM form_entries WHERE formId = :formId AND isDraft = 0 ORDER BY updatedAt DESC")
    fun getSubmittedEntriesForForm(formId: String): Flow<List<FormEntryEntity>>
    
    @Query("SELECT * FROM form_entries WHERE id = :id")
    fun getEntryById(id: String): Flow<FormEntryEntity?>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: FormEntryEntity): Long
    
    @Update
    suspend fun updateEntry(entry: FormEntryEntity)
    
    @Query("DELETE FROM form_entries WHERE id = :id")
    suspend fun deleteEntry(id: String)
    
    @Query("SELECT * FROM form_entries WHERE formId = :formId AND isDraft = 1 ORDER BY updatedAt DESC LIMIT 1")
    fun getDraftEntry(formId: String): Flow<FormEntryEntity?>
    
    @Query("DELETE FROM form_entries WHERE formId = :formId AND isDraft = 1")
    suspend fun deleteDraftEntry(formId: String)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveDraftEntry(entry: FormEntryEntity)
    
    @Query("DELETE FROM form_entries WHERE formId = :formId AND isDraft = 1 AND id != :currentEntryId")
    suspend fun cleanOldDrafts(formId: String, currentEntryId: String)
    
    // New queries for draft linking
    @Query("SELECT * FROM form_entries WHERE formId = :formId AND isDraft = 1 AND sourceEntryId IS NULL ORDER BY updatedAt DESC LIMIT 1")
    fun getNewDraftEntry(formId: String): Flow<FormEntryEntity?>
    
    @Query("SELECT * FROM form_entries WHERE sourceEntryId = :entryId AND isDraft = 1 ORDER BY updatedAt DESC LIMIT 1")
    fun getEditDraftForEntry(entryId: String): Flow<FormEntryEntity?>
    
    @Query("SELECT * FROM form_entries WHERE formId = :formId AND isDraft = 1 ORDER BY updatedAt DESC")
    fun getAllDraftsForForm(formId: String): Flow<List<FormEntryEntity>>
    
    @Query("DELETE FROM form_entries WHERE sourceEntryId = :entryId AND isDraft = 1")
    suspend fun deleteEditDraftsForEntry(entryId: String)
    
    @Query("DELETE FROM form_entries WHERE formId = :formId AND isDraft = 1 AND sourceEntryId IS NULL")
    suspend fun deleteNewDraftsForForm(formId: String)
    
    @Query("SELECT COUNT(*) FROM form_entries WHERE formId = :formId AND isDraft = 0")
    suspend fun getEntryCountForForm(formId: String): Int
}