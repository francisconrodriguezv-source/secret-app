package com.buds.cozy_love

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Bridge simple de `SharedPreferences` para Flutter. Reemplaza al package
/// `shared_preferences` (bloqueado por el proxy corporativo).
///
/// Métodos en el channel `cozy_love/prefs`:
/// - `read(key)` → String?
/// - `write(key, value)`
/// - `remove(key)`
class PrefsBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "cozy_love/prefs"
        const val PREFS_NAME = "cozy_app_prefs"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            when (call.method) {
                "read" -> {
                    val key = call.argument<String>("key") ?: return result.success(null)
                    result.success(prefs.getString(key, null))
                }
                "write" -> {
                    val key = call.argument<String>("key") ?: return result.error(
                        "BAD_ARG", "key missing", null
                    )
                    val value = call.argument<String>("value") ?: ""
                    prefs.edit().putString(key, value).apply()
                    result.success(null)
                }
                "remove" -> {
                    val key = call.argument<String>("key") ?: return result.success(null)
                    prefs.edit().remove(key).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("PREFS_ERROR", e.message, null)
        }
    }
}
