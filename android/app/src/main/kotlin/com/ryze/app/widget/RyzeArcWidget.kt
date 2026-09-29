package com.ryze.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.SizeF
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.ryze.app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.ceil

/**
 * The Winter Arc: the word of the day beside the ice flame, the day out of
 * 90, what is left to hold it, and in the medium size the 90 days as a grid.
 *
 * Every word comes from the app's `arc` block (lib/arc/arc_widget_data.dart);
 * this class only lays it out on the season's night. The snow and the flame
 * move in the layout itself (ViewFlippers, see widget_arc_flame.xml and
 * res/anim/arc_snow_*), so nothing here runs to animate them. A tap opens
 * the arc screen.
 */
class RyzeArcWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) update(context, appWidgetManager, id)
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        update(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == RyzeWidgetData.ACTION_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RyzeArcWidget::class.java))
            onUpdate(context, manager, ids)
        }
    }

    /** The `arc` block, read for today. */
    private class Arc(json: JSONObject, arc: JSONObject) {
        /**
         * The app wrote on an earlier day and has not been opened since: the
         * widget cannot know whether yesterday was held, so it keeps the
         * series as it was and asks for the app.
         */
        val stale: Boolean = json.optString("day", "") != SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val day: Int = arc.optInt("day", 0)
        val held: Boolean = arc.optBoolean("held", false) && !stale
        val cells: String = arc.optString("cells", "")
        val tag: String = if (stale) arc.optString("tag_open", "").ifEmpty { arc.optString("tag", "") } else arc.optString("tag", "")
        val status: String = if (stale) arc.optString("stale", "") else arc.optString("status", "")

        companion object {
            fun load(context: Context): Arc? {
                val text = HomeWidgetPlugin.getData(context).getString(RyzeWidgetData.DATA_KEY, null) ?: return null
                val json = try {
                    JSONObject(text)
                } catch (e: Exception) {
                    return null
                }
                if (json.optInt("v", 0) < 2) return null
                val arc = json.optJSONObject("arc") ?: return null
                return Arc(json, arc)
            }
        }
    }

    companion object {
        private const val LENGTH = 90

        /** From this width on, the widget has room for the grid. */
        private const val MEDIUM_MIN_WIDTH_DP = 250

        fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val arc = try {
                Arc.load(context)
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
            val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // the launcher picks the layout for the size it gives the widget
                RemoteViews(
                    mapOf(
                        SizeF(110f, 110f) to build(context, arc, medium = false),
                        SizeF(MEDIUM_MIN_WIDTH_DP.toFloat(), 110f) to build(context, arc, medium = true),
                    ),
                )
            } else {
                val width = manager.getAppWidgetOptions(widgetId).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
                build(context, arc, medium = width >= MEDIUM_MIN_WIDTH_DP)
            }
            manager.updateAppWidget(widgetId, views)
        }

        private fun build(context: Context, arc: Arc?, medium: Boolean): RemoteViews {
            val views = RemoteViews(context.packageName, if (medium) R.layout.widget_arc_medium else R.layout.widget_arc_small)
            val white = 0xFFFFFFFF.toInt()
            val amber = RyzeWidgetData.color(context, R.color.arc_amber)
            val iceHi = RyzeWidgetData.color(context, R.color.arc_ice_hi)

            // With animations removed on the phone, the snow and the flame stand still.
            val still = animationsOff(context)
            views.setViewVisibility(R.id.arc_snow_moving, if (still) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.arc_snow_still, if (still) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.arc_flame_moving, if (still) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.arc_flame_still, if (still) View.VISIBLE else View.GONE)

            if (arc == null) {
                // before the app has written the arc: the night, the flame, and the one thing to do
                views.setTextViewText(R.id.arc_tag, "")
                views.setTextViewText(R.id.arc_day, context.getString(R.string.widget_open_app))
                views.setTextViewTextSize(R.id.arc_day, TypedValue.COMPLEX_UNIT_SP, 17f)
                views.setViewVisibility(R.id.arc_of, View.GONE)
                views.setTextViewText(R.id.arc_status, "")
                if (medium) views.setImageViewBitmap(R.id.arc_grid, grid(context, ""))
            } else {
                views.setTextViewText(R.id.arc_tag, lines(arc.tag))
                views.setTextColor(R.id.arc_tag, if (arc.held) amber else white)
                views.setTextViewText(R.id.arc_day, arc.day.toString())
                views.setViewVisibility(R.id.arc_of, View.VISIBLE)
                views.setTextViewText(R.id.arc_status, arc.status)
                views.setTextColor(R.id.arc_status, if (arc.held) iceHi else amber)
                if (medium) views.setImageViewBitmap(R.id.arc_grid, grid(context, arc.cells))
            }

            views.setOnClickPendingIntent(R.id.arc_container, RyzeWidgetData.open(context, "ryse://arc", 400))
            return views
        }

        /**
         * One word to a line, never cut inside a word: the app marks where a
         * long word may break with a soft hyphen (GE-SCHAFFT.), and the text
         * view shrinks the whole word until the longest line fits.
         */
        private fun lines(tag: String): String =
            tag.split(' ').filter { it.isNotEmpty() }.joinToString("\n") { it.replace("\u00AD", "-\n") }

        private fun animationsOff(context: Context): Boolean = try {
            Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
        } catch (e: Exception) {
            false
        }

        /**
         * The 90 days, ten to a row: held in amber, a session in deep amber,
         * a joker in frost, the day still to hold outlined, the rest waiting.
         */
        private fun grid(context: Context, cells: String): Bitmap {
            val density = context.resources.displayMetrics.density
            val side = 9.6f * density
            val gap = 2.5f * density
            val radius = 2.4f * density
            val stroke = 1.2f * density
            val width = ceil(10 * side + 9 * gap).toInt()
            val height = ceil(9 * side + 8 * gap).toInt()
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
            val edge = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = stroke
                color = 0xE6FFFFFF.toInt()
            }
            val colors = mapOf(
                'h' to RyzeWidgetData.color(context, R.color.arc_amber),
                't' to RyzeWidgetData.color(context, R.color.arc_amber_deep),
                'j' to RyzeWidgetData.color(context, R.color.arc_joker),
            )
            val idle = RyzeWidgetData.color(context, R.color.arc_idle)
            for (i in 0 until LENGTH) {
                val x = (i % 10) * (side + gap)
                val y = (i / 10) * (side + gap)
                val code = cells.getOrNull(i)
                if (code == 'p') {
                    val inset = stroke / 2
                    canvas.drawRoundRect(RectF(x + inset, y + inset, x + side - inset, y + side - inset), radius, radius, edge)
                } else {
                    fill.color = code?.let { colors[it] } ?: idle
                    canvas.drawRoundRect(RectF(x, y, x + side, y + side), radius, radius, fill)
                }
            }
            return bitmap
        }
    }
}
