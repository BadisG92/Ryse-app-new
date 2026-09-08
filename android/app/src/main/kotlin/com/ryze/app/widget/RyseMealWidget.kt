package com.ryze.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.ryze.app.R

/**
 * The home in miniature: one thing to read, what is left of the goal, and
 * the five slots of the day in their three states. Free is a white tile with
 * a light edge, planned an ink edge, done an ink fill with a check. The
 * session is a pill, a meal a tile, as everywhere in the app. The ink and
 * the accent are the palette's, sent by the app. Its class name is the first
 * widget's, so the widgets already placed stay where they are.
 */
class RyseMealWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) update(context, appWidgetManager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == RyzeWidgetData.ACTION_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, RyseMealWidget::class.java))
            onUpdate(context, manager, ids)
        }
    }

    companion object {
        private val SLOT_IDS = intArrayOf(R.id.slot_1, R.id.slot_2, R.id.slot_3, R.id.slot_4, R.id.slot_5)
        private val FILL_IDS = intArrayOf(R.id.slot_1_fill, R.id.slot_2_fill, R.id.slot_3_fill, R.id.slot_4_fill, R.id.slot_5_fill)
        private val EDGE_IDS = intArrayOf(R.id.slot_1_edge, R.id.slot_2_edge, R.id.slot_3_edge, R.id.slot_4_edge, R.id.slot_5_edge)
        private val ICON_IDS = intArrayOf(R.id.slot_1_icon, R.id.slot_2_icon, R.id.slot_3_icon, R.id.slot_4_icon, R.id.slot_5_icon)
        private val LABEL_IDS = intArrayOf(R.id.slot_1_label, R.id.slot_2_label, R.id.slot_3_label, R.id.slot_4_label, R.id.slot_5_label)
        private val WORD_IDS = intArrayOf(R.id.slot_1_word, R.id.slot_2_word, R.id.slot_3_word, R.id.slot_4_word, R.id.slot_5_word)

        fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_meal_layout)
            try {
                val data = RyzeWidgetData.load(context)
                if (data == null) empty(context, views) else fill(context, views, data)
            } catch (e: Exception) {
                e.printStackTrace()
                empty(context, views)
            }
            views.setOnClickPendingIntent(R.id.widget_container, RyzeWidgetData.open(context, "ryse://dashboard", 100))
            manager.updateAppWidget(widgetId, views)
        }

        /** Before the app has written anything, or after a sign-out. */
        private fun empty(context: Context, views: RemoteViews) {
            views.setTextViewText(R.id.lead, context.getString(R.string.widget_meal_description))
            views.setTextViewText(R.id.figure, context.getString(R.string.widget_open_app))
            views.setTextViewText(R.id.unit, "")
            views.setTextViewText(R.id.detail, "")
            views.setProgressBar(R.id.gauge, 100, 0, false)
            views.setViewVisibility(R.id.slots, View.GONE)
        }

        private fun fill(context: Context, views: RemoteViews, data: RyzeWidgetData) {
            val ink = data.ink(context)
            val acc = data.acc(context)
            val line = data.line(context)
            val surf = RyzeWidgetData.color(context, R.color.ryze_surf)
            val paper = RyzeWidgetData.color(context, R.color.ryze_paper)
            val paper72 = RyzeWidgetData.color(context, R.color.ryze_paper_72)
            val mute = RyzeWidgetData.color(context, R.color.ryze_mute)
            val mute2 = RyzeWidgetData.color(context, R.color.ryze_mute2)

            views.setTextViewText(R.id.lead, data.string(data.leadKey))
            views.setTextViewText(R.id.figure, data.figure)
            views.setTextColor(R.id.figure, ink)
            views.setTextViewText(R.id.unit, if (data.goalKnown) data.string("unit", "kcal") else "")
            views.setTextViewText(R.id.detail, data.eatenText + "\n" + data.goalText)
            views.setProgressBar(R.id.gauge, 100, data.percent, false)
            // the accent of the gauge follows the palette where the system
            // lets a widget tint a progress bar; below Android 12 it keeps
            // the original amber of the drawable
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(R.id.gauge, "setProgressTintList", ColorStateList.valueOf(acc))
            }
            views.setViewVisibility(R.id.slots, View.VISIBLE)

            for (i in SLOT_IDS.indices) {
                val slot = data.slots.getOrNull(i)
                if (slot == null) {
                    views.setViewVisibility(SLOT_IDS[i], View.GONE)
                    continue
                }
                views.setViewVisibility(SLOT_IDS[i], View.VISIBLE)

                val done = slot.state == "done"
                val planned = slot.state == "planned"
                val sport = slot.id == "sport"
                val fg = if (done) paper else if (planned) ink else mute
                val fg2 = if (done) paper72 else mute2

                // the ground and the edge are two tinted shapes: ink fill when
                // done, an ink edge when planned, a light edge when free
                views.setImageViewResource(FILL_IDS[i], if (sport) R.drawable.pill_fill else R.drawable.tile_fill)
                views.setInt(FILL_IDS[i], "setColorFilter", if (done) ink else surf)
                views.setImageViewResource(
                    EDGE_IDS[i],
                    when {
                        planned && !done -> if (sport) R.drawable.pill_edge_thick else R.drawable.tile_edge_thick
                        else -> if (sport) R.drawable.pill_edge else R.drawable.tile_edge
                    },
                )
                views.setInt(EDGE_IDS[i], "setColorFilter", if (done || planned) ink else line)

                views.setImageViewResource(ICON_IDS[i], if (done) R.drawable.ic_check else icon(slot.id))
                views.setInt(ICON_IDS[i], "setColorFilter", fg)
                views.setTextViewText(LABEL_IDS[i], slot.label)
                views.setTextColor(LABEL_IDS[i], fg)
                views.setTextViewText(WORD_IDS[i], slot.word)
                views.setTextColor(WORD_IDS[i], fg2)

                // a meal opens its add sheet, the session opens Sport: what
                // the home's row of the day does for the same tap
                val uri = if (sport) "ryse://sport" else "ryse://add-food?meal=${slot.id}"
                views.setOnClickPendingIntent(SLOT_IDS[i], RyzeWidgetData.open(context, uri, 1 + i))
            }
        }

        private fun icon(slot: String): Int = when (slot) {
            "breakfast" -> R.drawable.ic_sunrise
            "lunch" -> R.drawable.ic_sun
            "snack" -> R.drawable.ic_cookie
            "dinner" -> R.drawable.ic_sunset
            "sport" -> R.drawable.ic_dumbbell
            else -> R.drawable.ic_sun
        }
    }
}
