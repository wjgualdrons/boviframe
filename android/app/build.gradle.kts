// Top del archivo build.gradle.kts
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}



android {
    namespace   = "com.app.boviframe"
    compileSdk  = flutter.compileSdkVersion
    ndkVersion  = "27.0.12077973"

    defaultConfig {
        applicationId = "com.app.boviframe"
        minSdk        = 23
        targetSdk     = 35
        versionCode   = 1
        versionName   = "1.0.1"
    }

    signingConfigs {
        create("release") {
            // Carga las propiedades del key.properties
val propsFile = rootProject.file("app/key.properties")
            val props = Properties().apply {
                load(FileInputStream(propsFile))
            }

            keyAlias      = props["keyAlias"]      as String
            keyPassword   = props["keyPassword"]   as String
storeFile = file("keystore-release.jks")
            storePassword = props["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig    = signingConfigs["release"]
            isMinifyEnabled   = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}
