package dev.steenbakker.mobile_scanner

import dev.steenbakker.mobile_scanner.objects.MobileScannerStartParameters

typealias MobileScannerCallback = (barcodes: List<Map<String, Any?>>, image: ByteArray?, width: Int?, height: Int?) -> Unit
typealias AnalyzerCallback = (barcodes: List<Map<String, Any?>>?) -> Unit
typealias MobileScannerErrorCallback = (error: String) -> Unit
typealias TorchStateCallback = (state: Int) -> Unit
typealias MobileScannerStartedCallback = (parameters: MobileScannerStartParameters) -> Unit