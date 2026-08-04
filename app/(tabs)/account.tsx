import { Pressable, ScrollView } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { ChevronRight, Check, Smartphone, Sun, Moon } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { AlertDialog, useAlertDialog } from '@/components/ui/alert-dialog'
import { SectionTitle } from '@/components/SectionTitle'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { supabase } from '@/lib/supabase'
import { isPremium } from '@/utils/limits'
import type { ThemePreference, UserPlan } from '@/types'

const THEME_OPTIONS: { value: ThemePreference; labelKey: string; icon: React.ComponentType<{ size?: number; color?: string }> }[] = [
  { value: 'system', labelKey: 'themeSystem', icon: Smartphone },
  { value: 'light', labelKey: 'themeLight', icon: Sun },
  { value: 'dark', labelKey: 'themeDark', icon: Moon },
]

const PLAN_BADGE: Record<UserPlan, { labelKey: string; color: string }> = {
  free: { labelKey: 'free', color: '#a1a1aa' },
  monthly: { labelKey: 'monthly', color: '#fcd34d' },
  yearly: { labelKey: 'yearly', color: '#fcd34d' },
  lifetime: { labelKey: 'lifetime', color: '#6ee7b7' },
}

export default function AccountScreen() {
  const { t } = useTranslation('account')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const primary = useColor('primary')
  const red = useColor('red')

  const user = useAppStore(s => s.user)
  const plan = useAppStore(s => s.plan)
  const logout = useAppStore(s => s.logout)
  const themePreference = useAppStore(s => s.themePreference)
  const setThemePreference = useAppStore(s => s.setThemePreference)

  const logoutDialog = useAlertDialog()
  const deleteDialog = useAlertDialog()

  const initials = (user?.username ?? user?.email ?? '?').slice(0, 2).toUpperCase()
  const planMeta = PLAN_BADGE[plan]

  const onLogout = async () => {
    await supabase.auth.signOut()
    logout()
    router.replace('/(auth)/login')
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 40, gap: 20 }}
    >
      <View style={{ alignItems: 'center', paddingVertical: 8 }}>
        <Avatar size={72} style={{ marginBottom: 12 }}>
          <AvatarFallback>
            <Text style={{ fontSize: 22, fontWeight: '700' }}>{initials}</Text>
          </AvatarFallback>
        </Avatar>
        <Text style={{ fontSize: 18, fontWeight: '700' }}>{user?.username ?? 'Invité'}</Text>
        <Text variant="caption" style={{ fontSize: 13, marginTop: 2 }}>{user?.email ?? ''}</Text>
        <Badge
          variant="outline"
          style={{ marginTop: 10, borderColor: planMeta.color + '60', backgroundColor: planMeta.color + '1A' }}
          textStyle={{ color: planMeta.color }}
        >
          {isPremium(plan) ? tc('pro') : tc('free').toUpperCase()}
        </Badge>
      </View>

      <View>
        <SectionTitle style={{ marginBottom: 8, marginLeft: 4 }}>{t('subscription')}</SectionTitle>
        <Card style={{ padding: 0 }}>
          <SettingsRow
            label={t('plan')}
            right={
              <Badge textStyle={{ color: planMeta.color }} style={{ backgroundColor: planMeta.color + '1A' }}>
                {tc(planMeta.labelKey)}
              </Badge>
            }
          />
          <Separator />
          <SettingsRow label={t('subscription')} showChevron onPress={() => router.push('/pricing')} />
        </Card>
      </View>

      <View>
        <SectionTitle style={{ marginBottom: 8, marginLeft: 4 }}>Sécurité</SectionTitle>
        <Card style={{ padding: 0 }}>
          <SettingsRow label={t('changePassword')} showChevron />
          <Separator />
          <SettingsRow label={t('changeUsername')} showChevron />
        </Card>
      </View>

      <View>
        <SectionTitle style={{ marginBottom: 8, marginLeft: 4 }}>{t('appearance')}</SectionTitle>
        <Card style={{ padding: 0 }}>
          {THEME_OPTIONS.map((option, index) => {
            const selected = themePreference === option.value
            const OptionIcon = option.icon
            return (
              <View key={option.value}>
                {index > 0 && <Separator />}
                <Pressable
                  onPress={() => setThemePreference(option.value)}
                  style={{
                    flexDirection: 'row',
                    alignItems: 'center',
                    gap: 12,
                    paddingVertical: 14,
                    paddingHorizontal: 16,
                    minHeight: 48,
                  }}
                >
                  <OptionIcon size={18} color={selected ? primary : '#71717a'} />
                  <Text style={{ flex: 1, fontSize: 14 }}>{t(option.labelKey)}</Text>
                  {selected && <Check size={18} color={primary} />}
                </Pressable>
              </View>
            )
          })}
        </Card>
      </View>

      <View>
        <SectionTitle style={{ marginBottom: 8, marginLeft: 4, color: red }}>{t('permanentDeletion')}</SectionTitle>
        <Card style={{ padding: 0, backgroundColor: red + '0D', borderColor: red + '33' }}>
          <SettingsRow label={t('signOut')} onPress={logoutDialog.open} color={red} />
          <Separator />
          <SettingsRow label={t('deleteMyAccount')} onPress={deleteDialog.open} color={red} />
        </Card>
      </View>

      <AlertDialog
        isVisible={logoutDialog.isVisible}
        onClose={logoutDialog.close}
        title={t('signOut')}
        description={t('signOutConfirm')}
        confirmText={t('signOut')}
        onConfirm={onLogout}
      />

      <AlertDialog
        isVisible={deleteDialog.isVisible}
        onClose={deleteDialog.close}
        title={t('deleteMyAccount')}
        description={t('deleteDesc')}
        confirmText={t('permanentDelete')}
        onConfirm={onLogout}
      />
    </ScrollView>
  )
}

function SettingsRow({
  label,
  right,
  showChevron,
  onPress,
  color,
}: {
  label: string
  right?: React.ReactNode
  showChevron?: boolean
  onPress?: () => void
  color?: string
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 14,
        paddingHorizontal: 16,
        minHeight: 48,
      }}
    >
      <Text style={{ flex: 1, fontSize: 14, color }}>{label}</Text>
      {right}
      {showChevron && <ChevronRight size={18} color="#71717a" />}
    </Pressable>
  )
}
