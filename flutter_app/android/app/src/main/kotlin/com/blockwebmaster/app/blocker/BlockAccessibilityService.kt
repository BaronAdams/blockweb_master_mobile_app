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
import android.util.Log
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
  private var lastContentCheckMs: Long = 0L
  private var lastShortsCheckMs: Long = 0L
  // Package we ourselves showed the "shorts" overlay for — lets the shorts
  // check dismiss its own overlay (user left the Reels/Shorts tab) without
  // interfering with the separate flat-app-block show/dismiss flow below.
  private var shortsOverlayActiveFor: String? = null

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
  private lateinit var countdownNotifier: CountdownNotifier

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

  // TYPE_WINDOW_STATE_CHANGED isn't reliably fired by every OEM launcher
  // on every transition — most notably, returning to an already-running
  // app via the Recents/task-switcher card doesn't always produce a fresh
  // event, so tracking/blocking could get stuck reflecting whatever app
  // was last confirmed by an event instead of what's actually on screen.
  // This lightweight poll (just reads the current window's package name,
  // no tree walk) catches that within one interval and also re-checks
  // block status for the CURRENT app on every tick — without it, a
  // scheduled profile crossing its limit only got enforced on the NEXT
  // real app switch, so the user had to leave and re-enter the app
  // before the block screen appeared.
  private val foregroundPollHandler = Handler(Looper.getMainLooper())
  private val foregroundPollRunnable = object : Runnable {
    override fun run() {
      checkForegroundConsistency()
      foregroundPollHandler.postDelayed(this, FOREGROUND_POLL_INTERVAL_MS)
    }
  }

  override fun onServiceConnected() {
    super.onServiceConnected()
    overlay = BlockOverlay(this)
    countdownNotifier = CountdownNotifier(this)
    heartbeatHandler.postDelayed(heartbeatRunnable, HEARTBEAT_INTERVAL_MS)
    foregroundPollHandler.postDelayed(foregroundPollRunnable, FOREGROUND_POLL_INTERVAL_MS)
    registerReceiver(screenReceiver, IntentFilter().apply {
      addAction(Intent.ACTION_SCREEN_OFF)
      addAction(Intent.ACTION_SCREEN_ON)
    })
  }

  override fun onDestroy() {
    heartbeatHandler.removeCallbacks(heartbeatRunnable)
    foregroundPollHandler.removeCallbacks(foregroundPollRunnable)
    try { unregisterReceiver(screenReceiver) } catch (e: Exception) {}
    if (::countdownNotifier.isInitialized) countdownNotifier.dismiss()
    super.onDestroy()
  }

  private fun checkForegroundConsistency() {
    if (!screenOn || !::overlay.isInitialized) return
    val root = rootInActiveWindow ?: return
    val currentPkg = try {
      root.packageName?.toString()
    } finally {
      try { root.recycle() } catch (e: Exception) {}
    }
    if (currentPkg.isNullOrBlank()) return

    if (currentPkg != lastPackageName) {
      // Missed switch event — replay the normal handling so tracking and
      // blocking catch up instead of staying stuck on stale state.
      handleWindowStateChanged(currentPkg)
      return
    }

    if (currentPkg == this.packageName) return

    if (isBlocked(currentPkg)) {
      if (!overlay.isShowingFor(currentPkg)) overlay.show(currentPkg, "app", "")
      if (::countdownNotifier.isInitialized) countdownNotifier.dismiss()
    } else if (!overlay.isShowingFor(currentPkg) && ::countdownNotifier.isInitialized) {
      // Same app as last tick, still not blocked — re-reads the countdown
      // prefs so the notification's remaining-minutes value stays current
      // as Dart pushes fresh syncs, without waiting for a fresh app switch.
      countdownNotifier.update(currentPkg)
    }
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
      shortsOverlayActiveFor = null

      if (packageName == this.packageName) {
        // The user opened BlockWeb Master itself — nothing to block/track.
        overlay.dismiss()
        if (::countdownNotifier.isInitialized) countdownNotifier.dismiss()
        return
      }

      if (isBlocked(packageName)) {
        overlay.show(packageName, "app", "")
        if (::countdownNotifier.isInitialized) countdownNotifier.dismiss()
        return
      } else {
        overlay.dismiss()
        if (::countdownNotifier.isInitialized) countdownNotifier.update(packageName)
      }
    }

    if (packageName != this.packageName && BrowserUrlWatcher.isKnownBrowser(packageName)) {
      checkBrowserUrl(packageName, force = true)
    }

    if (packageName != this.packageName && reelsShortsBlocked() && ShortsFeedDetector.supports(packageName)) {
      checkShortsFeed(packageName, force = true)
    }
  }

  private fun handleContentChanged(packageName: String) {
    // Ignore stale events from a window that isn't actually foreground —
    // AccessibilityEvent.packageName can lag behind the real foreground app.
    if (packageName != lastPackageName) return
    if (packageName == this.packageName) return

    if (BrowserUrlWatcher.isKnownBrowser(packageName)) {
      checkBrowserUrl(packageName, force = false)
    }
    if (reelsShortsBlocked() && ShortsFeedDetector.supports(packageName)) {
      checkShortsFeed(packageName, force = false)
    }
  }

  // ---- Reels/Shorts (experimental, see ShortsFeedDetector) --------------

  private fun checkShortsFeed(packageName: String, force: Boolean) {
    val now = SystemClock.elapsedRealtime()
    if (!force && now - lastShortsCheckMs < SHORTS_CHECK_THROTTLE_MS) return
    lastShortsCheckMs = now

    // See ShortsFeedDetector's DEBUG_LOGGING doc comment — confirms this
    // gating (reelsShortsBlocked + supported package) is even being reached
    // for the app under test, before looking at the detector's own logs.
    Log.d("BWM_Shorts", "checkShortsFeed pkg=$packageName force=$force")

    val root = rootInActiveWindow ?: return
    val showing = try {
      ShortsFeedDetector.isShowingShortsFeed(root)
    } catch (e: Exception) {
      false
    } finally {
      try { root.recycle() } catch (e: Exception) {}
    }

    if (showing) {
      shortsOverlayActiveFor = packageName
      overlay.show(packageName, "shorts", "")
    } else if (shortsOverlayActiveFor == packageName) {
      shortsOverlayActiveFor = null
      overlay.dismiss()
    }
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
    try {
      val url = try {
        BrowserUrlWatcher.extractUrl(root, packageName)
      } catch (e: Exception) {
        null
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
        return
      }

      // Content-based fallback, for adult domains NOT in the curated list
      // — reuses this same `root` (still valid, not yet recycled) rather
      // than fetching it again. Only for a domain that isn't in the safe
      // allowlist, and throttled separately/more heavily than the URL
      // check since walking the tree for text is a lot more work than
      // just finding the address bar.
      if (adultContentBlocked() && !AdultContentDetector.isSafeDomain(host) &&
        now - lastContentCheckMs >= CONTENT_CHECK_THROTTLE_MS
      ) {
        lastContentCheckMs = now
        val bodyText = try {
          AdultContentDetector.extractVisibleText(root)
        } catch (e: Exception) {
          ""
        }
        if (AdultContentDetector.looksAdultByContent(bodyText)) {
          overlay.show(packageName, "adult", host)
        }
      }
    } finally {
      try { root.recycle() } catch (e: Exception) {}
    }
  }

  private fun blockedDomains(): Set<String> = prefs().getStringSet(BLOCKED_DOMAINS_KEY, emptySet()) ?: emptySet()
  private fun blockedKeywords(): Set<String> = prefs().getStringSet(BLOCKED_KEYWORDS_KEY, emptySet()) ?: emptySet()
  private fun adultDomains(): Set<String> = prefs().getStringSet(ADULT_DOMAINS_KEY, emptySet()) ?: emptySet()
  private fun adultContentBlocked(): Boolean = prefs().getBoolean(ADULT_CONTENT_BLOCKED_KEY, false)
  private fun reelsShortsBlocked(): Boolean = prefs().getBoolean(REELS_SHORTS_BLOCKED_KEY, false)

  private fun prefs(): SharedPreferences =
    applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)

  companion object {
    const val PREFS_NAME = "blockweb_master_blocker"
    const val BLOCKED_PACKAGES_KEY = "blocked_packages"
    const val BLOCKED_DOMAINS_KEY = "blocked_domains"
    const val BLOCKED_KEYWORDS_KEY = "blocked_keywords"
    const val ADULT_DOMAINS_KEY = "adult_domains"
    const val ADULT_CONTENT_BLOCKED_KEY = "adult_content_blocked"
    const val REELS_SHORTS_BLOCKED_KEY = "reels_shorts_blocked"
    const val PROFILE_COUNTDOWNS_KEY = "profile_countdowns"
    const val STATS_PREFIX = "usage:"
    const val DAYS_KEY = "usage_days"
    const val HOURLY_PREFIX = "usage_hourly:"
    private const val MAX_SESSION_MS = 20 * 60 * 1000L
    private const val URL_CHECK_THROTTLE_MS = 800L
    private const val CONTENT_CHECK_THROTTLE_MS = 2500L
    private const val SHORTS_CHECK_THROTTLE_MS = 1000L
    private const val HEARTBEAT_INTERVAL_MS = 60 * 1000L
    private const val FOREGROUND_POLL_INTERVAL_MS = 2000L

    fun dateKey(date: Date): String =
      SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date)

    fun todayKey(): String = dateKey(Date())
  }
}
