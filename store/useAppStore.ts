import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'
import i18n, { DEVICE_LANGUAGE } from '@/lib/i18n'
import type { AppState, BlockedApp, BlockedWebsite, DailyAnalytics, LimiterProfile, SubscriptionState } from '@/types'

type AppStore = AppState & {
  addBlockedApp: (app: BlockedApp) => void
  /** Returns false (no-op) when Strict Mode blocks the removal — callers
   *  use that to surface a toast instead of failing silently. */
  removeBlockedApp: (id: string) => boolean
  toggleBlockedApp: (id: string) => void
  addKeyword: (keyword: string) => void
  removeKeyword: (id: string) => boolean

  addBlockedWebsite: (website: BlockedWebsite) => void
  removeBlockedWebsite: (id: string) => boolean
  toggleBlockedWebsite: (id: string) => void

  addWhitelistedSite: (domain: string) => void
  removeWhitelistedSite: (id: string) => boolean

  addProfile: (profile: LimiterProfile) => void
  updateProfile: (id: string, updates: Partial<LimiterProfile>) => boolean
  deleteProfile: (id: string) => boolean
  activateProfile: (id: string) => void

  recordUsage: (packageName: string, minutes: number) => void
  getTodayStats: () => DailyAnalytics | null
  /** Overwrites each day's per-app usage with the native accessibility
   *  service's totals (see hooks/useAppMonitor.ts) — those are already
   *  cumulative for the day, so days present in `stats` are replaced, not
   *  added to, to avoid double-counting. `blockedAttempts` is preserved. */
  mergeUsageStats: (stats: Record<string, Record<string, number>>) => void
  /** Same idea as mergeUsageStats but for the hour-bucketed breakdown
   *  (DailyAnalytics.hourlyUsage) — replaces per (day, hour). */
  mergeHourlyUsageStats: (stats: Record<string, Record<string, Record<string, number>>>) => void

  activateStrictMode: (seconds: number) => void
  checkStrictExpiry: () => void

  setUser: (user: AppState['user']) => void
  /** Single source of truth for the user's plan — populated from Supabase's
   *  `subscriptions` table (see lib/subscription.ts), never set locally. */
  setSubscription: (subscription: SubscriptionState) => void
  /** Marks user/subscription as freshly confirmed against Supabase — starts
   *  the 7-day offline grace window (see app/_layout.tsx's syncUser). */
  setAuthCachedAt: (timestamp: number) => void
  logout: () => void

  completePermissionsOnboarding: () => void
  completeOnboarding: () => void
  setAccessibilityEnabled: (enabled: boolean) => void
  setOverlayPermissionGranted: (granted: boolean) => void
  setDeviceAdminActive: (active: boolean) => void

  /** 'device' follows the phone's language (falling back to English if
   *  unsupported); 'en' is an explicit user override. Applied immediately
   *  and re-applied on every cold start once the store rehydrates. */
  setLanguagePreference: (pref: 'device' | 'en') => void
}

const DEFAULT_SUBSCRIPTION: SubscriptionState = { plan: 'free', expiresAt: null, isValid: true }

export const useAppStore = create<AppStore>()(
  persist(
    (set, get) => ({
      blockedApps: [],
      blockedKeywords: [],
      blockedWebsites: [],
      whitelistedSites: [],
      limiterProfiles: [],
      analytics: [],
      strictMode: { isActive: false, durationSeconds: 86400 },
      plan: 'free',
      subscription: DEFAULT_SUBSCRIPTION,
      user: null,
      authCachedAt: null,
      hasSeenPermissionsOnboarding: false,
      hasCompletedOnboarding: false,
      isAccessibilityEnabled: false,
      isOverlayPermissionGranted: false,
      isDeviceAdminActive: false,
      languagePreference: 'device',

      addBlockedApp: (app) => set(s => ({
        blockedApps: [...s.blockedApps, app]
      })),

      removeBlockedApp: (id) => {
        if (get().strictMode.isActive) return false
        set(s => ({ blockedApps: s.blockedApps.filter(a => a.id !== id) }))
        return true
      },

      toggleBlockedApp: (id) => set(s => ({
        blockedApps: s.blockedApps.map(a =>
          a.id === id ? { ...a, isBlocked: !a.isBlocked } : a
        )
      })),

      addKeyword: (keyword) => set(s => ({
        blockedKeywords: [...s.blockedKeywords, {
          id: Date.now().toString(), keyword, addedAt: Date.now()
        }]
      })),

      removeKeyword: (id) => {
        if (get().strictMode.isActive) return false
        set(s => ({ blockedKeywords: s.blockedKeywords.filter(k => k.id !== id) }))
        return true
      },

      addBlockedWebsite: (website) => set(s => ({
        blockedWebsites: [...s.blockedWebsites, website]
      })),

      removeBlockedWebsite: (id) => {
        if (get().strictMode.isActive) return false
        set(s => ({ blockedWebsites: s.blockedWebsites.filter(w => w.id !== id) }))
        return true
      },

      toggleBlockedWebsite: (id) => set(s => ({
        blockedWebsites: s.blockedWebsites.map(w =>
          w.id === id ? { ...w, isBlocked: !w.isBlocked } : w
        )
      })),

      addWhitelistedSite: (domain) => set(s => ({
        whitelistedSites: [...s.whitelistedSites, {
          id: Date.now().toString(), domain, addedAt: Date.now()
        }]
      })),

      removeWhitelistedSite: (id) => {
        if (get().strictMode.isActive) return false
        set(s => ({ whitelistedSites: s.whitelistedSites.filter(w => w.id !== id) }))
        return true
      },

      addProfile: (profile) => set(s => ({
        limiterProfiles: [...s.limiterProfiles, profile]
      })),

      updateProfile: (id, updates) => {
        if (get().strictMode.isActive) return false
        set(s => ({
          limiterProfiles: s.limiterProfiles.map(p =>
            p.id === id ? { ...p, ...updates } : p
          )
        }))
        return true
      },

      deleteProfile: (id) => {
        if (get().strictMode.isActive) return false
        set(s => ({
          limiterProfiles: s.limiterProfiles.filter(p => p.id !== id)
        }))
        return true
      },

      activateProfile: (id) => set(s => ({
        limiterProfiles: s.limiterProfiles.map(p =>
          p.id === id ? { ...p, isActive: !p.isActive } : p
        )
      })),

      recordUsage: (packageName, minutes) => {
        const today = new Date().toISOString().split('T')[0]
        set(s => {
          const existing = s.analytics.find(a => a.date === today)
          if (existing) {
            return {
              analytics: s.analytics.map(a =>
                a.date === today
                  ? {
                      ...a,
                      totalMinutes: a.totalMinutes + minutes,
                      appUsage: {
                        ...a.appUsage,
                        [packageName]: (a.appUsage[packageName] ?? 0) + minutes
                      }
                    }
                  : a
              )
            }
          }
          return {
            analytics: [...s.analytics, {
              date: today,
              appUsage: { [packageName]: minutes },
              totalMinutes: minutes,
              blockedAttempts: 0,
            }]
          }
        })
      },

      getTodayStats: () => {
        const today = new Date().toISOString().split('T')[0]
        return get().analytics.find(a => a.date === today) ?? null
      },

      mergeUsageStats: (stats) => {
        const days = Object.keys(stats)
        if (days.length === 0) return
        set(s => {
          const byDate = new Map(s.analytics.map(a => [a.date, a]))
          for (const date of days) {
            const appUsage = stats[date]
            const totalMinutes = Object.values(appUsage).reduce((sum, m) => sum + m, 0)
            const existing = byDate.get(date)
            byDate.set(date, {
              date,
              appUsage,
              totalMinutes,
              blockedAttempts: existing?.blockedAttempts ?? 0,
              hourlyUsage: existing?.hourlyUsage,
            })
          }
          return { analytics: Array.from(byDate.values()).sort((a, b) => a.date.localeCompare(b.date)) }
        })
      },

      mergeHourlyUsageStats: (stats) => {
        const days = Object.keys(stats)
        if (days.length === 0) return
        set(s => {
          const byDate = new Map(s.analytics.map(a => [a.date, a]))
          for (const date of days) {
            const existing = byDate.get(date)
            byDate.set(date, {
              date,
              appUsage: existing?.appUsage ?? {},
              totalMinutes: existing?.totalMinutes ?? 0,
              blockedAttempts: existing?.blockedAttempts ?? 0,
              hourlyUsage: stats[date],
            })
          }
          return { analytics: Array.from(byDate.values()).sort((a, b) => a.date.localeCompare(b.date)) }
        })
      },

      activateStrictMode: (seconds) => {
        const now = Date.now()
        set({
          strictMode: {
            isActive: true,
            activatedAt: now,
            expiresAt: now + seconds * 1000,
            durationSeconds: seconds,
          }
        })
      },

      checkStrictExpiry: () => {
        const { strictMode } = get()
        if (strictMode.isActive && strictMode.expiresAt && Date.now() >= strictMode.expiresAt) {
          set({ strictMode: { isActive: false, durationSeconds: 86400 } })
        }
      },

      setUser: (user) => set({ user }),
      setSubscription: (subscription) => set({ subscription, plan: subscription.plan }),
      setAuthCachedAt: (authCachedAt) => set({ authCachedAt }),
      logout: () => set({ user: null, plan: 'free', subscription: DEFAULT_SUBSCRIPTION, authCachedAt: null }),
      completePermissionsOnboarding: () => set({ hasSeenPermissionsOnboarding: true }),
      completeOnboarding: () => set({ hasCompletedOnboarding: true }),
      setAccessibilityEnabled: (isAccessibilityEnabled) => set({ isAccessibilityEnabled }),
      setOverlayPermissionGranted: (isOverlayPermissionGranted) => set({ isOverlayPermissionGranted }),
      setDeviceAdminActive: (isDeviceAdminActive) => set({ isDeviceAdminActive }),

      setLanguagePreference: (languagePreference) => {
        set({ languagePreference })
        i18n.changeLanguage(languagePreference === 'en' ? 'en' : DEVICE_LANGUAGE)
      },
    }),
    {
      name: 'blockweb-master-storage',
      storage: createJSONStorage(() => AsyncStorage),
      // i18n.ts already boots with the device language as a synchronous
      // default (before this async AsyncStorage read resolves) — this
      // re-applies an explicit 'en' override once we know about it.
      onRehydrateStorage: () => (state) => {
        if (state?.languagePreference === 'en') i18n.changeLanguage('en')
      },
    }
  )
)
