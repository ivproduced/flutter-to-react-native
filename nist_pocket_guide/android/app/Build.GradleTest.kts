import com.android.build.gradle.internal.dsl.NdkBuildOptions // Add this import


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "life.eucann.nist_pocket_guide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11   
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "life.eucann.nist_pocket_guide"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create ("release") {
            storeFile = file("upload-keystore.jks")
            storePassword = "PW" // Replace with your keystore password
            keyAlias = "upload" // The alias you used when generating the key
            keyPassword = "PW"     // Replace with your key password (can be the same as keystore password)
            enableV1Signing = true
            enableV2Signing = true
        }
    }

 buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "android/app/proguard-rules.pro"
        )
    }
}

    flutter {
        source = "../.."
    } 

}