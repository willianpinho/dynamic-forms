package com.example.dynamicforms.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.dynamicforms.data.local.entity.FormEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface FormDao {
    
    @Query("SELECT * FROM forms ORDER BY updatedAt DESC")
    fun getAllForms(): Flow<List<FormEntity>>
    
    @Query("SELECT * FROM forms WHERE id = :id")
    fun getFormById(id: String): Flow<FormEntity?>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertForm(form: FormEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertForms(forms: List<FormEntity>)
    
    @Update
    suspend fun updateForm(form: FormEntity)
    
    @Query("DELETE FROM forms WHERE id = :id")
    suspend fun deleteForm(id: String)
    
    @Query("SELECT COUNT(*) FROM forms")
    suspend fun getFormCount(): Int
    
    @Query("DELETE FROM forms")
    suspend fun deleteAllForms()
}