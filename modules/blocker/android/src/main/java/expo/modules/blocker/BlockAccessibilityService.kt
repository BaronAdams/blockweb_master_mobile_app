package expo.modules.blocker

import android.accessibilityservice.AccessibilityService
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Detects foreground-app switches (TYPE_WINDOW_STATE_CHANGED) to (1) show a
 * block overlay (BlockOverlay) directly on top of a blocked app or a
 * blocked website/keyword match — no Activity/task switch, the blocked app
 * stays foregrounded — and (2) accumulate real per-app usage minutes, both
 * daily and hourly, into SharedPreferences, which BlockerModule.kt reads
 * back into JS.
 *
 * Website/keyword blocking (TYPE_WINDOW_CONTENT_CHANGED, throttled) reads
 * the address bar of known browsers via the accessibility tree — see
 * BrowserUrlWatcher for the known limitations of that approach.
 */
class BlockAccessibilityService : AccessibilityService() {

  private var lastPackageName: String? = null
  private var lastEventTimeMs: Long = 0L
  private var lastUrlCheckMs: Long = 0L
  private var lastCheckedUrl: String? = null

  private lateinit var overlay: BlockOverlay

  override fun onServiceConnected() {
    super.onServiceConnected()
    overlay = BlockOverlay(this)
  }

  override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    if (event == null || !::overlay.isInitialized) return
    val packageName = event.packageName?.toString() ?: return

    when (event.eventType) {
      AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> handleWindowStateChanged(packageName)
      AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> handleContentChanged(packageName)
    }
  }

  override fun onInterrupt() {}

  // ---- App switch / app blocking / usage tracking ------------------------

  private fun handleWindowStateChanged(packageName: String) {
    if (packageName != lastPackageName) {
      val now = SystemClock.elapsedRealtime()
      recordElapsed(now)
      lastPackageName = packageName
      lastEventTimeMs = now
      lastCheckedUrl = null

      if (packageName == this.packageName) {
        // The user opened BlockWeb Master itself — nothing to block/track.
        overlay.dismiss()
        return
      }

      if (isBlocked(packageName)) {
        overlay.show(packageName, "Application bloquée", "")
        return
      } else {
        overlay.dismiss()
      }
    }

    if (packageName != this.packageName && BrowserUrlWatcher.isKnownBrowser(packageName)) {
      checkBrowserUrl(packageName, force = true)
    }
  }

  private fun handleContentChanged(packageName: String) {
    // Ignore stale events from a window that isn't actually foreground —
    // AccessibilityEvent.packageName can lag behind the real foreground app.
    if (packageName != lastPackageName) return
    if (packageName == this.packageName) return
    if (!BrowserUrlWatcher.isKnownBrowser(packageName)) return
    checkBrowserUrl(packageName, force = false)
  }

  private fun recordElapsed(now: Long) {
    val pkg = lastPackageName ?: return
    if (pkg == this.packageName) return
    if (lastEventTimeMs <= 0L) return
    val elapsedMs = now - lastEventTimeMs
    // Guard against device sleep / service restarts producing bogus jumps.
    if (elapsedMs <= 0L || elapsedMs > MAX_SESSION_MS) return
    addUsage(pkg, elapsedMs / 60000.0)
  }

  private fun addUsage(packageName: String, minutes: Double) {
    val prefs = prefs()
    val editor = prefs.edit()
    val cal = Calendar.getInstance()
    val day = dateKey(cal.time)
    val hour = cal.get(Calendar.HOUR_OF_DAY).toString()

    // Daily total.
    val dailyKey = "$STATS_PREFIX$day:$packageName"
    editor.putFloat(dailyKey, prefs.getFloat(dailyKey, 0f) + minutes.toFloat())
    addToSet(prefs, editor, "$STATS_PREFIX$day:packages", packageName)
    addToSet(prefs, editor, DAYS_KEY, day)

    // Hourly bucket, for the hour-by-hour chart + click-to-filter.
    val hourlyKey = "$HOURLY_PREFIX$day:$hour:$packageName"
    editor.putFloat(hourlyKey, prefs.getFloat(hourlyKey, 0f) + minutes.toFloat())
    addToSet(prefs, editor, "$HOURLY_PREFIX$day:$hour:packages", packageName)
    addToSet(prefs, editor, "$HOURLY_PREFIX$day:hours", hour)

    editor.apply()
  }

  private fun addToSet(prefs: SharedPreferences, editor: SharedPreferences.Editor, key: String, value: String) {
    val set = HashSet(prefs.getStringSet(key, emptySet()) ?: emptySet())
    if (set.add(value)) editor.putStringSet(key, set)
  }

  private fun isBlocked(packageName: String): Boolean {
    if (packageName == this.packageName) return false
    val blocked = prefs().getStringSet(BLOCKED_PACKAGES_KEY, emptySet()) ?: emptySet()
    return blocked.contains(packageName)
  }

  // ---- Website / keyword blocking -----------------------------------------

  private fun checkBrowserUrl(packageName: String, force: Boolean) {
    val now = SystemClock.elapsedRealtime()
    if (!force && now - lastUrlCheckMs < URL_CHECK_THROTTLE_MS) return
    lastUrlCheckMs = now

    val root = rootInActiveWindow ?: return
    val url = try {
      BrowserUrlWatcher.extractUrl(root, packageName)
    } catch (e: Exception) {
      null
    } finally {
      try { root.recycle() } catch (e: Exception) {}
    }
    if (url.isNullOrBlank() || url == lastCheckedUrl) return
    lastCheckedUrl = url

    val host = BrowserUrlWatcher.extractHost(url)
    val blockedDomain = blockedDomains().firstOrNull { BrowserUrlWatcher.domainMatches(host, it) }
    if (blockedDomain != null) {
      overlay.show(packageName, "Site bloqué", blockedDomain)
      return
    }

    val lowerUrl = url.lowercase()
    val blockedKeyword = blockedKeywords().firstOrNull { lowerUrl.contains(it.lowercase()) }
    if (blockedKeyword != null) {
      overlay.show(packageName, "Contenu bloqué", "Mot-clé : $blockedKeyword")
    }
  }

  private fun blockedDomains(): Set<String> = prefs().getStringSet(BLOCKED_DOMAINS_KEY, emptySet()) ?: emptySet()
  private fun blockedKeywords(): Set<String> = prefs().getStringSet(BLOCKED_KEYWORDS_KEY, emptySet()) ?: emptySet()

  private fun prefs(): SharedPreferences =
    applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)

  companion object {
    const val PREFS_NAME = "blockweb_master_blocker"
    const val BLOCKED_PACKAGES_KEY = "blocked_packages"
    const val BLOCKED_DOMAINS_KEY = "blocked_domains"
    const val BLOCKED_KEYWORDS_KEY = "blocked_keywords"
    const val STATS_PREFIX = "usage:"
    const val DAYS_KEY = "usage_days"
    const val HOURLY_PREFIX = "usage_hourly:"
    private const val MAX_SESSION_MS = 20 * 60 * 1000L
    private const val URL_CHECK_THROTTLE_MS = 800L

    fun dateKey(date: Date): String =
      SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date)

    fun todayKey(): String = dateKey(Date())
  }
}
