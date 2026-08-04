import { useColorScheme as useRNColorScheme } from 'react-native'
import { useAppStore } from '@/store/useAppStore'

// Resolves the effective color scheme: an explicit user choice ('light'/
// 'dark') wins, otherwise it follows the phone's setting — falling back to
// 'dark' only if the OS can't report one (matches the splash screen default).
export function useColorScheme() {
  const preference = useAppStore(s => s.themePreference)
  const system = useRNColorScheme()

  if (preference === 'light' || preference === 'dark') return preference
  return system ?? 'dark'
}
