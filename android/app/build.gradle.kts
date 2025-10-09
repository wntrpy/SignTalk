plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Needed for Firebase
    id("dev.flutter.flutter-gradle-plugin") // Must come after android/kotlin
}

android {
    namespace = "com.example.signtalk"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.signtalk"
        //minSdk = flutter.minSdkVersion // ✅ required for Firebase Messaging
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Replace with your real signing config
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // Firebase Core (always needed)
    implementation("com.google.firebase:firebase-analytics")

    // Firebase Auth
    implementation("com.google.firebase:firebase-auth")

    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging")

    // Google Play Services Auth
    implementation("com.google.android.gms:play-services-auth:21.3.0")

    // Required for desugaring (coreLibraryDesugaringEnabled true)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
