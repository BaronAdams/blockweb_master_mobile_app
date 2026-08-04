import { View } from '@/components/ui/view'
import { AppLogo } from '@/components/AppLogo'
import { useColor } from '@/hooks/useColor'

// Bridges the native splash (icon only — expo-splash-screen can't render
// custom-font text before JS boots) to the real app: shown the instant
// fonts are ready, with the full icon + "BlockWeb Master" Montserrat
// wordmark, while the session/auth check finishes in the background.
export function AppSplashScreen() {
  const background = useColor('background')

  return (
    <View style={{ flex: 1, backgroundColor: background, alignItems: 'center', justifyContent: 'center' }}>
      <AppLogo size={72} />
    </View>
  )
}
