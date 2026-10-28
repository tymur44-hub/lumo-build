import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

val ks = Properties().apply { file("keystore.properties").inputStream().use { load(it) } }

android {
    namespace = "ru.volshebnymir.lumo"
    compileSdk = 35
    defaultConfig {
        applicationId = "ru.volshebnymir.lumo"
        minSdk = 26
        targetSdk = 34
        versionCode = 13
        versionName = "2.2-beta"
    }
    signingConfigs {
        create("lumo") {
            storeFile = file("lumo.jks")
            storePassword = ks.getProperty("storePassword")
            keyAlias = ks.getProperty("keyAlias")
            keyPassword = ks.getProperty("keyPassword")
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("lumo")
        }
        debug { signingConfig = signingConfigs.getByName("lumo") }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
    packaging { resources.excludes += "/META-INF/{AL2.0,LGPL2.1}" }
}

dependencies {
    val bom = platform("androidx.compose:compose-bom:2024.09.02")
    implementation(bom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.fragment:fragment-ktx:1.8.3")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("io.coil-kt:coil-compose:2.7.0")
    implementation("io.coil-kt:coil-video:2.7.0")
    implementation("androidx.media3:media3-exoplayer:1.4.1")
    implementation("androidx.media3:media3-ui:1.4.1")
    implementation("io.getstream:stream-webrtc-android:1.3.7")
    implementation("com.google.zxing:core:3.5.3")
    // ядро обхода замедления (скачивается в CI в app/libs/libXray.aar)
    implementation(files("libs/libXray.aar"))
    val camx = "1.3.4"
    implementation("androidx.camera:camera-camera2:$camx")
    implementation("androidx.camera:camera-lifecycle:$camx")
    implementation("androidx.camera:camera-video:$camx")
    implementation("androidx.camera:camera-view:$camx")
}
