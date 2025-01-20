package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Display
import android.view.Surface
import android.view.WindowManager
import dev.steenbakker.mobile_scanner.utils.serialize
import io.flutter.embedding.engine.systemchannels.PlatformChannel
import io.flutter.plugin.common.EventChannel

/**
 * This class will listen to device orientation changes.
 *
 * When a new orientation is received, the registered listener will be invoked.
 */
class DeviceOrientationListener(
    private val activity: Activity,
): BroadcastReceiver(), EventChannel.StreamHandler {

    companion object {
        // The intent filter for listening to orientation changes.
        private val orientationIntentFilter = IntentFilter(Intent.ACTION_CONFIGURATION_CHANGED)
    }

    // The event sink that handles device orientation events.
    private var deviceOrientationEventSink: EventChannel.EventSink? = null

    // The last received orientation. This is used to prevent duplicate events.
    private var lastOrientation: PlatformChannel.DeviceOrientation? = null
    // Whether the device orientation is currently being observed.
    private var listening = false

    override fun onReceive(context: Context?, intent: Intent?) {
        val orientation: PlatformChannel.DeviceOrientation = getUIOrientation()
        if (orientation != lastOrientation) {
            Handler(Looper.getMainLooper()).post {
                deviceOrientationEventSink?.success(orientation.serialize())
            }
        }

        lastOrientation = orientation
    }

    override fun onListen(event: Any?, eventSink: EventChannel.EventSink?) {
        deviceOrientationEventSink = eventSink
    }

    override fun onCancel(event: Any?) {
        deviceOrientationEventSink = null
    }

    @Suppress("deprecation")
    private fun getDisplay(): Display {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display!!
        } else {
            (activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay
        }
    }

    /**
     * Gets the current user interface orientation.
     */
    fun getUIOrientation(): PlatformChannel.DeviceOrientation {
        val rotation: Int = getDisplay().rotation
        val orientation: Int = activity.resources.configuration.orientation

        return when(orientation) {
            Configuration.ORIENTATION_PORTRAIT -> {
                if (rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_90) {
                    PlatformChannel.DeviceOrientation.PORTRAIT_UP
                } else {
                    PlatformChannel.DeviceOrientation.PORTRAIT_DOWN
                }
            }
            Configuration.ORIENTATION_LANDSCAPE -> {
                if (rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_90) {
                    PlatformChannel.DeviceOrientation.LANDSCAPE_LEFT
                } else {
                    PlatformChannel.DeviceOrientation.LANDSCAPE_RIGHT
                }
            }
            Configuration.ORIENTATION_UNDEFINED -> PlatformChannel.DeviceOrientation.PORTRAIT_UP
            else -> PlatformChannel.DeviceOrientation.PORTRAIT_UP
        }
    }

    /**
     * Start listening to device orientation changes.
     */
    fun start() {
        if (listening) {
            return
        }

        listening = true
        activity.registerReceiver(this, orientationIntentFilter)

        // Trigger the orientation listener with the current value.
        onReceive(activity, null)
    }

    /**
     * Stop listening to device orientation changes.
     */
    fun stop() {
        if (!listening) {
            return
        }

        activity.unregisterReceiver(this)
        listening = false
    }
}