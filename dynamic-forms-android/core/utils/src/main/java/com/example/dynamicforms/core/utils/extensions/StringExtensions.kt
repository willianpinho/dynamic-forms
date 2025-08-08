package com.example.dynamicforms.core.utils.extensions

import java.util.UUID

fun String?.isValidEmail(): Boolean {
    if (this.isNullOrBlank()) return false
    return android.util.Patterns.EMAIL_ADDRESS.matcher(this).matches()
}

fun String?.isValidNumber(): Boolean {
    if (this.isNullOrBlank()) return false
    return try {
        this.toDouble()
        true
    } catch (e: NumberFormatException) {
        false
    }
}

fun String?.isValidUUID(): Boolean {
    if (this.isNullOrBlank()) return false
    return try {
        UUID.fromString(this)
        true
    } catch (e: IllegalArgumentException) {
        false
    }
}

fun String.toSafeString(): String {
    return this.trim().replace(Regex("\\s+"), " ")
}

fun String?.orEmpty(default: String = ""): String {
    return if (this.isNullOrBlank()) default else this
}

fun String.capitalizeWords(): String {
    return this.split(" ").joinToString(" ") { word ->
        word.lowercase().replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
    }
}

fun String.truncate(maxLength: Int, suffix: String = "..."): String {
    return if (this.length <= maxLength) {
        this
    } else {
        this.take(maxLength - suffix.length) + suffix
    }
}