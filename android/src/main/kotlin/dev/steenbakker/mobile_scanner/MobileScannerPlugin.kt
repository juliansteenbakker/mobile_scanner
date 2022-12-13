package dev.steenbakker.mobile_scanner

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** MobileScannerPlugin */
class MobileScannerPlugin : FlutterPlugin, ActivityAware {
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var methodCallHandler: MethodCallHandlerImpl? = null
    private var handler: MobileScanner? = null
    private var method: MethodChannel? = null

    private lateinit var barcodeHandler: BarcodeHandler

    private var analyzerResult: MethodChannel.Result? = null

    private val callback: MobileScannerCallback = { barcodes: List<Map<String, Any?>>, image: ByteArray?, width: Int?, height: Int? ->
        if (image != null) {
            barcodeHandler.publishEvent(mapOf(
                "name" to "barcode",
                "data" to barcodes,
                "image" to image,
                "width" to width!!.toDouble(),
                "height" to height!!.toDouble()
            ))
        } else {
            barcodeHandler.publishEvent(mapOf(
                "name" to "barcode",
                "data" to barcodes
            ))
        }
    }

    private val analyzerCallback: AnalyzerCallback = { barcodes: List<Map<String, Any?>>?->
        if (barcodes != null) {
            barcodeHandler.publishEvent(mapOf(
                "name" to "barcode",
                "data" to barcodes
            ))
            analyzerResult?.success(true)
        } else {
            analyzerResult?.success(false)
        }
        analyzerResult = null
    }

    private val errorCallback: MobileScannerErrorCallback = {error: String ->
        barcodeHandler.publishEvent(mapOf(
            "name" to "error",
            "data" to error,
        ))
    }

    private val torchStateCallback: TorchStateCallback = {state: Int ->
        barcodeHandler.publishEvent(mapOf("name" to "torchState", "data" to state))
    }

    @ExperimentalGetImage
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (handler == null) {
            result.error("MobileScanner", "Called ${call.method} before initializing.", null)
            return
        }
        when (call.method) {
            "state" -> result.success(handler!!.hasCameraPermission())
            "request" -> handler!!.requestPermission(result)
            "start" -> start(call, result)
            "torch" -> toggleTorch(call, result)
            "stop" -> stop(result)
            "analyzeImage" -> analyzeImage(call, result)
            "setScale" -> setScale(call, result)
            "updateScanWindow" -> updateScanWindow(call)
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = binding
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = null
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        val binaryMessenger = this.flutterPluginBinding!!.binaryMessenger

        methodCallHandler = MethodCallHandlerImpl(
            activityPluginBinding.activity,
            BarcodeHandler(binaryMessenger),
            binaryMessenger,
            MobileScannerPermissions(),
            activityPluginBinding::addRequestPermissionsResultListener,
            this.flutterPluginBinding!!.textureRegistry,
        )

        this.activityPluginBinding = activityPluginBinding
    }

    override fun onDetachedFromActivity() {
        methodCallHandler?.dispose(this.activityPluginBinding!!)
        methodCallHandler = null
        activityPluginBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private fun setScale(call: MethodCall, result: MethodChannel.Result) {
        try {
            handler!!.setScale(call.arguments as Double)
            result.success(null)
        } catch (e: ZoomWhenStopped) {
            result.error("MobileScanner", "Called setScale() while stopped!", null)
        } catch (e: ZoomNotInRange) {
            result.error("MobileScanner", "Scale should be within 0 and 1", null)
        }
    }
    
    private fun updateScanWindow(call: MethodCall) {
        handler!!.scanWindow = call.argument<List<Float>>("rect")
    }
}
