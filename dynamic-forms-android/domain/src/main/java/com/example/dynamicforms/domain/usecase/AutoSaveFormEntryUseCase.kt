package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.repository.FormEntryRepository
import javax.inject.Inject

class AutoSaveFormEntryUseCase @Inject constructor(
    private val formEntryRepository: FormEntryRepository
) {
    suspend operator fun invoke(entry: FormEntry): Result<Unit> {
        return try {
            formEntryRepository.saveEntryDraft(entry)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}