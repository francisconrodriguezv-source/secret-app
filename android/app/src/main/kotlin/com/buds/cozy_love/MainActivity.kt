package com.buds.cozy_love

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/// [FlutterActivity] con [MethodChannel]s que exponen:
///   - `cozy_love/photo`   → galería SAF + cámara.
///   - `cozy_love/widgets` → sincronización de home widgets.
///   - `cozy_love/prefs`   → SharedPreferences persistentes.
///   - `cozy_love/notifications` → notificaciones locales del sistema.
class MainActivity : FlutterActivity() {
    private companion object {
        private const val PHOTO_CHANNEL = "cozy_love/photo"
        private const val NOTIF_CHANNEL = "cozy_love/notifications"
        private const val REQ_GALLERY = 1001
        private const val REQ_CAMERA = 1002
        private const val REQ_NOTIF_PERMISSION = 2001
    }

    private var pendingResult: MethodChannel.Result? = null
    private var lastCameraFile: File? = null

    // Handler para el permiso POST_NOTIFICATIONS (se resuelve en
    // `onRequestPermissionsResult`).
    private var pendingPermResult: MethodChannel.Result? = null
    private var notificationBridge: NotificationBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHOTO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFromGallery" -> pickFromGallery(result)
                    "takePhoto" -> takePhoto(result)
                    else -> result.notImplemented()
                }
            }

        // Widgets bridge.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WidgetsBridge.CHANNEL
        ).setMethodCallHandler(WidgetsBridge(applicationContext))

        // Persistencia via SharedPreferences.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PrefsBridge.CHANNEL
        ).setMethodCallHandler(PrefsBridge(applicationContext))

        // Notificaciones. El `send` se delega al bridge. El `requestPermission`
        // se maneja aquí porque necesita el Activity.
        notificationBridge = NotificationBridge(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIF_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestNotificationPermission(result)
                else -> notificationBridge?.onMethodCall(call, result)
                    ?: result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        // Android 12- no requiere permiso runtime; siempre otorgado.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }
        val perm = Manifest.permission.POST_NOTIFICATIONS
        if (ContextCompat.checkSelfPermission(this, perm)
            == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingPermResult != null) {
            result.error("BUSY", "Another permission request in progress", null)
            return
        }
        pendingPermResult = result
        ActivityCompat.requestPermissions(
            this, arrayOf(perm), REQ_NOTIF_PERMISSION
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_NOTIF_PERMISSION) {
            val r = pendingPermResult
            pendingPermResult = null
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            r?.success(granted)
        }
    }

    private fun pickFromGallery(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "Another picker call is in progress", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, REQ_GALLERY)
    }

    private fun takePhoto(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "Another picker call is in progress", null)
            return
        }
        pendingResult = result

        val dir = externalCacheDir ?: cacheDir
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, "cozy_${System.currentTimeMillis()}.jpg")
        lastCameraFile = file

        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )

        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        if (intent.resolveActivity(packageManager) == null) {
            pendingResult = null
            lastCameraFile = null
            result.error("NO_CAMERA", "No camera app available", null)
            return
        }
        startActivityForResult(intent, REQ_CAMERA)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        when (requestCode) {
            REQ_GALLERY -> handleGalleryResult(data?.data, result)
            REQ_CAMERA -> {
                val file = lastCameraFile?.takeIf { it.exists() }
                lastCameraFile = null
                if (file == null) {
                    result.success(null)
                    return
                }
                // Selfies: la cámara del sistema guarda la foto sin
                // espejar (como la ve el sensor), pero el preview sí se
                // muestra espejado. Voltear horizontalmente para que la
                // foto guardada coincida con lo que el usuario vio.
                mirrorHorizontally(file)
                result.success(file.absolutePath)
            }
        }
    }

    /// Voltea la imagen JPEG horizontalmente in-place. Preserva rotación
    /// original (portrait/landscape). Si falla el decode, se deja igual.
    private fun mirrorHorizontally(file: File) {
        try {
            // Downsample si la imagen es muy grande para no OOM.
            val opts = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(file.absolutePath, opts)
            val maxDim = maxOf(opts.outWidth, opts.outHeight)
            val sample = if (maxDim > 4096) 2 else 1
            val decodeOpts = BitmapFactory.Options().apply {
                inSampleSize = sample
            }
            val bmp = BitmapFactory.decodeFile(file.absolutePath, decodeOpts)
                ?: return
            val matrix = Matrix().apply { preScale(-1f, 1f) }
            val flipped = Bitmap.createBitmap(
                bmp, 0, 0, bmp.width, bmp.height, matrix, true
            )
            FileOutputStream(file).use { out ->
                flipped.compress(Bitmap.CompressFormat.JPEG, 92, out)
            }
            if (flipped != bmp) bmp.recycle()
            flipped.recycle()
        } catch (_: Exception) {
            // Si algo falla, seguimos con la foto original.
        }
    }

    /// Copia los bytes del content URI seleccionado a un archivo en el
    /// cache del app y retorna su path absoluto.
    private fun handleGalleryResult(uri: Uri?, result: MethodChannel.Result) {
        if (uri == null) {
            result.success(null)
            return
        }
        try {
            val dir = externalCacheDir ?: cacheDir
            if (!dir.exists()) dir.mkdirs()
            val ext = contentResolver.getType(uri)
                ?.substringAfter('/', "jpg")
                ?.takeIf { it.isNotBlank() } ?: "jpg"
            val destFile = File(dir, "cozy_pick_${System.currentTimeMillis()}.$ext")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            }
            result.success(destFile.absolutePath)
        } catch (e: Exception) {
            result.error("IO_ERROR", e.message, null)
        }
    }
}
