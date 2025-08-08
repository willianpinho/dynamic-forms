package com.example.dynamicforms.data.repository.di

import com.example.dynamicforms.data.repository.FormEntryRepositoryImpl
import com.example.dynamicforms.data.repository.FormRepositoryImpl
import com.example.dynamicforms.domain.repository.FormEntryRepository
import com.example.dynamicforms.domain.repository.FormRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    
    @Binds
    @Singleton
    abstract fun bindFormRepository(
        formRepositoryImpl: FormRepositoryImpl
    ): FormRepository
    
    @Binds
    @Singleton
    abstract fun bindFormEntryRepository(
        formEntryRepositoryImpl: FormEntryRepositoryImpl
    ): FormEntryRepository
}