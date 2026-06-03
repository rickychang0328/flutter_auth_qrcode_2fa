package com.example.flutter_auth_qrcode_2fa

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.text.TextUtils
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.ChecksumException
import com.google.zxing.DecodeHintType
import com.google.zxing.FormatException
import com.google.zxing.NotFoundException
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.Result
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Hashtable

/// ZXing gallery decode — aligned with nosms `LoadingPictureActivity`.
class QrImageDecodeHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_DECODE_FROM_IMAGE_PATH -> decodeFromImagePath(call, result)
            else -> result.notImplemented()
        }
    }

    private fun decodeFromImagePath(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>(ARG_PATH)
        if (path.isNullOrBlank()) {
            result.error(
                CODE_INVALID_PATH,
                "無法讀取圖片：路徑為空",
                null,
            )
            return
        }

        try {
            val payload = decodeQrPayload(path)
            if (payload.isNullOrBlank()) {
                result.error(
                    CODE_NOT_FOUND,
                    "無法從圖片中辨識 QR 碼",
                    null,
                )
                return
            }
            result.success(
                mapOf(
                    KEY_SUCCESS to true,
                    KEY_PAYLOAD to payload,
                ),
            )
        } catch (e: Exception) {
            result.error(
                CODE_INVALID_PATH,
                "無法讀取圖片：${e.message ?: e.javaClass.simpleName}",
                null,
            )
        }
    }

    private fun decodeQrPayload(path: String): String? {
        for (sampleSize in DENSITY_ARR) {
            val decoded = scanQrCode(path, sampleSize, sampleSize)
            if (!decoded.isNullOrBlank()) {
                return decoded.trim()
            }
        }
        return null
    }

    private fun scanQrCode(path: String, reqWidth: Int, reqHeight: Int): String? {
        val bitmap = decodeSampledBitmapFromPath(path, reqWidth, reqHeight) ?: return null
        return try {
            decodeBitmap(bitmap)?.text
        } finally {
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
    }

    private fun decodeBitmap(bitmap: Bitmap): Result? {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        val hints = Hashtable<DecodeHintType, Any?>()
        hints[DecodeHintType.CHARACTER_SET] = "UTF-8"
        hints[DecodeHintType.TRY_HARDER] = java.lang.Boolean.TRUE
        hints[DecodeHintType.POSSIBLE_FORMATS] = BarcodeFormat.QR_CODE

        val source = RGBLuminanceSource(width, height, pixels)
        val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
        val reader = QRCodeReader()
        return try {
            reader.decode(binaryBitmap, hints)
        } catch (_: NotFoundException) {
            null
        } catch (_: FormatException) {
            null
        } catch (_: ChecksumException) {
            null
        }
    }

    private fun decodeSampledBitmapFromPath(
        path: String,
        reqWidth: Int,
        reqHeight: Int,
    ): Bitmap? {
        if (TextUtils.isEmpty(path)) return null

        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        loadBitmapBounds(path, options)
        if (options.outWidth <= 0 || options.outHeight <= 0) {
            return null
        }

        options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)
        options.inJustDecodeBounds = false
        return loadBitmap(path, options)
    }

    private fun loadBitmapBounds(path: String, options: BitmapFactory.Options) {
        if (path.startsWith("content://")) {
            context.contentResolver.openInputStream(Uri.parse(path))?.use { stream ->
                BitmapFactory.decodeStream(stream, null, options)
            }
        } else {
            BitmapFactory.decodeFile(path, options)
        }
    }

    private fun loadBitmap(path: String, options: BitmapFactory.Options): Bitmap? {
        return if (path.startsWith("content://")) {
            context.contentResolver.openInputStream(Uri.parse(path))?.use { stream ->
                BitmapFactory.decodeStream(stream, null, options)
            }
        } else {
            BitmapFactory.decodeFile(path, options)
        }
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int,
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            var halfHeight = height / 2
            var halfWidth = width / 2
            while (halfHeight / inSampleSize > reqHeight &&
                halfWidth / inSampleSize > reqWidth
            ) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    companion object {
        const val CHANNEL_NAME = "com.example.flutter_auth_qrcode_2fa/qr_decode"
        const val METHOD_DECODE_FROM_IMAGE_PATH = "decodeFromImagePath"
        const val ARG_PATH = "path"
        const val KEY_SUCCESS = "success"
        const val KEY_PAYLOAD = "payload"
        const val CODE_NOT_FOUND = "NOT_FOUND"
        const val CODE_INVALID_PATH = "INVALID_PATH"

        private val DENSITY_ARR = intArrayOf(512, 1024, 768, 2048, 1536)

        fun registerWith(context: Context, channel: MethodChannel) {
            channel.setMethodCallHandler(QrImageDecodeHandler(context))
        }
    }
}
