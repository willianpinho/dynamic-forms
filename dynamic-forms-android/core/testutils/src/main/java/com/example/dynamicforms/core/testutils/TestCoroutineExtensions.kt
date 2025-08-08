package com.example.dynamicforms.core.testutils

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.rules.TestWatcher
import org.junit.runner.Description

@ExperimentalCoroutinesApi
class MainDispatcherRule(
    private val testDispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {
    
    override fun starting(description: Description) {
        Dispatchers.setMain(testDispatcher)
    }
    
    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}

@ExperimentalCoroutinesApi
fun runTestWithDispatcher(
    testDispatcher: TestDispatcher = UnconfinedTestDispatcher(),
    testBody: suspend () -> Unit
) = runTest(testDispatcher) {
    testBody()
}

fun <T> createMockFlow(value: T): Flow<T> = flowOf(value)

fun <T> createMockFlow(values: List<T>): Flow<List<T>> = flowOf(values)