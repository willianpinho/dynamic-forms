package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.repository.FormEntryRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mockito.`when`
import org.mockito.kotlin.*

@ExperimentalCoroutinesApi
class AutoSaveFormEntryUseCaseTest {

    private val mockFormEntryRepository: FormEntryRepository = mock()
    private val useCase = AutoSaveFormEntryUseCase(mockFormEntryRepository)

    @Before
    fun setUp() {
        // Reset mocks before each test
        reset(mockFormEntryRepository)
    }

    @Test
    fun invoke_success_returnsSuccessResult() = runTest {
        // Given
        val draftEntry = TestDataFactory.createTestFormEntry(
            id = "draft-id",
            formId = "form1",
            isDraft = true
        )

        `when`(mockFormEntryRepository.saveEntryDraft(draftEntry)).thenReturn(Result.success(Unit))

        // When
        val result = useCase.invoke(draftEntry)

        // Then
        assertTrue(result.isSuccess)
        verify(mockFormEntryRepository).saveEntryDraft(draftEntry)
    }

    @Test
    fun invoke_failure_returnsFailureResult() = runTest {
        // Given
        val draftEntry = TestDataFactory.createTestFormEntry(
            id = "draft-id",
            formId = "form1",
            isDraft = true
        )
        val expectedException = RuntimeException("Auto-save failed")

        `when`(mockFormEntryRepository.saveEntryDraft(draftEntry)).thenReturn(Result.failure(expectedException))

        // When
        val result = useCase.invoke(draftEntry)

        // Then
        assertTrue(result.isFailure)
        assertEquals(expectedException, result.exceptionOrNull())
        verify(mockFormEntryRepository).saveEntryDraft(draftEntry)
    }

    @Test
    fun invoke_whenRepositoryThrowsException_returnsFailure() = runTest {
        // Given
        val draftEntry = TestDataFactory.createTestFormEntry(
            id = "draft-id",
            formId = "form1",
            isDraft = true
        )
        val expectedException = RuntimeException("Unexpected error")

        `when`(mockFormEntryRepository.saveEntryDraft(draftEntry)).thenThrow(expectedException)

        // When
        val result = useCase.invoke(draftEntry)

        // Then
        assertTrue(result.isFailure)
        assertEquals(expectedException, result.exceptionOrNull())
        verify(mockFormEntryRepository).saveEntryDraft(draftEntry)
    }

    @Test
    fun invoke_passesCorrectParametersToRepository() = runTest {
        // Given
        val specificEntry = TestDataFactory.createTestFormEntry(
            id = "specific-id",
            formId = "specific-form",
            fieldValues = mapOf("field1" to "value1", "field2" to "value2"),
            isDraft = true
        )

        `when`(mockFormEntryRepository.saveEntryDraft(any())).thenReturn(Result.success(Unit))

        // When
        val result = useCase.invoke(specificEntry)

        // Then
        assertTrue(result.isSuccess)
        verify(mockFormEntryRepository).saveEntryDraft(specificEntry)
    }
}