package com.blockwebmaster.app.blocker

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.blockwebmaster.app.R
import org.json.JSONObject

/**
 * Ongoing notification showing the remaining time on a scheduled (daily/
 * hourly/weekly) profile's limit, shown while the user is inside one of
 * that profile's apps — so the countdown is visible from the moment they
 * open the app, not just once it's already blocked.
 *
 * Data comes from Dart (profile_enforcement.dart's computeProfileCountdowns
 * / app_monitor.dart's _syncProfileCountdowns), pushed into the same
 * SharedPreferences BlockerBridge.kt already uses. The displayed minutes
 * are only as fresh as the last sync (driven by store changes — usually
 * within seconds, not a literal per-second native tick), refreshed by
 * BlockAccessibilityService's existing ~2s foreground poll while the app
 * stays in the foreground — a periodically-updated "X minutes left"
 * rather than a live HH:MM:SS clock, matching the whole-minute granularity
 * profile limits are actually configured in.
 *
 * Uses plain platform Notification APIs (not androidx.core's
 * NotificationCompat) — this module has no direct androidx.core dependency
 * declared, only a transitive one from other Flutter plugins, which isn't
 * safe to assume is exposed on this module's compile classpath.
 */
class CountdownNotifier(private val service: BlockAccessibilityService) {

  private var shownForPackage: String? = null
  private var lastRemainingMinutes: Int? = null

  /** Shows/updates the countdown for [packageName] if one applies, or
   *  dismisses any currently-shown countdown if it doesn't (profile
   *  deactivated, ran out in the meantime, or simply not a tracked app). */
  fun update(packageName: String) {
    val entry = countdownFor(packageName)
    if (entry == null) {
      // See DEBUG_LOGGING doc comment — confirms whether Dart ever pushed a
      // countdown covering this package at all, before looking any further.
      if (DEBUG_LOGGING) Log.d(TAG, "update pkg=$packageName: no countdown entry (raw=${prefsString(BlockAccessibilityService.PROFILE_COUNTDOWNS_KEY)})")
      dismiss()
      return
    }
    val (profileName, remainingMinutes) = entry
    if (DEBUG_LOGGING) Log.d(TAG, "update pkg=$packageName profile=$profileName remaining=$remainingMinutes")
    if (shownForPackage == packageName && lastRemainingMinutes == remainingMinutes) return
    show(packageName, profileName, remainingMinutes)
  }

  fun dismiss() {
    if (shownForPackage == null) return
    shownForPackage = null
    lastRemainingMinutes = null
    try {
      notificationManager()?.cancel(NOTIFICATION_ID)
    } catch (e: Exception) {}
  }

  private fun show(packageName: String, profileName: String, remainingMinutes: Int) {
    if (!hasNotificationPermission()) {
      if (DEBUG_LOGGING) Log.d(TAG, "show pkg=$packageName: POST_NOTIFICATIONS not granted, skipping")
      return
    }
    val nm = notificationManager() ?: return
    ensureChannel(nm)

    val strings = countdownStrings()
    val title = strings?.optString("title")?.takeIf { it.isNotBlank() }?.replace("{{profile}}", profileName)
      ?: profileName
    val body = strings?.optString("body")?.takeIf { it.isNotBlank() }?.replace("{{minutes}}", remainingMinutes.toString())
      ?: "$remainingMinutes"

    val contentIntent = try {
      val launchIntent = service.packageManager.getLaunchIntentForPackage(service.packageName)
        ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      launchIntent?.let {
        PendingIntent.getActivity(service, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
      }
    } catch (e: Exception) {
      null
    }

    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Notification.Builder(service, CHANNEL_ID)
    } else {
      @Suppress("DEPRECATION")
      Notification.Builder(service)
    }
    builder
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle(title)
      .setContentText(body)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setShowWhen(false)
    if (contentIntent != null) builder.setContentIntent(contentIntent)

    try {
      nm.notify(NOTIFICATION_ID, builder.build())
      shownForPackage = packageName
      lastRemainingMinutes = remainingMinutes
      if (DEBUG_LOGGING) Log.d(TAG, "show pkg=$packageName: notify() called, title=\"$title\" body=\"$body\"")
    } catch (e: Exception) {
      // Best-effort — a failed notification just means no countdown is
      // visible, not something worth crashing the accessibility service over.
      if (DEBUG_LOGGING) Log.w(TAG, "show pkg=$packageName: notify() threw", e)
    }
  }

  private fun countdownFor(packageName: String): Pair<String, Int>? {
    val json = prefsString(BlockAccessibilityService.PROFILE_COUNTDOWNS_KEY) ?: return null
    return try {
      val entry = JSONObject(json).optJSONObject(packageName) ?: return null
      val name = entry.optString("profileName", "")
      val minutes = entry.optInt("remainingMinutes", -1)
      if (name.isEmpty() || minutes < 0) null else Pair(name, minutes)
    } catch (e: Exception) {
      null
    }
  }

  private fun countdownStrings(): JSONObject? {
    val json = prefsString(BlockOverlay.BLOCK_SCREEN_STRINGS_KEY) ?: return null
    return try {
      JSONObject(json).optJSONObject("countdown")
    } catch (e: Exception) {
      null
    }
  }

  private fun prefsString(key: String): String? =
    service.applicationContext
      .getSharedPreferences(BlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
      .getString(key, null)

  private fun hasNotificationPermission(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
    return service.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
  }

  private fun ensureChannel(nm: NotificationManager) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    if (nm.getNotificationChannel(CHANNEL_ID) != null) return
    val channel = NotificationChannel(CHANNEL_ID, "Time-limit countdown", NotificationManager.IMPORTANCE_LOW).apply {
      setShowBadge(false)
    }
    nm.createNotificationChannel(channel)
  }

  private fun notificationManager(): NotificationManager? =
    service.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

  companion object {
    private const val CHANNEL_ID = "blockweb_master_countdown"
    private const val NOTIFICATION_ID = 4821
    // Reported non-functional with no device to reproduce on — capture via
    // `adb logcat -s BWM_Countdown` while opening an app covered by an
    // active scheduled profile with time left. Flip back to false once
    // diagnosed.
    private const val DEBUG_LOGGING = true
    private const val TAG = "BWM_Countdown"
  }
}
