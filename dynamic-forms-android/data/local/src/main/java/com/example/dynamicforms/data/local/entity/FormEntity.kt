package com.example.dynamicforms.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "forms")
data class FormEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val fieldsJson: String, // JSON string of fields
    val sectionsJson: String, // JSON string of sections
    val createdAt: Long,
    val updatedAt: Long
)