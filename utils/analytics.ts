const DISTRACTION_APPS = [
  'com.instagram.android', 'com.zhiliaoapp.musically',
  'com.facebook.katana', 'com.twitter.android',
  'com.reddit.frontpage', 'com.snapchat.android',
]
const ENTERTAINMENT_APPS = [
  'com.google.android.youtube', 'com.netflix.mediaclient',
  'com.spotify.music', 'com.twitch.android.app',
]

export function getCategoryBreakdown(
  appUsage: Record<string, number>,
  productiveApps: string[]
): Record<'distraction' | 'productivity' | 'entertainment' | 'other', number> {
  const result = { distraction: 0, productivity: 0, entertainment: 0, other: 0 }

  for (const [pkg, minutes] of Object.entries(appUsage)) {
    if (productiveApps.includes(pkg)) result.productivity += minutes
    else if (DISTRACTION_APPS.includes(pkg)) result.distraction += minutes
    else if (ENTERTAINMENT_APPS.includes(pkg)) result.entertainment += minutes
    else result.other += minutes
  }

  return result
}

export function formatMinutes(minutes: number): string {
  if (minutes < 60) return `${Math.round(minutes)}m`
  const h = Math.floor(minutes / 60)
  const m = Math.round(minutes % 60)
  return m > 0 ? `${h}h ${m}m` : `${h}h`
}

export function getHourlyData(appUsage: Record<string, number>): number[] {
  const total = Object.values(appUsage).reduce((a, b) => a + b, 0)
  return Array.from({ length: 24 }, (_, h) => {
    if (h >= 19 && h <= 22) return total * 0.08
    if (h >= 12 && h <= 14) return total * 0.06
    if (h >= 8 && h <= 11) return total * 0.04
    return 0
  })
}

export function getWeeklyHeatmapData(
  analytics: { date: string; totalMinutes: number }[]
): number[][] {
  const last35Days = Array.from({ length: 35 }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() - (34 - i))
    return d.toISOString().split('T')[0]
  })
  const byDate = Object.fromEntries(analytics.map(a => [a.date, a.totalMinutes]))
  const flat = last35Days.map(d => byDate[d] ?? 0)
  return Array.from({ length: 5 }, (_, w) => flat.slice(w * 7, w * 7 + 7))
}
