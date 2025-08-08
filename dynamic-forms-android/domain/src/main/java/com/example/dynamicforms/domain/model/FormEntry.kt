package com.example.dynamicforms.domain.model

data class FormEntry(
    val id: String,
    val formId: String,
    val sourceEntryId: String? = null, // ID of the original entry this draft is based on (for edit drafts)
    val fieldValues: Map<String, String>, // fieldUuid -> value
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isComplete: Boolean = false,
    val isDraft: Boolean = true
) {
    fun getValueForField(fieldUuid: String): String {
        return fieldValues[fieldUuid] ?: ""
    }
    
    fun updateFieldValue(fieldUuid: String, value: String): FormEntry {
        val updatedValues = fieldValues.toMutableMap()
        updatedValues[fieldUuid] = value
        
        return copy(
            fieldValues = updatedValues,
            updatedAt = System.currentTimeMillis(),
            isDraft = true
        )
    }
    
    fun markAsComplete(): FormEntry {
        return copy(
            isComplete = true,
            isDraft = false,
            updatedAt = System.currentTimeMillis()
        )
    }
    
    fun validateAgainstForm(form: DynamicForm): Map<String, String> {
        val errors = mutableMapOf<String, String>()
        
        form.getRequiredFields().forEach { field ->
            val value = getValueForField(field.uuid)
            if (value.isBlank()) {
                errors[field.uuid] = "${field.label} is required"
            }
        }
        
        return errors
    }
    
    /**
     * Determines if this entry is a draft created for editing an existing submitted entry
     */
    fun isEditDraft(): Boolean = isDraft && sourceEntryId != null
    
    /**
     * Determines if this entry is a new draft (not based on an existing entry)
     */
    fun isNewDraft(): Boolean = isDraft && sourceEntryId == null
    
    /**
     * Creates an edit draft based on this entry
     */
    fun createEditDraft(draftId: String = "draft_edit_${id}_${System.currentTimeMillis()}"): FormEntry {
        return copy(
            id = draftId,
            sourceEntryId = this.id,
            isDraft = true,
            isComplete = false,
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis()
        )
    }
}