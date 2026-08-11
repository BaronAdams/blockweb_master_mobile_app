package com.blockwebmaster.app.blocker

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Best-effort in-app Reels/Shorts detector via known accessibility labels
 * on each app's tab bar. EXPERIMENTAL / UNVERIFIED against real devices —
 * this sandbox has no Android device or the target apps installed to
 * inspect their actual current accessibility tree, so the label strings
 * below are a best guess based on general knowledge of each app's English
 * UI. They may be stale, wrong, or miss non-English builds entirely, and
 * app updates can silently change them at any time — expect to verify and
 * adjust these against a real device.
 *
 * A native app exposes far less than a webpage: no URL, no DOM, only
 * whatever text/content-description the app itself assigns to its UI for
 * screen readers — not a documented or stable API. TikTok is deliberately
 * NOT covered here: its entire interface is short-form video, so blocking
 * the whole app (Block Lists > Applications) already achieves the same
 * result with no detection needed — see AppMonitorService's handling of
 * reelsShortsBlocked for TikTok's package names.
 *
 * Confirmed non-functional on a real device (heuristic never fires) — cause
 * unconfirmed since this sandbox can't inspect Instagram/Facebook/YouTube's
 * actual accessibility tree. DEBUG_LOGGING below exists to capture that real
 * tree via `adb logcat -s BWM_Shorts` while opening Reels/Shorts in each app,
 * so the label list (or the isSelected/isChecked assumption entirely — many
 * apps build custom tab bars that don't set standard a11y selection state on
 * their views) can be corrected from real data instead of guesses. Flip back
 * to false once diagnosed — this walks every visible node on every check.
 */
object ShortsFeedDetector {

  private const val DEBUG_LOGGING = true
  private const val TAG = "BWM_Shorts"

  private val LABELS = listOf("reels", "réels", "reel", "shorts", "short")

  /** Packages worth even checking — anything else is skipped outright,
   *  since walking a full accessibility tree on every event is expensive. */
  private val SUPPORTED_PACKAGES = setOf(
    "com.instagram.android",
    "com.facebook.katana", "com.facebook.lite",
    "com.google.android.youtube",
  )

  fun supports(packageName: String): Boolean = packageName in SUPPORTED_PACKAGES

  /** True if a selected/checked tab or heading currently on screen looks
   *  like a Reels/Shorts surface. */
  fun isShowingShortsFeed(root: AccessibilityNodeInfo?): Boolean {
    if (root == null) {
      if (DEBUG_LOGGING) Log.d(TAG, "isShowingShortsFeed: root is null")
      return false
    }
    val result = search(root, depth = 0)
    if (DEBUG_LOGGING) Log.d(TAG, "isShowingShortsFeed: result=$result")
    return result
  }

  private fun search(node: AccessibilityNodeInfo, depth: Int): Boolean {
    if (depth > 40) return false

    val label = (node.contentDescription?.toString() ?: node.text?.toString())?.lowercase()?.trim()

    if (DEBUG_LOGGING && !label.isNullOrBlank() && (node.isSelected || node.isChecked)) {
      // Every SELECTED/CHECKED node with a label, matching or not — this is
      // the ground truth for "what does this app call its active tab", which
      // is exactly what's needed to fix LABELS/the matching logic below.
      Log.d(TAG, "depth=$depth class=${node.className} label=\"$label\" selected=${node.isSelected} checked=${node.isChecked}")
    }

    if (label != null && LABELS.any { label == it || label.contains(it) }) {
      if (DEBUG_LOGGING) {
        Log.d(TAG, "LABEL MATCH depth=$depth class=${node.className} label=\"$label\" selected=${node.isSelected} checked=${node.isChecked}")
      }
      // A label match alone isn't enough — "Reels" appears on the tab
      // button whether or not it's the ACTIVE tab. Require the node to be
      // selected/checked, which is how Android exposes "this is the
      // current tab" to accessibility services.
      if (node.isSelected || node.isChecked) return true
    }

    for (i in 0 until node.childCount) {
      val child = node.getChild(i) ?: continue
      if (search(child, depth + 1)) return true
    }
    return false
  }
}
