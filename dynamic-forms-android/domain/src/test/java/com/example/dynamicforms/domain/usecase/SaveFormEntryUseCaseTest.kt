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
class SaveFormEntryUseCaseTest {

    private val mockFormEntryRepository: FormEntryRepository = mock()
    private val useCase = SaveFormEntryUseCase(mockFormEntryRepository)

    @Before
    fun setUp() {
        // Reset mocks before each test
        reset(mockFormEntryRepository)
    }

    @Test
    fun invoke_withNewEntryAsDraft_insertsEntry() = runTest {
        // Given
        val newEntry = TestDataFactory.createTestFormEntry(
            id = "",  // New entry has empty ID
            formId = "form1",
            isDraft = true
        )
        val expectedEntryId = "generated-id"

        `when`(mockFormEntryRepository.insertEntry(any())).thenReturn(Result.success(expectedEntryId))

        // When
        val result = useCase.invoke(newEntry, isComplete = false)

        // Then
        assertTrue(result.isSuccess)
        assertEquals(expectedEntryId, result.getOrThrow())
        verify(mockFormEntryRepository).insertEntry(argThat { entry ->
            entry.isDraft && !entry.isComplete
        })
        verify(mockFormEntryRepository, never()).updateEntry(any())
    }

    @Test
    fun invoke_withNewEntryAsComplete_insertsCompleteEntry() = runTest {
        // Given
        val newEntry = TestDataFactory.createTestFormEntry(
            id = "",  // New entry has empty ID
            formId = "form1",
            isDraft = true
        )
        val expectedEntryId = "generated-id"

        `when`(mockFormEntryRepository.insertEntry(any())).thenReturn(Result.success(expectedEntryId))

        // When
        val result = useCase.invoke(newEntry, isComplete = true)

        // Then
        assertTrue(result.isSuccess)
        assertEquals(expectedEntryId, result.getOrThrow())
        verify(mockFormEntryRepository).insertEntry(argThat { entry ->
            !entry.isDraft && entry.isComplete
        })
        verify(mockFormEntryRepository, never()).updateEntry(any())
    }

    @Test
    fun invoke_withExistingEntryAsDraft_updatesEntry() = runTest {
        // Given
        val existingEntry = TestDataFactory.createTestFormEntry(
            id = "existing-id",
            formId = "form1",
            isDraft = true
        )

        `when`(mockFormEntryRepository.updateEntry(any())).thenReturn(Result.success(Unit))

        // When
        val result = useCase.invoke(existingEntry, isComplete = false)

        // Then
        assertTrue(result.isSuccess)
        assertEquals("existing-id", result.getOrThrow())
        verify(mockFormEntryRepository).updateEntry(argThat { entry ->
            entry.id == "existing-id" && entry.isDraft && !entry.isComplete
        })
        verify(mockFormEntryRepository, never()).insertEntry(any())
    }

    @Test
    fun invoke_withExistingEntryAsComplete_updatesCompleteEntry() = runTest {
        // Given
        val existingEntry = TestDataFactory.createTestFormEntry(
            id = "existing-id",
            formId = "form1",
            isDraft = true
        )

        `when`(mockFormEntryRepository.updateEntry(any())).thenReturn(Result.success(Unit))

        // When
        val result = useCase.invoke(existingEntry, isComplete = true)

        // Then
        assertTrue(result.isSuccess)
        assertEquals("existing-id", result.getOrThrow())
        verify(mockFormEntryRepository).updateEntry(argThat { entry ->
            entry.id == "existing-id" && !entry.isDraft && entry.isComplete
        })
        verify(mockFormEntryRepository, never()).insertEntry(any())
    }

    @Test
    fun invoke_whenInsertFails_returnsFailure() = runTest {
        // Given
        val newEntry = TestDataFactory.createTestFormEntry(id = "", formId = "form1")
        val expectedException = RuntimeException("Insert failed")

        `when`(mockFormEntryRepository.insertEntry(any())).thenReturn(Result.failure(expectedException))

        // When
        val result = useCase.invoke(newEntry, isComplete = false)

        // Then
        assertTrue(result.isFailure)
        assertEquals(expectedException, result.exceptionOrNull())
        verify(mockFormEntryRepository).insertEntry(any())
        verify(mockFormEntryRepository, never()).updateEntry(any())
    }

    @Test
    fun invoke_whenUpdateFails_returnsFailure() = runTest {
        // Given
        val existingEntry = TestDataFactory.createTestFormEntry(id = "existing-id", formId = "form1")
        val expectedException = RuntimeException("Update failed")

        `when`(mockFormEntryRepository.updateEntry(any())).thenReturn(Result.failure(expectedException))

        // When
        val result = useCase.invoke(existingEntry, isComplete = false)

        // Then
        assertTrue(result.isFailure)
        assertEquals(expectedException, result.exceptionOrNull())
        verify(mockFormEntryRepository).updateEntry(any())
        verify(mockFormEntryRepository, never()).insertEntry(any())
    }

    @Test
    fun invoke_whenRepositoryThrowsException_returnsFailure() = runTest {
        // Given
        val newEntry = TestDataFactory.createTestFormEntry(id = "", formId = "form1")
        val expectedException = RuntimeException("Unexpected error")

        `when`(mockFormEntryRepository.insertEntry(any())).thenThrow(expectedException)

        // When
        val result = useCase.invoke(newEntry, isComplete = false)

        // Then
        assertTrue(result.isFailure)
        assertEquals(expectedException, result.exceptionOrNull())
    }
}