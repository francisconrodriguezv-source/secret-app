package com.buds.cozy_love

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar
import java.util.concurrent.TimeUnit

/// Widget "Notes" — muestra la ÚLTIMA sticky note como un post-it grande.
///
/// Los datos llegan vía [WidgetsBridge.saveNotes] como JSON array. Sólo se
/// renderiza el primer elemento. Cada nota: `{ text, author, color, addedAtMs }`.
class NotesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val local = WidgetLocale.localized(context)
        for (widgetId in appWidgetIds) {
            renderWidget(context, local, appWidgetManager, widgetId)
        }
    }

    private fun renderWidget(
        context: Context,
        localCtx: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences(
            WidgetsBridge.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val json = prefs.getString(WidgetsBridge.KEY_NOTES_JSON, "[]") ?: "[]"
        val note = parseFirstNote(json)

        val views = RemoteViews(context.packageName, R.layout.widget_notes)

        if (note == null) {
            views.setViewVisibility(R.id.widget_notes_card, View.GONE)
            views.setViewVisibility(R.id.widget_notes_empty_wrap, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_notes_empty,
                localCtx.getString(R.string.widget_empty_notes)
            )
        } else {
            views.setViewVisibility(R.id.widget_notes_empty_wrap, View.GONE)
            views.setViewVisibility(R.id.widget_notes_card, View.VISIBLE)
            views.setTextViewText(R.id.widget_notes_text, note.text)

            val authorLabel = if (note.author.isBlank()) ""
            else "— ${note.author}"
            views.setTextViewText(R.id.widget_notes_author, authorLabel)

            val stamp = if (note.addedAtMs > 0)
                relativeStamp(localCtx, note.addedAtMs)
            else ""
            views.setTextViewText(R.id.widget_notes_timestamp, stamp)

            val bg = when (note.color) {
                "pink" -> R.drawable.widget_note_bg_pink
                "blue" -> R.drawable.widget_note_bg_blue
                "purple" -> R.drawable.widget_note_bg_purple
                else -> R.drawable.widget_note_bg_yellow
            }
            views.setInt(R.id.widget_notes_card, "setBackgroundResource", bg)
        }

        // Tap → abre la app.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                context, widgetId, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_notes_root, pi)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /// Timestamp humano relativo ("2 min", "1 h", "3 d") — corto para caber
    /// dentro del post-it.
    private fun relativeStamp(ctx: Context, addedAtMs: Long): String {
        val now = System.currentTimeMillis()
        val diff = now - addedAtMs
        val mins = TimeUnit.MILLISECONDS.toMinutes(diff)
        val hours = TimeUnit.MILLISECONDS.toHours(diff)
        val days = TimeUnit.MILLISECONDS.toDays(diff)
        return when {
            mins < 1 -> ctx.getString(R.string.widget_relative_today)
            mins < 60 -> "$mins min"
            hours < 24 -> "$hours h"
            days < 7 -> "$days d"
            else -> {
                val cal = Calendar.getInstance().apply { timeInMillis = addedAtMs }
                val prefs = ctx.getSharedPreferences(
                    WidgetsBridge.PREFS_NAME,
                    Context.MODE_PRIVATE
                )
                val code = prefs.getString(WidgetsBridge.KEY_LOCALE, "en") ?: "en"
                val months = if (code == "es") listOf(
                    "ene", "feb", "mar", "abr", "may", "jun",
                    "jul", "ago", "sep", "oct", "nov", "dic",
                ) else listOf(
                    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
                )
                "${cal.get(Calendar.DAY_OF_MONTH)} ${months[cal.get(Calendar.MONTH)]}"
            }
        }
    }

    private data class NoteDto(
        val text: String,
        val author: String,
        val color: String,
        val addedAtMs: Long,
    )

    private fun parseFirstNote(json: String): NoteDto? = try {
        val arr = JSONArray(json)
        if (arr.length() == 0) null
        else {
            val o = arr.getJSONObject(0)
            NoteDto(
                text = o.optString("text", ""),
                author = o.optString("author", ""),
                color = o.optString("color", "yellow"),
                addedAtMs = o.optLong("addedAtMs", 0L),
            )
        }
    } catch (e: Exception) {
        null
    }

    companion object {
        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, NotesWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            val intent = Intent(context, NotesWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
