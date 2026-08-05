import { useEffect, useRef } from 'react'
import { AppState as RNAppState, type AppStateStatus } from 'react-native'
import { useAppStore } from '@/store/useAppStore'
import * as Blocker from '@/modules/blocker'

/**
 * Bridges the store's blocklists/analytics to the real native blocking
 * engine (modules/blocker — an Android AccessibilityService).
 *
 * - Pushes the current blocked apps/domains/keywords to native whenever
 *   they change, so the AccessibilityService always enforces the latest
 *   rules (app blocking + overlay, and best-effort website/keyword
 *   blocking via reading known browsers' address bars — see
 *   BrowserUrlWatcher.kt for that approach's limitations).
 * - Pulls real usage stats (daily + hourly) from native on mount and
 *   whenever the app returns to the foreground, merging them into the
 *   store's analytics.
 * - Writes isAccessibilityEnabled / isOverlayPermissionGranted into the
 *   store so any screen can warn when a rule exists but won't be
 *   enforced, without each one re-polling native itself.
 *
 * Mounted once, in app/_layout.tsx, and runs for the lifetime of the app.
 */
export function useAppMonitor() {
  const blockedApps = useAppStore(s => s.blockedApps)
  const blockedWebsites = useAppStore(s => s.blockedWebsites)
  const blockedKeywords = useAppStore(s => s.blockedKeywords)
  const mergeUsageStats = useAppStore(s => s.mergeUsageStats)
  const mergeHourlyUsageStats = useAppStore(s => s.mergeHourlyUsageStats)
  const setAccessibilityEnabled = useAppStore(s => s.setAccessibilityEnabled)
  const setOverlayPermissionGranted = useAppStore(s => s.setOverlayPermissionGranted)
  const isAccessibilityEnabled = useAppStore(s => s.isAccessibilityEnabled)

  const blockedAppsKey = blockedApps.filter(a => a.isBlocked).map(a => a.packageName).sort().join(',')
  const blockedDomainsKey = blockedWebsites.filter(w => w.isBlocked).map(w => w.domain).sort().join(',')
  const blockedKeywordsKey = blockedKeywords.map(k => k.keyword).sort().join(',')
  const lastSyncedApps = useRef<string | null>(null)
  const lastSyncedDomains = useRef<string | null>(null)
  const lastSyncedKeywords = useRef<string | null>(null)

  useEffect(() => {
    if (lastSyncedApps.current === blockedAppsKey) return
    lastSyncedApps.current = blockedAppsKey
    Blocker.setBlockedPackages(blockedAppsKey ? blockedAppsKey.split(',') : [])
  }, [blockedAppsKey])

  useEffect(() => {
    if (lastSyncedDomains.current === blockedDomainsKey) return
    lastSyncedDomains.current = blockedDomainsKey
    Blocker.setBlockedDomains(blockedDomainsKey ? blockedDomainsKey.split(',') : [])
  }, [blockedDomainsKey])

  useEffect(() => {
    if (lastSyncedKeywords.current === blockedKeywordsKey) return
    lastSyncedKeywords.current = blockedKeywordsKey
    Blocker.setBlockedKeywords(blockedKeywordsKey ? blockedKeywordsKey.split(',') : [])
  }, [blockedKeywordsKey])

  useEffect(() => {
    const refresh = async () => {
      const [enabled, overlayGranted, stats, hourlyStats] = await Promise.all([
        Blocker.isAccessibilityServiceEnabled(),
        Blocker.isOverlayPermissionGranted(),
        Blocker.getUsageStats(),
        Blocker.getHourlyUsageStats(),
      ])
      setAccessibilityEnabled(enabled)
      setOverlayPermissionGranted(overlayGranted)
      if (Object.keys(stats).length > 0) mergeUsageStats(stats)
      if (Object.keys(hourlyStats).length > 0) mergeHourlyUsageStats(hourlyStats)
    }

    refresh()

    const onAppStateChange = (status: AppStateStatus) => {
      if (status === 'active') refresh()
    }
    const subscription = RNAppState.addEventListener('change', onAppStateChange)
    return () => subscription.remove()
  }, [mergeUsageStats, mergeHourlyUsageStats, setAccessibilityEnabled, setOverlayPermissionGranted])

  const isMonitoring = isAccessibilityEnabled && blockedApps.some(a => a.isBlocked)

  return { isMonitoring, isAccessibilityEnabled }
}
