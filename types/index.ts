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
}

export type StrictModeState = {
  isActive: boolean
  activatedAt?: number
  expiresAt?: number
  durationDays: number
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
}
