pluginManagement {
    val flutterSdkPath =
        run {
            val propertiesFile = file("local.properties")
            if (propertiesFile.exists()) {
                val properties = java.util.Properties()
                propertiesFile.inputStream().use { properties.load(it) }
                val flutterSdkPath = properties.getProperty("flutter.sdk")
                require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
                flutterSdkPath
            } else {
                val envFlutterSdk = System.getenv("FLUTTER_SDK") ?: System.getenv("FLUTTER_ROOT")
                require(envFlutterSdk != null) {
                    "Unable to locate Flutter SDK. Set FLUTTER_SDK or create android/local.properties"
                }
                envFlutterSdk
            }
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
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
