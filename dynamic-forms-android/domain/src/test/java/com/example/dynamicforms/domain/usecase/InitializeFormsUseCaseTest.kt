package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.core.testutils.TestDataFactory
import com.example.dynamicforms.domain.repository.FormRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.Mockito.`when`
import org.mockito.kotlin.*

@ExperimentalCoroutinesApi
class InitializeFormsUseCaseTest {

    private val mockFormRepository: FormRepository = mock()
    private val useCase = InitializeFormsUseCase(mockFormRepository)

    @Before
    fun setUp() {
        // Reset mocks before each test
        reset(mockFormRepository)
    }

    @Test
    fun invoke_whenFormsNotInitialized_loadsAndSavesForms() = runTest {
        // Given
        val forms = listOf(
            TestDataFactory.createTestDynamicForm("form1", "Form 1"),
            TestDataFactory.createTestDynamicForm("form2", "Form 2")
        )
        
        `when`(mockFormRepository.isFormsDataInitialized()).thenReturn(false)
        `when`(mockFormRepository.loadFormsFromAssets()).thenReturn(Result.success(forms))
        `when`(mockFormRepository.insertForm(any())).thenReturn(Result.success(Unit))

        // When
        val result = useCase.invoke()

        // Then
        assertTrue(result.isSuccess)
        verify(mockFormRepository).isFormsDataInitialized()
        verify(mockFormRepository).loadFormsFromAssets()
        verify(mockFormRepository, times(2)).insertForm(any())
    }

    @Test
    fun invoke_whenFormsAlreadyInitialized_returnsSuccessWithoutLoading() = runTest {
        // Given
        `when`(mockFormRepository.isFormsDataInitialized()).thenReturn(true)

        // When
        val result = useCase.invoke()

        // Then
        assertTrue(result.isSuccess)
        verify(mockFormRepository).isFormsDataInitialized()
        verify(mockFormRepository, never()).loadFormsFromAssets()
        verify(mockFormRepository, never()).insertForm(any())
    }

    @Test
    fun invoke_whenLoadFromAssetsFailes_returnsFailure() = runTest {
        // Given
        val expectedException = RuntimeException("Asset loading failed")
        
        `when`(mockFormRepository.isFormsDataInitialized()).thenReturn(false)
        `when`(mockFormRepository.loadFormsFromAssets()).thenReturn(Result.failure(expectedException))

        // When
        val result = useCase.invoke()

        // Then
        assertTrue(result.isFailure)
        verify(mockFormRepository).isFormsDataInitialized()
        verify(mockFormRepository).loadFormsFromAssets()
        verify(mockFormRepository, never()).insertForm(any())
    }

    @Test
    fun invoke_whenInsertFormThrowsException_returnsFailure() = runTest {
        // Given
        val forms = listOf(TestDataFactory.createTestDynamicForm("form1", "Form 1"))
        val expectedException = RuntimeException("Insert failed")
        
        `when`(mockFormRepository.isFormsDataInitialized()).thenReturn(false)
        `when`(mockFormRepository.loadFormsFromAssets()).thenReturn(Result.success(forms))
        `when`(mockFormRepository.insertForm(any())).thenThrow(expectedException)

        // When
        val result = useCase.invoke()

        // Then
        assertTrue(result.isFailure)
        verify(mockFormRepository).isFormsDataInitialized()
        verify(mockFormRepository).loadFormsFromAssets()
        verify(mockFormRepository).insertForm(any())
    }
}