import com.android.Version
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension

plugins {
    id("com.android.library")
}

group = "dev.steenbakker.mobile_scanner"
version = "1.0-SNAPSHOT"

// AGP 9+ compiles Kotlin itself when built-in Kotlin is enabled (the default),
// but apps migrated by the Flutter tool disable it via android.builtInKotlin=false.
// Apply KGP whenever built-in Kotlin is not active, so the Kotlin extension
// configured below exists in both configurations.
val agpMajor = Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore('.').toInt()
val builtInKotlin = agpMajor >= 9 &&
    (findProperty("android.builtInKotlin")?.toString() ?: "true").toBoolean()
if (!builtInKotlin) {
    apply(plugin = "kotlin-android")
}

android {
    namespace = "dev.steenbakker.mobile_scanner"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 23
        consumerProguardFiles("proguard-rules.pro")
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true

            all { test ->
                test.useJUnitPlatform()
                test.outputs.upToDateWhen { false }

                test.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

// Configured through `extensions` rather than a `kotlin { }` block, because the
// Kotlin plugin is applied imperatively above and so has no type-safe accessor.
// The extension may not exist yet: with AGP 9 and android.builtInKotlin=false the
// Flutter Gradle Plugin applies KGP to this subproject after the script is evaluated.
fun configureKotlin() {
    extensions.configure(KotlinAndroidProjectExtension::class.java) {
        compilerOptions {
            jvmTarget = JvmTarget.JVM_17
        }
    }
}
if (extensions.findByName("kotlin") != null) {
    configureKotlin()
} else {
    plugins.withId("org.jetbrains.kotlin.android") { configureKotlin() }
}

dependencies {
    val useUnbundled = findProperty("dev.steenbakker.mobile_scanner.useUnbundled")?.toString() ?: "false"
    if (useUnbundled.toBoolean()) {
        // Dynamically downloaded model via Google Play Services
        implementation("com.google.android.gms:play-services-mlkit-barcode-scanning:18.3.1")
    } else {
        // Bundled model in app
        implementation("com.google.mlkit:barcode-scanning:17.3.0")
    }

    implementation("androidx.camera:camera-lifecycle:1.6.1")
    implementation("androidx.camera:camera-camera2:1.6.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.23.0")

    // Robolectric provides real implementations of the Android framework
    // classes (Rect, Point, ArrayMap) that the stub android.jar throws on.
    // It is JUnit 4 based, so the vintage engine runs it on the JUnit
    // Platform alongside the JUnit 5 tests.
    testImplementation("org.robolectric:robolectric:4.16.1")
    testImplementation("junit:junit:4.13.2")
    testRuntimeOnly("org.junit.vintage:junit-vintage-engine:6.1.2")
}
