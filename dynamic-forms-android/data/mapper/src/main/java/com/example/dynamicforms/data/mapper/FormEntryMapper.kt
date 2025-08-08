package com.example.dynamicforms.data.mapper

import com.example.dynamicforms.data.local.entity.FormEntryEntity
import com.example.dynamicforms.domain.model.FormEntry
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FormEntryMapper @Inject constructor() {
    
    private val gson = Gson()
    
    fun toDomain(entity: FormEntryEntity): FormEntry {
        val fieldValues = parseFieldValues(entity.fieldValuesJson)
        
        return FormEntry(
            id = entity.id,
            formId = entity.formId,
            sourceEntryId = entity.sourceEntryId,
            fieldValues = fieldValues,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt,
            isComplete = entity.isComplete,
            isDraft = entity.isDraft
        )
    }
    
    fun toEntity(domain: FormEntry): FormEntryEntity {
        val id = domain.id.ifEmpty {
            UUID.randomUUID().toString()
        }
        
        return FormEntryEntity(
            id = id,
            formId = domain.formId,
            sourceEntryId = domain.sourceEntryId,
            fieldValuesJson = serializeFieldValues(domain.fieldValues),
            createdAt = domain.createdAt,
            updatedAt = domain.updatedAt,
            isComplete = domain.isComplete,
            isDraft = domain.isDraft
        )
    }
    
    fun createNewEntry(formId: String): FormEntry {
        return FormEntry(
            id = "", // Will be generated when saving
            formId = formId,
            fieldValues = emptyMap(),
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis(),
            isComplete = false,
            isDraft = true
        )
    }
    
    private fun parseFieldValues(fieldValuesJson: String): Map<String, String> {
        if (fieldValuesJson.isEmpty()) return emptyMap()
        
        val type = object : TypeToken<Map<String, String>>() {}.type
        return gson.fromJson(fieldValuesJson, type) ?: emptyMap()
    }
    
    private fun serializeFieldValues(fieldValues: Map<String, String>): String {
        return gson.toJson(fieldValues)
    }
}