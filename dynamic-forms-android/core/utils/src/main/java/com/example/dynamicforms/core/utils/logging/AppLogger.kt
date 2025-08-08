package com.example.dynamicforms.core.utils.logging

import timber.log.Timber

object AppLogger {
    
    private var isDebugMode = false
    
    fun init(isDebug: Boolean) {
        isDebugMode = isDebug
        if (isDebug) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(CrashReportingTree())
        }
    }
    
    fun d(tag: String, message: String, vararg args: Any?) {
        Timber.tag(tag).d(message, *args)
    }
    
    fun d(message: String, vararg args: Any?) {
        Timber.d(message, *args)
    }
    
    fun d(throwable: Throwable, message: String, vararg args: Any?) {
        Timber.d(throwable, message, *args)
    }
    
    /**
     * Debug log with tag that only logs if debug mode is enabled
     * Used for performance-critical logging that should be minimal in production
     */
    fun dv(tag: String, message: String) {
        if (isDebugMode) {
            Timber.tag(tag).d(message)
        }
    }
    
    fun i(tag: String, message: String, vararg args: Any?) {
        Timber.tag(tag).i(message, *args)
    }
    
    fun i(message: String, vararg args: Any?) {
        Timber.i(message, *args)
    }
    
    fun i(throwable: Throwable, message: String, vararg args: Any?) {
        Timber.i(throwable, message, *args)
    }
    
    fun w(tag: String, message: String, vararg args: Any?) {
        Timber.tag(tag).w(message, *args)
    }
    
    fun w(message: String, vararg args: Any?) {
        Timber.w(message, *args)
    }
    
    fun w(throwable: Throwable, message: String, vararg args: Any?) {
        Timber.w(throwable, message, *args)
    }
    
    fun e(tag: String, message: String, vararg args: Any?) {
        Timber.tag(tag).e(message, *args)
    }
    
    fun e(message: String, vararg args: Any?) {
        Timber.e(message, *args)
    }
    
    fun e(throwable: Throwable, message: String, vararg args: Any?) {
        Timber.e(throwable, message, *args)
    }
    
    private class CrashReportingTree : Timber.Tree() {
        override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
            
        }
    }
}