package com.buds.cozy_love

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit

/// Widget "Countdown" — cuenta días hasta la próxima fecha importante.
///
/// El bridge (Flutter) resuelve cuál es la fecha objetivo y la guarda en
/// `countdown_json = { title, startMs }`. Si no hay datos, muestra empty.
class CountdownWidgetProvider : AppWidgetProvider() {

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
        val json = prefs.getString(WidgetsBridge.KEY_COUNTDOWN_JSON, "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.widget_countdown)

        val target = parseTarget(json)
        if (target == null) {
            renderEmpty(views, localCtx)
        } else {
            renderTarget(views, localCtx, target)
        }

        // Tap → abre la app.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                context, widgetId, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_countdown_root, pi)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun renderEmpty(views: RemoteViews, localCtx: Context) {
        views.setViewVisibility(R.id.widget_countdown_top, View.GONE)
        views.setViewVisibility(R.id.widget_countdown_progress, View.GONE)
        views.setViewVisibility(R.id.widget_countdown_empty_wrap, View.VISIBLE)
        views.setTextViewText(
            R.id.widget_countdown_empty,
            localCtx.getString(R.string.widget_empty_countdown)
        )
    }

    private fun renderTarget(
        views: RemoteViews,
        localCtx: Context,
        target: TargetDto,
    ) {
        views.setViewVisibility(R.id.widget_countdown_empty_wrap, View.GONE)
        views.setViewVisibility(R.id.widget_countdown_top, View.VISIBLE)
        views.setViewVisibility(R.id.widget_countdown_progress, View.VISIBLE)

        views.setTextViewText(R.id.widget_countdown_title, target.title)

        val days = daysUntil(target.startMs)
        val absDays = kotlin.math.abs(days)
        views.setTextViewText(R.id.widget_countdown_days, absDays.toString())

        // "days" o "día" con el número — se pluraliza.
        val word = if (absDays == 1)
            localCtx.getString(R.string.widget_day_word)
        else
            localCtx.getString(R.string.widget_days_word)
        views.setTextViewText(R.id.widget_countdown_days_word, word)

        val dateStr = WidgetLocale.formatShortDate(localCtx, target.startMs)
        views.setTextViewText(R.id.widget_countdown_date, dateStr)

        // Progress hacia la fecha objetivo. Ventana de 100 días:
        //   - Si daysLeft >= 100 → progreso ~0% (evento muy lejano)
        //   - Si daysLeft == 0  → 100% (¡es hoy!)
        //   - Si daysLeft < 0   → 100% (evento pasado, se mantiene lleno)
        val progress = when {
            days < 0 -> 100
            days >= 100 -> 3 // mínimo visible para que se vea "algo"
            else -> 100 - days
        }
        views.setProgressBar(
            R.id.widget_countdown_progress,
            100,
            progress,
            false,
        )
    }

    private data class TargetDto(val title: String, val startMs: Long)

    private fun parseTarget(json: String): TargetDto? {
        if (json.isBlank() || json == "null") return null
        return try {
            val o = JSONObject(json)
            val title = o.optString("title", "")
            val ms = o.optLong("startMs", 0L)
            if (title.isBlank() || ms <= 0L) null
            else TargetDto(title, ms)
        } catch (e: Exception) {
            null
        }
    }

    private fun daysUntil(startMs: Long): Int {
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
        val diff = target.timeInMillis - today.timeInMillis
        return TimeUnit.MILLISECONDS.toDays(diff).toInt()
    }

    companion object {
        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, CountdownWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            val intent = Intent(context, CountdownWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
