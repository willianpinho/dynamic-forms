package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.repository.FormEntryRepository
import javax.inject.Inject

class SaveFormEntryUseCase @Inject constructor(
    private val formEntryRepository: FormEntryRepository
) {
    suspend operator fun invoke(entry: FormEntry, isComplete: Boolean = false): Result<String> {
        return try {
            val finalEntry = if (isComplete) {
                entry.markAsComplete()
            } else {
                entry
            }
            
            if (entry.id.isEmpty()) {
                formEntryRepository.insertEntry(finalEntry)
            } else {
                formEntryRepository.updateEntry(finalEntry).map { entry.id }
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}