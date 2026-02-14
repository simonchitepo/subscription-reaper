import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties (android/key.properties)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.sub_reaper"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ✅ IMPORTANT: change this before publishing (must be unique on Google Play)
        applicationId = "com.cypher.subreaper"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Release signing loaded from key.properties
        create("release") {
            // Only configure if key.properties exists (avoids breaking local dev)
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String

                // storeFile in key.properties should be "upload-keystore.jks"
                // and the file should exist inside android/app/
                val storeFileName = keystoreProperties["storeFile"] as String
                storeFile = file(storeFileName)
            }
        }
    }

    buildTypes {
        debug {
            // keep default debug signing
        }

        release {
            // ✅ Use your release keystore
            signingConfig = signingConfigs.getByName("release")

            // ✅ Production optimizations
            isMinifyEnabled = true
            isShrinkResources = true

            // Default optimized rules + your custom rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
