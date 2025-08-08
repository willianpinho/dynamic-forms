pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "DynamicForms"
include(":app")

// Core modules
include(":core:designsystem")
include(":core:ui")
include(":core:utils")
include(":core:testutils")

// Domain layer
include(":domain")

// Data layer
include(":data:local")
include(":data:repository")
include(":data:mapper")

// Feature modules
include(":features:formlist")
include(":features:formentries")
include(":features:formdetail")