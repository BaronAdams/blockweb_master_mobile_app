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

    AsyncFunction("setBlockedPackages") { packages: List<String> ->
      prefs().edit()
        .putStringSet(BlockAccessibilityService.BLOCKED_PACKAGES_KEY, packages.toHashSet())
        .apply()
    }

    AsyncFunction("getUsageStats") {
      readUsageStats()
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
        val minutes = prefs.getFloat("${BlockAccessibilityService.STATS_PREFIX}$day:$pkg", 0f)
        if (minutes > 0f) dayUsage[pkg] = minutes.toDouble()
      }
      if (dayUsage.isNotEmpty()) result[day] = dayUsage
    }

    return result
  }
}
