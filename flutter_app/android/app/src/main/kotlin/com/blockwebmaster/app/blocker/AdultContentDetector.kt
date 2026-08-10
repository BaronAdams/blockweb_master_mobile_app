package com.blockwebmaster.app.blocker

import android.view.accessibility.AccessibilityNodeInfo

/**
 * Best-effort adult-content detection from a webpage's VISIBLE on-screen
 * text, read via the accessibility tree — not the DOM/HTML source, not
 * <meta>/og: tags, not <title> (none of those are exposed as accessibility
 * nodes, only what's rendered as visible text), just whatever text is
 * currently on screen and would be read aloud by a screen reader. A
 * narrower signal set than the chrome extension's
 * content/adultContentScript.ts (which reads the real DOM + meta tags),
 * used here only as a fallback for domains NOT already in
 * toggle_block_lists.dart's curated adult-domain list.
 */
object AdultContentDetector {

  // Same signal words as content/adultContentScript.ts's ADULT_SIGNALS.
  private val ADULT_SIGNALS = listOf(
    "porn", "xxx", "xvideos", "xhamster", "pornhub", "redtube", "youporn",
    "brazzers", "onlyfans", "chaturbate", "livejasmin", "stripchat",
    "sexe", "sexo", "porno", "erotic", "hentai", "milf", "nude",
    "naked", "nsfw", "adult content", "contenu adulte", "18+",
    "adult entertainment", "sex videos", "free porn"
  )

  // Same allowlist as content/adultContentScript.ts's SAFE_DOMAINS — a
  // domain here is never flagged by content analysis, no matter how many
  // signal words happen to appear on one of its pages (news articles,
  // discussions, docs, etc. legitimately mention some of these words).
  private val SAFE_DOMAINS = listOf(
    "github.com", "gitlab.com", "bitbucket.org", "stackoverflow.com",
    "notion.so", "figma.com", "linear.app", "trello.com", "asana.com",
    "jira.atlassian.com", "confluence.atlassian.com", "clickup.com",
    "monday.com", "airtable.com", "miro.com", "loom.com",
    "docs.google.com", "sheets.google.com", "slides.google.com",
    "drive.google.com", "calendar.google.com", "gmail.com",
    "outlook.com", "office.com", "teams.microsoft.com", "slack.com",
    "zoom.us", "meet.google.com", "vercel.com", "netlify.com",
    "supabase.com", "firebase.google.com", "aws.amazon.com",
    "vscode.dev", "codepen.io", "codesandbox.io", "replit.com",
    "leetcode.com", "hackerrank.com", "freecodecamp.org",
    "developer.mozilla.org", "npmjs.com", "pypi.org",
    "anthropic.com", "openai.com", "huggingface.co",
    "google.com", "bing.com", "duckduckgo.com", "yahoo.com",
    "wikipedia.org", "wikimedia.org", "wiktionary.org",
    "youtube.com", "netflix.com", "spotify.com", "deezer.com",
    "twitch.tv", "vimeo.com", "soundcloud.com",
    "twitter.com", "x.com", "facebook.com", "instagram.com",
    "linkedin.com", "reddit.com", "discord.com", "telegram.org",
    "tiktok.com", "pinterest.com", "snapchat.com",
    "bbc.com", "cnn.com", "lemonde.fr", "lefigaro.fr", "liberation.fr",
    "nytimes.com", "theguardian.com", "reuters.com", "apnews.com",
    "amazon.com", "amazon.fr", "ebay.com", "paypal.com",
    "stripe.com", "shopify.com"
  )

  fun isSafeDomain(host: String): Boolean {
    val h = host.removePrefix("www.").lowercase()
    return SAFE_DOMAINS.any { h == it || h.endsWith(".$it") }
  }

  /** Extracts up to maxChars of visible text from the tree, matching the
   *  extension's `document.body.innerText.slice(0, 800)`. Bounded depth
   *  guards against pathological trees. */
  fun extractVisibleText(root: AccessibilityNodeInfo, maxChars: Int = 800): String {
    val sb = StringBuilder()
    collect(root, sb, maxChars, depth = 0)
    return sb.toString()
  }

  private fun collect(node: AccessibilityNodeInfo, sb: StringBuilder, maxChars: Int, depth: Int) {
    if (sb.length >= maxChars || depth > 60) return
    val text = node.text?.toString()
    if (!text.isNullOrBlank()) sb.append(text).append(' ')

    for (i in 0 until node.childCount) {
      if (sb.length >= maxChars) return
      val child = node.getChild(i) ?: continue
      collect(child, sb, maxChars, depth + 1)
    }
  }

  /** Requires 2+ distinct signal-word hits to reduce false positives — a
   *  single stray match (a headline mentioning a word out of context)
   *  isn't enough, mirroring the extension's own confidence threshold. */
  fun looksAdultByContent(bodyText: String): Boolean {
    if (bodyText.isBlank()) return false
    val normalized = bodyText.lowercase()
    val hits = ADULT_SIGNALS.count { normalized.contains(it) }
    return hits >= 2
  }
}
