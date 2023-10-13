package dev.steenbakker.mobile_scanner

import android.hardware.display.DisplayManager

/**
 * This class will listen for display changes
 * and executes `onUpdateResolution` when that happens.
 */
class MobileScannerDisplayListener(
    private val onUpdateResolution: () -> Unit
) : DisplayManager.DisplayListener {
    override fun onDisplayAdded(displayId: Int) {}

    override fun onDisplayRemoved(displayId: Int) {}

    override fun onDisplayChanged(displayId: Int) {
        onUpdateResolution()
    }
}