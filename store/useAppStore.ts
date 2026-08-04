import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import AsyncStorage from '@react-native-async-storage/async-storage'
import type { AppState, BlockedApp, BlockedWebsite, DailyAnalytics, LimiterProfile, SubscriptionState, ThemePreference } from '@/types'

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

  activateStrictMode: (days: number) => void
  checkStrictExpiry: () => void

  setUser: (user: AppState['user']) => void
  /** Single source of truth for the user's plan — populated from Supabase's
   *  `subscriptions` table (see lib/subscription.ts), never set locally. */
  setSubscription: (subscription: SubscriptionState) => void
  logout: () => void

  /** 'system' follows the phone's setting; 'light'/'dark' overrides it. */
  setThemePreference: (preference: ThemePreference) => void
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
      themePreference: 'system',

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
      logout: () => set({ user: null, plan: 'free', subscription: DEFAULT_SUBSCRIPTION }),
      setThemePreference: (themePreference) => set({ themePreference }),
    }),
    {
      name: 'blockweb-master-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
)
