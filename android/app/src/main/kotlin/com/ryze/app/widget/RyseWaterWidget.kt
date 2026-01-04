package com.ryze.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.app.PendingIntent
import com.ryze.app.R
import org.json.JSONObject
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget Android pour afficher la consommation d'eau
 * Équivalent au SmallWidgetView iOS (widget eau)
 */
class RyseWaterWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        // Handle widget update broadcast from Flutter
        if (intent.action == "com.ryze.app.ACTION_UPDATE_WIDGETS") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, RyseWaterWidget::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_water_layout)

            try {
                val jsonString = widgetData.getString("widget_meal_data", null)

                if (jsonString != null) {
                    val json = JSONObject(jsonString)
                    val water = json.optJSONObject("water")

                    if (water != null) {
                        val currentL = water.optDouble("currentL", 0.0)
                        val goalL = water.optDouble("goalL", 2.0)
                        val percentage = water.optInt("percentage", 0)

                        views.setTextViewText(
                            R.id.water_text,
                            String.format("%.1f / %.1f L", currentL, goalL)
                        )
                        views.setProgressBar(R.id.water_progress, 100, percentage.coerceIn(0, 100), false)

                        // Show check mark if goal completed
                        if (currentL >= goalL && goalL > 0) {
                            views.setViewVisibility(R.id.water_complete_icon, android.view.View.VISIBLE)
                        } else {
                            views.setViewVisibility(R.id.water_complete_icon, android.view.View.GONE)
                        }
                    }
                } else {
                    // Default/placeholder values
                    views.setTextViewText(R.id.water_text, "0.0 / 2.0 L")
                    views.setProgressBar(R.id.water_progress, 100, 0, false)
                    views.setViewVisibility(R.id.water_complete_icon, android.view.View.GONE)
                }

                // Set up click intent to add water
                val addWaterIntent = Intent(Intent.ACTION_VIEW, Uri.parse("ryse://add-water"))
                addWaterIntent.setPackage(context.packageName)
                val addWaterPendingIntent = PendingIntent.getActivity(
                    context,
                    200,
                    addWaterIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_water_container, addWaterPendingIntent)

                // Quick add buttons
                val amounts = listOf(250, 500)
                val buttonIds = listOf(R.id.btn_add_250, R.id.btn_add_500)

                amounts.forEachIndexed { index, amount ->
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("ryse://add-water?amount=$amount"))
                    intent.setPackage(context.packageName)
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        201 + index,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(buttonIds[index], pendingIntent)
                }

            } catch (e: Exception) {
                e.printStackTrace()
                // Fallback to defaults
                views.setTextViewText(R.id.water_text, "0.0 / 2.0 L")
                views.setProgressBar(R.id.water_progress, 100, 0, false)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
