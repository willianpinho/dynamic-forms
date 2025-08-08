package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.repository.FormEntryRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetEntryByIdUseCase @Inject constructor(
    private val formEntryRepository: FormEntryRepository
) {
    suspend operator fun invoke(entryId: String): Flow<FormEntry?> {
        return formEntryRepository.getEntryById(entryId)
    }
}