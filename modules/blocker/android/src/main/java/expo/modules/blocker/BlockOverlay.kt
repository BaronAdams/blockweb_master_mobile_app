package expo.modules.blocker

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Draws a full-screen block overlay directly on top of the currently
 * foregrounded (blocked) app — no Activity/task switch, so the blocked app
 * never loses foreground and the user is never bounced into our own app.
 * Requires the "draw over other apps" permission (SYSTEM_ALERT_WINDOW),
 * requested in the JS onboarding flow; falls back to doing nothing if it
 * was never granted (see `canShow`) — deep-linking into our own app was
 * explicitly rejected by the product owner as a fallback, since that's the
 * exact behavior this replaces.
 *
 * Built with plain Android views (no XML, no Compose dependency added just
 * for this) — deliberately minimal, not a port of the JS /blocked screen's
 * full design (fonts, i18n strings, quotes, animations): that would mean
 * duplicating a whole React screen natively. Kept purposely simple so it
 * has the best chance of working correctly on a first, unverified build.
 */
class BlockOverlay(private val service: AccessibilityService) {

  private var overlayView: View? = null
  private var shownForPackage: String? = null
  private var lastTitle: String? = null
  private var lastDetail: String? = null

  fun canShow(): Boolean = Settings.canDrawOverlays(service)

  fun isShowingFor(packageName: String): Boolean = shownForPackage == packageName

  /**
   * @param packageName the app currently on screen (whose icon is shown —
   *   for a site/keyword match this is the browser, not a "blocked app").
   * @param title e.g. "Application bloquée" / "Site bloqué" / "Contenu bloqué".
   * @param detail secondary line — the matched domain/keyword, or blank
   *   for a plain app block.
   */
  fun show(packageName: String, title: String, detail: String) {
    if (isShowingFor(packageName) && lastTitle == title && lastDetail == detail) return
    dismiss()
    if (!canShow()) return

    val windowManager = service.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return
    val appLabel = resolveAppLabel(packageName)
    val appIcon = resolveAppIcon(packageName)

    val view = buildOverlayView(appLabel, appIcon, title, detail)
    val params = WindowManager.LayoutParams(
      WindowManager.LayoutParams.MATCH_PARENT,
      WindowManager.LayoutParams.MATCH_PARENT,
      overlayWindowType(),
      WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
      PixelFormat.TRANSLUCENT
    )

    try {
      windowManager.addView(view, params)
      overlayView = view
      shownForPackage = packageName
      lastTitle = title
      lastDetail = detail
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
    }
    overlayView = null
    shownForPackage = null
    lastTitle = null
    lastDetail = null
  }

  private fun overlayWindowType(): Int =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
      @Suppress("DEPRECATION")
      WindowManager.LayoutParams.TYPE_PHONE
    }

  private fun resolveAppLabel(packageName: String): String = try {
    val pm = service.packageManager
    pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
  } catch (e: Exception) {
    packageName
  }

  private fun resolveAppIcon(packageName: String) = try {
    service.packageManager.getApplicationIcon(packageName)
  } catch (e: PackageManager.NameNotFoundException) {
    null
  }

  private fun buildOverlayView(
    appLabel: String,
    appIcon: android.graphics.drawable.Drawable?,
    title: String,
    detail: String
  ): View {
    val ctx = service

    val root = FrameLayout(ctx).apply {
      setBackgroundColor(Color.parseColor("#F2000000"))
      isClickable = true
      isFocusable = true
    }

    val card = LinearLayout(ctx).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER_HORIZONTAL
      setPadding(dp(28), dp(32), dp(28), dp(28))
      background = GradientDrawable().apply {
        setColor(Color.parseColor("#1A1A1A"))
        setCornerRadius(dp(20).toFloat())
      }
    }
    val cardParams = FrameLayout.LayoutParams(
      dp(300), FrameLayout.LayoutParams.WRAP_CONTENT
    ).apply { gravity = Gravity.CENTER }
    root.addView(card, cardParams)

    if (appIcon != null) {
      val iconWrap = FrameLayout(ctx).apply {
        background = GradientDrawable().apply {
          setColor(Color.parseColor("#2A2A2A"))
          setCornerRadius(dp(18).toFloat())
        }
      }
      val icon = ImageView(ctx).apply { setImageDrawable(appIcon) }
      iconWrap.addView(icon, FrameLayout.LayoutParams(dp(40), dp(40)).apply {
        gravity = Gravity.CENTER
      })
      card.addView(iconWrap, LinearLayout.LayoutParams(dp(72), dp(72)).apply {
        bottomMargin = dp(16)
      })
    }

    card.addView(TextView(ctx).apply {
      text = title
      setTextColor(Color.WHITE)
      textSize = 18f
      gravity = Gravity.CENTER
      setTypeface(typeface, android.graphics.Typeface.BOLD)
    }, LinearLayout.LayoutParams(
      LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { bottomMargin = dp(6) })

    card.addView(TextView(ctx).apply {
      text = appLabel
      setTextColor(Color.parseColor("#A1A1AA"))
      textSize = 14f
      gravity = Gravity.CENTER
    }, LinearLayout.LayoutParams(
      LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { bottomMargin = dp(2) })

    if (detail.isNotBlank()) {
      card.addView(TextView(ctx).apply {
        text = detail
        setTextColor(Color.parseColor("#71717A"))
        textSize = 11f
        gravity = Gravity.CENTER
        setPadding(0, dp(4), 0, 0)
      }, LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
      ).apply { bottomMargin = dp(18) })
    } else {
      card.addView(View(ctx), LinearLayout.LayoutParams(0, dp(14)))
    }

    card.addView(Button(ctx).apply {
      text = "Quitter"
      setTextColor(Color.parseColor("#0A0A0A"))
      setAllCaps(false)
      background = GradientDrawable().apply {
        setColor(Color.parseColor("#F59E0B"))
        setCornerRadius(dp(10).toFloat())
      }
      setOnClickListener {
        dismiss()
        @Suppress("DEPRECATION")
        service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
      }
    }, LinearLayout.LayoutParams(
      LinearLayout.LayoutParams.MATCH_PARENT, dp(46)
    ))

    return root
  }

  private fun dp(value: Int): Int =
    (value * service.resources.displayMetrics.density).toInt()
}
