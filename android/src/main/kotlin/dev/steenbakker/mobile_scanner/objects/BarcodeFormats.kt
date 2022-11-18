package dev.steenbakker.mobile_scanner.objects

enum class BarcodeFormats(val intValue: Int) {
    UNKNOWN(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_UNKNOWN),
    ALL_FORMATS(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_ALL_FORMATS), CODE_128(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODE_128), CODE_39(
        com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODE_39
    ),
    CODE_93(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODE_93), CODABAR(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_CODABAR), DATA_MATRIX(
        com.google.mlkit.vision.barcode.common.Barcode.FORMAT_DATA_MATRIX
    ),
    EAN_13(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_EAN_13), EAN_8(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_EAN_8), ITF(
        com.google.mlkit.vision.barcode.common.Barcode.FORMAT_ITF
    ),
    QR_CODE(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_QR_CODE), UPC_A(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_UPC_A), UPC_E(
        com.google.mlkit.vision.barcode.common.Barcode.FORMAT_UPC_E
    ),
    PDF417(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_PDF417), AZTEC(com.google.mlkit.vision.barcode.common.Barcode.FORMAT_AZTEC);
}