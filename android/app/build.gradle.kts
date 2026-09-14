plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sungguard.user"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sungguard.user"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "default"

    productFlavors {
        create("dev") {
            dimension = "default"
            // 📝 NOTE FOR ADMIN / DEVELOPER:
            // Uncomment the line below when 'com.sungguard.user.dev' is added to Firebase Console & updated in google-services.json
            // applicationIdSuffix = ".dev"
            resValue("string", "app_name", "SunGguard Dev")
        }
        create("staging") {
            dimension = "default"
            // 📝 NOTE FOR ADMIN / DEVELOPER:
            // Uncomment the line below when 'com.sungguard.user.staging' is added to Firebase Console & updated in google-services.json
            // applicationIdSuffix = ".staging"
            resValue("string", "app_name", "SunGguard Staging")
        }
        create("prod") {
            dimension = "default"
            resValue("string", "app_name", "SunGguard")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Import the Firebase BoM

  implementation(platform("com.google.firebase:firebase-bom:34.18.0"))


  // TODO: Add the dependencies for Firebase products you want to use

  // When using the BoM, don't specify versions in Firebase dependencies

  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products

  // https://firebase.google.com/docs/android/setup#available-libraries

}
