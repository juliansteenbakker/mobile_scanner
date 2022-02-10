package dev.steenbakker.mobile_scanner.old

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.util.Log
import androidx.annotation.NonNull
import androidx.camera.core.ExperimentalGetImage
import androidx.core.app.ActivityCompat
import dev.steenbakker.mobile_scanner.exceptions.NoPermissionException

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import io.flutter.view.TextureRegistry
import java.io.IOException

/** MobileScannerPlugin */
class MobileScannerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
  RequestPermissionsResultListener, EventChannel.StreamHandler {

  private lateinit var textures: TextureRegistry
  private lateinit var channel : MethodChannel
  private lateinit var event : EventChannel
  private var activity: Activity? = null
  private var waitingForPermissionResult = false
  private var sink: EventChannel.EventSink? = null

  private var mobileScanner: MobileScanner? = null

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    textures = flutterPluginBinding.textureRegistry
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/method")
    event = EventChannel(flutterPluginBinding.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/event")
    channel.setMethodCallHandler(this)
    event.setStreamHandler(this)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    this.sink = events
  }

  override fun onCancel(arguments: Any?) {
    sink = null
  }


  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<String?>?,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == 105505) {
      waitingForPermissionResult = false
      if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        Log.i(
          "mobile_scanner",
          "Permissions request granted."
        )
        mobileScanner?.stop()
      } else {
        Log.i(
          "mobile_scanner",
          "Permissions request denied."
        )
        mobileScanner?.stop()
      }
      return true
    }
    return false
  }

  @ExperimentalGetImage
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
  when (call.method) {
    "start" -> {
//        val targetWidth: Int? = call.argument<Int>("targetWidth")
//        val targetHeight: Int? = call.argument<Int>("targetHeight")
//        val formatStrings: List<String>? = call.argument<List<String>>("formats")
//        if (targetWidth == null || targetHeight == null) {
//          result.error(
//            "INVALID_ARGUMENT",
//            "Missing a required argument",
//            "Expecting targetWidth, targetHeight"
//          )
//          return
//        }

//        val options: BarcodeScannerOptions = BarcodeFormats.optionsFromStringList(formatStrings)

//        mobileScanner ?:

        try {
          MobileScanner(activity!!, textures).start(result, null, channel)
        } catch (e: IOException) {
          e.printStackTrace()
          result.error(
            "IOException",
            "Error starting camera because of IOException: " + e.localizedMessage,
            null
          )
        } catch (e: MobileScanner.Exception) {
          e.printStackTrace()
          result.error(
            e.reason.name,
            "Error starting camera for reason: " + e.reason.name,
            null
          )
        } catch (e: NoPermissionException) {
          waitingForPermissionResult = true
          ActivityCompat.requestPermissions(
            activity!!,
            arrayOf(Manifest.permission.CAMERA),
            105505
          )
        }
      }
    "stop" -> {
      if (mobileScanner != null && !waitingForPermissionResult) {
        mobileScanner!!.stop()
      }
      result.success(null)
    }
    else -> result.notImplemented()
  }
  }

}
