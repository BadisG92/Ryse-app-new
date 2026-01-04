package com.ryze.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import android.app.PendingIntent
import com.ryze.app.R
import org.json.JSONObject
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget Android pour afficher les repas et les calories
 * Équivalent au RyseMealWidget iOS
 */
class RyseMealWidget : AppWidgetProvider() {

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
                android.content.ComponentName(context, RyseMealWidget::class.java)
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
            val views = RemoteViews(context.packageName, R.layout.widget_meal_layout)

            try {
                val jsonString = widgetData.getString("widget_meal_data", null)

                if (jsonString != null) {
                    val json = JSONObject(jsonString)
                    val totals = json.optJSONObject("totals")
                    val allMeals = json.optJSONArray("allMeals")

                    // Update calorie display
                    val current = totals?.optInt("current", 0) ?: 0
                    val goal = totals?.optInt("goal", 2000) ?: 2000
                    val percentage = totals?.optInt("percentage", 0) ?: 0

                    views.setTextViewText(R.id.calorie_text, "$current / $goal kcal")
                    views.setProgressBar(R.id.calorie_progress, 100, percentage.coerceIn(0, 100), false)

                    // Update meal calories and labels
                    if (allMeals != null) {
                        val mealCalorieIds = listOf(
                            R.id.breakfast_calories,
                            R.id.lunch_calories,
                            R.id.dinner_calories,
                            R.id.snack_calories
                        )

                        val mealLabelIds = listOf(
                            R.id.breakfast_label,
                            R.id.lunch_label,
                            R.id.dinner_label,
                            R.id.snack_label
                        )

                        for (i in 0 until minOf(allMeals.length(), 4)) {
                            val meal = allMeals.getJSONObject(i)
                            val calories = meal.optInt("calories", 0)
                            val name = meal.optString("name", "")

                            views.setTextViewText(mealCalorieIds[i], "$calories")

                            // Set localized meal name if available
                            if (name.isNotEmpty()) {
                                views.setTextViewText(mealLabelIds[i], name)
                            }
                        }
                    }
                } else {
                    // Default/placeholder values
                    views.setTextViewText(R.id.calorie_text, "0 / 2000 kcal")
                    views.setProgressBar(R.id.calorie_progress, 100, 0, false)
                }

                // Set up click intents for each meal button
                val mealTypes = listOf("petit-dejeuner", "dejeuner", "diner", "snack")
                val buttonIds = listOf(R.id.btn_breakfast, R.id.btn_lunch, R.id.btn_dinner, R.id.btn_snack)

                mealTypes.forEachIndexed { index, mealType ->
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("ryse://add-food?meal=$mealType"))
                    intent.setPackage(context.packageName)
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        index,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(buttonIds[index], pendingIntent)
                }

                // Default click opens the app
                val openAppIntent = Intent(Intent.ACTION_VIEW, Uri.parse("ryse://dashboard"))
                openAppIntent.setPackage(context.packageName)
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    100,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

            } catch (e: Exception) {
                e.printStackTrace()
                // Fallback to defaults
                views.setTextViewText(R.id.calorie_text, "0 / 2000 kcal")
                views.setProgressBar(R.id.calorie_progress, 100, 0, false)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
