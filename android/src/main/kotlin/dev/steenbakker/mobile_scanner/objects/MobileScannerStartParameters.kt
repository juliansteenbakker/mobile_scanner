package dev.steenbakker.mobile_scanner.objects

class MobileScannerStartParameters(
    val width: Double = 0.0,
    val height: Double,
    val naturalDeviceOrientation: String,
    val sensorOrientation: Int,
    val isPreviewPreTransformed: Boolean,
    val currentTorchState: Int,
    val id: Long,
    val numberOfCameras: Int,
    val cameraDirection: Int?,
)