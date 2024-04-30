package dev.steenbakker.mobile_scanner.objects

class MobileScannerStartParameters(
    val width: Double = 0.0,
    val height: Double,
    val currentTorchState: Int,
    val id: Long,
    val numberOfCameras: Int
)