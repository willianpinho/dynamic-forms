package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.utils.validators.FieldValidator
import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.model.FormField
import javax.inject.Inject

data class ValidationError(
    val fieldUuid: String,
    val message: String
)

class ValidateFormEntryUseCase @Inject constructor() {
    
    operator fun invoke(form: DynamicForm, entry: FormEntry): List<ValidationError> {
        val errors = mutableListOf<ValidationError>()
        
        form.fields.forEach { field ->
            val value = entry.getValueForField(field.uuid)
            val validationResult = validateField(field, value)
            
            if (!validationResult.isValid) {
                val errorMessage = validationResult.errorMessage
                if (errorMessage != null) {
                    errors.add(ValidationError(field.uuid, errorMessage))
                }
            }
        }
        
        return errors
    }
    
    private fun validateField(field: FormField, value: String) = 
        FieldValidator.validateField(
            value = value,
            fieldType = field.type.name,
            isRequired = field.required,
            options = field.options.map { it.value },
            fieldName = field.label
        )
}