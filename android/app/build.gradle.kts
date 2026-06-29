plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bhromon_app"
    compileSdk = flutter.compileSdkVersion.toInt() // Updated syntax
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Updated to use compilerOptions DSL to avoid deprecation warnings
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.example.bhromon_app"
        minSdk = flutter.minSdkVersion.toInt() // Updated syntax
        targetSdk = flutter.targetSdkVersion.toInt() // Updated syntax
        multiDexEnabled = true
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}