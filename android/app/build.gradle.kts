import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ayimoloumap_mobile"
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
        applicationId = "com.example.ayimoloumap_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 🔹 Charger la clé depuis .env (à la racine du projet Flutter)
        val envProps = Properties()
        val envFile = project.rootProject.file("../.env")  // 👈 Chemin vers .env à la racine
        if (envFile.exists()) {
            envProps.load(FileInputStream(envFile))
        }
        
        val mapsApiKey = envProps.getProperty("GOOGLE_MAPS_API_KEY") ?: ""

        resValue("string", "google_maps_key", mapsApiKey)
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
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
