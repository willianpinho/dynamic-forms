package com.example.dynamicforms

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTheme
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography
import com.example.dynamicforms.core.designsystem.components.AppButton
import com.example.dynamicforms.data.local.datasource.DatabaseInitializer
import com.example.dynamicforms.data.local.entity.FormEntity
import com.example.dynamicforms.data.local.dao.FormDao
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import com.example.dynamicforms.core.utils.logging.AppLogger
import javax.inject.Inject

@AndroidEntryPoint
class InitializationActivity : ComponentActivity() {

    @Inject
    lateinit var databaseInitializer: DatabaseInitializer

    @Inject
    lateinit var formDao: FormDao

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            DynamicFormsTheme {
                DatabaseTestScreen(
                    databaseInitializer = databaseInitializer,
                    formDao = formDao
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatabaseTestScreen(
    databaseInitializer: DatabaseInitializer,
    formDao: FormDao
) {
    var initializationStatus by remember { mutableStateOf("Not Started") }
    var isLoading by remember { mutableStateOf(false) }
    val forms by formDao.getAllForms().collectAsStateWithLifecycle(initialValue = emptyList())
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Database Initialization Test",
                    style = DynamicFormsTypography.headlineSmall
                )
                
                Text(
                    text = "Status: $initializationStatus",
                    style = DynamicFormsTypography.bodyMedium
                )
                
                Text(
                    text = "Forms Count: ${forms.size}",
                    style = DynamicFormsTypography.bodyMedium
                )

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    AppButton(
                        text = if (isLoading) "Initializing..." else "Initialize Database",
                        onClick = {
                            scope.launch {
                                isLoading = true
                                initializationStatus = "Initializing..."
                                try {
                                    val result = databaseInitializer.initializeDatabase()
                                    initializationStatus = if (result is com.example.dynamicforms.core.utils.result.Resource.Success) {
                                        "Success"
                                    } else {
                                        "Failed: ${(result as com.example.dynamicforms.core.utils.result.Resource.Error).exception.message}"
                                    }
                                } catch (e: Exception) {
                                    initializationStatus = "Error: ${e.message}"
                                    AppLogger.e(e, "Database initialization failed")
                                } finally {
                                    isLoading = false
                                }
                            }
                        },
                        enabled = !isLoading
                    )

                    AppButton(
                        text = "Force Reload",
                        onClick = {
                            scope.launch {
                                isLoading = true
                                initializationStatus = "Force Reloading..."
                                try {
                                    val result = databaseInitializer.forceReloadForms()
                                    initializationStatus = if (result is com.example.dynamicforms.core.utils.result.Resource.Success) {
                                        "Force Reload Success"
                                    } else {
                                        "Failed: ${(result as com.example.dynamicforms.core.utils.result.Resource.Error).exception.message}"
                                    }
                                } catch (e: Exception) {
                                    initializationStatus = "Error: ${e.message}"
                                    AppLogger.e(e, "Force reload failed")
                                } finally {
                                    isLoading = false
                                }
                            }
                        },
                        enabled = !isLoading
                    )
                }
            }
        }

        if (forms.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Loaded Forms (${forms.size})",
                        style = DynamicFormsTypography.headlineSmall,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                    
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(forms) { form ->
                            FormItem(form = form)
                        }
                    }
                }
            }
        } else {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No forms loaded yet.\nClick 'Initialize Database' to load forms from assets.",
                        style = DynamicFormsTypography.bodyMedium
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FormItem(form: FormEntity) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = form.title,
                style = DynamicFormsTypography.titleMedium
            )
            Text(
                text = "ID: ${form.id}",
                style = DynamicFormsTypography.bodySmall
            )
            
            // Show field count
            val fieldCount = try {
                val fieldsJson = form.fieldsJson
                // Simple count by counting field objects
                fieldsJson.split("\"id\"").size - 1
            } catch (e: Exception) {
                0
            }
            
            Text(
                text = "Fields: $fieldCount",
                style = DynamicFormsTypography.bodySmall
            )
            
            Text(
                text = "Created: ${java.text.SimpleDateFormat("yyyy-MM-dd HH:mm", java.util.Locale.getDefault()).format(java.util.Date(form.createdAt))}",
                style = DynamicFormsTypography.bodySmall
            )
        }
    }
}