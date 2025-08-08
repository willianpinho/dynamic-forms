package com.example.dynamicforms.core.utils.formatters

import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object TextFormatter {
    
    private val timestampFormat = SimpleDateFormat("MMM dd, yyyy 'at' HH:mm", Locale.getDefault())
    private val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    private val decimalFormat = DecimalFormat("#,##0.##")
    
    fun formatTimestamp(timestamp: Long): String {
        return timestampFormat.format(Date(timestamp))
    }
    
    fun formatDate(date: Date): String {
        return dateFormat.format(date)
    }
    
    fun formatTime(date: Date): String {
        return timeFormat.format(date)
    }
    
    fun formatNumber(number: Double): String {
        return decimalFormat.format(number)
    }
    
    fun formatFieldLabel(label: String, isRequired: Boolean): String {
        return if (isRequired) "$label *" else label
    }
    
    fun formatFormTitle(title: String): String {
        return title.trim().takeIf { it.isNotEmpty() } ?: "Untitled Form"
    }
    
    fun formatEntryCount(count: Int): String {
        return when (count) {
            0 -> "No entries"
            1 -> "1 entry"
            else -> "$count entries"
        }
    }
    
    fun formatFileSize(bytes: Long): String {
        val kb = bytes / 1024
        val mb = kb / 1024
        
        return when {
            mb > 0 -> "${DecimalFormat("#.#").format(mb.toDouble())} MB"
            kb > 0 -> "${DecimalFormat("#.#").format(kb.toDouble())} KB"
            else -> "$bytes bytes"
        }
    }
    
    fun stripHtmlTags(html: String): String {
        return html.replace(Regex("<[^>]*>"), "").trim()
    }
    
    fun formatValidationError(fieldName: String, error: String): String {
        return "$fieldName: $error"
    }
}