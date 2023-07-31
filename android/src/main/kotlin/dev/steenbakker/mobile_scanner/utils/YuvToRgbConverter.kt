package dev.steenbakker.mobile_scanner.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.media.Image
import android.os.Build
import android.renderscript.Allocation
import android.renderscript.Element
import android.renderscript.RenderScript
import android.renderscript.ScriptIntrinsicYuvToRGB
import android.renderscript.Type
import androidx.annotation.RequiresApi
import java.nio.ByteBuffer


/**
 * Helper class used to efficiently convert a [Media.Image] object from
 * YUV_420_888 format to an RGB [Bitmap] object.
 *
 * Copied from https://github.com/owahltinez/camerax-tflite/blob/master/app/src/main/java/com/android/example/camerax/tflite/YuvToRgbConverter.kt
 *
 * The [yuvToRgb] method is able to achieve the same FPS as the CameraX image
 * analysis use case at the default analyzer resolution, which is 30 FPS with
 * 640x480 on a Pixel 3 XL device.
 */class YuvToRgbConverter(context: Context) {
    private val rs = RenderScript.create(context)
    private val scriptYuvToRgb =
        ScriptIntrinsicYuvToRGB.create(rs, Element.U8_4(rs))

    // Do not add getters/setters functions to these private variables
    // because yuvToRgb() assume they won't be modified elsewhere
    private var yuvBits: ByteBuffer? = null
    private var bytes: ByteArray = ByteArray(0)
    private var inputAllocation: Allocation? = null
    private var outputAllocation: Allocation? = null

    @Synchronized
    fun yuvToRgb(image: Image, output: Bitmap) {
        val yuvBuffer = YuvByteBuffer(image, yuvBits)
        yuvBits = yuvBuffer.buffer

        if (needCreateAllocations(image, yuvBuffer)) {
            val yuvType = Type.Builder(rs, Element.U8(rs))
                .setX(image.width)
                .setY(image.height)
                .setYuvFormat(yuvBuffer.type)
            inputAllocation = Allocation.createTyped(
                rs,
                yuvType.create(),
                Allocation.USAGE_SCRIPT
            )
            bytes = ByteArray(yuvBuffer.buffer.capacity())
            val rgbaType = Type.Builder(rs, Element.RGBA_8888(rs))
                .setX(image.width)
                .setY(image.height)
            outputAllocation = Allocation.createTyped(
                rs,
                rgbaType.create(),
                Allocation.USAGE_SCRIPT
            )
        }

        yuvBuffer.buffer.get(bytes)
        inputAllocation!!.copyFrom(bytes)

        // Convert NV21 or YUV_420_888 format to RGB
        inputAllocation!!.copyFrom(bytes)
        scriptYuvToRgb.setInput(inputAllocation)
        scriptYuvToRgb.forEach(outputAllocation)
        outputAllocation!!.copyTo(output)
    }

    private fun needCreateAllocations(image: Image, yuvBuffer: YuvByteBuffer): Boolean {
        return (inputAllocation == null ||               // the very 1st call
                inputAllocation!!.type.x != image.width ||   // image size changed
                inputAllocation!!.type.y != image.height ||
                inputAllocation!!.type.yuv != yuvBuffer.type || // image format changed
                bytes.size == yuvBuffer.buffer.capacity())
    }
}