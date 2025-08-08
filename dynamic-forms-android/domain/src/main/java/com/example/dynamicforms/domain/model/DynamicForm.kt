package com.example.dynamicforms.domain.model

data class DynamicForm(
    val id: String,
    val title: String,
    val fields: List<FormField>,
    val sections: List<FormSection> = emptyList(),
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun getFieldsInSection(section: FormSection): List<FormField> {
        return fields.subList(
            minOf(section.from, fields.size),
            minOf(section.to + 1, fields.size)
        )
    }
    
    fun getFieldByUuid(uuid: String): FormField? {
        return fields.find { it.uuid == uuid }
    }
    
    fun updateFieldValue(fieldUuid: String, value: String): DynamicForm {
        val updatedFields = fields.map { field ->
            if (field.uuid == fieldUuid) {
                field.copy(value = value, validationError = null)
            } else {
                field
            }
        }
        return copy(fields = updatedFields, updatedAt = System.currentTimeMillis())
    }
    
    fun updateFieldValidation(fieldUuid: String, error: String?): DynamicForm {
        val updatedFields = fields.map { field ->
            if (field.uuid == fieldUuid) {
                field.copy(validationError = error)
            } else {
                field
            }
        }
        return copy(fields = updatedFields)
    }
    
    fun isValid(): Boolean {
        return fields.all { it.validationError == null }
    }
    
    fun getRequiredFields(): List<FormField> {
        return fields.filter { it.required }
    }
}