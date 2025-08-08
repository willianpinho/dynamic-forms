package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.repository.FormRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify
import org.mockito.MockitoAnnotations

@ExperimentalCoroutinesApi
class GetAllFormsUseCaseTest {

    @Mock
    private lateinit var mockFormRepository: FormRepository

    private lateinit var useCase: GetAllFormsUseCase

    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        useCase = GetAllFormsUseCase(mockFormRepository)
    }

    @Test
    fun invoke_delegatesToRepository() = runTest {
        // Given
        val expectedForms = listOf(
            TestDataFactory.createTestDynamicForm("form1", "Form 1"),
            TestDataFactory.createTestDynamicForm("form2", "Form 2")
        )
        `when`(mockFormRepository.getAllForms()).thenReturn(flowOf(expectedForms))

        // When
        val flow = useCase.invoke()
        val result = flow.first()

        // Then
        assertEquals(expectedForms, result)
        verify(mockFormRepository).getAllForms()
    }

    @Test
    fun invoke_returnsEmptyListWhenRepositoryReturnsEmpty() = runTest {
        // Given
        `when`(mockFormRepository.getAllForms()).thenReturn(flowOf(emptyList()))

        // When
        val flow = useCase.invoke()
        val result = flow.first()

        // Then
        assertEquals(emptyList<Any>(), result)
        verify(mockFormRepository).getAllForms()
    }
}