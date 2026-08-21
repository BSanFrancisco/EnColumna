import java.util.Properties

plugins {
    id("com.android.application")
    // AGP 8.x (no el "Kotlin built-in" de AGP 9) requiere aplicar el
    // plugin de Kotlin clásico acá. Ver la nota en Tablas de
    // Multiplicar: esta es la combinación que evita el choque con
    // shared_preferences (y otros plugins de pub.dev).
    id("org.jetbrains.kotlin.android")
    // El plugin de Flutter debe aplicarse después.
    id("dev.flutter.flutter-gradle-plugin")
}

// Datos de firma para el release, leídos desde android/key.properties
// (ese archivo NO se sube a git: contiene contraseñas). Al principio
// no vas a tener este archivo todavía — no pasa nada, el build de
// release cae a la firma de debug (solo sirve para probar en el
// celular, no para publicar) hasta que agregues tu propio keystore.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())

    val storeFilePath = keystoreProperties.getProperty("storeFile")
    val storeFileResolved = rootProject.file(storeFilePath)
    if (!storeFileResolved.exists()) {
        throw GradleException(
            "android/key.properties existe pero apunta a un archivo " +
                "que no está: '${storeFileResolved.absolutePath}'."
        )
    }
} else {
    logger.warn(
        "\n" + "!".repeat(70) + "\n" +
            "⚠️  ADVERTENCIA: no se encontró android/key.properties.\n" +
            "El build de RELEASE se va a firmar con la clave de DEBUG.\n" +
            "Esa build NO sirve para subir a la Play Store.\n" +
            "!".repeat(70) + "\n"
    )
}

android {
    namespace = "com.sebalima.multiplicacionescolumna"
    // Máximo que soporta AGP 8.13 (ver comentario en settings.gradle.kts).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sebalima.multiplicacionescolumna"
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
