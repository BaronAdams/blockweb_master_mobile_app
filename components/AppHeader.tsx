import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { View } from '@/components/ui/view'
import { AppLogo } from '@/components/AppLogo'
import { useColor } from '@/hooks/useColor'

// Mirrors the Chrome extension's sidebar logo header (dashboard shell):
// amber-tinted rounded square with the app icon, "BlockWeb Master" wordmark
// in Montserrat Bold next to it. Shown on every tab except Account, which
// has its own profile-focused header.
export function AppHeader() {
  const insets = useSafeAreaInsets()
  const border = useColor('border')

  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 20,
        paddingTop: insets.top + 12,
        paddingBottom: 12,
        borderBottomWidth: 1,
        borderBottomColor: border,
      }}
    >
      <AppLogo />
    </View>
  )
}
