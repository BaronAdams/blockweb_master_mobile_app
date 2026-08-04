import { useCallback, useEffect, useState } from 'react'
import { Platform } from 'react-native'

export type InstalledApp = {
  packageName: string
  appName: string
  icon?: string
}

export function useInstalledApps() {
  const [apps, setApps] = useState<InstalledApp[]>([])
  const [loading, setLoading] = useState(true)

  const loadApps = useCallback(async () => {
    setLoading(true)

    // react-native-launcher-kit is Android-only (it reads the device's
    // PackageManager) — iOS has no equivalent API at all, Apple doesn't
    // allow any app to enumerate what else is installed, so there's no
    // library that could do this on iOS. Fall back to the curated list
    // there and on web.
    if (Platform.OS === 'android') {
      try {
        const { InstalledApps } = await import('react-native-launcher-kit')
        const installed = await InstalledApps.getSortedApps({
          includeVersion: false,
          includeAccentColor: false,
        })
        setApps(installed.map(app => ({
          packageName: app.packageName,
          appName: app.label,
          icon: app.icon,
        })))
        setLoading(false)
        return
      } catch {
        // Native module unavailable (e.g. running in Expo Go, or the
        // permission prompt failed) — fall through to the demo list below.
      }
    }

    setApps(Platform.OS === 'android' ? POPULAR_APPS_ANDROID : POPULAR_APPS_IOS)
    setLoading(false)
  }, [])

  useEffect(() => {
    loadApps()
  }, [loadApps])

  return { apps, loading, reload: loadApps }
}

const POPULAR_APPS_ANDROID: InstalledApp[] = [
  { packageName: 'com.instagram.android', appName: 'Instagram' },
  { packageName: 'com.zhiliaoapp.musically', appName: 'TikTok' },
  { packageName: 'com.facebook.katana', appName: 'Facebook' },
  { packageName: 'com.twitter.android', appName: 'X (Twitter)' },
  { packageName: 'com.google.android.youtube', appName: 'YouTube' },
  { packageName: 'com.reddit.frontpage', appName: 'Reddit' },
  { packageName: 'com.snapchat.android', appName: 'Snapchat' },
  { packageName: 'com.discord', appName: 'Discord' },
  { packageName: 'com.pinterest', appName: 'Pinterest' },
  { packageName: 'com.linkedin.android', appName: 'LinkedIn' },
  { packageName: 'com.whatsapp', appName: 'WhatsApp' },
  { packageName: 'org.telegram.messenger', appName: 'Telegram' },
]

const POPULAR_APPS_IOS: InstalledApp[] = [
  { packageName: 'com.burbn.instagram', appName: 'Instagram' },
  { packageName: 'com.zhiliaoapp.musically', appName: 'TikTok' },
  { packageName: 'com.facebook.Facebook', appName: 'Facebook' },
  { packageName: 'com.atebits.Tweetie2', appName: 'X (Twitter)' },
  { packageName: 'com.google.ios.youtube', appName: 'YouTube' },
  { packageName: 'com.reddit.Reddit', appName: 'Reddit' },
  { packageName: 'com.toyopagroup.picaboo', appName: 'Snapchat' },
  { packageName: 'com.hammerandchisel.discord', appName: 'Discord' },
  { packageName: 'pinterest', appName: 'Pinterest' },
  { packageName: 'com.linkedin.LinkedIn', appName: 'LinkedIn' },
]
