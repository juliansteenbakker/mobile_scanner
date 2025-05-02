

package dev.steenbakker.mobile_scanner.utils

import android.content.Context
import android.graphics.Bitmap
import android.media.Image
import android.renderscript.Allocation
import android.renderscript.Element
import android.renderscript.RenderScript
import android.renderscript.ScriptIntrinsicYuvToRGB
import android.renderscript.Type
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
 */
/// TODO: Upgrade to implementation without deprecated android.renderscript, but with same or better performance. See https://github.com/juliansteenbakker/mobile_scanner/issues/1142
class YuvToRgbConverter(context: Context) {
    @Suppress("DEPRECATION")
    private val rs = RenderScript.create(context)
    @Suppress("DEPRECATION")
    private val scriptYuvToRgb =
        ScriptIntrinsicYuvToRGB.create(rs, Element.U8_4(rs))

    private var yuvBits: ByteBuffer? = null
    private var bytes: ByteArray = ByteArray(0)
    @Suppress("DEPRECATION")
    private var inputAllocation: Allocation? = null
    @Suppress("DEPRECATION")
    private var outputAllocation: Allocation? = null

    @Synchronized
    fun yuvToRgb(image: Image, output: Bitmap) {
        try {
            val yuvBuffer = YuvByteBuffer(image, yuvBits)
            yuvBits = yuvBuffer.buffer

            if (needCreateAllocations(image, yuvBuffer)) {
                createAllocations(image, yuvBuffer)
            }

            yuvBuffer.buffer.get(bytes)
            @Suppress("DEPRECATION")
            inputAllocation!!.copyFrom(bytes)

            @Suppress("DEPRECATION")
            scriptYuvToRgb.setInput(inputAllocation)
            @Suppress("DEPRECATION")
            scriptYuvToRgb.forEach(outputAllocation)
            @Suppress("DEPRECATION")
            outputAllocation!!.copyTo(output)
        } catch (e: Exception) {
            throw IllegalStateException("Failed to convert YUV to RGB", e)
        }
    }

    private fun needCreateAllocations(image: Image, yuvBuffer: YuvByteBuffer): Boolean {
        @Suppress("DEPRECATION")
        return inputAllocation?.type?.x != image.width ||
                inputAllocation?.type?.y != image.height ||
                inputAllocation?.type?.yuv != yuvBuffer.type
    }

    private fun createAllocations(image: Image, yuvBuffer: YuvByteBuffer) {
        @Suppress("DEPRECATION")
        val yuvType = Type.Builder(rs, Element.U8(rs))
            .setX(image.width)
            .setY(image.height)
            .setYuvFormat(yuvBuffer.type)
        @Suppress("DEPRECATION")
        inputAllocation = Allocation.createTyped(
            rs,
            yuvType.create(),
            Allocation.USAGE_SCRIPT
        )
        bytes = ByteArray(yuvBuffer.buffer.capacity())
        @Suppress("DEPRECATION")
        val rgbaType = Type.Builder(rs, Element.RGBA_8888(rs))
            .setX(image.width)
            .setY(image.height)
        @Suppress("DEPRECATION")
        outputAllocation = Allocation.createTyped(
            rs,
            rgbaType.create(),
            Allocation.USAGE_SCRIPT
        )
    }

    @Suppress("DEPRECATION")
    fun release() {
        inputAllocation?.destroy()
        outputAllocation?.destroy()
        scriptYuvToRgb.destroy()
        rs.destroy()
    }
}
