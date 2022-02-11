package dev.steenbakker.mobile_scanner

import android.Manifest
import android.R.attr.height
import android.R.attr.width
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.params.StreamConfigurationMap
import android.util.Log
import android.util.Rational
import android.util.Size
import android.view.Surface
import android.view.Surface.ROTATION_0
import android.view.Surface.ROTATION_180
import androidx.annotation.IntDef
import androidx.annotation.NonNull
import androidx.camera.core.*
import androidx.camera.core.impl.PreviewConfig
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry


class MobileScanner(private val activity: Activity, private val textureRegistry: TextureRegistry)
    : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val REQUEST_CODE = 19930430
    }

    private var sink: EventChannel.EventSink? = null
    private var listener: PluginRegistry.RequestPermissionsResultListener? = null

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    @AnalyzeMode
    private var analyzeMode: Int = AnalyzeMode.NONE

    @ExperimentalGetImage
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "state" -> stateNative(result)
            "request" -> requestNative(result)
            "start" -> startNative(call, result)
            "torch" -> torchNative(call, result)
            "analyze" -> analyzeNative(call, result)
            "stop" -> stopNative(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        return listener?.onRequestPermissionsResult(requestCode, permissions, grantResults) ?: false
    }

    private fun stateNative(result: MethodChannel.Result) {
        // Can't get exact denied or not_determined state without request. Just return not_determined when state isn't authorized
        val state =
                if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) 1
                else 0
        result.success(state)
    }

    private fun requestNative(result: MethodChannel.Result) {
        listener = PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode != REQUEST_CODE) {
                false
            } else {
                val authorized = grantResults[0] == PackageManager.PERMISSION_GRANTED
                result.success(authorized)
                listener = null
                true
            }
        }
        val permissions = arrayOf(Manifest.permission.CAMERA)
        ActivityCompat.requestPermissions(activity, permissions, REQUEST_CODE)
    }

    private var sensorOrientation = 0

    @ExperimentalGetImage
//    @androidx.camera.camera2.interop.ExperimentalCamera2Interop
    private fun startNative(call: MethodCall, result: MethodChannel.Result) {

        val targetWidth: Int? = call.argument<Int>("targetWidth")
        val targetHeight: Int? = call.argument<Int>("targetHeight")
        val facing: Int? = call.argument<Int>("facing")

        if (targetWidth == null || targetHeight == null) {
            result.error("INVALID_ARGUMENT", "Missing a required argument", "Expecting targetWidth, targetHeight")
            return
        }

        Log.i("LOG", "Target resolution : $targetWidth, $targetHeight")

        val future = ProcessCameraProvider.getInstance(activity)
        val executor = ContextCompat.getMainExecutor(activity)
        future.addListener({
            cameraProvider = future.get()
            textureEntry = textureRegistry.createSurfaceTexture()
            val textureId = textureEntry!!.id()
            // Preview
            val surfaceProvider = Preview.SurfaceProvider { request ->
                val texture = textureEntry!!.surfaceTexture()
                val resolution = request.resolution
                texture.setDefaultBufferSize(resolution.width, resolution.height)
                Log.i("LOG", "Image resolution : ${request.resolution}")
                val surface = Surface(texture)
                request.provideSurface(surface, executor) { }
            }
//            PreviewConfig().apply {  }
//            val previewConfig = PreviewConfig.Builder().apply {
//                setTargetAspectRatio(SQUARE_ASPECT_RATIO)
//                setTargetRotation(viewFinder.display.rotation)
//            }.build()


            val preview = Preview.Builder()
                    .setTargetResolution(Size(targetWidth, targetHeight))
                    .build().apply { setSurfaceProvider(surfaceProvider) }
            // Analyzer
            val analyzer = ImageAnalysis.Analyzer { imageProxy -> // YUV_420_888 format
                when (analyzeMode) {
                    AnalyzeMode.BARCODE -> {
                        val mediaImage = imageProxy.image ?: return@Analyzer
                        val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                        val scanner = BarcodeScanning.getClient()
                        scanner.process(inputImage)
                                .addOnSuccessListener { barcodes ->
                                    for (barcode in barcodes) {
                                        val event = mapOf("name" to "barcode", "data" to barcode.data)
                                        sink?.success(event)
                                    }
                                }
                                .addOnFailureListener { e -> Log.e(TAG, e.message, e) }
                                .addOnCompleteListener { imageProxy.close() }
                    }
                    else -> imageProxy.close()
                }
            }
            val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setTargetResolution(Size(targetWidth, targetHeight))
                    .build().apply { setAnalyzer(executor, analyzer) }
            // Bind to lifecycle.
            val owner = activity as LifecycleOwner
            val selector =
                    if (call.arguments == 0) CameraSelector.DEFAULT_FRONT_CAMERA
                    else CameraSelector.DEFAULT_BACK_CAMERA
            camera = cameraProvider!!.bindToLifecycle(owner, selector, preview, analysis)

            val analysisSize =  analysis.resolutionInfo?.resolution  ?: Size(0, 0)
            val previewSize =  preview.resolutionInfo?.resolution ?: Size(0, 0)
                            Log.i("LOG", "Analyzer: $analysisSize")
                            Log.i("LOG", "Preview: $previewSize")

            camera!!.cameraInfo.torchState.observe(owner) { state ->
                // TorchState.OFF = 0; TorchState.ON = 1
                val event = mapOf("name" to "torchState", "data" to state)
                sink?.success(event)
            }

            val resolution = preview.resolutionInfo!!.resolution
            val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()
//            val size = mapOf("width" to 1920.0, "height" to 1080.0)
            val size = if (portrait) mapOf("width" to width, "height" to height) else mapOf("width" to height, "height" to width)
            val answer = mapOf("textureId" to textureId, "size" to size, "torchable" to camera!!.torchable)
            result.success(answer)
        }, executor)
    }

    private fun torchNative(call: MethodCall, result: MethodChannel.Result) {
        val state = call.arguments == 1
        camera!!.cameraControl.enableTorch(state)
        result.success(null)
    }

    private fun analyzeNative(call: MethodCall, result: MethodChannel.Result) {
        analyzeMode = call.arguments as Int
        result.success(null)
    }

    private fun stopNative(result: MethodChannel.Result) {
        val owner = activity as LifecycleOwner
        camera!!.cameraInfo.torchState.removeObservers(owner)
        cameraProvider!!.unbindAll()
        textureEntry!!.release()

        analyzeMode = AnalyzeMode.NONE
        camera = null
        textureEntry = null
        cameraProvider = null

        result.success(null)
    }
}

@IntDef(AnalyzeMode.NONE, AnalyzeMode.BARCODE)
@Target(AnnotationTarget.FIELD)
@Retention(AnnotationRetention.SOURCE)
annotation class AnalyzeMode {
    companion object {
        const val NONE = 0
        const val BARCODE = 1
    }
}