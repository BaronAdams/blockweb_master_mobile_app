package com.blockwebmaster.app.blocker

import android.content.Context
import android.content.Intent
import android.view.inputmethod.InputMethodManager

/**
 * Decides whether a foreground package is a real, user-facing app worth
 * tracking/attributing usage minutes to.
 *
 * Two layers:
 *  1. Positive check — the package must have a launcher-visible activity
 *     (ACTION_MAIN + CATEGORY_LAUNCHER, the same query BlockerBridge.kt's
 *     getInstalledApps uses for the block-list picker). Without this,
 *     background services, permission/autofill dialogs, OEM system
 *     components, push-notification helper activities etc. that briefly
 *     grab a foreground window — but were never actually opened by the
 *     user — got attributed real dwell time and showed up in Analytics
 *     history as a bare "com.xxx.xxxx" the user never launched.
 *  2. Negative check — excludes OS chrome that IS launcher-visible but
 *     still isn't something the user deliberately "opened" this instant:
 *     - the home-screen launcher itself (e.g. XOS, One UI Home, Nova…) —
 *       foregrounds constantly just by going back to the home screen
 *     - com.android.systemui — notification shade, quick settings, recent
 *       apps overview, lock screen, volume panel
 *     - the active keyboard (IME) — many (e.g. Gboard) have their own
 *       launcher-visible settings activity, so the positive check alone
 *       wouldn't exclude them
 *
 * Both launcher/IME and the launchable-app set are resolved dynamically
 * instead of hardcoded, so this works across OEM launchers/keyboards
 * rather than just the ones seen during testing.
 */
object TrackablePackages {
  private var cachedExcluded: Set<String>? = null
  private var cachedLaunchable: Set<String>? = null

  fun isTrackable(context: Context, packageName: String): Boolean {
    if (packageName == "com.android.systemui") return false
    if (excludedPackages(context).contains(packageName)) return false

    val launchable = launchablePackages(context)
    // Empty only means the query itself failed (queryIntentActivities on
    // CATEGORY_LAUNCHER essentially never fails in practice, since the
    // system guarantees at least the home launcher there) — fail open in
    // that case rather than silently disabling all tracking.
    if (launchable.isEmpty()) return true
    return launchable.contains(packageName)
  }

  private fun launchablePackages(context: Context): Set<String> {
    cachedLaunchable?.let { return it }

    val result = HashSet<String>()
    try {
      val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
      context.packageManager.queryIntentActivities(intent, 0).forEach {
        result.add(it.activityInfo.packageName)
      }
    } catch (e: Exception) {
      // Leave `result` empty — isTrackable() treats that as "query
      // failed" and falls back to the old exclusion-only behavior.
    }

    cachedLaunchable = result
    return result
  }

  private fun excludedPackages(context: Context): Set<String> {
    cachedExcluded?.let { return it }

    val result = HashSet<String>()

    try {
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      context.packageManager.queryIntentActivities(homeIntent, 0).forEach {
        result.add(it.activityInfo.packageName)
      }
    } catch (e: Exception) {
      // Best-effort — if this fails, the launcher just won't be excluded.
    }

    try {
      val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
      imm?.inputMethodList?.forEach { result.add(it.packageName) }
    } catch (e: Exception) {
      // Best-effort, see above.
    }

    cachedExcluded = result
    return result
  }
}
