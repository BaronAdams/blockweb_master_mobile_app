import { Pressable, ScrollView } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { ChevronRight, Check, Smartphone, Sun, Moon, LogOut, Trash2, User as UserIcon } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { AlertDialog, useAlertDialog } from '@/components/ui/alert-dialog'
import { SectionTitle } from '@/components/SectionTitle'
import { DangerButton } from '@/components/DangerButton'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { useModeContext, type Mode } from '@/providers/mode-provider'
import { supabase } from '@/lib/supabase'
import { isPremium } from '@/utils/limits'
import type { UserPlan } from '@/types'

const THEME_OPTIONS: { value: Mode; labelKey: string; icon: React.ComponentType<{ size?: number; color?: string }> }[] = [
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
  const mutedForeground = useColor('mutedForeground')

  const user = useAppStore(s => s.user)
  const plan = useAppStore(s => s.plan)
  const logout = useAppStore(s => s.logout)

  const logoutDialog = useAlertDialog()
  const deleteDialog = useAlertDialog()

  const initials = (user?.username ?? user?.email ?? '?').slice(0, 2).toUpperCase()
  const planMeta = PLAN_BADGE[plan]

  // Sign-out only clears local session state — no forced navigation. The
  // user stays on this tab, which just re-renders in its guest state.
  const onLogout = async () => {
    await supabase.auth.signOut()
    logout()
  }

  if (!user) {
    return (
      <ScrollView
        style={{ flex: 1, backgroundColor: background }}
        contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 40, gap: 20 }}
      >
        <View style={{ alignItems: 'center', paddingVertical: 8, gap: 12 }}>
          <Avatar size={72}>
            <AvatarFallback>
              <UserIcon size={28} color={mutedForeground} />
            </AvatarFallback>
          </Avatar>
          <View style={{ alignItems: 'center', gap: 4 }}>
            <Text style={{ fontSize: 18, fontWeight: '700' }}>{t('guestTitle')}</Text>
            <Text variant="caption" style={{ fontSize: 13, textAlign: 'center', maxWidth: 280, lineHeight: 18 }}>
              {t('guestDesc')}
            </Text>
          </View>
          <Button onPress={() => router.push('/(auth)/login')} style={{ marginTop: 8 }}>
            {t('signInCta')}
          </Button>
        </View>

        <AppearanceSection />
      </ScrollView>
    )
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
        <Text style={{ fontSize: 18, fontWeight: '700' }}>{user.username}</Text>
        <Text variant="caption" style={{ fontSize: 13, marginTop: 2 }}>{user.email}</Text>
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

      <AppearanceSection />

      <View>
        <SectionTitle style={{ marginBottom: 8, marginLeft: 4, color: red }}>{t('permanentDeletion')}</SectionTitle>
        <View style={{ gap: 10 }}>
          <DangerButton label={t('signOut')} icon={LogOut} onPress={logoutDialog.open} />
          <DangerButton label={t('deleteMyAccount')} icon={Trash2} onPress={deleteDialog.open} />
        </View>
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

// A device preference, not personal account data — shown for guests too.
function AppearanceSection() {
  const { t } = useTranslation('account')
  const primary = useColor('primary')
  // Non-null: RootLayout always mounts a ModeProvider above every screen.
  const { mode, setMode } = useModeContext()!

  return (
    <View>
      <SectionTitle style={{ marginBottom: 8, marginLeft: 4 }}>{t('appearance')}</SectionTitle>
      <Card style={{ padding: 0 }}>
        {THEME_OPTIONS.map((option, index) => {
          const selected = mode === option.value
          const OptionIcon = option.icon
          return (
            <View key={option.value}>
              {index > 0 && <Separator />}
              <Pressable
                onPress={() => setMode(option.value)}
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
  )
}

function SettingsRow({
  label,
  right,
  showChevron,
  onPress,
}: {
  label: string
  right?: React.ReactNode
  showChevron?: boolean
  onPress?: () => void
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
      <Text style={{ flex: 1, fontSize: 14 }}>{label}</Text>
      {right}
      {showChevron && <ChevronRight size={18} color="#71717a" />}
    </Pressable>
  )
}
