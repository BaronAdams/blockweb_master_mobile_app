import 'react-native-gesture-handler'
import '@/lib/i18n'
import { useEffect, useState } from 'react'
import { I18nManager, Platform } from 'react-native'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { GestureHandlerRootView } from 'react-native-gesture-handler'
import { Stack } from 'expo-router'
import { StatusBar } from 'expo-status-bar'
import { useFonts } from 'expo-font'
import * as SplashScreen from 'expo-splash-screen'
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
import { AppSplashScreen } from '@/components/AppSplashScreen'
import { PermissionsOnboarding } from '@/components/PermissionsOnboarding'
import { supabase } from '@/lib/supabase'
import { fetchSubscription } from '@/lib/subscription'
import { useAppStore } from '@/store/useAppStore'
import { useAppMonitor } from '@/hooks/useAppMonitor'

// The native splash (icon only — see app.json's expo-splash-screen plugin)
// stays up until we explicitly hide it, so it can hand off to
// AppSplashScreen (icon + Montserrat wordmark) instead of auto-hiding onto
// a blank frame the moment the first native frame is drawn.
SplashScreen.preventAutoHideAsync().catch(() => {})

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000

// Mirrors the Chrome extension's syncAuth: a network failure must never
// sign the user out. Only a confirmed invalid/expired session does that.
function isNetworkError(err: unknown): boolean {
  if (!(err instanceof Error)) return false
  const msg = err.message.toLowerCase()
  return msg.includes('fetch') || msg.includes('network') || msg.includes('failed') || msg.includes('offline')
}

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
  const { setUser, setSubscription, setAuthCachedAt, logout, hasSeenPermissionsOnboarding, completePermissionsOnboarding } = useAppStore()
  const colorScheme = useColorScheme()
  const [sessionLoaded, setSessionLoaded] = useState(false)
  // Always mounted (not gated behind the splash/onboarding screens below)
  // so blocklist sync and usage-stat pulls keep running continuously.
  useAppMonitor()
  const [fontsLoaded] = useFonts({
    Inter_400Regular, Inter_500Medium, Inter_600SemiBold, Inter_700Bold, Inter_800ExtraBold,
    Montserrat_700Bold,
  })

  useEffect(() => {
    if (fontsLoaded) SplashScreen.hideAsync().catch(() => {})
  }, [fontsLoaded])

  useEffect(() => {
    const syncUser = async (session: Awaited<ReturnType<typeof supabase.auth.getSession>>['data']['session']) => {
      if (!session?.user) {
        logout()
        return
      }
      setUser({
        email: session.user.email ?? '',
        username: session.user.email?.split('@')[0] ?? '',
      })
      // Real plan always comes from Supabase's `subscriptions` table — never
      // set locally in the UI (see lib/subscription.ts). May throw on a
      // network failure; the outer catch below decides what to do with that.
      setSubscription(await fetchSubscription(session.user.id))
      setAuthCachedAt(Date.now())
    }

    // A network failure reaching Supabase falls back to whatever is already
    // cached in the store (from the last successful sync) as long as it's
    // less than 7 days old — otherwise, or on a confirmed invalid session,
    // sign out for real.
    const handleSyncError = (err: unknown) => {
      const { authCachedAt, user } = useAppStore.getState()
      const withinGrace = !!user && authCachedAt != null && Date.now() - authCachedAt < SEVEN_DAYS_MS
      if (isNetworkError(err) && withinGrace) return
      logout()
    }

    supabase.auth.getSession()
      .then(({ data: { session } }) => syncUser(session))
      .catch(handleSyncError)
      .finally(() => setSessionLoaded(true))

    const { data: { subscription: authSubscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      syncUser(session).catch(handleSyncError)
    })

    return () => authSubscription.unsubscribe()
  }, [])

  if (!fontsLoaded) return null
  if (!sessionLoaded) return <AppSplashScreen />

  if (!hasSeenPermissionsOnboarding) {
    return (
      <GestureHandlerRootView style={{ flex: 1 }}>
        <ThemeProvider>
          <StatusBar style={colorScheme === 'dark' ? 'light' : 'dark'} />
          <PermissionsOnboarding onDone={completePermissionsOnboarding} />
        </ThemeProvider>
      </GestureHandlerRootView>
    )
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeProvider>
        <StatusBar style={colorScheme === 'dark' ? 'light' : 'dark'} />
        <Stack screenOptions={{ headerShown: false, animation: 'fade' }}>
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="(auth)" />
          <Stack.Screen name="profiles/create" />
          <Stack.Screen name="profiles/[id]" />
          <Stack.Screen name="pricing" />
          <Stack.Screen name="blocked" />
        </Stack>
      </ThemeProvider>
    </GestureHandlerRootView>
  )
}
