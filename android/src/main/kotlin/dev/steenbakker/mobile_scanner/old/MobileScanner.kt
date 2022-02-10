package dev.steenbakker.mobile_scanner.old

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import android.view.Surface
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import dev.steenbakker.mobile_scanner.exceptions.NoPermissionException
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.io.IOException

internal class MobileScanner(
    private val context: Activity,
    private val texture: TextureRegistry
) {

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    @ExperimentalGetImage
    @Throws(IOException::class, NoPermissionException::class, Exception::class)
    fun start(
        result: MethodChannel.Result,
        options: BarcodeScannerOptions?,
        channel: MethodChannel
    ) {
        if (!hasCameraHardware(context)) {
            throw Exception(Exception.Reason.noHardware)
        }
        if (!checkCameraPermission(context)) {
            throw NoPermissionException()
        }

        textureEntry = texture.createSurfaceTexture()
        val textureId = textureEntry!!.id()

        val future = ProcessCameraProvider.getInstance(context)
        val executor = ContextCompat.getMainExecutor(context)
        future.addListener({

            // Preview
            val surfaceProvider = Preview.SurfaceProvider { request ->
                val resolution = request.resolution
                val texture = textureEntry!!.surfaceTexture()
                texture.setDefaultBufferSize(resolution.width, resolution.height)
                val surface = Surface(texture)
                request.provideSurface(surface, executor, { })
            }

            val preview = Preview.Builder().build().apply { setSurfaceProvider(surfaceProvider) }
            val analyzer = ImageAnalysis.Analyzer { imageProxy -> // YUV_420_888 format
                val mediaImage = imageProxy.image ?: return@Analyzer
                val inputImage =
                    InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
               val scanner = if (options != null) {
                    BarcodeScanning.getClient(options)
                } else {
                    BarcodeScanning.getClient()
                }

                scanner.process(inputImage)
                    .addOnSuccessListener { barcodes ->
                        val barcodeList: MutableList<Map<String, Any?>> = mutableListOf()
                        for (barcode in barcodes) {
                            barcodeList.add(
                                mapOf(
                                    "value" to barcode.rawValue,
                                    "bytes" to barcode.rawBytes
                                )
                            )

                        }
                        channel.invokeMethod("qrRead", barcodeList)
                    }
                    .addOnFailureListener { e -> Log.e("Camera", e.message, e) }
                    .addOnCompleteListener { imageProxy.close() }
            }
            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build().apply { setAnalyzer(executor, analyzer) }
            // Bind to lifecycle.
            val owner = context as LifecycleOwner
//            val selector =
//                if (call.arguments == 0) CameraSelector.DEFAULT_FRONT_CAMERA
//                else CameraSelector.DEFAULT_BACK_CAMERA
            camera = cameraProvider!!.bindToLifecycle(
                owner,
                CameraSelector.DEFAULT_BACK_CAMERA,
                preview,
                analysis
            )
            camera!!.cameraInfo.torchState.observe(owner, { state ->
                // TorchState.OFF = 0; TorchState.ON = 1
//                val event = mapOf("name" to "torchState", "data" to state)
//                sink?.success(event)
            })
            // TODO: seems there's not a better way to get the final resolution
            @SuppressLint("RestrictedApi")
            val resolution = preview.attachedSurfaceResolution!!
            val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()
            val size = if (portrait) mapOf(
                "width" to width,
                "height" to height
            ) else mapOf("width" to height, "height" to width)
            result.success(mapOf("textureId" to textureId, "size" to size))
        }, executor)
    }

    fun stop() {
        val owner = context as LifecycleOwner
        camera!!.cameraInfo.torchState.removeObservers(owner)
        cameraProvider!!.unbindAll()
        textureEntry!!.release()

        camera = null
        textureEntry = null
        cameraProvider = null
    }

    private fun hasCameraHardware(context: Context): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
    }

    private fun checkCameraPermission(context: Context): Boolean {
        val permissions = arrayOf(Manifest.permission.CAMERA)
        val res = context.checkCallingOrSelfPermission(permissions[0])
        return res == PackageManager.PERMISSION_GRANTED
    }

    internal class Exception(val reason: Reason) :
        java.lang.Exception("Mobile Scanner failed because $reason") {

        internal enum class Reason {
            noHardware, noPermissions, noBackCamera
        }
    }
}