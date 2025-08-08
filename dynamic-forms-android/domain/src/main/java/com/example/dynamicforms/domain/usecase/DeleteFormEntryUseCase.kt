package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.repository.FormEntryRepository
import javax.inject.Inject

class DeleteFormEntryUseCase @Inject constructor(
    private val formEntryRepository: FormEntryRepository
) {
    suspend operator fun invoke(entryId: String): Result<Unit> {
        return try {
            formEntryRepository.deleteEntry(entryId)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}