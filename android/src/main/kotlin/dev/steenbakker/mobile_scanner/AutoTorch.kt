package dev.steenbakker.mobile_scanner

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.annotation.VisibleForTesting

/**
 * Turns the torch on in the dark and off again in bright light, using the ambient light sensor.
 *
 * The gap between the two thresholds keeps the torch from flickering at a single light level.
 */
internal class AutoTorch(
    private val sensorManager: SensorManager?,
    private val setTorch: (enabled: Boolean, onFailure: () -> Unit) -> Unit,
) : SensorEventListener {

    companion object {
        /** The raw value of `TorchState.auto` on the Dart side. */
        const val TORCH_STATE_AUTO = 2

        const val TOO_DARK_LUX = 45f
        const val BRIGHT_ENOUGH_LUX = 450f
    }

    var isListening = false
        private set

    /** The torch state the light level asks for. */
    private var wanted: Boolean? = null

    /** The torch state last sent to the camera, or null if it is unknown or the request failed. */
    private var applied: Boolean? = null

    /**
     * Start listening to the light sensor.
     *
     * Returns false if the device has no light sensor.
     */
    fun start(): Boolean {
        if (isListening) return true

        val lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT) ?: return false

        isListening = sensorManager.registerListener(this, lightSensor, SensorManager.SENSOR_DELAY_NORMAL)

        return isListening
    }

    fun stop() {
        if (!isListening) return

        sensorManager?.unregisterListener(this)
        isListening = false
    }

    /**
     * Start listening again and resend the wanted torch state, for when the camera has reopened.
     *
     * The light sensor only reports changes, so a steady light level would never trigger a retry.
     */
    fun resume() {
        start()
        applied = null
        sendTorch()
    }

    override fun onSensorChanged(event: SensorEvent) {
        onLightChanged(event.values[0])
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    @VisibleForTesting
    internal fun onLightChanged(lux: Float) {
        val enable = when {
            lux <= TOO_DARK_LUX -> true
            lux >= BRIGHT_ENOUGH_LUX -> false
            else -> return
        }

        wanted = enable
        sendTorch()
    }

    private fun sendTorch() {
        val enable = wanted ?: return
        if (enable == applied) return

        applied = enable
        setTorch(enable) {
            if (applied == enable) applied = null
        }
    }
}
