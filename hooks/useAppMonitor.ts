import { useEffect, useState } from 'react'
import { useAppStore } from '@/store/useAppStore'

/**
 * Real foreground-app blocking needs native OS permissions (Android
 * UsageStats + Accessibility Service, or iOS FamilyControls) not yet
 * integrated. This reports monitoring as active/inactive based on whether
 * there's anything to watch, without intercepting real app launches.
 */
export function useAppMonitor() {
  const blockedApps = useAppStore(s => s.blockedApps)
  const profiles = useAppStore(s => s.limiterProfiles)
  const [isMonitoring, setIsMonitoring] = useState(false)

  useEffect(() => {
    const hasTargets =
      blockedApps.some(a => a.isBlocked) || profiles.some(p => p.isActive)
    setIsMonitoring(hasTargets)
  }, [blockedApps, profiles])

  return { isMonitoring }
}
