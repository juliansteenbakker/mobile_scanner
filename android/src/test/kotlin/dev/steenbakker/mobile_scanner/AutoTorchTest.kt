package dev.steenbakker.mobile_scanner

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

/**
 * Unit tests for the light thresholds in [AutoTorch].
 *
 * Run these tests from the command line by running `./gradlew testDebugUnitTest`
 * in the `example/android/` directory.
 */
internal class AutoTorchTest {

    private val torchCalls = mutableListOf<Boolean>()
    private var failNextCall = false
    private val autoTorch = AutoTorch(null) { enabled, onFailure ->
        torchCalls.add(enabled)
        if (failNextCall) {
            failNextCall = false
            onFailure()
        }
    }

    @Test
    fun onLightChanged_dark_turnsTorchOn() {
        autoTorch.onLightChanged(10f)

        assertEquals(listOf(true), torchCalls)
    }

    @Test
    fun onLightChanged_bright_turnsTorchOff() {
        autoTorch.onLightChanged(1000f)

        assertEquals(listOf(false), torchCalls)
    }

    @Test
    fun onLightChanged_atThresholds_switchesTorch() {
        autoTorch.onLightChanged(AutoTorch.TOO_DARK_LUX)
        autoTorch.onLightChanged(AutoTorch.BRIGHT_ENOUGH_LUX)

        assertEquals(listOf(true, false), torchCalls)
    }

    @Test
    fun onLightChanged_betweenThresholds_keepsTorchState() {
        autoTorch.onLightChanged(100f)
        assertEquals(emptyList(), torchCalls)

        autoTorch.onLightChanged(10f)
        autoTorch.onLightChanged(200f)
        assertEquals(listOf(true), torchCalls)
    }

    @Test
    fun onLightChanged_repeatedDarkReadings_turnsTorchOnOnce() {
        autoTorch.onLightChanged(10f)
        autoTorch.onLightChanged(5f)
        autoTorch.onLightChanged(0f)

        assertEquals(listOf(true), torchCalls)
    }

    @Test
    fun onLightChanged_afterFailedCall_retries() {
        failNextCall = true
        autoTorch.onLightChanged(10f)
        autoTorch.onLightChanged(5f)

        assertEquals(listOf(true, true), torchCalls)
    }

    @Test
    fun resume_resendsWantedState() {
        autoTorch.onLightChanged(10f)
        autoTorch.resume()

        assertEquals(listOf(true, true), torchCalls)
    }

    @Test
    fun resume_withoutReading_doesNothing() {
        autoTorch.resume()

        assertEquals(emptyList(), torchCalls)
    }

    @Test
    fun start_withoutSensorManager_returnsFalse() {
        assertFalse(autoTorch.start())
        assertFalse(autoTorch.isListening)
    }
}
