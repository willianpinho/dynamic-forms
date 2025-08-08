package com.example.dynamicforms

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTheme
import com.example.dynamicforms.features.formlist.FormListScreen
import com.example.dynamicforms.features.formentries.FormEntriesScreen
import com.example.dynamicforms.features.formdetail.FormDetailScreen
import com.example.dynamicforms.navigation.Routes
import dagger.hilt.android.AndroidEntryPoint
import com.example.dynamicforms.core.utils.logging.AppLogger

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        AppLogger.d("MainActivity created")
        
        setContent {
            DynamicFormsTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    DynamicFormsApp(
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}

@Composable
private fun DynamicFormsApp(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Routes.FORM_LIST,
        modifier = modifier
    ) {
        composable(Routes.FORM_LIST) {
            FormListScreen(
                onNavigateToFormEntries = { formId ->
                    navController.navigate(Routes.formEntries(formId))
                }
            )
        }
        
        composable(
            route = Routes.FORM_ENTRIES,
            arguments = Routes.formEntriesArgs
        ) { backStackEntry ->
            val formId = backStackEntry.arguments?.getString(Routes.FORM_ID_ARG) ?: ""
            FormEntriesScreen(
                formId = formId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToFormDetail = { entryFormId, entryId ->
                    navController.navigate(Routes.formDetail(entryFormId, entryId))
                }
            )
        }
        
        composable(
            route = Routes.FORM_DETAIL,
            arguments = Routes.formDetailArgs
        ) { backStackEntry ->
            val formId = backStackEntry.arguments?.getString(Routes.FORM_ID_ARG) ?: ""
            val entryId = backStackEntry.arguments?.getString(Routes.ENTRY_ID_ARG)?.takeIf { it != "new" }
            
            FormDetailScreen(
                formId = formId,
                entryId = entryId,
                onBackClick = {
                    navController.popBackStack()
                },
                onSaveSuccess = {
                    navController.popBackStack()
                }
            )
        }
    }
}