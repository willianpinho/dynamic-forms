package com.example.dynamicforms.domain.model

data class FormSection(
    val uuid: String,
    val title: String,
    val from: Int,
    val to: Int,
    val index: Int,
    val fields: List<FormField> = emptyList()
)