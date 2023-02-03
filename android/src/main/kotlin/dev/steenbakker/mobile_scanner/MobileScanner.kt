package dev.steenbakker.mobile_scanner

import android.app.Activity
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
import io.flutter.view.TextureRegistry
import kotlin.math.roundToInt

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
                    lastScanned = newScannedBarcodes
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
                    mobileScannerCallback(
                        barcodeMap,
                        if (returnImage) mediaImage.toByteArray() else null,
                        if (returnImage) mediaImage.width else null,
                        if (returnImage) mediaImage.height else null
                    )
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
        mobileScannerStartedCallback: MobileScannerStartedCallback,
        detectionTimeout: Long
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
//                analysisBuilder.setTargetResolution(Size(1440, 1920))
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
        if (camera == null && preview == null) {
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

}
