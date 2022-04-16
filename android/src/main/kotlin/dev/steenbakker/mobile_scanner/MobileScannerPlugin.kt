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
    private var binding: ActivityPluginBinding? = null
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
        this.binding = binding

        flutter?.let {
            handler = MobileScanner(binding.activity, it.textureRegistry)
                .apply {
                    binding.addRequestPermissionsResultListener(this)
                }
            method = MethodChannel(it.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/method")
                .apply {
                    setMethodCallHandler(handler)
                }
            event = EventChannel(it.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/event")
                .apply {
                    setStreamHandler(handler)
                }
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        handler?.let { binding?.removeRequestPermissionsResultListener(it) }
        event?.setStreamHandler(null)
        method?.setMethodCallHandler(null)
        event = null
        method = null
        handler = null
        binding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}
