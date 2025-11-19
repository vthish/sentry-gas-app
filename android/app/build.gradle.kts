plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sentry_gas_app"
    compileSdk = flutter.compileSdkVersion

    // NDK version eka awashya paridi thaba ganna
    ndkVersion = "27.0.12077973"

    compileOptions {
        // [FIX]: Java 8 warning eka nathi kireemata Java 11 bawitha karamu
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // [FIX]: Kotlin walatath Java 11 target karamu
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.sentry_gas_app"
        // Smart Auth wani plugins walata minSdk 21 ho 23 wadi weema awashya viya haka
        minSdk = 23 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Library desugaring enable kala nisa meya 'true' thibeema wadagath
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Release build ekatath thawakalikawa debug key eka use karai
            // (Play Store damanawanam meka wenas kala yuthu we)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // [IMPORTANT]: Java 11 features (Desugaring) support kireemata meya athyawashyai
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}