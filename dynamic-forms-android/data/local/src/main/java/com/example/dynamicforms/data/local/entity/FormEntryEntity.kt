package com.example.dynamicforms.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "form_entries",
    foreignKeys = [
        ForeignKey(
            entity = FormEntity::class,
            parentColumns = ["id"],
            childColumns = ["formId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["formId"]),
        Index(value = ["sourceEntryId"]),
        Index(value = ["formId", "isDraft"]),
        Index(value = ["sourceEntryId", "isDraft"])
    ]
)
data class FormEntryEntity(
    @PrimaryKey
    val id: String,
    val formId: String,
    val sourceEntryId: String? = null, // ID of the original entry this draft is based on (for edit drafts)
    val fieldValuesJson: String, // JSON string of field values map
    val createdAt: Long,
    val updatedAt: Long,
    val isComplete: Boolean,
    val isDraft: Boolean
)