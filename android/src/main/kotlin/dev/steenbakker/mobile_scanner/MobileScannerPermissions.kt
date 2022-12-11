package dev.steenbakker.mobile_scanner

import android.Manifest.permission
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

/**
 * This class handles the camera permissions for the Mobile Scanner.
 */
class MobileScannerPermissions {
    companion object {
        const val CAMERA_ACCESS_DENIED = "CameraAccessDenied"
        const val CAMERA_ACCESS_DENIED_MESSAGE = "Camera access permission was denied."
        const val CAMERA_PERMISSIONS_REQUEST_ONGOING = "CameraPermissionsRequestOngoing"
        const val CAMERA_PERMISSIONS_REQUEST_ONGOING_MESSAGE = "Another request is ongoing and multiple requests cannot be handled at once."

        /**
         * When the application's activity is [androidx.fragment.app.FragmentActivity], requestCode can only use the lower 16 bits.
         * @see androidx.fragment.app.FragmentActivity.validateRequestPermissionsRequestCode
         */
        const val REQUEST_CODE = 0x0786
    }

    interface PermissionsRegistry {
        @SuppressWarnings("deprecation")
        fun addListener(handler: RequestPermissionsResultListener)
    }

    interface ResultCallback {
        fun onResult(errorCode: String?, errorDescription: String?)
    }

    private var listener: RequestPermissionsResultListener? = null

    fun getPermissionListener(): RequestPermissionsResultListener? {
        return listener
    }

    private var ongoing: Boolean = false

    fun hasCameraPermission(activity: Activity) : Int {
        val hasPermission = ContextCompat.checkSelfPermission(
            activity,
            permission.CAMERA,
        ) == PackageManager.PERMISSION_GRANTED

        return if (hasPermission) {
            1
        } else {
            0
        }
    }

    fun requestPermission(activity: Activity,
                          permissionsRegistry: PermissionsRegistry,
                          callback: ResultCallback) {
        if (ongoing) {
            callback.onResult(
                CAMERA_PERMISSIONS_REQUEST_ONGOING, CAMERA_PERMISSIONS_REQUEST_ONGOING_MESSAGE)
            return
        }

        if(hasCameraPermission(activity) == 1) {
            // Permissions already exist. Call the callback with success.
            callback.onResult(null, null)
            return
        }

        if(listener == null) {
            // Keep track of the listener, so that it can be unregistered later.
            listener = MobileScannerPermissionsListener(
                object: ResultCallback {
                    override fun onResult(errorCode: String?, errorDescription: String?) {
                        ongoing = false
                        callback.onResult(errorCode, errorDescription)
                    }
                }
            )
            permissionsRegistry.addListener(listener)
        }

        ongoing = true
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(permission.CAMERA),
            REQUEST_CODE
        )
    }
}

/**
 * This class handles incoming camera permission results.
 */
@SuppressWarnings("deprecation")
private class MobileScannerPermissionsListener(
    private val resultCallback: MobileScannerPermissions.ResultCallback,
): RequestPermissionsResultListener {
    // There's no way to unregister permission listeners in the v1 embedding, so we'll be called
    // duplicate times in cases where the user denies and then grants a permission. Keep track of if
    // we've responded before and bail out of handling the callback manually if this is a repeat
    // call.
    private var alreadyCalled: Boolean = false

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (alreadyCalled || requestCode != MobileScannerPermissions.REQUEST_CODE) {
            return false
        }

        alreadyCalled = true

        // grantResults could be empty if the permissions request with the user is interrupted
        // https://developer.android.com/reference/android/app/Activity#onRequestPermissionsResult(int,%20java.lang.String[],%20int[])
        if (grantResults.isEmpty() || grantResults[0] != PackageManager.PERMISSION_GRANTED) {
            resultCallback.onResult(
                MobileScannerPermissions.CAMERA_ACCESS_DENIED,
                MobileScannerPermissions.CAMERA_ACCESS_DENIED_MESSAGE)
        } else {
            resultCallback.onResult(null, null)
        }

        return true
    }
}