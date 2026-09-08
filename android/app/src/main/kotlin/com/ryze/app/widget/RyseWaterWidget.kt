package com.ryze.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import com.ryze.app.R

/**
 * The day's water as glasses, and two buttons that write. A button opens the
 * app on its own write path with the amount in the link, so the glass lands
 * in the journal at once and the widget is redrawn from the truth. Goal
 * reached, the tile turns to ink and the glasses to paper, as the home's
 * water tile does. The ink is the palette's, sent by the app.
 */
class RyseWaterWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) update(context, appWidgetManager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == RyzeWidgetData.ACTION_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RyseWaterWidget::class.java))
            onUpdate(context, manager, ids)
        }
    }

    companion object {
        private val GLASS_IDS = intArrayOf(
            R.id.glass_1, R.id.glass_2, R.id.glass_3, R.id.glass_4, R.id.glass_5, R.id.glass_6,
            R.id.glass_7, R.id.glass_8, R.id.glass_9, R.id.glass_10, R.id.glass_11, R.id.glass_12,
        )

        fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_water_layout)
            try {
                val data = RyzeWidgetData.load(context)
                if (data == null) empty(context, views) else fill(context, views, data)
            } catch (e: Exception) {
                e.printStackTrace()
                empty(context, views)
            }
            views.setOnClickPendingIntent(R.id.widget_water_container, RyzeWidgetData.open(context, "ryse://dashboard", 300))
            manager.updateAppWidget(widgetId, views)
        }

        /** Before the app has written anything, or after a sign-out. */
        private fun empty(context: Context, views: RemoteViews) {
            views.setViewVisibility(R.id.card_ink, View.GONE)
            views.setTextViewText(R.id.water_label, context.getString(R.string.widget_water_name))
            views.setTextViewText(R.id.water_value, context.getString(R.string.widget_open_app))
            views.setTextViewText(R.id.water_goal, "")
            val line = RyzeWidgetData.color(context, R.color.ryze_line)
            for (i in GLASS_IDS.indices) {
                views.setViewVisibility(GLASS_IDS[i], if (i < 8) View.VISIBLE else View.GONE)
                views.setImageViewResource(GLASS_IDS[i], R.drawable.glass_empty)
                views.setInt(GLASS_IDS[i], "setColorFilter", line)
            }
            views.setViewVisibility(R.id.buttons, View.GONE)
        }

        private fun fill(context: Context, views: RemoteViews, data: RyzeWidgetData) {
            val full = data.waterFull
            val ink = data.ink(context)
            val line = data.line(context)
            val surf = RyzeWidgetData.color(context, R.color.ryze_surf)
            val paper = RyzeWidgetData.color(context, R.color.ryze_paper)
            val fg = if (full) paper else ink
            val fg2 = RyzeWidgetData.color(context, if (full) R.color.ryze_paper_72 else R.color.ryze_mute)
            val nextEdge = RyzeWidgetData.color(context, if (full) R.color.ryze_paper_55 else R.color.ryze_mute2)
            val emptyEdge = if (full) RyzeWidgetData.color(context, R.color.ryze_paper_30) else line

            // goal reached: an ink card over the paper
            views.setViewVisibility(R.id.card_ink, if (full) View.VISIBLE else View.GONE)
            views.setInt(R.id.card_ink, "setColorFilter", ink)

            views.setTextViewText(R.id.water_label, data.string("water", context.getString(R.string.widget_water_name)))
            views.setTextColor(R.id.water_label, fg2)
            views.setTextViewText(R.id.water_value, data.waterText)
            views.setTextColor(R.id.water_value, fg)
            views.setTextViewText(R.id.water_goal, data.waterGoalText)
            views.setTextColor(R.id.water_goal, fg2)

            val shown = data.goalGlasses
            val fullGlasses = data.glasses
            for (i in GLASS_IDS.indices) {
                if (i >= shown) {
                    views.setViewVisibility(GLASS_IDS[i], View.GONE)
                    continue
                }
                views.setViewVisibility(GLASS_IDS[i], View.VISIBLE)
                when {
                    i < fullGlasses -> {
                        views.setImageViewResource(GLASS_IDS[i], R.drawable.glass_full)
                        views.setInt(GLASS_IDS[i], "setColorFilter", fg)
                    }
                    i == fullGlasses -> {
                        views.setImageViewResource(GLASS_IDS[i], R.drawable.glass_next)
                        views.setInt(GLASS_IDS[i], "setColorFilter", nextEdge)
                    }
                    else -> {
                        views.setImageViewResource(GLASS_IDS[i], R.drawable.glass_empty)
                        views.setInt(GLASS_IDS[i], "setColorFilter", emptyEdge)
                    }
                }
            }

            // the buttons: an ink pill and a ghost one on paper, the reverse on ink
            views.setViewVisibility(R.id.buttons, View.VISIBLE)
            views.setTextViewText(R.id.btn_glass_one_text, data.string("glass_one", "+ 1"))
            views.setTextColor(R.id.btn_glass_one_text, if (full) ink else paper)
            views.setInt(R.id.btn_glass_one_fill, "setColorFilter", if (full) paper else ink)
            views.setTextViewText(R.id.btn_glass_two_text, data.string("glass_two", "+ 2"))
            views.setTextColor(R.id.btn_glass_two_text, fg)
            views.setViewVisibility(R.id.btn_glass_two_fill, if (full) View.GONE else View.VISIBLE)
            views.setInt(R.id.btn_glass_two_fill, "setColorFilter", surf)
            views.setInt(
                R.id.btn_glass_two_edge,
                "setColorFilter",
                if (full) RyzeWidgetData.color(context, R.color.ryze_paper_35) else line,
            )

            // the amount travels in the link, and the app writes it on arrival
            views.setOnClickPendingIntent(R.id.btn_glass_one, RyzeWidgetData.open(context, "ryse://add-water?amount=${data.glassMl}", 301))
            views.setOnClickPendingIntent(R.id.btn_glass_two, RyzeWidgetData.open(context, "ryse://add-water?amount=${2 * data.glassMl}", 302))
        }
    }
}
