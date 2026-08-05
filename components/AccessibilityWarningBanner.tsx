import { Linking, Platform } from 'react-native'
import { useTranslation } from 'react-i18next'
import { ShieldAlert } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'

// Surfaced wherever a blocking rule exists but might not actually be
// enforced — see hooks/useAppMonitor.ts, which keeps
// isAccessibilityEnabled/isOverlayPermissionGranted in the store in sync
// with real native state. Two independent things can be missing: the
// AccessibilityService itself (needed to detect app/site switches at all)
// and the "draw over other apps" permission (needed for the block overlay
// to actually render on top of the blocked app) — checked in that order
// since accessibility is the more fundamental one.
// `active` should be true only when there's something for this screen to
// actually warn about (e.g. at least one blocked app), so the banner
// doesn't show on an empty blocklist.
export function AccessibilityWarningBanner({ active }: { active: boolean }) {
  const { t } = useTranslation('common')
  const red = useColor('red')
  const isAccessibilityEnabled = useAppStore(s => s.isAccessibilityEnabled)
  const isOverlayPermissionGranted = useAppStore(s => s.isOverlayPermissionGranted)

  if (Platform.OS !== 'android' || !active) return null
  if (isAccessibilityEnabled && isOverlayPermissionGranted) return null

  const missingAccessibility = !isAccessibilityEnabled
  const message = missingAccessibility ? t('accessibilityDisabledWarning') : t('overlayDisabledWarning')
  const settingsAction = missingAccessibility
    ? 'android.settings.ACCESSIBILITY_SETTINGS'
    : 'android.settings.action.MANAGE_OVERLAY_PERMISSION'

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
        {message}
      </Text>
      <Button
        size="sm"
        variant="outline"
        onPress={() => Linking.sendIntent(settingsAction).catch(() => {})}
      >
        {t('permissionsEnable')}
      </Button>
    </View>
  )
}
