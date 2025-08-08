package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.repository.FormEntryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify
import org.mockito.MockitoAnnotations

@ExperimentalCoroutinesApi
class GetFormEntriesUseCaseTest {

    @Mock
    private lateinit var mockFormEntryRepository: FormEntryRepository

    private lateinit var useCase: GetFormEntriesUseCase


    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        useCase = GetFormEntriesUseCase(mockFormEntryRepository)
    }

    @Test
    fun invoke_delegatesToRepository() = runTest {
        // Given
        val formId = "test-form-id"
        val expectedEntries = listOf(
            TestDataFactory.createTestFormEntry("entry1", formId),
            TestDataFactory.createTestFormEntry("entry2", formId)
        )
        `when`(mockFormEntryRepository.getEntriesForForm(formId)).thenReturn(flowOf(expectedEntries))

        // When
        val result = useCase.invoke(formId).first()

        // Then
        assertEquals(expectedEntries, result)
        verify(mockFormEntryRepository).getEntriesForForm(formId)
    }

    @Test
    fun invoke_returnsEmptyListWhenRepositoryReturnsEmpty() = runTest {
        // Given
        val formId = "empty-form-id"
        `when`(mockFormEntryRepository.getEntriesForForm(formId)).thenReturn(flowOf(emptyList()))

        // When
        val result = useCase.invoke(formId).first()

        // Then
        assertEquals(emptyList<Any>(), result)
        verify(mockFormEntryRepository).getEntriesForForm(formId)
    }
}