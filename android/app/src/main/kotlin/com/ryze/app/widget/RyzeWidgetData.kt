package com.ryze.app.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import com.ryze.app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * What the app writes, read for now.
 *
 * The contract (version 2) is documented in
 * lib/services/meal_widget_data_provider.dart and WIDGET.md. The app decides
 * everything that needs a rule or a language; this class only reads values
 * and formats numbers for the app's language. Data from another day keeps
 * the goals and the labels and zeroes everything eaten, drunk or planned: the
 * widget never shows yesterday as today. Data from an older app is treated
 * as none.
 */
class RyzeWidgetData private constructor(json: JSONObject, val isToday: Boolean) {

    data class Slot(val id: String, val state: String, val label: String, val word: String)

    val lang: String = json.optString("lang", "").ifEmpty { "en" }
    private val locale = Locale(lang)
    private val strings: JSONObject = json.optJSONObject("strings") ?: JSONObject()
    private val kcal: JSONObject = json.optJSONObject("kcal") ?: JSONObject()
    private val water: JSONObject = json.optJSONObject("water") ?: JSONObject()
    private val theme: JSONObject = json.optJSONObject("theme") ?: JSONObject()

    val eaten: Int = if (isToday) kcal.optInt("eaten", 0) else 0
    val goal: Int = kcal.optInt("goal", 0)
    val goalKnown: Boolean get() = goal > 0
    val left: Int get() = goal - eaten
    val percent: Int get() = if (goal > 0) ((eaten * 100f) / goal).toInt().coerceIn(0, 100) else 0

    val waterMl: Int = if (isToday) water.optInt("ml", 0) else 0
    val goalMl: Int = water.optInt("goalMl", 0)
    val glassMl: Int = water.optInt("glassMl", 250).let { if (it > 0) it else 250 }

    /** One glass is 250 ml, so the goal decides how many are drawn: four to twelve, as in the app. */
    val glasses: Int get() = waterMl / glassMl
    val goalGlasses: Int get() = if (goalMl > 0) (goalMl.toFloat() / glassMl).roundToInt().coerceIn(4, 12) else 8
    val waterFull: Boolean get() = goalMl > 0 && waterMl >= goalMl

    val slots: List<Slot> = run {
        val array = json.optJSONArray("slots") ?: return@run emptyList()
        val freeWord = strings.optString("free_word", "")
        (0 until array.length()).mapNotNull { i ->
            val item = array.optJSONObject(i) ?: return@mapNotNull null
            val word = item.optString("word", "")
            Slot(
                id = item.optString("slot", ""),
                state = if (isToday) item.optString("state", "free") else "free",
                label = item.optString("label", ""),
                word = if (isToday) word else freeWord.ifEmpty { word },
            )
        }
    }

    fun string(key: String, fallback: String = ""): String = strings.optString(key, "").ifEmpty { fallback }

    fun fill(key: String, vararg args: Pair<String, String>): String {
        var text = string(key)
        for ((name, value) in args) text = text.replace("{$name}", value)
        return text
    }

    fun integer(n: Int): String = NumberFormat.getIntegerInstance(locale).format(n)

    fun litres(ml: Int): String = NumberFormat.getNumberInstance(locale).apply {
        minimumFractionDigits = 0
        maximumFractionDigits = 2
    }.format(ml / 1000.0)

    /** What is left, the goal met, or the goal passed: the home's three states, never a fourth. */
    val leadKey: String
        get() = when {
            !goalKnown -> "lead_loading"
            left > 0 -> "lead_remaining"
            left == 0 -> "lead_reached"
            else -> "lead_over"
        }

    val figure: String get() = if (goalKnown) integer(abs(left)) else "—"
    val eatenText: String get() = fill("eaten_tpl", "n" to integer(eaten))
    val goalText: String get() = fill("goal_tpl", "n" to integer(goal))
    val waterText: String get() = litres(waterMl)
    val waterGoalText: String get() = fill("water_goal_tpl", "g" to litres(goalMl))

    // The edition the user chose (lib/design/palette.dart). An edition owns
    // its ground — paper, card, greys, text — and not only its mark, so a
    // widget on Volt is black with volt writing. The tokens in colors_ryze.xml
    // are the original edition, worn before the app has written one.

    val dark: Boolean = theme.optBoolean("dark", false)

    fun paper(context: Context): Int = col(context, "paper", R.color.ryze_paper)
    fun surf(context: Context): Int = col(context, "surf", R.color.ryze_surf)
    fun text(context: Context): Int = col(context, "text", R.color.ryze_ink)
    fun mute(context: Context): Int = col(context, "mute", R.color.ryze_mute)
    fun mute2(context: Context): Int = col(context, "mute2", R.color.ryze_mute2)
    fun idle(context: Context): Int = col(context, "idle", R.color.ryze_idle)
    fun ink(context: Context): Int = col(context, "ink", R.color.ryze_ink)
    fun acc(context: Context): Int = col(context, "acc", R.color.ryze_acc)

    /** The light edge of a free slot and of the widget: the text at 11 %, as the tokens derive it. */
    fun line(context: Context): Int = withAlpha(text(context), 0x1C)

    /** What is written on an ink surface: the card, which follows the ground. */
    fun onInk(context: Context): Int = surf(context)

    private fun col(context: Context, key: String, fallback: Int): Int =
        parse(theme.optString(key, "")) ?: color(context, fallback)

    private fun parse(hex: String): Int? = try {
        if (hex.isEmpty()) null else Color.parseColor(hex)
    } catch (e: IllegalArgumentException) {
        null
    }

    companion object {
        const val DATA_KEY = "widget_meal_data"
        const val ACTION_UPDATE = "com.ryze.app.ACTION_UPDATE_WIDGETS"

        fun load(context: Context): RyzeWidgetData? {
            val text = HomeWidgetPlugin.getData(context).getString(DATA_KEY, null) ?: return null
            val json = try {
                JSONObject(text)
            } catch (e: Exception) {
                return null
            }
            if (json.optInt("v", 0) < 2) return null
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            return RyzeWidgetData(json, json.optString("day", "") == today)
        }

        /** A tap: the app, on what the link names. */
        fun open(context: Context, uri: String, requestCode: Int): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
                setPackage(context.packageName)
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun color(context: Context, id: Int): Int =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                context.getColor(id)
            } else {
                @Suppress("DEPRECATION")
                context.resources.getColor(id)
            }

        fun withAlpha(color: Int, alpha: Int): Int = (color and 0x00FFFFFF) or (alpha shl 24)
    }
}
