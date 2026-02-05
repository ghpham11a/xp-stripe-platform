package com.example.stripedemo.di

import com.example.stripedemo.data.networking.ApiService
import com.example.stripedemo.data.repositories.AccountRepository
import com.google.gson.Gson
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideAccountRepository(
        apiService: ApiService,
        gson: Gson,
        okHttpClient: OkHttpClient
    ): AccountRepository {
        return AccountRepository(apiService, gson, okHttpClient)
    }
}
