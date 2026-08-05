import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import * as Localization from 'expo-localization'

import ar from '@/locales/ar/messages.json'
import de from '@/locales/de/messages.json'
import en from '@/locales/en/messages.json'
import es from '@/locales/es/messages.json'
import fr from '@/locales/fr/messages.json'
import hi from '@/locales/hi/messages.json'
import it from '@/locales/it/messages.json'
import ja from '@/locales/ja/messages.json'
import ko from '@/locales/ko/messages.json'
import nl from '@/locales/nl/messages.json'
import pl from '@/locales/pl/messages.json'
import pt_PT from '@/locales/pt_PT/messages.json'
import ru from '@/locales/ru/messages.json'
import zh_CN from '@/locales/zh_CN/messages.json'

export const NAMESPACES = [
  'common', 'sidebar', 'popup', 'auth', 'blocked',
  'analytics', 'blockLists', 'profiles', 'strictMode', 'account', 'pricing', 'onboarding',
] as const

const resources = { ar, de, en, es, fr, hi, it, ja, ko, nl, pl, pt_PT, ru, zh_CN }

export const SUPPORTED_LANGUAGES = Object.keys(resources)

// Chrome-extension locale codes use pt_PT/zh_CN; device locales report as
// pt-PT/zh-CN — normalize before matching against our supported set.
export function resolveDeviceLanguage(): string {
  const tags = Localization.getLocales().map(l => l.languageTag)
  for (const tag of tags) {
    const underscored = tag.replace('-', '_')
    if (SUPPORTED_LANGUAGES.includes(underscored)) return underscored
    const bare = tag.split('-')[0]
    if (SUPPORTED_LANGUAGES.includes(bare)) return bare
  }
  return 'en'
}

// The device's language, resolved once at boot — used as the "device
// default" option in the language picker (see app/(tabs)/account.tsx).
// A user's explicit choice is stored separately (store.languagePreference)
// and re-applied on top of this after the store rehydrates.
export const DEVICE_LANGUAGE = resolveDeviceLanguage()

// Autonyms, for the picker only — every other string in the app comes
// from the locale files themselves.
export const LANGUAGE_NAMES: Record<string, string> = {
  ar: 'العربية',
  de: 'Deutsch',
  en: 'English',
  es: 'Español',
  fr: 'Français',
  hi: 'हिन्दी',
  it: 'Italiano',
  ja: '日本語',
  ko: '한국어',
  nl: 'Nederlands',
  pl: 'Polski',
  pt_PT: 'Português',
  ru: 'Русский',
  zh_CN: '中文',
}

i18n.use(initReactI18next).init({
  resources,
  lng: DEVICE_LANGUAGE,
  fallbackLng: 'en',
  ns: NAMESPACES,
  defaultNS: 'common',
  interpolation: { escapeValue: false },
  react: { useSuspense: false },
})

export default i18n
