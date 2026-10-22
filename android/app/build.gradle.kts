import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase configuration is intentionally local and git-ignored. A fresh
// template must still compile with its no-op/bootstrap fallbacks; once the
// config is materialized, apply the Firebase build plugins for the real app.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.firebase-perf")
    apply(plugin = "com.google.firebase.crashlytics")
} else {
    logger.warn(
        "google-services.json is absent; Firebase Android Gradle plugins are disabled.",
    )
}

// Release signing is configured via android/key.properties (git-ignored).
// Copy key.properties.example to key.properties and point it at your upload
// keystore to ship Play-ready builds (see android/fastlane/README.md).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val requestedProdRelease = gradle.startParameter.taskNames.any { taskName ->
    taskName.substringAfterLast(':').contains("ProdRelease", ignoreCase = true)
}
if (requestedProdRelease && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Production release signing is not configured. " +
            "Copy android/key.properties.example to android/key.properties " +
            "and configure the upload keystore.",
    )
}

android {
    namespace = "com.lucistudio.flutter_starter_template"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // Flavors below define custom resource values via resValue(...).
        // AGP 9 disables this feature by default, so opt in explicitly.
        resValues = true
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Flutter Starter (Dev)")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "Flutter Starter (Staging)")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Flutter Starter")
        }
    }

    defaultConfig {
        applicationId = "com.lucistudio.flutter_starter_template"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
