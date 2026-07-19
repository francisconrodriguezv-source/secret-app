package com.buds.cozy_love

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

/// Utilidades comunes para los home widgets:
/// - Recuperar el idioma seleccionado en la app (persistido por
///   `WidgetsBridge`) y crear un [Context] con esa localización.
/// - Formatear duraciones y etiquetas relativas.
internal object WidgetLocale {

    /// Devuelve un context con la Locale que el usuario eligió en la app.
    fun localized(base: Context): Context {
        val prefs = base.getSharedPreferences(
            WidgetsBridge.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val code = prefs.getString(WidgetsBridge.KEY_LOCALE, "en") ?: "en"
        val locale = Locale(code)
        val config = Configuration(base.resources.configuration).apply {
            setLocale(locale)
        }
        return base.createConfigurationContext(config)
    }

    /// Formato completo de una duración: "6 yrs 10 mos 27 days" / "6 años 10 meses 27 días".
    fun formatFull(ctx: Context, years: Int, months: Int, days: Int): String {
        val out = mutableListOf<String>()
        if (years > 0) {
            val label = if (years == 1)
                ctx.getString(R.string.widget_year_singular)
            else
                ctx.getString(R.string.widget_year_plural)
            out.add("$years $label")
        }
        if (months > 0) {
            val label = if (months == 1)
                ctx.getString(R.string.widget_month_singular)
            else
                ctx.getString(R.string.widget_month_plural)
            out.add("$months $label")
        }
        val dayLabel = if (days == 1)
            ctx.getString(R.string.widget_day_singular)
        else
            ctx.getString(R.string.widget_day_plural)
        out.add("$days $dayLabel")
        return out.joinToString(" ")
    }

    /// Formato compacto: "6y 10m" / se acorta al primer año/mes disponible.
    fun formatCompact(years: Int, months: Int, days: Int): String {
        val bits = mutableListOf<String>()
        if (years > 0) bits.add("${years}y")
        if (months > 0) bits.add("${months}m")
        if (bits.isEmpty()) bits.add("${days}d")
        return bits.joinToString(" ")
    }

    /// Etiqueta relativa a hoy ("in 5 days" / "en 5 días", "Today"...).
    fun relativeLabel(ctx: Context, days: Int): String = when {
        days < 0 -> ctx.getString(R.string.widget_relative_past)
        days == 0 -> ctx.getString(R.string.widget_relative_today)
        days == 1 -> ctx.getString(R.string.widget_relative_tomorrow)
        days < 7 -> {
            val word = if (days == 1)
                ctx.getString(R.string.widget_day_word)
            else
                ctx.getString(R.string.widget_days_word)
            ctx.getString(R.string.widget_relative_in, "$days $word")
        }
        days < 30 -> {
            val w = (days / 7.0).toInt().coerceAtLeast(1)
            val word = if (w == 1)
                ctx.getString(R.string.widget_week_singular)
            else
                ctx.getString(R.string.widget_week_plural)
            ctx.getString(R.string.widget_relative_in, "$w $word")
        }
        else -> {
            val m = (days / 30.0).toInt().coerceAtLeast(1)
            val word = if (m == 1)
                ctx.getString(R.string.widget_month_singular)
            else
                ctx.getString(R.string.widget_month_plural)
            ctx.getString(R.string.widget_relative_in, "$m $word")
        }
    }

    /// Nombre corto de mes ("Aug" / "Ago") + día + año.
    fun formatShortDate(ctx: Context, millis: Long): String {
        val cal = java.util.Calendar.getInstance().apply { timeInMillis = millis }
        val prefs = ctx.getSharedPreferences(
            WidgetsBridge.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val code = prefs.getString(WidgetsBridge.KEY_LOCALE, "en") ?: "en"
        val monthNames = if (code == "es") listOf(
            "Ene", "Feb", "Mar", "Abr", "May", "Jun",
            "Jul", "Ago", "Sep", "Oct", "Nov", "Dic",
        ) else listOf(
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
        )
        val month = monthNames[cal.get(java.util.Calendar.MONTH)]
        val day = cal.get(java.util.Calendar.DAY_OF_MONTH)
        val year = cal.get(java.util.Calendar.YEAR)
        return "$month $day, $year"
    }
}
