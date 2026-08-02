import { useEffect, useState } from 'react'
import { Platform } from 'react-native'

export type InstalledApp = {
  packageName: string
  appName: string
  icon?: string
}

export function useInstalledApps() {
  const [apps, setApps] = useState<InstalledApp[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadApps()
  }, [])

  const loadApps = async () => {
    // Real device app listing requires native modules (Android UsageStats /
    // iOS Screen Time) not yet wired up. Using the static demo lists for now.
    setApps(Platform.OS === 'android' ? POPULAR_APPS_ANDROID : POPULAR_APPS_IOS)
    setLoading(false)
  }

  return { apps, loading }
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
