export type BlockedApp = {
  id: string
  packageName: string
  appName: string
  iconUrl?: string
  isBlocked: boolean
  addedAt: number
}

export type BlockedKeyword = {
  id: string
  keyword: string
  addedAt: number
}

export type BlockedWebsite = {
  id: string
  domain: string
  isBlocked: boolean
  addedAt: number
}

export type WhitelistedSite = {
  id: string
  domain: string
  addedAt: number
}

export type { LimiterType } from '@/lib/profileTypes'
import type { LimiterType } from '@/lib/profileTypes'

export type DayOfWeek = 'mon' | 'tue' | 'wed' | 'thu' | 'fri' | 'sat' | 'sun'

export type IntervalConfig = {
  startTime: string
  endTime: string
  days: DayOfWeek[]
}

export type LimiterProfile = {
  id: string
  name: string
  type: LimiterType
  apps: string[]
  websites: string[]
  keywords: string[]
  dailyLimitMinutes?: number
  dailyUsedMinutes?: number
  dailyResetAt?: number
  hourlyLimitMinutes?: number
  hourlyUsedMinutes?: number
  weeklyLimitMinutes?: number
  weeklyUsedMinutes?: number
  weeklyResetAt?: number
  intervalConfig?: IntervalConfig
  isActive: boolean
  createdAt: number
}

export type DailyAnalytics = {
  date: string
  appUsage: Record<string, number>
  totalMinutes: number
  blockedAttempts: number
  /** hour ("0".."23") -> packageName -> minutes, for the hourly chart and
   *  click-to-filter (see hooks/useAppMonitor.ts's mergeHourlyUsageStats). */
  hourlyUsage?: Record<string, Record<string, number>>
}

export type StrictModeState = {
  isActive: boolean
  activatedAt?: number
  expiresAt?: number
  durationSeconds: number
}

export type UserPlan = 'free' | 'monthly' | 'yearly' | 'lifetime'

export type SubscriptionState = {
  plan: UserPlan
  expiresAt: number | null
  isValid: boolean
}

export type AppState = {
  blockedApps: BlockedApp[]
  blockedKeywords: BlockedKeyword[]
  blockedWebsites: BlockedWebsite[]
  whitelistedSites: WhitelistedSite[]
  limiterProfiles: LimiterProfile[]
  analytics: DailyAnalytics[]
  strictMode: StrictModeState
  plan: UserPlan
  subscription: SubscriptionState
  user: { email: string; username: string } | null
  /** When `user`/`subscription` were last confirmed against Supabase.
   *  Used to keep the cached profile usable offline for a bounded grace
   *  period instead of signing out on a network error. */
  authCachedAt: number | null
  hasSeenPermissionsOnboarding: boolean
  /** The first-launch Build Up + Paywall flow (marketing/personalization
   *  intro), shown once before the permissions onboarding. */
  hasCompletedOnboarding: boolean
  /** Whether the native AccessibilityService (see modules/blocker) is
   *  actually enabled on-device — refreshed by hooks/useAppMonitor.ts.
   *  Blocking rules only take effect while this is true. */
  isAccessibilityEnabled: boolean
  /** Whether SYSTEM_ALERT_WINDOW ("draw over other apps") is granted —
   *  required for the native block overlay to actually appear. */
  isOverlayPermissionGranted: boolean
  /** Whether this app is registered as an active Android Device
   *  Administrator — required for the Strict Mode uninstall-friction
   *  restriction to actually apply (see modules/blocker/index.ts). */
  isDeviceAdminActive: boolean
  /** 'device' (default) follows the phone's language; 'en' is an explicit
   *  user override — see store/useAppStore.ts's setLanguagePreference. */
  languagePreference: 'device' | 'en'
}
