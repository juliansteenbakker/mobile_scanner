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
    private val setTorch: (enabled: Boolean) -> Unit,
) : SensorEventListener {

    companion object {
        /** The raw value of `TorchState.auto` on the Dart side. */
        const val TORCH_STATE_AUTO = 2

        const val TOO_DARK_LUX = 45f
        const val BRIGHT_ENOUGH_LUX = 450f
    }

    var isEnabled = false
        private set

    private var torchEnabled: Boolean? = null

    /**
     * Start listening to the light sensor.
     *
     * Returns false if the device has no light sensor.
     */
    fun start(): Boolean {
        val lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT) ?: return false

        torchEnabled = null
        isEnabled = sensorManager.registerListener(this, lightSensor, SensorManager.SENSOR_DELAY_NORMAL)

        return isEnabled
    }

    fun stop() {
        if (!isEnabled) return

        sensorManager?.unregisterListener(this)
        isEnabled = false
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

        if (enable != torchEnabled) {
            torchEnabled = enable
            setTorch(enable)
        }
    }
}
