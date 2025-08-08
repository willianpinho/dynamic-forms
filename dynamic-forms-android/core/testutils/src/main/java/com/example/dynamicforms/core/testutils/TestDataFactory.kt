package com.example.dynamicforms.core.testutils

import com.example.dynamicforms.data.local.entity.FormEntity
import com.example.dynamicforms.data.local.entity.FormEntryEntity
import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.model.FieldOption
import com.example.dynamicforms.domain.model.FieldType
import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.model.FormField
import com.example.dynamicforms.domain.model.FormSection

object TestDataFactory {
    
    fun createTestFormField(
        uuid: String = "test-field-uuid",
        type: FieldType = FieldType.TEXT,
        label: String = "Test Field",
        required: Boolean = false,
        options: List<FieldOption> = emptyList()
    ) = FormField(
        uuid = uuid,
        type = type,
        name = "test_field",
        label = label,
        required = required,
        options = options
    )
    
    fun createTestFormSection(
        uuid: String = "test-section-uuid",
        title: String = "Test Section",
        from: Int = 0,
        to: Int = 0,
        fields: List<FormField> = emptyList()
    ) = FormSection(
        uuid = uuid,
        title = title,
        from = from,
        to = to,
        index = 0,
        fields = fields
    )
    
    fun createTestDynamicForm(
        id: String = "test-form-id",
        title: String = "Test Form",
        fields: List<FormField> = listOf(createTestFormField()),
        sections: List<FormSection> = emptyList()
    ) = DynamicForm(
        id = id,
        title = title,
        fields = fields,
        sections = sections,
        createdAt = 1000L,
        updatedAt = 1000L
    )
    
    fun createTestFormEntry(
        id: String = "test-entry-id",
        formId: String = "test-form-id",
        fieldValues: Map<String, String> = mapOf("test-field-uuid" to "test value"),
        isComplete: Boolean = false,
        isDraft: Boolean = true
    ) = FormEntry(
        id = id,
        formId = formId,
        fieldValues = fieldValues,
        createdAt = 1000L,
        updatedAt = 1000L,
        isComplete = isComplete,
        isDraft = isDraft
    )
    
    fun createTestFormEntity(
        id: String = "test-form-id",
        title: String = "Test Form"
    ) = FormEntity(
        id = id,
        title = title,
        fieldsJson = """[{"uuid":"test-field-uuid","type":"text","name":"test_field","label":"Test Field","required":false}]""",
        sectionsJson = "[]",
        createdAt = 1000L,
        updatedAt = 1000L
    )
    
    fun createTestFormEntryEntity(
        id: String = "test-entry-id",
        formId: String = "test-form-id",
        isDraft: Boolean = true
    ) = FormEntryEntity(
        id = id,
        formId = formId,
        fieldValuesJson = """{"test-field-uuid":"test value"}""",
        createdAt = 1000L,
        updatedAt = 1000L,
        isComplete = !isDraft,
        isDraft = isDraft
    )
}