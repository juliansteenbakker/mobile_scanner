package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Display
import android.view.OrientationEventListener
import android.view.Surface
import android.view.WindowManager
import dev.steenbakker.mobile_scanner.utils.serialize
import io.flutter.embedding.engine.systemchannels.PlatformChannel
import io.flutter.plugin.common.EventChannel

/**
 * This class listens to display orientation changes.
 *
 * The orientation is determined from the display rotation rather than raw sensor data.
 * This ensures that the reported orientation respects both the system rotation lock
 * and Flutter `SystemChrome.setPreferredOrientations`.
 */
class DeviceOrientationListener(
    private val activity: Activity,
) : EventChannel.StreamHandler {

    // The event sink that handles device orientation events.
    private var deviceOrientationEventSink: EventChannel.EventSink? = null

    // The last received orientation. This is used to prevent duplicate events.
    private var lastOrientation: PlatformChannel.DeviceOrientation? = null

    // Called with the new [Surface.ROTATION_*] value whenever the display rotation changes.
    var onDisplayRotationChanged: ((Int) -> Unit)? = null

    private val handler = Handler(Looper.getMainLooper())

    private val rotationCheck = Runnable { checkRotation() }

    // The last physical orientation quadrant reported by the orientation sensor.
    // Used to limit rotation checks to actual 90-degree device turns.
    private var lastSensorQuadrant = -1

    // Listener for display configuration changes.
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
        override fun onDisplayChanged(displayId: Int) {
            // On some devices (e.g. Samsung) this callback can fire before the
            // display object reflects the new rotation. Check now and re-check
            // shortly after; [checkRotation] deduplicates, so the extra checks
            // are harmless.
            checkRotation()
            scheduleDelayedRotationChecks()
        }
    }

    // Sensor based fallback for devices where the display listener does not
    // fire (reliably) on rotation, e.g. seamless 180 degree rotations between
    // the two landscape orientations. The actual orientation is still read
    // from the display rotation in [checkRotation], so the system rotation
    // lock and the app's preferred orientations remain respected.
    private val orientationEventListener = object : OrientationEventListener(activity) {
        override fun onOrientationChanged(orientation: Int) {
            if (orientation == ORIENTATION_UNKNOWN) {
                return
            }
            val quadrant = ((orientation + 45) / 90) % 4
            if (quadrant != lastSensorQuadrant) {
                lastSensorQuadrant = quadrant
                // The display rotation usually settles some time after the
                // physical rotation, so check again after a delay.
                checkRotation()
                scheduleDelayedRotationChecks()
            }
        }
    }

    override fun onListen(event: Any?, eventSink: EventChannel.EventSink?) {
        deviceOrientationEventSink = eventSink
    }

    override fun onCancel(event: Any?) {
        deviceOrientationEventSink = null
    }

    /**
     * Start listening to display orientation changes.
     */
    fun start() {
        // Re-sync the cached orientation with the actual display rotation.
        // The display listener is unregistered while the camera is stopped, so
        // rotations that happen in that window would otherwise leave
        // [lastOrientation] stale, and [getOrientation] would report the wrong
        // initial orientation on the next camera start.
        lastOrientation = getUIOrientation()
        lastSensorQuadrant = -1
        val displayManager = activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayManager.registerDisplayListener(displayListener, handler)
        if (orientationEventListener.canDetectOrientation()) {
            orientationEventListener.enable()
        }
        // Emit the orientation on every camera start, so that listeners that
        // survive a stop/start cycle (e.g. when switching cameras) are
        // re-synced even if the device was rotated while the camera was
        // stopped, in which case no rotation change event was observed.
        lastOrientation?.let { orientation ->
            handler.post {
                deviceOrientationEventSink?.success(orientation.serialize())
            }
        }
    }

    /**
     * Stop listening to display orientation changes.
     */
    fun stop() {
        orientationEventListener.disable()
        val displayManager = activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayManager.unregisterDisplayListener(displayListener)
        handler.removeCallbacks(rotationCheck)
        onDisplayRotationChanged = null
    }

    /**
     * Schedule delayed re-checks of the display rotation, to catch rotations
     * that are only reflected on the display after the triggering callback.
     */
    private fun scheduleDelayedRotationChecks() {
        handler.postDelayed(rotationCheck, 150)
        handler.postDelayed(rotationCheck, 500)
    }

    /**
     * Propagate the current display rotation and send an orientation event if
     * the orientation changed.
     */
    private fun checkRotation() {
        onDisplayRotationChanged?.invoke(getDisplay().rotation)
        sendOrientationIfChanged()
    }

    @Suppress("deprecation")
    private fun getDisplay(): Display {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.let { return it }
        }
        return (activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay
    }

    /**
     * Gets the current user interface orientation from the display.
     * This respects the system's rotation lock setting.
     */
    private fun getUIOrientation(): PlatformChannel.DeviceOrientation {
        return when (getDisplay().rotation) {
            Surface.ROTATION_0 -> PlatformChannel.DeviceOrientation.PORTRAIT_UP
            Surface.ROTATION_90 -> PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT
            Surface.ROTATION_180 -> PlatformChannel.DeviceOrientation.PORTRAIT_DOWN
            Surface.ROTATION_270 -> PlatformChannel.DeviceOrientation.LANDSCAPE_RIGHT
            else -> PlatformChannel.DeviceOrientation.PORTRAIT_UP
        }
    }

    /**
     * Check the current display orientation and send an event if it changed.
     */
    private fun sendOrientationIfChanged() {
        val newOrientation = getUIOrientation()

        if (newOrientation != lastOrientation) {
            lastOrientation = newOrientation
            Handler(Looper.getMainLooper()).post {
                deviceOrientationEventSink?.success(newOrientation.serialize())
            }
        }
    }

    fun getOrientation(): PlatformChannel.DeviceOrientation {
        return lastOrientation ?: getUIOrientation()
    }
}
