package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.repository.FormEntryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify
import org.mockito.MockitoAnnotations

@ExperimentalCoroutinesApi
class GetEntryByIdUseCaseTest {

    @Mock
    private lateinit var mockFormEntryRepository: FormEntryRepository

    private lateinit var useCase: GetEntryByIdUseCase


    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        useCase = GetEntryByIdUseCase(mockFormEntryRepository)
    }

    @Test
    fun invoke_withExistingEntryId_returnsEntry() = runTest {
        // Given
        val entryId = "existing-entry"
        val expectedEntry = TestDataFactory.createTestFormEntry(entryId, "form1")
        `when`(mockFormEntryRepository.getEntryById(entryId)).thenReturn(flowOf(expectedEntry))

        // When
        val result = useCase.invoke(entryId).first()

        // Then
        assertEquals(expectedEntry, result)
        verify(mockFormEntryRepository).getEntryById(entryId)
    }

    @Test
    fun invoke_withNonExistingEntryId_returnsNull() = runTest {
        // Given
        val entryId = "non-existing-entry"
        `when`(mockFormEntryRepository.getEntryById(entryId)).thenReturn(flowOf(null))

        // When
        val result = useCase.invoke(entryId).first()

        // Then
        assertNull(result)
        verify(mockFormEntryRepository).getEntryById(entryId)
    }
}