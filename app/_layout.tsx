import 'react-native-gesture-handler'
import '@/lib/i18n'
import { useEffect, useState } from 'react'
import { I18nManager, Platform } from 'react-native'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { GestureHandlerRootView } from 'react-native-gesture-handler'
import { Stack } from 'expo-router'
import { StatusBar } from 'expo-status-bar'
import { useFonts } from 'expo-font'
import i18n from '@/lib/i18n'
import { ModeProvider } from '@/providers/mode-provider'
import { useColorScheme } from '@/hooks/useColorScheme'
// Imported from per-weight submodules (not the package root) so Metro only
// bundles the weights we actually use, instead of all 18 Inter variants.
import { Inter_400Regular } from '@expo-google-fonts/inter/400Regular'
import { Inter_500Medium } from '@expo-google-fonts/inter/500Medium'
import { Inter_600SemiBold } from '@expo-google-fonts/inter/600SemiBold'
import { Inter_700Bold } from '@expo-google-fonts/inter/700Bold'
import { Inter_800ExtraBold } from '@expo-google-fonts/inter/800ExtraBold'
// Header wordmark ("BlockWeb Master") uses Montserrat Bold, matching the
// extension's sidebar logo — only this one weight is needed.
import { Montserrat_700Bold } from '@expo-google-fonts/montserrat/700Bold'
import { ThemeProvider } from '@/theme/theme-provider'
import { supabase } from '@/lib/supabase'
import { fetchSubscription } from '@/lib/subscription'
import { useAppStore } from '@/store/useAppStore'

// RTL layout for Arabic. RN only fully applies a forceRTL change after an
// app reload, so this only takes effect from the next cold start once the
// language changes — acceptable for a device-locale-driven default.
if (Platform.OS !== 'web') {
  const shouldBeRTL = i18n.language === 'ar'
  if (I18nManager.isRTL !== shouldBeRTL) {
    I18nManager.allowRTL(shouldBeRTL)
    I18nManager.forceRTL(shouldBeRTL)
  }
}

export default function RootLayout() {
  return (
    <ModeProvider storage={AsyncStorage} storageKey="blockweb-master.mode" defaultMode="system">
      <RootLayoutNav />
    </ModeProvider>
  )
}

function RootLayoutNav() {
  const { user, setUser, setSubscription } = useAppStore()
  const colorScheme = useColorScheme()
  const [sessionLoaded, setSessionLoaded] = useState(false)
  const [fontsLoaded] = useFonts({
    Inter_400Regular, Inter_500Medium, Inter_600SemiBold, Inter_700Bold, Inter_800ExtraBold,
    Montserrat_700Bold,
  })

  useEffect(() => {
    const syncUser = async (session: Awaited<ReturnType<typeof supabase.auth.getSession>>['data']['session']) => {
      setUser(session?.user ? {
        email: session.user.email ?? '',
        username: session.user.email?.split('@')[0] ?? '',
      } : null)
      // Real plan always comes from Supabase's `subscriptions` table — never
      // set locally in the UI (see lib/subscription.ts).
      setSubscription(session?.user ? await fetchSubscription(session.user.id) : { plan: 'free', expiresAt: null, isValid: true })
    }

    supabase.auth.getSession().then(({ data: { session } }) => {
      syncUser(session).finally(() => setSessionLoaded(true))
    })

    const { data: { subscription: authSubscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      syncUser(session)
    })

    return () => authSubscription.unsubscribe()
  }, [])

  if (!sessionLoaded || !fontsLoaded) return null

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeProvider>
        <StatusBar style={colorScheme === 'dark' ? 'light' : 'dark'} />
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Protected guard={!!user}>
            <Stack.Screen name="(tabs)" />
            <Stack.Screen name="profiles/create" />
            <Stack.Screen name="profiles/[id]" />
            <Stack.Screen name="pricing" />
            <Stack.Screen name="blocked" />
          </Stack.Protected>
          <Stack.Protected guard={!user}>
            <Stack.Screen name="(auth)" />
          </Stack.Protected>
        </Stack>
      </ThemeProvider>
    </GestureHandlerRootView>
  )
}
