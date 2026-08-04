import { Linking, Platform } from 'react-native'
import { useTranslation } from 'react-i18next'
import { ShieldAlert } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'

// Surfaced wherever a blocking rule exists but might not actually be
// enforced — see hooks/useAppMonitor.ts, which keeps isAccessibilityEnabled
// in the store in sync with the real native AccessibilityService state.
// `active` should be true only when there's something for this screen to
// actually warn about (e.g. at least one blocked app), so the banner
// doesn't show on an empty blocklist.
export function AccessibilityWarningBanner({ active }: { active: boolean }) {
  const { t } = useTranslation('common')
  const red = useColor('red')
  const isAccessibilityEnabled = useAppStore(s => s.isAccessibilityEnabled)

  if (Platform.OS !== 'android' || isAccessibilityEnabled || !active) return null

  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        padding: 12,
        borderRadius: 12,
        backgroundColor: red + '14',
        borderWidth: 1,
        borderColor: red + '33',
        marginBottom: 12,
      }}
    >
      <ShieldAlert size={18} color={red} />
      <Text variant="caption" style={{ flex: 1, fontSize: 12, lineHeight: 16 }}>
        {t('accessibilityDisabledWarning')}
      </Text>
      <Button
        size="sm"
        variant="outline"
        onPress={() => Linking.sendIntent('android.settings.ACCESSIBILITY_SETTINGS').catch(() => {})}
      >
        {t('permissionsEnable')}
      </Button>
    </View>
  )
}
