package com.example.dynamicforms.data.local.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import android.content.Context
import com.example.dynamicforms.data.local.dao.FormDao
import com.example.dynamicforms.data.local.dao.FormEntryDao
import com.example.dynamicforms.data.local.entity.FormEntity
import com.example.dynamicforms.data.local.entity.FormEntryEntity

@Database(
    entities = [FormEntity::class, FormEntryEntity::class],
    version = 2,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class DynamicFormsDatabase : RoomDatabase() {
    
    abstract fun formDao(): FormDao
    abstract fun formEntryDao(): FormEntryDao
    
    companion object {
        private const val DATABASE_NAME = "dynamic_forms_database"
        
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // Add sourceEntryId column to form_entries table
                database.execSQL("""
                    ALTER TABLE form_entries 
                    ADD COLUMN sourceEntryId TEXT DEFAULT NULL
                """.trimIndent())
                
                // Create indices for better performance
                database.execSQL("""
                    CREATE INDEX IF NOT EXISTS index_form_entries_sourceEntryId 
                    ON form_entries(sourceEntryId)
                """.trimIndent())
                
                database.execSQL("""
                    CREATE INDEX IF NOT EXISTS index_form_entries_formId_isDraft 
                    ON form_entries(formId, isDraft)
                """.trimIndent())
                
                database.execSQL("""
                    CREATE INDEX IF NOT EXISTS index_form_entries_sourceEntryId_isDraft 
                    ON form_entries(sourceEntryId, isDraft)
                """.trimIndent())
            }
        }
        
        fun create(context: Context): DynamicFormsDatabase {
            return Room.databaseBuilder(
                context.applicationContext,
                DynamicFormsDatabase::class.java,
                DATABASE_NAME
            )
            .addMigrations(MIGRATION_1_2)
            .build()
        }
    }
}