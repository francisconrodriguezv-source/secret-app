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

/// Widget de home screen "Upcoming". Lee un JSON array desde
/// SharedPreferences (`upcoming_json`) con hasta 2 eventos futuros que
/// Flutter mantiene sincronizados.
///
/// Cada evento tiene shape:
/// `{ "title": String, "subtitle": String, "startMs": Long, "endMs": Long? }`.
class UpcomingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val local = WidgetLocale.localized(context)
        for (widgetId in appWidgetIds) {
            updateWidget(context, local, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        localCtx: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences(
            WidgetsBridge.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val json = prefs.getString(WidgetsBridge.KEY_UPCOMING_JSON, "[]") ?: "[]"
        val events = parseEvents(json)

        val views = RemoteViews(context.packageName, R.layout.widget_upcoming)

        if (events.isEmpty()) {
            views.setViewVisibility(R.id.widget_up_row1, View.GONE)
            views.setViewVisibility(R.id.widget_up_sub1, View.GONE)
            views.setViewVisibility(R.id.widget_up_row2, View.GONE)
            views.setViewVisibility(R.id.widget_up_sub2, View.GONE)
            views.setViewVisibility(R.id.widget_up_empty, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_up_empty,
                localCtx.getString(R.string.widget_empty_upcoming)
            )
        } else {
            views.setViewVisibility(R.id.widget_up_empty, View.GONE)
            renderRow(views, localCtx, events[0], 1)
            if (events.size >= 2) {
                renderRow(views, localCtx, events[1], 2)
            } else {
                views.setViewVisibility(R.id.widget_up_row2, View.GONE)
                views.setViewVisibility(R.id.widget_up_sub2, View.GONE)
            }
        }

        // Tap → abre la app.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                context,
                1,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_up_row1, pi)
            views.setOnClickPendingIntent(R.id.widget_up_row2, pi)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun renderRow(views: RemoteViews, localCtx: Context, event: EventDto, idx: Int) {
        val (title, sub, whenBadge) = Triple(
            event.title,
            event.subtitle,
            WidgetLocale.relativeLabel(localCtx, daysUntil(event.startMs))
        )
        if (idx == 1) {
            views.setViewVisibility(R.id.widget_up_row1, View.VISIBLE)
            views.setViewVisibility(R.id.widget_up_sub1, View.VISIBLE)
            views.setTextViewText(R.id.widget_up_title1, title)
            views.setTextViewText(R.id.widget_up_sub1, sub)
            views.setTextViewText(R.id.widget_up_when1, whenBadge)
        } else {
            views.setViewVisibility(R.id.widget_up_row2, View.VISIBLE)
            views.setViewVisibility(R.id.widget_up_sub2, View.VISIBLE)
            views.setTextViewText(R.id.widget_up_title2, title)
            views.setTextViewText(R.id.widget_up_sub2, sub)
            views.setTextViewText(R.id.widget_up_when2, whenBadge)
        }
    }

    private data class EventDto(
        val title: String,
        val subtitle: String,
        val startMs: Long
    )

    private fun parseEvents(json: String): List<EventDto> {
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                EventDto(
                    title = o.optString("title", "Event"),
                    subtitle = o.optString("subtitle", ""),
                    startMs = o.optLong("startMs", 0L)
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun daysUntil(startMs: Long): Int {
        if (startMs <= 0) return 0
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val target = Calendar.getInstance().apply {
            timeInMillis = startMs
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val diffMs = target.timeInMillis - today.timeInMillis
        return TimeUnit.MILLISECONDS.toDays(diffMs).toInt()
    }

    companion object {
        /// Refresca todos los widgets Upcoming instalados.
        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, UpcomingWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            val intent = Intent(context, UpcomingWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
