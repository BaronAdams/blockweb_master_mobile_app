package com.blockwebmaster.app.blocker

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import android.text.TextUtils
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter MethodChannel counterpart of the RN app's Expo module
 * (modules/blocker/android/.../BlockerModule.kt) — identical
 * responsibilities and identical SharedPreferences contract with
 * BlockAccessibilityService/BlockOverlay, just wired through a
 * MethodChannel (see MainActivity.kt) instead of the Expo Modules DSL.
 * See flutter_app/lib/native/blocker_bridge.dart for the Dart-side caller.
 */
class BlockerBridge(private val context: Context) : MethodChannel.MethodCallHandler {

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "isAccessibilityServiceEnabled" -> result.success(isServiceEnabled())
        "isOverlayPermissionGranted" -> result.success(Settings.canDrawOverlays(context))

        "setBlockedPackages" -> {
          val packages = (call.argument<List<String>>("packages") ?: emptyList())
          prefs().edit()
            .putStringSet(BlockAccessibilityService.BLOCKED_PACKAGES_KEY, packages.toHashSet())
            .apply()
          result.success(null)
        }

        "setBlockedDomains" -> {
          val domains = (call.argument<List<String>>("domains") ?: emptyList())
          prefs().edit()
            .putStringSet(BlockAccessibilityService.BLOCKED_DOMAINS_KEY, domains.toHashSet())
            .apply()
          result.success(null)
        }

        "setBlockedKeywords" -> {
          val keywords = (call.argument<List<String>>("keywords") ?: emptyList())
          prefs().edit()
            .putStringSet(BlockAccessibilityService.BLOCKED_KEYWORDS_KEY, keywords.toHashSet())
            .apply()
          result.success(null)
        }

        "getUsageStats" -> result.success(readUsageStats())
        "getHourlyUsageStats" -> result.success(readHourlyUsageStats())

        "isDeviceAdminActive" -> result.success(devicePolicyManager().isAdminActive(deviceAdminComponent()))

        "requestDeviceAdmin" -> {
          requestDeviceAdmin(call.argument<String>("explanation") ?: "")
          result.success(null)
        }

        "setBlockScreenStrings" -> {
          val json = call.argument<String>("json") ?: "{}"
          prefs().edit().putString(BlockOverlay.BLOCK_SCREEN_STRINGS_KEY, json).apply()
          result.success(null)
        }

        "openAndroidSettings" -> {
          openSettings(call.argument<String>("action") ?: "")
          result.success(null)
        }

        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      // Every Dart call site already treats a failed platform-channel call
      // as "stay at the last known state" (see blocker_bridge.dart's
      // try/catch-with-safe-default on every wrapper) — surface it as a
      // normal channel error rather than letting it crash the app.
      result.error("blocker_error", e.message, null)
    }
  }

  private fun devicePolicyManager(): DevicePolicyManager =
    context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

  private fun deviceAdminComponent(): ComponentName =
    ComponentName(context, BlockerDeviceAdminReceiver::class.java)

  private fun requestDeviceAdmin(explanation: String) {
    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
      putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, deviceAdminComponent())
      putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, explanation)
      addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    try {
      context.startActivity(intent)
    } catch (e: Exception) {
      // No Settings app able to handle this on some OEM builds — the
      // Strict Mode screen just keeps showing "not active" in that case.
    }
  }

  /** Opens a system Settings screen by action string (e.g.
   *  Settings.ACTION_ACCESSIBILITY_SETTINGS) — used by the "Enable" button
   *  on AccessibilityWarningBanner (Dart side). */
  private fun openSettings(action: String) {
    if (action.isEmpty()) return
    try {
      val intent = Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      context.startActivity(intent)
    } catch (e: Exception) {
      // No Settings screen able to handle this action on some OEM builds.
    }
  }

  private fun prefs(): SharedPreferences =
    context.applicationContext.getSharedPreferences(BlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)

  private fun isServiceEnabled(): Boolean {
    val expected = "${context.packageName}/com.blockwebmaster.app.blocker.BlockAccessibilityService"

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
        // recorded by an older build — the Dart side replaces each day's
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
