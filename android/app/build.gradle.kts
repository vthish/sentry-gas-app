// --- android/app/build.gradle.kts (FINAL UPDATED) ---

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sentry_gas_app"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "27.0.12077973"

     compileOptions {
     sourceCompatibility = JavaVersion.VERSION_1_8
     targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
     }

     kotlinOptions {
     jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
     applicationId = "com.example.sentry_gas_app"
     minSdk = 23 
     targetSdk = flutter.targetSdkVersion
     versionCode = flutter.versionCode
     versionName = flutter.versionName
        multiDexEnabled = true
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

dependencies {
    // [IMPORTANT]: Version updated to 2.1.4 as required by the build error
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}