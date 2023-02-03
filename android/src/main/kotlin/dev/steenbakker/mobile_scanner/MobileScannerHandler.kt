package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.net.Uri
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import dev.steenbakker.mobile_scanner.objects.BarcodeFormats
import dev.steenbakker.mobile_scanner.objects.DetectionSpeed
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.view.TextureRegistry
import java.io.File

class MobileScannerHandler(
    private val activity: Activity,
    private val barcodeHandler: BarcodeHandler,
    binaryMessenger: BinaryMessenger,
    private val permissions: MobileScannerPermissions,
    private val addPermissionListener: (RequestPermissionsResultListener) -> Unit,
    textureRegistry: TextureRegistry): MethodChannel.MethodCallHandler {

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

    private val errorCallback: MobileScannerErrorCallback = {error: String ->
        barcodeHandler.publishEvent(mapOf(
            "name" to "error",
            "data" to error,
        ))
    }

    private var methodChannel: MethodChannel? = null

    private var mobileScanner: MobileScanner? = null

    private val torchStateCallback: TorchStateCallback = {state: Int ->
        barcodeHandler.publishEvent(mapOf("name" to "torchState", "data" to state))
    }

    init {
        methodChannel = MethodChannel(binaryMessenger,
            "dev.steenbakker.mobile_scanner/scanner/method")
        methodChannel!!.setMethodCallHandler(this)
        mobileScanner = MobileScanner(activity, textureRegistry, callback, errorCallback)
    }

    fun dispose(activityPluginBinding: ActivityPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        mobileScanner = null

        val listener: RequestPermissionsResultListener? = permissions.getPermissionListener()

        if(listener != null) {
            activityPluginBinding.removeRequestPermissionsResultListener(listener)
        }

    }

    @ExperimentalGetImage
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (mobileScanner == null) {
            result.error("MobileScanner", "Called ${call.method} before initializing.", null)
            return
        }
        when (call.method) {
            "state" -> result.success(permissions.hasCameraPermission(activity))
            "request" -> permissions.requestPermission(
                activity,
                addPermissionListener,
                object: MobileScannerPermissions.ResultCallback {
                    override fun onResult(errorCode: String?, errorDescription: String?) {
                        when(errorCode) {
                            null -> result.success(true)
                            MobileScannerPermissions.CAMERA_ACCESS_DENIED -> result.success(false)
                            else -> result.error(errorCode, errorDescription, null)
                        }
                    }
                })
            "start" -> start(call, result)
            "torch" -> toggleTorch(call, result)
            "stop" -> stop(result)
            "analyzeImage" -> analyzeImage(call, result)
            "setScale" -> setScale(call, result)
            "updateScanWindow" -> updateScanWindow(call)
            else -> result.notImplemented()
        }
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
            mobileScanner!!.start(barcodeScannerOptions, returnImage, position, torch, detectionSpeed, torchStateCallback, mobileScannerStartedCallback = {
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
            mobileScanner!!.stop()
            result.success(null)
        } catch (e: AlreadyStopped) {
            result.success(null)
        }
    }

    private fun analyzeImage(call: MethodCall, result: MethodChannel.Result) {
        analyzerResult = result
        val uri = Uri.fromFile(File(call.arguments.toString()))
        mobileScanner!!.analyzeImage(uri, analyzerCallback)
    }

    private fun toggleTorch(call: MethodCall, result: MethodChannel.Result) {
        try {
            mobileScanner!!.toggleTorch(call.arguments == 1)
            result.success(null)
        } catch (e: AlreadyStopped) {
            result.error("MobileScanner", "Called toggleTorch() while stopped!", null)
        }
    }

    private fun setScale(call: MethodCall, result: MethodChannel.Result) {
        try {
            mobileScanner!!.setScale(call.arguments as Double)
            result.success(null)
        } catch (e: ZoomWhenStopped) {
            result.error("MobileScanner", "Called setScale() while stopped!", null)
        } catch (e: ZoomNotInRange) {
            result.error("MobileScanner", "Scale should be within 0 and 1", null)
        }
    }

    private fun updateScanWindow(call: MethodCall) {
        mobileScanner!!.scanWindow = call.argument<List<Float>?>("rect")
    }
}