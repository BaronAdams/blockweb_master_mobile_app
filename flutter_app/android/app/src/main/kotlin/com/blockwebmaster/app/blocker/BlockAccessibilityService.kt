package com.blockwebmaster.app.blocker

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
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
 * daily and hourly, into SharedPreferences, which BlockerBridge.kt reads
 * back to Dart over the MethodChannel.
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

  // TYPE_WINDOW_STATE_CHANGED doesn't fire just because the screen turns
  // off — the foreground app doesn't change, the display just goes dark —
  // so without this, a locked phone with an app still "foreground" kept
  // accruing tracked time via the heartbeat below for as long as it sat
  // locked. screenOn gates recordElapsed() so only time the screen was
  // actually on (i.e. the app's UI was genuinely visible/open) counts.
  private var screenOn = true
  private val screenReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      when (intent.action) {
        Intent.ACTION_SCREEN_OFF -> {
          // Flush whatever's accrued right up to the screen going dark —
          // that dwell time is real — before gating further accrual.
          recordElapsed(SystemClock.elapsedRealtime())
          screenOn = false
        }
        Intent.ACTION_SCREEN_ON -> {
          screenOn = true
          lastEventTimeMs = SystemClock.elapsedRealtime()
        }
      }
    }
  }

  private lateinit var overlay: BlockOverlay

  // Without a periodic flush, dwell time was only ever persisted at the
  // NEXT app switch (recordElapsed is only called from
  // handleWindowStateChanged) — so staying in one app (e.g. scrolling a
  // single feed) for longer than that switch never happened meant that
  // session's whole duration was recorded as zero, and MAX_SESSION_MS
  // capped/discarded whatever finally got measured anyway. Ticking every
  // HEARTBEAT_INTERVAL_MS flushes small, accurate chunks continuously
  // instead, the same way the RN app's native module should have but
  // didn't either.
  private val heartbeatHandler = Handler(Looper.getMainLooper())
  private val heartbeatRunnable = object : Runnable {
    override fun run() {
      val now = SystemClock.elapsedRealtime()
      recordElapsed(now)
      lastEventTimeMs = now
      heartbeatHandler.postDelayed(this, HEARTBEAT_INTERVAL_MS)
    }
  }

  override fun onServiceConnected() {
    super.onServiceConnected()
    overlay = BlockOverlay(this)
    heartbeatHandler.postDelayed(heartbeatRunnable, HEARTBEAT_INTERVAL_MS)
    registerReceiver(screenReceiver, IntentFilter().apply {
      addAction(Intent.ACTION_SCREEN_OFF)
      addAction(Intent.ACTION_SCREEN_ON)
    })
  }

  override fun onDestroy() {
    heartbeatHandler.removeCallbacks(heartbeatRunnable)
    try { unregisterReceiver(screenReceiver) } catch (e: Exception) {}
    super.onDestroy()
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
    // Adding our own overlay window can itself trigger an accessibility
    // event reporting our package as foreground — that's not a real app
    // switch, just the overlay window being added/laid out. Without this
    // guard, the block below would read it as "user opened BlockWeb
    // Master" and call overlay.dismiss() on the overlay we just showed,
    // producing a blink where the blocked app is briefly interactable.
    if (packageName == this.packageName && overlay.isActive()) return

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
        overlay.show(packageName, "app", "")
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
    if (!screenOn) return
    val pkg = lastPackageName ?: return
    if (pkg == this.packageName) return
    // Don't attribute dwell time to the launcher/systemui/keyboard — they
    // foreground constantly as a side effect of navigation, not because
    // the user opened them (see TrackablePackages for why).
    if (!TrackablePackages.isTrackable(applicationContext, pkg)) return
    if (lastEventTimeMs <= 0L) return
    // Capped rather than discarded: a session longer than MAX_SESSION_MS
    // (e.g. the device slept for hours with this app foregrounded) still
    // credits a sane amount instead of recording zero for the whole thing.
    // With the heartbeat now flushing every HEARTBEAT_INTERVAL_MS, this
    // cap is mostly a safety net for sleep/service-restart gaps rather
    // than the routine path it used to be.
    val elapsedMs = (now - lastEventTimeMs).coerceIn(0L, MAX_SESSION_MS)
    if (elapsedMs <= 0L) return
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

    // Checked before the generic domain list so a match gets the "adult"
    // overlay copy/badge instead of the generic "site" one.
    val adultDomain = adultDomains().firstOrNull { BrowserUrlWatcher.domainMatches(host, it) }
    if (adultDomain != null) {
      overlay.show(packageName, "adult", adultDomain)
      return
    }

    val blockedDomain = blockedDomains().firstOrNull { BrowserUrlWatcher.domainMatches(host, it) }
    if (blockedDomain != null) {
      overlay.show(packageName, "site", blockedDomain)
      return
    }

    val lowerUrl = url.lowercase()
    val blockedKeyword = blockedKeywords().firstOrNull { lowerUrl.contains(it.lowercase()) }
    if (blockedKeyword != null) {
      overlay.show(packageName, "keyword", blockedKeyword)
    }
  }

  private fun blockedDomains(): Set<String> = prefs().getStringSet(BLOCKED_DOMAINS_KEY, emptySet()) ?: emptySet()
  private fun blockedKeywords(): Set<String> = prefs().getStringSet(BLOCKED_KEYWORDS_KEY, emptySet()) ?: emptySet()
  private fun adultDomains(): Set<String> = prefs().getStringSet(ADULT_DOMAINS_KEY, emptySet()) ?: emptySet()

  private fun prefs(): SharedPreferences =
    applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)

  companion object {
    const val PREFS_NAME = "blockweb_master_blocker"
    const val BLOCKED_PACKAGES_KEY = "blocked_packages"
    const val BLOCKED_DOMAINS_KEY = "blocked_domains"
    const val BLOCKED_KEYWORDS_KEY = "blocked_keywords"
    const val ADULT_DOMAINS_KEY = "adult_domains"
    const val STATS_PREFIX = "usage:"
    const val DAYS_KEY = "usage_days"
    const val HOURLY_PREFIX = "usage_hourly:"
    private const val MAX_SESSION_MS = 20 * 60 * 1000L
    private const val URL_CHECK_THROTTLE_MS = 800L
    private const val HEARTBEAT_INTERVAL_MS = 60 * 1000L

    fun dateKey(date: Date): String =
      SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date)

    fun todayKey(): String = dateKey(Date())
  }
}
