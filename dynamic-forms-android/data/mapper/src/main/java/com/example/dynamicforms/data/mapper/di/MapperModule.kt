package com.example.dynamicforms.data.mapper.di

import com.example.dynamicforms.data.mapper.FormEntryMapper
import com.example.dynamicforms.data.mapper.FormMapper
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object MapperModule {
    
    @Provides
    @Singleton
    fun provideFormMapper(): FormMapper = FormMapper()
    
    @Provides
    @Singleton
    fun provideFormEntryMapper(): FormEntryMapper = FormEntryMapper()
}