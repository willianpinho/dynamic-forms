package com.example.dynamicforms.navigation

import androidx.navigation.NamedNavArgument
import androidx.navigation.NavType
import androidx.navigation.navArgument

object Routes {
    const val FORM_LIST = "form_list"
    private const val FORM_ENTRIES_BASE = "form_entries"
    private const val FORM_DETAIL_BASE = "form_detail"

    const val FORM_ID_ARG = "formId"
    const val ENTRY_ID_ARG = "entryId"

    const val FORM_ENTRIES = "$FORM_ENTRIES_BASE/{$FORM_ID_ARG}"
    const val FORM_DETAIL = "$FORM_DETAIL_BASE/{$FORM_ID_ARG}?$ENTRY_ID_ARG={$ENTRY_ID_ARG}"

    fun formEntries(formId: String): String {
        return "$FORM_ENTRIES_BASE/$formId"
    }

    fun formDetail(formId: String, entryId: String? = null): String {
        return "$FORM_DETAIL_BASE/$formId?entryId=${entryId ?: "new"}"
    }

    val formEntriesArgs: List<NamedNavArgument> = listOf(
        navArgument(FORM_ID_ARG) { type = NavType.StringType }
    )

    val formDetailArgs: List<NamedNavArgument> = listOf(
        navArgument(FORM_ID_ARG) { type = NavType.StringType },
        navArgument(ENTRY_ID_ARG) {
            type = NavType.StringType
            nullable = true
            defaultValue = "new"
        }
    )
}