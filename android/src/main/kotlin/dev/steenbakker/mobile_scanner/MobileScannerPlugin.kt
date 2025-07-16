package dev.steenbakker.mobile_scanner

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

/** MobileScannerPlugin */
class MobileScannerPlugin : FlutterPlugin, ActivityAware {
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var methodCallHandler: MobileScannerHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = binding
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activityPluginBinding = binding

        initializeMethodCallHandler()

    }

    private fun initializeMethodCallHandler() {

        val currentActivityBinding = activityPluginBinding
        val currentFlutterBinding = flutterPluginBinding

        if (currentActivityBinding != null && currentFlutterBinding != null) {


            val binaryMessenger: BinaryMessenger = currentFlutterBinding.binaryMessenger
            val textureRegistry = currentFlutterBinding.textureRegistry


            methodCallHandler?.dispose(currentActivityBinding)
            methodCallHandler = null

            methodCallHandler = MobileScannerHandler(
                currentActivityBinding.activity,
                BarcodeHandler(binaryMessenger),
                binaryMessenger,
                MobileScannerPermissions(),
                currentActivityBinding::addRequestPermissionsResultListener,
                textureRegistry
            )
        } else {

        }
    }

    override fun onDetachedFromActivity() {

        val localActivityPluginBinding = activityPluginBinding
        if (localActivityPluginBinding != null) {
            methodCallHandler?.dispose(localActivityPluginBinding)
        }
        methodCallHandler = null
        this.activityPluginBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activityPluginBinding = binding
        initializeMethodCallHandler()
    }

    override fun onDetachedFromActivityForConfigChanges() {

        onDetachedFromActivity()
    }
}