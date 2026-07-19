package com.buds.cozy_love

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Bridge Dart → nativo Android para lanzar notificaciones locales.
///
/// Métodos disponibles en el channel `cozy_love/notifications`:
/// - `send(title: String, body: String)` — muestra una notificación
///   en el drawer del sistema. Requiere permiso `POST_NOTIFICATIONS`
///   en Android 13+ (se solicita desde el lado Dart).
class NotificationBridge(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "cozy_love/notifications"
        private const val CHANNEL_ID = "cozy_thinking"
        private const val CHANNEL_NAME_EN = "Thinking of you"
        private const val CHANNEL_NAME_ES = "Pensando en ti"
        private var channelReady = false
        private var notifIdCounter = 100
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "send" -> {
                    ensureChannel()
                    val title = call.argument<String>("title") ?: "Tandem"
                    val body = call.argument<String>("body") ?: ""
                    show(title, body)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("NOTIF_ERROR", e.message, null)
        }
    }

    /// Crea el NotificationChannel (idempotente). Sólo Android 26+.
    private fun ensureChannel() {
        if (channelReady) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = context.getSystemService(NotificationManager::class.java)
            val prefs = context.getSharedPreferences(
                WidgetsBridge.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val code = prefs.getString(WidgetsBridge.KEY_LOCALE, "en") ?: "en"
            val name = if (code == "es") CHANNEL_NAME_ES else CHANNEL_NAME_EN
            val channel = NotificationChannel(
                CHANNEL_ID,
                name,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = name
                enableVibration(true)
            }
            mgr?.createNotificationChannel(channel)
        }
        channelReady = true
    }

    private fun show(title: String, body: String) {
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        val pi = if (launchIntent != null) {
            PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val notif = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply { if (pi != null) setContentIntent(pi) }
            .build()

        val mgr = context.getSystemService(NotificationManager::class.java)
        mgr?.notify(notifIdCounter++, notif)
    }
}
