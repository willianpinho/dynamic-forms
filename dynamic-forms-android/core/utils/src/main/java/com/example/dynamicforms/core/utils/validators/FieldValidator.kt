package com.example.dynamicforms.core.utils.validators

import com.example.dynamicforms.core.utils.extensions.isValidEmail
import com.example.dynamicforms.core.utils.extensions.isValidNumber

data class ValidationResult(
    val isValid: Boolean,
    val errorMessage: String? = null
)

object FieldValidator {
    
    private fun validateRequired(value: String?, fieldName: String = "Field"): ValidationResult {
        return if (value.isNullOrBlank()) {
            ValidationResult(false, "$fieldName is required")
        } else {
            ValidationResult(true)
        }
    }
    
    fun validateEmail(value: String?): ValidationResult {
        return if (value.isNullOrBlank()) {
            ValidationResult(true) // Empty is valid for non-required fields
        } else if (!value.isValidEmail()) {
            ValidationResult(false, "Please enter a valid email address")
        } else {
            ValidationResult(true)
        }
    }
    
    private fun validateNumber(value: String?): ValidationResult {
        return if (value.isNullOrBlank()) {
            ValidationResult(true) // Empty is valid for non-required fields
        } else if (!value.isValidNumber()) {
            ValidationResult(false, "Please enter a valid number")
        } else {
            ValidationResult(true)
        }
    }
    
    private fun validateMinLength(value: String?, minLength: Int): ValidationResult {
        return if (value != null && value.length < minLength) {
            ValidationResult(false, "Must be at least $minLength characters")
        } else {
            ValidationResult(true)
        }
    }
    
    private fun validateMaxLength(value: String?, maxLength: Int): ValidationResult {
        return if (value != null && value.length > maxLength) {
            ValidationResult(false, "Must be no more than $maxLength characters")
        } else {
            ValidationResult(true)
        }
    }
    
    private fun validateDropdownSelection(
        value: String?, 
        options: List<String>
    ): ValidationResult {
        return if (value.isNullOrBlank()) {
            ValidationResult(true) // Empty is valid for non-required fields
        } else if (!options.contains(value)) {
            ValidationResult(false, "Please select a valid option")
        } else {
            ValidationResult(true)
        }
    }
    
    fun validateField(
        value: String?,
        fieldType: String,
        isRequired: Boolean,
        options: List<String>? = null,
        minLength: Int? = null,
        maxLength: Int? = null,
        fieldName: String = "Field"
    ): ValidationResult {
        // Check required validation first
        if (isRequired) {
            val requiredResult = validateRequired(value, fieldName)
            if (!requiredResult.isValid) return requiredResult
        }
        
        // If field is empty and not required, it's valid
        if (value.isNullOrBlank() && !isRequired) {
            return ValidationResult(true)
        }
        
        // Type-specific validation - only for supported types
        val typeResult = when (fieldType.lowercase()) {
            "number" -> validateNumber(value)
            "dropdown" -> if (options != null) validateDropdownSelection(value, options) else ValidationResult(true)
            "text", "description" -> ValidationResult(true) // Text and description need no special validation
            else -> ValidationResult(true) // All other types are treated as text
        }
        
        if (!typeResult.isValid) return typeResult
        
        // Length validation
        minLength?.let { min ->
            val minResult = validateMinLength(value, min)
            if (!minResult.isValid) return minResult
        }
        
        maxLength?.let { max ->
            val maxResult = validateMaxLength(value, max)
            if (!maxResult.isValid) return maxResult
        }
        
        return ValidationResult(true)
    }
}