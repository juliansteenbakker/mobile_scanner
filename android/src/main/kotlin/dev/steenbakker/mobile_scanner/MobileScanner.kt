package dev.steenbakker.mobile_scanner

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Rect
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import dev.steenbakker.mobile_scanner.objects.DetectionSpeed
import dev.steenbakker.mobile_scanner.objects.MobileScannerStartParameters
import dev.steenbakker.mobile_scanner.utils.YuvToRgbConverter
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
import kotlin.math.roundToInt
import android.util.Size
import android.hardware.display.DisplayManager
import android.view.WindowManager
import android.content.Context


class MobileScanner(
    private val activity: Activity,
    private val textureRegistry: TextureRegistry,
    private val mobileScannerCallback: MobileScannerCallback,
    private val mobileScannerErrorCallback: MobileScannerErrorCallback
) {

    /// Internal variables
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var preview: Preview? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var scanner = BarcodeScanning.getClient()
    private var lastScanned: List<String?>? = null
    private var scannerTimeout = false

    /// Configurable variables
    var scanWindow: List<Float>? = null
    private var detectionSpeed: DetectionSpeed = DetectionSpeed.NO_DUPLICATES
    private var detectionTimeout: Long = 250
    private var returnImage = false

    /**
     * callback for the camera. Every frame is passed through this function.
     */
    @ExperimentalGetImage
    val captureOutput = ImageAnalysis.Analyzer { imageProxy -> // YUV_420_888 format
        val mediaImage = imageProxy.image ?: return@Analyzer
        val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)

        if (detectionSpeed == DetectionSpeed.NORMAL && scannerTimeout) {
            imageProxy.close()
            return@Analyzer
        } else if (detectionSpeed == DetectionSpeed.NORMAL) {
            scannerTimeout = true
        }

        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                if (detectionSpeed == DetectionSpeed.NO_DUPLICATES) {
                    val newScannedBarcodes = barcodes.map { barcode -> barcode.rawValue }
                    if (newScannedBarcodes == lastScanned) {
                        // New scanned is duplicate, returning
                        return@addOnSuccessListener
                    }
                    if (newScannedBarcodes.isNotEmpty()) lastScanned = newScannedBarcodes
                }

                val barcodeMap: MutableList<Map<String, Any?>> = mutableListOf()

                for (barcode in barcodes) {
                    if (scanWindow != null) {
                        val match = isBarcodeInScanWindow(scanWindow!!, barcode, imageProxy)
                        if (!match) {
                            continue
                        } else {
                            barcodeMap.add(barcode.data)
                        }
                    } else {
                        barcodeMap.add(barcode.data)
                    }
                }


                if (barcodeMap.isNotEmpty()) {
                    if (returnImage) {

                        val bitmap = Bitmap.createBitmap(mediaImage.width, mediaImage.height, Bitmap.Config.ARGB_8888)

                        val imageFormat = YuvToRgbConverter(activity.applicationContext)

                        imageFormat.yuvToRgb(mediaImage, bitmap)

                        val bmResult = rotateBitmap(bitmap, camera?.cameraInfo?.sensorRotationDegrees?.toFloat() ?: 90f)

                        val stream = ByteArrayOutputStream()
                        bmResult.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        val byteArray = stream.toByteArray()
                        bmResult.recycle()


                        mobileScannerCallback(
                            barcodeMap,
                            byteArray,
                            bmResult.width,
                            bmResult.height
                        )

                    } else {

                        mobileScannerCallback(
                            barcodeMap,
                            null,
                            null,
                            null
                        )
                    }
                }
            }
            .addOnFailureListener { e ->
                mobileScannerErrorCallback(
                    e.localizedMessage ?: e.toString()
                )
            }
            .addOnCompleteListener { imageProxy.close() }

        if (detectionSpeed == DetectionSpeed.NORMAL) {
            // Set timer and continue
            Handler(Looper.getMainLooper()).postDelayed({
                scannerTimeout = false
            }, detectionTimeout)
        }
    }

    fun rotateBitmap(bitmap: Bitmap, degrees: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }


    // scales the scanWindow to the provided inputImage and checks if that scaled
    // scanWindow contains the barcode
    private fun isBarcodeInScanWindow(
        scanWindow: List<Float>,
        barcode: Barcode,
        inputImage: ImageProxy
    ): Boolean {
        val barcodeBoundingBox = barcode.boundingBox ?: return false

        val imageWidth = inputImage.height
        val imageHeight = inputImage.width

        val left = (scanWindow[0] * imageWidth).roundToInt()
        val top = (scanWindow[1] * imageHeight).roundToInt()
        val right = (scanWindow[2] * imageWidth).roundToInt()
        val bottom = (scanWindow[3] * imageHeight).roundToInt()

        val scaledScanWindow = Rect(left, top, right, bottom)
        return scaledScanWindow.contains(barcodeBoundingBox)
    }

    // Return the best resolution for the actual device orientation.
    // By default camera set its resolution to width 480 and height 640 which is too low for ML KIT.
    // If we return an higher resolution than device can handle, camera package take the most relevant one available.
    // Resolution set must take care of device orientation to preserve aspect ratio.
    private fun getResolution(windowManager: WindowManager, androidResolution: Size): Size {
        val rotation = windowManager.defaultDisplay.rotation
        val widthMaxRes = androidResolution.width
        val heightMaxRes = androidResolution.height

        val targetResolution = if (rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180) {
            Size(widthMaxRes, heightMaxRes) // Portrait mode
        } else {
            Size(heightMaxRes, widthMaxRes) // Landscape mode
        }
        return targetResolution
    }


    /**
     * Start barcode scanning by initializing the camera and barcode scanner.
     */
    @ExperimentalGetImage
    fun start(
        barcodeScannerOptions: BarcodeScannerOptions?,
        returnImage: Boolean,
        cameraPosition: CameraSelector,
        torch: Boolean,
        detectionSpeed: DetectionSpeed,
        torchStateCallback: TorchStateCallback,
        zoomScaleStateCallback: ZoomScaleStateCallback,
        mobileScannerStartedCallback: MobileScannerStartedCallback,
        detectionTimeout: Long,
        androidResolution: Size?
    ) {
        this.detectionSpeed = detectionSpeed
        this.detectionTimeout = detectionTimeout
        this.returnImage = returnImage

        if (camera?.cameraInfo != null && preview != null && textureEntry != null) {
            throw AlreadyStarted()
        }

        scanner = if (barcodeScannerOptions != null) {
            BarcodeScanning.getClient(barcodeScannerOptions)
        } else {
            BarcodeScanning.getClient()
        }

        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity)
        val executor = ContextCompat.getMainExecutor(activity)

        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            if (cameraProvider == null) {
                throw CameraError()
            }
            cameraProvider!!.unbindAll()
            textureEntry = textureRegistry.createSurfaceTexture()

            // Preview
            val surfaceProvider = Preview.SurfaceProvider { request ->
                if (isStopped()) {
                    return@SurfaceProvider
                }

                val texture = textureEntry!!.surfaceTexture()
                texture.setDefaultBufferSize(
                    request.resolution.width,
                    request.resolution.height
                )

                val surface = Surface(texture)
                request.provideSurface(surface, executor) { }
            }

            // Build the preview to be shown on the Flutter texture
            val previewBuilder = Preview.Builder()
            preview = previewBuilder.build().apply { setSurfaceProvider(surfaceProvider) }

            // Build the analyzer to be passed on to MLKit
            val analysisBuilder = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            val displayManager = activity.applicationContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val windowManager = activity.applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            if (androidResolution != null) {
                // Override initial resolution
                analysisBuilder.setTargetResolution(getResolution(windowManager, androidResolution))
                // Listen future orientation change to apply the custom resolution
                displayManager.registerDisplayListener(object : DisplayManager.DisplayListener {
                    override fun onDisplayAdded(displayId: Int) {}
                    override fun onDisplayRemoved(displayId: Int) {}
                    override fun onDisplayChanged(displayId: Int) {
                        analysisBuilder.setTargetResolution(getResolution(windowManager, androidResolution))
                    }
                }, null)
            }

            val analysis = analysisBuilder.build().apply { setAnalyzer(executor, captureOutput) }

            camera = cameraProvider!!.bindToLifecycle(
                activity as LifecycleOwner,
                cameraPosition,
                preview,
                analysis
            )

            // Register the torch listener
            camera!!.cameraInfo.torchState.observe(activity) { state ->
                // TorchState.OFF = 0; TorchState.ON = 1
                torchStateCallback(state)
            }

            // Register the zoom scale listener
            camera!!.cameraInfo.zoomState.observe(activity) { state ->
                zoomScaleStateCallback(state.linearZoom.toDouble())
            }


            // Enable torch if provided
            camera!!.cameraControl.enableTorch(torch)

            val resolution = analysis.resolutionInfo!!.resolution
            val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()

            mobileScannerStartedCallback(
                MobileScannerStartParameters(
                    if (portrait) width else height,
                    if (portrait) height else width,
                    camera!!.cameraInfo.hasFlashUnit(),
                    textureEntry!!.id()
                )
            )
        }, executor)

    }
    /**
     * Stop barcode scanning.
     */
    fun stop() {
        if (isStopped()) {
            throw AlreadyStopped()
        }

        val owner = activity as LifecycleOwner
        camera?.cameraInfo?.torchState?.removeObservers(owner)
        cameraProvider?.unbindAll()
        textureEntry?.release()

        camera = null
        preview = null
        textureEntry = null
        cameraProvider = null
    }

    private fun isStopped() = camera == null && preview == null

    /**
     * Toggles the flash light on or off.
     */
    fun toggleTorch(enableTorch: Boolean) {
        if (camera == null) {
            throw TorchWhenStopped()
        }
        camera!!.cameraControl.enableTorch(enableTorch)
    }

    /**
     * Analyze a single image.
     */
    fun analyzeImage(image: Uri, analyzerCallback: AnalyzerCallback) {
        val inputImage = InputImage.fromFilePath(activity, image)

        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                val barcodeMap = barcodes.map { barcode -> barcode.data }

                if (barcodeMap.isNotEmpty()) {
                    analyzerCallback(barcodeMap)
                } else {
                    analyzerCallback(null)
                }
            }
            .addOnFailureListener { e ->
                mobileScannerErrorCallback(
                    e.localizedMessage ?: e.toString()
                )
            }
    }

    /**
     * Set the zoom rate of the camera.
     */
    fun setScale(scale: Double) {
        if (camera == null) throw ZoomWhenStopped()
        if (scale > 1.0 || scale < 0) throw ZoomNotInRange()
        camera!!.cameraControl.setLinearZoom(scale.toFloat())
    }

    /**
     * Reset the zoom rate of the camera.
     */
    fun resetScale() {
        if (camera == null) throw ZoomWhenStopped()
        camera!!.cameraControl.setZoomRatio(1f)
    }

}
