package apps.waleed.sunnah.wgoot.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import apps.waleed.sunnah.wgoot.MainActivity
import apps.waleed.sunnah.wgoot.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = WidgetPayload.parse(widgetData.getString(PAYLOAD_KEY, null))
        val now = System.currentTimeMillis()
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(
                widgetId,
                render(context, appWidgetManager, widgetId, payload, now),
            )
        }
        scheduleNextRefresh(context, payload, now)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in REFRESH_ACTIONS) {
            refreshAll(context)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        alarmManager(context)?.cancel(refreshIntent(context))
    }

    private fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(
            ComponentName(context, PrayerWidgetProvider::class.java),
        )
        if (ids.isNotEmpty()) {
            onUpdate(context, manager, ids)
        }
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        payload: WidgetPayload?,
        now: Long,
    ): RemoteViews {
        val minHeight = appWidgetManager
            .getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val compact = minHeight in 1 until COMPACT_MAX_HEIGHT_DP
        val layout = if (compact) R.layout.wgoot_widget_compact else R.layout.wgoot_widget
        val views = RemoteViews(context.packageName, layout)

        views.setOnClickPendingIntent(
            R.id.wgoot_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val day = payload?.dayAt(now)
        val next = payload?.nextFard(now)
        if (day == null || next == null) {
            renderPlaceholder(context, views, compact)
            return views
        }

        views.setViewVisibility(R.id.wgoot_empty, View.GONE)
        views.setViewVisibility(R.id.wgoot_countdown_block, View.VISIBLE)
        views.setTextViewText(R.id.wgoot_city, payload.city)
        views.setTextViewText(R.id.wgoot_next_title, next.title)
        views.setTextViewText(R.id.wgoot_next_clock, next.clock)
        views.setChronometerCountDown(R.id.wgoot_countdown, true)
        views.setChronometer(
            R.id.wgoot_countdown,
            SystemClock.elapsedRealtime() + (next.at - now),
            null,
            true,
        )

        if (!compact) {
            views.setViewVisibility(R.id.wgoot_grid, View.VISIBLE)
            views.setTextViewText(R.id.wgoot_hijri, day.hijri)
            renderGrid(context, views, day, next)
        }
        return views
    }

    private fun renderPlaceholder(context: Context, views: RemoteViews, compact: Boolean) {
        views.setTextViewText(R.id.wgoot_city, context.getString(R.string.app_name))
        views.setTextViewText(R.id.wgoot_next_title, PLACEHOLDER_DASH)
        views.setTextViewText(R.id.wgoot_next_clock, "")
        views.setViewVisibility(R.id.wgoot_countdown_block, View.GONE)
        views.setViewVisibility(R.id.wgoot_empty, View.VISIBLE)
        if (!compact) {
            views.setTextViewText(R.id.wgoot_hijri, "")
            views.setViewVisibility(R.id.wgoot_grid, View.GONE)
        }
    }

    private fun renderGrid(
        context: Context,
        views: RemoteViews,
        day: WidgetDay,
        next: WidgetSlot,
    ) {
        val gold = context.getColor(R.color.wgoot_widget_gold)
        val muted = context.getColor(R.color.wgoot_widget_muted)
        val text = context.getColor(R.color.wgoot_widget_text)

        SLOT_IDS.forEachIndexed { index, ids ->
            val slot = day.slots.getOrNull(index)
            if (slot == null) {
                views.setViewVisibility(ids.container, View.GONE)
                return@forEachIndexed
            }
            val highlighted = slot.at == next.at
            views.setViewVisibility(ids.container, View.VISIBLE)
            views.setTextViewText(ids.title, slot.title)
            views.setTextViewText(ids.clock, slot.clock)
            views.setInt(
                ids.container,
                "setBackgroundResource",
                if (highlighted) R.drawable.wgoot_widget_pill else 0,
            )
            views.setTextColor(ids.title, if (highlighted) gold else muted)
            views.setTextColor(ids.clock, if (highlighted) gold else text)
        }
    }

    private fun scheduleNextRefresh(context: Context, payload: WidgetPayload?, now: Long) {
        val manager = alarmManager(context) ?: return
        val pendingIntent = refreshIntent(context)
        manager.cancel(pendingIntent)

        val target = payload?.nextBoundary(now) ?: (now + FALLBACK_REFRESH_MS)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            manager.canScheduleExactAlarms()
        if (exact) {
            manager.setExact(AlarmManager.RTC, target, pendingIntent)
        } else {
            manager.set(AlarmManager.RTC, target, pendingIntent)
        }
    }

    private fun alarmManager(context: Context): AlarmManager? =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    private fun refreshIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerWidgetProvider::class.java)
            .setAction(ACTION_REFRESH)
        return PendingIntent.getBroadcast(
            context,
            REFRESH_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private data class SlotIds(val container: Int, val title: Int, val clock: Int)

    private companion object {
        const val PAYLOAD_KEY = "wgoot_payload"
        const val ACTION_REFRESH = "apps.waleed.sunnah.wgoot.widget.REFRESH"
        const val REFRESH_REQUEST_CODE = 8301
        const val COMPACT_MAX_HEIGHT_DP = 110
        const val FALLBACK_REFRESH_MS = 30 * 60 * 1000L
        const val PLACEHOLDER_DASH = "—"

        val REFRESH_ACTIONS = setOf(
            ACTION_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
        )

        val SLOT_IDS = listOf(
            SlotIds(R.id.wgoot_slot_0, R.id.wgoot_slot_0_title, R.id.wgoot_slot_0_clock),
            SlotIds(R.id.wgoot_slot_1, R.id.wgoot_slot_1_title, R.id.wgoot_slot_1_clock),
            SlotIds(R.id.wgoot_slot_2, R.id.wgoot_slot_2_title, R.id.wgoot_slot_2_clock),
            SlotIds(R.id.wgoot_slot_3, R.id.wgoot_slot_3_title, R.id.wgoot_slot_3_clock),
            SlotIds(R.id.wgoot_slot_4, R.id.wgoot_slot_4_title, R.id.wgoot_slot_4_clock),
            SlotIds(R.id.wgoot_slot_5, R.id.wgoot_slot_5_title, R.id.wgoot_slot_5_clock),
        )
    }
}
