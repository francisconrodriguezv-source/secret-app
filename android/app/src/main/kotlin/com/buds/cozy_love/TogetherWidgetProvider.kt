package com.buds.cozy_love

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

/// Widget de home screen "Together". Muestra cuánto tiempo lleva junta
/// la pareja (años + meses + días) leyendo `couple_name` y
/// `since_date_ms` desde SharedPreferences (`cozy_widget_prefs`).
///
/// Resizable de 1x1 a 1x4 celdas. `onAppWidgetOptionsChanged` recibe el
/// tamaño en dp y elige qué elementos mostrar/ocultar y qué formato de
/// duración usar.
class TogetherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val local = WidgetLocale.localized(context)
        for (widgetId in appWidgetIds) {
            val opts = appWidgetManager.getAppWidgetOptions(widgetId)
            renderWidget(context, local, appWidgetManager, widgetId, opts)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val local = WidgetLocale.localized(context)
        renderWidget(context, local, appWidgetManager, appWidgetId, newOptions)
    }

    private fun renderWidget(
        context: Context,
        localCtx: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        options: Bundle
    ) {
        val prefs = context.getSharedPreferences(
            WidgetsBridge.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val coupleName = prefs.getString(WidgetsBridge.KEY_COUPLE_NAME, "")
            ?.takeIf { it.isNotBlank() } ?: "Us"
        val sinceMs = prefs.getLong(WidgetsBridge.KEY_SINCE_MS, 0L)

        val widthDp = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
            250
        )
        val size = sizeForWidth(widthDp)

        val views = RemoteViews(context.packageName, R.layout.widget_together)
        // Label localizado ("TOGETHER" / "JUNTOS").
        views.setTextViewText(
            R.id.widget_together_label,
            localCtx.getString(R.string.widget_label_together)
        )
        applySizeVisibility(views, size)
        applyContent(views, localCtx, size, sinceMs, coupleName)

        // Tap → abre la app.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                context,
                widgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_together_root, pi)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private enum class SizeBucket { XS, S, M, L }

    /// Aproximación estándar: cada celda ≈ 70dp de ancho.
    /// - < 100dp  → 1x1 (XS)
    /// - < 170dp → 1x2 (S)
    /// - < 240dp → 1x3 (M)
    /// - resto   → 1x4 (L)
    private fun sizeForWidth(widthDp: Int): SizeBucket = when {
        widthDp < 100 -> SizeBucket.XS
        widthDp < 170 -> SizeBucket.S
        widthDp < 240 -> SizeBucket.M
        else -> SizeBucket.L
    }

    private fun applySizeVisibility(
        views: RemoteViews,
        size: SizeBucket
    ) {
        when (size) {
            SizeBucket.XS -> {
                // Sólo icono + número compacto grande.
                views.setViewVisibility(R.id.widget_together_text_wrap, View.GONE)
                views.setViewVisibility(R.id.widget_together_label, View.GONE)
                views.setViewVisibility(R.id.widget_together_couple, View.GONE)
                views.setViewVisibility(R.id.widget_together_days_big, View.VISIBLE)
            }
            SizeBucket.S -> {
                views.setViewVisibility(R.id.widget_together_text_wrap, View.VISIBLE)
                views.setViewVisibility(R.id.widget_together_label, View.GONE)
                views.setViewVisibility(R.id.widget_together_couple, View.GONE)
                views.setViewVisibility(R.id.widget_together_days_big, View.GONE)
            }
            SizeBucket.M -> {
                views.setViewVisibility(R.id.widget_together_text_wrap, View.VISIBLE)
                views.setViewVisibility(R.id.widget_together_label, View.VISIBLE)
                views.setViewVisibility(R.id.widget_together_couple, View.GONE)
                views.setViewVisibility(R.id.widget_together_days_big, View.GONE)
            }
            SizeBucket.L -> {
                views.setViewVisibility(R.id.widget_together_text_wrap, View.VISIBLE)
                views.setViewVisibility(R.id.widget_together_label, View.VISIBLE)
                views.setViewVisibility(R.id.widget_together_couple, View.VISIBLE)
                views.setViewVisibility(R.id.widget_together_days_big, View.GONE)
            }
        }
    }

    private fun applyContent(
        views: RemoteViews,
        localCtx: Context,
        size: SizeBucket,
        sinceMs: Long,
        coupleName: String
    ) {
        if (sinceMs <= 0) {
            views.setTextViewText(R.id.widget_together_duration, "—")
            views.setTextViewText(R.id.widget_together_days_big, "—")
            views.setTextViewText(R.id.widget_together_couple, coupleName)
            return
        }
        val parts = computeParts(sinceMs)
        val totalDays = computeTotalDays(sinceMs)

        val durationText = when (size) {
            SizeBucket.S -> WidgetLocale.formatCompact(parts.years, parts.months, parts.days)
            else -> WidgetLocale.formatFull(localCtx, parts.years, parts.months, parts.days)
        }
        views.setTextViewText(R.id.widget_together_duration, durationText)
        views.setTextViewText(R.id.widget_together_days_big, "${totalDays}d")
        views.setTextViewText(R.id.widget_together_couple, coupleName)
    }

    private data class DurationParts(
        val years: Int,
        val months: Int,
        val days: Int,
    )

    private fun computeParts(sinceMs: Long): DurationParts {
        val since = Calendar.getInstance().apply { timeInMillis = sinceMs }
        val now = Calendar.getInstance()

        var years = now.get(Calendar.YEAR) - since.get(Calendar.YEAR)
        var months = now.get(Calendar.MONTH) - since.get(Calendar.MONTH)
        var days = now.get(Calendar.DAY_OF_MONTH) - since.get(Calendar.DAY_OF_MONTH)

        if (days < 0) {
            months--
            val tmp = Calendar.getInstance()
            tmp.timeInMillis = now.timeInMillis
            tmp.add(Calendar.MONTH, -1)
            days += tmp.getActualMaximum(Calendar.DAY_OF_MONTH)
        }
        if (months < 0) {
            years--
            months += 12
        }
        return DurationParts(years, months, days)
    }

    private fun computeTotalDays(sinceMs: Long): Int {
        val now = System.currentTimeMillis()
        return ((now - sinceMs) / (1000L * 60 * 60 * 24)).toInt()
    }

    companion object {
        /// Refresca todos los widgets Together instalados.
        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, TogetherWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            val intent = Intent(context, TogetherWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
