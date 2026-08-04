import { useEffect, useRef } from 'react'
import { AppState as RNAppState, type AppStateStatus } from 'react-native'
import { useAppStore } from '@/store/useAppStore'
import * as Blocker from '@/modules/blocker'

/**
 * Bridges the store's blocklist/analytics to the real native blocking
 * engine (modules/blocker — an Android AccessibilityService). Website and
 * keyword blocking are not covered here: that needs a VpnService-based
 * approach and is deferred to a future version.
 *
 * - Pushes the current blocked-packages set to native whenever it changes,
 *   so the AccessibilityService always enforces the latest rules.
 * - Pulls real usage stats from native on mount and whenever the app
 *   returns to the foreground, merging them into the store's analytics.
 * - Writes isAccessibilityEnabled into the store so any screen can warn
 *   when blocking rules exist but won't be enforced, without each one
 *   re-polling native itself.
 *
 * Mounted once, in app/_layout.tsx, and runs for the lifetime of the app.
 */
export function useAppMonitor() {
  const blockedApps = useAppStore(s => s.blockedApps)
  const mergeUsageStats = useAppStore(s => s.mergeUsageStats)
  const setAccessibilityEnabled = useAppStore(s => s.setAccessibilityEnabled)
  const isAccessibilityEnabled = useAppStore(s => s.isAccessibilityEnabled)

  const blockedKey = blockedApps.filter(a => a.isBlocked).map(a => a.packageName).sort().join(',')
  const lastSyncedKey = useRef<string | null>(null)

  useEffect(() => {
    if (lastSyncedKey.current === blockedKey) return
    lastSyncedKey.current = blockedKey
    const packages = blockedKey ? blockedKey.split(',') : []
    Blocker.setBlockedPackages(packages)
  }, [blockedKey])

  useEffect(() => {
    const refresh = async () => {
      const [enabled, stats] = await Promise.all([
        Blocker.isAccessibilityServiceEnabled(),
        Blocker.getUsageStats(),
      ])
      setAccessibilityEnabled(enabled)
      if (Object.keys(stats).length > 0) mergeUsageStats(stats)
    }

    refresh()

    const onAppStateChange = (status: AppStateStatus) => {
      if (status === 'active') refresh()
    }
    const subscription = RNAppState.addEventListener('change', onAppStateChange)
    return () => subscription.remove()
  }, [mergeUsageStats, setAccessibilityEnabled])

  const isMonitoring = isAccessibilityEnabled && blockedApps.some(a => a.isBlocked)

  return { isMonitoring, isAccessibilityEnabled }
}
