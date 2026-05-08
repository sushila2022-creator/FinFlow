plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.finflowai.money.manager"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // Add this to read the release key properties
    // def keystoreProperties = new Properties()
    // def keystorePropertiesFile = rootProject.file("key.properties")
    // if (keystorePropertiesFile.exists()) {
    //     keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    // }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.finflowai.money.manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        versionCode = 8
        versionName = "1.0.8"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("../../android/finflow_secure.keystore")
            keyAlias = "finflow_secure_key"
            storePassword = System.getenv("STORE_PASSWORD") ?: "SecureFinFlow2025!"  // Set manually or via environment variable
            keyPassword = System.getenv("KEY_PASSWORD") ?: "SecureFinFlow2025!"      // Set manually or via environment variable
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // Enable code shrinking for release build only
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}
