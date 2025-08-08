package com.example.dynamicforms.domain.di

import com.example.dynamicforms.domain.usecase.AutoSaveFormEntryUseCase
import com.example.dynamicforms.domain.usecase.DeleteFormEntryUseCase
import com.example.dynamicforms.domain.usecase.GetAllFormsUseCase
import com.example.dynamicforms.domain.usecase.GetDraftEntryUseCase
import com.example.dynamicforms.domain.usecase.GetFormByIdUseCase
import com.example.dynamicforms.domain.usecase.GetFormEntriesUseCase
import com.example.dynamicforms.domain.usecase.InitializeFormsUseCase
import com.example.dynamicforms.domain.usecase.SaveFormEntryUseCase
import com.example.dynamicforms.domain.usecase.ValidateFormEntryUseCase
import com.example.dynamicforms.domain.repository.FormEntryRepository
import com.example.dynamicforms.domain.repository.FormRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DomainModule {

    @Provides
    @Singleton
    fun provideGetAllFormsUseCase(
        formRepository: FormRepository
    ): GetAllFormsUseCase = GetAllFormsUseCase(formRepository)

    @Provides
    @Singleton
    fun provideGetFormByIdUseCase(
        formRepository: FormRepository
    ): GetFormByIdUseCase = GetFormByIdUseCase(formRepository)

    @Provides
    @Singleton
    fun provideInitializeFormsUseCase(
        formRepository: FormRepository
    ): InitializeFormsUseCase = InitializeFormsUseCase(formRepository)

    @Provides
    @Singleton
    fun provideGetFormEntriesUseCase(
        formEntryRepository: FormEntryRepository
    ): GetFormEntriesUseCase = GetFormEntriesUseCase(formEntryRepository)

    @Provides
    @Singleton
    fun provideSaveFormEntryUseCase(
        formEntryRepository: FormEntryRepository
    ): SaveFormEntryUseCase = SaveFormEntryUseCase(formEntryRepository)

    @Provides
    @Singleton
    fun provideAutoSaveFormEntryUseCase(
        formEntryRepository: FormEntryRepository
    ): AutoSaveFormEntryUseCase = AutoSaveFormEntryUseCase(formEntryRepository)

    @Provides
    @Singleton
    fun provideGetDraftEntryUseCase(
        formEntryRepository: FormEntryRepository
    ): GetDraftEntryUseCase = GetDraftEntryUseCase(formEntryRepository)

    @Provides
    @Singleton
    fun provideValidateFormEntryUseCase(): ValidateFormEntryUseCase = ValidateFormEntryUseCase()

    @Provides
    @Singleton
    fun provideDeleteFormEntryUseCase(
        formEntryRepository: FormEntryRepository
    ): DeleteFormEntryUseCase = DeleteFormEntryUseCase(formEntryRepository)
}