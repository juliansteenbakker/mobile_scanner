package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Size
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

    private val analyzeImageErrorCallback: AnalyzerErrorCallback = {
        Handler(Looper.getMainLooper()).post {
            analyzerResult?.error("MobileScanner", it, null)
            analyzerResult = null
        }
    }

    private val analyzeImageSuccessCallback: AnalyzerSuccessCallback = {
        Handler(Looper.getMainLooper()).post {
            analyzerResult?.success(mapOf(
                "name" to "barcode",
                "data" to it
            ))
            analyzerResult = null
        }
    }

    private var analyzerResult: MethodChannel.Result? = null

    private val callback: MobileScannerCallback = { barcodes: List<Map<String, Any?>>, image: ByteArray?, width: Int?, height: Int? ->
        if (image != null) {
            barcodeHandler.publishEvent(mapOf(
                "name" to "barcode",
                "data" to barcodes,
                "image" to mapOf(
                    "bytes" to image,
                    "width" to width?.toDouble(),
                    "height" to height?.toDouble(),
                )
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
        // Off = 0, On = 1
        barcodeHandler.publishEvent(mapOf("name" to "torchState", "data" to state))
    }

    private val zoomScaleStateCallback: ZoomScaleStateCallback = {zoomScale: Double ->
        barcodeHandler.publishEvent(mapOf("name" to "zoomScaleState", "data" to zoomScale))
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
        mobileScanner?.dispose()
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
            "stop" -> stop(result)
            "toggleTorch" -> toggleTorch(result)
            "analyzeImage" -> analyzeImage(call, result)
            "setScale" -> setScale(call, result)
            "resetScale" -> resetScale(result)
            "updateScanWindow" -> updateScanWindow(call, result)
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
        val cameraResolutionValues: List<Int>? = call.argument<List<Int>>("cameraResolution")
        val useNewCameraSelector: Boolean = call.argument<Boolean>("useNewCameraSelector") ?: false
        val cameraResolution: Size? = if (cameraResolutionValues != null) {
            Size(cameraResolutionValues[0], cameraResolutionValues[1])
        } else {
            null
        }

        var barcodeScannerOptions: BarcodeScannerOptions? = null
        if (formats != null) {
            val formatsList: MutableList<Int> = mutableListOf()
            for (formatValue in formats) {
                formatsList.add(BarcodeFormats.fromRawValue(formatValue).intValue)
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

        val detectionSpeed: DetectionSpeed = if (speed == 0) DetectionSpeed.NO_DUPLICATES
        else if (speed ==1) DetectionSpeed.NORMAL else DetectionSpeed.UNRESTRICTED

        mobileScanner!!.start(
            barcodeScannerOptions,
            returnImage,
            position,
            torch,
            detectionSpeed,
            torchStateCallback,
            zoomScaleStateCallback,
            mobileScannerStartedCallback = {
                Handler(Looper.getMainLooper()).post {
                    result.success(mapOf(
                        "textureId" to it.id,
                        "size" to mapOf("width" to it.width, "height" to it.height),
                        "currentTorchState" to it.currentTorchState,
                        "numberOfCameras" to it.numberOfCameras
                    ))
                }
            },
            mobileScannerErrorCallback = {
                Handler(Looper.getMainLooper()).post {
                    when (it) {
                        is AlreadyStarted -> {
                            result.error(
                                "MobileScanner",
                                "Called start() while already started",
                                null
                            )
                        }
                        is CameraError -> {
                            result.error(
                                "MobileScanner",
                                "Error occurred when setting up camera!",
                                null
                            )
                        }
                        is NoCamera -> {
                            result.error(
                                "MobileScanner",
                                "No camera found or failed to open camera!",
                                null
                            )
                        }
                        else -> {
                            result.error(
                                "MobileScanner",
                                "Unknown error occurred.",
                                null
                            )
                        }
                    }
                }
            },
            timeout.toLong(),
            cameraResolution,
            useNewCameraSelector
        )
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

        // TODO: parse options from the method call
        // See https://github.com/juliansteenbakker/mobile_scanner/issues/1069
        mobileScanner!!.analyzeImage(
            uri,
            null,
            analyzeImageSuccessCallback,
            analyzeImageErrorCallback)
    }

    private fun toggleTorch(result: MethodChannel.Result) {
        mobileScanner?.toggleTorch()
        result.success(null)
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

    private fun resetScale(result: MethodChannel.Result) {
        try {
            mobileScanner!!.resetScale()
            result.success(null)
        } catch (e: ZoomWhenStopped) {
            result.error("MobileScanner", "Called resetScale() while stopped!", null)
        }
    }

    private fun updateScanWindow(call: MethodCall, result: MethodChannel.Result) {
        mobileScanner?.scanWindow = call.argument<List<Float>?>("rect")

        result.success(null)
    }
}
