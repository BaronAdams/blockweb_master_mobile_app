export type SiteCategory = 'adult' | 'distraction' | 'entertainment' | 'productivity' | 'other'

type CategoryMeta = {
  labelKey: string
  descKey: string
  color: string
  emoji: string
}

// Exact colors/emojis from the Chrome extension's lib/constants.ts CATEGORY_META.
export const CATEGORY_META: Record<SiteCategory, CategoryMeta> = {
  adult: {
    labelKey: 'adultContent',
    descKey: 'adultContentDesc',
    color: '#f43f5e',
    emoji: '🔞',
  },
  distraction: {
    labelKey: 'distraction',
    descKey: 'distractionDesc',
    color: '#9e4fe7',
    emoji: '📱',
  },
  entertainment: {
    labelKey: 'entertainment',
    descKey: 'entertainmentDesc',
    color: '#fbbf24',
    emoji: '🎬',
  },
  productivity: {
    labelKey: 'productivity',
    descKey: 'productivityDesc',
    color: '#34d399',
    emoji: '💼',
  },
  other: {
    labelKey: 'other',
    descKey: 'otherDesc',
    color: '#60a5fa',
    emoji: '🌐',
  },
}

export const CATEGORY_ORDER: SiteCategory[] = ['adult', 'distraction', 'entertainment', 'productivity', 'other']
