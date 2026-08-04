package expo.modules.blocker

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Detects foreground-app switches (TYPE_WINDOW_STATE_CHANGED) to (1) enforce
 * blocking by launching the JS /blocked screen via deep link when the app
 * that just came to the foreground is on the blocklist, and (2) accumulate
 * real per-app usage minutes into SharedPreferences, which BlockerModule.kt
 * reads back into JS. There is no VPN/DNS layer here — this only covers
 * app-level blocking, not websites/keywords (deferred, needs VpnService).
 */
class BlockAccessibilityService : AccessibilityService() {

  private var lastPackageName: String? = null
  private var lastEventTimeMs: Long = 0L

  override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
    val packageName = event.packageName?.toString() ?: return
    if (packageName == this.packageName) return
    if (packageName == lastPackageName) return

    val now = SystemClock.elapsedRealtime()
    recordElapsed(now)
    lastPackageName = packageName
    lastEventTimeMs = now

    if (isBlocked(packageName)) {
      launchBlockedScreen(packageName)
    }
  }

  override fun onInterrupt() {}

  private fun recordElapsed(now: Long) {
    val pkg = lastPackageName ?: return
    if (lastEventTimeMs <= 0L) return
    val elapsedMs = now - lastEventTimeMs
    // Guard against device sleep / service restarts producing bogus jumps.
    if (elapsedMs <= 0L || elapsedMs > MAX_SESSION_MS) return
    addUsage(pkg, elapsedMs / 60000.0)
  }

  private fun addUsage(packageName: String, minutes: Double) {
    val prefs = prefs()
    val day = todayKey()
    val usageKey = "$STATS_PREFIX$day:$packageName"
    val current = prefs.getFloat(usageKey, 0f)
    val editor = prefs.edit()
    editor.putFloat(usageKey, current + minutes.toFloat())

    val packagesKey = "$STATS_PREFIX$day:packages"
    val packages = HashSet(prefs.getStringSet(packagesKey, emptySet()) ?: emptySet())
    if (packages.add(packageName)) editor.putStringSet(packagesKey, packages)

    val days = HashSet(prefs.getStringSet(DAYS_KEY, emptySet()) ?: emptySet())
    if (days.add(day)) editor.putStringSet(DAYS_KEY, days)

    editor.apply()
  }

  private fun isBlocked(packageName: String): Boolean {
    val blocked = prefs().getStringSet(BLOCKED_PACKAGES_KEY, emptySet()) ?: emptySet()
    return blocked.contains(packageName)
  }

  private fun launchBlockedScreen(packageName: String) {
    try {
      val label = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
      } catch (e: Exception) {
        packageName
      }
      val uri = Uri.parse("blockweb-master-mobile-app://blocked")
        .buildUpon()
        .appendQueryParameter("reason", "app")
        .appendQueryParameter("value", label)
        .build()
      val intent = Intent(Intent.ACTION_VIEW, uri).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
      }
      startActivity(intent)
    } catch (e: Exception) {
      // Never let a broken launch crash the accessibility service — that
      // would silently kill blocking for every app, not just this one.
    }
  }

  private fun prefs(): SharedPreferences =
    applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)

  companion object {
    const val PREFS_NAME = "blockweb_master_blocker"
    const val BLOCKED_PACKAGES_KEY = "blocked_packages"
    const val STATS_PREFIX = "usage:"
    const val DAYS_KEY = "usage_days"
    private const val MAX_SESSION_MS = 20 * 60 * 1000L

    fun todayKey(): String =
      SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
  }
}
