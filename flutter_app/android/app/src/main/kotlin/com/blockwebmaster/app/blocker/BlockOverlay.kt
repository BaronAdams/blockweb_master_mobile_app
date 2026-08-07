package com.blockwebmaster.app.blocker

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.view.WindowManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import com.blockwebmaster.app.R
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

/**
 * Draws a full-screen block overlay directly on top of the currently
 * foregrounded (blocked) app — no Activity/task switch, so the blocked app
 * never loses foreground and the user is never bounced into our own app.
 * Requires the "draw over other apps" permission (SYSTEM_ALERT_WINDOW).
 *
 * Rendered as a WebView loading an inline HTML/CSS document that mirrors
 * the browser extension's /blocked page (App.tsx + App.css) exactly — same
 * layout, same @keyframes (float/pulse-glow/bounce/pulse), same detail-card
 * structure — rather than a hand-rolled native UI. All strings come from a
 * JSON bundle Dart pushes via BlockerBridge's "setBlockScreenStrings"
 * method channel call (see lib/l10n/i18n_service.dart on the Dart side —
 * the actual strings-bundle builder gets ported alongside the screens in
 * phase 2); native only ever substitutes the literal "{{value}}" token, it
 * has no i18n of its own.
 *
 * Direct port of modules/blocker/android/.../BlockOverlay.kt from the RN
 * app, with one behavioral change: openManageRules() now just brings this
 * app's own launcher activity to the foreground instead of a deep link,
 * since the Flutter app's routing/deep-linking isn't wired up yet
 * (phase 2) — revisit once go_router has a real "open blocklists" route.
 */
class BlockOverlay(private val service: AccessibilityService) {

  private var overlayView: WebView? = null
  private var shownForPackage: String? = null
  private var lastReasonKey: String? = null
  private var lastValue: String? = null

  /** Cached header logo (res/drawable-nodpi/logo_shield.png, same gold
   *  shield mark as AppHeader/app icon) — decoded once since it never
   *  changes, avoiding a bitmap decode + base64 encode on every show(). */
  private val logoDataUri: String? by lazy { resolveLogoDataUri() }

  fun canShow(): Boolean = Settings.canDrawOverlays(service)

  fun isShowingFor(packageName: String): Boolean = shownForPackage == packageName

  /** Whether an overlay window is currently on screen — used by the
   *  service to ignore the accessibility event that adding this very
   *  window can itself trigger (see BlockAccessibilityService). */
  fun isActive(): Boolean = overlayView != null

  /**
   * @param packageName the app currently on screen (whose icon is shown for
   *   reasonKey == "app"; the browser, for a site/keyword/adult match).
   * @param reasonKey one of "app" | "site" | "keyword" | "adult" | "daily" |
   *   "hourly" | "weekly" | "interval" — selects which entry of the pushed
   *   strings bundle to render, matching the extension's per-reason variants.
   * @param value the app label / domain / keyword / profile name to
   *   substitute for "{{value}}" in the description and show in the detail
   *   row — ignored for reasonKey == "app" (resolved from packageName instead).
   */
  fun show(packageName: String, reasonKey: String, value: String) {
    if (isShowingFor(packageName) && lastReasonKey == reasonKey && lastValue == value) return
    dismiss()
    if (!canShow()) return

    val windowManager = service.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return

    val webView = try {
      WebView(service)
    } catch (e: Exception) {
      return
    }
    webView.settings.javaScriptEnabled = false
    webView.setBackgroundColor(Color.parseColor("#030303"))
    webView.webViewClient = object : WebViewClient() {
      override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean =
        handleAction(request?.url)

      @Suppress("DEPRECATION")
      override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean =
        handleAction(url?.let { Uri.parse(it) })
    }

    val html = buildHtml(packageName, reasonKey, value)
    webView.loadDataWithBaseURL(null, html, "text/html", "utf-8", null)

    val params = WindowManager.LayoutParams(
      WindowManager.LayoutParams.MATCH_PARENT,
      WindowManager.LayoutParams.MATCH_PARENT,
      overlayWindowType(),
      WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
      PixelFormat.TRANSLUCENT
    )

    try {
      windowManager.addView(webView, params)
      overlayView = webView
      shownForPackage = packageName
      lastReasonKey = reasonKey
      lastValue = value
    } catch (e: Exception) {
      // Some OEMs restrict overlay windows further than the permission
      // check alone predicts — never let this crash the service.
    }
  }

  fun dismiss() {
    val view = overlayView
    if (view != null) {
      val windowManager = service.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
      try {
        windowManager?.removeView(view)
      } catch (e: Exception) {
        // View already detached — ignore.
      }
      try {
        view.destroy()
      } catch (e: Exception) {}
    }
    overlayView = null
    shownForPackage = null
    lastReasonKey = null
    lastValue = null
  }

  // ---- Action buttons (intercepted custom-scheme navigations) -----------

  private fun handleAction(uri: Uri?): Boolean {
    return when (uri?.host) {
      "quit" -> {
        dismiss()
        @Suppress("DEPRECATION")
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
        true
      }
      "manage" -> {
        dismiss()
        openManageRules()
        true
      }
      else -> false
    }
  }

  private fun openManageRules() {
    try {
      val launchIntent = service.packageManager.getLaunchIntentForPackage(service.packageName)
      launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      launchIntent?.let { service.startActivity(it) }
    } catch (e: Exception) {}
  }

  private fun overlayWindowType(): Int =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
      @Suppress("DEPRECATION")
      WindowManager.LayoutParams.TYPE_PHONE
    }

  // ---- App icon/label resolution -----------------------------------------

  private fun resolveAppLabel(packageName: String): String = try {
    val pm = service.packageManager
    pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
  } catch (e: Exception) {
    packageName
  }

  private fun resolveAppIconDataUri(packageName: String): String? {
    val drawable = try {
      service.packageManager.getApplicationIcon(packageName)
    } catch (e: PackageManager.NameNotFoundException) {
      return null
    }
    val bitmap = try {
      drawableToBitmap(drawable)
    } catch (e: Exception) {
      return null
    }
    val stream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
    val base64 = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    return "data:image/png;base64,$base64"
  }

  private fun resolveLogoDataUri(): String? {
    val bitmap = try {
      BitmapFactory.decodeResource(service.resources, R.drawable.logo_shield)
    } catch (e: Exception) {
      null
    } ?: return null
    val stream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
    val base64 = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    return "data:image/png;base64,$base64"
  }

  private fun drawableToBitmap(drawable: Drawable): Bitmap {
    if (drawable is BitmapDrawable && drawable.bitmap != null) return drawable.bitmap
    val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
    val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    drawable.setBounds(0, 0, canvas.width, canvas.height)
    drawable.draw(canvas)
    return bitmap
  }

  // ---- Strings bundle (pushed from Dart via BlockerBridge) ---------------

  private fun strings(): JSONObject {
    val prefs = service.applicationContext.getSharedPreferences(
      BlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE
    )
    val json = prefs.getString(BLOCK_SCREEN_STRINGS_KEY, null) ?: return JSONObject()
    return try {
      JSONObject(json)
    } catch (e: Exception) {
      JSONObject()
    }
  }

  private fun displayValue(reasonKey: String, packageName: String, value: String): String =
    if (reasonKey == "app") resolveAppLabel(packageName) else value

  private fun pickQuote(quotes: JSONArray?): Pair<String, String> {
    if (quotes == null || quotes.length() == 0) return Pair("", "")
    val obj = quotes.optJSONObject((0 until quotes.length()).random()) ?: return Pair("", "")
    return Pair(obj.optString("text", ""), obj.optString("author", ""))
  }

  private fun esc(s: String): String = s
    .replace("&", "&amp;")
    .replace("<", "&lt;")
    .replace(">", "&gt;")
    .replace("\"", "&quot;")

  // ---- Per-reason colors + icons -------------------------------------------

  /** (icon color, glow color) — the only two things tinted by reason; the
   *  detail/reason icon boxes are always neutral gray. */
  private fun colorsFor(reasonKey: String): Pair<String, String> = when (reasonKey) {
    "daily" -> Pair("#fbbf24", "#f59e0b")
    "hourly" -> Pair("#60a5fa", "#3b82f6")
    "weekly" -> Pair("#a78bfa", "#8b5cf6")
    "app" -> Pair("#fbbf24", "#f59e0b")
    else -> Pair("#fb7185", "#f43f5e") // site, keyword, adult, interval
  }

  private fun floatingIconSvg(reasonKey: String, color: String): String = when (reasonKey) {
    "adult" -> svg(color, """<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="M12 8v4"/><path d="M12 16h.01"/>""")
    "daily" -> svg(color, """<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/>""")
    "hourly" -> svg(color, """<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>""")
    "weekly" -> svg(color, """<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/>""")
    "interval" -> svg(color, """<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>""")
    else -> svg(color, """<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>""") // site, keyword
  }

  private fun detailIconSvg(reasonKey: String): String = when (reasonKey) {
    "app" -> svg(NEUTRAL, """<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/>""")
    "keyword" -> svg(NEUTRAL, """<path d="M17 6.1H3"/><path d="M21 12.1H3"/><path d="M15.1 18H3"/>""")
    "adult" -> svg(NEUTRAL, """<circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/>""")
    "daily", "hourly", "weekly", "interval" -> svg(NEUTRAL, """<line x1="10" x2="14" y1="2" y2="2"/><line x1="12" x2="15" y1="14" y2="11"/><circle cx="12" cy="14" r="8"/>""")
    else -> svg(NEUTRAL, """<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>""") // site
  }

  private fun svg(color: String, paths: String): String =
    """<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">$paths</svg>"""

  private val iconHourglass = svg(NEUTRAL, """<path d="M5 22h14"/><path d="M5 2h14"/><path d="M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"/><path d="M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"/>""")
  private val iconX = svg("rgba(244,63,94,0.8)", """<circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/>""")
  private val iconArrowLeft = svg("#000000", """<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>""")
  private val iconSettings = svg(NEUTRAL, """<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>""")

  // ---- HTML document, mirroring the extension's blocked/App.tsx + App.css --

  private fun buildHtml(packageName: String, reasonKey: String, value: String): String {
    val bundle = strings()
    val common = bundle.optJSONObject("common") ?: JSONObject()
    val reasonData = bundle.optJSONObject("reasons")?.optJSONObject(reasonKey) ?: JSONObject()

    val resolvedValue = displayValue(reasonKey, packageName, value)
    val title = reasonData.optString("title", "")
    val desc = reasonData.optString("desc", "").replace("{{value}}", resolvedValue)
    val badge = reasonData.optString("badge", "")
    val detailLabel = reasonData.optString("detailLabel", "")
    val reasonLabel = reasonData.optString("reasonLabel", "")
    val quote = pickQuote(bundle.optJSONArray("quotes"))

    val (iconColor, glowColor) = colorsFor(reasonKey)
    val logoImgHtml = if (logoDataUri != null) """<img src="$logoDataUri" />""" else ""
    val appIconDataUri = if (reasonKey == "app") resolveAppIconDataUri(packageName) else null
    val floatingIconHtml = if (appIconDataUri != null) {
      """<img src="$appIconDataUri" style="width:48px;height:48px;border-radius:12px;object-fit:cover;" />"""
    } else {
      floatingIconSvg(reasonKey, iconColor)
    }
    val mono = reasonKey == "site" || reasonKey == "keyword" || reasonKey == "adult"

    val detailRowHtml = if (resolvedValue.isNotBlank()) """
      <div class="row">
        <div class="row-left">
          <div class="icon-box">${detailIconSvg(reasonKey)}</div>
          <div>
            <p class="row-label">${esc(detailLabel)}</p>
            <p class="row-value${if (mono) " mono" else ""}">${esc(resolvedValue)}</p>
          </div>
        </div>
        $iconX
      </div>
      <div class="divider"></div>
    """ else ""

    return """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
<style>
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  html, body { margin: 0; padding: 0; background: #030303; color: #e5e5e5; font-family: sans-serif; }
  .grid-bg { position: fixed; inset: 0; background-size: 50px 50px;
    background-image: linear-gradient(to right, rgba(255,255,255,0.03) 1px, transparent 1px),
      linear-gradient(to bottom, rgba(255,255,255,0.03) 1px, transparent 1px); }
  .page { position: relative; min-height: 100vh; display: flex; flex-direction: column;
    align-items: center; justify-content: center; padding: 24px; }
  .logo-row { position: absolute; top: 24px; left: 0; width: 100%; display: flex;
    justify-content: center; align-items: center; gap: 10px; opacity: 0.85; }
  .logo-box { width: 34px; height: 34px; border-radius: 9px; background: rgba(245,158,11,0.1);
    border: 1px solid rgba(245,158,11,0.25); display: flex; align-items: center; justify-content: center; }
  .logo-box img { width: 20px; height: 20px; object-fit: contain; }
  .logo-text { font-size: 14px; font-weight: 500; color: #fff; }
  main { position: relative; z-index: 10; width: 100%; max-width: 460px; margin-top: 60px;
    display: flex; flex-direction: column; align-items: center; text-align: center; }
  .icon-wrap { position: relative; margin-bottom: 36px; width: 96px; height: 96px;
    display: flex; align-items: center; justify-content: center; }
  .glow { position: absolute; width: 128px; height: 128px; border-radius: 9999px;
    filter: blur(60px); opacity: 0.2; background: $glowColor; animation: pulse-glow 4s cubic-bezier(.4,0,.6,1) infinite; }
  .icon-circle { position: relative; width: 96px; height: 96px; border-radius: 9999px;
    border: 1px solid rgba(255,255,255,0.1); background: rgba(255,255,255,0.05);
    display: flex; align-items: center; justify-content: center; animation: float 6s ease-in-out infinite; }
  .badge { position: absolute; right: -14px; top: 0; background: #18181b; border: 1px solid #27272a;
    padding: 6px 12px; border-radius: 9999px; display: flex; align-items: center; gap: 8px;
    animation: bounce 5s infinite; white-space: nowrap; }
  .badge .dot { width: 6px; height: 6px; border-radius: 9999px; background: #f43f5e;
    animation: pulse 2s cubic-bezier(.4,0,.6,1) infinite; }
  .badge span { font-size: 11px; color: #a1a1aa; font-weight: 500; }
  h1 { font-size: 25px; font-weight: 500; color: #fff; margin: 0 0 14px; letter-spacing: -0.01em; }
  .desc { color: #a1a1aa; font-size: 15px; line-height: 1.6; margin: 0 0 36px; font-weight: 300; max-width: 380px; }
  .card { width: 100%; background: rgba(24,24,27,0.5); border: 1px solid rgba(255,255,255,0.05);
    border-radius: 12px; overflow: hidden; margin-bottom: 36px; text-align: left; }
  .card-header { border-bottom: 1px solid rgba(255,255,255,0.05); padding: 12px 18px;
    background: rgba(255,255,255,0.02); font-size: 11px; font-weight: 500; color: #71717a;
    text-transform: uppercase; letter-spacing: 0.05em; }
  .card-body { padding: 18px; }
  .row { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; }
  .row-left { display: flex; align-items: center; gap: 12px; }
  .icon-box { padding: 8px; border-radius: 8px; background: rgba(39,39,42,0.5); color: $NEUTRAL;
    border: 1px solid rgba(255,255,255,0.05); display: flex; flex-shrink: 0; }
  .row-label { font-size: 11px; color: #71717a; margin: 0 0 2px; }
  .row-value { font-size: 14px; color: #e4e4e7; font-weight: 500; margin: 0; }
  .row-value.mono { font-family: monospace; letter-spacing: -0.02em; }
  .divider { width: 100%; height: 1px; background: rgba(255,255,255,0.05); margin-bottom: 14px; }
  .actions { display: flex; flex-direction: column; gap: 14px; width: 100%; }
  .btn { display: flex; align-items: center; justify-content: center; gap: 8px; padding: 13px 24px;
    border-radius: 8px; font-size: 14px; font-weight: 500; text-decoration: none; }
  .btn-primary { background: #fff; color: #000; box-shadow: 0 0 20px rgba(255,255,255,0.1); }
  .btn-outline { background: transparent; border: 1px solid #27272a; color: #a1a1aa; }
  .quote { margin-top: 48px; padding-bottom: 24px; }
  .quote-text { font-size: 14px; font-style: italic; color: #71717a; font-family: serif; margin: 0; }
  .quote-author { font-size: 12px; color: #52525b; margin: 8px 0 0; }
  @keyframes float { 0% { transform: translateY(0); } 50% { transform: translateY(-12px); } 100% { transform: translateY(0); } }
  @keyframes pulse-glow { 0%, 100% { opacity: 0.1; transform: scale(0.95); } 50% { opacity: 0.25; transform: scale(1.1); } }
  @keyframes bounce { 0%, 100% { transform: translateY(-25%); animation-timing-function: cubic-bezier(.8,0,1,1); } 50% { transform: none; animation-timing-function: cubic-bezier(0,0,.2,1); } }
  @keyframes pulse { 50% { opacity: 0.5; } }
</style>
</head>
<body>
  <div class="grid-bg"></div>
  <div class="page">
    <div class="logo-row">
      <div class="logo-box">$logoImgHtml</div>
      <span class="logo-text">BlockWeb Master</span>
    </div>
    <main>
      <div class="icon-wrap">
        <div class="glow"></div>
        <div class="icon-circle">$floatingIconHtml</div>
        <div class="badge"><span class="dot"></span><span>${esc(badge)}</span></div>
      </div>
      <h1>${esc(title)}</h1>
      <p class="desc">${esc(desc)}</p>
      <div class="card">
        <div class="card-header">${esc(common.optString("securityDetails", ""))}</div>
        <div class="card-body">
          $detailRowHtml
          <div class="row">
            <div class="row-left">
              <div class="icon-box">$iconHourglass</div>
              <div>
                <p class="row-label">${esc(common.optString("blockingReason", ""))}</p>
                <p class="row-value">${esc(reasonLabel)}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="actions">
        <a href="action://quit" class="btn btn-primary">$iconArrowLeft ${esc(common.optString("goBack", ""))}</a>
        <a href="action://manage" class="btn btn-outline">$iconSettings ${esc(common.optString("manageRules", ""))}</a>
      </div>
      <div class="quote">
        <p class="quote-text">&quot;${esc(quote.first)}&quot;</p>
        ${if (quote.second.isNotBlank() && !quote.second.contains("quote")) "<p class=\"quote-author\">— ${esc(quote.second)}</p>" else ""}
      </div>
    </main>
  </div>
</body>
</html>
    """.trimIndent()
  }

  companion object {
    const val BLOCK_SCREEN_STRINGS_KEY = "block_screen_strings"
    private const val NEUTRAL = "#a1a1aa"
  }
}
