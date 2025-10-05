plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ziraai.ziraai_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Default application ID - overridden by flavors
        applicationId = "com.ziraai.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            manifestPlaceholders["deepLinkHost"] = "ziraai.com"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
