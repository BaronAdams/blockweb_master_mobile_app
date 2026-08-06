package com.blockwebmaster.app.blocker

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

  /** A blocked domain matches itself and any subdomain of it. */
  fun domainMatches(host: String, blockedDomain: String): Boolean {
    val normalized = blockedDomain.trim().removePrefix("www.").lowercase()
    if (normalized.isEmpty()) return false
    return host == normalized || host.endsWith(".$normalized")
  }
}
