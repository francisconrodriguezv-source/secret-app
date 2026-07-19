package com.buds.cozy_love

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/// Bridge entre Flutter y los home widgets. Guarda los datos en
/// SharedPreferences y refresca los widgets vía broadcast.
///
/// Métodos disponibles en el channel `cozy_love/widgets`:
/// - `updateCouple(name: String, sinceMs: Long)`
/// - `updateUpcoming(events: List<Map>)` — cada evento con `title`,
///   `subtitle`, `startMs`.
/// - `refreshAll()` — fuerza update de ambos widgets.
class WidgetsBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "cozy_love/widgets"
        const val PREFS_NAME = "cozy_widget_prefs"
        const val KEY_COUPLE_NAME = "couple_name"
        const val KEY_SINCE_MS = "since_date_ms"
        const val KEY_UPCOMING_JSON = "upcoming_json"
        const val KEY_NOTES_JSON = "notes_json"
        const val KEY_COUNTDOWN_JSON = "countdown_json"
        const val KEY_LOCALE = "locale"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "updateCouple" -> {
                    val name = call.argument<String>("name") ?: ""
                    val sinceMs = call.argument<Number>("sinceMs")?.toLong() ?: 0L
                    saveCouple(name, sinceMs)
                    refreshAll()
                    result.success(null)
                }
                "updateUpcoming" -> {
                    @Suppress("UNCHECKED_CAST")
                    val events = call.argument<List<Map<String, Any?>>>("events")
                        ?: emptyList()
                    saveUpcoming(events)
                    UpcomingWidgetProvider.updateAll(context)
                    result.success(null)
                }
                "updateNotes" -> {
                    @Suppress("UNCHECKED_CAST")
                    val notes = call.argument<List<Map<String, Any?>>>("notes")
                        ?: emptyList()
                    saveNotes(notes)
                    NotesWidgetProvider.updateAll(context)
                    result.success(null)
                }
                "updateCountdown" -> {
                    val title = call.argument<String>("title") ?: ""
                    val startMs = call.argument<Number>("startMs")?.toLong() ?: 0L
                    saveCountdown(title, startMs)
                    CountdownWidgetProvider.updateAll(context)
                    result.success(null)
                }
                "updateLocale" -> {
                    val code = call.argument<String>("code") ?: "en"
                    saveLocale(code)
                    refreshAll()
                    result.success(null)
                }
                "refreshAll" -> {
                    refreshAll()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("BRIDGE_ERROR", e.message, null)
        }
    }

    private fun refreshAll() {
        TogetherWidgetProvider.updateAll(context)
        UpcomingWidgetProvider.updateAll(context)
        NotesWidgetProvider.updateAll(context)
        CountdownWidgetProvider.updateAll(context)
    }

    private fun saveCouple(name: String, sinceMs: Long) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_COUPLE_NAME, name)
            .putLong(KEY_SINCE_MS, sinceMs)
            .apply()
    }

    private fun saveUpcoming(events: List<Map<String, Any?>>) {
        val arr = JSONArray()
        for (e in events) {
            arr.put(
                JSONObject().apply {
                    put("title", e["title"]?.toString() ?: "")
                    put("subtitle", e["subtitle"]?.toString() ?: "")
                    put(
                        "startMs",
                        (e["startMs"] as? Number)?.toLong() ?: 0L
                    )
                }
            )
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_UPCOMING_JSON, arr.toString())
            .apply()
    }

    private fun saveNotes(notes: List<Map<String, Any?>>) {
        val arr = JSONArray()
        for (n in notes) {
            arr.put(
                JSONObject().apply {
                    put("text", n["text"]?.toString() ?: "")
                    put("author", n["author"]?.toString() ?: "")
                    put("color", n["color"]?.toString() ?: "yellow")
                    put(
                        "addedAtMs",
                        (n["addedAtMs"] as? Number)?.toLong() ?: 0L
                    )
                }
            )
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_NOTES_JSON, arr.toString())
            .apply()
    }

    private fun saveCountdown(title: String, startMs: Long) {
        val json = if (title.isBlank() || startMs <= 0L) {
            ""
        } else {
            JSONObject().apply {
                put("title", title)
                put("startMs", startMs)
            }.toString()
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_COUNTDOWN_JSON, json)
            .apply()
    }

    private fun saveLocale(code: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LOCALE, code)
            .apply()
    }
}
