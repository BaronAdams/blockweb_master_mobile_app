// Builds the full set of localized strings the native block overlay needs
// (see modules/blocker/android/.../BlockOverlay.kt) — pushed to native via
// Blocker.setBlockScreenStrings() whenever the app's language changes (see
// hooks/useAppMonitor.ts), so the overlay never needs its own i18n. Native
// only ever substitutes a single "{{value}}" token per description, so
// templated strings are pre-rendered here with the real i18next
// interpolation passed the literal token itself — e.g. t(key, { name:
// '{{value}}' }) — rather than reimplementing i18next's syntax in Kotlin.
type TFn = (key: string, options?: Record<string, unknown>) => string

export type BlockScreenReasonKey = 'app' | 'site' | 'keyword' | 'adult' | 'daily' | 'hourly' | 'weekly' | 'interval'

export type BlockScreenStrings = {
  common: {
    securityDetails: string
    blockingReason: string
    goBack: string
    manageRules: string
  }
  reasons: Record<BlockScreenReasonKey, {
    title: string
    /** May contain the literal substring "{{value}}" — native replaces it
     *  with the app name / domain / keyword being reported. */
    desc: string
    badge: string
    detailLabel: string
    reasonLabel: string
  }>
  quotes: { text: string; author: string }[]
}

export function buildBlockScreenStrings(t: TFn): BlockScreenStrings {
  const withPlaceholder = (key: string, varName: string) => t(key, { [varName]: '{{value}}' })

  return {
    common: {
      securityDetails: t('securityDetails'),
      blockingReason: t('blockingReason'),
      goBack: t('goBack'),
      manageRules: t('manageRules'),
    },
    reasons: {
      app: {
        title: t('appBlockedTitle'),
        desc: withPlaceholder('appBlockedDesc', 'name'),
        badge: t('focusBadge'),
        detailLabel: t('blockedApplication'),
        reasonLabel: t('appBlockedReason'),
      },
      site: {
        title: t('restrictedAccess'),
        desc: t('focusDesc'),
        badge: t('focusBadge'),
        detailLabel: t('targetDomain'),
        reasonLabel: t('focusMode'),
      },
      keyword: {
        title: t('restrictedAccess'),
        desc: withPlaceholder('keywordDesc', 'keyword'),
        badge: t('keywordBadge'),
        detailLabel: t('detectedKeyword'),
        reasonLabel: t('keywordReason'),
      },
      adult: {
        title: t('adultBlocked'),
        desc: t('adultDesc'),
        badge: t('adultBadge'),
        detailLabel: t('adultBlockedSite'),
        reasonLabel: t('adultReason'),
      },
      daily: {
        title: t('dailyTitle'),
        desc: withPlaceholder('dailyDesc', 'name'),
        badge: t('dailyBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('dailyReason'),
      },
      hourly: {
        title: t('hourlyTitle'),
        desc: withPlaceholder('hourlyDesc', 'name'),
        badge: t('hourlyBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('hourlyReason'),
      },
      weekly: {
        title: t('weeklyTitle'),
        desc: withPlaceholder('weeklyDesc', 'name'),
        badge: t('weeklyBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('weeklyReason'),
      },
      interval: {
        title: t('intervalTitle'),
        desc: withPlaceholder('intervalDesc', 'name'),
        badge: t('intervalBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('intervalReason'),
      },
    },
    quotes: Array.from({ length: 10 }, (_, i) => ({
      text: t(`quote_${i + 1}_desc`),
      author: t(`quote_${i + 1}_author`),
    })),
  }
}
