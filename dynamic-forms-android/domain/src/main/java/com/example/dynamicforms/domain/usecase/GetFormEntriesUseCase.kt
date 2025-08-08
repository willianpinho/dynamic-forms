package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.model.FormEntry
import com.example.dynamicforms.domain.repository.FormEntryRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetFormEntriesUseCase @Inject constructor(
    private val formEntryRepository: FormEntryRepository
) {
    suspend operator fun invoke(formId: String): Flow<List<FormEntry>> {
        return formEntryRepository.getEntriesForForm(formId)
    }
}