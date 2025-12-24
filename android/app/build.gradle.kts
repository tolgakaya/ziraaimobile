import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.ziraai.app"
    compileSdk = 36  // Updated to support latest plugins (backward compatible with API 35)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Default application ID - overridden by flavors
        applicationId = "com.ziraai.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35  // Updated to Android 15 (API 35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.ziraai.app.dev"
            resValue("string", "app_name", "ZiraAI Dev")
            manifestPlaceholders["deepLinkHost"] = "localhost:5001"
        }

        create("staging") {
            dimension = "environment"
            applicationId = "com.ziraai.app.staging"
            resValue("string", "app_name", "ZiraAI Staging")
            manifestPlaceholders["deepLinkHost"] = "ziraai-api-sit.up.railway.app"
        }

        create("prod") {
            dimension = "environment"
            applicationId = "com.ziraai.app"
            resValue("string", "app_name", "ZiraAI")
            manifestPlaceholders["deepLinkHost"] = "api.ziraai.com"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
