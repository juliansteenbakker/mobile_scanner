package dev.steenbakker.mobile_scanner

import android.net.Uri
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import dev.steenbakker.mobile_scanner.objects.BarcodeFormats
import dev.steenbakker.mobile_scanner.objects.DetectionSpeed
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** MobileScannerPlugin */
class MobileScannerPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var handler: MobileScanner? = null
    private var method: MethodChannel? = null

    private lateinit var barcodeHandler: BarcodeHandler

    private var permissionResult: MethodChannel.Result? = null
    private var analyzerResult: MethodChannel.Result? = null

    private val permissionCallback: PermissionCallback = {hasPermission: Boolean ->
        permissionResult?.success(hasPermission)
        permissionResult = null
    }

    private val callback: MobileScannerCallback = { barcodes: List<Map<String, Any?>>, image: ByteArray? ->
        if (image != null) {
            barcodeHandler.publishEvent(mapOf(
                "name" to "barcode",
                "data" to barcodes,
                "image" to image
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
            "request" -> requestPermission(result)
            "start" -> start(call, result)
            "torch" -> toggleTorch(call, result)
            "stop" -> stop(result)
            "analyzeImage" -> analyzeImage(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        method = MethodChannel(binding.binaryMessenger, "dev.steenbakker.mobile_scanner/scanner/method")
        method!!.setMethodCallHandler(this)

        barcodeHandler = BarcodeHandler(binding)

        this.flutterPluginBinding = binding
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = null
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        handler = MobileScanner(activityPluginBinding.activity, flutterPluginBinding!!.textureRegistry, callback, errorCallback
        )
        activityPluginBinding.addRequestPermissionsResultListener(handler!!)

        this.activityPluginBinding = activityPluginBinding
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityPluginBinding!!.removeRequestPermissionsResultListener(handler!!)
        method!!.setMethodCallHandler(null)
        method = null
        handler = null
        activityPluginBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private fun requestPermission(result: MethodChannel.Result) {
        permissionResult = result
        handler!!.requestPermission(permissionCallback)
    }

    @ExperimentalGetImage
    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val torch: Boolean = call.argument<Boolean>("torch") ?: false
        val facing: Int = call.argument<Int>("facing") ?: 0
        val formats: List<Int>? = call.argument<List<Int>>("formats")
        val returnImage: Boolean = call.argument<Boolean>("returnImage") ?: false
        val speed: Int = call.argument<Int>("speed") ?: 1
        val timeout: Int = call.argument<Int>("timeout") ?: 250

        var barcodeScannerOptions: BarcodeScannerOptions? = null
        if (formats != null) {
            val formatsList: MutableList<Int> = mutableListOf()
            for (index in formats) {
                formatsList.add(BarcodeFormats.values()[index].intValue)
            }
            barcodeScannerOptions = if (formatsList.size == 1) {
                BarcodeScannerOptions.Builder().setBarcodeFormats(formatsList.first())
                    .build()
            } else {
                BarcodeScannerOptions.Builder().setBarcodeFormats(
                    formatsList.first(),
                    *formatsList.subList(1, formatsList.size).toIntArray()
                ).build()
            }
        }

        val position =
            if (facing == 0) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA

        val detectionSpeed: DetectionSpeed = DetectionSpeed.values().first { it.intValue == speed}

        try {
            handler!!.start(barcodeScannerOptions, returnImage, position, torch, detectionSpeed, torchStateCallback, mobileScannerStartedCallback = {
                result.success(mapOf(
                    "textureId" to it.id,
                    "size" to mapOf("width" to it.width, "height" to it.height),
                    "torchable" to it.hasFlashUnit
                ))
            },
                timeout.toLong())

        } catch (e: AlreadyStarted) {
            result.error(
                "MobileScanner",
            "Called start() while already started",
                null
            )
        } catch (e: NoCamera) {
            result.error(
                "MobileScanner",
                "No camera found or failed to open camera!",
                null
            )
        } catch (e: TorchError) {
            result.error(
                "MobileScanner",
                "Error occurred when setting torch!",
                null
            )
        } catch (e: CameraError) {
            result.error(
                "MobileScanner",
                "Error occurred when setting up camera!",
                null
            )
        } catch (e: Exception) {
            result.error(
                "MobileScanner",
                "Unknown error occurred..",
                null
            )
        }
    }

    private fun stop(result: MethodChannel.Result) {
        try {
            handler!!.stop()
            result.success(null)
        } catch (e: AlreadyStopped) {
            result.error("MobileScanner", "Called stop() while already stopped!", null)
        }
    }

    private fun analyzeImage(call: MethodCall, result: MethodChannel.Result) {
        analyzerResult = result
        val uri = Uri.fromFile(File(call.arguments.toString()))
        handler!!.analyzeImage(uri, analyzerCallback)
    }

    private fun toggleTorch(call: MethodCall, result: MethodChannel.Result) {
        try {
            handler!!.toggleTorch(call.arguments == 1)
            result.success(null)
        } catch (e: AlreadyStopped) {
            result.error("MobileScanner", "Called toggleTorch() while stopped!", null)
        }
    }
}
