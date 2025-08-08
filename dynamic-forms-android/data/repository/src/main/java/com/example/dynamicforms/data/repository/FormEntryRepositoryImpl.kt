package com.example.dynamicforms.data.repository

import com.example.dynamicforms.data.local.datasource.FormEntryLocalDataSource
import com.example.dynamicforms.data.mapper.FormEntryMapper
import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.repository.FormEntryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FormEntryRepositoryImpl @Inject constructor(
    private val localDataSource: FormEntryLocalDataSource,
    private val formEntryMapper: FormEntryMapper
) : FormEntryRepository {
    
    override suspend fun getEntriesForForm(formId: String): Flow<List<FormEntry>> {
        return localDataSource.getEntriesForForm(formId).map { entities ->
            entities.map { formEntryMapper.toDomain(it) }
        }
    }
    
    override suspend fun getEntryById(id: String): Flow<FormEntry?> {
        return localDataSource.getEntryById(id).map { entity ->
            entity?.let { formEntryMapper.toDomain(it) }
        }
    }
    
    override suspend fun insertEntry(entry: FormEntry): Result<String> {
        return try {
            val entity = formEntryMapper.toEntity(entry)
            localDataSource.insertEntry(entity)
            Result.success(entity.id)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun updateEntry(entry: FormEntry): Result<Unit> {
        return try {
            val entity = formEntryMapper.toEntity(entry)
            localDataSource.updateEntry(entity)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun deleteEntry(id: String): Result<Unit> {
        return try {
            localDataSource.deleteEntry(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun saveEntryDraft(entry: FormEntry): Result<Unit> {
        return try {
            val draftEntry = entry.copy(isDraft = true)
            val entity = formEntryMapper.toEntity(draftEntry)
            localDataSource.saveDraftEntry(entity)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun getDraftEntry(formId: String): Flow<FormEntry?> {
        return localDataSource.getDraftEntry(formId).map { entity ->
            entity?.let { formEntryMapper.toDomain(it) }
        }
    }
    
    override suspend fun deleteDraftEntry(formId: String): Result<Unit> {
        return try {
            localDataSource.deleteDraftEntry(formId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // New methods for draft linking
    override suspend fun getNewDraftEntry(formId: String): Flow<FormEntry?> {
        return localDataSource.getNewDraftEntry(formId).map { entity ->
            entity?.let { formEntryMapper.toDomain(it) }
        }
    }
    
    override suspend fun getEditDraftForEntry(entryId: String): Flow<FormEntry?> {
        return localDataSource.getEditDraftForEntry(entryId).map { entity ->
            entity?.let { formEntryMapper.toDomain(it) }
        }
    }
    
    override suspend fun getAllDraftsForForm(formId: String): Flow<List<FormEntry>> {
        return localDataSource.getAllDraftsForForm(formId).map { entities ->
            entities.map { formEntryMapper.toDomain(it) }
        }
    }
    
    override suspend fun deleteEditDraftsForEntry(entryId: String): Result<Unit> {
        return try {
            localDataSource.deleteEditDraftsForEntry(entryId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}