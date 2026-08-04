import { Image } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

// Mirrors the Chrome extension's sidebar logo header (dashboard shell):
// amber-tinted rounded square with the app icon, "BlockWeb Master" wordmark
// in Montserrat Bold next to it. Shown on every tab except Account, which
// has its own profile-focused header.
export function AppHeader() {
  const insets = useSafeAreaInsets()
  const primary = useColor('primary')
  const border = useColor('border')
  const text = useColor('text')

  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingHorizontal: 20,
        paddingTop: insets.top + 12,
        paddingBottom: 12,
        borderBottomWidth: 1,
        borderBottomColor: border,
      }}
    >
      <View
        style={{
          width: 44,
          height: 44,
          borderRadius: 12,
          backgroundColor: primary + '1A',
          borderWidth: 1,
          borderColor: primary + '40',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Image
          source={require('@/assets/android-icon-foreground.png')}
          style={{ width: 36, height: 36 }}
          resizeMode="contain"
        />
      </View>
      <Text
        style={{
          fontSize: 15,
          fontFamily: 'Montserrat_700Bold',
          color: text,
          letterSpacing: -0.2,
        }}
      >
        BlockWeb Master
      </Text>
    </View>
  )
}
