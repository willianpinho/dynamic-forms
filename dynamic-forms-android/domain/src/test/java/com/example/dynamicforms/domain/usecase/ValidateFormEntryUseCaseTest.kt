package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.model.FieldType
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class ValidateFormEntryUseCaseTest {

    private lateinit var useCase: ValidateFormEntryUseCase

    @Before
    fun setUp() {
        useCase = ValidateFormEntryUseCase()
    }

    @Test
    fun invoke_withValidEntry_returnsEmptyErrorList() {
        // Given
        val requiredField = TestDataFactory.createTestFormField(
            uuid = "required-field",
            label = "Required Field",
            required = true
        )
        val optionalField = TestDataFactory.createTestFormField(
            uuid = "optional-field",
            label = "Optional Field",
            required = false
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(requiredField, optionalField)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = mapOf(
                "required-field" to "Valid value",
                "optional-field" to ""  // Optional can be empty
            )
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertTrue(errors.isEmpty())
    }

    @Test
    fun invoke_withMissingRequiredField_returnsValidationError() {
        // Given
        val requiredField = TestDataFactory.createTestFormField(
            uuid = "required-field",
            label = "Required Field",
            required = true
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(requiredField)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = mapOf("required-field" to "")  // Empty required field
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertEquals(1, errors.size)
        assertEquals("required-field", errors[0].fieldUuid)
        assertTrue(errors[0].message.contains("required", ignoreCase = true))
    }

    @Test
    fun invoke_withMultipleValidationErrors_returnsAllErrors() {
        // Given
        val requiredField1 = TestDataFactory.createTestFormField(
            uuid = "required-1",
            label = "Required Field 1",
            required = true
        )
        val requiredField2 = TestDataFactory.createTestFormField(
            uuid = "required-2",
            label = "Required Field 2",
            required = true
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(requiredField1, requiredField2)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = mapOf(
                "required-1" to "",  // Empty required field
                "required-2" to ""   // Empty required field
            )
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertEquals(2, errors.size)
        assertTrue(errors.any { it.fieldUuid == "required-1" })
        assertTrue(errors.any { it.fieldUuid == "required-2" })
    }

    @Test
    fun invoke_withTextFieldValidation_returnsErrorForRequired() {
        // Given
        val textField = TestDataFactory.createTestFormField(
            uuid = "text-field",
            type = FieldType.TEXT,
            label = "Text Field",
            required = true
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(textField)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = mapOf("text-field" to "")
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertEquals(1, errors.size)
        assertEquals("text-field", errors[0].fieldUuid)
        assertTrue(errors[0].message.contains("required", ignoreCase = true))
    }

    @Test
    fun invoke_withNumberFieldValidation_returnsErrorForInvalidNumber() {
        // Given
        val numberField = TestDataFactory.createTestFormField(
            uuid = "number-field",
            type = FieldType.NUMBER,
            label = "Number Field",
            required = true
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(numberField)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = mapOf("number-field" to "not-a-number")
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertEquals(1, errors.size)
        assertEquals("number-field", errors[0].fieldUuid)
        assertTrue(errors[0].message.contains("number", ignoreCase = true))
    }

    @Test
    fun invoke_withFieldNotInEntry_treatsAsEmptyValue() {
        // Given
        val requiredField = TestDataFactory.createTestFormField(
            uuid = "missing-field",
            label = "Missing Field",
            required = true
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(requiredField)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = emptyMap()  // Field not present in entry
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertEquals(1, errors.size)
        assertEquals("missing-field", errors[0].fieldUuid)
        assertTrue(errors[0].message.contains("required", ignoreCase = true))
    }

    @Test
    fun invoke_withValidTextAndNumber_returnsNoErrors() {
        // Given
        val textField = TestDataFactory.createTestFormField(
            uuid = "text-field",
            type = FieldType.TEXT,
            label = "Text Field",
            required = true
        )
        val numberField = TestDataFactory.createTestFormField(
            uuid = "number-field",
            type = FieldType.NUMBER,
            label = "Number Field",
            required = true
        )
        val form = TestDataFactory.createTestDynamicForm(
            fields = listOf(textField, numberField)
        )
        val entry = TestDataFactory.createTestFormEntry(
            fieldValues = mapOf(
                "text-field" to "valid text",
                "number-field" to "123.45"
            )
        )

        // When
        val errors = useCase.invoke(form, entry)

        // Then
        assertTrue(errors.isEmpty())
    }
}