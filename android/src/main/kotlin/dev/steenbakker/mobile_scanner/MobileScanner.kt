package dev.steenbakker.mobile_scanner

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.Point
import android.net.Uri
import android.util.Log
import android.util.Size
import android.view.Surface
import androidx.annotation.NonNull
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import java.io.File


class MobileScanner(private val activity: Activity, private val textureRegistry: TextureRegistry)
    : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val REQUEST_CODE = 22022022
        private val TAG = MobileScanner::class.java.simpleName
    }

    private var sink: EventChannel.EventSink? = null
    private var listener: PluginRegistry.RequestPermissionsResultListener? = null

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var preview: Preview? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

//    @AnalyzeMode
//    private var analyzeMode: Int = AnalyzeMode.NONE

    @ExperimentalGetImage
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "state" -> checkPermission(result)
            "request" -> requestPermission(result)
            "start" -> start(call, result)
            "torch" -> toggleTorch(call, result)
//            "analyze" -> switchAnalyzeMode(call, result)
            "stop" -> stop(result)
            "analyzeImage" -> analyzeImage(call, result)
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

    private fun checkPermission(result: MethodChannel.Result) {
        // Can't get exact denied or not_determined state without request. Just return not_determined when state isn't authorized
        val state =
                if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) 1
                else 0
        result.success(state)
    }

    private fun requestPermission(result: MethodChannel.Result) {
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


    @ExperimentalGetImage
    val analyzer = ImageAnalysis.Analyzer { imageProxy -> // YUV_420_888 format
//        when (analyzeMode) {
//            AnalyzeMode.BARCODE -> {
                val mediaImage = imageProxy.image ?: return@Analyzer
                val inputImage = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)

                scanner.process(inputImage)
                        .addOnSuccessListener { barcodes ->
                            for (barcode in barcodes) {
                                val event = mapOf("name" to "barcode", "data" to barcode.data)
                                sink?.success(event)
                            }
                        }
                        .addOnFailureListener { e -> Log.e(TAG, e.message, e) }
                        .addOnCompleteListener { imageProxy.close() }
//            }
//            else -> imageProxy.close()
//        }
    }


    private var scanner = BarcodeScanning.getClient()

    @ExperimentalGetImage
    private fun start(call: MethodCall, result: MethodChannel.Result) {
        if (camera != null && preview != null) {
            val resolution = preview!!.resolutionInfo!!.resolution
            val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()
            val size = if (portrait) mapOf("width" to width, "height" to height) else mapOf("width" to height, "height" to width)
            val answer = mapOf("textureId" to textureEntry!!.id(), "size" to size, "torchable" to camera!!.cameraInfo.hasFlashUnit())
            result.success(answer)
        } else {
            val facing: Int = call.argument<Int>("facing") ?: 0
            val ratio: Int? = call.argument<Int>("ratio")
            val torch: Boolean = call.argument<Boolean>("torch") ?: false
            val formats: List<Int>? = call.argument<List<Int>>("formats")

            if (formats != null) {
                val formatsList: MutableList<Int> = mutableListOf()
                for (index in formats) {
                    formatsList.add(BarcodeFormats.values()[index].intValue)
                }
                scanner = if (formatsList.size == 1) {
                    BarcodeScanning.getClient(BarcodeScannerOptions.Builder().setBarcodeFormats(formatsList.first()).build())
                } else {
                    BarcodeScanning.getClient(BarcodeScannerOptions.Builder().setBarcodeFormats(formatsList.first(), *formatsList.subList(1, formatsList.size).toIntArray()).build())
                }
            }

            val future = ProcessCameraProvider.getInstance(activity)
            val executor = ContextCompat.getMainExecutor(activity)

            future.addListener({
                cameraProvider = future.get()
                cameraProvider!!.unbindAll()
                textureEntry = textureRegistry.createSurfaceTexture()

                // Preview
                val surfaceProvider = Preview.SurfaceProvider { request ->
                    val texture = textureEntry!!.surfaceTexture()
                    texture.setDefaultBufferSize(request.resolution.width, request.resolution.height)
                    val surface = Surface(texture)
                    request.provideSurface(surface, executor) { }
                }

                // Build the preview to be shown on the Flutter texture
                val previewBuilder = Preview.Builder()
                if (ratio != null) {
                    previewBuilder.setTargetAspectRatio(ratio)
                }
                preview = previewBuilder.build().apply { setSurfaceProvider(surfaceProvider) }

                // Build the analyzer to be passed on to MLKit
                val analysisBuilder = ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                if (ratio != null) {
                    analysisBuilder.setTargetAspectRatio(ratio)
                }
                val analysis = analysisBuilder.build().apply { setAnalyzer(executor, analyzer) }

                // Select the correct camera
                val selector = if (facing == 0) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA

                camera = cameraProvider!!.bindToLifecycle(activity as LifecycleOwner, selector, preview, analysis)

                val analysisSize = analysis.resolutionInfo?.resolution ?: Size(0, 0)
                val previewSize = preview!!.resolutionInfo?.resolution ?: Size(0, 0)
                Log.i("LOG", "Analyzer: $analysisSize")
                Log.i("LOG", "Preview: $previewSize")

                // Register the torch listener
                camera!!.cameraInfo.torchState.observe(activity) { state ->
                    // TorchState.OFF = 0; TorchState.ON = 1
                    sink?.success(mapOf("name" to "torchState", "data" to state))
                }

                // Enable torch if provided
                camera!!.cameraControl.enableTorch(torch)

                val resolution = preview!!.resolutionInfo!!.resolution
                val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
                val width = resolution.width.toDouble()
                val height = resolution.height.toDouble()
                val size = if (portrait) mapOf("width" to width, "height" to height) else mapOf("width" to height, "height" to width)
                val answer = mapOf("textureId" to textureEntry!!.id(), "size" to size, "torchable" to camera!!.cameraInfo.hasFlashUnit())
                result.success(answer)
            }, executor)
        }
    }

    private fun toggleTorch(call: MethodCall, result: MethodChannel.Result) {
        if (camera == null) {
            result.error(TAG,"Called toggleTorch() while stopped!", null)
            return
        }
        camera!!.cameraControl.enableTorch(call.arguments == 1)
        result.success(null)
    }

//    private fun switchAnalyzeMode(call: MethodCall, result: MethodChannel.Result) {
//        analyzeMode = call.arguments as Int
//        result.success(null)
//    }

    private fun analyzeImage(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.fromFile( File(call.arguments.toString()))
        val inputImage = InputImage.fromFilePath(activity, uri)

        var barcodeFound = false
        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                for (barcode in barcodes) {
                    barcodeFound = true
                    sink?.success(mapOf("name" to "barcode", "data" to barcode.data))
                }
            }
            .addOnFailureListener { e -> Log.e(TAG, e.message, e)
                result.error(TAG, e.message, e)}
            .addOnCompleteListener { result.success(barcodeFound) }

    }

    private fun stop(result: MethodChannel.Result) {
        if (camera == null && preview == null) {
            result.error(TAG,"Called stop() while already stopped!", null)
            return
        }

        val owner = activity as LifecycleOwner
        camera?.cameraInfo?.torchState?.removeObservers(owner)
        cameraProvider?.unbindAll()
        textureEntry?.release()

//        analyzeMode = AnalyzeMode.NONE
        camera = null
        preview = null
        textureEntry = null
        cameraProvider = null

        result.success(null)
    }


    private val Barcode.data: Map<String, Any?>
        get() = mapOf("corners" to cornerPoints?.map { corner -> corner.data }, "format" to format,
                "rawBytes" to rawBytes, "rawValue" to rawValue, "type" to valueType,
                "calendarEvent" to calendarEvent?.data, "contactInfo" to contactInfo?.data,
                "driverLicense" to driverLicense?.data, "email" to email?.data,
                "geoPoint" to geoPoint?.data, "phone" to phone?.data, "sms" to sms?.data,
                "url" to url?.data, "wifi" to wifi?.data)

    private val Point.data: Map<String, Double>
        get() = mapOf("x" to x.toDouble(), "y" to y.toDouble())

    private val Barcode.CalendarEvent.data: Map<String, Any?>
        get() = mapOf("description" to description, "end" to end?.rawValue, "location" to location,
                "organizer" to organizer, "start" to start?.rawValue, "status" to status,
                "summary" to summary)

    private val Barcode.ContactInfo.data: Map<String, Any?>
        get() = mapOf("addresses" to addresses.map { address -> address.data },
                "emails" to emails.map { email -> email.data }, "name" to name?.data,
                "organization" to organization, "phones" to phones.map { phone -> phone.data },
                "title" to title, "urls" to urls)

    private val Barcode.Address.data: Map<String, Any?>
        get() = mapOf("addressLines" to addressLines, "type" to type)

    private val Barcode.PersonName.data: Map<String, Any?>
        get() = mapOf("first" to first, "formattedName" to formattedName, "last" to last,
                "middle" to middle, "prefix" to prefix, "pronunciation" to pronunciation,
                "suffix" to suffix)

    private val Barcode.DriverLicense.data: Map<String, Any?>
        get() = mapOf("addressCity" to addressCity, "addressState" to addressState,
                "addressStreet" to addressStreet, "addressZip" to addressZip, "birthDate" to birthDate,
                "documentType" to documentType, "expiryDate" to expiryDate, "firstName" to firstName,
                "gender" to gender, "issueDate" to issueDate, "issuingCountry" to issuingCountry,
                "lastName" to lastName, "licenseNumber" to licenseNumber, "middleName" to middleName)

    private val Barcode.Email.data: Map<String, Any?>
        get() = mapOf("address" to address, "body" to body, "subject" to subject, "type" to type)

    private val Barcode.GeoPoint.data: Map<String, Any?>
        get() = mapOf("latitude" to lat, "longitude" to lng)

    private val Barcode.Phone.data: Map<String, Any?>
        get() = mapOf("number" to number, "type" to type)

    private val Barcode.Sms.data: Map<String, Any?>
        get() = mapOf("message" to message, "phoneNumber" to phoneNumber)

    private val Barcode.UrlBookmark.data: Map<String, Any?>
        get() = mapOf("title" to title, "url" to url)

    private val Barcode.WiFi.data: Map<String, Any?>
        get() = mapOf("encryptionType" to encryptionType, "password" to password, "ssid" to ssid)
}