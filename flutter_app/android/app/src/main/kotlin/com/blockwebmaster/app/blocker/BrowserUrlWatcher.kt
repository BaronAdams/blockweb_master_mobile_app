package com.blockwebmaster.app.blocker

import android.os.Build
import android.os.Bundle
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Reads the current URL out of a known browser's address bar via the
 * accessibility tree — no VpnService, no packet inspection. This is the
 * same technique most consumer app/site blockers use on Android, and it
 * reuses the AccessibilityService already required for app blocking.
 *
 * This is inherently best-effort: browsers don't expose a stable public
 * API for "give me the current URL," so this depends on view resource-ids
 * that browser vendors can (and do) change between versions. The resource
 * ids below are current as of writing for the listed browsers' Play Store
 * builds; the generic EditText fallback catches most other
 * Chromium-based browsers even when the specific id guess is wrong.
 */
object BrowserUrlWatcher {

  private val URL_BAR_IDS: Map<String, List<String>> = mapOf(
    "com.android.chrome" to listOf("com.android.chrome:id/url_bar"),
    "com.chrome.beta" to listOf("com.chrome.beta:id/url_bar"),
    "com.chrome.dev" to listOf("com.chrome.dev:id/url_bar"),
    "com.chrome.canary" to listOf("com.chrome.canary:id/url_bar"),
    "org.mozilla.firefox" to listOf(
      "org.mozilla.firefox:id/mozac_browser_toolbar_url_view",
      "org.mozilla.firefox:id/url_bar_title"
    ),
    "org.mozilla.firefox_beta" to listOf("org.mozilla.firefox_beta:id/mozac_browser_toolbar_url_view"),
    "com.sec.android.app.sbrowser" to listOf("com.sec.android.app.sbrowser:id/location_bar_edit_text"),
    "com.microsoft.emmx" to listOf("com.microsoft.emmx:id/url_bar"),
    "com.opera.browser" to listOf("com.opera.browser:id/url_field", "com.opera.browser:id/addressbarEdit"),
    "com.opera.mini.native" to listOf("com.opera.mini.native:id/url_field"),
    "com.brave.browser" to listOf("com.brave.browser:id/url_bar"),
    "com.duckduckgo.mobile.android" to listOf("com.duckduckgo.mobile.android:id/omnibarTextInput"),
    "com.vivaldi.browser" to listOf("com.vivaldi.browser:id/url_bar"),
    "com.kiwibrowser.browser" to listOf("com.kiwibrowser.browser:id/url_bar"),
    "com.UCMobile.intl" to listOf("com.UCMobile.intl:id/address_bar_edit_text"),
    "mark.via.gp" to listOf("mark.via.gp:id/address_editor_text"),
  )

  /** Packages known to be browsers — used to decide whether it's worth
   *  walking the accessibility tree at all on a given event. */
  fun isKnownBrowser(packageName: String): Boolean = URL_BAR_IDS.containsKey(packageName)

  fun extractUrl(root: AccessibilityNodeInfo?, packageName: String): String? {
    if (root == null) return null

    for (id in URL_BAR_IDS[packageName].orEmpty()) {
      val nodes = try {
        root.findAccessibilityNodeInfosByViewId(id)
      } catch (e: Exception) {
        null
      }
      val text = nodes?.firstOrNull()?.text?.toString()
      if (!text.isNullOrBlank()) return text
    }

    return findUrlLikeEditText(root, depth = 0)
  }

  /**
   * Best-effort in-place redirect: types the safe URL directly into the
   * browser's own address bar (reusing the same URL_BAR_IDS this object
   * already relies on for URL detection — real, exercised infrastructure,
   * not a fresh guess) and submits it — this replaces the blocked tab's own
   * content instead of opening an extra tab alongside it (see BlockOverlay's
   * redirectBrowserToSafeTab, kept as the fallback when this fails), so no
   * "dead" blocked tab is left sitting in the browser's tab list.
   *
   * Requires ACTION_IME_ENTER (API 30+) to submit the typed URL without a
   * real IME attached — returns false below that SDK level, or if the
   * address bar node can't be found/edited for any reason, so the caller
   * can fall back to the open-a-new-tab approach instead of leaving text
   * typed but never submitted.
   */
  fun navigateInPlace(root: AccessibilityNodeInfo?, packageName: String, url: String): Boolean {
    if (root == null) return false
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false

    val node = findUrlBarNode(root, packageName) ?: return false
    return try {
      val args = Bundle().apply {
        putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, url)
      }
      val textSet = node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
      if (!textSet) return false
      // Unlike ACTION_SET_TEXT (a plain int constant on AccessibilityNodeInfo
      // itself), ACTION_IME_ENTER only exists as a nested AccessibilityAction
      // object (API 30+) — performAction() needs its .id, not the object.
      node.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)
    } catch (e: Exception) {
      false
    } finally {
      try { node.recycle() } catch (e: Exception) {}
    }
  }

  /** Only the known id-based lookup — unlike extractUrl's generic
   *  URL-like-EditText fallback, typing into an arbitrary unrecognized field
   *  that merely looks like it holds a URL is too risky (could be some
   *  unrelated form input), so navigateInPlace only acts on a browser it
   *  actually recognizes. */
  private fun findUrlBarNode(root: AccessibilityNodeInfo, packageName: String): AccessibilityNodeInfo? {
    for (id in URL_BAR_IDS[packageName].orEmpty()) {
      val nodes = try {
        root.findAccessibilityNodeInfosByViewId(id)
      } catch (e: Exception) {
        null
      }
      val node = nodes?.firstOrNull()
      if (node != null) return node
    }
    return null
  }

  /** Generic fallback: search for an EditText-ish node whose text looks
   *  like a URL/domain. Bounded depth to avoid pathological trees. */
  private fun findUrlLikeEditText(node: AccessibilityNodeInfo, depth: Int): String? {
    if (depth > 40) return null

    val className = node.className?.toString().orEmpty()
    if (className.contains("EditText", ignoreCase = true)) {
      val text = node.text?.toString()
      if (looksLikeUrl(text)) return text
    }

    for (i in 0 until node.childCount) {
      val child = node.getChild(i) ?: continue
      val result = findUrlLikeEditText(child, depth + 1)
      if (result != null) return result
    }

    return null
  }

  private fun looksLikeUrl(text: String?): Boolean {
    if (text.isNullOrBlank()) return false
    if (text.contains(' ')) return false
    if (!text.contains('.')) return false
    return text.length in 4..2048
  }

  /** Strips scheme/path/query/port and a leading "www." to get a bare
   *  host for domain-list matching. */
  fun extractHost(url: String): String {
    var host = url.trim()
      .removePrefix("https://")
      .removePrefix("http://")
      .substringBefore('/')
      .substringBefore('?')
      .substringBefore(':')
    if (host.startsWith("www.")) host = host.removePrefix("www.")
    return host.lowercase()
  }

  /** A blocked domain matches itself and any subdomain of it. Runs the
   *  blocked-domain value through the same scheme/path stripping as
   *  extractHost() — defense-in-depth against a stored value that still
   *  has "https://" or a trailing path (e.g. from before the Dart-side
   *  input was normalized, or a future add point that forgets to). */
  fun domainMatches(host: String, blockedDomain: String): Boolean {
    val normalized = extractHost(blockedDomain)
    if (normalized.isEmpty()) return false
    return host == normalized || host.endsWith(".$normalized")
  }
}
