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
class GetDraftEntryUseCaseTest {

    @Mock
    private lateinit var mockFormEntryRepository: FormEntryRepository

    private lateinit var useCase: GetDraftEntryUseCase


    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        useCase = GetDraftEntryUseCase(mockFormEntryRepository)
    }

    @Test
    fun invoke_withExistingDraft_returnsDraftEntry() = runTest {
        // Given
        val formId = "test-form"
        val expectedDraft = TestDataFactory.createTestFormEntry(
            id = "draft-id",
            formId = formId,
            isDraft = true
        )
        `when`(mockFormEntryRepository.getDraftEntry(formId)).thenReturn(flowOf(expectedDraft))

        // When
        val result = useCase.invoke(formId).first()

        // Then
        assertEquals(expectedDraft, result)
        verify(mockFormEntryRepository).getDraftEntry(formId)
    }

    @Test
    fun invoke_withNoDraft_returnsNull() = runTest {
        // Given
        val formId = "form-with-no-draft"
        `when`(mockFormEntryRepository.getDraftEntry(formId)).thenReturn(flowOf(null))

        // When
        val result = useCase.invoke(formId).first()

        // Then
        assertNull(result)
        verify(mockFormEntryRepository).getDraftEntry(formId)
    }
}