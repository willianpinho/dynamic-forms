package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.repository.FormRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify
import org.mockito.MockitoAnnotations

@ExperimentalCoroutinesApi
class GetFormByIdUseCaseTest {

    @Mock
    private lateinit var mockFormRepository: FormRepository

    private lateinit var useCase: GetFormByIdUseCase

    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        useCase = GetFormByIdUseCase(mockFormRepository)
    }

    @Test
    fun invoke_withExistingFormId_returnsForm() = runTest {
        // Given
        val formId = "existing-form"
        val expectedForm = TestDataFactory.createTestDynamicForm(formId, "Existing Form")
        `when`(mockFormRepository.getFormById(formId)).thenReturn(flowOf(expectedForm))

        // When
        val result = useCase.invoke(formId).first()

        // Then
        assertEquals(expectedForm, result)
        verify(mockFormRepository).getFormById(formId)
    }

    @Test
    fun invoke_withNonExistingFormId_returnsNull() = runTest {
        // Given
        val formId = "non-existing-form"
        `when`(mockFormRepository.getFormById(formId)).thenReturn(flowOf(null))

        // When
        val result = useCase.invoke(formId).first()

        // Then
        assertNull(result)
        verify(mockFormRepository).getFormById(formId)
    }
}