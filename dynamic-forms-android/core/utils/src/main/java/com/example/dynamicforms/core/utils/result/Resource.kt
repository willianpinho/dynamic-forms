package com.example.dynamicforms.core.utils.result

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart

sealed class Resource<out T> {
    data object Loading : Resource<Nothing>()
    data class Success<T>(val data: T) : Resource<T>()
    data class Error(val exception: Throwable, val message: String = exception.message ?: "Unknown error") : Resource<Nothing>()
    
    inline fun onSuccess(action: (value: T) -> Unit): Resource<T> {
        if (this is Success) action(data)
        return this
    }
    
    inline fun onError(action: (exception: Throwable) -> Unit): Resource<T> {
        if (this is Error) action(exception)
        return this
    }
    
    inline fun onLoading(action: () -> Unit): Resource<T> {
        if (this is Loading) action()
        return this
    }
}

fun <T> Resource<T>.data(): T? {
    return if (this is Resource.Success) data else null
}

fun <T> Resource<T>.error(): Throwable? {
    return if (this is Resource.Error) exception else null
}

fun <T> Resource<T>.isLoading(): Boolean {
    return this is Resource.Loading
}

fun <T> Resource<T>.isSuccess(): Boolean {
    return this is Resource.Success
}

fun <T> Resource<T>.isError(): Boolean {
    return this is Resource.Error
}

suspend fun <T> safeCall(action: suspend () -> T): Resource<T> {
    return try {
        Resource.Success(action())
    } catch (e: Exception) {
        Resource.Error(e)
    }
}

fun <T> Flow<T>.asResource(): Flow<Resource<T>> {
    return this
        .map<T, Resource<T>> { Resource.Success(it) }
        .onStart { emit(Resource.Loading) }
        .catch { emit(Resource.Error(it)) }
}