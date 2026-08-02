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
  'analytics', 'blockLists', 'profiles', 'strictMode', 'account', 'pricing',
] as const

const resources = { ar, de, en, es, fr, hi, it, ja, ko, nl, pl, pt_PT, ru, zh_CN }

export const SUPPORTED_LANGUAGES = Object.keys(resources)

// Chrome-extension locale codes use pt_PT/zh_CN; device locales report as
// pt-PT/zh-CN — normalize before matching against our supported set.
function resolveDeviceLanguage(): string {
  const tags = Localization.getLocales().map(l => l.languageTag)
  for (const tag of tags) {
    const underscored = tag.replace('-', '_')
    if (SUPPORTED_LANGUAGES.includes(underscored)) return underscored
    const bare = tag.split('-')[0]
    if (SUPPORTED_LANGUAGES.includes(bare)) return bare
  }
  return 'en'
}

i18n.use(initReactI18next).init({
  resources,
  lng: resolveDeviceLanguage(),
  fallbackLng: 'en',
  ns: NAMESPACES,
  defaultNS: 'common',
  interpolation: { escapeValue: false },
  react: { useSuspense: false },
})

export default i18n
