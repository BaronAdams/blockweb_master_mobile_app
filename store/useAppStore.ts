import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'
import type { AppState, BlockedApp, BlockedWebsite, DailyAnalytics, LimiterProfile, SubscriptionState } from '@/types'

type AppStore = AppState & {
  addBlockedApp: (app: BlockedApp) => void
  removeBlockedApp: (id: string) => void
  toggleBlockedApp: (id: string) => void
  addKeyword: (keyword: string) => void
  removeKeyword: (id: string) => void

  addBlockedWebsite: (website: BlockedWebsite) => void
  removeBlockedWebsite: (id: string) => void
  toggleBlockedWebsite: (id: string) => void

  addWhitelistedSite: (domain: string) => void
  removeWhitelistedSite: (id: string) => void

  addProfile: (profile: LimiterProfile) => void
  updateProfile: (id: string, updates: Partial<LimiterProfile>) => void
  deleteProfile: (id: string) => void
  activateProfile: (id: string) => void

  recordUsage: (packageName: string, minutes: number) => void
  getTodayStats: () => DailyAnalytics | null
  /** Overwrites each day's per-app usage with the native accessibility
   *  service's totals (see hooks/useAppMonitor.ts) — those are already
   *  cumulative for the day, so days present in `stats` are replaced, not
   *  added to, to avoid double-counting. `blockedAttempts` is preserved. */
  mergeUsageStats: (stats: Record<string, Record<string, number>>) => void

  activateStrictMode: (days: number) => void
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
  setAccessibilityEnabled: (enabled: boolean) => void
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
      strictMode: { isActive: false, durationDays: 1 },
      plan: 'free',
      subscription: DEFAULT_SUBSCRIPTION,
      user: null,
      authCachedAt: null,
      hasSeenPermissionsOnboarding: false,
      isAccessibilityEnabled: false,

      addBlockedApp: (app) => set(s => ({
        blockedApps: [...s.blockedApps, app]
      })),

      removeBlockedApp: (id) => {
        if (get().strictMode.isActive) return
        set(s => ({ blockedApps: s.blockedApps.filter(a => a.id !== id) }))
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
        if (get().strictMode.isActive) return
        set(s => ({ blockedKeywords: s.blockedKeywords.filter(k => k.id !== id) }))
      },

      addBlockedWebsite: (website) => set(s => ({
        blockedWebsites: [...s.blockedWebsites, website]
      })),

      removeBlockedWebsite: (id) => {
        if (get().strictMode.isActive) return
        set(s => ({ blockedWebsites: s.blockedWebsites.filter(w => w.id !== id) }))
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
        if (get().strictMode.isActive) return
        set(s => ({ whitelistedSites: s.whitelistedSites.filter(w => w.id !== id) }))
      },

      addProfile: (profile) => set(s => ({
        limiterProfiles: [...s.limiterProfiles, profile]
      })),

      updateProfile: (id, updates) => {
        if (get().strictMode.isActive) return
        set(s => ({
          limiterProfiles: s.limiterProfiles.map(p =>
            p.id === id ? { ...p, ...updates } : p
          )
        }))
      },

      deleteProfile: (id) => {
        if (get().strictMode.isActive) return
        set(s => ({
          limiterProfiles: s.limiterProfiles.filter(p => p.id !== id)
        }))
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
            })
          }
          return { analytics: Array.from(byDate.values()).sort((a, b) => a.date.localeCompare(b.date)) }
        })
      },

      activateStrictMode: (days) => {
        const now = Date.now()
        set({
          strictMode: {
            isActive: true,
            activatedAt: now,
            expiresAt: now + days * 86400 * 1000,
            durationDays: days,
          }
        })
      },

      checkStrictExpiry: () => {
        const { strictMode } = get()
        if (strictMode.isActive && strictMode.expiresAt && Date.now() >= strictMode.expiresAt) {
          set({ strictMode: { isActive: false, durationDays: 1 } })
        }
      },

      setUser: (user) => set({ user }),
      setSubscription: (subscription) => set({ subscription, plan: subscription.plan }),
      setAuthCachedAt: (authCachedAt) => set({ authCachedAt }),
      logout: () => set({ user: null, plan: 'free', subscription: DEFAULT_SUBSCRIPTION, authCachedAt: null }),
      completePermissionsOnboarding: () => set({ hasSeenPermissionsOnboarding: true }),
      setAccessibilityEnabled: (isAccessibilityEnabled) => set({ isAccessibilityEnabled }),
    }),
    {
      name: 'blockweb-master-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
)
