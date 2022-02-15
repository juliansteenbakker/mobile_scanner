package dev.steenbakker.mobile_scanner

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** MobileScannerPlugin */
class MobileScannerPlugin : FlutterPlugin, ActivityAware {
    private var flutter: FlutterPlugin.FlutterPluginBinding? = null
    private var activity: ActivityPluginBinding? = null
    private var handler: MobileScanner? = null
    private var method: MethodChannel? = null
    private var event: EventChannel? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutter = binding
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutter = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        handler = MobileScanner(activity!!.activity, flutter!!.textureRegistry)
        method = MethodChannel(flutter!!.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/method")
        event = EventChannel(flutter!!.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/event")
        method!!.setMethodCallHandler(handler)
        event!!.setStreamHandler(handler)
        activity!!.addRequestPermissionsResultListener(handler!!)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity!!.removeRequestPermissionsResultListener(handler!!)
        event!!.setStreamHandler(null)
        method!!.setMethodCallHandler(null)
        event = null
        method = null
        handler = null
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}
