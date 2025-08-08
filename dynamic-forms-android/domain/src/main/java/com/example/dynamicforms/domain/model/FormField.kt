package com.example.dynamicforms.domain.model

data class FormField(
    val uuid: String,
    val type: FieldType,
    val name: String,
    val label: String,
    val required: Boolean = false,
    val options: List<FieldOption> = emptyList(),
    val value: String = "",
    val validationError: String? = null
)

enum class FieldType {
    TEXT,
    NUMBER,
    DROPDOWN,
    DESCRIPTION;
    
    companion object {
        fun fromString(type: String): FieldType {
            return when (type.lowercase()) {
                "text" -> TEXT
                "number" -> NUMBER
                "dropdown" -> DROPDOWN
                "description" -> DESCRIPTION
                else -> TEXT // All unsupported types become TEXT
            }
        }
    }
}

data class FieldOption(
    val label: String,
    val value: String
)