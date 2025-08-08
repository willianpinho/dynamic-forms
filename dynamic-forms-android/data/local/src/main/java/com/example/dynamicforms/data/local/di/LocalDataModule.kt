package com.example.dynamicforms.data.local.di

import android.content.Context
import androidx.room.Room
import com.example.dynamicforms.data.local.dao.FormDao
import com.example.dynamicforms.data.local.dao.FormEntryDao
import com.example.dynamicforms.data.local.database.DynamicFormsDatabase
import com.example.dynamicforms.data.local.datasource.AssetsDataSource
import com.example.dynamicforms.data.local.datasource.DatabaseInitializer
import com.example.dynamicforms.data.local.datasource.FormEntryLocalDataSource
import com.example.dynamicforms.data.local.datasource.FormLocalDataSource
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object LocalDataModule {
    
    @Provides
    @Singleton
    fun provideDynamicFormsDatabase(
        @ApplicationContext context: Context
    ): DynamicFormsDatabase {
        return DynamicFormsDatabase.create(context)
    }
    
    @Provides
    fun provideFormDao(database: DynamicFormsDatabase): FormDao {
        return database.formDao()
    }
    
    @Provides
    fun provideFormEntryDao(database: DynamicFormsDatabase): FormEntryDao {
        return database.formEntryDao()
    }
    
    @Provides
    @Singleton
    fun provideFormLocalDataSource(formDao: FormDao): FormLocalDataSource {
        return FormLocalDataSource(formDao)
    }
    
    @Provides
    @Singleton
    fun provideFormEntryLocalDataSource(formEntryDao: FormEntryDao): FormEntryLocalDataSource {
        return FormEntryLocalDataSource(formEntryDao)
    }
    
    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder()
            .setPrettyPrinting()
            .create()
    }

    @Provides
    @Singleton
    fun provideAssetsDataSource(
        @ApplicationContext context: Context,
        gson: Gson
    ): AssetsDataSource {
        return AssetsDataSource(context, gson)
    }

    @Provides
    @Singleton
    fun provideDatabaseInitializer(
        @ApplicationContext context: Context,
        formDao: FormDao,
        assetsDataSource: AssetsDataSource,
        gson: Gson
    ): DatabaseInitializer {
        return DatabaseInitializer(context, formDao, assetsDataSource, gson)
    }
}