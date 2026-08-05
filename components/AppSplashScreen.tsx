import { Image } from 'react-native'
import { View } from '@/components/ui/view'
import { useColorScheme } from '@/hooks/useColorScheme'

// Bridges the native splash (expo-splash-screen, see app.json) to the real
// app: shown the instant fonts are ready, while the session/auth check
// finishes in the background. Matches the native splash exactly — icon
// only, no wordmark — and uses the same hardcoded white/black backgrounds
// as app.json's splash plugin config (not the theme's `background` token,
// which can be an off-white/off-black shade and would show as a visible
// flash at the handoff).
export function AppSplashScreen() {
  const colorScheme = useColorScheme()
  const background = colorScheme === 'dark' ? '#000000' : '#ffffff'

  return (
    <View style={{ flex: 1, backgroundColor: background, alignItems: 'center', justifyContent: 'center' }}>
      <Image
        source={require('@/assets/android-icon-foreground.png')}
        style={{ width: 140, height: 140 }}
        resizeMode="contain"
      />
    </View>
  )
}
