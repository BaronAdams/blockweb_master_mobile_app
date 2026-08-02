import type { UserPlan } from '@/types'

const TIER_LIMITS = {
  free: {
    maxBlockedApps: 3,
    maxKeywords: 3,
    maxProfiles: 1,
    maxAppsPerProfile: 3,
    maxStrictDays: 1,
  },
  premium: {
    maxBlockedApps: Infinity,
    maxKeywords: Infinity,
    maxProfiles: Infinity,
    maxAppsPerProfile: Infinity,
    maxStrictDays: 30,
  },
}

export function isPremium(plan: UserPlan): boolean {
  return plan !== 'free'
}

export function limitsFor(plan: UserPlan) {
  return isPremium(plan) ? TIER_LIMITS.premium : TIER_LIMITS.free
}

export function canAddBlockedApp(plan: UserPlan, currentCount: number): boolean {
  return currentCount < limitsFor(plan).maxBlockedApps
}

export function canCreateProfile(plan: UserPlan, currentCount: number): boolean {
  return currentCount < limitsFor(plan).maxProfiles
}

export function canActivateStrictMode(plan: UserPlan, days: number): boolean {
  return days <= limitsFor(plan).maxStrictDays
}
