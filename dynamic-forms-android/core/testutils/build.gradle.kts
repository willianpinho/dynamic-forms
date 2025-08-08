plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.example.dynamicforms.core.testutils"
    compileSdk = 35

    defaultConfig {
        minSdk = 30
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    api(project(":domain"))
    api(project(":data:local"))
    
    api(libs.junit)
    api(libs.kotlinx.coroutines.test)
    api(libs.mockito.core)
    api(libs.mockito.kotlin)
    api(libs.androidx.junit)
    api(libs.androidx.espresso.core)
    api(libs.androidx.room.testing)
}