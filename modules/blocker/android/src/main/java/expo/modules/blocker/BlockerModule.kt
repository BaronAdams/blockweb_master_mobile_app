package expo.modules.blocker

import android.content.Context
import android.provider.Settings
import android.text.TextUtils
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class BlockerModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("Blocker")

    AsyncFunction("isAccessibilityServiceEnabled") {
      isServiceEnabled()
    }

    AsyncFunction("isOverlayPermissionGranted") {
      Settings.canDrawOverlays(context)
    }

    AsyncFunction("setBlockedPackages") { packages: List<String> ->
      prefs().edit()
        .putStringSet(BlockAccessibilityService.BLOCKED_PACKAGES_KEY, packages.toHashSet())
        .apply()
    }

    AsyncFunction("setBlockedDomains") { domains: List<String> ->
      prefs().edit()
        .putStringSet(BlockAccessibilityService.BLOCKED_DOMAINS_KEY, domains.toHashSet())
        .apply()
    }

    AsyncFunction("setBlockedKeywords") { keywords: List<String> ->
      prefs().edit()
        .putStringSet(BlockAccessibilityService.BLOCKED_KEYWORDS_KEY, keywords.toHashSet())
        .apply()
    }

    AsyncFunction("getUsageStats") {
      readUsageStats()
    }

    AsyncFunction("getHourlyUsageStats") {
      readHourlyUsageStats()
    }
  }

  private val context: Context
    get() = appContext.reactContext ?: throw IllegalStateException("React context is not available")

  private fun prefs() =
    context.applicationContext.getSharedPreferences(BlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)

  private fun isServiceEnabled(): Boolean {
    val expected = "${context.packageName}/expo.modules.blocker.BlockAccessibilityService"

    val accessibilityEnabled = try {
      Settings.Secure.getInt(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
    } catch (e: Settings.SettingNotFoundException) {
      0
    }
    if (accessibilityEnabled != 1) return false

    val enabledServices = Settings.Secure.getString(
      context.contentResolver,
      Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
    ) ?: return false

    val splitter = TextUtils.SimpleStringSplitter(':')
    splitter.setString(enabledServices)
    while (splitter.hasNext()) {
      if (splitter.next().equals(expected, ignoreCase = true)) return true
    }
    return false
  }

  private fun readUsageStats(): Map<String, Map<String, Double>> {
    val prefs = prefs()
    val days = prefs.getStringSet(BlockAccessibilityService.DAYS_KEY, emptySet()) ?: emptySet()
    val result = mutableMapOf<String, Map<String, Double>>()

    for (day in days) {
      val packages = prefs.getStringSet("${BlockAccessibilityService.STATS_PREFIX}$day:packages", emptySet()) ?: emptySet()
      val dayUsage = mutableMapOf<String, Double>()
      for (pkg in packages) {
        // Filters out launcher/systemui/keyboard even if they were
        // recorded by an older build — the JS side replaces each day's
        // data wholesale with what this returns, so this retroactively
        // cleans already-stored bad entries too.
        if (!TrackablePackages.isTrackable(context, pkg)) continue
        val minutes = prefs.getFloat("${BlockAccessibilityService.STATS_PREFIX}$day:$pkg", 0f)
        if (minutes > 0f) dayUsage[pkg] = minutes.toDouble()
      }
      if (dayUsage.isNotEmpty()) result[day] = dayUsage
    }

    return result
  }

  /** { [date]: { [hour 0-23 as string]: { [packageName]: minutes } } } —
   *  only days/hours with at least one non-zero entry are included. */
  private fun readHourlyUsageStats(): Map<String, Map<String, Map<String, Double>>> {
    val prefs = prefs()
    val days = prefs.getStringSet(BlockAccessibilityService.DAYS_KEY, emptySet()) ?: emptySet()
    val result = mutableMapOf<String, Map<String, Map<String, Double>>>()
    val hourlyPrefix = BlockAccessibilityService.HOURLY_PREFIX

    for (day in days) {
      val hours = prefs.getStringSet("$hourlyPrefix$day:hours", emptySet()) ?: emptySet()
      val dayUsage = mutableMapOf<String, Map<String, Double>>()

      for (hour in hours) {
        val packages = prefs.getStringSet("$hourlyPrefix$day:$hour:packages", emptySet()) ?: emptySet()
        val hourUsage = mutableMapOf<String, Double>()
        for (pkg in packages) {
          if (!TrackablePackages.isTrackable(context, pkg)) continue
          val minutes = prefs.getFloat("$hourlyPrefix$day:$hour:$pkg", 0f)
          if (minutes > 0f) hourUsage[pkg] = minutes.toDouble()
        }
        if (hourUsage.isNotEmpty()) dayUsage[hour] = hourUsage
      }

      if (dayUsage.isNotEmpty()) result[day] = dayUsage
    }

    return result
  }
}
