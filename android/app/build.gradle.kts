plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aizatfir.focus_clock"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.aizatfir.focus_clock"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["appName"] = "Focus Clock"
    }

    flavorDimensions += "app"
    productFlavors {
        create("fitrah") {
            dimension = "app"
            applicationId = "com.aizatfir.fitrah_launcher"
            manifestPlaceholders["appName"] = "Fitrah Launcher"
        }
        create("sadar") {
            dimension = "app"
            applicationId = "com.aizatfir.sadar"
            manifestPlaceholders["appName"] = "Sadar"
        }
        create("focus") {
            dimension = "app"
            applicationId = "com.aizatfir.focus_clock"
            manifestPlaceholders["appName"] = "Focus Clock"
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
