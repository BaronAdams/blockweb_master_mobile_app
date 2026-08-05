import { categorizeApp, type SiteCategory } from '@/lib/categories'

export function getCategoryBreakdown(
  appUsage: Record<string, number>,
  productiveApps: string[]
): Record<'distraction' | 'productivity' | 'entertainment' | 'other', number> {
  const result = { distraction: 0, productivity: 0, entertainment: 0, other: 0 }

  for (const [pkg, minutes] of Object.entries(appUsage)) {
    const category: SiteCategory = productiveApps.includes(pkg) ? 'productivity' : categorizeApp(pkg)
    if (category === 'adult') {
      result.other += minutes
    } else {
      result[category] += minutes
    }
  }

  return result
}

export function formatMinutes(minutes: number): string {
  if (minutes < 1) return `${Math.round(minutes * 60)}s`
  if (minutes < 60) {
    const whole = Math.floor(minutes)
    const seconds = Math.round((minutes - whole) * 60)
    return seconds > 0 ? `${whole}m ${seconds}s` : `${whole}m`
  }
  const h = Math.floor(minutes / 60)
  const m = Math.round(minutes % 60)
  return m > 0 ? `${h}h ${m}m` : `${h}h`
}
