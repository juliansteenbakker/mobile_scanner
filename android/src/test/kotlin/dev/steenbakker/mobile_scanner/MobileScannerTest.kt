package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.graphics.Rect
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.common.Barcode
import kotlin.test.Test
import org.mockito.Mockito
import io.flutter.view.TextureRegistry
import kotlin.test.expect

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class MobileScannerTest {
    @Test
    fun isBarcodeInScanWindow_canHandleNaNValues() {
        val barcodeScannerMock = Mockito.mock(BarcodeScanner::class.java)

        val mobileScanner = MobileScanner(
            Mockito.mock(Activity::class.java),
            Mockito.mock(TextureRegistry::class.java),
            { _: List<Map<String, Any?>>, _: ByteArray?, _: Int?, _: Int? -> },
            { _: String  -> },
            { _: BarcodeScannerOptions? -> barcodeScannerMock }
        )

        // Intentional suppression for the mock value in the test,
        // since there is no NaN constant.
        @Suppress("DIVISION_BY_ZERO")
        val notANumber = 0.0f / 0.0f

        val barcodeMock: Barcode = Mockito.mock(Barcode::class.java)
        val imageMock: ImageProxy = Mockito.mock(ImageProxy::class.java)

        // TODO: use corner points instead of bounding box

        // Bounding box that is 100 pixels offset from the left and top,
        // and is 100 pixels in width and height.
        Mockito.`when`(barcodeMock.boundingBox).thenReturn(
            Rect(100, 100, 200, 300))
        Mockito.`when`(imageMock.height).thenReturn(400)
        Mockito.`when`(imageMock.width).thenReturn(400)

        // Use a scan window that has an invalid value, but otherwise uses the entire image.
        val scanWindow: List<Float> = listOf(0f, notANumber, 100f, 100f)

        expect(false) {
            mobileScanner.isBarcodeInScanWindow(scanWindow, barcodeMock, imageMock)
        }
    }
}