package com.example.dynamicforms.domain.usecase

import com.example.dynamicforms.domain.repository.FormRepository
import javax.inject.Inject

class InitializeFormsUseCase @Inject constructor(
    private val formRepository: FormRepository
) {
    suspend operator fun invoke(): Result<Unit> {
        return try {
            if (!formRepository.isFormsDataInitialized()) {
                val formsResult = formRepository.loadFormsFromAssets()
                if (formsResult.isSuccess) {
                    val forms = formsResult.getOrThrow()
                    forms.forEach { form ->
                        formRepository.insertForm(form)
                    }
                }
                formsResult.map { }
            } else {
                Result.success(Unit)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}