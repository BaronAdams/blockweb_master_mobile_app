import { useState } from 'react'
import { Linking, Platform, ScrollView } from 'react-native'
import { useTranslation } from 'react-i18next'
import * as Notifications from 'expo-notifications'
import { Accessibility, Bell, Eye, Layers, ShieldCheck, type LucideIcon } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useColor } from '@/hooks/useColor'

type PermissionRow = {
  key: string
  icon: LucideIcon
  titleKey: string
  descKey: string
  onEnable: () => void | Promise<void>
}

// Shown once (see hasSeenPermissionsOnboarding in the app store) right
// after the session/splash gate. Notifications is a real, requestable
// runtime permission; Accessibility, Usage Access and "display over other
// apps" are Android "special app access" grants with no request dialog —
// the OS only lets a user flip them from Settings, so these deep-link
// there instead of pretending to request them. There's no API to read
// back whether the user actually granted them afterwards, so this can't
// hard-gate the app on it — "Continuer" always proceeds.
//
// Accessibility is the important one: it's what actually lets the app
// detect app/site switches in real time to enforce blocking and track
// usage (see hooks/useAppMonitor.ts) — Usage Access alone is poll-based
// and much less immediate. None of the three has its native counterpart
// wired up yet (no AccessibilityService is registered in this build), so
// enabling them today doesn't yet turn on real blocking.
export function PermissionsOnboarding({ onDone }: { onDone: () => void }) {
  const { t } = useTranslation('common')
  const background = useColor('background')
  const primary = useColor('primary')

  const [requested, setRequested] = useState<Set<string>>(new Set())
  const markRequested = (key: string) => setRequested(prev => new Set(prev).add(key))

  const requestNotifications = async () => {
    try {
      await Notifications.requestPermissionsAsync()
    } catch {
      // Best-effort — a denied or unavailable notifications module must not
      // block onboarding.
    }
    markRequested('notifications')
  }

  const openAccessibilitySettings = () => {
    markRequested('accessibility')
    if (Platform.OS === 'android') {
      Linking.sendIntent('android.settings.ACCESSIBILITY_SETTINGS').catch(() => {})
    }
  }

  const openUsageAccessSettings = () => {
    markRequested('usage')
    if (Platform.OS === 'android') {
      Linking.sendIntent('android.settings.USAGE_ACCESS_SETTINGS').catch(() => {})
    }
  }

  const openOverlaySettings = () => {
    markRequested('overlay')
    if (Platform.OS === 'android') {
      Linking.sendIntent('android.settings.action.MANAGE_OVERLAY_PERMISSION').catch(() => {})
    }
  }

  const rows: PermissionRow[] = [
    { key: 'notifications', icon: Bell, titleKey: 'permissionsNotifTitle', descKey: 'permissionsNotifDesc', onEnable: requestNotifications },
    ...(Platform.OS === 'android' ? [
      { key: 'accessibility', icon: Accessibility, titleKey: 'permissionsAccessibilityTitle', descKey: 'permissionsAccessibilityDesc', onEnable: openAccessibilitySettings },
      { key: 'usage', icon: Eye, titleKey: 'permissionsUsageTitle', descKey: 'permissionsUsageDesc', onEnable: openUsageAccessSettings },
      { key: 'overlay', icon: Layers, titleKey: 'permissionsOverlayTitle', descKey: 'permissionsOverlayDesc', onEnable: openOverlaySettings },
    ] as PermissionRow[] : []),
  ]

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 20, paddingTop: 60, paddingBottom: 24 }}>
        <View style={{ alignItems: 'center', gap: 12, marginBottom: 28 }}>
          <View
            style={{
              width: 56, height: 56, borderRadius: 16,
              backgroundColor: primary + '1A', borderWidth: 1, borderColor: primary + '40',
              alignItems: 'center', justifyContent: 'center',
            }}
          >
            <ShieldCheck size={26} color={primary} />
          </View>
          <Text variant="title" style={{ fontSize: 20, textAlign: 'center' }}>{t('permissionsTitle')}</Text>
          <Text variant="caption" style={{ fontSize: 13, textAlign: 'center', lineHeight: 18, maxWidth: 320 }}>
            {t('permissionsIntro')}
          </Text>
        </View>

        <View style={{ gap: 10 }}>
          {rows.map(row => {
            const Icon = row.icon
            const done = requested.has(row.key)
            return (
              <Card key={row.key} style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                <View
                  style={{
                    width: 40, height: 40, borderRadius: 10,
                    backgroundColor: primary + '1A',
                    alignItems: 'center', justifyContent: 'center',
                  }}
                >
                  <Icon size={19} color={primary} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 14, fontWeight: '600' }}>{t(row.titleKey)}</Text>
                  <Text variant="caption" style={{ fontSize: 11, marginTop: 2, lineHeight: 15 }}>
                    {t(row.descKey)}
                  </Text>
                </View>
                <Button size="sm" variant={done ? 'outline' : 'default'} onPress={row.onEnable}>
                  {done ? t('permissionsRequested') : t('permissionsEnable')}
                </Button>
              </Card>
            )
          })}
        </View>

        <View style={{ flex: 1, minHeight: 24 }} />

        <View style={{ gap: 10 }}>
          <Button onPress={onDone}>{t('continue')}</Button>
          <Button variant="ghost" onPress={onDone}>{t('permissionsSkip')}</Button>
        </View>
      </ScrollView>
    </View>
  )
}
