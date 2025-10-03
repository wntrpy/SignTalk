pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ Bump AGP to 8.9.1
    id("com.android.application") version "8.9.1" apply false

    // ✅ Keep Firebase / Google Services updated
    id("com.google.gms.google-services") version "4.4.2" apply false

    // ✅ Kotlin plugin (matches Flutter’s Kotlin compatibility)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
