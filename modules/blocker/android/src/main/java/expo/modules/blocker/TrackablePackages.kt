package expo.modules.blocker

import android.content.Context
import android.content.Intent
import android.view.inputmethod.InputMethodManager

/**
 * Decides whether a foreground package is a real, user-facing app worth
 * tracking/attributing usage minutes to. Excludes OS chrome that briefly
 * becomes "foreground" as a side effect of normal navigation, but isn't
 * something the user deliberately opened:
 *  - the home-screen launcher (e.g. XOS, One UI Home, Nova…) — foregrounds
 *    constantly just by going back to the home screen between real apps
 *  - com.android.systemui — notification shade, quick settings, recent
 *    apps overview, lock screen, volume panel
 *  - the active keyboard (IME) — can register its own foreground window
 *    while typing inside another app
 *
 * Launcher/IME packages are resolved dynamically (queryIntentActivities /
 * InputMethodManager) instead of hardcoded, so this works across OEM
 * launchers and keyboards rather than just the ones seen during testing.
 */
object TrackablePackages {
  private var cachedExcluded: Set<String>? = null

  fun isTrackable(context: Context, packageName: String): Boolean {
    if (packageName == "com.android.systemui") return false
    return !excludedPackages(context).contains(packageName)
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
