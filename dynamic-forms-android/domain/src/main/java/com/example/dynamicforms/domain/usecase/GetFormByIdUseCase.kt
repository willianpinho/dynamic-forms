package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.model.DynamicForm
import com.example.dynamicforms.domain.repository.FormRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetFormByIdUseCase @Inject constructor(
    private val formRepository: FormRepository
) {
    suspend operator fun invoke(formId: String): Flow<DynamicForm?> {
        return formRepository.getFormById(formId)
    }
}