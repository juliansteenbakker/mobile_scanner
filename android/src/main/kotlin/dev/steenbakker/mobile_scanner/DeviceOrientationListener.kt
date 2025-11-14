package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.view.OrientationEventListener
import dev.steenbakker.mobile_scanner.utils.serialize
import io.flutter.embedding.engine.systemchannels.PlatformChannel
import io.flutter.plugin.common.EventChannel

/**
 * This class will listen to device orientation changes.
 *
 * When a new orientation is received, the registered listener will be invoked.
 */
class DeviceOrientationListener(
    activity: Activity,
) : OrientationEventListener(activity, SensorManager.SENSOR_DELAY_NORMAL), EventChannel.StreamHandler {

    // The event sink that handles device orientation events.
    private var deviceOrientationEventSink: EventChannel.EventSink? = null

    // The last received orientation. This is used to prevent duplicate events.
    private var lastOrientation: PlatformChannel.DeviceOrientation? = null

    override fun onListen(event: Any?, eventSink: EventChannel.EventSink?) {
        deviceOrientationEventSink = eventSink
    }

    override fun onCancel(event: Any?) {
        deviceOrientationEventSink = null
    }

    /**
     * Start listening to device orientation changes.
     */
    fun start() {
        if (canDetectOrientation()) {
            enable()
        }
    }

    /**
     * Stop listening to device orientation changes.
     */
    fun stop() {
        disable()
    }

    override fun onOrientationChanged(orientation: Int) {
        if (orientation == ORIENTATION_UNKNOWN) {
            return
        }

        val newOrientation = when (orientation) {
            in 45..134 -> PlatformChannel.DeviceOrientation.LANDSCAPE_RIGHT
            in 135..224 -> PlatformChannel.DeviceOrientation.PORTRAIT_DOWN
            in 225..314 -> PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT
            else -> PlatformChannel.DeviceOrientation.PORTRAIT_UP
        }

        if (newOrientation != lastOrientation) {
            lastOrientation = newOrientation
            Handler(Looper.getMainLooper()).post {
                deviceOrientationEventSink?.success(newOrientation.serialize())
            }
        }
    }

    fun getOrientation(): PlatformChannel.DeviceOrientation {
        return lastOrientation ?: PlatformChannel.DeviceOrientation.PORTRAIT_UP
    }
}
